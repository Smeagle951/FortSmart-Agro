import 'package:flutter/material.dart';
import '../models/infestation_point.dart';
import '../models/organism_catalog.dart';
import '../modules/infestation_map/services/infestation_calculation_service.dart';

/// Exemplo prático de uso do motor matemático de infestação
/// Demonstra como usar o sistema unificado para cálculos por ponto e consolidação por talhão
class MathematicalInfestationExample {
  final InfestationCalculationService _calculationService = InfestationCalculationService();

  /// Exemplo completo: Cultura Soja - Percevejo-marrom
  Future<void> runSojaPercevejoExample() async {
    print('🌱 === EXEMPLO: SOJA - PERCEVEJO-MARROM ===');
    
    try {
      // 1. Criar pontos de infestação simulados
      final points = _createSampleInfestationPoints();
      
      // 2. Criar organismo (simulado - normalmente viria do catálogo)
      final organism = _createSampleOrganism();
      
      // 3. Executar cálculo matemático
      final result = await _calculationService.calculateMathematicalInfestation(
        points: points,
        organismId: 'soja_percevejo_marrom',
        phenologicalPhase: 'floracao',
        talhaoArea: 10.5, // hectares
        totalPlants: 50000, // plantas no talhão
      );
      
      // 4. Exibir resultados
      _displayResults(result);
      
      // 5. Gerar dados para visualização no mapa
      final mapData = _calculationService.generateMapVisualizationData(
        result: result,
        talhaoId: 'talhao_001',
      );
      
      _displayMapData(mapData);
      
    } catch (e) {
      print('❌ Erro no exemplo: $e');
    }
  }

  /// Cria pontos de infestação de exemplo
  List<InfestationPoint> _createSampleInfestationPoints() {
    return [
      // Ponto 1: Infestação baixa
      InfestationPoint(
        latitude: -10.123456,
        longitude: -55.123456,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        count: 1, // 1 percevejo
        unit: 'percevejos/m',
        accuracy: 3.0, // 3 metros de precisão
        talhaoId: 'talhao_001',
        talhaoName: 'Talhão Norte',
        notes: 'Ponto próximo à borda',
      ),
      
      // Ponto 2: Infestação moderada
      InfestationPoint(
        latitude: -10.123500,
        longitude: -55.123500,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        count: 2, // 2 percevejos
        unit: 'percevejos/m',
        accuracy: 2.5,
        talhaoId: 'talhao_001',
        talhaoName: 'Talhão Norte',
        notes: 'Ponto central do talhão',
      ),
      
      // Ponto 3: Infestação alta
      InfestationPoint(
        latitude: -10.123600,
        longitude: -55.123600,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        count: 4, // 4 percevejos (acima do limiar)
        unit: 'percevejos/m',
        accuracy: 1.8,
        talhaoId: 'talhao_001',
        talhaoName: 'Talhão Norte',
        notes: 'Área com histórico de infestação',
      ),
      
      // Ponto 4: Infestação crítica
      InfestationPoint(
        latitude: -10.123700,
        longitude: -55.123700,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        count: 6, // 6 percevejos (muito acima do limiar)
        unit: 'percevejos/m',
        accuracy: 2.0,
        talhaoId: 'talhao_001',
        talhaoName: 'Talhão Norte',
        notes: 'Ponto crítico - ação imediata necessária',
      ),
    ];
  }

