import '../services/database_reset_service.dart';

/// Script para executar reset seguro do banco de dados
/// Remove apenas culturas de teste sem quebrar dados do usuário
void main() async {
  print('🔧 FortSmart Agro - Reset Seguro do Banco de Dados');
  print('=' * 50);
  
  try {
    // Verificar culturas atuais
    print('📋 Verificando culturas atuais no banco...');
    final culturas = await DatabaseResetService.listAllCultures();
    
    print('\n🌾 Culturas encontradas:');
    for (final cultura in culturas) {
      final nome = cultura['name'] ?? 'Sem nome';
      final id = cultura['id'] ?? 'Sem ID';
      print('   • $nome (ID: $id)');
    }
    
    // Verificar se há culturas de teste
    final hasTest = await DatabaseResetService.hasTestCultures();
    print('\n🔍 Culturas de teste encontradas: ${hasTest ? "SIM" : "NÃO"}');
    
    if (hasTest) {
      print('\n🧹 Executando reset seguro...');
      await DatabaseResetService.safeReset();
      
      print('\n✅ RESET SEGURO CONCLUÍDO!');
      print('\n📱 PRÓXIMOS PASSOS:');
      print('   1. Feche completamente o app');
      print('   2. Reabra o app');
      print('   3. Vá para "Culturas da Fazenda"');
      print('   4. As culturas de teste devem ter desaparecido');
      print('   5. Cana-de-açúcar e Tomate devem aparecer');
      
    } else {
      print('\n✅ Nenhuma cultura de teste encontrada!');
      print('   O banco já está limpo.');
    }
    
  } catch (e) {
    print('\n❌ ERRO durante o reset: $e');
    print('\n💡 SOLUÇÕES ALTERNATIVAS:');
    print('   1. Desinstalar e reinstalar o app');
    print('   2. Limpar dados do app nas configurações');
    print('   3. Usar emulador/dispositivo diferente');
  }
  
  print('\n' + '=' * 50);
  print('🏁 Script finalizado');
}
