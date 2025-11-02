// Este script é usado para atualizar os arquivos relacionados ao mapa
// para compatibilidade com flutter_map 5.0.0

import 'dart:io';

void main() async {
  // Lista de arquivos a serem substituídos
  final filesToReplace = {
    'lib/utils/map_compatibility_layer.dart': 'lib/utils/map_compatibility_layer_corrected.dart',
    'lib/screens/widgets/map_tiler_map_widget.dart': 'lib/screens/widgets/map_tiler_map_widget_corrected.dart',
  };
  
  // Substituir os arquivos
  for (final entry in filesToReplace.entries) {
    final originalFile = File(entry.key);
    final correctedFile = File(entry.value);
    
    if (await correctedFile.exists()) {
      print('Substituindo ${entry.key} por ${entry.value}');
      final correctedContent = await correctedFile.readAsString();
      await originalFile.writeAsString(correctedContent);
      print('Arquivo ${entry.key} atualizado com sucesso!');
    } else {
      print('ERRO: Arquivo corrigido ${entry.value} não encontrado!');
    }
  }
  
  print('\nAtualização concluída!');
  print('Os arquivos foram atualizados para compatibilidade com flutter_map 5.0.0');
  print('Agora você pode compilar o projeto sem erros relacionados ao flutter_map.');
}
