import 'dart:io';

void main() {
  final file = File('lib/screens/farm/farm_profile_screen.dart');
  final content = file.readAsStringSync();
  
  // Encontrar onde começa a segunda declaração de _buildPremiumCard
  final firstDeclaration = content.indexOf('Widget _buildPremiumCard(String title, IconData icon, List<Widget> children) {');
  final secondDeclaration = content.indexOf('Widget _buildPremiumCard(String title, IconData icon, List<Widget> children) {', firstDeclaration + 1);
  
  if (secondDeclaration == -1) {
    print('❌ Não foi possível encontrar a segunda declaração de _buildPremiumCard');
    return;
  }
  
  print('📍 Primeira declaração em: $firstDeclaration');
  print('📍 Segunda declaração em: $secondDeclaration');
  
  // Remover tudo a partir da segunda declaração
  final correctedContent = content.substring(0, secondDeclaration);
  
  // Salvar o arquivo corrigido
  file.writeAsStringSync(correctedContent);
  print('✅ Arquivo farm_profile_screen.dart corrigido com sucesso!');
  print('📊 Tamanho original: ${content.length} caracteres');
  print('📊 Tamanho corrigido: ${correctedContent.length} caracteres');
}
