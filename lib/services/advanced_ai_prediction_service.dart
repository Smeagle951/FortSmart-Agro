import 'dart:math';
import '../models/infestacao_model.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';

/// Serviço de predições avançadas de IA para análise ponto a ponto
class AdvancedAIPredictionService {
  
  /// Gera predições ponto a ponto baseadas em dados enriquecidos
  Future<List<AIPointPrediction>> generatePointPredictions({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('🤖 [AI-PREDICTION] Gerando predições ponto a ponto com ${occurrences.length} ocorrências');
      
      final predictions = <AIPointPrediction>[];
      
      // Agrupar ocorrências por ponto
      final pointGroups = _groupOccurrencesByPoint(occurrences, monitoringPoints);
      
      for (final entry in pointGroups.entries) {
        final pointId = entry.key;
        final pointOccurrences = entry.value;
        final monitoringPoint = monitoringPoints.firstWhere(
          (p) => p.id == pointId,
          orElse: () => monitoringPoints.first,
        );
        
        // Gerar predição para o ponto
        final prediction = await _generatePointPrediction(
          pointId,
          monitoringPoint,
          pointOccurrences,
        );
        
        if (prediction != null) {
          predictions.add(prediction);
        }
      }
      
      Logger.info('✅ [AI-PREDICTION] ${predictions.length} predições ponto a ponto geradas');
      return predictions;
      
    } catch (e) {
      Logger.error('❌ [AI-PREDICTION] Erro ao gerar predições: $e');
      return [];
    }
  }
  
  /// Gera predições por talhão com análise econômica
  Future<List<TalhaoAIPrediction>> generateTalhaoPredictions({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('🏞️ [AI-TALHAO] Gerando predições por talhão com ${occurrences.length} ocorrências');
      
      final predictions = <TalhaoAIPrediction>[];
      
      // Agrupar ocorrências por talhão
      final talhaoGroups = _groupOccurrencesByTalhao(occurrences);
      
      for (final entry in talhaoGroups.entries) {
        final talhaoId = entry.key;
        final talhaoOccurrences = entry.value;
        
        // Gerar predição para o talhão
        final prediction = await _generateTalhaoPrediction(
          talhaoId,
          talhaoOccurrences,
        );
        
        if (prediction != null) {
          predictions.add(prediction);
        }
      }
      
      Logger.info('✅ [AI-TALHAO] ${predictions.length} predições por talhão geradas');
      return predictions;
      
    } catch (e) {
      Logger.error('❌ [AI-TALHAO] Erro ao gerar predições por talhão: $e');
      return [];
    }
  }
  
  /// Gera análise econômica completa
  Future<EconomicAnalysis> generateEconomicAnalysis({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('💰 [AI-ECONOMIC] Gerando análise econômica com ${occurrences.length} ocorrências');
      
      // Calcular métricas econômicas
      final totalArea = _calculateTotalArea(monitoringPoints);
      final totalOccurrences = occurrences.length;
      final averageSeverity = _calculateAverageSeverity(occurrences);
      
      // Calcular perdas por organismo
      final organismLosses = _calculateOrganismLosses(occurrences);
      
      // Calcular perdas por talhão
      final talhaoLosses = _calculateTalhaoLosses(occurrences);
      
      // Calcular custos de controle
      final controlCosts = _calculateControlCosts(occurrences);
      
      // Calcular ROI de intervenções
      final roiAnalysis = _calculateROI(occurrences, controlCosts);
      
      // Gerar recomendações econômicas
      final recommendations = _generateEconomicRecommendations(
        organismLosses,
        talhaoLosses,
        controlCosts,
        roiAnalysis,
      );
      
      final analysis = EconomicAnalysis(
        totalArea: totalArea,
        totalOccurrences: totalOccurrences,
        averageSeverity: averageSeverity,
        organismLosses: organismLosses,
        talhaoLosses: talhaoLosses,
        controlCosts: controlCosts,
        roiAnalysis: roiAnalysis,
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );
      
      Logger.info('✅ [AI-ECONOMIC] Análise econômica gerada com sucesso');
      return analysis;
      
    } catch (e) {
      Logger.error('❌ [AI-ECONOMIC] Erro ao gerar análise econômica: $e');
      return EconomicAnalysis.empty();
    }
  }
  
  // Métodos auxiliares
  
