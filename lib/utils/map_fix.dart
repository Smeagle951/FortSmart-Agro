import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Utilitário para corrigir problemas de compatibilidade na migração para MapTiler
void main() async {
  print('Iniciando correção de problemas de compatibilidade...');
  
  // Diretório raiz do projeto
  final projectDir = Directory('.');
  
  // Lista de arquivos a serem verificados
  final filesToCheck = [
    'lib/utils/map_controllers.dart',
    'lib/utils/map_types.dart',
    'lib/widgets/maptiler_plot_map.dart',
    'lib/utils/mapbox_compatibility_adapter.dart',
    'lib/utils/google_maps_compatibility.dart',
    'lib/utils/map_compatibility.dart',
    'lib/utils/map_compatibility_layer.dart',
    'lib/utils/map_global_adapter.dart',
    'lib/utils/map_imports.dart',
  ];
  
  // Verifica e corrige cada arquivo
  for (final filePath in filesToCheck) {
    final file = File(path.join(projectDir.path, filePath));
    if (await file.exists()) {
      print('Verificando ${file.path}...');
      await fixFile(file);
    } else {
      print('Arquivo não encontrado: ${file.path}');
    }
  }
  
  print('Correção concluída!');
}

/// Corrige problemas específicos em cada arquivo
Future<void> fixFile(File file) async {
  final content = await file.readAsString();
  String newContent = content;
  
  final fileName = path.basename(file.path);
  
  switch (fileName) {
    case 'map_controllers.dart':
      // Corrige problemas com target vs latLng
      newContent = content.replaceAll(
        'updateData.target.latitude',
        'updateData.latLng.latitude'
      ).replaceAll(
        'updateData.target.longitude',
        'updateData.latLng.longitude'
      ).replaceAll(
        'updateMove.target.latitude',
        'updateMove.latLng.latitude'
      ).replaceAll(
        'updateMove.target.longitude',
        'updateMove.latLng.longitude'
      );
      
      // Corrige problemas com operadores null-aware
      newContent = newContent.replaceAll(
        'point?.x ?? 0',
        'point.x'
      ).replaceAll(
        'point?.y ?? 0',
        'point.y'
      );
      break;
      
    case 'map_types.dart':
      // Adiciona o getter target para compatibilidade
      if (!content.contains('LatLng get target =>')) {
        newContent = content.replaceAll(
          'class CameraUpdateMove extends CameraUpdate {\n  final LatLng latLng;\n  final double zoom;\n  \n  const CameraUpdateMove(this.latLng, this.zoom);',
          'class CameraUpdateMove extends CameraUpdate {\n  final LatLng latLng;\n  final double zoom;\n  \n  const CameraUpdateMove(this.latLng, this.zoom);\n  \n  /// Getter para compatibilidade com código existente\n  LatLng get target => latLng;'
        );
      }
      break;
      
    case 'maptiler_plot_map.dart':
      // Remove referências a _isMapReady
      newContent = content.replaceAll(
        '_isMapReady = true;',
        '// Atualização do estado concluída'
      );
      break;
  }
  
  // Salva as alterações se o conteúdo foi modificado
  if (newContent != content) {
    await file.writeAsString(newContent);
    print('Arquivo corrigido: ${file.path}');
  } else {
    print('Nenhuma correção necessária para: ${file.path}');
  }
}
