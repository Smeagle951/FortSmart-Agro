import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import '../modules/ai/services/ai_diagnosis_service.dart';
import '../modules/ai/services/image_recognition_service.dart';
import '../modules/ai/services/organism_prediction_service.dart';
import '../modules/ai/repositories/ai_organism_repository.dart';
import '../modules/ai/models/ai_diagnosis_result.dart';

/// Resultado de análise de IA para monitoramento
class AIMonitoringAnalysisResult {
  final String monitoringId;
  final String pointId;
  final String organismId;
  final String organismName;
  final String scientificName;
  final double confidenceScore;
  final double severityLevel;
  final String riskCategory;
  final List<String> symptoms;
  final List<String> managementStrategies;
  final Map<String, dynamic> environmentalFactors;
  final DateTime analysisDate;
  final String analysisMethod;

  AIMonitoringAnalysisResult({
    required this.monitoringId,
    required this.pointId,
    required this.organismId,
    required this.organismName,
    required this.scientificName,
    required this.confidenceScore,
    required this.severityLevel,
    required this.riskCategory,
    required this.symptoms,
    required this.managementStrategies,
    required this.environmentalFactors,
    required this.analysisDate,
    required this.analysisMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'monitoring_id': monitoringId,
      'point_id': pointId,
      'organism_id': organismId,
      'organism_name': organismName,
      'scientific_name': scientificName,
      'confidence_score': confidenceScore,
      'severity_level': severityLevel,
      'risk_category': riskCategory,
      'symptoms': symptoms,
      'management_strategies': managementStrategies,
      'environmental_factors': environmentalFactors,
      'analysis_date': analysisDate.toIso8601String(),
      'analysis_method': analysisMethod,
    };
  }
}

/// Resultado de processamento de heatmap com IA
class AIHeatmapResult {
  final String talhaoId;
  final String talhaoName;
  final List<Map<String, dynamic>> heatmapPoints;
  final Map<String, double> severityDistribution;
  final Map<String, int> organismCounts;
  final double overallRiskScore;
  final String riskLevel;
  final List<String> recommendations;
  final Map<String, dynamic> metadata;

  AIHeatmapResult({
    required this.talhaoId,
    required this.talhaoName,
    required this.heatmapPoints,
    required this.severityDistribution,
    required this.organismCounts,
    required this.overallRiskScore,
    required this.riskLevel,
    required this.recommendations,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'talhao_id': talhaoId,
      'talhao_name': talhaoName,
      'heatmap_points': heatmapPoints,
      'severity_distribution': severityDistribution,
      'organism_counts': organismCounts,
      'overall_risk_score': overallRiskScore,
      'risk_level': riskLevel,
      'recommendations': recommendations,
      'metadata': metadata,
    };
  }
}

/// Serviço de integração de IA com monitoramento e mapa de infestação
/// Utiliza algoritmos de IA para melhorar precisão e velocidade
class AIMonitoringIntegrationService {
  final AppDatabase _appDatabase = AppDatabase();
  final AIDiagnosisService _aiDiagnosisService = AIDiagnosisService();
  final ImageRecognitionService _imageService = ImageRecognitionService();
  final OrganismPredictionService _predictionService = OrganismPredictionService();
  final AIOrganismRepository _organismRepository = AIOrganismRepository();

  /// Processa monitoramento com IA para melhorar precisão
  Future<List<AIMonitoringAnalysisResult>> processMonitoringWithAI(Monitoring monitoring) async {
    try {
      Logger.info('🤖 [IA-MONITORING] Processando monitoramento com IA: ${monitoring.id}');
      
      final results = <AIMonitoringAnalysisResult>[];
      
      for (final point in monitoring.points) {
        // 1. Análise de IA por sintomas
        final symptomResults = await _analyzePointWithSymptoms(point, monitoring);
        results.addAll(symptomResults);
        
        // 2. Análise de IA por imagens (se disponível)
        if (point.observations != null && point.observations!.isNotEmpty) {
          final imageResults = await _analyzePointWithImages(point, monitoring);
          results.addAll(imageResults);
        }
        
        // 3. Predição de organismos baseada em dados ambientais
        final predictionResults = await _predictOrganismsForPoint(point, monitoring);
        results.addAll(predictionResults);
      }
      
      // 4. Salvar resultados no banco
      await _saveAIAnalysisResults(results);
      
      Logger.info('✅ [IA-MONITORING] ${results.length} análises de IA processadas');
      
      return results;
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro no processamento com IA: $e');
      return [];
    }
  }