  Map<String, List<InfestacaoModel>> _groupOccurrencesByPoint(
    List<InfestacaoModel> occurrences,
    List<MonitoringPoint> monitoringPoints,
  ) {
    final grouped = <String, List<InfestacaoModel>>{};
    
    for (final occurrence in occurrences) {
      // Encontrar ponto mais próximo
      final nearestPoint = _findNearestPoint(occurrence, monitoringPoints);
      if (nearestPoint != null) {
        grouped.putIfAbsent(nearestPoint.id, () => []).add(occurrence);
      }
    }
    
    return grouped;
  }
  
  Map<String, List<InfestacaoModel>> _groupOccurrencesByTalhao(List<InfestacaoModel> occurrences) {
    final grouped = <String, List<InfestacaoModel>>{};
    
    for (final occurrence in occurrences) {
      grouped.putIfAbsent(occurrence.talhaoId, () => []).add(occurrence);
    }
    
    return grouped;
  }
  
  MonitoringPoint? _findNearestPoint(InfestacaoModel occurrence, List<MonitoringPoint> points) {
    if (points.isEmpty) return null;
    
    double minDistance = double.infinity;
    MonitoringPoint? nearestPoint;
    
    for (final point in points) {
      final distance = _calculateDistance(
        occurrence.latitude,
        occurrence.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }
    
    return minDistance < 0.1 ? nearestPoint : null; // 100m de tolerância
  }
  
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  
  Future<AIPointPrediction?> _generatePointPrediction(
    String pointId,
    MonitoringPoint monitoringPoint,
    List<InfestacaoModel> occurrences,
  ) async {
    try {
      // Calcular métricas do ponto
      final metrics = _calculatePointMetrics(occurrences);
      
      // Predizer evolução
      final evolution = _predictEvolution(metrics, occurrences);
      
      // Calcular impacto econômico
      final economicImpact = _calculatePointEconomicImpact(metrics, monitoringPoint);
      
      // Gerar recomendações específicas
      final recommendations = _generatePointRecommendations(metrics, evolution);
      
      return AIPointPrediction(
        pointId: pointId,
        latitude: monitoringPoint.latitude,
        longitude: monitoringPoint.longitude,
        organismId: metrics.dominantOrganism,
        organismName: metrics.dominantOrganismName,
        currentSeverity: metrics.averageSeverity,
        predictedSeverity: evolution.predictedSeverity,
        evolutionDays: evolution.evolutionDays,
        riskLevel: evolution.riskLevel,
        economicImpact: economicImpact,
        recommendations: recommendations,
        confidence: evolution.confidence,
        environmentalFactors: _extractEnvironmentalFactors(occurrences),
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('❌ [AI-POINT] Erro ao gerar predição do ponto $pointId: $e');
      return null;
    }
  }
  
  Future<TalhaoAIPrediction?> _generateTalhaoPrediction(
    String talhaoId,
    List<InfestacaoModel> occurrences,
  ) async {
    try {
      // Calcular métricas do talhão
      final metrics = _calculateTalhaoMetrics(occurrences);
      
      // Predizer evolução do talhão
      final evolution = _predictTalhaoEvolution(metrics, occurrences);
      
      // Calcular impacto econômico do talhão
      final economicImpact = _calculateTalhaoEconomicImpact(metrics, talhaoId);
      
      // Gerar recomendações para o talhão
      final recommendations = _generateTalhaoRecommendations(metrics, evolution);
      
      return TalhaoAIPrediction(
        talhaoId: talhaoId,
        totalOccurrences: occurrences.length,
        averageSeverity: metrics.averageSeverity,
        dominantOrganism: metrics.dominantOrganism,
        predictedEvolution: evolution,
        economicImpact: economicImpact,
        recommendations: recommendations,
        riskLevel: evolution.riskLevel,
        confidence: evolution.confidence,
        generatedAt: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('❌ [AI-TALHAO] Erro ao gerar predição do talhão $talhaoId: $e');
      return null;
    }
  }
  
  // Métodos de cálculo de métricas
  
  PointMetrics _calculatePointMetrics(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return PointMetrics.empty();
    
    final totalSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a + b);
    final averageSeverity = totalSeverity / occurrences.length;
    
    // Organismo dominante
    final organismCounts = <String, int>{};
    for (final occurrence in occurrences) {
      organismCounts[occurrence.subtipo] = (organismCounts[occurrence.subtipo] ?? 0) + 1;
    }
    
    final dominantOrganism = organismCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return PointMetrics(
      averageSeverity: averageSeverity,
      totalOccurrences: occurrences.length,
      dominantOrganism: dominantOrganism,
      dominantOrganismName: dominantOrganism,
      maxSeverity: occurrences.map((o) => o.percentual).reduce((a, b) => a > b ? a : b),
      minSeverity: occurrences.map((o) => o.percentual).reduce((a, b) => a < b ? a : b),
      phases: _extractPhases(occurrences),
      environmentalFactors: _extractEnvironmentalFactors(occurrences),
    );
  }
  
  TalhaoMetrics _calculateTalhaoMetrics(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return TalhaoMetrics.empty();
    
    final totalSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a + b);
    final averageSeverity = totalSeverity / occurrences.length;
    
    // Organismo dominante
    final organismCounts = <String, int>{};
    for (final occurrence in occurrences) {
      organismCounts[occurrence.subtipo] = (organismCounts[occurrence.subtipo] ?? 0) + 1;
    }
    
    final dominantOrganism = organismCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return TalhaoMetrics(
      averageSeverity: averageSeverity,
      totalOccurrences: occurrences.length,
      dominantOrganism: dominantOrganism,
      maxSeverity: occurrences.map((o) => o.percentual).reduce((a, b) => a > b ? a : b),
      minSeverity: occurrences.map((o) => o.percentual).reduce((a, b) => a < b ? a : b),
      organismDistribution: organismCounts,
      phases: _extractPhases(occurrences),
      environmentalFactors: _extractEnvironmentalFactors(occurrences),
    );
  }
  
  // Métodos de predição
  
  EvolutionPrediction _predictEvolution(PointMetrics metrics, List<InfestacaoModel> occurrences) {
    // Simular predição baseada em dados históricos
    final currentSeverity = metrics.averageSeverity;
    final environmentalRisk = _calculateEnvironmentalRisk(occurrences);
    final organismType = _getOrganismType(metrics.dominantOrganism);
    
    // Calcular evolução baseada no tipo de organismo
    double evolutionRate = _getEvolutionRate(organismType, environmentalRisk);
    int evolutionDays = _calculateEvolutionDays(currentSeverity, evolutionRate);
    double predictedSeverity = _calculatePredictedSeverity(currentSeverity, evolutionRate, evolutionDays);
    
    // Calcular nível de risco
    String riskLevel = _calculateRiskLevel(predictedSeverity, environmentalRisk);
    
    // Calcular confiança
    double confidence = _calculatePredictionConfidence(metrics, environmentalRisk);
    
    return EvolutionPrediction(
      currentSeverity: currentSeverity,
      predictedSeverity: predictedSeverity,
      evolutionDays: evolutionDays,
      evolutionRate: evolutionRate,
      riskLevel: riskLevel,
      confidence: confidence,
      factors: _getEvolutionFactors(organismType, environmentalRisk),
    );
  }
  
  TalhaoEvolutionPrediction _predictTalhaoEvolution(TalhaoMetrics metrics, List<InfestacaoModel> occurrences) {
    // Simular predição para talhão
    final currentSeverity = metrics.averageSeverity;
    final environmentalRisk = _calculateEnvironmentalRisk(occurrences);
    final organismType = _getOrganismType(metrics.dominantOrganism);
    
    double evolutionRate = _getEvolutionRate(organismType, environmentalRisk);
    int evolutionDays = _calculateEvolutionDays(currentSeverity, evolutionRate);
    double predictedSeverity = _calculatePredictedSeverity(currentSeverity, evolutionRate, evolutionDays);
    
    String riskLevel = _calculateRiskLevel(predictedSeverity, environmentalRisk);
    double confidence = _calculatePredictionConfidence(metrics, environmentalRisk);
    
    return TalhaoEvolutionPrediction(
      currentSeverity: currentSeverity,
      predictedSeverity: predictedSeverity,
      evolutionDays: evolutionDays,
      riskLevel: riskLevel,
      confidence: confidence,
      organismDistribution: metrics.organismDistribution,
      environmentalFactors: metrics.environmentalFactors,
    );
  }
  
  // Métodos de análise econômica
  
  double _calculateTotalArea(List<MonitoringPoint> points) {
    // Simular área baseada nos pontos
    return points.length * 1.0; // 1 hectare por ponto (simulado)
  }
  
  double _calculateAverageSeverity(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return 0.0;
    return occurrences.map((o) => o.percentual).reduce((a, b) => a + b) / occurrences.length;
  }
  
  Map<String, EconomicLoss> _calculateOrganismLosses(List<InfestacaoModel> occurrences) {
    final losses = <String, EconomicLoss>{};
    
    // Agrupar por organismo
    final organismGroups = <String, List<InfestacaoModel>>{};
    for (final occurrence in occurrences) {
      organismGroups.putIfAbsent(occurrence.subtipo, () => []).add(occurrence);
    }
    
    for (final entry in organismGroups.entries) {
      final organism = entry.key;
      final organismOccurrences = entry.value;
      
      final averageSeverity = organismOccurrences.map((o) => o.percentual).reduce((a, b) => a + b) / organismOccurrences.length;
      final productivityLoss = _calculateProductivityLoss(averageSeverity);
      final economicLoss = _calculateEconomicLoss(productivityLoss, organism);
      
      losses[organism] = EconomicLoss(
        organism: organism,
        occurrences: organismOccurrences.length,
        averageSeverity: averageSeverity,
        productivityLoss: productivityLoss,
        economicLoss: economicLoss,
        costPerHectare: economicLoss / organismOccurrences.length,
      );
    }
    
    return losses;
  }
  
  Map<String, EconomicLoss> _calculateTalhaoLosses(List<InfestacaoModel> occurrences) {
    final losses = <String, EconomicLoss>{};
    
    // Agrupar por talhão
    final talhaoGroups = <String, List<InfestacaoModel>>{};
    for (final occurrence in occurrences) {
      talhaoGroups.putIfAbsent(occurrence.talhaoId, () => []).add(occurrence);
    }
    
    for (final entry in talhaoGroups.entries) {
      final talhaoId = entry.key;
      final talhaoOccurrences = entry.value;
      
      final averageSeverity = talhaoOccurrences.map((o) => o.percentual).reduce((a, b) => a + b) / talhaoOccurrences.length;
      final productivityLoss = _calculateProductivityLoss(averageSeverity);
      final economicLoss = _calculateEconomicLoss(productivityLoss, 'Talhão $talhaoId');
      
      losses[talhaoId] = EconomicLoss(
        organism: 'Talhão $talhaoId',
        occurrences: talhaoOccurrences.length,
        averageSeverity: averageSeverity,
        productivityLoss: productivityLoss,
        economicLoss: economicLoss,
        costPerHectare: economicLoss / talhaoOccurrences.length,
      );
    }
    
    return losses;
  }
  
  Map<String, double> _calculateControlCosts(List<InfestacaoModel> occurrences) {
    final costs = <String, double>{};
    
    // Agrupar por organismo
    final organismGroups = <String, List<InfestacaoModel>>{};
    for (final occurrence in occurrences) {
      organismGroups.putIfAbsent(occurrence.subtipo, () => []).add(occurrence);
    }
    
    for (final entry in organismGroups.entries) {
      final organism = entry.key;
      final organismOccurrences = entry.value;
      
      // Calcular custo baseado no tipo de organismo e severidade
      final averageSeverity = organismOccurrences.map((o) => o.percentual).reduce((a, b) => a + b) / organismOccurrences.length;
      final costPerOccurrence = _getControlCostPerOrganism(organism, averageSeverity);
      final totalCost = costPerOccurrence * organismOccurrences.length;
      
      costs[organism] = totalCost;
    }
    
    return costs;
  }
  
  ROIAnalysis _calculateROI(List<InfestacaoModel> occurrences, Map<String, double> controlCosts) {
    double totalControlCost = controlCosts.values.reduce((a, b) => a + b);
    double totalEconomicLoss = _calculateTotalEconomicLoss(occurrences);
    
    double roi = totalControlCost > 0 ? (totalEconomicLoss - totalControlCost) / totalControlCost : 0.0;
    double paybackPeriod = totalControlCost > 0 ? totalControlCost / (totalEconomicLoss / 12) : 0.0; // meses
    
    return ROIAnalysis(
      totalControlCost: totalControlCost,
      totalEconomicLoss: totalEconomicLoss,
      roi: roi,
      paybackPeriod: paybackPeriod,
      netBenefit: totalEconomicLoss - totalControlCost,
      costBenefitRatio: totalControlCost / totalEconomicLoss,
    );
  }
  
  // Métodos auxiliares de cálculo
  
  double _calculateProductivityLoss(double severity) {
    // Perda de produtividade baseada na severidade
    if (severity <= 10) return 0.05; // 5%
    if (severity <= 30) return 0.15; // 15%
    if (severity <= 60) return 0.35; // 35%
    return 0.60; // 60%
  }
  
  double _calculateEconomicLoss(double productivityLoss, String organism) {
    // Simular valor por hectare (R$ 3.000/ha para soja)
    const double valuePerHectare = 3000.0;
    return productivityLoss * valuePerHectare;
  }
  
  double _getControlCostPerOrganism(String organism, double severity) {
    // Custos de controle por organismo
    double baseCost = 50.0; // R$ 50/ha base
    
    if (organism.toLowerCase().contains('praga')) {
      baseCost = 80.0; // Pragas são mais caras
    } else if (organism.toLowerCase().contains('doenca')) {
      baseCost = 120.0; // Doenças são mais caras
    } else if (organism.toLowerCase().contains('daninha')) {
      baseCost = 60.0; // Plantas daninhas são mais baratas
    }
    
    // Ajustar pela severidade
    return baseCost * (1 + severity / 100.0);
  }
  
  double _calculateTotalEconomicLoss(List<InfestacaoModel> occurrences) {
    double totalLoss = 0.0;
    
    for (final occurrence in occurrences) {
      final productivityLoss = _calculateProductivityLoss(occurrence.percentual.toDouble());
      final economicLoss = _calculateEconomicLoss(productivityLoss, occurrence.subtipo);
      totalLoss += economicLoss;
    }
    
    return totalLoss;
  }
  
  // Métodos auxiliares de predição
  
  String _getOrganismType(String organism) {
    if (organism.toLowerCase().contains('praga')) return 'praga';
    if (organism.toLowerCase().contains('doenca')) return 'doenca';
    if (organism.toLowerCase().contains('daninha')) return 'daninha';
    return 'outro';
  }
  
  double _getEvolutionRate(String organismType, double environmentalRisk) {
    // Taxa de evolução baseada no tipo de organismo e condições ambientais
    double baseRate = 0.1; // 10% por dia base
    
    switch (organismType) {
      case 'praga':
        baseRate = 0.15; // Pragas evoluem mais rápido
        break;
      case 'doenca':
        baseRate = 0.20; // Doenças evoluem mais rápido
        break;
      case 'daninha':
        baseRate = 0.08; // Plantas daninhas evoluem mais devagar
        break;
      default:
        baseRate = 0.10;
    }
    
    return baseRate * (1 + environmentalRisk);
  }
  
  int _calculateEvolutionDays(double currentSeverity, double evolutionRate) {
    // Calcular dias para evolução baseada na severidade atual e taxa
    if (currentSeverity >= 80) return 1; // Já crítico
    if (currentSeverity >= 60) return 3; // Alto, evoluirá em 3 dias
    if (currentSeverity >= 40) return 7; // Médio, evoluirá em 7 dias
    return 14; // Baixo, evoluirá em 14 dias
  }
  
  double _calculatePredictedSeverity(double currentSeverity, double evolutionRate, int days) {
    // Calcular severidade prevista
    double predicted = currentSeverity * (1 + evolutionRate * days);
    return predicted.clamp(0.0, 100.0);
  }
  
  String _calculateRiskLevel(double predictedSeverity, double environmentalRisk) {
    if (predictedSeverity >= 80 || environmentalRisk >= 0.8) return 'Crítico';
    if (predictedSeverity >= 60 || environmentalRisk >= 0.6) return 'Alto';
    if (predictedSeverity >= 40 || environmentalRisk >= 0.4) return 'Médio';
    return 'Baixo';
  }
  
  double _calculatePredictionConfidence(dynamic metrics, double environmentalRisk) {
    // Calcular confiança baseada na qualidade dos dados
    double confidence = 70.0; // Base
    
    if (metrics.totalOccurrences >= 3) confidence += 10;
    if (environmentalRisk >= 0.5) confidence += 10;
    if (metrics.averageSeverity >= 30) confidence += 10;
    
    return confidence.clamp(0.0, 100.0);
  }
  
  double _calculateEnvironmentalRisk(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return 0.5;
    
    // Simular risco ambiental baseado na data
    final month = occurrences.first.dataHora.month;
    double risk = 0.5; // Base
    
    if (month >= 9 && month <= 11) risk += 0.3; // Primavera
    if (month >= 12 && month <= 2) risk += 0.2; // Verão
    
    return risk.clamp(0.0, 1.0);
  }
  
  List<String> _extractPhases(List<InfestacaoModel> occurrences) {
    final phases = <String>[];
    for (final occurrence in occurrences) {
      final phase = _extractPhaseFromOccurrence(occurrence);
      if (!phases.contains(phase)) phases.add(phase);
    }
    return phases;
  }
  
  String _extractPhaseFromOccurrence(InfestacaoModel occurrence) {
    final observations = occurrence.observacao?.toLowerCase() ?? '';
    if (observations.contains('ovo')) return 'Ovo';
    if (observations.contains('larva')) return 'Larva Média';
    if (observations.contains('adulto')) return 'Adulto';
    return 'Larva Média';
  }
  
  Map<String, dynamic> _extractEnvironmentalFactors(List<InfestacaoModel> occurrences) {
    return {
      'temperature': _simulateTemperature(occurrences.first.dataHora),
      'humidity': _simulateHumidity(occurrences.first.dataHora),
      'season': _getSeason(occurrences.first.dataHora),
      'riskLevel': _calculateEnvironmentalRisk(occurrences),
    };
  }
  
  double _simulateTemperature(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 22.0;
    if (month >= 6 && month <= 8) return 18.0;
    if (month >= 9 && month <= 11) return 25.0;
    return 28.0;
  }
  
  double _simulateHumidity(DateTime date) {
    final month = date.month;
    if (month >= 6 && month <= 8) return 85.0;
    if (month >= 12 && month <= 2) return 75.0;
    return 70.0;
  }
  
  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'Outono';
    if (month >= 6 && month <= 8) return 'Inverno';
    if (month >= 9 && month <= 11) return 'Primavera';
    return 'Verão';
  }
  
