import 'dart:math';
import '../models/infestacao_model.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';
import 'advanced_ai_prediction_service.dart';

/// Serviço de relatórios inteligentes com análise avançada
class IntelligentReportsService {
  
  /// Gera relatório executivo inteligente
  Future<ExecutiveReport> generateExecutiveReport({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('📊 [REPORTS] Gerando relatório executivo inteligente');
      
      // Análise geral
      final generalAnalysis = _generateGeneralAnalysis(occurrences);
      
      // Análise por talhão
      final talhaoAnalysis = _generateTalhaoAnalysis(occurrences);
      
      // Análise por organismo
      final organismAnalysis = _generateOrganismAnalysis(occurrences);
      
      // Análise temporal
      final temporalAnalysis = _generateTemporalAnalysis(occurrences);
      
      // Análise espacial
      final spatialAnalysis = _generateSpatialAnalysis(occurrences, monitoringPoints);
      
      // Análise econômica
      final economicAnalysis = await _generateEconomicAnalysis(occurrences, monitoringPoints);
      
      // Predições e recomendações
      final predictions = await _generatePredictions(occurrences, monitoringPoints);
      
      // Alertas críticos
      final criticalAlerts = _generateCriticalAlerts(occurrences);
      
      final report = ExecutiveReport(
        generalAnalysis: generalAnalysis,
        talhaoAnalysis: talhaoAnalysis,
        organismAnalysis: organismAnalysis,
        temporalAnalysis: temporalAnalysis,
        spatialAnalysis: spatialAnalysis,
        economicAnalysis: economicAnalysis,
        predictions: predictions,
        criticalAlerts: criticalAlerts,
        generatedAt: DateTime.now(),
      );
      
      Logger.info('✅ [REPORTS] Relatório executivo gerado com sucesso');
      return report;
      
    } catch (e) {
      Logger.error('❌ [REPORTS] Erro ao gerar relatório executivo: $e');
      return ExecutiveReport.empty();
    }
  }
  
  /// Gera relatório por talhão
  Future<TalhaoReport> generateTalhaoReport({
    required String talhaoId,
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('🏞️ [REPORTS] Gerando relatório para talhão $talhaoId');
      
      // Filtrar ocorrências do talhão
      final talhaoOccurrences = occurrences.where((o) => o.talhaoId == talhaoId).toList();
      
      if (talhaoOccurrences.isEmpty) {
        return TalhaoReport.empty(talhaoId);
      }
      
      // Análise do talhão
      final analysis = _analyzeTalhao(talhaoOccurrences);
      
      // Predições para o talhão
      final predictions = await _generateTalhaoPredictions(talhaoOccurrences);
      
      // Recomendações específicas
      final recommendations = _generateTalhaoRecommendations(analysis, predictions);
      
      final report = TalhaoReport(
        talhaoId: talhaoId,
        analysis: analysis,
        predictions: predictions,
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );
      
      Logger.info('✅ [REPORTS] Relatório do talhão $talhaoId gerado');
      return report;
      
    } catch (e) {
      Logger.error('❌ [REPORTS] Erro ao gerar relatório do talhão $talhaoId: $e');
      return TalhaoReport.empty(talhaoId);
    }
  }
  
  // Métodos de análise
  