  /// Cria organismo de exemplo (simulado)
  OrganismCatalog _createSampleOrganism() {
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

  /// Exibe os resultados do cálculo
  void _displayResults(InfestationCalculationResult result) {
    print('\n📊 === RESULTADOS DO CÁLCULO ===');
    print('🎯 Classificação: ${result.classification}');
    print('📈 Índice de Infestação: ${result.infestationIndex.toStringAsFixed(2)}%');
    print('📊 Média de Contagem: ${result.averageCount.toStringAsFixed(2)}');
    print('🔢 Total de Contagem: ${result.totalCount.toStringAsFixed(0)}');
    print('📍 Número de Pontos: ${result.pointCount}');
    print('⚠️ Pontos Críticos: ${result.criticalPoints.length}');
    print('🔥 Dados Heatmap: ${result.heatmapData.length}');
    
    print('\n🗺️ === DADOS DO HEATMAP ===');
    for (int i = 0; i < result.heatmapData.length; i++) {
      final heatmap = result.heatmapData[i];
      print('   Ponto ${i + 1}:');
      print('     📍 Coordenadas: ${heatmap.latitude.toStringAsFixed(6)}, ${heatmap.longitude.toStringAsFixed(6)}');
      print('     🔥 Intensidade: ${heatmap.intensity.toStringAsFixed(3)}');
      print('     📊 Nível: ${heatmap.level}');
      print('     📏 Raio: ${heatmap.radius.toStringAsFixed(1)}m');
    }
    
    print('\n⚠️ === PONTOS CRÍTICOS ===');
    for (int i = 0; i < result.criticalPoints.length; i++) {
      final point = result.criticalPoints[i];
      print('   Ponto ${i + 1}:');
      print('     📍 Coordenadas: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}');
      print('     🔢 Contagem: ${point.count} ${point.unit}');
      print('     📝 Observações: ${point.notes ?? 'Nenhuma'}');
    }
    
    print('\n📋 === METADADOS ===');
    result.metadata.forEach((key, value) {
      print('   $key: $value');
    });
  }

  /// Exibe os dados para visualização no mapa
  void _displayMapData(Map<String, dynamic> mapData) {
    print('\n🗺️ === DADOS PARA O MAPA ===');
    
    if (mapData['success'] == true) {
      final summary = mapData['summary'] as Map<String, dynamic>;
      print('✅ Status: Sucesso');
      print('🎯 Classificação: ${summary['classification']}');
      print('📈 Índice: ${summary['infestation_index']}%');
      print('📍 Total de Pontos: ${summary['total_points']}');
      print('⚠️ Pontos Críticos: ${summary['critical_points']}');
      print('📊 Média: ${summary['average_count']}');
      print('🔢 Total: ${summary['total_count']}');
      
      final geoJson = mapData['geojson'] as Map<String, dynamic>;
      final features = geoJson['features'] as List;
      print('🗺️ Features GeoJSON: ${features.length}');
      
      // Contar tipos de features
      int heatmapFeatures = 0;
      int criticalFeatures = 0;
      
      for (final feature in features) {
        final properties = feature['properties'] as Map<String, dynamic>;
        if (properties.containsKey('intensity')) {
          heatmapFeatures++;
        } else {
          criticalFeatures++;
        }
      }
      
      print('   🔥 Features Heatmap: $heatmapFeatures');
      print('   ⚠️ Features Críticas: $criticalFeatures');
      
    } else {
      print('❌ Erro: ${mapData['error']}');
    }
  }

  /// Exemplo de uso com dados reais de monitoramento
  Future<void> runRealMonitoringExample() async {
    print('\n🌱 === EXEMPLO: DADOS REAIS DE MONITORAMENTO ===');
    
    try {
      // Simular dados de monitoramento (normalmente viriam do banco)
      final monitoringPoints = _createSampleMonitoringPoints();
      
      // Executar cálculo a partir de dados de monitoramento
      final result = await _calculationService.calculateFromMonitoringData(
        monitoringPoints: monitoringPoints,
        organismId: 'soja_percevejo_marrom',
        organismName: 'Percevejo-marrom',
        talhaoId: 'talhao_001',
        phenologicalPhase: 'floracao',
        talhaoName: 'Talhão Norte',
        talhaoArea: 10.5,
        totalPlants: 50000,
      );
      
      // Exibir resultados
      _displayResults(result);
      
    } catch (e) {
      print('❌ Erro no exemplo de monitoramento: $e');
    }
  }

  /// Cria pontos de monitoramento de exemplo
  List<dynamic> _createSampleMonitoringPoints() {
    // Simular estrutura de MonitoringPoint
    return [
      {
        'latitude': -10.123456,
        'longitude': -55.123456,
        'quantity': 1,
        'unidade': 'percevejos/m',
        'accuracy': 3.0,
        'collectedAt': DateTime.now(),
        'observacoes': 'Ponto próximo à borda',
        'collectorId': 'coletor_001',
      },
      {
        'latitude': -10.123500,
        'longitude': -55.123500,
        'quantity': 2,
        'unidade': 'percevejos/m',
        'accuracy': 2.5,
        'collectedAt': DateTime.now(),
        'observacoes': 'Ponto central do talhão',
        'collectorId': 'coletor_001',
      },
      {
        'latitude': -10.123600,
        'longitude': -55.123600,
        'quantity': 4,
        'unidade': 'percevejos/m',
        'accuracy': 1.8,
        'collectedAt': DateTime.now(),
        'observacoes': 'Área com histórico de infestação',
        'collectorId': 'coletor_001',
      },
    ];
  }
}

/// Função principal para executar os exemplos
Future<void> runMathematicalInfestationExamples() async {
  final example = MathematicalInfestationExample();
  
  print('🚀 === INICIANDO EXEMPLOS DO MOTOR MATEMÁTICO ===\n');
  
  // Exemplo 1: Cálculo direto com InfestationPoints
  await example.runSojaPercevejoExample();
  
  // Exemplo 2: Cálculo a partir de dados de monitoramento
  await example.runRealMonitoringExample();
  
  print('\n✅ === EXEMPLOS CONCLUÍDOS ===');
}