  List<String> _getEvolutionFactors(String organismType, double environmentalRisk) {
    final factors = <String>[];
    
    if (environmentalRisk >= 0.7) factors.add('Condições ambientais favoráveis');
    if (organismType == 'praga') factors.add('Ciclo de vida rápido');
    if (organismType == 'doenca') factors.add('Disseminação por esporos');
    if (environmentalRisk >= 0.8) factors.add('Alta umidade e temperatura');
    
    return factors;
  }
  
  // Métodos de geração de recomendações
  
  List<String> _generatePointRecommendations(PointMetrics metrics, EvolutionPrediction evolution) {
    final recommendations = <String>[];
    
    if (evolution.riskLevel == 'Crítico') {
      recommendations.add('🚨 AÇÃO IMEDIATA: Aplicar defensivo específico');
      recommendations.add('📞 CONTATO: Notificar agrônomo responsável');
    } else if (evolution.riskLevel == 'Alto') {
      recommendations.add('⚠️ MONITORAMENTO: Verificar área a cada 24h');
      recommendations.add('🛡️ PREVENÇÃO: Aplicar defensivo preventivo');
    } else if (evolution.riskLevel == 'Médio') {
      recommendations.add('📊 ANÁLISE: Verificar fatores de crescimento');
      recommendations.add('🔍 MONITORAMENTO: Verificar área a cada 48h');
    } else {
      recommendations.add('✅ MANUTENÇÃO: Continuar monitoramento regular');
    }
    
    return recommendations;
  }
  
