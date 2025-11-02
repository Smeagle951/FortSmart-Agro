import 'culture_organisms_monitoring_service.dart';
import '../utils/enums.dart';

/// Arquivo de teste para verificar o carregamento de organismos
/// Execute este teste para verificar se o sistema está funcionando corretamente
class TestOrganismLoading {
  static Future<void> runTest() async {
    print('🧪 Iniciando teste de carregamento de organismos...');
    
    final service = CultureOrganismsMonitoringService();
    
    try {
      // Teste 0: Verificar obtenção do nome real da cultura
      print('\n📋 Teste 0: Obtendo nome real da cultura Soja (ID: 1)');
      final nomeSoja = await service.getCultureNameById('1');
      print('✅ Nome da cultura encontrado: $nomeSoja');
      
      final nomeMilho = await service.getCultureNameById('2');
      print('✅ Nome da cultura encontrado: $nomeMilho');
      // Teste 1: Carregar pragas do módulo culturas (sem passar nome - será obtido automaticamente)
      print('\n📋 Teste 1: Carregando pragas do módulo culturas da fazenda');
      final pragasSoja = await service.getOrganismsByCultureAndType(
        culturaId: '1',
        tipo: OccurrenceType.pest,
      );
      print('✅ Encontradas ${pragasSoja.length} pragas do módulo culturas para ${pragasSoja.isNotEmpty ? pragasSoja.first.culturaNome : 'Soja'}');
      for (final praga in pragasSoja.take(3)) {
        print('  - ${praga.nome} (${praga.nomeCientifico ?? 'N/A'}) - ${praga.categoria ?? 'Sem categoria'}');
      }
      
      // Teste 2: Carregar doenças do módulo culturas
      print('\n📋 Teste 2: Carregando doenças do módulo culturas da fazenda');
      final doencasMilho = await service.getOrganismsByCultureAndType(
        culturaId: '2',
        tipo: OccurrenceType.disease,
      );
      print('✅ Encontradas ${doencasMilho.length} doenças do módulo culturas para ${doencasMilho.isNotEmpty ? doencasMilho.first.culturaNome : 'Milho'}');
      for (final doenca in doencasMilho.take(3)) {
        print('  - ${doenca.nome} (${doenca.nomeCientifico ?? 'N/A'}) - ${doenca.categoria ?? 'Sem categoria'}');
      }
      
      // Teste 3: Carregar plantas daninhas do módulo culturas
      print('\n📋 Teste 3: Carregando plantas daninhas do módulo culturas da fazenda');
      final daninhasAlgodao = await service.getOrganismsByCultureAndType(
        culturaId: '4',
        tipo: OccurrenceType.weed,
      );
      print('✅ Encontradas ${daninhasAlgodao.length} plantas daninhas do módulo culturas para ${daninhasAlgodao.isNotEmpty ? daninhasAlgodao.first.culturaNome : 'Algodão'}');
      for (final daninha in daninhasAlgodao.take(3)) {
        print('  - ${daninha.nome} (${daninha.nomeCientifico ?? 'N/A'}) - ${daninha.categoria ?? 'Sem categoria'}');
      }
      
      // Teste 4: Busca inteligente no módulo culturas
      print('\n📋 Teste 4: Busca inteligente por "lagarta" no módulo culturas');
      final buscaResultado = await service.searchOrganisms(query: 'lagarta');
      print('✅ Encontrados ${buscaResultado.length} organismos do módulo culturas com "lagarta"');
      for (final resultado in buscaResultado.take(3)) {
        print('  - ${resultado.nome} (${resultado.culturaNome})');
      }
      
      print('\n🎉 Todos os testes concluídos com sucesso!');
      
    } catch (e) {
      print('❌ Erro durante o teste: $e');
    }
  }
}

/// Para executar o teste, chame:
/// TestOrganismLoading.runTest();
