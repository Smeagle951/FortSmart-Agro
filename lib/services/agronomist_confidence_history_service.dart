import 'dart:math';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import 'agronomist_data_validation_service.dart';

/// Histórico de confiabilidade por talhão
class TalhaoConfidenceHistory {
  final String talhaoId;
  final String talhaoName;
  final DateTime date;
  final double confidenceScore;
  final String qualityLevel;
  final int totalMonitorings;
  final int validMonitorings;
  final double averageAccuracy;
  final double dataCompleteness;
  final List<String> commonIssues;
  final Map<String, dynamic> metadata;

  TalhaoConfidenceHistory({
    required this.talhaoId,
    required this.talhaoName,
    required this.date,
    required this.confidenceScore,
    required this.qualityLevel,
    required this.totalMonitorings,
    required this.validMonitorings,
    required this.averageAccuracy,
    required this.dataCompleteness,
    required this.commonIssues,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'talhaoName': talhaoName,
      'date': date.toIso8601String(),
      'confidenceScore': confidenceScore,
      'qualityLevel': qualityLevel,
      'totalMonitorings': totalMonitorings,
      'validMonitorings': validMonitorings,
      'averageAccuracy': averageAccuracy,
      'dataCompleteness': dataCompleteness,
      'commonIssues': commonIssues,
      'metadata': metadata,
    };
  }
}

/// Benchmark de confiabilidade
class ConfidenceBenchmark {
  final String talhaoId;
  final String talhaoName;
  final double averageConfidence;
  final String qualityLevel;
  final int totalMonitorings;
  final double improvementTrend;
  final List<String> strengths;
  final List<String> weaknesses;
  final Map<String, dynamic> recommendations;

  ConfidenceBenchmark({
    required this.talhaoId,
    required this.talhaoName,
    required this.averageConfidence,
    required this.qualityLevel,
    required this.totalMonitorings,
    required this.improvementTrend,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'talhaoName': talhaoName,
      'averageConfidence': averageConfidence,
      'qualityLevel': qualityLevel,
      'totalMonitorings': totalMonitorings,
      'improvementTrend': improvementTrend,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
    };
  }
}

/// Serviço de histórico de confiabilidade
/// Mantém histórico e benchmarks de qualidade dos dados
class AgronomistConfidenceHistoryService {
  final AppDatabase _appDatabase = AppDatabase();
  final AgronomistDataValidationService _validationService = AgronomistDataValidationService();

  /// Registra histórico de confiabilidade
  Future<void> recordConfidenceHistory(String talhaoId, String talhaoName) async {
    try {
      Logger.info('📊 [HISTÓRICO] Registrando histórico de confiabilidade para talhão: $talhaoName');
      
      final database = await _appDatabase.database;
      
      // Buscar monitoramentos do talhão
      final monitorings = await _getMonitoringsByTalhao(database, talhaoId);
      
      if (monitorings.isEmpty) {
        Logger.warning('⚠️ [HISTÓRICO] Nenhum monitoramento encontrado para talhão: $talhaoName');
        return;
      }
      
      // Validar dados
      final validationResult = await _validationService.validateExecutiveReportData(monitorings);
      
      // Calcular métricas
      final metrics = _calculateConfidenceMetrics(monitorings, validationResult);
      
      // Salvar histórico
      await _saveConfidenceHistory(database, talhaoId, talhaoName, metrics);
      
      Logger.info('✅ [HISTÓRICO] Histórico registrado com sucesso');
      
    } catch (e) {
      Logger.error('❌ [HISTÓRICO] Erro ao registrar histórico: $e');
    }
  }

  /// Obtém histórico de confiabilidade por talhão
  Future<List<TalhaoConfidenceHistory>> getConfidenceHistory(String talhaoId, {int days = 30}) async {
    try {
      final database = await _appDatabase.database;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final results = await database.query(
        'confidence_history',
        where: 'talhao_id = ? AND date >= ?',
        whereArgs: [talhaoId, cutoffDate.toIso8601String()],
        orderBy: 'date DESC',
      );
      
      return results.map((row) => TalhaoConfidenceHistory(
        talhaoId: row['talhao_id'] as String,
        talhaoName: row['talhao_name'] as String,
        date: DateTime.parse(row['date'] as String),
        confidenceScore: row['confidence_score'] as double,
        qualityLevel: row['quality_level'] as String,
        totalMonitorings: row['total_monitorings'] as int,
        validMonitorings: row['valid_monitorings'] as int,
        averageAccuracy: row['average_accuracy'] as double,
        dataCompleteness: row['data_completeness'] as double,
        commonIssues: List<String>.from(jsonDecode(row['common_issues'] as String)),
        metadata: jsonDecode(row['metadata'] as String),
      )).toList();
      
    } catch (e) {
      Logger.error('❌ [HISTÓRICO] Erro ao obter histórico: $e');
      return [];
    }
  }

