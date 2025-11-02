import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../services/complete_integration_service.dart';
import '../utils/enums.dart';

/// Exemplo de uso da integração completa entre módulos
/// Demonstra como resolver o problema de conectividade entre Monitoramento, Catálogo e Mapa de Infestação
class IntegrationUsageExample {
  final CompleteIntegrationService _integrationService = CompleteIntegrationService();

  /// Exemplo 1: Processar dados de monitoramento e integrar com todos os módulos
  Future<void> exampleProcessMonitoringData() async {
    try {
      // 1. Inicializar serviços
      await _integrationService.initialize();
      
      // 2. Criar dados de monitoramento de exemplo
      final monitoring = _createExampleMonitoring();
      
      // 3. Processar integração completa
      final result = await _integrationService.processCompleteIntegration(monitoring);
      
      print('✅ Integração concluída:');
      print('   - Status: ${result['status']}');
      print('   - Total de pontos: ${result['summary']['total_pontos_processados']}');
      print('   - Organismos detectados: ${result['summary']['total_organismos_detectados']}');
      print('   - Alertas gerados: ${result['summary']['total_alertas_gerados']}');
      print('   - Nível geral: ${result['summary']['nivel_geral_infestacao']}');
      
    } catch (e) {
      print('❌ Erro na integração: $e');
    }
  }

  /// Exemplo 2: Obter dados para o mapa de infestação
  Future<void> exampleGetInfestationMapData() async {
    try {
      // Obter dados do mapa para um talhão específico
      final mapData = await _integrationService.getInfestationMapData(
        talhaoId: '1',
        fromDate: DateTime.now().subtract(const Duration(days: 30)),
        toDate: DateTime.now(),
      );
      
      print('🗺️ Dados do mapa de infestação:');
      print('   - Total de talhões: ${mapData['total_talhoes']}');
      print('   - Total de pontos: ${mapData['total_pontos']}');
      print('   - Total de organismos: ${mapData['total_organismos']}');
      print('   - Nível geral: ${mapData['estatisticas_gerais']['nivel_geral']}');
      
      // Mostrar dados por talhão
      final talhoes = mapData['talhoes'] as List;
      for (final talhao in talhoes) {
        print('   📍 Talhão ${talhao['talhao_nome']}:');
        print('      - Nível: ${talhao['nivel_geral']} (${talhao['cor_geral']})');
        print('      - Pontos: ${talhao['total_pontos']}');
        print('      - Organismos: ${talhao['total_organismos']}');
      }
      
    } catch (e) {
      print('❌ Erro ao obter dados do mapa: $e');
    }
  }

  /// Exemplo 3: Obter alertas de infestação
  Future<void> exampleGetInfestationAlerts() async {
    try {
      // Obter alertas de alto e crítico
      final alerts = await _integrationService.getInfestationAlerts(
        nivel: 'ALTO',
        limit: 10,
      );
      
      print('🚨 Alertas de infestação:');
      for (final alert in alerts) {
        print('   ⚠️ ${alert['organismo_nome']} em ${alert['talhao_nome']}');
        print('      - Nível: ${alert['nivel']}');
        print('      - Quantidade: ${alert['quantidade']} ${alert['unidade']}');
        print('      - Data: ${alert['data']}');
        print('      - Descrição: ${alert['descricao']}');
      }
      
    } catch (e) {
      print('❌ Erro ao obter alertas: $e');
    }
  }

  /// Exemplo 4: Obter estatísticas de organismos
  Future<void> exampleGetOrganismStatistics() async {
    try {
      // Obter estatísticas de todos os organismos
      final statistics = await _integrationService.getOrganismStatistics();
      
      print('📊 Estatísticas de organismos:');
      for (final stat in statistics.take(5)) {
        print('   🐛 ${stat['organismo_nome']} (${stat['cultura_nome']})');
        print('      - Ocorrências: ${stat['total_ocorrencias']}');
        print('      - Média de infestação: ${stat['media_infestacao']?.toStringAsFixed(1)}%');
        print('      - Nível mais comum: ${stat['nivel_mais_comum']}');
        print('      - Tendência: ${stat['tendencia']}');
        print('      - Confiabilidade: ${(stat['confiabilidade'] * 100)?.toStringAsFixed(1)}%');
      }
      
    } catch (e) {
      print('❌ Erro ao obter estatísticas: $e');
    }
  }

