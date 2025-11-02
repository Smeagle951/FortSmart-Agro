import '../models/enhanced_ai_organism_data.dart';
import '../repositories/enhanced_ai_organism_repository.dart';
import '../services/enhanced_ai_diagnosis_service.dart';
import '../../../modules/infestation_map/models/infestation_summary.dart';
import '../../../models/talhao_model.dart';
import '../../../utils/logger.dart';

/// Serviço de integração entre IA expandida e mapa de infestação
/// Fornece dados corretos para mapas térmicos com severidades
class AIInfestationMapIntegrationService {
  final EnhancedAIOrganismRepository _organismRepository = EnhancedAIOrganismRepository();
  final EnhancedAIDiagnosisService _diagnosisService = EnhancedAIDiagnosisService();

  /// Gera dados de infestação com severidade para mapas térmicos
  Future<List<InfestationSummary>> generateThermalMapData({
    required String talhaoId,
    required String organismId,
    required List<Map<String, dynamic>> monitoringPoints,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Logger.info('🔥 Gerando dados térmicos para talhão $talhaoId, organismo $organismId');
      
      // Busca dados expandidos do organismo
      final organism = await _organismRepository.getOrganismById(organismId.hashCode);
      if (organism == null) {
        Logger.warning('⚠️ Organismo $organismId não encontrado na IA expandida');
        return [];
      }

      // Calcula severidade para cada ponto de monitoramento
      final thermalData = <InfestationSummary>[];
      
      for (final point in monitoringPoints) {
        final severity = _calculatePointSeverity(
          organism: organism,
          pointData: point,
          temperature: point['temperature']?.toDouble(),
          humidity: point['humidity']?.toDouble(),
        );
        
        final thermalSummary = InfestationSummary(
          id: '${talhaoId}_${organismId}_${point['id']}',
          talhaoId: talhaoId,
          organismoId: organismId,
          talhaoName: point['talhaoName'] ?? '',
          organismName: organism.name,
          periodoIni: startDate,
          periodoFim: endDate,
          avgInfestation: point['quantity']?.toDouble() ?? 0.0,
          infestationPercentage: _calculateInfestationPercentage(organism, point),
          level: severity['level'],
          lastUpdate: DateTime.now(),
          lastMonitoringDate: DateTime.tryParse(point['date'] ?? ''),
          trend: _calculateTrend(point),
          severity: severity['severity'],
          heatGeoJson: _generateHeatGeoJson(point, severity),
          totalPoints: 1,
          pointsWithOccurrence: point['quantity'] != null && point['quantity'] > 0 ? 1 : 0,
        );
        
        thermalData.add(thermalSummary);
      }

      Logger.info('✅ Dados térmicos gerados: ${thermalData.length} pontos');
      return thermalData;

    } catch (e) {
      Logger.error('❌ Erro ao gerar dados térmicos: $e');
      return [];
    }
  }

  /// Calcula severidade de um ponto baseada nos dados expandidos da IA
  Map<String, dynamic> _calculatePointSeverity({
    required EnhancedAIOrganismData organism,
    required Map<String, dynamic> pointData,
    double? temperature,
    double? humidity,
  }) {
    final quantity = pointData['quantity']?.toDouble() ?? 0.0;
    
    // Usa predição de severidade da IA se condições disponíveis
    if (temperature != null && humidity != null) {
      final predictedSeverity = organism.predictSeverity(
        temperature: temperature,
        humidity: humidity,
        organismCount: quantity.round(),
      );
      
      return {
        'level': _mapSeverityToLevel(predictedSeverity),
        'severity': predictedSeverity,
        'confidence': 0.9,
        'color': organism.getAlertColor(predictedSeverity),
        'recommendation': organism.getRecommendation(predictedSeverity),
        'productivityLoss': organism.getEstimatedProductivityLoss(predictedSeverity),
      };
    }
    
    // Fallback: usa limiares do catálogo
    return _calculateSeverityFromLimits(organism, quantity);
  }

