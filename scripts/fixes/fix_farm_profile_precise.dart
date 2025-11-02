import 'dart:io';

void main() {
  final file = File('lib/screens/farm/farm_profile_screen.dart');
  final content = file.readAsStringSync();
  
  // Encontrar todas as ocorrências de métodos duplicados
  final methodsToRemove = [
    'Widget _buildHeaderContent() {',
    'Widget _buildQuickStatCard(String title, String value, IconData icon) {',
    'Widget _buildGeneralTab() {',
    'Widget _buildStatisticsTab() {',
    'Widget _buildCertificationsTab() {',
    'Widget _buildLocationTab() {',
    'Widget _buildPremiumTextField(',
    'Widget _buildMetricCard(String title, String value, IconData icon, Color color) {',
    'Widget _buildCertificationItem(String name, String validity, bool isActive) {',
    'Widget _buildDocumentItem(String name, String description, IconData icon) {',
    'Widget _buildInfoItem(String label, String value) {',
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
    int endIndex = result.indexOf('Widget _', secondIndex + 1);
    if (endIndex == -1) {
      endIndex = result.indexOf('  }', secondIndex);
      if (endIndex != -1) {
        endIndex = result.indexOf('  }', endIndex + 1);
      }
    }
    
    if (endIndex != -1) {
      // Remover o segundo método
      result = result.substring(0, secondIndex) + result.substring(endIndex);
      print('✅ Removido método duplicado: $method');
    }
  }
  
  // Salvar o arquivo corrigido
  file.writeAsStringSync(result);
  print('✅ Arquivo farm_profile_screen.dart corrigido com sucesso!');
  print('📊 Tamanho original: ${content.length} caracteres');
  print('📊 Tamanho corrigido: ${result.length} caracteres');
}
