import 'dart:io';

void main() {
  final file = File('lib/screens/monitoring/monitoring_point_screen.dart');
  final content = file.readAsStringSync();
  
  // Encontrar onde termina a classe _MonitoringPointScreenState
  final classEnd = content.indexOf('}\n\n/// Widget para visualização de galeria de imagens');
  if (classEnd == -1) {
    print('❌ Não foi possível encontrar o final da classe _MonitoringPointScreenState');
    return;
  }
  
  // Extrair a parte da classe principal
  final mainClassContent = content.substring(0, classEnd + 1);
  
  // Extrair a classe _ImageGalleryView
  final imageGalleryContent = content.substring(classEnd + 1);
  
  // Verificar se há código sendo executado fora da classe
  final lines = mainClassContent.split('\n');
  final correctedLines = <String>[];
  
  bool insideClass = false;
  bool insideMethod = false;
  int braceCount = 0;
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    
    // Verificar se estamos entrando na classe
    if (line.contains('class _MonitoringPointScreenState extends State<MonitoringPointScreen> {')) {
      insideClass = true;
      correctedLines.add(line);
      continue;
    }
    
    // Se não estamos dentro da classe, pular linhas que não são imports ou declarações
    if (!insideClass) {
      if (line.trim().isEmpty || 
          line.trim().startsWith('import ') ||
          line.trim().startsWith('//') ||
          line.trim().startsWith('///') ||
          line.contains('class MonitoringPointScreen extends StatefulWidget')) {
        correctedLines.add(line);
      }
      continue;
    }
    
    // Contar chaves para detectar métodos
    if (line.contains('{')) {
      braceCount++;
      if (braceCount == 1 && !line.contains('class')) {
        insideMethod = true;
      }
    }
    
    if (line.contains('}')) {
      braceCount--;
      if (braceCount == 0) {
        insideMethod = false;
      }
    }
    
    // Se estamos dentro de um método, adicionar a linha
    if (insideMethod || line.trim().isEmpty || line.startsWith('  ')) {
      correctedLines.add(line);
    } else if (line.trim().startsWith('//') || line.trim().startsWith('///')) {
      correctedLines.add(line);
    }
  }
  
  // Reconstruir o arquivo
  final correctedContent = correctedLines.join('\n') + '\n' + imageGalleryContent;
  
  // Salvar o arquivo corrigido
  file.writeAsStringSync(correctedContent);
  print('✅ Arquivo monitoring_point_screen.dart corrigido com sucesso!');
  print('📊 Tamanho original: ${content.length} caracteres');
  print('📊 Tamanho corrigido: ${correctedContent.length} caracteres');
}