  List<String> _generateTalhaoRecommendations(TalhaoMetrics metrics, TalhaoEvolutionPrediction evolution) {
    final recommendations = <String>[];
    
    if (evolution.riskLevel == 'Crítico') {
      recommendations.add('🚨 EMERGÊNCIA: Isolamento da área recomendado');
      recommendations.add('📞 CONTATO: Notificar equipe técnica');
    } else if (evolution.riskLevel == 'Alto') {
      recommendations.add('⚠️ ALERTA: Aplicação preventiva em todo talhão');
      recommendations.add('🔍 MONITORAMENTO: Verificar bordas do talhão');
    } else if (evolution.riskLevel == 'Médio') {
      recommendations.add('📊 ESTRATÉGIA: Desenvolver plano de controle');
      recommendations.add('🔄 ROTAÇÃO: Considerar rotação de culturas');
    } else {
      recommendations.add('✅ MANUTENÇÃO: Continuar práticas atuais');
    }
    
    return recommendations;
  }
  
  List<String> _generateEconomicRecommendations(
    Map<String, EconomicLoss> organismLosses,
    Map<String, EconomicLoss> talhaoLosses,
    Map<String, double> controlCosts,
    ROIAnalysis roiAnalysis,
  ) {
    final recommendations = <String>[];
    
    if (roiAnalysis.roi > 2.0) {
      recommendations.add('💰 ALTA RENTABILIDADE: Intervenção altamente recomendada');
    } else if (roiAnalysis.roi > 1.0) {
      recommendations.add('✅ RENTABILIDADE: Intervenção recomendada');
    } else if (roiAnalysis.roi > 0.5) {
      recommendations.add('⚠️ RENTABILIDADE BAIXA: Avaliar custo-benefício');
    } else {
      recommendations.add('❌ NÃO RECOMENDADO: Intervenção não é economicamente viável');
    }
    
    // Recomendações específicas por organismo
    for (final entry in organismLosses.entries) {
      final organism = entry.key;
      final loss = entry.value;
      
      if (loss.economicLoss > 1000) {
        recommendations.add('🎯 PRIORIDADE: $organism - Perda: R\$ ${loss.economicLoss.toStringAsFixed(2)}');
      }
    }
    
    return recommendations;
  }
  