  /// Gera benchmark de confiabilidade
  Future<List<ConfidenceBenchmark>> generateConfidenceBenchmark() async {
    try {
      Logger.info('📊 [BENCHMARK] Gerando benchmark de confiabilidade...');
      
      final database = await _appDatabase.database;
      
      // Buscar todos os talhões
      final talhoes = await database.query('talhoes');
      
      final benchmarks = <ConfidenceBenchmark>[];
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        // Obter histórico do talhão
        final history = await getConfidenceHistory(talhaoId, days: 90);
        
        if (history.isNotEmpty) {
          final benchmark = _calculateBenchmark(talhaoId, talhaoName, history);
          benchmarks.add(benchmark);
        }
      }
      
      // Ordenar por confiabilidade
      benchmarks.sort((a, b) => b.averageConfidence.compareTo(a.averageConfidence));
      
      Logger.info('✅ [BENCHMARK] Benchmark gerado: ${benchmarks.length} talhões');
      
      return benchmarks;
      
    } catch (e) {
      Logger.error('❌ [BENCHMARK] Erro ao gerar benchmark: $e');
      return [];
    }
  }

  /// Obtém tendências de melhoria
  Future<Map<String, dynamic>> getImprovementTrends(String talhaoId) async {
    try {
      final history = await getConfidenceHistory(talhaoId, days: 90);
      
      if (history.length < 2) {
        return {
          'trend': 'INSUFICIENTE',
          'message': 'Dados insuficientes para análise de tendência',
          'improvement': 0.0,
        };
      }
      
      // Calcular tendência
      final firstScore = history.last.confidenceScore;
      final lastScore = history.first.confidenceScore;
      final improvement = lastScore - firstScore;
      
      String trend;
      if (improvement > 10) {
        trend = 'MELHORANDO';
      } else if (improvement < -10) {
        trend = 'PIORANDO';
      } else {
        trend = 'ESTÁVEL';
      }
      
      return {
        'trend': trend,
        'improvement': improvement,
        'firstScore': firstScore,
        'lastScore': lastScore,
        'dataPoints': history.length,
      };
      
    } catch (e) {
      Logger.error('❌ [TENDÊNCIA] Erro ao calcular tendência: $e');
      return {
        'trend': 'ERRO',
        'message': 'Erro ao calcular tendência: $e',
        'improvement': 0.0,
      };
    }
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
      Logger.error('❌ [HISTÓRICO] Erro ao buscar monitoramentos: $e');
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
      Logger.error('❌ [HISTÓRICO] Erro ao buscar pontos: $e');
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
      Logger.error('❌ [HISTÓRICO] Erro ao buscar ocorrências: $e');
      return [];
    }
  }

  /// Calcula métricas de confiabilidade
  Map<String, dynamic> _calculateConfidenceMetrics(List<Monitoring> monitorings, DataValidationResult validationResult) {
    // Calcular precisão média
    double totalAccuracy = 0.0;
    int accuracyCount = 0;
    
    for (final monitoring in monitorings) {
      for (final point in monitoring.points) {
        if (point.gpsAccuracy != null) {
          totalAccuracy += point.gpsAccuracy!;
          accuracyCount++;
        }
      }
    }
    
    final averageAccuracy = accuracyCount > 0 ? totalAccuracy / accuracyCount : 0.0;
    
    // Calcular completude dos dados
    int totalFields = 0;
    int completeFields = 0;
    
    for (final monitoring in monitorings) {
      for (final point in monitoring.points) {
        totalFields += 3; // lat, lng, accuracy
        if (point.latitude != 0.0 && point.longitude != 0.0) completeFields += 2;
        if (point.gpsAccuracy != null && point.gpsAccuracy! > 0) completeFields += 1;
        
        for (final occurrence in point.occurrences) {
          totalFields += 3; // name, type, infestation_index
          if (occurrence.name.isNotEmpty) completeFields += 1;
          if (occurrence.type != OccurrenceType.other) completeFields += 1;
          if (occurrence.infestationIndex >= 0) completeFields += 1;
        }
      }
    }
    
    final dataCompleteness = totalFields > 0 ? (completeFields / totalFields) * 100 : 0.0;
    
    // Identificar problemas comuns
    final commonIssues = <String>[];
    if (averageAccuracy > 10.0) commonIssues.add('Precisão GPS baixa');
    if (dataCompleteness < 80.0) commonIssues.add('Dados incompletos');
    if (validationResult.warnings.isNotEmpty) commonIssues.add('Avisos de validação');
    
    return {
      'confidenceScore': validationResult.confidenceScore,
      'qualityLevel': validationResult.qualityLevel,
      'totalMonitorings': monitorings.length,
      'validMonitorings': monitorings.where((m) => m.points.isNotEmpty).length,
      'averageAccuracy': averageAccuracy,
      'dataCompleteness': dataCompleteness,
      'commonIssues': commonIssues,
      'metadata': validationResult.metadata,
    };
  }

  /// Salva histórico de confiabilidade
  Future<void> _saveConfidenceHistory(Database database, String talhaoId, String talhaoName, Map<String, dynamic> metrics) async {
    try {
      await database.insert('confidence_history', {
        'talhao_id': talhaoId,
        'talhao_name': talhaoName,
        'date': DateTime.now().toIso8601String(),
        'confidence_score': metrics['confidenceScore'],
        'quality_level': metrics['qualityLevel'],
        'total_monitorings': metrics['totalMonitorings'],
        'valid_monitorings': metrics['validMonitorings'],
        'average_accuracy': metrics['averageAccuracy'],
        'data_completeness': metrics['dataCompleteness'],
        'common_issues': jsonEncode(metrics['commonIssues']),
        'metadata': jsonEncode(metrics['metadata']),
      });
    } catch (e) {
      Logger.error('❌ [HISTÓRICO] Erro ao salvar histórico: $e');
    }
  }

  /// Calcula benchmark para um talhão
  ConfidenceBenchmark _calculateBenchmark(String talhaoId, String talhaoName, List<TalhaoConfidenceHistory> history) {
    // Calcular média de confiabilidade
    final averageConfidence = history.map((h) => h.confidenceScore).reduce((a, b) => a + b) / history.length;
    
    // Determinar nível de qualidade
    String qualityLevel;
    if (averageConfidence >= 95) qualityLevel = 'EXCELENTE';
    else if (averageConfidence >= 85) qualityLevel = 'MUITO BOM';
    else if (averageConfidence >= 75) qualityLevel = 'BOM';
    else if (averageConfidence >= 65) qualityLevel = 'REGULAR';
    else qualityLevel = 'BAIXO';
    
    // Calcular tendência de melhoria
    final firstScore = history.last.confidenceScore;
    final lastScore = history.first.confidenceScore;
    final improvementTrend = lastScore - firstScore;
    
    // Identificar pontos fortes e fracos
    final strengths = <String>[];
    final weaknesses = <String>[];
    
    if (averageConfidence >= 85) strengths.add('Alta confiabilidade geral');
    if (history.any((h) => h.averageAccuracy <= 5.0)) strengths.add('Precisão GPS excelente');
    if (history.any((h) => h.dataCompleteness >= 90.0)) strengths.add('Dados completos');
    
    if (averageConfidence < 75) weaknesses.add('Confiabilidade baixa');
    if (history.any((h) => h.averageAccuracy > 15.0)) weaknesses.add('Precisão GPS ruim');
    if (history.any((h) => h.dataCompleteness < 70.0)) weaknesses.add('Dados incompletos');
    
    // Gerar recomendações
    final recommendations = <String, dynamic>{};
    if (averageConfidence < 80) {
      recommendations['priority'] = 'ALTA';
      recommendations['actions'] = ['Melhorar precisão GPS', 'Completar dados de monitoramento'];
    } else if (averageConfidence < 90) {
      recommendations['priority'] = 'MÉDIA';
      recommendations['actions'] = ['Otimizar processo de coleta', 'Padronizar observações'];
    } else {
      recommendations['priority'] = 'BAIXA';
      recommendations['actions'] = ['Manter padrão atual', 'Expandir monitoramento'];
    }
    
    return ConfidenceBenchmark(
      talhaoId: talhaoId,
      talhaoName: talhaoName,
      averageConfidence: averageConfidence,
      qualityLevel: qualityLevel,
      totalMonitorings: history.fold(0, (sum, h) => sum + h.totalMonitorings),
      improvementTrend: improvementTrend,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }
}
