import 'dart:math';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Resultado da análise de prioridade de infestação
class InfestationPriorityResult {
  final String organismId;
  final String organismName;
  final OccurrenceType organismType;
  final double infestationIndex;
  final String severityLevel;
  final double priorityScore;
  final String riskCategory;
  final List<String> recommendations;
  final String urgencyLevel;
  final DateTime detectedAt;
  final String location;

  InfestationPriorityResult({
    required this.organismId,
    required this.organismName,
    required this.organismType,
    required this.infestationIndex,
    required this.severityLevel,
    required this.priorityScore,
    required this.riskCategory,
    required this.recommendations,
    required this.urgencyLevel,
    required this.detectedAt,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'organismId': organismId,
      'organismName': organismName,
      'organismType': organismType.toString(),
      'infestationIndex': infestationIndex,
      'severityLevel': severityLevel,
      'priorityScore': priorityScore,
      'riskCategory': riskCategory,
      'recommendations': recommendations,
      'urgencyLevel': urgencyLevel,
      'detectedAt': detectedAt.toIso8601String(),
      'location': location,
    };
  }
}

/// Relatório consolidado de infestação por talhão
class TalhaoInfestationReport {
  final String talhaoId;
  final String talhaoName;
  final DateTime reportDate;
  final List<InfestationPriorityResult> criticalInfestations;
  final List<InfestationPriorityResult> highInfestations;
  final List<InfestationPriorityResult> moderateInfestations;
  final List<InfestationPriorityResult> lowInfestations;
  final double overallRiskScore;
  final String overallRiskLevel;
  final List<String> urgentActions;
  final Map<String, int> organismCounts;
  final Map<String, double> averageInfestationByType;

  TalhaoInfestationReport({
    required this.talhaoId,
    required this.talhaoName,
    required this.reportDate,
    required this.criticalInfestations,
    required this.highInfestations,
    required this.moderateInfestations,
    required this.lowInfestations,
    required this.overallRiskScore,
    required this.overallRiskLevel,
    required this.urgentActions,
    required this.organismCounts,
    required this.averageInfestationByType,
  });

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'talhaoName': talhaoName,
      'reportDate': reportDate.toIso8601String(),
      'criticalInfestations': criticalInfestations.map((e) => e.toMap()).toList(),
      'highInfestations': highInfestations.map((e) => e.toMap()).toList(),
      'moderateInfestations': moderateInfestations.map((e) => e.toMap()).toList(),
      'lowInfestations': lowInfestations.map((e) => e.toMap()).toList(),
      'overallRiskScore': overallRiskScore,
      'overallRiskLevel': overallRiskLevel,
      'urgentActions': urgentActions,
      'organismCounts': organismCounts,
      'averageInfestationByType': averageInfestationByType,
    };
  }
}

/// Serviço de análise de prioridade de infestação
/// Implementa lógica inteligente para identificar e priorizar infestações
class InfestationPriorityAnalysisService {
  
  /// Analisa um monitoramento e retorna as infestações priorizadas
  Future<List<InfestationPriorityResult>> analyzeMonitoring(Monitoring monitoring) async {
    try {
      Logger.info('🔍 [PRIORIDADE] Analisando monitoramento: ${monitoring.id}');
      
      final allInfestations = <InfestationPriorityResult>[];
      
      // Processar cada ponto do monitoramento
      for (final point in monitoring.points) {
        if (point.occurrences.isNotEmpty) {
          // Para cada ponto, analisar todas as ocorrências
          final pointInfestations = await _analyzePointInfestations(point, monitoring);
          allInfestations.addAll(pointInfestations);
        }
      }
      
      // Ordenar por prioridade (mais crítico primeiro)
      allInfestations.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      
      Logger.info('📊 [PRIORIDADE] ${allInfestations.length} infestações analisadas');
      return allInfestations;
      
    } catch (e) {
      Logger.error('❌ [PRIORIDADE] Erro na análise: $e');
      return [];
    }
  }

