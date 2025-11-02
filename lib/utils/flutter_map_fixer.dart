import 'dart:io';

void main() async {
  print('Iniciando correção de compatibilidade do Flutter Map 5.0.0...');
  
  // Lista de diretórios para verificar
  final directories = [
    'lib/screens',
    'lib/utils',
    'lib/widgets',
    'lib/modules',
  ];
  
  // Padrões para substituição
  final replacements = [
    // 1. Substituir child por builder em Marker
    {
      'pattern': r'Marker\(\s*(?:[^{]*,)?\s*child:',
      'replacement': r'Marker(\n      point: point,\n      builder:',
      'description': 'Substituindo child por builder em Marker'
    },
    // 2. Substituir initialCenter por center em MapOptions
    {
      'pattern': r'center:',
      'replacement': r'center:',
      'description': 'Substituindo initialCenter por center em MapOptions'
    },
    // 3. Substituir initialZoom por zoom em MapOptions
    {
      'pattern': r'zoom:',
      'replacement': r'zoom:',
      'description': 'Substituindo initialZoom por zoom em MapOptions'
    },
    // 4. Substituir camera.center por center diretamente
    {
      'pattern': r'_controller\.camera\.center',
      'replacement': r'_controller.center',
      'description': 'Substituindo _controller.center por _controller.center'
    },
    // 5. Substituir camera.zoom por zoom diretamente
    {
      'pattern': r'_controller\.camera\.zoom',
      'replacement': r'_controller.zoom',
      'description': 'Substituindo _controller.zoom por _controller.zoom'
    },
    // 6. Substituir backgroundColor por bgColor em MapOptions
    {
      'pattern': r'// backgroundColor:', // backgroundColor não é suportado em flutter_map 5.0.0
      'replacement': r'// backgroundColor: /* Remover este parâmetro, // backgroundColor não é suportado em flutter_map 5.0.0 não é suportado em flutter_map 5.0.0 */ ',
      'description': 'Comentando backgroundColor que não é suportado'
    },
    // 7. Substituir onTap em Polygon por onTap em GestureDetector
    {
      'pattern': r'// onTap:', // onTap não é suportado em Polygon no flutter_map 5.0.0
      'replacement': r'/* onTap não é suportado, use GestureDetector */ //// onTap:', // onTap não é suportado em Polygon no flutter_map 5.0.0
      'description': 'Comentando onTap em Polygon que não é suportado'
    },
    // 8. Substituir Point<num> por CustomPoint<num>
    {
      'pattern': r'dart_math\.Point<num>',
      'replacement': r'CustomPoint<num>',
      'description': 'Substituindo Point<num> por CustomPoint<num>'
    },
    // 9. Substituir fitCamera por fitBounds
    {
      'pattern': r'fitCamera\(flutter_map\.CameraFit\.bounds',
      'replacement': r'fitBounds',
      'description': 'Substituindo fitCamera por fitBounds'
    },
    // 10. Substituir alignment em Marker
    {
      'pattern': r'// alignment:', // alignment não é suportado em Marker no flutter_map 5.0.0
      'replacement': r'/* alignment não é suportado em Marker */ //// alignment:', // alignment não é suportado em Marker no flutter_map 5.0.0
      'description': 'Comentando alignment em Marker que não é suportado'
    },
    // 11. Substituir InteractionOptions
    {
      'pattern': r'interactionOptions:.*?\),',
      'replacement': r'/* interactionOptions não é suportado */ ',
      'description': 'Removendo interactionOptions que não é suportado'
    },
  ];
  
  // Arquivos específicos que precisam ser corrigidos manualmente
  final specificFiles = [
    'lib/screens/talhoes/talhoes_screen_safra.dart',
    'lib/screens/infestacao/mapa_infestacao_screen.dart',
    'lib/modules/planting/widgets/talhao_map_widget.dart',
    'lib/screens/talhoes/talhao_form_safra_screen.dart',
    'lib/widgets/maptiler_map_widget.dart',
    'lib/utils/google_maps_compatibility.dart',
    'lib/utils/map_controllers.dart',
    'lib/utils/map_global_adapter.dart',
    'lib/utils/google_maps_adapter.dart',
    'lib/utils/maptiler_config.dart',
    'lib/utils/google_maps_types.dart',
  ];
  
  // Processar arquivos específicos primeiro
  for (final filePath in specificFiles) {
    await processFile(filePath, replacements);
  }
  
  // Processar todos os arquivos nos diretórios
  for (final directory in directories) {
    await processDirectory(directory, replacements);
  }
  
  print('\nCorreção concluída!');
  print('Agora você deve verificar manualmente os arquivos que ainda podem ter problemas.');
  print('Consulte o arquivo lib/utils/FLUTTER_MAP_COMPATIBILITY.md para mais informações.');
}

Future<void> processDirectory(String directory, List<Map<String, String>> replacements) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    print('Diretório não encontrado: $directory');
    return;
  }
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await processFile(entity.path, replacements);
    }
  }
}

Future<void> processFile(String filePath, List<Map<String, String>> replacements) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('Arquivo não encontrado: $filePath');
    return;
  }
  
  try {
    String content = await file.readAsString();
    bool changed = false;
    
    for (final replacement in replacements) {
      final pattern = RegExp(replacement['pattern']!);
      if (pattern.hasMatch(content)) {
        content = content.replaceAll(pattern, replacement['replacement']!);
        print('${replacement['description']} em $filePath');
        changed = true;
      }
    }
    
    if (changed) {
      await file.writeAsString(content);
      print('Arquivo atualizado: $filePath');
    }
  } catch (e) {
    print('Erro ao processar arquivo $filePath: $e');
  }
}

// Função para corrigir manualmente arquivos específicos com problemas complexos
Future<void> fixSpecificFiles() async {
  // Aqui você pode adicionar correções específicas para arquivos que precisam de mais atenção
}