  // Métodos de cálculo de impacto econômico
  
  EconomicImpact _calculatePointEconomicImpact(PointMetrics metrics, MonitoringPoint point) {
    final productivityLoss = _calculateProductivityLoss(metrics.averageSeverity);
    final economicLoss = _calculateEconomicLoss(productivityLoss, metrics.dominantOrganism);
    
    return EconomicImpact(
      productivityLoss: productivityLoss,
      economicLoss: economicLoss,
      costPerHectare: economicLoss,
      severity: metrics.averageSeverity,
      organism: metrics.dominantOrganism,
    );
  }
  
  EconomicImpact _calculateTalhaoEconomicImpact(TalhaoMetrics metrics, String talhaoId) {
    final productivityLoss = _calculateProductivityLoss(metrics.averageSeverity);
    final economicLoss = _calculateEconomicLoss(productivityLoss, 'Talhão $talhaoId');
    
    return EconomicImpact(
      productivityLoss: productivityLoss,
      economicLoss: economicLoss,
      costPerHectare: economicLoss / metrics.totalOccurrences,
      severity: metrics.averageSeverity,
      organism: metrics.dominantOrganism,
    );
  }
}

// Classes de dados

class AIPointPrediction {
  final String pointId;
  final double latitude;
  final double longitude;
  final String organismId;
  final String organismName;
  final double currentSeverity;
  final double predictedSeverity;
  final int evolutionDays;
  final String riskLevel;
  final EconomicImpact economicImpact;
  final List<String> recommendations;
  final double confidence;
  final Map<String, dynamic> environmentalFactors;
  final DateTime timestamp;
  
