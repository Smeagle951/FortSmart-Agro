import 'dart:io';

void main() async {
  final directory = Directory('lib/modules/planting');
  await processDirectory(directory);
  print('Busca concluída!');
}

Future<void> processDirectory(Directory directory) async {
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await checkFile(entity);
    }
  }
}

Future<void> checkFile(File file) async {
  try {
    String content = await file.readAsString();
    
    // Verificar comentários incorretos sobre backgroundColor
    final bgMatches = RegExp(r'// backgroundColor: (.*?), // backgroundColor não é suportado').allMatches(content);
    
    // Verificar comentários incorretos sobre onTap
    final tapMatches = RegExp(r'// onTap: (.*?), // onTap não é suportado').allMatches(content);
    
    if (bgMatches.isNotEmpty || tapMatches.isNotEmpty) {
      print('Arquivo com comentários incorretos: ${file.path}');
      print('  - backgroundColor incorretos: ${bgMatches.length}');
      print('  - onTap incorretos: ${tapMatches.length}');
    }
  } catch (e) {
    print('Erro ao processar ${file.path}: $e');
  }
}
