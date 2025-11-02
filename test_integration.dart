import 'lib/tests/quick_integration_test.dart';

/// Arquivo de teste executável para verificar integração entre módulos
/// Execute com: dart test_integration.dart
void main() async {
  print('🚀 === TESTE DE INTEGRAÇÃO - MÓDULOS ===\n');
  
  try {
    // Executar teste rápido
    await runQuickIntegrationTest();
    
    print('\n✅ === TESTE CONCLUÍDO COM SUCESSO ===');
    print('🎯 Todos os módulos estão funcionando perfeitamente!');
    print('📊 Monitoramento → Mapa de Infestação → Catálogo de Organismos');
    
  } catch (e) {
    print('\n❌ === ERRO NO TESTE ===');
    print('Erro: $e');
    print('\n🔧 Verifique se todos os módulos estão implementados corretamente.');
  }
}