  AIPointPrediction({
    required this.pointId,
    required this.latitude,
    required this.longitude,
    required this.organismId,
    required this.organismName,
    required this.currentSeverity,
    required this.predictedSeverity,
    required this.evolutionDays,
    required this.riskLevel,
    required this.economicImpact,
    required this.recommendations,
    required this.confidence,
    required this.environmentalFactors,
    required this.timestamp,
  });
}

class TalhaoAIPrediction {
  final String talhaoId;
  final int totalOccurrences;
  final double averageSeverity;
  final String dominantOrganism;
  final TalhaoEvolutionPrediction predictedEvolution;
  final EconomicImpact economicImpact;
  final List<String> recommendations;
  final String riskLevel;
  final double confidence;
  final DateTime generatedAt;
  
  TalhaoAIPrediction({
    required this.talhaoId,
    required this.totalOccurrences,
    required this.averageSeverity,
    required this.dominantOrganism,
    required this.predictedEvolution,
    required this.economicImpact,
    required this.recommendations,
    required this.riskLevel,
    required this.confidence,
    required this.generatedAt,
  });
}

class EconomicAnalysis {
  final double totalArea;
  final int totalOccurrences;
  final double averageSeverity;
  final Map<String, EconomicLoss> organismLosses;
  final Map<String, EconomicLoss> talhaoLosses;
  final Map<String, double> controlCosts;
  final ROIAnalysis roiAnalysis;
  final List<String> recommendations;
  final DateTime generatedAt;
  