  /// Gera heatmap inteligente com IA
  Future<AIHeatmapResult> generateIntelligentHeatmap(String talhaoId, String talhaoName) async {
    try {
      Logger.info('🔥 [IA-HEATMAP] Gerando heatmap inteligente para talhão: $talhaoName');
      
      final database = await _appDatabase.database;
      
      // Buscar dados de monitoramento do talhão
      final monitorings = await _getMonitoringsByTalhao(database, talhaoId);
      
      if (monitorings.isEmpty) {
        return _createEmptyHeatmapResult(talhaoId, talhaoName);
      }
      
      // Processar cada monitoramento com IA
      final allAnalysisResults = <AIMonitoringAnalysisResult>[];
      for (final monitoring in monitorings) {
        final analysisResults = await processMonitoringWithAI(monitoring);
        allAnalysisResults.addAll(analysisResults);
      }
      
      // Gerar heatmap com dados de IA
      final heatmapResult = await _generateHeatmapFromAIData(talhaoId, talhaoName, allAnalysisResults);
      
      Logger.info('✅ [IA-HEATMAP] Heatmap inteligente gerado com ${heatmapResult.heatmapPoints.length} pontos');
      
      return heatmapResult;
      
    } catch (e) {
      Logger.error('❌ [IA-HEATMAP] Erro na geração do heatmap: $e');
      return _createEmptyHeatmapResult(talhaoId, talhaoName);
    }
  }

  /// Analisa ponto com sintomas usando IA
  Future<List<AIMonitoringAnalysisResult>> _analyzePointWithSymptoms(MonitoringPoint point, Monitoring monitoring) async {
    final results = <AIMonitoringAnalysisResult>[];
    
    try {
      // Extrair sintomas das ocorrências
      final symptoms = <String>[];
      for (final occurrence in point.occurrences) {
        if (occurrence.notes != null && occurrence.notes!.isNotEmpty) {
          symptoms.addAll(_extractSymptomsFromNotes(occurrence.notes!));
        }
      }
      
      if (symptoms.isNotEmpty) {
        // Usar IA para diagnóstico
        final diagnosisResults = await _aiDiagnosisService.diagnoseBySymptoms(
          symptoms: symptoms,
          cropName: monitoring.cropName ?? 'Soja',
          confidenceThreshold: 0.3,
        );
        
        for (final diagnosis in diagnosisResults) {
          results.add(AIMonitoringAnalysisResult(
            monitoringId: monitoring.id,
            pointId: point.id,
            organismId: diagnosis.organismName,
            organismName: diagnosis.organismName,
            scientificName: diagnosis.scientificName,
            confidenceScore: diagnosis.confidence,
            severityLevel: _calculateSeverityFromConfidence(diagnosis.confidence),
            riskCategory: _determineRiskCategory(diagnosis.confidence),
            symptoms: diagnosis.symptoms,
            managementStrategies: diagnosis.managementStrategies,
            environmentalFactors: _analyzeEnvironmentalFactors(point, monitoring),
            analysisDate: DateTime.now(),
            analysisMethod: 'symptoms_ai',
          ));
        }
      }
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro na análise por sintomas: $e');
    }
    
    return results;
  }

  /// Analisa ponto com imagens usando IA
  Future<List<AIMonitoringAnalysisResult>> _analyzePointWithImages(MonitoringPoint point, Monitoring monitoring) async {
    final results = <AIMonitoringAnalysisResult>[];
    
    try {
      for (final imagePath in [point.observations!]) {
        // Usar reconhecimento de imagem
        final imageResults = await _imageService.recognizeOrganism(
          imagePath: imagePath,
          cropName: monitoring.cropName ?? 'Soja',
          confidenceThreshold: 0.3,
        );
        
        for (final diagnosis in imageResults) {
          results.add(AIMonitoringAnalysisResult(
            monitoringId: monitoring.id,
            pointId: point.id,
            organismId: diagnosis.organismName,
            organismName: diagnosis.organismName,
            scientificName: diagnosis.scientificName,
            confidenceScore: diagnosis.confidence,
            severityLevel: _calculateSeverityFromConfidence(diagnosis.confidence),
            riskCategory: _determineRiskCategory(diagnosis.confidence),
            symptoms: diagnosis.symptoms,
            managementStrategies: diagnosis.managementStrategies,
            environmentalFactors: _analyzeEnvironmentalFactors(point, monitoring),
            analysisDate: DateTime.now(),
            analysisMethod: 'image_ai',
          ));
        }
      }
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro na análise por imagens: $e');
    }
    
    return results;
  }