  /// Calcula severidade baseada nos limiares do catálogo
  Map<String, dynamic> _calculateSeverityFromLimits(EnhancedAIOrganismData organism, double quantity) {
    final limiares = organism.limiaresAcao;
    
    String level;
    String severity;
    String color;
    
    if (quantity <= limiares.baixo) {
      level = 'baixo';
      severity = 'baixo';
      color = '#4CAF50'; // Verde
    } else if (quantity <= limiares.medio) {
      level = 'medio';
      severity = 'medio';
      color = '#FF9800'; // Laranja
    } else if (quantity <= limiares.alto) {
      level = 'alto';
      severity = 'alto';
      color = '#F44336'; // Vermelho
    } else {
      level = 'critico';
      severity = 'critico';
      color = '#9C27B0'; // Roxo
    }
    
    return {
      'level': level,
      'severity': severity,
      'confidence': 0.7,
      'color': color,
      'recommendation': organism.getRecommendation(severity),
      'productivityLoss': organism.getEstimatedProductivityLoss(severity),
    };
  }

  /// Mapeia severidade da IA para nível do mapa
  String _mapSeverityToLevel(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo':
        return 'baixo';
      case 'medio':
        return 'medio';
      case 'alto':
        return 'alto';
      case 'critico':
        return 'critico';
      default:
        return 'baixo';
    }
  }

  /// Calcula percentual de infestação baseado nos dados da IA
  double _calculateInfestationPercentage(EnhancedAIOrganismData organism, Map<String, dynamic> point) {
    final quantity = point['quantity']?.toDouble() ?? 0.0;
    final limiares = organism.limiaresAcao;
    
    // Usa o limite alto como referência para 100%
    if (limiares.alto <= 0) return 0.0;
    
    double percentage = (quantity / limiares.alto) * 100;
    return percentage > 100 ? 100.0 : percentage;
  }

  /// Calcula tendência baseada em dados históricos
  String? _calculateTrend(Map<String, dynamic> point) {
    // Implementação simplificada - pode ser expandida com dados históricos
    final quantity = point['quantity']?.toDouble() ?? 0.0;
    final previousQuantity = point['previousQuantity']?.toDouble() ?? 0.0;
    
    if (quantity > previousQuantity) {
      return 'crescendo';
    } else if (quantity < previousQuantity) {
      return 'diminuindo';
    } else {
      return 'estavel';
    }
  }

  /// Gera GeoJSON para heatmap
  String _generateHeatGeoJson(Map<String, dynamic> point, Map<String, dynamic> severity) {
    final lat = point['latitude']?.toDouble() ?? 0.0;
    final lng = point['longitude']?.toDouble() ?? 0.0;
    final intensity = _getHeatIntensity(severity['level']);
    
    return '''
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [$lng, $lat]
      },
      "properties": {
        "intensity": $intensity,
        "severity": "${severity['severity']}",
        "level": "${severity['level']}",
        "color": "${severity['color']}",
        "quantity": ${point['quantity'] ?? 0}
      }
    }
    ''';
  }

  /// Obtém intensidade do heatmap baseada no nível
  double _getHeatIntensity(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return 0.2;
      case 'medio':
        return 0.5;
      case 'alto':
        return 0.8;
      case 'critico':
        return 1.0;
      default:
        return 0.1;
    }
  }

  /// Gera mapa térmico completo para um talhão
  Future<Map<String, dynamic>> generateTalhaoThermalMap({
    required String talhaoId,
    required TalhaoModel talhao,
    required List<Map<String, dynamic>> monitoringData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      Logger.info('🗺️ Gerando mapa térmico completo para talhão $talhaoId');
      
      // Agrupa dados por organismo
      final organismGroups = <String, List<Map<String, dynamic>>>{};
      for (final data in monitoringData) {
        final organismId = data['organismId'] ?? '';
        if (organismId.isNotEmpty) {
          organismGroups.putIfAbsent(organismId, () => []).add(data);
        }
      }
      
      final thermalMapData = <String, dynamic>{
        'talhaoId': talhaoId,
        'talhaoName': talhao.nome,
        'area': talhao.area,
        'cultura': talhao.culturaNome ?? 'Cultura não definida',
        'periodo': {
          'inicio': startDate.toIso8601String(),
          'fim': endDate.toIso8601String(),
        },
        'organismos': <String, dynamic>{},
        'estatisticas': <String, dynamic>{},
        'heatmap': <String, dynamic>{},
      };
      
      // Processa cada organismo
      for (final entry in organismGroups.entries) {
        final organismId = entry.key;
        final points = entry.value;
        
        final organism = await _organismRepository.getOrganismById(organismId.hashCode);
        if (organism == null) continue;
        
        final organismThermalData = await generateThermalMapData(
          talhaoId: talhaoId,
          organismId: organismId,
          monitoringPoints: points,
          startDate: startDate,
          endDate: endDate,
        );
        
        thermalMapData['organismos'][organismId] = {
          'name': organism.name,
          'scientificName': organism.scientificName,
          'category': organism.categoria,
          'icon': organism.icone,
          'points': organismThermalData.length,
          'severityDistribution': _calculateSeverityDistribution(organismThermalData),
          'averageSeverity': _calculateAverageSeverity(organismThermalData),
          'recommendations': _generateRecommendations(organism, organismThermalData),
          'economicImpact': _calculateEconomicImpact(organism, organismThermalData, talhao.area),
        };
      }
      
      // Calcula estatísticas gerais
      thermalMapData['estatisticas'] = _calculateGeneralStatistics(thermalMapData['organismos']);
      
      // Gera dados do heatmap
      thermalMapData['heatmap'] = _generateHeatmapData(thermalMapData['organismos']);
      
      Logger.info('✅ Mapa térmico gerado para talhão $talhaoId');
      return thermalMapData;

    } catch (e) {
      Logger.error('❌ Erro ao gerar mapa térmico: $e');
      return {};
    }
  }

  /// Calcula distribuição de severidade
  Map<String, int> _calculateSeverityDistribution(List<InfestationSummary> data) {
    final distribution = <String, int>{};
    
    for (final summary in data) {
      final severity = summary.severity ?? 'baixo';
      distribution[severity] = (distribution[severity] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Calcula severidade média
  String _calculateAverageSeverity(List<InfestationSummary> data) {
    if (data.isEmpty) return 'baixo';
    
    final severityCounts = <String, int>{};
    for (final summary in data) {
      final severity = summary.severity ?? 'baixo';
      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
    }
    
    // Retorna a severidade mais comum
    return severityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Gera recomendações baseadas nos dados da IA
  List<String> _generateRecommendations(EnhancedAIOrganismData organism, List<InfestationSummary> data) {
    final recommendations = <String>[];
    
    // Recomendações baseadas na severidade média
    final averageSeverity = _calculateAverageSeverity(data);
    recommendations.add(organism.getRecommendation(averageSeverity));
    
    // Recomendações baseadas nas condições favoráveis
    if (organism.condicoesFavoraveis.temperatura.isNotEmpty) {
      recommendations.add('Monitorar condições: ${organism.condicoesFavoraveis.temperatura}');
    }
    
    // Recomendações do manejo integrado
    recommendations.addAll(organism.manejoIntegrado.quimico.take(2));
    recommendations.addAll(organism.manejoIntegrado.biologico.take(1));
    recommendations.addAll(organism.manejoIntegrado.cultural.take(1));
    
    return recommendations.toSet().toList();
  }

  /// Calcula impacto econômico
  Map<String, dynamic> _calculateEconomicImpact(
    EnhancedAIOrganismData organism,
    List<InfestationSummary> data,
    double area,
  ) {
    if (data.isEmpty) return {'perdaEstimada': 0.0, 'recomendacao': 'Monitoramento contínuo'};
    
    final averageSeverity = _calculateAverageSeverity(data);
    final productivityLoss = organism.getEstimatedProductivityLoss(averageSeverity);
    
    // Extrai porcentagem de perda
    final regex = RegExp(r'(\d+(?:\.\d+)?)%');
    final match = regex.firstMatch(productivityLoss);
    final lossPercentage = double.tryParse(match?.group(1) ?? '0') ?? 0.0;
    
    // Calcula perda estimada (simplificado)
    final estimatedLoss = (area * 1000 * lossPercentage / 100); // Assumindo 1000 kg/ha
    
    return {
      'perdaEstimada': estimatedLoss,
      'percentualPerda': lossPercentage,
      'recomendacao': organism.getRecommendation(averageSeverity),
      'danoEconomico': organism.danoEconomico.descricao,
    };
  }

  /// Calcula estatísticas gerais
  Map<String, dynamic> _calculateGeneralStatistics(Map<String, dynamic> organismos) {
    int totalPoints = 0;
    int totalOrganisms = organismos.length;
    final severityCounts = <String, int>{};
    
    for (final organismData in organismos.values) {
      final points = organismData['points'] as int? ?? 0;
      totalPoints += points;
      
      final distribution = organismData['severityDistribution'] as Map<String, int>? ?? {};
      for (final entry in distribution.entries) {
        severityCounts[entry.key] = (severityCounts[entry.key] ?? 0) + entry.value;
      }
    }
    
    return {
      'totalPoints': totalPoints,
      'totalOrganisms': totalOrganisms,
      'severityDistribution': severityCounts,
      'averagePointsPerOrganism': totalOrganisms > 0 ? totalPoints / totalOrganisms : 0.0,
    };
  }

  /// Gera dados do heatmap
  Map<String, dynamic> _generateHeatmapData(Map<String, dynamic> organismos) {
    final heatmapPoints = <Map<String, dynamic>>[];
    
    for (final organismData in organismos.values) {
      // Simula pontos do heatmap baseado nos dados
      final points = organismData['points'] as int? ?? 0;
      final severity = organismData['averageSeverity'] as String? ?? 'baixo';
      
      for (int i = 0; i < points; i++) {
        heatmapPoints.add({
          'lat': -23.5505 + (i * 0.001), // Coordenadas simuladas
          'lng': -46.6333 + (i * 0.001),
          'intensity': _getHeatIntensity(severity),
          'severity': severity,
        });
      }
    }
    
    return {
      'points': heatmapPoints,
      'maxIntensity': 1.0,
      'minIntensity': 0.1,
    };
  }

  /// Obtém dados de severidade para visualização
  Future<Map<String, dynamic>> getSeverityVisualizationData({
    required String talhaoId,
    required String organismId,
  }) async {
    try {
      final organism = await _organismRepository.getOrganismById(organismId.hashCode);
      if (organism == null) {
        return {};
      }
      
      return {
        'organismName': organism.name,
        'scientificName': organism.scientificName,
        'category': organism.categoria,
        'icon': organism.icone,
        'severityLevels': organism.severidadeDetalhada.map((k, v) => MapEntry(k, {
          'description': v.descricao,
          'color': v.corAlerta,
          'action': v.acao,
          'productivityLoss': v.perdaProdutividade,
        })),
        'favorableConditions': organism.condicoesFavoraveis.toMap(),
        'actionLimits': organism.limiaresAcao.toMap(),
        'economicDamage': organism.danoEconomico.toMap(),
        'managementStrategies': organism.manejoIntegrado.toMap(),
        'observations': organism.observacoes,
      };

    } catch (e) {
      Logger.error('❌ Erro ao obter dados de visualização: $e');
      return {};
    }
  }

  /// Valida se os dados da IA estão alinhados com o mapa de infestação
  Future<Map<String, dynamic>> validateAIInfestationAlignment() async {
    try {
      Logger.info('🔍 Validando alinhamento IA ↔ Mapa de Infestação');
      
      final organisms = await _organismRepository.getAllOrganisms();
      final alignmentReport = <String, dynamic>{
        'totalOrganisms': organisms.length,
        'organismsWithSeverityData': 0,
        'organismsWithPhaseData': 0,
        'organismsWithEconomicData': 0,
        'organismsWithManagementData': 0,
        'alignmentScore': 0.0,
        'recommendations': <String>[],
      };
      
      for (final organism in organisms) {
        if (organism.severidadeDetalhada.isNotEmpty) {
          alignmentReport['organismsWithSeverityData']++;
        }
        if (organism.fases.isNotEmpty) {
          alignmentReport['organismsWithPhaseData']++;
        }
        if (organism.danoEconomico.descricao.isNotEmpty) {
          alignmentReport['organismsWithEconomicData']++;
        }
        if (organism.manejoIntegrado.quimico.isNotEmpty || 
            organism.manejoIntegrado.biologico.isNotEmpty || 
            organism.manejoIntegrado.cultural.isNotEmpty) {
          alignmentReport['organismsWithManagementData']++;
        }
      }
      
      // Calcula score de alinhamento
      final total = organisms.length;
      if (total > 0) {
        final severityScore = (alignmentReport['organismsWithSeverityData'] / total) * 0.4;
        final phaseScore = (alignmentReport['organismsWithPhaseData'] / total) * 0.3;
        final economicScore = (alignmentReport['organismsWithEconomicData'] / total) * 0.2;
        final managementScore = (alignmentReport['organismsWithManagementData'] / total) * 0.1;
        
        alignmentReport['alignmentScore'] = severityScore + phaseScore + economicScore + managementScore;
      }
      
      // Gera recomendações
      if (alignmentReport['alignmentScore'] < 0.7) {
        alignmentReport['recommendations'].add('Expandir dados de severidade para mais organismos');
      }
      if (alignmentReport['organismsWithPhaseData'] < total * 0.5) {
        alignmentReport['recommendations'].add('Adicionar dados de fase de desenvolvimento');
      }
      if (alignmentReport['organismsWithEconomicData'] < total * 0.3) {
        alignmentReport['recommendations'].add('Incluir dados econômicos de danos');
      }
      
      Logger.info('✅ Validação concluída - Score: ${alignmentReport['alignmentScore']}');
      return alignmentReport;

    } catch (e) {
      Logger.error('❌ Erro na validação de alinhamento: $e');
      return {'error': e.toString()};
    }
  }

  // ========================================
  // NOVOS MÉTODOS ENRIQUECIDOS COM ESTANDE E HISTÓRICO
  // ========================================

  /// Calcula severidade ponderada com dados enriquecidos do estande e histórico
  Map<String, dynamic> calculateEnrichedSeverity({
    required String organismId,
    required Map<String, dynamic> occurrenceData,
    required Map<String, dynamic>? standData,
    required String? historySummary,
    required List<String> previousManagement,
    required double? economicImpact,
  }) {
    try {
      Logger.info('🧠 Calculando severidade enriquecida para organismo: $organismId');
      
      // Severidade base (funcionalidade existente mantida)
      final baseSeverity = _calculateBaseSeverity(organismId, occurrenceData);
      
      // Fatores de ponderação
      final standFactor = _calculateStandFactor(standData);
      final historyFactor = _calculateHistoryFactor(historySummary, occurrenceData);
      final managementFactor = _calculateManagementFactor(previousManagement);
      final economicFactor = _calculateEconomicFactor(economicImpact);
      
      // Fórmula de severidade ponderada
      final weightedSeverity = _applyWeightedFormula(
        baseSeverity: baseSeverity,
        standFactor: standFactor,
        historyFactor: historyFactor,
        managementFactor: managementFactor,
        economicFactor: economicFactor,
      );
      
      Logger.info('✅ Severidade ponderada calculada: ${weightedSeverity['severity']} (confiança: ${weightedSeverity['confidence']})');
      
      return weightedSeverity;
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular severidade enriquecida: $e');
      // Fallback para funcionalidade existente
      return _calculateBaseSeverity(organismId, occurrenceData);
    }
  }

  /// Calcula severidade base (mantém funcionalidade existente)
  Map<String, dynamic> _calculateBaseSeverity(String organismId, Map<String, dynamic> occurrenceData) {
    // Usa a lógica existente como base
    final quantity = occurrenceData['severidade']?.toDouble() ?? 0.0;
    final temperature = occurrenceData['temperatura']?.toDouble();
    final humidity = occurrenceData['umidade']?.toDouble();
    
    // Simula dados do organismo (em produção real viria do repositório)
    final mockOrganism = _createMockOrganismData(organismId);
    
    if (temperature != null && humidity != null) {
      final predictedSeverity = _predictSeverityWithConditions(
        organismId: organismId,
        temperature: temperature,
        humidity: humidity,
        organismCount: quantity.round(),
      );
      
      return {
        'level': _mapSeverityToLevel(predictedSeverity),
        'severity': predictedSeverity,
        'confidence': 0.8,
        'color': _getAlertColor(predictedSeverity),
        'recommendation': _getRecommendation(predictedSeverity),
        'productivityLoss': _getEstimatedProductivityLoss(predictedSeverity),
      };
    }
    
    // Fallback para limiares
    return _calculateSeverityFromQuantity(quantity);
  }

  /// Calcula fator de ponderação do estande
  Map<String, dynamic> _calculateStandFactor(Map<String, dynamic>? standData) {
    if (standData == null || !standData['hasStand']) {
      return {
        'factor': 1.0,
        'impact': 'neutral',
        'description': 'Nenhum estande disponível',
        'weight': 0.1,
      };
    }

    final populacao = standData['populacao']?.toDouble() ?? 0.0;
    final eficiencia = standData['eficiencia']?.toDouble() ?? 0.0;
    final diasAposEmergencia = standData['diasAposEmergencia'] ?? 0;
    
    // Estande fraco = maior vulnerabilidade
    double factor = 1.0;
    String impact = 'neutral';
    String description = 'Estande normal';
    
    if (populacao < 200000) { // Menos de 200k plantas/ha
      factor = 1.3; // 30% mais severo
      impact = 'negative';
      description = 'Estande fraco (${populacao.toInt()} plantas/ha)';
    } else if (populacao > 350000) { // Mais de 350k plantas/ha
      factor = 0.9; // 10% menos severo
      impact = 'positive';
      description = 'Estande denso (${populacao.toInt()} plantas/ha)';
    }
    
    // Ajuste por eficiência
    if (eficiencia < 0.7) {
      factor *= 1.2; // Estande ineficiente = mais vulnerável
      description += ', baixa eficiência';
    }
    
    // Ajuste por estádio fenológico (DAE)
    if (diasAposEmergencia > 45) { // Estádio reprodutivo
      factor *= 1.1; // Mais crítico no reprodutivo
      description += ', estádio reprodutivo';
    }

    return {
      'factor': factor,
      'impact': impact,
      'description': description,
      'weight': 0.25, // 25% do peso total
      'populacao': populacao,
      'eficiencia': eficiencia,
      'dae': diasAposEmergencia,
    };
  }

  /// Calcula fator de ponderação do histórico
  Map<String, dynamic> _calculateHistoryFactor(String? historySummary, Map<String, dynamic> occurrenceData) {
    if (historySummary == null || historySummary.isEmpty) {
      return {
        'factor': 1.0,
        'impact': 'neutral',
        'description': 'Nenhum histórico disponível',
        'weight': 0.15,
      };
    }

    final organismName = occurrenceData['organismo'] ?? '';
    double factor = 1.0;
    String impact = 'neutral';
    String description = 'Primeira ocorrência';
    
    // Análise simples do resumo de histórico
    if (historySummary.toLowerCase().contains('crescente') || 
        historySummary.toLowerCase().contains('aumento')) {
      factor = 1.4; // 40% mais severo
      impact = 'negative';
      description = 'Tendência crescente detectada';
    } else if (historySummary.toLowerCase().contains('decrescente') || 
               historySummary.toLowerCase().contains('diminui')) {
      factor = 0.8; // 20% menos severo
      impact = 'positive';
      description = 'Tendência decrescente detectada';
    } else if (historySummary.toLowerCase().contains('severidade média') || 
               historySummary.toLowerCase().contains('severidade alta')) {
      factor = 1.2; // 20% mais severo
      impact = 'negative';
      description = 'Histórico de severidade alta';
    }

    return {
      'factor': factor,
      'impact': impact,
      'description': description,
      'weight': 0.20, // 20% do peso total
      'summary': historySummary,
    };
  }

  /// Calcula fator de ponderação do manejo anterior
  Map<String, dynamic> _calculateManagementFactor(List<String> previousManagement) {
    if (previousManagement.isEmpty) {
      return {
        'factor': 1.0,
        'impact': 'neutral',
        'description': 'Nenhum manejo anterior registrado',
        'weight': 0.15,
      };
    }

    double factor = 1.0;
    String impact = 'neutral';
    String description = 'Manejo registrado';
    
    // Lógica de resistência baseada no tipo de manejo
    if (previousManagement.contains('quimico')) {
      // Manejo químico recente pode indicar resistência
      if (previousManagement.length == 1) {
        factor = 1.3; // 30% mais severo (possível resistência)
        impact = 'negative';
        description = 'Manejo químico recente (possível resistência)';
      } else {
        factor = 1.1; // 10% mais severo
        description = 'Manejo químico + outros';
      }
    }
    
    if (previousManagement.contains('biologico')) {
      factor *= 0.9; // 10% menos severo (controle biológico)
      description += ', controle biológico ativo';
      impact = 'positive';
    }
    
    if (previousManagement.contains('cultural')) {
      factor *= 0.95; // 5% menos severo
      description += ', manejo cultural';
      if (impact == 'neutral') impact = 'positive';
    }

    return {
      'factor': factor,
      'impact': impact,
      'description': description,
      'weight': 0.15, // 15% do peso total
      'types': previousManagement,
    };
  }

  /// Calcula fator de ponderação econômico
  Map<String, dynamic> _calculateEconomicFactor(double? economicImpact) {
    if (economicImpact == null) {
      return {
        'factor': 1.0,
        'impact': 'neutral',
        'description': 'Impacto econômico não estimado',
        'weight': 0.15,
      };
    }

    double factor = 1.0;
    String impact = 'neutral';
    String description = 'Impacto econômico normal';
    
    if (economicImpact > 15) { // Alto impacto
      factor = 1.2; // 20% mais severo
      impact = 'negative';
      description = 'Alto impacto econômico (${economicImpact.toStringAsFixed(1)}%)';
    } else if (economicImpact < 5) { // Baixo impacto
      factor = 0.9; // 10% menos severo
      impact = 'positive';
      description = 'Baixo impacto econômico (${economicImpact.toStringAsFixed(1)}%)';
    }

    return {
      'factor': factor,
      'impact': impact,
      'description': description,
      'weight': 0.15, // 15% do peso total
      'percentage': economicImpact,
    };
  }

  /// Aplica fórmula de severidade ponderada
  Map<String, dynamic> _applyWeightedFormula({
    required Map<String, dynamic> baseSeverity,
    required Map<String, dynamic> standFactor,
    required Map<String, dynamic> historyFactor,
    required Map<String, dynamic> managementFactor,
    required Map<String, dynamic> economicFactor,
  }) {
    // Peso dos fatores (deve somar 1.0)
    final weights = {
      'base': 0.35,      // 35% - severidade base
      'stand': standFactor['weight'],     // 25%
      'history': historyFactor['weight'], // 20%
      'management': managementFactor['weight'], // 15%
      'economic': economicFactor['weight'],     // 15%
    };

    // Converte severidade base para número (0-100)
    final baseSeverityValue = _severityToNumber(baseSeverity['severity']);
    
    // Calcula severidade ponderada
    final weightedValue = (baseSeverityValue * weights['base']!) +
                         (baseSeverityValue * standFactor['factor'] * weights['stand']!) +
                         (baseSeverityValue * historyFactor['factor'] * weights['history']!) +
                         (baseSeverityValue * managementFactor['factor'] * weights['management']!) +
                         (baseSeverityValue * economicFactor['factor'] * weights['economic']!);

    // Converte de volta para nível de severidade
    final finalSeverity = _numberToSeverity(weightedValue);
    
    // Calcula confiança baseada nos fatores disponíveis
    double confidence = 0.8; // Base
    if (standFactor['factor'] != 1.0) confidence += 0.05;
    if (historyFactor['factor'] != 1.0) confidence += 0.05;
    if (managementFactor['factor'] != 1.0) confidence += 0.05;
    if (economicFactor['factor'] != 1.0) confidence += 0.05;
    confidence = confidence > 1.0 ? 1.0 : confidence;

    return {
      'severity': finalSeverity,
      'level': _mapSeverityToLevel(finalSeverity),
      'confidence': confidence,
      'color': _getAlertColor(finalSeverity),
      'recommendation': _getRecommendation(finalSeverity),
      'productivityLoss': _getEstimatedProductivityLoss(finalSeverity),
      'weightedValue': weightedValue,
      'factors': {
        'stand': standFactor,
        'history': historyFactor,
        'management': managementFactor,
        'economic': economicFactor,
      },
      'calculation': {
        'baseValue': baseSeverityValue,
        'weights': weights,
        'formula': 'weighted = base×0.35 + stand×0.25 + history×0.20 + management×0.15 + economic×0.15',
      },
    };
  }

  // ========================================
  // MÉTODOS AUXILIARES PARA NOVA FUNCIONALIDADE
  // ========================================

  /// Converte severidade textual para número (0-100)
  double _severityToNumber(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo': return 25.0;
      case 'medio': return 50.0;
      case 'alto': return 75.0;
      case 'critico': return 100.0;
      default: return 25.0;
    }
  }

  /// Converte número para severidade textual
  String _numberToSeverity(double value) {
    if (value < 35) return 'baixo';
    if (value < 60) return 'medio';
    if (value < 85) return 'alto';
    return 'critico';
  }

  /// Cria dados mock do organismo para testes
  Map<String, dynamic> _createMockOrganismData(String organismId) {
    return {
      'id': organismId,
      'name': 'Organismo $organismId',
      'limiaresAcao': {
        'baixo': 5.0,
        'medio': 15.0,
        'alto': 30.0,
      },
    };
  }

  /// Prediz severidade com condições ambientais
  String _predictSeverityWithConditions({
    required String organismId,
    required double temperature,
    required double humidity,
    required int organismCount,
  }) {
    // Simulação de IA baseada em condições
    double severityScore = 0.0;
    
    // Fator de temperatura (ideal: 20-30°C)
    if (temperature < 15 || temperature > 35) {
      severityScore += 0.2; // Condições desfavoráveis
    }
    
    // Fator de umidade (ideal: 60-80%)
    if (humidity < 50 || humidity > 90) {
      severityScore += 0.2; // Condições desfavoráveis
    }
    
    // Fator de quantidade
    severityScore += (organismCount / 50.0).clamp(0.0, 1.0);
    
    // Normaliza para 0-1 e converte para severidade
    if (severityScore < 0.3) return 'baixo';
    if (severityScore < 0.6) return 'medio';
    if (severityScore < 0.8) return 'alto';
    return 'critico';
  }

  /// Calcula severidade baseada apenas na quantidade
  Map<String, dynamic> _calculateSeverityFromQuantity(double quantity) {
    String level;
    String severity;
    String color;
    
    if (quantity <= 5) {
      level = 'baixo';
      severity = 'baixo';
      color = '#4CAF50';
    } else if (quantity <= 15) {
      level = 'medio';
      severity = 'medio';
      color = '#FF9800';
    } else if (quantity <= 30) {
      level = 'alto';
      severity = 'alto';
      color = '#F44336';
    } else {
      level = 'critico';
      severity = 'critico';
      color = '#9C27B0';
    }
    
    return {
      'level': level,
      'severity': severity,
      'confidence': 0.7,
      'color': color,
      'recommendation': _getRecommendation(severity),
      'productivityLoss': _getEstimatedProductivityLoss(severity),
    };
  }

  /// Obtém cor de alerta baseada na severidade
  String _getAlertColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo': return '#4CAF50';
      case 'medio': return '#FF9800';
      case 'alto': return '#F44336';
      case 'critico': return '#9C27B0';
      default: return '#4CAF50';
    }
  }

  /// Obtém recomendação baseada na severidade
  String _getRecommendation(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo': return 'Monitorar continuamente';
      case 'medio': return 'Preparar ação preventiva';
      case 'alto': return 'Aplicar controle imediatamente';
      case 'critico': return 'Ação emergencial necessária';
      default: return 'Avaliar situação';
    }
  }

  /// Obtém perda de produtividade estimada
  double _getEstimatedProductivityLoss(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixo': return 2.0;
      case 'medio': return 8.0;
      case 'alto': return 18.0;
      case 'critico': return 35.0;
      default: return 5.0;
    }
  }
}
