import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Please provide the path to your Flutter project.');
    return;
  }

  String projectPath = arguments[0];
  await refactorProject(projectPath);
}

Future<void> refactorProject(String projectPath) async {
  var collection = AnalysisContextCollection(
    includedPaths: [projectPath],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  for (var context in collection.contexts) {
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (filePath.endsWith('.dart')) {
        var result = await context.currentSession.getResolvedUnit(filePath);
        if (result is ResolvedUnitResult) {
          var visitor = VariableRenamer();
          result.unit.accept(visitor);

          if (visitor.changes.isNotEmpty) {
            applyChanges(filePath, visitor.changes);
            print('Refactored: $filePath');
          }
        }
      }
    }
  }
}

class VariableRenamer extends RecursiveAstVisitor<void> {
  final changes = <SourceEdit>[];
  final renamedVariables = <String, String>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var name = node.name.lexeme;
    if (name.startsWith('_')) {
      var newName = name.substring(1);
      renamedVariables[name] = newName;
      changes.add(SourceEdit(node.name.offset, node.name.length, newName));
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var name = node.name;
    if (renamedVariables.containsKey(name)) {
      changes
          .add(SourceEdit(node.offset, node.length, renamedVariables[name]!));
    }
    super.visitSimpleIdentifier(node);
  }
}

void applyChanges(String filePath, List<SourceEdit> edits) {
  var file = File(filePath);
  var content = file.readAsStringSync();
  var sortedEdits = edits..sort((a, b) => b.offset.compareTo(a.offset));

  for (var edit in sortedEdits) {
    content = content.replaceRange(
        edit.offset, edit.offset + edit.length, edit.replacement);
  }

  file.writeAsStringSync(content);
}

class SourceEdit {
  final int offset;
  final int length;
  final String replacement;

  SourceEdit(this.offset, this.length, this.replacement);
}
