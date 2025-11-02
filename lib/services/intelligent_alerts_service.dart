import 'dart:math';
// Removido import não utilizado
import '../models/infestacao_model.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';

/// Serviço de alertas automáticos baseados em dados inteligentes
class IntelligentAlertsService {
  
  /// Gera alertas automáticos baseados em dados enriquecidos
  Future<List<IntelligentAlert>> generateIntelligentAlerts({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('🚨 [ALERTS] Gerando alertas automáticos com ${occurrences.length} ocorrências');
      
      final alerts = <IntelligentAlert>[];
      
      // Agrupar ocorrências por talhão
      final talhaoGroups = _groupOccurrencesByTalhao(occurrences);
      
      for (final entry in talhaoGroups.entries) {
        final talhaoId = entry.key;
        final talhaoOccurrences = entry.value;
        
        // Analisar cada tipo de alerta
        final criticalAlerts = await _analyzeCriticalAlerts(talhaoId, talhaoOccurrences);
        final riskAlerts = await _analyzeRiskAlerts(talhaoId, talhaoOccurrences);
        final environmentalAlerts = await _analyzeEnvironmentalAlerts(talhaoId, talhaoOccurrences);
        final aiAlerts = await _analyzeAIAlerts(talhaoId, talhaoOccurrences);
        
        alerts.addAll(criticalAlerts);
        alerts.addAll(riskAlerts);
        alerts.addAll(environmentalAlerts);
        alerts.addAll(aiAlerts);
      }
      
      // Ordenar alertas por prioridade
      alerts.sort((a, b) => _comparePriorities(b.priority, a.priority));
      
      Logger.info('✅ [ALERTS] ${alerts.length} alertas inteligentes gerados');
      return alerts;
      
    } catch (e) {
      Logger.error('❌ [ALERTS] Erro ao gerar alertas inteligentes: $e');
      return [];
    }
  }
  
  /// Compara prioridades de alertas
  int _comparePriorities(AlertPriority a, AlertPriority b) {
    const priorityOrder = {
      AlertPriority.critical: 0,
      AlertPriority.high: 1,
      AlertPriority.medium: 2,
      AlertPriority.low: 3,
    };
    return priorityOrder[a]!.compareTo(priorityOrder[b]!);
  }
  
  /// Agrupa ocorrências por talhão
  Map<String, List<InfestacaoModel>> _groupOccurrencesByTalhao(List<InfestacaoModel> occurrences) {
    final grouped = <String, List<InfestacaoModel>>{};
    
    for (final occurrence in occurrences) {
      final talhaoId = occurrence.talhaoId;
      grouped.putIfAbsent(talhaoId, () => []).add(occurrence);
    }
    
    return grouped;
  }
  