  /// Prediz organismos para o ponto
  Future<List<AIMonitoringAnalysisResult>> _predictOrganismsForPoint(MonitoringPoint point, Monitoring monitoring) async {
    final results = <AIMonitoringAnalysisResult>[];
    
    try {
      // Dados ambientais do ponto
      final environmentalData = {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'temperature': _estimateTemperature(point),
        'humidity': _estimateHumidity(point),
        'crop_stage': 'vegetativo',
        'crop_name': monitoring.cropName ?? 'Soja',
        'date': monitoring.date.toIso8601String(),
      };
      
      // Usar predição de organismos
      final predictions = await _predictionService.predictOutbreakRisk(
        cropName: monitoring.cropName ?? 'Soja',
        location: '${point.latitude},${point.longitude}',
        weatherData: environmentalData,
      );
      
      // Usar dados reais das ocorrências do ponto
      for (final occurrence in point.occurrences) {
        results.add(AIMonitoringAnalysisResult(
          monitoringId: monitoring.id,
          pointId: point.id,
          organismId: occurrence.name,
          organismName: occurrence.name,
          scientificName: occurrence.name,
          confidenceScore: _calculateConfidenceFromOccurrence(occurrence),
          severityLevel: _calculateSeverityFromOccurrence(occurrence),
          riskCategory: _determineRiskCategoryFromOccurrence(occurrence),
          symptoms: _extractSymptomsFromOccurrence(occurrence),
          managementStrategies: _extractManagementFromOccurrence(occurrence),
          environmentalFactors: environmentalData,
          analysisDate: DateTime.now(),
          analysisMethod: 'prediction_ai',
        ));
      }
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro na predição de organismos: $e');
    }
    
    return results;
  }