  /// Analisa infestações de um ponto específico
  Future<List<InfestationPriorityResult>> _analyzePointInfestations(
    MonitoringPoint point, 
    Monitoring monitoring
  ) async {
    final results = <InfestationPriorityResult>[];
    
    for (final occurrence in point.occurrences) {
      // Calcular score de prioridade baseado em múltiplos fatores
      final priorityScore = _calculatePriorityScore(occurrence, point, monitoring);
      
      // Determinar nível de severidade
      final severityLevel = _determineSeverityLevel(occurrence.infestationIndex, occurrence.type);
      
      // Determinar categoria de risco
      final riskCategory = _determineRiskCategory(occurrence.type, occurrence.infestationIndex);
      
      // Gerar recomendações
      final recommendations = _generateRecommendations(occurrence, severityLevel);
      
      // Determinar urgência
      final urgencyLevel = _determineUrgencyLevel(priorityScore, severityLevel);
      
      final result = InfestationPriorityResult(
        organismId: occurrence.name,
        organismName: occurrence.name,
        organismType: occurrence.type,
        infestationIndex: occurrence.infestationIndex,
        severityLevel: severityLevel,
        priorityScore: priorityScore,
        riskCategory: riskCategory,
        recommendations: recommendations,
        urgencyLevel: urgencyLevel,
        detectedAt: point.createdAt,
        location: 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}',
      );
      
      results.add(result);
    }
    