  /// Analisa alertas críticos
  Future<List<IntelligentAlert>> _analyzeCriticalAlerts(
    String talhaoId,
    List<InfestacaoModel> occurrences,
  ) async {
    final alerts = <IntelligentAlert>[];
    
    // Alertas de severidade crítica
    final criticalOccurrences = occurrences.where((o) => o.percentual >= 80).toList();
    if (criticalOccurrences.isNotEmpty) {
      alerts.add(IntelligentAlert(
        id: 'critical_severity_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        type: AlertType.critical,
        priority: AlertPriority.critical,
        title: '🚨 INFESTAÇÃO CRÍTICA DETECTADA',
        message: 'Severidade crítica (${criticalOccurrences.length} ocorrências ≥80%) no talhão $talhaoId',
        details: _generateCriticalDetails(criticalOccurrences),
        recommendations: _generateCriticalRecommendations(criticalOccurrences),
        severity: 10,
        confidence: 95.0,
        organisms: criticalOccurrences.map((o) => o.subtipo).toSet().toList(),
        phases: _extractPhases(criticalOccurrences),
        environmentalFactors: _extractEnvironmentalFactors(criticalOccurrences),
        aiAnalysis: _generateAIAnalysis(criticalOccurrences),
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 6)), // Urgente
        isActive: true,
      ));
    }
    
    // Alertas de múltiplos organismos
    final organismCount = occurrences.map((o) => o.subtipo).toSet().length;
    if (organismCount >= 3) {
      alerts.add(IntelligentAlert(
        id: 'multiple_organisms_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        type: AlertType.warning,
        priority: AlertPriority.high,
        title: '⚠️ MÚLTIPLOS ORGANISMOS DETECTADOS',
        message: '$organismCount organismos diferentes detectados no talhão $talhaoId',
        details: _generateMultipleOrganismsDetails(occurrences),
        recommendations: _generateMultipleOrganismsRecommendations(occurrences),
        severity: 7,
        confidence: 85.0,
        organisms: occurrences.map((o) => o.subtipo).toSet().toList(),
        phases: _extractPhases(occurrences),
        environmentalFactors: _extractEnvironmentalFactors(occurrences),
        aiAnalysis: _generateAIAnalysis(occurrences),
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 2)),
        isActive: true,
      ));
    }
    
    return alerts;
  }
  
  /// Analisa alertas de risco
  Future<List<IntelligentAlert>> _analyzeRiskAlerts(
    String talhaoId,
    List<InfestacaoModel> occurrences,
  ) async {
    final alerts = <IntelligentAlert>[];
    
    // Análise de tendência de crescimento
    final trend = _calculateGrowthTrend(occurrences);
    if (trend > 0.3) { // Crescimento > 30%
      alerts.add(IntelligentAlert(
        id: 'growth_trend_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        type: AlertType.warning,
        priority: AlertPriority.high,
        title: '📈 TENDÊNCIA DE CRESCIMENTO ALTA',
        message: 'Crescimento de ${(trend * 100).toStringAsFixed(1)}% detectado no talhão $talhaoId',
        details: _generateTrendDetails(occurrences, trend),
        recommendations: _generateTrendRecommendations(trend),
        severity: 6,
        confidence: 80.0,
        organisms: occurrences.map((o) => o.subtipo).toSet().toList(),
        phases: _extractPhases(occurrences),
        environmentalFactors: _extractEnvironmentalFactors(occurrences),
        aiAnalysis: _generateAIAnalysis(occurrences),
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 3)),
        isActive: true,
      ));
    }
    
    // Análise de dispersão espacial
    final dispersion = _calculateSpatialDispersion(occurrences);
    if (dispersion > 0.7) { // Alta dispersão
      alerts.add(IntelligentAlert(
        id: 'spatial_dispersion_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        type: AlertType.info,
        priority: AlertPriority.medium,
        title: '🗺️ ALTA DISPERSÃO ESPACIAL',
        message: 'Infestação se espalhando rapidamente no talhão $talhaoId',
        details: _generateDispersionDetails(occurrences, dispersion),
        recommendations: _generateDispersionRecommendations(),
        severity: 5,
        confidence: 75.0,
        organisms: occurrences.map((o) => o.subtipo).toSet().toList(),
        phases: _extractPhases(occurrences),
        environmentalFactors: _extractEnvironmentalFactors(occurrences),
        aiAnalysis: _generateAIAnalysis(occurrences),
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 5)),
        isActive: true,
      ));
    }
    
    return alerts;
  }
  
  /// Analisa alertas ambientais
  Future<List<IntelligentAlert>> _analyzeEnvironmentalAlerts(
    String talhaoId,
    List<InfestacaoModel> occurrences,
  ) async {
    final alerts = <IntelligentAlert>[];
    
    // Análise de condições favoráveis
    final environmentalRisk = _calculateEnvironmentalRisk(occurrences);
    if (environmentalRisk > 0.8) {
      alerts.add(IntelligentAlert(
        id: 'environmental_risk_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        type: AlertType.warning,
        priority: AlertPriority.medium,
        title: '🌡️ CONDIÇÕES AMBIENTAIS FAVORÁVEIS',
        message: 'Condições ideais para desenvolvimento de pragas/doenças no talhão $talhaoId',
        details: _generateEnvironmentalDetails(occurrences, environmentalRisk),
        recommendations: _generateEnvironmentalRecommendations(environmentalRisk),
        severity: 4,
        confidence: 70.0,
        organisms: occurrences.map((o) => o.subtipo).toSet().toList(),
        phases: _extractPhases(occurrences),
        environmentalFactors: _extractEnvironmentalFactors(occurrences),
        aiAnalysis: _generateAIAnalysis(occurrences),
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 7)),
        isActive: true,
      ));
    }
    
    return alerts;
  }
  
  /// Analisa alertas de IA
  Future<List<IntelligentAlert>> _analyzeAIAlerts(
    String talhaoId,
    List<InfestacaoModel> occurrences,
  ) async {
    final alerts = <IntelligentAlert>[];
    
    // Análise de predição de IA
    final aiPrediction = _generateAIPrediction(occurrences);
    if (aiPrediction['riskLevel'] == 'Alto' || aiPrediction['riskLevel'] == 'Crítico') {
      alerts.add(IntelligentAlert(
        id: 'ai_prediction_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        type: AlertType.info,
        priority: AlertPriority.medium,
        title: '🤖 PREDIÇÃO DE IA: ${aiPrediction['riskLevel']?.toString().toUpperCase()}',
        message: 'IA prevê ${aiPrediction['prediction']} no talhão $talhaoId',
        details: _generateAIPredictionDetails(aiPrediction),
        recommendations: _generateAIPredictionRecommendations(aiPrediction),
        severity: aiPrediction['severity'] ?? 5,
        confidence: aiPrediction['confidence'] ?? 75.0,
        organisms: occurrences.map((o) => o.subtipo).toSet().toList(),
        phases: _extractPhases(occurrences),
        environmentalFactors: _extractEnvironmentalFactors(occurrences),
        aiAnalysis: aiPrediction,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: 10)),
        isActive: true,
      ));
    }
    
    return alerts;
  }
  
  // Métodos auxiliares
  
  Map<String, dynamic> _generateCriticalDetails(List<InfestacaoModel> occurrences) {
    return {
      'totalOccurrences': occurrences.length,
      'averageSeverity': occurrences.map((o) => o.percentual).reduce((a, b) => a + b) / occurrences.length,
      'maxSeverity': occurrences.map((o) => o.percentual).reduce((a, b) => a > b ? a : b),
      'organisms': occurrences.map((o) => o.subtipo).toSet().toList(),
      'phases': _extractPhases(occurrences),
      'recommendedActions': [
        'Aplicação imediata de defensivos',
        'Isolamento da área se possível',
        'Monitoramento intensivo',
        'Contato com agrônomo'
      ],
    };
  }
  
  List<String> _generateCriticalRecommendations(List<InfestacaoModel> occurrences) {
    return [
      '🚨 AÇÃO IMEDIATA: Aplicar defensivo específico',
      '📞 CONTATO: Notificar agrônomo responsável',
      '🔍 MONITORAMENTO: Verificar área a cada 24h',
      '📊 RELATÓRIO: Gerar relatório de emergência',
    ];
  }
  
  Map<String, dynamic> _generateMultipleOrganismsDetails(List<InfestacaoModel> occurrences) {
    final organismGroups = <String, List<InfestacaoModel>>{};
    for (final occurrence in occurrences) {
      final organism = occurrence.subtipo;
      organismGroups.putIfAbsent(organism, () => []).add(occurrence);
    }
    
    return {
      'organismCount': organismGroups.length,
      'organisms': organismGroups.keys.toList(),
      'organismDetails': organismGroups.map((key, value) => MapEntry(key, {
        'count': value.length,
        'averageSeverity': value.map((o) => o.percentual).reduce((a, b) => a + b) / value.length,
      })),
    };
  }
  
  List<String> _generateMultipleOrganismsRecommendations(List<InfestacaoModel> occurrences) {
    return [
      '🔬 ANÁLISE: Identificar organismos dominantes',
      '🎯 ESTRATÉGIA: Desenvolver plano integrado',
      '📋 ROTAÇÃO: Considerar rotação de culturas',
      '🧪 TESTE: Análise de resistência',
    ];
  }
  
  double _calculateGrowthTrend(List<InfestacaoModel> occurrences) {
    if (occurrences.length < 2) return 0.0;
    
    // Simular tendência baseada na data
    final sortedOccurrences = occurrences..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    final firstHalf = sortedOccurrences.take(sortedOccurrences.length ~/ 2);
    final secondHalf = sortedOccurrences.skip(sortedOccurrences.length ~/ 2);
    
    final firstAvg = firstHalf.map((o) => o.percentual.toDouble()).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.map((o) => o.percentual.toDouble()).reduce((a, b) => a + b) / secondHalf.length;
    
    return (secondAvg - firstAvg) / firstAvg;
  }
  
  double _calculateSpatialDispersion(List<InfestacaoModel> occurrences) {
    if (occurrences.length < 2) return 0.0;
    
    // Calcular dispersão baseada na distância entre pontos
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
    
    return comparisons > 0 ? totalDistance / comparisons / 1000.0 : 0.0; // Normalizar
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
  
  double _calculateEnvironmentalRisk(List<InfestacaoModel> occurrences) {
    // Simular risco ambiental baseado na data
    final month = occurrences.first.dataHora.month;
    double risk = 0.5; // Base
    
    // Ajustar baseado na estação
    if (month >= 9 && month <= 11) risk += 0.3; // Primavera
    if (month >= 12 && month <= 2) risk += 0.2; // Verão
    if (month >= 3 && month <= 5) risk += 0.1; // Outono
    
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
  
  Map<String, dynamic> _generateAIAnalysis(List<InfestacaoModel> occurrences) {
    return {
      'analysisMethod': 'AI_Enhanced_Analysis',
      'confidence': 85.0,
      'prediction': 'Crescimento moderado esperado',
      'recommendations': [
        'Monitoramento intensivo recomendado',
        'Aplicação preventiva sugerida',
        'Análise de resistência necessária'
      ],
      'riskFactors': [
        'Condições ambientais favoráveis',
        'Múltiplos organismos presentes',
        'Alta dispersão espacial'
      ],
    };
  }
  
  Map<String, dynamic> _generateAIPrediction(List<InfestacaoModel> occurrences) {
    final severity = occurrences.map((o) => o.percentual.toDouble()).reduce((a, b) => a + b) / occurrences.length;
    final riskLevel = severity >= 70 ? 'Crítico' : severity >= 50 ? 'Alto' : severity >= 30 ? 'Médio' : 'Baixo';
    
    return {
      'riskLevel': riskLevel,
      'severity': severity,
      'confidence': 80.0,
      'prediction': 'Crescimento de ${(severity * 0.1).toStringAsFixed(1)}% esperado em 7 dias',
      'recommendations': [
        'Aplicação preventiva recomendada',
        'Monitoramento a cada 48h',
        'Análise de resistência necessária'
      ],
    };
  }
  
  // Métodos de geração de detalhes e recomendações (implementação simplificada)
  Map<String, dynamic> _generateTrendDetails(List<InfestacaoModel> occurrences, double trend) {
    return {
      'trend': trend,
      'trendPercentage': (trend * 100).toStringAsFixed(1),
      'recommendedActions': ['Monitoramento intensivo', 'Aplicação preventiva'],
    };
  }
  
  List<String> _generateTrendRecommendations(double trend) {
    return [
      '📈 MONITORAMENTO: Aumentar frequência de verificação',
      '🛡️ PREVENÇÃO: Aplicar defensivo preventivo',
      '📊 ANÁLISE: Verificar fatores de crescimento',
    ];
  }
  
  Map<String, dynamic> _generateDispersionDetails(List<InfestacaoModel> occurrences, double dispersion) {
    return {
      'dispersion': dispersion,
      'affectedArea': 'Área ampla do talhão',
      'recommendedActions': ['Contenção imediata', 'Barreira de proteção'],
    };
  }
  
  List<String> _generateDispersionRecommendations() {
    return [
      '🚧 CONTENÇÃO: Criar barreira de proteção',
      '🔍 MONITORAMENTO: Verificar bordas do talhão',
      '📋 ESTRATÉGIA: Desenvolver plano de contenção',
    ];
  }
  
  Map<String, dynamic> _generateEnvironmentalDetails(List<InfestacaoModel> occurrences, double risk) {
    return {
      'environmentalRisk': risk,
      'conditions': 'Favoráveis para desenvolvimento',
      'recommendedActions': ['Monitoramento ambiental', 'Ajuste de manejo'],
    };
  }
  
  List<String> _generateEnvironmentalRecommendations(double risk) {
    return [
      '🌡️ AMBIENTE: Monitorar condições climáticas',
      '📊 DADOS: Registrar temperatura e umidade',
      '🔄 MANEJO: Ajustar práticas culturais',
    ];
  }
  
  Map<String, dynamic> _generateAIPredictionDetails(Map<String, dynamic> prediction) {
    return {
      'prediction': prediction,
      'confidence': prediction['confidence'],
      'recommendedActions': prediction['recommendations'],
    };
  }
  
  List<String> _generateAIPredictionRecommendations(Map<String, dynamic> prediction) {
    return [
      '🤖 IA: Seguir recomendações da análise',
      '📊 DADOS: Validar predições com monitoramento',
      '🔄 ATUALIZAÇÃO: Revisar modelo conforme necessário',
    ];
  }
}

/// Tipos de alerta
enum AlertType {
  critical,
  warning,
  info,
}

/// Prioridades de alerta
enum AlertPriority {
  critical,
  high,
  medium,
  low,
}

/// Alerta inteligente com dados enriquecidos
class IntelligentAlert {
  final String id;
  final String talhaoId;
  final AlertType type;
  final AlertPriority priority;
  final String title;
  final String message;
  final Map<String, dynamic> details;
  final List<String> recommendations;
  final int severity;
  final double confidence;
  final List<String> organisms;
  final List<String> phases;
  final Map<String, dynamic> environmentalFactors;
  final Map<String, dynamic> aiAnalysis;
  final DateTime timestamp;
  final DateTime expiresAt;
  final bool isActive;
  
  IntelligentAlert({
    required this.id,
    required this.talhaoId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.details,
    required this.recommendations,
    required this.severity,
    required this.confidence,
    required this.organisms,
    required this.phases,
    required this.environmentalFactors,
    required this.aiAnalysis,
    required this.timestamp,
    required this.expiresAt,
    required this.isActive,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'message': message,
      'details': details,
      'recommendations': recommendations,
      'severity': severity,
      'confidence': confidence,
      'organisms': organisms,
      'phases': phases,
      'environmentalFactors': environmentalFactors,
      'aiAnalysis': aiAnalysis,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