  /// Exemplo 5: Obter organismos mais problemáticos
  Future<void> exampleGetMostProblematicOrganisms() async {
    try {
      // Obter os 5 organismos mais problemáticos
      final problematic = await _integrationService.getMostProblematicOrganisms(limit: 5);
      
      print('⚠️ Organismos mais problemáticos:');
      for (final organism in problematic) {
        print('   🔴 ${organism['organismo_nome']} (${organism['cultura_nome']})');
        print('      - Nível: ${organism['nivel_mais_comum']}');
        print('      - Ocorrências: ${organism['total_ocorrencias']}');
        print('      - Média: ${organism['media_infestacao']?.toStringAsFixed(1)}%');
        print('      - Tendência: ${organism['tendencia']}');
      }
      
    } catch (e) {
      print('❌ Erro ao obter organismos problemáticos: $e');
    }
  }

  /// Exemplo 6: Obter tendências por cultura
  Future<void> exampleGetTrendsByCrop() async {
    try {
      // Obter tendências por cultura
      final trends = await _integrationService.getTrendsByCrop();
      
      print('📈 Tendências por cultura:');
      final trendsByCrop = trends['tendencias_por_cultura'] as List;
      for (final trend in trendsByCrop) {
        print('   🌾 ${trend['cultura_nome']}:');
        print('      - Total de organismos: ${trend['total_organismos']}');
        print('      - Média geral: ${trend['media_geral_infestacao']?.toStringAsFixed(1)}%');
        print('      - Tendência crescente: ${trend['tendencia_crescente']}');
        print('      - Tendência decrescente: ${trend['tendencia_decrescente']}');
        print('      - Tendência estável: ${trend['tendencia_estavel']}');
        print('      - Organismos problemáticos: ${trend['organismos_problematicos']}');
      }
      
    } catch (e) {
      print('❌ Erro ao obter tendências: $e');
    }
  }

  /// Exemplo 7: Processar múltiplos monitoramentos
  Future<void> exampleProcessMultipleMonitorings() async {
    try {
      // Criar múltiplos monitoramentos de exemplo
      final monitorings = [
        _createExampleMonitoring(),
        _createExampleMonitoring2(),
        _createExampleMonitoring3(),
      ];
      
      // Processar em lote
      final results = await _integrationService.processMultipleMonitorings(monitorings);
      
      print('🔄 Processamento em lote concluído:');
      final successCount = results.where((r) => r['status'] == 'SUCCESS').length;
      final errorCount = results.where((r) => r['status'] == 'ERROR').length;
      
      print('   - Sucessos: $successCount');
      print('   - Erros: $errorCount');
      
      for (final result in results) {
        if (result['status'] == 'SUCCESS') {
          print('   ✅ ${result['monitoring_id']}: ${result['summary']['total_organismos_detectados']} organismos');
        } else {
          print('   ❌ ${result['monitoring_id']}: ${result['error']}');
        }
      }
      
    } catch (e) {
      print('❌ Erro no processamento em lote: $e');
    }
  }

  /// Exemplo 8: Obter dados de integração entre módulos
  Future<void> exampleGetModulesIntegrationData() async {
    try {
      // Obter dados de integração
      final integrationData = await _integrationService.getModulesIntegrationData(
        talhaoId: '1',
        fromDate: DateTime.now().subtract(const Duration(days: 7)),
        toDate: DateTime.now(),
      );
      
      print('🔗 Dados de integração entre módulos:');
      print('   - Total de registros: ${integrationData.length}');
      
      for (final data in integrationData.take(3)) {
        print('   📍 ${data['organismo_nome']} em ${data['talhao_nome']}');
        print('      - Nível: ${data['nivel_intensidade']}');
        print('      - Quantidade: ${data['quantidade_detectada']} ${data['unidade_medida']}');
        print('      - Cor do mapa: ${data['cor_mapa']}');
        print('      - Data: ${data['data_monitoramento']}');
      }
      
    } catch (e) {
      print('❌ Erro ao obter dados de integração: $e');
    }
  }

