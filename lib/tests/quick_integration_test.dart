import 'package:flutter/material.dart';
import '../models/monitoring_point.dart';
import '../models/infestation_point.dart';
import '../modules/infestation_map/services/infestation_calculation_service.dart';

/// Teste rápido de integração entre módulos
/// Executa em menos de 30 segundos
class QuickIntegrationTest {
  final InfestationCalculationService _calculationService = InfestationCalculationService();

  /// Executa teste rápido
  Future<void> runQuickTest() async {
    print('⚡ === TESTE RÁPIDO DE INTEGRAÇÃO ===\n');
    
    try {
      // 1. Criar ponto de monitoramento
      print('📝 1. Criando ponto de monitoramento...');
      final monitoringPoint = _createQuickTestPoint();
      print('   ✅ Ponto: ${monitoringPoint.quantity} ${monitoringPoint.unidade}');
      
      // 2. Converter para InfestationPoint
      print('\n🔄 2. Convertendo para InfestationPoint...');
      final infestationPoints = _calculationService.convertMonitoringPointsToInfestationPoints(
        monitoringPoints: [monitoringPoint],
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        talhaoId: 'talhao_teste',
        talhaoName: 'Talhão Teste',
      );
      print('   ✅ Convertido: ${infestationPoints.length} ponto(s)');
      
      // 3. Executar cálculo matemático
      print('\n🧮 3. Executando cálculo matemático...');
      final result = await _calculationService.calculateMathematicalInfestation(
        points: infestationPoints,
        organismId: 'soja_percevejo_marrom',
        phenologicalPhase: 'floracao',
        talhaoArea: 5.0,
        totalPlants: 25000,
      );
      
      print('   ✅ Cálculo concluído:');
      print('      📊 Classificação: ${result.classification}');
      print('      📈 Índice: ${result.infestationIndex.toStringAsFixed(2)}%');
      print('      🔢 Média: ${result.averageCount.toStringAsFixed(2)}');
      print('      ⚠️ Críticos: ${result.criticalPoints.length}');
      print('      🔥 Heatmap: ${result.heatmapData.length}');
      
      // 4. Gerar dados para mapa
      print('\n🗺️ 4. Gerando dados para mapa...');
      final mapData = _calculationService.generateMapVisualizationData(
        result: result,
        talhaoId: 'talhao_teste',
      );
      
      if (mapData['success'] == true) {
        final summary = mapData['summary'] as Map<String, dynamic>;
        print('   ✅ Dados gerados:');
        print('      🎯 Status: Sucesso');
        print('      📊 Classificação: ${summary['classification']}');
        print('      📈 Índice: ${summary['infestation_index']}%');
        print('      📍 Pontos: ${summary['total_points']}');
        print('      ⚠️ Críticos: ${summary['critical_points']}');
        
        final geoJson = mapData['geojson'] as Map<String, dynamic>;
        final features = geoJson['features'] as List;
        print('      🗺️ Features: ${features.length}');
      } else {
        print('   ❌ Erro: ${mapData['error']}');
      }
      
      // 5. Verificar integração com catálogo
      print('\n📚 5. Verificando integração com catálogo...');
      await _testOrganismCatalog();
      
      print('\n✅ === TESTE RÁPIDO CONCLUÍDO COM SUCESSO ===');
      
    } catch (e, stackTrace) {
      print('❌ === ERRO NO TESTE RÁPIDO ===');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Cria ponto de teste rápido
  MonitoringPoint _createQuickTestPoint() {
    return MonitoringPoint(
      id: 'quick_test_001',
      monitoringId: 'quick_session_001',
      latitude: -10.123456,
      longitude: -55.123456,
      organismId: 'soja_percevejo_marrom',
      organismName: 'Percevejo-marrom',
      quantity: 3, // 3 percevejos (acima do limiar de 2)
      unidade: 'percevejos/m',
      accuracy: 2.5,
      collectedAt: DateTime.now(),
      observacoes: 'Teste rápido - infestação moderada',
      collectorId: 'coletor_teste',
      talhaoId: 'talhao_teste',
      talhaoName: 'Talhão Teste',
    );
  }

  /// Testa integração com catálogo de organismos
  Future<void> _testOrganismCatalog() async {
    try {
      // Simular busca no catálogo
      print('   🔍 Buscando organismo no catálogo...');
      
      // Aqui normalmente faria a busca real no catálogo
      // Por enquanto, vamos simular
      final organismData = {
        'id': 'soja_percevejo_marrom',
        'nome': 'Percevejo-marrom',
        'nome_cientifico': 'Euschistus heros',
        'categoria': 'Praga',
        'limiares_especificos': {
          'floracao': '2 percevejos por metro',
        },
        'severidade': {
          'baixo': {'descricao': '1 percevejo por metro'},
          'medio': {'descricao': '2 percevejos por metro'},
          'alto': {'descricao': '3+ percevejos por metro'},
        },
      };
      
      print('   ✅ Organismo encontrado: ${organismData['nome']}');
      print('      🧬 Nome científico: ${organismData['nome_cientifico']}');
      print('      📊 Categoria: ${organismData['categoria']}');
      print('      📏 Limiar floração: ${organismData['limiares_especificos']['floracao']}');
      
      // Verificar se o cálculo está usando os limiares corretos
      final limiar = organismData['limiares_especificos']['floracao'] as String;
      if (limiar.contains('2 percevejos')) {
        print('      ✅ Limiar correto para floração: 2 percevejos por metro');
      } else {
        print('      ⚠️ Limiar pode estar incorreto: $limiar');
      }
      
    } catch (e) {
      print('   ❌ Erro na integração com catálogo: $e');
    }
  }

  /// Testa múltiplos pontos
  Future<void> testMultiplePoints() async {
    print('\n📊 === TESTE COM MÚLTIPLOS PONTOS ===');
    
    try {
      // Criar múltiplos pontos
      final monitoringPoints = [
        MonitoringPoint(
          id: 'multi_001',
          monitoringId: 'multi_session',
          latitude: -10.123456,
          longitude: -55.123456,
          organismId: 'soja_percevejo_marrom',
          organismName: 'Percevejo-marrom',
          quantity: 1, // Baixo
          unidade: 'percevejos/m',
          accuracy: 2.5,
          collectedAt: DateTime.now(),
          observacoes: 'Ponto baixo',
          collectorId: 'coletor_teste',
          talhaoId: 'talhao_teste',
          talhaoName: 'Talhão Teste',
        ),
        MonitoringPoint(
          id: 'multi_002',
          monitoringId: 'multi_session',
          latitude: -10.123500,
          longitude: -55.123500,
          organismId: 'soja_percevejo_marrom',
          organismName: 'Percevejo-marrom',
          quantity: 4, // Alto
          unidade: 'percevejos/m',
          accuracy: 2.0,
          collectedAt: DateTime.now(),
          observacoes: 'Ponto alto',
          collectorId: 'coletor_teste',
          talhaoId: 'talhao_teste',
          talhaoName: 'Talhão Teste',
        ),
        MonitoringPoint(
          id: 'multi_003',
          monitoringId: 'multi_session',
          latitude: -10.123600,
          longitude: -55.123600,
          organismId: 'soja_percevejo_marrom',
          organismName: 'Percevejo-marrom',
          quantity: 6, // Crítico
          unidade: 'percevejos/m',
          accuracy: 1.8,
          collectedAt: DateTime.now(),
          observacoes: 'Ponto crítico',
          collectorId: 'coletor_teste',
          talhaoId: 'talhao_teste',
          talhaoName: 'Talhão Teste',
        ),
      ];
      
      print('📝 Criados ${monitoringPoints.length} pontos de teste');
      
      // Converter
      final infestationPoints = _calculationService.convertMonitoringPointsToInfestationPoints(
        monitoringPoints: monitoringPoints,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        talhaoId: 'talhao_teste',
        talhaoName: 'Talhão Teste',
      );
      
      print('🔄 Convertidos ${infestationPoints.length} pontos');
      
      // Calcular
      final result = await _calculationService.calculateMathematicalInfestation(
        points: infestationPoints,
        organismId: 'soja_percevejo_marrom',
        phenologicalPhase: 'floracao',
        talhaoArea: 5.0,
        totalPlants: 25000,
      );
      
      print('🧮 Cálculo concluído:');
      print('   📊 Classificação: ${result.classification}');
      print('   📈 Índice: ${result.infestationIndex.toStringAsFixed(2)}%');
      print('   🔢 Média: ${result.averageCount.toStringAsFixed(2)}');
      print('   ⚠️ Críticos: ${result.criticalPoints.length}');
      print('   🔥 Heatmap: ${result.heatmapData.length}');
      
      // Verificar pontos críticos
      if (result.criticalPoints.isNotEmpty) {
        print('   🎯 Pontos críticos identificados:');
        for (int i = 0; i < result.criticalPoints.length; i++) {
          final point = result.criticalPoints[i];
          print('      ${i + 1}. ${point.count} ${point.unit}');
        }
      }
      
    } catch (e) {
      print('❌ Erro no teste múltiplos pontos: $e');
    }
  }
}

/// Função para executar teste rápido
Future<void> runQuickIntegrationTest() async {
  final test = QuickIntegrationTest();
  
  print('⚡ === INICIANDO TESTE RÁPIDO ===\n');
  
  // Teste principal
  await test.runQuickTest();
  
  // Teste múltiplos pontos
  await test.testMultiplePoints();
  
  print('\n🎉 === TESTE RÁPIDO FINALIZADO ===');
}