  EconomicAnalysis({
    required this.totalArea,
    required this.totalOccurrences,
    required this.averageSeverity,
    required this.organismLosses,
    required this.talhaoLosses,
    required this.controlCosts,
    required this.roiAnalysis,
    required this.recommendations,
    required this.generatedAt,
  });
  
  factory EconomicAnalysis.empty() {
    return EconomicAnalysis(
      totalArea: 0.0,
      totalOccurrences: 0,
      averageSeverity: 0.0,
      organismLosses: {},
      talhaoLosses: {},
      controlCosts: {},
      roiAnalysis: ROIAnalysis.empty(),
      recommendations: [],
      generatedAt: DateTime.now(),
    );
  }
}

class PointMetrics {
  final double averageSeverity;
  final int totalOccurrences;
  final String dominantOrganism;
  final String dominantOrganismName;
  final int maxSeverity;
  final int minSeverity;
  final List<String> phases;
  final Map<String, dynamic> environmentalFactors;
  
  PointMetrics({
    required this.averageSeverity,
    required this.totalOccurrences,
    required this.dominantOrganism,
    required this.dominantOrganismName,
    required this.maxSeverity,
    required this.minSeverity,
    required this.phases,
    required this.environmentalFactors,
  });
  
  factory PointMetrics.empty() {
    return PointMetrics(
      averageSeverity: 0.0,
      totalOccurrences: 0,
      dominantOrganism: '',
      dominantOrganismName: '',
      maxSeverity: 0,
      minSeverity: 0,
      phases: [],
      environmentalFactors: {},
    );
  }
}

