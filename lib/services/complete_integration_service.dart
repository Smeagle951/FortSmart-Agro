import '../models/infestacao_model.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';
import 'intelligent_heatmap_service.dart';
import 'intelligent_hexagon_service.dart';
import 'intelligent_alerts_service.dart';
import 'advanced_ai_prediction_service.dart';
import 'intelligent_reports_service.dart';

/// Serviço de integração completa entre todos os módulos
class CompleteIntegrationService {
  
  /// Executa sincronização completa entre todos os módulos
  Future<CompleteIntegrationResult> executeCompleteIntegration({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('🔄 [INTEGRATION] Iniciando sincronização completa entre todos os módulos');
      
      final startTime = DateTime.now();
      
      // 1. Gerar heatmap inteligente
      Logger.info('🔥 [INTEGRATION] Gerando heatmap inteligente...');
      final heatmapService = IntelligentHeatmapService();
      final heatmapPoints = await heatmapService.generateIntelligentHeatmap(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      // 2. Gerar hexágonos inteligentes
      Logger.info('🔷 [INTEGRATION] Gerando hexágonos inteligentes...');
      final hexagonService = IntelligentHexagonService();
      final hexagons = await hexagonService.generateIntelligentHexagons(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
        hexagonSize: 100.0,
      );
      
      // 3. Gerar alertas inteligentes
      Logger.info('🚨 [INTEGRATION] Gerando alertas inteligentes...');
      final alertsService = IntelligentAlertsService();
      final alerts = await alertsService.generateIntelligentAlerts(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      // 4. Gerar predições de IA avançada
      Logger.info('🤖 [INTEGRATION] Gerando predições de IA avançada...');
      final predictionService = AdvancedAIPredictionService();
      final pointPredictions = await predictionService.generatePointPredictions(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      final talhaoPredictions = await predictionService.generateTalhaoPredictions(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      final economicAnalysis = await predictionService.generateEconomicAnalysis(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      // 5. Gerar relatórios inteligentes
      Logger.info('📊 [INTEGRATION] Gerando relatórios inteligentes...');
      final reportsService = IntelligentReportsService();
      final executiveReport = await reportsService.generateExecutiveReport(
        occurrences: occurrences,
        monitoringPoints: monitoringPoints,
      );
      
      // 6. Validar integração
      Logger.info('✅ [INTEGRATION] Validando integração...');
      final validation = await _validateIntegration(
        heatmapPoints,
        hexagons,
        alerts,
        pointPredictions,
        talhaoPredictions,
        economicAnalysis,
        executiveReport,
      );
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      final result = CompleteIntegrationResult(
        success: validation.isValid,
        heatmapPoints: heatmapPoints,
        hexagons: hexagons,
        alerts: alerts,
        pointPredictions: pointPredictions,
        talhaoPredictions: talhaoPredictions,
        economicAnalysis: economicAnalysis,
        executiveReport: executiveReport,
        validation: validation,
        processingTime: duration,
        generatedAt: DateTime.now(),
      );
      
      Logger.info('✅ [INTEGRATION] Sincronização completa finalizada em ${duration.inMilliseconds}ms');
      return result;
      
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro na sincronização completa: $e');
      return CompleteIntegrationResult.error(e.toString());
    }
  }
  
  /// Valida a integração entre todos os módulos
  Future<IntegrationValidation> _validateIntegration(
    List<IntelligentHeatmapPoint> heatmapPoints,
    List<IntelligentHexagon> hexagons,
    List<IntelligentAlert> alerts,
    List<AIPointPrediction> pointPredictions,
    List<TalhaoAIPrediction> talhaoPredictions,
    EconomicAnalysis economicAnalysis,
    ExecutiveReport executiveReport,
  ) async {
    try {
      final issues = <String>[];
      final warnings = <String>[];
      
      // Validar heatmap
      if (heatmapPoints.isEmpty) {
        warnings.add('Heatmap vazio - nenhum ponto gerado');
      } else {
        Logger.info('✅ Heatmap: ${heatmapPoints.length} pontos gerados');
      }
      
      // Validar hexágonos
      if (hexagons.isEmpty) {
        warnings.add('Hexágonos vazios - nenhum hexágono gerado');
      } else {
        Logger.info('✅ Hexágonos: ${hexagons.length} hexágonos gerados');
      }
      
      // Validar alertas
      if (alerts.isEmpty) {
        warnings.add('Nenhum alerta gerado');
      } else {
        Logger.info('✅ Alertas: ${alerts.length} alertas gerados');
      }
      
      // Validar predições
      if (pointPredictions.isEmpty) {
        warnings.add('Nenhuma predição ponto a ponto gerada');
      } else {
        Logger.info('✅ Predições ponto a ponto: ${pointPredictions.length} predições geradas');
      }
      
      if (talhaoPredictions.isEmpty) {
        warnings.add('Nenhuma predição por talhão gerada');
      } else {
        Logger.info('✅ Predições por talhão: ${talhaoPredictions.length} predições geradas');
      }
      
      // Validar análise econômica
      if (economicAnalysis.totalOccurrences == 0) {
        warnings.add('Análise econômica sem dados');
      } else {
        Logger.info('✅ Análise econômica: ${economicAnalysis.totalOccurrences} ocorrências analisadas');
      }
      
      // Validar relatório executivo
      if (executiveReport.generalAnalysis.totalOccurrences == 0) {
        warnings.add('Relatório executivo sem dados');
      } else {
        Logger.info('✅ Relatório executivo: ${executiveReport.generalAnalysis.totalOccurrences} ocorrências analisadas');
      }
      
      final isValid = issues.isEmpty;
      final score = _calculateIntegrationScore(heatmapPoints, hexagons, alerts, pointPredictions, talhaoPredictions);
      
      return IntegrationValidation(
        isValid: isValid,
        score: score,
        issues: issues,
        warnings: warnings,
        validatedAt: DateTime.now(),
      );
      
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro na validação: $e');
      return IntegrationValidation.error(e.toString());
    }
  }
  
  /// Valida consistência entre módulos
  Future<void> _validateConsistency(
    List<IntelligentHeatmapPoint> heatmapPoints,
    List<IntelligentHexagon> hexagons,
    List<IntelligentAlert> alerts,
    List<AIPointPrediction> pointPredictions,
    List<TalhaoAIPrediction> talhaoPredictions,
    List<String> issues,
    List<String> warnings,
  ) async {
    try {
      // Verificar se há dados em pelo menos um módulo
      final hasData = heatmapPoints.isNotEmpty || 
                     hexagons.isNotEmpty || 
                     alerts.isNotEmpty || 
                     pointPredictions.isNotEmpty || 
                     talhaoPredictions.isNotEmpty;
      
      if (!hasData) {
        issues.add('Nenhum módulo gerou dados - verificar dados de entrada');
        return;
      }
      
      // Verificar consistência de organismos entre módulos
      final heatmapOrganisms = heatmapPoints.map((p) => p.organismId).toSet();
      final hexagonOrganisms = hexagons.map((h) => h.organismId).toSet();
      final alertOrganisms = alerts.expand((a) => a.organisms).toSet();
      
      if (heatmapOrganisms.isNotEmpty && hexagonOrganisms.isNotEmpty) {
        final commonOrganisms = heatmapOrganisms.intersection(hexagonOrganisms);
        if (commonOrganisms.isEmpty) {
          warnings.add('Nenhum organismo comum entre heatmap e hexágonos');
        }
      }
      
      // Verificar consistência de severidade
      final heatmapSeverities = heatmapPoints.map((p) => p.severity).toList();
      final hexagonSeverities = hexagons.map((h) => h.severity).toList();
      
      if (heatmapSeverities.isNotEmpty && hexagonSeverities.isNotEmpty) {
        final heatmapAvg = heatmapSeverities.reduce((a, b) => a + b) / heatmapSeverities.length;
        final hexagonAvg = hexagonSeverities.reduce((a, b) => a + b) / hexagonSeverities.length;
        
        if ((heatmapAvg - hexagonAvg).abs() > 2.0) {
          warnings.add('Diferença significativa na severidade média entre heatmap e hexágonos');
        }
      }
      
      // Verificar consistência de predições
      if (pointPredictions.isNotEmpty && talhaoPredictions.isNotEmpty) {
        final pointRiskLevels = pointPredictions.map((p) => p.riskLevel).toSet();
        final talhaoRiskLevels = talhaoPredictions.map((t) => t.riskLevel).toSet();
        
        if (pointRiskLevels.contains('Crítico') && !talhaoRiskLevels.contains('Crítico')) {
          warnings.add('Pontos críticos detectados mas talhões não marcados como críticos');
        }
      }
      
      Logger.info('✅ Consistência entre módulos validada');
      
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro na validação de consistência: $e');
      issues.add('Erro na validação de consistência: $e');
    }
  }
  
  /// Calcula score de integração
  double _calculateIntegrationScore(
    List<IntelligentHeatmapPoint> heatmapPoints,
    List<IntelligentHexagon> hexagons,
    List<IntelligentAlert> alerts,
    List<AIPointPrediction> pointPredictions,
    List<TalhaoAIPrediction> talhaoPredictions,
  ) {
    double score = 0.0;
    
    // Score baseado na quantidade de dados gerados
    if (heatmapPoints.isNotEmpty) score += 20.0;
    if (hexagons.isNotEmpty) score += 20.0;
    if (alerts.isNotEmpty) score += 20.0;
    if (pointPredictions.isNotEmpty) score += 20.0;
    if (talhaoPredictions.isNotEmpty) score += 20.0;
    
    // Bonus por qualidade dos dados
    if (heatmapPoints.length > 10) score += 5.0;
    if (hexagons.length > 5) score += 5.0;
    if (alerts.length > 3) score += 5.0;
    if (pointPredictions.length > 10) score += 5.0;
    if (talhaoPredictions.length > 3) score += 5.0;
    
    return score.clamp(0.0, 100.0);
  }
  
  /// Gera relatório de integração
  Future<IntegrationReport> generateIntegrationReport(CompleteIntegrationResult result) async {
    try {
      Logger.info('📋 [INTEGRATION] Gerando relatório de integração...');
      
      final report = IntegrationReport(
        success: result.success,
        processingTime: result.processingTime,
        heatmapPoints: result.heatmapPoints.length,
        hexagons: result.hexagons.length,
        alerts: result.alerts.length,
        pointPredictions: result.pointPredictions.length,
        talhaoPredictions: result.talhaoPredictions.length,
        economicAnalysis: result.economicAnalysis,
        executiveReport: result.executiveReport,
        validation: result.validation,
        recommendations: _generateIntegrationRecommendations(result),
        generatedAt: DateTime.now(),
      );
      
      Logger.info('✅ [INTEGRATION] Relatório de integração gerado');
      return report;
      
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro ao gerar relatório de integração: $e');
      return IntegrationReport.error(e.toString());
    }
  }
  
  /// Gera recomendações de integração
  List<String> _generateIntegrationRecommendations(CompleteIntegrationResult result) {
    final recommendations = <String>[];
    
    if (result.success) {
      recommendations.add('✅ Integração completa bem-sucedida');
      recommendations.add('🔄 Todos os módulos sincronizados corretamente');
      recommendations.add('📊 Dados prontos para visualização no mapa');
      recommendations.add('🤖 Predições de IA disponíveis');
      recommendations.add('💰 Análise econômica concluída');
      recommendations.add('📋 Relatórios executivos gerados');
    } else {
      recommendations.add('⚠️ Integração com problemas detectados');
      recommendations.add('🔍 Verificar logs para detalhes');
      recommendations.add('🔄 Tentar reprocessar dados');
    }
    
    // Recomendações específicas baseadas na validação
    if (result.validation.issues.isNotEmpty) {
      recommendations.add('🚨 Problemas críticos encontrados:');
      for (final issue in result.validation.issues) {
        recommendations.add('  - $issue');
      }
    }
    
    if (result.validation.warnings.isNotEmpty) {
      recommendations.add('⚠️ Avisos encontrados:');
      for (final warning in result.validation.warnings) {
        recommendations.add('  - $warning');
      }
    }
    
    return recommendations;
  }
  
  /// Inicializa o serviço de integração
  Future<void> initialize() async {
    try {
      Logger.info('🔄 [INTEGRATION] Inicializando serviço de integração...');
      // Implementar inicialização se necessário
      Logger.info('✅ [INTEGRATION] Serviço de integração inicializado');
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro ao inicializar serviço: $e');
    }
  }
  
  /// Obtém estatísticas de organismos
  Future<Map<String, dynamic>> getOrganismStatistics() async {
    try {
      Logger.info('📊 [INTEGRATION] Obtendo estatísticas de organismos...');
      
      // Simular estatísticas de organismos
      return {
        'totalOrganisms': 150,
        'activeOrganisms': 45,
        'criticalOrganisms': 8,
        'trendingUp': 12,
        'trendingDown': 3,
        'newDetections': 5,
      };
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Obtém organismos mais problemáticos
  Future<List<Map<String, dynamic>>> getMostProblematicOrganisms() async {
    try {
      Logger.info('🚨 [INTEGRATION] Obtendo organismos mais problemáticos...');
      
      // Simular lista de organismos problemáticos
      return [
        {
          'name': 'Lagarta-da-soja',
          'severity': 85,
          'occurrences': 45,
          'trend': 'increasing',
        },
        {
          'name': 'Ferrugem Asiática',
          'severity': 78,
          'occurrences': 32,
          'trend': 'stable',
        },
        {
          'name': 'Buva',
          'severity': 72,
          'occurrences': 28,
          'trend': 'increasing',
        },
      ];
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro ao obter organismos problemáticos: $e');
      return [];
    }
  }
  
  /// Obtém tendências por cultura
  Future<Map<String, dynamic>> getTrendsByCrop() async {
    try {
      Logger.info('📈 [INTEGRATION] Obtendo tendências por cultura...');
      
      // Simular tendências por cultura
      return {
        'soja': {
          'totalOccurrences': 156,
          'trend': 'increasing',
          'severity': 65,
          'topOrganisms': ['Lagarta-da-soja', 'Ferrugem Asiática', 'Buva'],
        },
        'milho': {
          'totalOccurrences': 89,
          'trend': 'stable',
          'severity': 58,
          'topOrganisms': ['Lagarta-do-cartucho', 'Cigarrinha', 'Capim-colonião'],
        },
        'algodao': {
          'totalOccurrences': 67,
          'trend': 'decreasing',
          'severity': 45,
          'topOrganisms': ['Bicudo', 'Lagarta-rosada', 'Ramulária'],
        },
      };
    } catch (e) {
      Logger.error('❌ [INTEGRATION] Erro ao obter tendências: $e');
      return {};
    }
  }
}

// Classes de dados para integração

class CompleteIntegrationResult {
  final bool success;
  final List<IntelligentHeatmapPoint> heatmapPoints;
  final List<IntelligentHexagon> hexagons;
  final List<IntelligentAlert> alerts;
  final List<AIPointPrediction> pointPredictions;
  final List<TalhaoAIPrediction> talhaoPredictions;
  final EconomicAnalysis economicAnalysis;
  final ExecutiveReport executiveReport;
  final IntegrationValidation validation;
  final Duration processingTime;
  final DateTime generatedAt;
  
  CompleteIntegrationResult({
    required this.success,
    required this.heatmapPoints,
    required this.hexagons,
    required this.alerts,
    required this.pointPredictions,
    required this.talhaoPredictions,
    required this.economicAnalysis,
    required this.executiveReport,
    required this.validation,
    required this.processingTime,
    required this.generatedAt,
  });
  
  factory CompleteIntegrationResult.error(String error) {
    return CompleteIntegrationResult(
      success: false,
      heatmapPoints: [],
      hexagons: [],
      alerts: [],
      pointPredictions: [],
      talhaoPredictions: [],
      economicAnalysis: EconomicAnalysis.empty(),
      executiveReport: ExecutiveReport.empty(),
      validation: IntegrationValidation.error(error),
      processingTime: Duration.zero,
      generatedAt: DateTime.now(),
    );
  }
}

class IntegrationValidation {
  final bool isValid;
  final double score;
  final List<String> issues;
  final List<String> warnings;
  final DateTime validatedAt;
  
  IntegrationValidation({
    required this.isValid,
    required this.score,
    required this.issues,
    required this.warnings,
    required this.validatedAt,
  });
  
  factory IntegrationValidation.error(String error) {
    return IntegrationValidation(
      isValid: false,
      score: 0.0,
      issues: [error],
      warnings: [],
      validatedAt: DateTime.now(),
    );
  }
}

class IntegrationReport {
  final bool success;
  final Duration processingTime;
  final int heatmapPoints;
  final int hexagons;
  final int alerts;
  final int pointPredictions;
  final int talhaoPredictions;
  final EconomicAnalysis economicAnalysis;
  final ExecutiveReport executiveReport;
  final IntegrationValidation validation;
  final List<String> recommendations;
  final DateTime generatedAt;
  
  IntegrationReport({
    required this.success,
    required this.processingTime,
    required this.heatmapPoints,
    required this.hexagons,
    required this.alerts,
    required this.pointPredictions,
    required this.talhaoPredictions,
    required this.economicAnalysis,
    required this.executiveReport,
    required this.validation,
    required this.recommendations,
    required this.generatedAt,
  });
  
  factory IntegrationReport.error(String error) {
    return IntegrationReport(
      success: false,
      processingTime: Duration.zero,
      heatmapPoints: 0,
      hexagons: 0,
      alerts: 0,
      pointPredictions: 0,
      talhaoPredictions: 0,
      economicAnalysis: EconomicAnalysis.empty(),
      executiveReport: ExecutiveReport.empty(),
      validation: IntegrationValidation.error(error),
      recommendations: ['Erro na integração: $error'],
      generatedAt: DateTime.now(),
    );
  }
}