// Script para corrigir as importações no projeto
// Execute com: flutter run fix_imports.dart

import 'dart:io';

void main() async {
  final projectDir = Directory('.');
  final dartFiles = await _findDartFiles(projectDir);
  int updatedFiles = 0;
  
  for (final file in dartFiles) {
    final content = await File(file.path).readAsString();
    if (content.contains('package:fortsmartagro/')) {
      print('Corrigindo importações em: ${file.path}');
      final newContent = content.replaceAll(
        'package:fortsmartagro/', 
        'package:fortsmart_agro_new/'
      );
      await File(file.path).writeAsString(newContent);
      updatedFiles++;
    }
  }
  
  print('Concluído! $updatedFiles arquivos foram atualizados.');
}

Future<List<FileSystemEntity>> _findDartFiles(Directory dir) async {
  final List<FileSystemEntity> result = [];
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      result.add(entity);
    }
  }
  
  return result;
}
