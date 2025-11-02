import 'dart:io';

void main() {
  final file = File('lib/screens/monitoring/monitoring_point_screen.dart');
  final content = file.readAsStringSync();
  
  // Métodos que estão duplicados
  final methodsToRemove = [
    'String _formatDate(DateTime date) {',
    'void _fillOccurrenceForm(MonitoringAlert alert) {',
    'String _generatePlotId(String plotName) {',
    'void _showMonitoringCompletedDialog() {',
    'Future<void> _emergencySave() async {',
  ];
  
  String result = content;
  
  for (final method in methodsToRemove) {
    // Encontrar a primeira ocorrência
    final firstIndex = result.indexOf(method);
    if (firstIndex == -1) continue;
    
    // Encontrar a segunda ocorrência
    final secondIndex = result.indexOf(method, firstIndex + 1);
    if (secondIndex == -1) continue;
    
    // Encontrar o final do segundo método (próximo método ou final da classe)
    int endIndex = result.indexOf('  }', secondIndex);
    if (endIndex != -1) {
      endIndex = result.indexOf('  }', endIndex + 1);
    }
    
    if (endIndex != -1) {
      // Remover o segundo método
      result = result.substring(0, secondIndex) + result.substring(endIndex);
      print('✅ Removido método duplicado: $method');
    }
  }
  
  // Corrigir os throws Exception que estão com argumentos incorretos
  result = result.replaceAll('throw Exception(\'', 'throw Exception(');
  result = result.replaceAll('\');', ');');
  
  // Salvar o arquivo corrigido
  file.writeAsStringSync(result);
  print('✅ Arquivo monitoring_point_screen.dart corrigido com sucesso!');
  print('📊 Tamanho original: ${content.length} caracteres');
  print('📊 Tamanho corrigido: ${result.length} caracteres');
}
