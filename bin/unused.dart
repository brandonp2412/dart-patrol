import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please provide the path to the Dart project.');
    return;
  }

  final projectPath = args[0];
  final publicMembers = <String>{};
  final usedMembers = <String>{};

  final dartFiles = Directory(projectPath)
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  // Step 1: Collect all public members
  for (var file in dartFiles) {
    final content = file.readAsStringSync();
    final lines = content.split('\n');

    for (var line in lines) {
      final publicMember = extractPublicMember(line);
      if (publicMember != null) {
        publicMembers.add(publicMember);
      }
    }
  }

  // Step 2: Collect all used members
  for (var file in dartFiles) {
    final content = file.readAsStringSync();
    final words = content.split(RegExp(r'\W+'));

    for (var word in words) {
      if (publicMembers.contains(word)) {
        usedMembers.add(word);
      }
    }
  }

  // Step 3: Find unused public members
  final unusedMembers = publicMembers.difference(usedMembers);

  print('Unused public members:');
  for (var member in unusedMembers) {
    print(member);
  }
}

String? extractPublicMember(String line) {
  final publicMemberPattern = RegExp(
    r'^(?:class|typedef|var|final|const|dynamic|String|int|double|bool|List|Set|Map)\s+([A-Za-z_]\w*)',
  );

  final match = publicMemberPattern.firstMatch(line);
  if (match != null) {
    return match.group(1);
  }

  return null;
}