    return results;
  }

  /// Calcula score de prioridade baseado em múltiplos fatores
  double _calculatePriorityScore(Occurrence occurrence, MonitoringPoint point, Monitoring monitoring) {
    double score = 0.0;
    
    // 1. Fator base: índice de infestação (0-100)
    score += occurrence.infestationIndex;
    
    // 2. Fator de tipo de organismo (multiplicadores)
    double typeMultiplier = _getTypeMultiplier(occurrence.type);
    score *= typeMultiplier;
    
    // 3. Fator de precisão GPS (pontos mais precisos têm maior prioridade)
    final accuracyFactor = _getAccuracyFactor(point.gpsAccuracy ?? 10.0);
    score *= accuracyFactor;
    
    // 4. Fator de recência (dados mais recentes têm maior prioridade)
    final recencyFactor = _getRecencyFactor(point.createdAt);
    score *= recencyFactor;
    
    // 5. Fator de seções afetadas (mais seções = maior prioridade)
    final sectionsFactor = _getSectionsFactor(occurrence.affectedSections.map((s) => s.toString()).toList());
    score *= sectionsFactor;
    
    // 6. Fator de múltiplas infestações no mesmo ponto
    final multipleInfestationFactor = _getMultipleInfestationFactor(point.occurrences.length);
    score *= multipleInfestationFactor;
    
    return score.clamp(0.0, 1000.0); // Limitar a 1000 para facilitar comparação
  }

  /// Multiplicadores por tipo de organismo
  double _getTypeMultiplier(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.disease:
        return 3.0; // Doenças são 3x mais críticas
      case OccurrenceType.pest:
        return 2.5; // Pragas são 2.5x mais críticas
      case OccurrenceType.deficiency:
        return 2.0; // Deficiências são 2x mais críticas
      case OccurrenceType.weed:
        return 1.5; // Plantas daninhas são 1.5x mais críticas
      default:
        return 1.0;
    }
  }

  /// Fator de precisão GPS
  double _getAccuracyFactor(double accuracy) {
    if (accuracy <= 2.0) return 1.2; // Muito preciso
    if (accuracy <= 5.0) return 1.1; // Preciso
    if (accuracy <= 10.0) return 1.0; // Normal
    return 0.9; // Menos preciso
  }

  /// Fator de recência
  double _getRecencyFactor(DateTime detectedAt) {
    final hoursSinceDetection = DateTime.now().difference(detectedAt).inHours;
    if (hoursSinceDetection <= 1) return 1.3; // Muito recente
    if (hoursSinceDetection <= 6) return 1.2; // Recente
    if (hoursSinceDetection <= 24) return 1.1; // Recente
    if (hoursSinceDetection <= 72) return 1.0; // Normal
    return 0.9; // Antigo
  }

  /// Fator de seções afetadas
  double _getSectionsFactor(List<String> sections) {
    if (sections.isEmpty) return 1.0;
    if (sections.length == 1) return 1.1;
    if (sections.length == 2) return 1.2;
    return 1.3; // 3 ou mais seções
  }

  /// Fator de múltiplas infestações
  double _getMultipleInfestationFactor(int infestationCount) {
    if (infestationCount == 1) return 1.0;
    if (infestationCount == 2) return 1.2;
    if (infestationCount == 3) return 1.4;
    return 1.6; // 4 ou mais infestações
  }

  /// Determina nível de severidade
  String _determineSeverityLevel(double infestationIndex, OccurrenceType type) {
    // Ajustar thresholds baseado no tipo de organismo
    double lowThreshold = 25.0;
    double moderateThreshold = 50.0;
    double highThreshold = 75.0;
    
    switch (type) {
      case OccurrenceType.disease:
        // Doenças são mais críticas - thresholds menores
        lowThreshold = 15.0;
        moderateThreshold = 30.0;
        highThreshold = 50.0;
        break;
      case OccurrenceType.pest:
        // Pragas têm thresholds normais
        break;
      case OccurrenceType.deficiency:
        // Deficiências são críticas - thresholds menores
        lowThreshold = 20.0;
        moderateThreshold = 40.0;
        highThreshold = 60.0;
        break;
      case OccurrenceType.weed:
        // Plantas daninhas são menos críticas - thresholds maiores
        lowThreshold = 30.0;
        moderateThreshold = 60.0;
        highThreshold = 80.0;
        break;
      case OccurrenceType.other:
        // Outros tipos usam thresholds padrão
        break;
    }
    
    if (infestationIndex <= lowThreshold) return 'BAIXO';
    if (infestationIndex <= moderateThreshold) return 'MODERADO';
    if (infestationIndex <= highThreshold) return 'ALTO';
    return 'CRÍTICO';
  }

  /// Determina categoria de risco
  String _determineRiskCategory(OccurrenceType type, double infestationIndex) {
    if (type == OccurrenceType.disease && infestationIndex >= 30) return 'RISCO_ALTO';
    if (type == OccurrenceType.pest && infestationIndex >= 60) return 'RISCO_ALTO';
    if (type == OccurrenceType.deficiency && infestationIndex >= 40) return 'RISCO_ALTO';
    if (infestationIndex >= 80) return 'RISCO_CRÍTICO';
    if (infestationIndex >= 50) return 'RISCO_MÉDIO';
    return 'RISCO_BAIXO';
  }

  /// Gera recomendações baseadas na infestação
  List<String> _generateRecommendations(Occurrence occurrence, String severityLevel) {
    final recommendations = <String>[];
    
    // Recomendações baseadas no tipo
    switch (occurrence.type) {
      case OccurrenceType.disease:
        recommendations.add('Aplicar fungicida preventivo');
        recommendations.add('Melhorar ventilação da área');
        if (severityLevel == 'CRÍTICO') {
          recommendations.add('Aplicação imediata de fungicida curativo');
          recommendations.add('Remover plantas severamente afetadas');
        }
        break;
      case OccurrenceType.pest:
        recommendations.add('Aplicar inseticida específico');
        recommendations.add('Monitorar população de predadores naturais');
        if (severityLevel == 'CRÍTICO') {
          recommendations.add('Aplicação imediata de inseticida de contato');
          recommendations.add('Considerar controle biológico');
        }
        break;
      case OccurrenceType.deficiency:
        recommendations.add('Aplicar fertilizante específico');
        recommendations.add('Verificar pH do solo');
        if (severityLevel == 'CRÍTICO') {
          recommendations.add('Aplicação foliar imediata');
          recommendations.add('Análise completa do solo');
        }
        break;
      case OccurrenceType.weed:
        recommendations.add('Aplicar herbicida seletivo');
        recommendations.add('Capina manual em áreas críticas');
        if (severityLevel == 'CRÍTICO') {
          recommendations.add('Aplicação imediata de herbicida');
          recommendations.add('Cobertura do solo com palha');
        }
        break;
      case OccurrenceType.other:
        recommendations.add('Avaliar situação específica');
        recommendations.add('Consultar especialista');
        if (severityLevel == 'CRÍTICO') {
          recommendations.add('Ação imediata necessária');
          recommendations.add('Documentar detalhadamente');
        }
        break;
    }
    
    // Recomendações baseadas na severidade
    if (severityLevel == 'CRÍTICO') {
      recommendations.add('Reavaliar em 24-48 horas');
      recommendations.add('Documentar com fotos');
    } else if (severityLevel == 'ALTO') {
      recommendations.add('Reavaliar em 3-5 dias');
    }
    
    return recommendations;
  }

  /// Determina nível de urgência
  String _determineUrgencyLevel(double priorityScore, String severityLevel) {
    if (severityLevel == 'CRÍTICO' || priorityScore >= 800) return 'URGENTE';
    if (severityLevel == 'ALTO' || priorityScore >= 600) return 'ALTA';
    if (severityLevel == 'MODERADO' || priorityScore >= 400) return 'MÉDIA';
    return 'BAIXA';
  }

  /// Gera relatório consolidado por talhão
  Future<TalhaoInfestationReport> generateTalhaoReport(
    String talhaoId,
    String talhaoName,
    List<Monitoring> monitorings,
  ) async {
    try {
      Logger.info('📊 [RELATÓRIO] Gerando relatório para talhão: $talhaoName');
      
      final allInfestations = <InfestationPriorityResult>[];
      
      // Analisar todos os monitoramentos do talhão
      for (final monitoring in monitorings) {
        final infestations = await analyzeMonitoring(monitoring);
        allInfestations.addAll(infestations);
      }
      
      // Agrupar por nível de severidade
      final criticalInfestations = allInfestations.where((i) => i.severityLevel == 'CRÍTICO').toList();
      final highInfestations = allInfestations.where((i) => i.severityLevel == 'ALTO').toList();
      final moderateInfestations = allInfestations.where((i) => i.severityLevel == 'MODERADO').toList();
      final lowInfestations = allInfestations.where((i) => i.severityLevel == 'BAIXO').toList();
      
      // Calcular score geral de risco
      final overallRiskScore = _calculateOverallRiskScore(allInfestations);
      final overallRiskLevel = _determineOverallRiskLevel(overallRiskScore);
      
      // Gerar ações urgentes
      final urgentActions = _generateUrgentActions(criticalInfestations, highInfestations);
      
      // Contar organismos por tipo
      final organismCounts = _countOrganismsByType(allInfestations);
      
      // Calcular média de infestação por tipo
      final averageInfestationByType = _calculateAverageInfestationByType(allInfestations);
      
      final report = TalhaoInfestationReport(
        talhaoId: talhaoId,
        talhaoName: talhaoName,
        reportDate: DateTime.now(),
        criticalInfestations: criticalInfestations,
        highInfestations: highInfestations,
        moderateInfestations: moderateInfestations,
        lowInfestations: lowInfestations,
        overallRiskScore: overallRiskScore,
        overallRiskLevel: overallRiskLevel,
        urgentActions: urgentActions,
        organismCounts: organismCounts,
        averageInfestationByType: averageInfestationByType,
      );
      
      Logger.info('✅ [RELATÓRIO] Relatório gerado para $talhaoName');
      Logger.info('   🚨 Críticas: ${criticalInfestations.length}');
      Logger.info('   ⚠️ Altas: ${highInfestations.length}');
      Logger.info('   📊 Moderadas: ${moderateInfestations.length}');
      Logger.info('   ✅ Baixas: ${lowInfestations.length}');
      
      return report;
      
    } catch (e) {
      Logger.error('❌ [RELATÓRIO] Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Calcula score geral de risco do talhão
  double _calculateOverallRiskScore(List<InfestationPriorityResult> infestations) {
    if (infestations.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    for (final infestation in infestations) {
      totalScore += infestation.priorityScore;
    }
    
    return (totalScore / infestations.length).clamp(0.0, 1000.0);
  }

  /// Determina nível geral de risco
  String _determineOverallRiskLevel(double riskScore) {
    if (riskScore >= 800) return 'CRÍTICO';
    if (riskScore >= 600) return 'ALTO';
    if (riskScore >= 400) return 'MÉDIO';
    return 'BAIXO';
  }

  /// Gera ações urgentes
  List<String> _generateUrgentActions(
    List<InfestationPriorityResult> critical,
    List<InfestationPriorityResult> high,
  ) {
    final actions = <String>[];
    
    if (critical.isNotEmpty) {
      actions.add('🚨 AÇÃO IMEDIATA: ${critical.length} infestações críticas detectadas');
      actions.add('📞 Contatar agrônomo responsável');
      actions.add('🔬 Coletar amostras para análise laboratorial');
    }
    
    if (high.isNotEmpty) {
      actions.add('⚠️ ATENÇÃO: ${high.length} infestações de alto risco');
      actions.add('📋 Planejar aplicação de defensivos');
    }
    
    if (critical.isNotEmpty || high.isNotEmpty) {
      actions.add('📸 Documentar com fotos todas as ocorrências');
      actions.add('📝 Atualizar plano de manejo integrado');
    }
    
    return actions;
  }

  /// Conta organismos por tipo
  Map<String, int> _countOrganismsByType(List<InfestationPriorityResult> infestations) {
    final counts = <String, int>{};
    
    for (final infestation in infestations) {
      final type = infestation.organismType.toString().split('.').last;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Calcula média de infestação por tipo
  Map<String, double> _calculateAverageInfestationByType(List<InfestationPriorityResult> infestations) {
    final typeGroups = <String, List<double>>{};
    
    for (final infestation in infestations) {
      final type = infestation.organismType.toString().split('.').last;
      typeGroups.putIfAbsent(type, () => []).add(infestation.infestationIndex);
    }
    
    final averages = <String, double>{};
    for (final entry in typeGroups.entries) {
      final type = entry.key;
      final values = entry.value;
      averages[type] = values.reduce((a, b) => a + b) / values.length;
    }
    
    return averages;
  }
}
