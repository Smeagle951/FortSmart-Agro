import 'dart:io';

void main() async {
  final directory = Directory('lib/modules/planting');
  await processDirectory(directory);
  print('Processamento concluído!');
}

Future<void> processDirectory(Directory directory) async {
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await processFile(entity);
    }
  }
}

Future<void> processFile(File file) async {
  try {
    String content = await file.readAsString();
    
    // Corrigir comentários incorretos sobre backgroundColor
    final originalContent = content;
    
    // Corrigir comentários sobre backgroundColor
    content = content.replaceAll(
      RegExp(r'// backgroundColor: (.*?), // backgroundColor não é suportado em flutter_map 5\.0\.0'),
      'backgroundColor: \$1,',
    );
    
    // Corrigir comentários sobre onTap
    content = content.replaceAll(
      RegExp(r'// onTap: (.*?), // onTap não é suportado em Polygon no flutter_map 5\.0\.0'),
      'onTap: \$1,',
    );
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Arquivo corrigido: ${file.path}');
    }
  } catch (e) {
    print('Erro ao processar ${file.path}: $e');
  }
}