class TalhaoMetrics {
  final double averageSeverity;
  final int totalOccurrences;
  final String dominantOrganism;
  final int maxSeverity;
  final int minSeverity;
  final Map<String, int> organismDistribution;
  final List<String> phases;
  final Map<String, dynamic> environmentalFactors;
  
  TalhaoMetrics({
    required this.averageSeverity,
    required this.totalOccurrences,
    required this.dominantOrganism,
    required this.maxSeverity,
    required this.minSeverity,
    required this.organismDistribution,
    required this.phases,
    required this.environmentalFactors,
  });
  
  factory TalhaoMetrics.empty() {
    return TalhaoMetrics(
      averageSeverity: 0.0,
      totalOccurrences: 0,
      dominantOrganism: '',
      maxSeverity: 0,
      minSeverity: 0,
      organismDistribution: {},
      phases: [],
      environmentalFactors: {},
    );
  }
}

class EvolutionPrediction {
  final double currentSeverity;
  final double predictedSeverity;
  final int evolutionDays;
  final double evolutionRate;
  final String riskLevel;
  final double confidence;
  final List<String> factors;
  
  EvolutionPrediction({
    required this.currentSeverity,
    required this.predictedSeverity,
    required this.evolutionDays,
    required this.evolutionRate,
    required this.riskLevel,
    required this.confidence,
    required this.factors,
  });
}

class TalhaoEvolutionPrediction {
  final double currentSeverity;
  final double predictedSeverity;
  final int evolutionDays;
  final String riskLevel;
  final double confidence;
  final Map<String, int> organismDistribution;
  final Map<String, dynamic> environmentalFactors;
  
  TalhaoEvolutionPrediction({
    required this.currentSeverity,
    required this.predictedSeverity,
    required this.evolutionDays,
    required this.riskLevel,
    required this.confidence,
    required this.organismDistribution,
    required this.environmentalFactors,
  });
}

class EconomicLoss {
  final String organism;
  final int occurrences;
  final double averageSeverity;
  final double productivityLoss;
  final double economicLoss;
  final double costPerHectare;
  
  EconomicLoss({
    required this.organism,
    required this.occurrences,
    required this.averageSeverity,
    required this.productivityLoss,
    required this.economicLoss,
    required this.costPerHectare,
  });
}

class EconomicImpact {
  final double productivityLoss;
  final double economicLoss;
  final double costPerHectare;
  final double severity;
  final String organism;
  
  EconomicImpact({
    required this.productivityLoss,
    required this.economicLoss,
    required this.costPerHectare,
    required this.severity,
    required this.organism,
  });
}

class ROIAnalysis {
  final double totalControlCost;
  final double totalEconomicLoss;
  final double roi;
  final double paybackPeriod;
  final double netBenefit;
  final double costBenefitRatio;
  
  ROIAnalysis({
    required this.totalControlCost,
    required this.totalEconomicLoss,
    required this.roi,
    required this.paybackPeriod,
    required this.netBenefit,
    required this.costBenefitRatio,
  });
  
  factory ROIAnalysis.empty() {
    return ROIAnalysis(
      totalControlCost: 0.0,
      totalEconomicLoss: 0.0,
      roi: 0.0,
      paybackPeriod: 0.0,
      netBenefit: 0.0,
      costBenefitRatio: 0.0,
    );
  }
  
  /// Método de compatibilidade para generatePredictions
  Future<Map<String, dynamic>> generatePredictions({
    required String talhaoId,
    required List<String> organismos,
    required Map<String, dynamic> dadosAmbientais,
  }) async {
    // Implementação temporária
    return {
      'predictions': [],
      'confidence': 0.8,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
