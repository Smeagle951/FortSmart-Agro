import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  // Lista de arquivos a serem corrigidos
  final filesToFix = [
    'lib/database/talhao_database.dart',
    'lib/screens/talhoes/talhoes_screen_safra.dart',
    'lib/screens/infestacao/mapa_infestacao_screen.dart',
    'lib/modules/planting/services/data_cache_service.dart',
    'lib/services/talhao_sync_service.dart',
    'lib/widgets/enhanced_farm_map.dart',
    'lib/models/talhao_model.dart',
    'lib/utils/model_adapters.dart'
  ];

  final projectDir = Directory.current.path;
  
  print('Iniciando correção de tipos de cores...');
  
  for (final filePath in filesToFix) {
    final fullPath = path.join(projectDir, filePath);
    final file = File(fullPath);
    
    if (await file.exists()) {
      print('Corrigindo arquivo: $filePath');
      String content = await file.readAsString();
      
      // Adicionar importação do ColorConverter se não existir
      if (!content.contains("import '../utils/color_converter.dart'") && 
          !content.contains("import 'package:fortsmart_agro/utils/color_converter.dart'")) {
        
        // Encontrar a última linha de importação
        final importRegex = RegExp(r'import\s+[\'"].*?[\'"];');
        final matches = importRegex.allMatches(content).toList();
        
        if (matches.isNotEmpty) {
          final lastImport = matches.last;
          final insertPos = lastImport.end;
          
          // Determinar o caminho relativo correto para a importação
          String importPath;
          final dirDepth = filePath.split('/').length - 2; // -2 para lib e arquivo
          if (dirDepth == 0) {
            importPath = "import 'utils/color_converter.dart';";
          } else {
            final prefix = '../' * dirDepth;
            importPath = "import '$prefix" + "utils/color_converter.dart';";
          }
          
          content = content.substring(0, insertPos) + 
                   '\n$importPath' + 
                   content.substring(insertPos);
        }
      }
      
      // Corrigir problemas específicos em cada arquivo
      switch (path.basename(filePath)) {
        case 'talhao_database.dart':
          // Corrigir atribuições de Color para String
          content = content.replaceAll(
            "final Color cor = Color(int.parse('0xFF\${corHex.replaceAll('#', '')}'));",
            "// Não precisamos converter para Color, pois o modelo espera uma String"
          );
          content = content.replaceAll(
            "culturaCor: cor,",
            "culturaCor: corHex, // Usar a string hexadecimal diretamente"
          );
          break;
          
        // Adicione casos para outros arquivos conforme necessário
      }
      
      // Salvar o arquivo corrigido
      await file.writeAsString(content);
      print('Arquivo corrigido: $filePath');
    } else {
      print('Arquivo não encontrado: $filePath');
    }
  }
  
  print('Correção de tipos de cores concluída!');
}
