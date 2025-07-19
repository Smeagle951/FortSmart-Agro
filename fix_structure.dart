import 'dart:io';

void main() {
  // Caminho para o arquivo original e o arquivo temporário
  final String originalPath = 'c:\\Users\\fortu\\fortsmart_agro_new\\lib\\screens\\farm\\farm_profile_screen.dart';
  final String tempPath = 'c:\\Users\\fortu\\fortsmart_agro_new\\lib\\screens\\farm\\farm_profile_screen.dart.new';
  
  try {
    // Lê o arquivo original
    final File originalFile = File(originalPath);
    final List<String> lines = originalFile.readAsLinesSync();
    
    // Inicializa a lista para as linhas corrigidas
    final List<String> correctedLines = [];
    
    // Variáveis para controle de indentação
    int indenationLevel = 0;
    bool inContainer = false;
    bool inChildren = false;
    
    // Processa cada linha
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      // Corrige a indentação na linha 672 (GestureDetector e comentário)
      if (i == 671) {
        line = line.replaceFirst('children: [', 'children: [');
      } else if (i == 672) {
        line = line.replaceFirst('// Logo da fazenda', '      // Logo da fazenda');
      } else if (i == 673) {
        line = line.replaceFirst('GestureDetector', '      GestureDetector');
      }
      
      // Corrige a indentação na linha 814 (Align)
      else if (i == 813) {
        line = line.replaceFirst('Align', '      Align');
      }
      
      correctedLines.add(line);
    }
    
    // Escreve as linhas corrigidas em um arquivo temporário
    final File tempFile = File(tempPath);
    tempFile.writeAsStringSync(correctedLines.join('\n'));
    
    print('Arquivo temporário criado em: $tempPath');
    print('Verifique se as correções estão corretas e então substitua o arquivo original.');
  } catch (e) {
    print('Erro ao processar o arquivo: $e');
  }
}
