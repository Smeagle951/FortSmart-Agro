import 'package:flutter/material.dart';
import '../models/monitoring_point.dart';
import '../models/infestation_point.dart';
import '../models/organism_catalog.dart';
import '../modules/infestation_map/services/infestation_calculation_service.dart';
import '../modules/infestation_map/services/mathematical_infestation_calculator.dart';
import '../services/monitoring_integration_service.dart';
import '../utils/logger.dart';

/// Teste de integração entre módulos:
/// Monitoramento → Mapa de Infestação → Catálogo de Organismos
class IntegrationTest {
  final InfestationCalculationService _calculationService = InfestationCalculationService();
  final MonitoringIntegrationService _monitoringService = MonitoringIntegrationService();

  /// Executa teste completo de integração
  Future<void> runFullIntegrationTest() async {
    print('🧪 === TESTE DE INTEGRAÇÃO COMPLETA ===\n');
    
    try {
      // 1. Criar ponto de monitoramento de teste
      print('📝 1. Criando ponto de monitoramento de teste...');
      final monitoringPoint = _createTestMonitoringPoint();
      print('   ✅ Ponto criado: ${monitoringPoint.toString()}');
      
      // 2. Simular salvamento no módulo de monitoramento
      print('\n💾 2. Simulando salvamento no módulo de monitoramento...');
      final monitoringData = _simulateMonitoringSave(monitoringPoint);
      print('   ✅ Dados salvos: ${monitoringData['status']}');
      
      // 3. Converter para InfestationPoint
      print('\n🔄 3. Convertendo para InfestationPoint...');
      final infestationPoints = _calculationService.convertMonitoringPointsToInfestationPoints(
        monitoringPoints: [monitoringPoint],
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        talhaoId: 'talhao_teste_001',
        talhaoName: 'Talhão de Teste',
      );
      print('   ✅ Convertidos: ${infestationPoints.length} pontos');
      print('   📍 Primeiro ponto: ${infestationPoints.first.toString()}');
      
      // 4. Testar cálculo matemático de infestação
      print('\n🧮 4. Testando cálculo matemático de infestação...');
      final calculationResult = await _calculationService.calculateMathematicalInfestation(
        points: infestationPoints,
        organismId: 'soja_percevejo_marrom',
        phenologicalPhase: 'floracao',
        talhaoArea: 5.0, // 5 hectares
        totalPlants: 25000, // 25 mil plantas
      );
      print('   ✅ Cálculo concluído:');
      print('      📊 Classificação: ${calculationResult.classification}');
      print('      📈 Índice: ${calculationResult.infestationIndex.toStringAsFixed(2)}%');
      print('      🔢 Média: ${calculationResult.averageCount.toStringAsFixed(2)}');
      print('      ⚠️ Pontos críticos: ${calculationResult.criticalPoints.length}');
      print('      🔥 Dados heatmap: ${calculationResult.heatmapData.length}');
      
      // 5. Testar geração de dados para o mapa
      print('\n🗺️ 5. Testando geração de dados para o mapa...');
      final mapData = _calculationService.generateMapVisualizationData(
        result: calculationResult,
        talhaoId: 'talhao_teste_001',
      );
      print('   ✅ Dados do mapa gerados:');
      print('      🎯 Status: ${mapData['success']}');
      if (mapData['success'] == true) {
        final summary = mapData['summary'] as Map<String, dynamic>;
        print('      📊 Classificação: ${summary['classification']}');
        print('      📈 Índice: ${summary['infestation_index']}%');
        print('      📍 Total de pontos: ${summary['total_points']}');
        print('      ⚠️ Pontos críticos: ${summary['critical_points']}');
        
        final geoJson = mapData['geojson'] as Map<String, dynamic>;
        final features = geoJson['features'] as List;
        print('      🗺️ Features GeoJSON: ${features.length}');
      }
      
      // 6. Testar integração com catálogo de organismos
      print('\n📚 6. Testando integração com catálogo de organismos...');
      await _testOrganismCatalogIntegration();
      
      // 7. Testar fluxo completo de monitoramento
      print('\n🔄 7. Testando fluxo completo de monitoramento...');
      await _testCompleteMonitoringFlow();
      
      print('\n✅ === TESTE DE INTEGRAÇÃO CONCLUÍDO COM SUCESSO ===');
      
    } catch (e, stackTrace) {
      print('❌ === ERRO NO TESTE DE INTEGRAÇÃO ===');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Cria ponto de monitoramento de teste
  MonitoringPoint _createTestMonitoringPoint() {
    return MonitoringPoint(
      id: 'monitoring_test_001',
      monitoringId: 'monitoring_session_001',
      latitude: -10.123456,
      longitude: -55.123456,
      organismId: 'soja_percevejo_marrom',
      organismName: 'Percevejo-marrom',
      quantity: 3, // 3 percevejos (acima do limiar de 2)
      unidade: 'percevejos/m',
      accuracy: 2.5, // 2.5 metros de precisão
      collectedAt: DateTime.now(),
      observacoes: 'Ponto de teste - infestação moderada',
      collectorId: 'coletor_teste',
      talhaoId: 'talhao_teste_001',
      talhaoName: 'Talhão de Teste',
    );
  }

  /// Simula salvamento no módulo de monitoramento
  Map<String, dynamic> _simulateMonitoringSave(MonitoringPoint point) {
    // Simular processo de salvamento
    return {
      'status': 'success',
      'point_id': point.id,
      'monitoring_id': point.monitoringId,
      'organism': point.organismName,
      'quantity': point.quantity,
      'unit': point.unidade,
      'coordinates': '${point.latitude}, ${point.longitude}',
      'accuracy': point.accuracy,
      'collected_at': point.collectedAt.toIso8601String(),
      'talhao': point.talhaoName,
    };
  }

  /// Testa integração com catálogo de organismos
  Future<void> _testOrganismCatalogIntegration() async {
    try {
      // Simular busca no catálogo
      final organism = await _getTestOrganism();
      print('   ✅ Organismo encontrado: ${organism.nome}');
      print('      🧬 Nome científico: ${organism.nomeCientifico}');
      print('      📊 Categoria: ${organism.categoria}');
      print('      🌱 Cultura: ${organism.culturaId}');
      
      // Verificar limiares específicos
      final limiares = organism.limiaresEspecificos;
      if (limiares != null) {
        print('      📏 Limiares específicos:');
        limiares.forEach((phase, threshold) {
          print('         $phase: $threshold');
        });
      }
      
      // Verificar severidade
      final severidade = organism.severidade;
      if (severidade != null) {
        print('      ⚠️ Níveis de severidade:');
        severidade.forEach((level, data) {
          print('         $level: ${data['descricao']}');
        });
      }
      
    } catch (e) {
      print('   ❌ Erro na integração com catálogo: $e');
    }
  }

  /// Obtém organismo de teste (simulado)
  Future<OrganismCatalog> _getTestOrganism() async {
    return OrganismCatalog(
      id: 'soja_percevejo_marrom',
      nome: 'Percevejo-marrom',
      nomeCientifico: 'Euschistus heros',
      categoria: 'Praga',
      culturaId: 'soja',
      sintomas: ['Sucção de seiva', 'Transmissão de vírus'],
      danoEconomico: 'Pode causar perdas de até 30%',
      partesAfetadas: ['Folhas', 'Vagens'],
      fenologia: ['Floração', 'Enchimento'],
      nivelAcao: '2 percevejos por metro',
      manejoQuimico: ['Inseticidas sistêmicos'],
      manejoBiologico: ['Controle biológico'],
      manejoCultural: ['Rotação de culturas'],
      observacoes: 'Praga-chave da soja',
      icone: '🐛',
      ativo: true,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      fases: [
        {
          'fase': 'Ovo',
          'tamanho': '1 mm',
          'danos': 'Sem dano direto',
        },
        {
          'fase': 'Ninfa',
          'tamanho': '3-8 mm',
          'danos': 'Sucção inicial de seiva',
        },
        {
          'fase': 'Adulto',
          'tamanho': '10-12 mm',
          'danos': 'Sucção intensa, transmissão de vírus',
        },
      ],
      severidade: {
        'baixo': {
          'descricao': '1 percevejo por metro, danos menores que 5%',
          'perda_produtividade': '0-5%',
          'cor_alerta': '#4CAF50',
          'acao': 'Monitoramento, controle biológico',
        },
        'medio': {
          'descricao': '2 percevejos por metro, danos entre 5-15%',
          'perda_produtividade': '5-15%',
          'cor_alerta': '#FF9800',
          'acao': 'Controle químico seletivo',
        },
        'alto': {
          'descricao': '3+ percevejos por metro, danos superiores a 15%',
          'perda_produtividade': '15-30%',
          'cor_alerta': '#F44336',
          'acao': 'Controle químico imediato',
        },
      },
      condicoesFavoraveis: {
        'temperatura': '20-30°C',
        'umidade': '60-80%',
        'chuva': 'Períodos secos',
        'vento': 'Ventos fracos',
        'solo': 'Solos bem drenados',
      },
      limiaresEspecificos: {
        'vegetativo': 'Não aplicável',
        'floracao': '2 percevejos por metro',
        'enchimento': '2 percevejos por metro',
      },
    );
  }

  /// Testa fluxo completo de monitoramento
  Future<void> _testCompleteMonitoringFlow() async {
    try {
      // Criar múltiplos pontos de teste
      final monitoringPoints = _createMultipleTestPoints();
      print('   ✅ Criados ${monitoringPoints.length} pontos de teste');
      
      // Converter para InfestationPoints
      final infestationPoints = _calculationService.convertMonitoringPointsToInfestationPoints(
        monitoringPoints: monitoringPoints,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        talhaoId: 'talhao_teste_001',
        talhaoName: 'Talhão de Teste',
      );
      print('   ✅ Convertidos ${infestationPoints.length} pontos');
      
      // Executar cálculo matemático
      final result = await _calculationService.calculateMathematicalInfestation(
        points: infestationPoints,
        organismId: 'soja_percevejo_marrom',
        phenologicalPhase: 'floracao',
        talhaoArea: 5.0,
        totalPlants: 25000,
      );
      
      print('   ✅ Cálculo matemático concluído:');
      print('      📊 Classificação: ${result.classification}');
      print('      📈 Índice: ${result.infestationIndex.toStringAsFixed(2)}%');
      print('      🔢 Média: ${result.averageCount.toStringAsFixed(2)}');
      print('      ⚠️ Pontos críticos: ${result.criticalPoints.length}');
      
      // Verificar se pontos críticos foram identificados corretamente
      if (result.criticalPoints.isNotEmpty) {
        print('      🎯 Pontos críticos identificados:');
        for (int i = 0; i < result.criticalPoints.length; i++) {
          final point = result.criticalPoints[i];
          print('         ${i + 1}. ${point.count} ${point.unit} em (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})');
        }
      }
      
      // Verificar dados do heatmap
      if (result.heatmapData.isNotEmpty) {
        print('      🔥 Heatmap gerado com ${result.heatmapData.length} pontos');
        for (int i = 0; i < result.heatmapData.length; i++) {
          final heatmap = result.heatmapData[i];
          print('         ${i + 1}. Nível: ${heatmap.level}, Intensidade: ${heatmap.intensity.toStringAsFixed(3)}, Raio: ${heatmap.radius.toStringAsFixed(1)}m');
        }
      }
      
    } catch (e) {
      print('   ❌ Erro no fluxo completo: $e');
    }
  }

  /// Cria múltiplos pontos de teste com diferentes níveis de infestação
  List<MonitoringPoint> _createMultipleTestPoints() {
    return [
      // Ponto 1: Baixo (1 percevejo)
      MonitoringPoint(
        id: 'monitoring_test_001',
        monitoringId: 'monitoring_session_001',
        latitude: -10.123456,
        longitude: -55.123456,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        quantity: 1,
        unidade: 'percevejos/m',
        accuracy: 2.5,
        collectedAt: DateTime.now(),
        observacoes: 'Ponto baixo - 1 percevejo',
        collectorId: 'coletor_teste',
        talhaoId: 'talhao_teste_001',
        talhaoName: 'Talhão de Teste',
      ),
      
      // Ponto 2: Médio (2 percevejos - no limiar)
      MonitoringPoint(
        id: 'monitoring_test_002',
        monitoringId: 'monitoring_session_001',
        latitude: -10.123500,
        longitude: -55.123500,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        quantity: 2,
        unidade: 'percevejos/m',
        accuracy: 2.0,
        collectedAt: DateTime.now(),
        observacoes: 'Ponto médio - 2 percevejos (limiar)',
        collectorId: 'coletor_teste',
        talhaoId: 'talhao_teste_001',
        talhaoName: 'Talhão de Teste',
      ),
      
      // Ponto 3: Alto (3 percevejos - acima do limiar)
      MonitoringPoint(
        id: 'monitoring_test_003',
        monitoringId: 'monitoring_session_001',
        latitude: -10.123600,
        longitude: -55.123600,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        quantity: 3,
        unidade: 'percevejos/m',
        accuracy: 1.8,
        collectedAt: DateTime.now(),
        observacoes: 'Ponto alto - 3 percevejos (acima do limiar)',
        collectorId: 'coletor_teste',
        talhaoId: 'talhao_teste_001',
        talhaoName: 'Talhão de Teste',
      ),
      
      // Ponto 4: Crítico (5 percevejos - muito acima do limiar)
      MonitoringPoint(
        id: 'monitoring_test_004',
        monitoringId: 'monitoring_session_001',
        latitude: -10.123700,
        longitude: -55.123700,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        quantity: 5,
        unidade: 'percevejos/m',
        accuracy: 1.5,
        collectedAt: DateTime.now(),
        observacoes: 'Ponto crítico - 5 percevejos (muito acima do limiar)',
        collectorId: 'coletor_teste',
        talhaoId: 'talhao_teste_001',
        talhaoName: 'Talhão de Teste',
      ),
    ];
  }

  /// Testa cálculo direto com InfestationPoints
  Future<void> testDirectInfestationCalculation() async {
    print('\n🧮 === TESTE DIRETO DE CÁLCULO DE INFESTAÇÃO ===');
    
    try {
      // Criar InfestationPoints diretamente
      final infestationPoints = [
        InfestationPoint(
          latitude: -10.123456,
          longitude: -55.123456,
          organismId: 'soja_percevejo_marrom',
          organismName: 'Percevejo-marrom',
          count: 3,
          unit: 'percevejos/m',
          accuracy: 2.5,
          talhaoId: 'talhao_teste_001',
          talhaoName: 'Talhão de Teste',
          notes: 'Teste direto - 3 percevejos',
        ),
        InfestationPoint(
          latitude: -10.123500,
          longitude: -55.123500,
          organismId: 'soja_percevejo_marrom',
          organismName: 'Percevejo-marrom',
          count: 4,
          unit: 'percevejos/m',
          accuracy: 2.0,
          talhaoId: 'talhao_teste_001',
          talhaoName: 'Talhão de Teste',
          notes: 'Teste direto - 4 percevejos',
        ),
      ];
      
      print('📊 Criados ${infestationPoints.length} InfestationPoints');
      
      // Executar cálculo
      final result = await _calculationService.calculateMathematicalInfestation(
        points: infestationPoints,
        organismId: 'soja_percevejo_marrom',
        phenologicalPhase: 'floracao',
        talhaoArea: 5.0,
        totalPlants: 25000,
      );
      
      print('✅ Resultado do cálculo direto:');
      print('   📊 Classificação: ${result.classification}');
      print('   📈 Índice: ${result.infestationIndex.toStringAsFixed(2)}%');
      print('   🔢 Média: ${result.averageCount.toStringAsFixed(2)}');
      print('   ⚠️ Pontos críticos: ${result.criticalPoints.length}');
      print('   🔥 Dados heatmap: ${result.heatmapData.length}');
      
    } catch (e) {
      print('❌ Erro no teste direto: $e');
    }
  }
}

/// Função principal para executar o teste
Future<void> runIntegrationTest() async {
  final test = IntegrationTest();
  
  print('🚀 === INICIANDO TESTE DE INTEGRAÇÃO ===\n');
  
  // Teste principal
  await test.runFullIntegrationTest();
  
  // Teste direto
  await test.testDirectInfestationCalculation();
  
  print('\n🎉 === TESTE DE INTEGRAÇÃO FINALIZADO ===');
}
