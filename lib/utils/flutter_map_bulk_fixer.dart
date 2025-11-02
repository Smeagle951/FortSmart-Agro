import 'dart:io';

/// Script para corrigir automaticamente problemas de compatibilidade com flutter_map 5.0.0
/// Este script percorre todos os arquivos .dart no projeto e faz substituições
/// para corrigir os problemas mais comuns.
void main() async {
  print('Iniciando correção automática de compatibilidade com flutter_map 5.0.0...');
  
  // Diretórios a serem verificados
  final directories = [
    'lib/screens',
    'lib/utils',
    'lib/widgets',
    'lib/modules',
  ];
  
  // Padrões de substituição
  final replacements = [
    // 1. Substituir child por builder em Marker
    {
      'pattern': r'Marker\(\s*(?:[^{]*,)?\s*point:\s*([^,]+),\s*child:',
      'replacement': r'Marker(\n      point: $1,\n      builder: (context) =>',
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
      'pattern': r'(\w+)\.camera\.center',
      'replacement': r'$1.center',
      'description': 'Substituindo .camera.center por .center'
    },
    // 5. Substituir camera.zoom por zoom diretamente
    {
      'pattern': r'(\w+)\.camera\.zoom',
      'replacement': r'$1.zoom',
      'description': 'Substituindo .camera.zoom por .zoom'
    },
    // 6. Comentar backgroundColor em MapOptions
    {
      'pattern': r'(// backgroundColor:\s*[^, // backgroundColor não é suportado em flutter_map 5.0.0]+),',
      'replacement': r'// $1, // backgroundColor não é suportado em flutter_map 5.0.0',
      'description': 'Comentando backgroundColor que não é suportado'
    },
    // 7. Comentar onTap em Polygon
    {
      'pattern': r'(// onTap:\s*[^, // onTap não é suportado em Polygon no flutter_map 5.0.0]+),',
      'replacement': r'// $1, // onTap não é suportado em Polygon no flutter_map 5.0.0',
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
      'pattern': r'fitCamera\(flutter_map\.CameraFit\.bounds\(([^)]+)\)\)',
      'replacement': r'fitBounds($1)',
      'description': 'Substituindo fitCamera por fitBounds'
    },
    // 10. Comentar alignment em Marker
    {
      'pattern': r'(// alignment:\s*[^, // alignment não é suportado em Marker no flutter_map 5.0.0]+),',
      'replacement': r'// $1, // alignment não é suportado em Marker no flutter_map 5.0.0',
      'description': 'Comentando alignment em Marker que não é suportado'
    },
    // 11. Comentar InteractionOptions
    {
      'pattern': r'interactionOptions:\s*const\s*InteractionOptions\([^)]+\),',
      'replacement': r'// interactionOptions não é suportado no flutter_map 5.0.0',
      'description': 'Removendo interactionOptions que não é suportado'
    },
    // 12. Substituir tooltipBgColor por tooltipBackgroundColor em BarTouchTooltipData
    {
      'pattern': r'tooltipBackgroundColor:',
      'replacement': r'tooltipBackgroundColor:',
      'description': 'Substituindo tooltipBgColor por tooltipBackgroundColor em BarTouchTooltipData'
    },
  ];
  
  int filesProcessed = 0;
  int filesModified = 0;
  int totalReplacements = 0;
  
  // Processar todos os arquivos nos diretórios
  for (final directory in directories) {
    final dir = Directory(directory);
    if (!await dir.exists()) {
      print('Diretório não encontrado: $directory');
      continue;
    }
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        filesProcessed++;
        final replacementCount = await processFile(entity.path, replacements);
        if (replacementCount > 0) {
          filesModified++;
          totalReplacements += replacementCount;
        }
      }
    }
  }
  
  print('\nCorreção concluída!');
  print('Arquivos processados: $filesProcessed');
  print('Arquivos modificados: $filesModified');
  print('Total de substituições: $totalReplacements');
  print('\nVerifique os arquivos manualmente para garantir que todas as correções foram aplicadas corretamente.');
  print('Consulte o arquivo lib/utils/FLUTTER_MAP_COMPATIBILITY.md para mais informações sobre as correções.');
}

/// Processa um arquivo aplicando as substituições necessárias
Future<int> processFile(String filePath, List<Map<String, String>> replacements) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('Arquivo não encontrado: $filePath');
    return 0;
  }
  
  try {
    String content = await file.readAsString();
    String originalContent = content;
    int replacementCount = 0;
    
    for (final replacement in replacements) {
      final pattern = RegExp(replacement['pattern']!, multiLine: true);
      final matches = pattern.allMatches(content).toList();
      
      if (matches.isNotEmpty) {
        content = content.replaceAllMapped(pattern, (match) {
          replacementCount++;
          return replacement['replacement']!
              .replaceAllMapped(RegExp(r'\$(\d+)'), (numMatch) {
                final groupNum = int.parse(numMatch.group(1)!);
                return match.group(groupNum) ?? '';
              });
        });
        print('${replacement['description']} em $filePath (${matches.length} ocorrências)');
      }
    }
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Arquivo atualizado: $filePath com $replacementCount substituições');
      return replacementCount;
    }
  } catch (e) {
    print('Erro ao processar arquivo $filePath: $e');
  }
  
  return 0;
}