  /// Cria monitoramento de exemplo 1
  Monitoring _createExampleMonitoring() {
    final points = [
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão 1',
        cropId: 1,
        cropName: 'Soja',
        latitude: -15.7801,
        longitude: -47.9292,
        occurrences: [
          Occurrence(
            type: OccurrenceType.pest,
            name: 'Lagarta-da-soja',
            infestationIndex: 15.0,
            affectedSections: [PlantSection.upper, PlantSection.middle],
            notes: 'Infestação moderada no terço superior',
          ),
          Occurrence(
            type: OccurrenceType.disease,
            name: 'Ferrugem-asiática',
            infestationIndex: 8.0,
            affectedSections: [PlantSection.middle],
            notes: 'Manchas nas folhas do terço médio',
          ),
        ],
      ),
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão 1',
        cropId: 1,
        cropName: 'Soja',
        latitude: -15.7802,
        longitude: -47.9293,
        occurrences: [
          Occurrence(
            type: OccurrenceType.pest,
            name: 'Percevejo-marrom',
            infestationIndex: 25.0,
            affectedSections: [PlantSection.upper],
            notes: 'Alta infestação de percevejos',
          ),
        ],
      ),
    ];

    return Monitoring(
      date: DateTime.now(),
      plotId: 1,
      plotName: 'Talhão 1',
      cropId: 1,
      cropName: 'Soja',
      route: [],
      points: points,
    );
  }

  /// Cria monitoramento de exemplo 2
  Monitoring _createExampleMonitoring2() {
    final points = [
      MonitoringPoint(
        plotId: 2,
        plotName: 'Talhão 2',
        cropId: 2,
        cropName: 'Milho',
        latitude: -15.7803,
        longitude: -47.9294,
        occurrences: [
          Occurrence(
            type: OccurrenceType.pest,
            name: 'Lagarta-do-cartucho',
            infestationIndex: 35.0,
            affectedSections: [PlantSection.upper],
            notes: 'Infestação alta no cartucho',
          ),
        ],
      ),
    ];

    return Monitoring(
      date: DateTime.now().subtract(const Duration(days: 1)),
      plotId: 2,
      plotName: 'Talhão 2',
      cropId: 2,
      cropName: 'Milho',
      route: [],
      points: points,
    );
  }

  /// Cria monitoramento de exemplo 3
  Monitoring _createExampleMonitoring3() {
    final points = [
      MonitoringPoint(
        plotId: 3,
        plotName: 'Talhão 3',
        cropId: 3,
        cropName: 'Algodão',
        latitude: -15.7804,
        longitude: -47.9295,
        occurrences: [
          Occurrence(
            type: OccurrenceType.pest,
            name: 'Bicudo-do-algodoeiro',
            infestationIndex: 45.0,
            affectedSections: [PlantSection.upper],
            notes: 'Infestação crítica de bicudo',
          ),
        ],
      ),
    ];

    return Monitoring(
      date: DateTime.now().subtract(const Duration(days: 2)),
      plotId: 3,
      plotName: 'Talhão 3',
      cropId: 3,
      cropName: 'Algodão',
      route: [],
      points: points,
    );
  }

  /// Executa todos os exemplos
  Future<void> runAllExamples() async {
    print('🚀 Iniciando exemplos de integração...\n');
    
    await exampleProcessMonitoringData();
    print('');
    
    await exampleGetInfestationMapData();
    print('');
    
    await exampleGetInfestationAlerts();
    print('');
    
    await exampleGetOrganismStatistics();
    print('');
    
    await exampleGetMostProblematicOrganisms();
    print('');
    
    await exampleGetTrendsByCrop();
    print('');
    
    await exampleProcessMultipleMonitorings();
    print('');
    
    await exampleGetModulesIntegrationData();
    print('');
    
    print('✅ Todos os exemplos executados com sucesso!');
  }
}