  /// Gera heatmap a partir de dados de IA
  Future<AIHeatmapResult> _generateHeatmapFromAIData(String talhaoId, String talhaoName, List<AIMonitoringAnalysisResult> analysisResults) async {
    final heatmapPoints = <Map<String, dynamic>>[];
    final severityDistribution = <String, double>{};
    final organismCounts = <String, int>{};
    final recommendations = <String>[];
    
    // Processar cada resultado de análise
    for (final result in analysisResults) {
      // Calcular intensidade do heatmap baseada na IA
      final heatmapIntensity = _calculateHeatmapIntensity(result);
      
      heatmapPoints.add({
        'latitude': result.pointId, // Usar ID do ponto como referência
        'longitude': result.pointId,
        'intensity': heatmapIntensity,
        'confidence': result.confidenceScore,
        'severity': result.severityLevel,
        'organism': result.organismName,
        'risk_category': result.riskCategory,
        'ai_analysis': true,
        'analysis_method': result.analysisMethod,
      });
      
      // Atualizar distribuição de severidade
      final severityKey = _getSeverityKey(result.severityLevel);
      severityDistribution[severityKey] = (severityDistribution[severityKey] ?? 0) + result.severityLevel;
      
      // Contar organismos
      organismCounts[result.organismName] = (organismCounts[result.organismName] ?? 0) + 1;
    }
    
    // Calcular score geral de risco
    final overallRiskScore = _calculateOverallRiskScore(analysisResults);
    final riskLevel = _determineOverallRiskLevel(overallRiskScore);
    
    // Gerar recomendações baseadas em IA
    recommendations.addAll(_generateAIRecommendations(analysisResults));
    
    return AIHeatmapResult(
      talhaoId: talhaoId,
      talhaoName: talhaoName,
      heatmapPoints: heatmapPoints,
      severityDistribution: severityDistribution,
      organismCounts: organismCounts,
      overallRiskScore: overallRiskScore,
      riskLevel: riskLevel,
      recommendations: recommendations,
      metadata: {
        'total_analysis': analysisResults.length,
        'ai_confidence_avg': _calculateAverageConfidence(analysisResults),
        'analysis_methods': _getAnalysisMethods(analysisResults),
        'generated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Extrai sintomas das notas
  List<String> _extractSymptomsFromNotes(String notes) {
    final symptoms = <String>[];
    final commonSymptoms = [
      'folhas com furos',
      'manchas nas folhas',
      'desfolhamento',
      'grãos chochos',
      'presença de insetos',
      'redução no crescimento',
      'pústulas nas folhas',
      'secamento das folhas',
      'lesões marrom-claras',
      'furos irregulares',
    ];
    
    for (final symptom in commonSymptoms) {
      if (notes.toLowerCase().contains(symptom)) {
        symptoms.add(symptom);
      }
    }
    
    return symptoms;
  }

  /// Calcula severidade baseada na confiança
  double _calculateSeverityFromConfidence(double confidence) {
    if (confidence >= 0.8) return 90.0; // Muito alta
    if (confidence >= 0.6) return 70.0; // Alta
    if (confidence >= 0.4) return 50.0; // Média
    if (confidence >= 0.3) return 30.0; // Baixa
    return 10.0; // Muito baixa
  }

  /// Determina categoria de risco
  String _determineRiskCategory(double confidence) {
    if (confidence >= 0.8) return 'CRÍTICO';
    if (confidence >= 0.6) return 'ALTO';
    if (confidence >= 0.4) return 'MÉDIO';
    return 'BAIXO';
  }

  /// Analisa fatores ambientais
  Map<String, dynamic> _analyzeEnvironmentalFactors(MonitoringPoint point, Monitoring monitoring) {
    return {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'gps_accuracy': point.gpsAccuracy ?? 10.0,
      'crop_name': monitoring.cropName ?? 'Soja',
      'crop_stage': 'vegetativo',
      'date': monitoring.date.toIso8601String(),
      'temperature_estimate': _estimateTemperature(point),
      'humidity_estimate': _estimateHumidity(point),
    };
  }

  /// Estima temperatura baseada na localização e data
  double _estimateTemperature(MonitoringPoint point) {
    // Algoritmo simplificado de estimativa de temperatura
    final month = DateTime.now().month;
    final baseTemp = 25.0; // Temperatura base
    final seasonalVariation = sin((month - 1) * 2 * pi / 12) * 5.0;
    return baseTemp + seasonalVariation;
  }

  /// Estima umidade baseada na localização e data
  double _estimateHumidity(MonitoringPoint point) {
    // Algoritmo simplificado de estimativa de umidade
    final month = DateTime.now().month;
    final baseHumidity = 70.0; // Umidade base
    final seasonalVariation = cos((month - 1) * 2 * pi / 12) * 10.0;
    return (baseHumidity + seasonalVariation).clamp(30.0, 90.0);
  }

  /// Calcula intensidade do heatmap
  double _calculateHeatmapIntensity(AIMonitoringAnalysisResult result) {
    // Combina confiança, severidade e fatores ambientais
    final confidenceWeight = 0.4;
    final severityWeight = 0.4;
    final environmentalWeight = 0.2;
    
    final confidenceScore = result.confidenceScore;
    final severityScore = result.severityLevel / 100.0;
    final environmentalScore = _calculateEnvironmentalScore(result.environmentalFactors);
    
    return (confidenceScore * confidenceWeight + 
            severityScore * severityWeight + 
            environmentalScore * environmentalWeight) * 100.0;
  }

  /// Calcula score ambiental
  double _calculateEnvironmentalScore(Map<String, dynamic> factors) {
    // Algoritmo simplificado de score ambiental
    double score = 0.5; // Score base
    
    // Ajustar baseado na temperatura
    final temp = factors['temperature_estimate'] as double? ?? 25.0;
    if (temp >= 20.0 && temp <= 30.0) score += 0.2;
    
    // Ajustar baseado na umidade
    final humidity = factors['humidity_estimate'] as double? ?? 70.0;
    if (humidity >= 60.0 && humidity <= 80.0) score += 0.2;
    
    // Ajustar baseado na precisão GPS
    final accuracy = factors['gps_accuracy'] as double? ?? 10.0;
    if (accuracy <= 5.0) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calcula score geral de risco
  double _calculateOverallRiskScore(List<AIMonitoringAnalysisResult> results) {
    if (results.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    for (final result in results) {
      totalScore += result.confidenceScore * result.severityLevel / 100.0;
    }
    
    return (totalScore / results.length) * 100.0;
  }

  /// Determina nível geral de risco
  String _determineOverallRiskLevel(double riskScore) {
    if (riskScore >= 80.0) return 'CRÍTICO';
    if (riskScore >= 60.0) return 'ALTO';
    if (riskScore >= 40.0) return 'MÉDIO';
    return 'BAIXO';
  }

  /// Gera recomendações baseadas em IA
  List<String> _generateAIRecommendations(List<AIMonitoringAnalysisResult> results) {
    final recommendations = <String>[];
    
    if (results.isEmpty) {
      recommendations.add('Nenhuma análise de IA disponível');
      return recommendations;
    }
    
    // Recomendações baseadas na confiança média
    final avgConfidence = _calculateAverageConfidence(results);
    if (avgConfidence >= 0.8) {
      recommendations.add('Ação imediata necessária - alta confiança na detecção');
    } else if (avgConfidence >= 0.6) {
      recommendations.add('Monitoramento intensivo recomendado');
    } else {
      recommendations.add('Coleta de dados adicionais necessária');
    }
    
    // Recomendações baseadas nos organismos detectados
    final organismCounts = <String, int>{};
    for (final result in results) {
      organismCounts[result.organismName] = (organismCounts[result.organismName] ?? 0) + 1;
    }
    
    final topOrganism = organismCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    recommendations.add('Organismo mais detectado: ${topOrganism.key} (${topOrganism.value} ocorrências)');
    
    return recommendations;
  }

  /// Calcula confiança média
  double _calculateAverageConfidence(List<AIMonitoringAnalysisResult> results) {
    if (results.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    for (final result in results) {
      totalConfidence += result.confidenceScore;
    }
    
    return totalConfidence / results.length;
  }

  /// Obtém métodos de análise
  List<String> _getAnalysisMethods(List<AIMonitoringAnalysisResult> results) {
    return results.map((r) => r.analysisMethod).toSet().toList();
  }

  /// Obtém chave de severidade
  String _getSeverityKey(double severity) {
    if (severity >= 80.0) return 'CRÍTICA';
    if (severity >= 60.0) return 'ALTA';
    if (severity >= 40.0) return 'MÉDIA';
    return 'BAIXA';
  }

  /// Busca monitoramentos por talhão
  Future<List<Monitoring>> _getMonitoringsByTalhao(Database database, String talhaoId) async {
    try {
      final results = await database.query(
        'monitorings',
        where: 'plot_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
      );
      
      List<Monitoring> monitorings = [];
      for (final row in results) {
        final monitoring = Monitoring.fromMap(row);
        final points = await _getPointsByMonitoringId(database, monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro ao buscar monitoramentos: $e');
      return [];
    }
  }

  /// Busca pontos por ID de monitoramento
  Future<List<MonitoringPoint>> _getPointsByMonitoringId(Database database, String monitoringId) async {
    try {
      final results = await database.query(
        'monitoring_points',
        where: 'monitoring_id = ?',
        whereArgs: [monitoringId],
        orderBy: 'created_at ASC',
      );
      
      List<MonitoringPoint> points = [];
      for (final row in results) {
        final point = MonitoringPoint.fromMap(row);
        final occurrences = await _getOccurrencesByPointId(database, point.id);
        points.add(point.copyWith(occurrences: occurrences));
      }
      
      return points;
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro ao buscar pontos: $e');
      return [];
    }
  }

  /// Busca ocorrências por ID de ponto
  Future<List<Occurrence>> _getOccurrencesByPointId(Database database, String pointId) async {
    try {
      final results = await database.query(
        'occurrences',
        where: 'monitoring_point_id = ?',
        whereArgs: [pointId],
        orderBy: 'created_at ASC',
      );
      
      return results.map((row) => Occurrence.fromMap(row)).toList();
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro ao buscar ocorrências: $e');
      return [];
    }
  }

  /// Salva resultados de análise de IA
  Future<void> _saveAIAnalysisResults(List<AIMonitoringAnalysisResult> results) async {
    try {
      final database = await _appDatabase.database;
      
      for (final result in results) {
        await database.insert('ai_analysis_results', result.toMap());
      }
      
      Logger.info('✅ [IA-MONITORING] ${results.length} resultados de IA salvos');
      
    } catch (e) {
      Logger.error('❌ [IA-MONITORING] Erro ao salvar resultados: $e');
    }
  }

  /// Cria resultado vazio de heatmap
  AIHeatmapResult _createEmptyHeatmapResult(String talhaoId, String talhaoName) {
    return AIHeatmapResult(
      talhaoId: talhaoId,
      talhaoName: talhaoName,
      heatmapPoints: [],
      severityDistribution: {},
      organismCounts: {},
      overallRiskScore: 0.0,
      riskLevel: 'BAIXO',
      recommendations: ['Nenhum dado de monitoramento disponível'],
      metadata: {
        'total_analysis': 0,
        'ai_confidence_avg': 0.0,
        'analysis_methods': [],
        'generated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Calcula confiança baseada na ocorrência real
  double _calculateConfidenceFromOccurrence(Occurrence occurrence) {
    // Baseado na precisão GPS e dados da ocorrência
    double baseConfidence = 0.7;
    
    // Ajustar baseado na precisão GPS (usar precisão do ponto de monitoramento)
    // A precisão GPS está no MonitoringPoint, não na Occurrence
    baseConfidence += 0.1; // Confiança baseada em dados reais
    
    // Ajustar baseado na quantidade de dados
    if (occurrence.notes != null && occurrence.notes!.isNotEmpty) {
      baseConfidence += 0.1;
    }
    
    return baseConfidence.clamp(0.0, 1.0);
  }

  /// Calcula severidade baseada na ocorrência real
  double _calculateSeverityFromOccurrence(Occurrence occurrence) {
    // Baseado no índice de infestação real (0-100)
    return occurrence.infestationIndex;
  }

  /// Determina categoria de risco baseada na ocorrência real
  String _determineRiskCategoryFromOccurrence(Occurrence occurrence) {
    // Baseado no tipo de organismo e índice
    if (occurrence.type == OccurrenceType.pest && occurrence.infestationIndex >= 50) {
      return 'Alto Risco';
    }
    if (occurrence.type == OccurrenceType.disease && occurrence.infestationIndex >= 30) {
      return 'Médio Risco';
    }
    return 'Baixo Risco';
  }

  /// Extrai sintomas reais da ocorrência
  List<String> _extractSymptomsFromOccurrence(Occurrence occurrence) {
    List<String> symptoms = [];
    
    // Usar observações reais do usuário
    if (occurrence.notes != null && occurrence.notes!.isNotEmpty) {
      symptoms.add('Observações: ${occurrence.notes}');
    }
    
    // Adicionar sintomas baseados no tipo
    if (occurrence.type == OccurrenceType.pest) {
      symptoms.add('Presença de pragas detectada');
    } else if (occurrence.type == OccurrenceType.disease) {
      symptoms.add('Sintomas de doença observados');
    }
    
    return symptoms;
  }

  /// Extrai estratégias de manejo baseadas na ocorrência real
  List<String> _extractManagementFromOccurrence(Occurrence occurrence) {
    List<String> strategies = [];
    
    // Estratégias baseadas no tipo e severidade
    if (occurrence.type == OccurrenceType.pest) {
      if (occurrence.infestationIndex >= 50) {
        strategies.add('Aplicação imediata de inseticida');
        strategies.add('Monitoramento intensivo');
      } else {
        strategies.add('Monitoramento preventivo');
        strategies.add('Avaliação semanal');
      }
    } else if (occurrence.type == OccurrenceType.disease) {
      if (occurrence.infestationIndex >= 30) {
        strategies.add('Aplicação de fungicida');
        strategies.add('Melhoria da ventilação');
      } else {
        strategies.add('Monitoramento preventivo');
        strategies.add('Controle cultural');
      }
    }
    
    return strategies;
  }
  
  /// Método de compatibilidade para analyzeData
  Future<Map<String, dynamic>> analyzeData({
    required String talhaoId,
    required List<String> organismos,
    required List<double> intensidades,
    required Map<String, dynamic> dadosAmbientais,
  }) async {
    // Implementação temporária
    return {
      'analysis': 'Análise temporária',
      'confidence': 0.8,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