  GeneralAnalysis _generateGeneralAnalysis(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return GeneralAnalysis.empty();
    
    final totalOccurrences = occurrences.length;
    final averageSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a + b) / totalOccurrences;
    final maxSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a > b ? a : b);
    final minSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a < b ? a : b);
    
    // Distribuição por nível
    final severityDistribution = <String, int>{};
    for (final occurrence in occurrences) {
      final level = _getSeverityLevel(occurrence.percentual);
      severityDistribution[level] = (severityDistribution[level] ?? 0) + 1;
    }
    
    // Organismos únicos
    final uniqueOrganisms = occurrences.map((o) => o.subtipo).toSet().length;
    
    // Talhões únicos
    final uniqueTalhoes = occurrences.map((o) => o.talhaoId).toSet().length;
    
    return GeneralAnalysis(
      totalOccurrences: totalOccurrences,
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      minSeverity: minSeverity,
      severityDistribution: severityDistribution,
      uniqueOrganisms: uniqueOrganisms,
      uniqueTalhoes: uniqueTalhoes,
      riskLevel: _calculateOverallRisk(severityDistribution),
    );
  }
  
  List<TalhaoAnalysis> _generateTalhaoAnalysis(List<InfestacaoModel> occurrences) {
    final analyses = <TalhaoAnalysis>[];
    
    // Agrupar por talhão
    final talhaoGroups = <String, List<InfestacaoModel>>{};
    for (final occurrence in occurrences) {
      talhaoGroups.putIfAbsent(occurrence.talhaoId, () => []).add(occurrence);
    }
    
    for (final entry in talhaoGroups.entries) {
      final talhaoId = entry.key;
      final talhaoOccurrences = entry.value;
      
      final analysis = _analyzeTalhao(talhaoOccurrences);
      analyses.add(TalhaoAnalysis(
        talhaoId: talhaoId,
        analysis: analysis,
        totalOccurrences: talhaoOccurrences.length,
        riskLevel: analysis.riskLevel,
      ));
    }
    
    return analyses;
  }
  
  List<OrganismAnalysis> _generateOrganismAnalysis(List<InfestacaoModel> occurrences) {
    final analyses = <OrganismAnalysis>[];
    
    // Agrupar por organismo
    final organismGroups = <String, List<InfestacaoModel>>{};
    for (final occurrence in occurrences) {
      organismGroups.putIfAbsent(occurrence.subtipo, () => []).add(occurrence);
    }
    
    for (final entry in organismGroups.entries) {
      final organism = entry.key;
      final organismOccurrences = entry.value;
      
      final analysis = _analyzeOrganism(organismOccurrences);
      analyses.add(OrganismAnalysis(
        organism: organism,
        analysis: analysis,
        totalOccurrences: organismOccurrences.length,
        riskLevel: analysis.riskLevel,
      ));
    }
    
    return analyses;
  }
  
  TemporalAnalysis _generateTemporalAnalysis(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return TemporalAnalysis.empty();
    
    // Ordenar por data
    final sortedOccurrences = occurrences..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    
    // Análise de tendência
    final trend = _calculateTrend(sortedOccurrences);
    
    // Distribuição por mês
    final monthlyDistribution = <String, int>{};
    for (final occurrence in sortedOccurrences) {
      final month = occurrence.dataHora.month;
      final monthName = _getMonthName(month);
      monthlyDistribution[monthName] = (monthlyDistribution[monthName] ?? 0) + 1;
    }
    
    // Período de maior incidência
    final peakPeriod = monthlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return TemporalAnalysis(
      trend: trend,
      monthlyDistribution: monthlyDistribution,
      peakPeriod: peakPeriod,
      totalDays: _calculateTotalDays(sortedOccurrences),
      averageOccurrencesPerDay: sortedOccurrences.length / _calculateTotalDays(sortedOccurrences),
    );
  }
  
  SpatialAnalysis _generateSpatialAnalysis(List<InfestacaoModel> occurrences, List<MonitoringPoint> monitoringPoints) {
    if (occurrences.isEmpty) return SpatialAnalysis.empty();
    
    // Calcular dispersão espacial
    final dispersion = _calculateSpatialDispersion(occurrences);
    
    // Área afetada
    final affectedArea = _calculateAffectedArea(occurrences, monitoringPoints);
    
    // Densidade de ocorrências
    final density = _calculateOccurrenceDensity(occurrences, affectedArea);
    
    // Pontos críticos
    final criticalPoints = _identifyCriticalPoints(occurrences);
    
    return SpatialAnalysis(
      dispersion: dispersion,
      affectedArea: affectedArea,
      density: density,
      criticalPoints: criticalPoints,
      totalPoints: monitoringPoints.length,
    );
  }
  
  Future<EconomicAnalysis> _generateEconomicAnalysis(List<InfestacaoModel> occurrences, List<MonitoringPoint> monitoringPoints) async {
    try {
      final predictionService = AdvancedAIPredictionService();
      return await predictionService.generateEconomicAnalysis(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
    } catch (e) {
      Logger.error('❌ [REPORTS] Erro ao gerar análise econômica: $e');
      return EconomicAnalysis.empty();
    }
  }
  
  Future<PredictionsAndRecommendations> _generatePredictions(List<InfestacaoModel> occurrences, List<MonitoringPoint> monitoringPoints) async {
    try {
      final predictionService = AdvancedAIPredictionService();
      
      final pointPredictions = await predictionService.generatePointPredictions(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      final talhaoPredictions = await predictionService.generateTalhaoPredictions(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      return PredictionsAndRecommendations(
        pointPredictions: pointPredictions,
        talhaoPredictions: talhaoPredictions,
        overallRisk: _calculateOverallRiskFromPredictions(pointPredictions, talhaoPredictions),
        recommendations: _generateOverallRecommendations(pointPredictions, talhaoPredictions),
      );
    } catch (e) {
      Logger.error('❌ [REPORTS] Erro ao gerar predições: $e');
      return PredictionsAndRecommendations.empty();
    }
  }
  
  List<CriticalAlert> _generateCriticalAlerts(List<InfestacaoModel> occurrences) {
    final alerts = <CriticalAlert>[];
    
    // Alertas de severidade crítica
    final criticalOccurrences = occurrences.where((o) => o.percentual >= 80).toList();
    if (criticalOccurrences.isNotEmpty) {
      alerts.add(CriticalAlert(
        id: 'critical_severity_${DateTime.now().millisecondsSinceEpoch}',
        type: 'CRITICAL_SEVERITY',
        title: '🚨 INFESTAÇÃO CRÍTICA DETECTADA',
        message: '${criticalOccurrences.length} ocorrências com severidade ≥80%',
        severity: 10,
        priority: 'CRITICAL',
        recommendations: [
          'Aplicação imediata de defensivos',
          'Isolamento da área se possível',
          'Contato com agrônomo responsável',
        ],
        timestamp: DateTime.now(),
      ));
    }
    
    // Alertas de múltiplos organismos
    final organismCount = occurrences.map((o) => o.subtipo).toSet().length;
    if (organismCount >= 3) {
      alerts.add(CriticalAlert(
        id: 'multiple_organisms_${DateTime.now().millisecondsSinceEpoch}',
        type: 'MULTIPLE_ORGANISMS',
        title: '⚠️ MÚLTIPLOS ORGANISMOS DETECTADOS',
        message: '$organismCount organismos diferentes detectados',
        severity: 7,
        priority: 'HIGH',
        recommendations: [
          'Desenvolver plano integrado de controle',
          'Considerar rotação de culturas',
          'Análise de resistência necessária',
        ],
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }
  
  // Métodos auxiliares
  
  TalhaoAnalysisData _analyzeTalhao(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return TalhaoAnalysisData.empty();
    
    final averageSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a + b) / occurrences.length;
    final maxSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a > b ? a : b);
    final minSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a < b ? a : b);
    
    // Organismo dominante
    final organismCounts = <String, int>{};
    for (final occurrence in occurrences) {
      organismCounts[occurrence.subtipo] = (organismCounts[occurrence.subtipo] ?? 0) + 1;
    }
    
    final dominantOrganism = organismCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return TalhaoAnalysisData(
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      minSeverity: minSeverity,
      dominantOrganism: dominantOrganism,
      organismDistribution: organismCounts,
      riskLevel: _calculateRiskLevel(averageSeverity),
      totalOccurrences: occurrences.length,
    );
  }
  
  OrganismAnalysisData _analyzeOrganism(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return OrganismAnalysisData.empty();
    
    final averageSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a + b) / occurrences.length;
    final maxSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a > b ? a : b);
    final minSeverity = occurrences.map((o) => o.percentual).reduce((a, b) => a < b ? a : b);
    
    return OrganismAnalysisData(
      averageSeverity: averageSeverity,
      maxSeverity: maxSeverity,
      minSeverity: minSeverity,
      riskLevel: _calculateRiskLevel(averageSeverity),
      totalOccurrences: occurrences.length,
      phases: _extractPhases(occurrences),
    );
  }
  
  String _getSeverityLevel(int percentual) {
    if (percentual >= 80) return 'Crítico';
    if (percentual >= 60) return 'Alto';
    if (percentual >= 40) return 'Médio';
    return 'Baixo';
  }
  
  String _calculateOverallRisk(Map<String, int> severityDistribution) {
    final critical = severityDistribution['Crítico'] ?? 0;
    final high = severityDistribution['Alto'] ?? 0;
    final medium = severityDistribution['Médio'] ?? 0;
    final low = severityDistribution['Baixo'] ?? 0;
    
    final total = critical + high + medium + low;
    if (total == 0) return 'Baixo';
    
    final riskScore = (critical * 4 + high * 3 + medium * 2 + low * 1) / total;
    
    if (riskScore >= 3.5) return 'Crítico';
    if (riskScore >= 2.5) return 'Alto';
    if (riskScore >= 1.5) return 'Médio';
    return 'Baixo';
  }
  
  String _calculateRiskLevel(double averageSeverity) {
    if (averageSeverity >= 80) return 'Crítico';
    if (averageSeverity >= 60) return 'Alto';
    if (averageSeverity >= 40) return 'Médio';
    return 'Baixo';
  }
  
  double _calculateTrend(List<InfestacaoModel> occurrences) {
    if (occurrences.length < 2) return 0.0;
    
    final firstHalf = occurrences.take(occurrences.length ~/ 2);
    final secondHalf = occurrences.skip(occurrences.length ~/ 2);
    
    final firstAvg = firstHalf.map((o) => o.percentual).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.map((o) => o.percentual).reduce((a, b) => a + b) / secondHalf.length;
    
    return (secondAvg - firstAvg) / firstAvg;
  }
  
  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }
  
  int _calculateTotalDays(List<InfestacaoModel> occurrences) {
    if (occurrences.length < 2) return 1;
    
    final first = occurrences.first.dataHora;
    final last = occurrences.last.dataHora;
    return last.difference(first).inDays + 1;
  }
  
  double _calculateSpatialDispersion(List<InfestacaoModel> occurrences) {
    if (occurrences.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    int comparisons = 0;
    
    for (int i = 0; i < occurrences.length; i++) {
      for (int j = i + 1; j < occurrences.length; j++) {
        final distance = _calculateDistance(
          occurrences[i].latitude,
          occurrences[i].longitude,
          occurrences[j].latitude,
          occurrences[j].longitude,
        );
        totalDistance += distance;
        comparisons++;
      }
    }
    
    return comparisons > 0 ? totalDistance / comparisons / 1000.0 : 0.0;
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
  
  double _calculateAffectedArea(List<InfestacaoModel> occurrences, List<MonitoringPoint> monitoringPoints) {
    // Simular área afetada baseada nos pontos
    return monitoringPoints.length * 1.0; // 1 hectare por ponto
  }
  
  double _calculateOccurrenceDensity(List<InfestacaoModel> occurrences, double area) {
    return area > 0 ? occurrences.length / area : 0.0;
  }
  
  List<String> _identifyCriticalPoints(List<InfestacaoModel> occurrences) {
    final criticalPoints = <String>[];
    
    for (final occurrence in occurrences) {
      if (occurrence.percentual >= 80) {
        criticalPoints.add('${occurrence.latitude.toStringAsFixed(4)}, ${occurrence.longitude.toStringAsFixed(4)}');
      }
    }
    
    return criticalPoints;
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
  
  Future<List<AIPointPrediction>> _generateTalhaoPredictions(List<InfestacaoModel> occurrences) async {
    try {
      final predictionService = AdvancedAIPredictionService();
      return await predictionService.generatePointPredictions(
        occurrences: occurrences,
        monitoringPoints: [], // Será implementado
      );
    } catch (e) {
      Logger.error('❌ [REPORTS] Erro ao gerar predições do talhão: $e');
      return [];
    }
  }
  
  List<String> _generateTalhaoRecommendations(TalhaoAnalysisData analysis, List<AIPointPrediction> predictions) {
    final recommendations = <String>[];
    
    if (analysis.riskLevel == 'Crítico') {
      recommendations.add('🚨 AÇÃO IMEDIATA: Aplicar defensivo específico');
      recommendations.add('📞 CONTATO: Notificar agrônomo responsável');
    } else if (analysis.riskLevel == 'Alto') {
      recommendations.add('⚠️ MONITORAMENTO: Verificar área a cada 24h');
      recommendations.add('🛡️ PREVENÇÃO: Aplicar defensivo preventivo');
    } else if (analysis.riskLevel == 'Médio') {
      recommendations.add('📊 ANÁLISE: Verificar fatores de crescimento');
      recommendations.add('🔍 MONITORAMENTO: Verificar área a cada 48h');
    } else {
      recommendations.add('✅ MANUTENÇÃO: Continuar monitoramento regular');
    }
    
    return recommendations;
  }
  
  String _calculateOverallRiskFromPredictions(List<AIPointPrediction> pointPredictions, List<TalhaoAIPrediction> talhaoPredictions) {
    if (pointPredictions.isEmpty && talhaoPredictions.isEmpty) return 'Baixo';
    
    int criticalCount = 0;
    int highCount = 0;
    
    for (final prediction in pointPredictions) {
      if (prediction.riskLevel == 'Crítico') criticalCount++;
      if (prediction.riskLevel == 'Alto') highCount++;
    }
    
    for (final prediction in talhaoPredictions) {
      if (prediction.riskLevel == 'Crítico') criticalCount++;
      if (prediction.riskLevel == 'Alto') highCount++;
    }
    
    if (criticalCount > 0) return 'Crítico';
    if (highCount > 0) return 'Alto';
    return 'Médio';
  }
  
  List<String> _generateOverallRecommendations(List<AIPointPrediction> pointPredictions, List<TalhaoAIPrediction> talhaoPredictions) {
    final recommendations = <String>[];
    
    // Recomendações baseadas em predições
    for (final prediction in pointPredictions) {
      if (prediction.riskLevel == 'Crítico') {
        recommendations.add('🚨 PONTO CRÍTICO: ${prediction.organismName} - Ação imediata necessária');
      }
    }
    
    for (final prediction in talhaoPredictions) {
      if (prediction.riskLevel == 'Crítico') {
        recommendations.add('🚨 TALHÃO CRÍTICO: ${prediction.talhaoId} - Intervenção urgente');
      }
    }
    
    return recommendations;
  }
}

// Classes de dados para relatórios

class ExecutiveReport {
  final GeneralAnalysis generalAnalysis;
  final List<TalhaoAnalysis> talhaoAnalysis;
  final List<OrganismAnalysis> organismAnalysis;
  final TemporalAnalysis temporalAnalysis;
  final SpatialAnalysis spatialAnalysis;
  final EconomicAnalysis economicAnalysis;
  final PredictionsAndRecommendations predictions;
  final List<CriticalAlert> criticalAlerts;
  final DateTime generatedAt;
  
  ExecutiveReport({
    required this.generalAnalysis,
    required this.talhaoAnalysis,
    required this.organismAnalysis,
    required this.temporalAnalysis,
    required this.spatialAnalysis,
    required this.economicAnalysis,
    required this.predictions,
    required this.criticalAlerts,
    required this.generatedAt,
  });
  
  factory ExecutiveReport.empty() {
    return ExecutiveReport(
      generalAnalysis: GeneralAnalysis.empty(),
      talhaoAnalysis: [],
      organismAnalysis: [],
      temporalAnalysis: TemporalAnalysis.empty(),
      spatialAnalysis: SpatialAnalysis.empty(),
      economicAnalysis: EconomicAnalysis.empty(),
      predictions: PredictionsAndRecommendations.empty(),
      criticalAlerts: [],
      generatedAt: DateTime.now(),
    );
  }
}

class TalhaoReport {
  final String talhaoId;
  final TalhaoAnalysisData analysis;
  final List<AIPointPrediction> predictions;
  final List<String> recommendations;
  final DateTime generatedAt;
  
  TalhaoReport({
    required this.talhaoId,
    required this.analysis,
    required this.predictions,
    required this.recommendations,
    required this.generatedAt,
  });
  
  factory TalhaoReport.empty(String talhaoId) {
    return TalhaoReport(
      talhaoId: talhaoId,
      analysis: TalhaoAnalysisData.empty(),
      predictions: [],
      recommendations: [],
      generatedAt: DateTime.now(),
    );
  }
}

class GeneralAnalysis {
  final int totalOccurrences;
  final double averageSeverity;
  final int maxSeverity;
  final int minSeverity;
  final Map<String, int> severityDistribution;
  final int uniqueOrganisms;
  final int uniqueTalhoes;
  final String riskLevel;
  
  GeneralAnalysis({
    required this.totalOccurrences,
    required this.averageSeverity,
    required this.maxSeverity,
    required this.minSeverity,
    required this.severityDistribution,
    required this.uniqueOrganisms,
    required this.uniqueTalhoes,
    required this.riskLevel,
  });
  
  factory GeneralAnalysis.empty() {
    return GeneralAnalysis(
      totalOccurrences: 0,
      averageSeverity: 0.0,
      maxSeverity: 0,
      minSeverity: 0,
      severityDistribution: {},
      uniqueOrganisms: 0,
      uniqueTalhoes: 0,
      riskLevel: 'Baixo',
    );
  }
}

class TalhaoAnalysis {
  final String talhaoId;
  final TalhaoAnalysisData analysis;
  final int totalOccurrences;
  final String riskLevel;
  
  TalhaoAnalysis({
    required this.talhaoId,
    required this.analysis,
    required this.totalOccurrences,
    required this.riskLevel,
  });
}

class OrganismAnalysis {
  final String organism;
  final OrganismAnalysisData analysis;
  final int totalOccurrences;
  final String riskLevel;
  
  OrganismAnalysis({
    required this.organism,
    required this.analysis,
    required this.totalOccurrences,
    required this.riskLevel,
  });
}

class TalhaoAnalysisData {
  final double averageSeverity;
  final int maxSeverity;
  final int minSeverity;
  final String dominantOrganism;
  final Map<String, int> organismDistribution;
  final String riskLevel;
  final int totalOccurrences;
  
  TalhaoAnalysisData({
    required this.averageSeverity,
    required this.maxSeverity,
    required this.minSeverity,
    required this.dominantOrganism,
    required this.organismDistribution,
    required this.riskLevel,
    required this.totalOccurrences,
  });
  
  factory TalhaoAnalysisData.empty() {
    return TalhaoAnalysisData(
      averageSeverity: 0.0,
      maxSeverity: 0,
      minSeverity: 0,
      dominantOrganism: '',
      organismDistribution: {},
      riskLevel: 'Baixo',
      totalOccurrences: 0,
    );
  }
}

class OrganismAnalysisData {
  final double averageSeverity;
  final int maxSeverity;
  final int minSeverity;
  final String riskLevel;
  final int totalOccurrences;
  final List<String> phases;
  
  OrganismAnalysisData({
    required this.averageSeverity,
    required this.maxSeverity,
    required this.minSeverity,
    required this.riskLevel,
    required this.totalOccurrences,
    required this.phases,
  });
  
  factory OrganismAnalysisData.empty() {
    return OrganismAnalysisData(
      averageSeverity: 0.0,
      maxSeverity: 0,
      minSeverity: 0,
      riskLevel: 'Baixo',
      totalOccurrences: 0,
      phases: [],
    );
  }
}

class TemporalAnalysis {
  final double trend;
  final Map<String, int> monthlyDistribution;
  final String peakPeriod;
  final int totalDays;
  final double averageOccurrencesPerDay;
  
  TemporalAnalysis({
    required this.trend,
    required this.monthlyDistribution,
    required this.peakPeriod,
    required this.totalDays,
    required this.averageOccurrencesPerDay,
  });
  
  factory TemporalAnalysis.empty() {
    return TemporalAnalysis(
      trend: 0.0,
      monthlyDistribution: {},
      peakPeriod: '',
      totalDays: 0,
      averageOccurrencesPerDay: 0.0,
    );
  }
}

class SpatialAnalysis {
  final double dispersion;
  final double affectedArea;
  final double density;
  final List<String> criticalPoints;
  final int totalPoints;
  
  SpatialAnalysis({
    required this.dispersion,
    required this.affectedArea,
    required this.density,
    required this.criticalPoints,
    required this.totalPoints,
  });
  
  factory SpatialAnalysis.empty() {
    return SpatialAnalysis(
      dispersion: 0.0,
      affectedArea: 0.0,
      density: 0.0,
      criticalPoints: [],
      totalPoints: 0,
    );
  }
}

class PredictionsAndRecommendations {
  final List<AIPointPrediction> pointPredictions;
  final List<TalhaoAIPrediction> talhaoPredictions;
  final String overallRisk;
  final List<String> recommendations;
  
  PredictionsAndRecommendations({
    required this.pointPredictions,
    required this.talhaoPredictions,
    required this.overallRisk,
    required this.recommendations,
  });
  
  factory PredictionsAndRecommendations.empty() {
    return PredictionsAndRecommendations(
      pointPredictions: [],
      talhaoPredictions: [],
      overallRisk: 'Baixo',
      recommendations: [],
    );
  }
}

class CriticalAlert {
  final String id;
  final String type;
  final String title;
  final String message;
  final int severity;
  final String priority;
  final List<String> recommendations;
  final DateTime timestamp;
  
  CriticalAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.priority,
    required this.recommendations,
    required this.timestamp,
  });
}
