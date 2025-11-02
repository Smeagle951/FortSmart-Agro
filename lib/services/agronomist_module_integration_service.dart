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
import 'agronomist_confidence_history_service.dart';
import 'agronomist_automatic_alerts_service.dart';
import 'monitoring_infestation_integration_service.dart';

/// Status de integração entre módulos
enum ModuleIntegrationStatus {
  synchronized,
  outOfSync,
  validationFailed,
  dataMissing,
  gpsInaccurate,
  temporalInconsistent,
}

/// Resultado da integração
class ModuleIntegrationResult {
  final ModuleIntegrationStatus status;
  final double syncScore;
  final List<String> issues;
  final List<String> recommendations;
  final Map<String, dynamic> metadata;
  final DateTime lastSync;
  final bool requiresAction;

  ModuleIntegrationResult({
    required this.status,
    required this.syncScore,
    required this.issues,
    required this.recommendations,
    required this.metadata,
    required this.lastSync,
    required this.requiresAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status.toString(),
      'syncScore': syncScore,
      'issues': issues,
      'recommendations': recommendations,
      'metadata': metadata,
      'lastSync': lastSync.toIso8601String(),
      'requiresAction': requiresAction,
    };
  }
}

/// Serviço de integração total entre módulos
/// Garante 100% de alinhamento entre Monitoramento e Mapa de Infestação
class AgronomistModuleIntegrationService {
  final AppDatabase _appDatabase = AppDatabase();
  final AgronomistDataValidationService _validationService = AgronomistDataValidationService();
  final AgronomistConfidenceHistoryService _historyService = AgronomistConfidenceHistoryService();
  final AgronomistAutomaticAlertsService _alertsService = AgronomistAutomaticAlertsService();
  final MonitoringInfestationIntegrationService _integrationService = MonitoringInfestationIntegrationService();

  /// Executa verificação completa de integração
  Future<ModuleIntegrationResult> checkModuleIntegration() async {
    try {
      Logger.info('🔗 [INTEGRAÇÃO] Verificando alinhamento entre módulos...');
      
      final issues = <String>[];
      final recommendations = <String>[];
      final metadata = <String, dynamic>{};
      double syncScore = 100.0;
      
      // 1. Verificar sincronização de dados
      final syncResult = await _checkDataSynchronization();
      if (syncResult['issues'].isNotEmpty) {
        issues.addAll(syncResult['issues']);
        syncScore -= syncResult['penalty'];
      }
      
      // 2. Verificar validação de dados
      final validationResult = await _checkDataValidation();
      if (validationResult['issues'].isNotEmpty) {
        issues.addAll(validationResult['issues']);
        syncScore -= validationResult['penalty'];
      }
      
      // 3. Verificar precisão espacial
      final spatialResult = await _checkSpatialAccuracy();
      if (spatialResult['issues'].isNotEmpty) {
        issues.addAll(spatialResult['issues']);
        syncScore -= spatialResult['penalty'];
      }
      
      // 4. Verificar consistência temporal
      final temporalResult = await _checkTemporalConsistency();
      if (temporalResult['issues'].isNotEmpty) {
        issues.addAll(temporalResult['issues']);
        syncScore -= temporalResult['penalty'];
      }
      
      // 5. Verificar qualidade dos dados
      final qualityResult = await _checkDataQuality();
      if (qualityResult['issues'].isNotEmpty) {
        issues.addAll(qualityResult['issues']);
        syncScore -= qualityResult['penalty'];
      }
      
      // 6. Gerar recomendações
      recommendations.addAll(_generateIntegrationRecommendations(issues, syncScore));
      
      // 7. Determinar status
      final status = _determineIntegrationStatus(syncScore, issues);
      
      // 8. Coletar metadados
      metadata.addAll({
        'syncResult': syncResult,
        'validationResult': validationResult,
        'spatialResult': spatialResult,
        'temporalResult': temporalResult,
        'qualityResult': qualityResult,
        'totalIssues': issues.length,
        'criticalIssues': issues.where((i) => i.contains('CRÍTICO')).length,
      });
      
      final result = ModuleIntegrationResult(
        status: status,
        syncScore: syncScore.clamp(0.0, 100.0),
        issues: issues,
        recommendations: recommendations,
        metadata: metadata,
        lastSync: DateTime.now(),
        requiresAction: issues.isNotEmpty,
      );
      
      Logger.info('✅ [INTEGRAÇÃO] Verificação concluída - Score: ${syncScore.toStringAsFixed(1)}% - Status: $status');
      
      return result;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro na verificação: $e');
      return ModuleIntegrationResult(
        status: ModuleIntegrationStatus.outOfSync,
        syncScore: 0.0,
        issues: ['Erro na verificação de integração: $e'],
        recommendations: ['Verificar configuração do sistema'],
        metadata: {},
        lastSync: DateTime.now(),
        requiresAction: true,
      );
    }
  }

  /// Força sincronização entre módulos
  Future<bool> forceModuleSynchronization() async {
    try {
      Logger.info('🔄 [INTEGRAÇÃO] Forçando sincronização entre módulos...');
      
      final database = await _appDatabase.database;
      
      // 1. Buscar todos os monitoramentos
      final monitorings = await _getAllMonitorings(database);
      
      if (monitorings.isEmpty) {
        Logger.warning('⚠️ [INTEGRAÇÃO] Nenhum monitoramento encontrado');
        return false;
      }
      
      // 2. Processar cada monitoramento
      int processedCount = 0;
      int errorCount = 0;
      
      for (final monitoring in monitorings) {
        try {
          // Validar dados antes de processar
          final validationResult = await _validationService.validateMonitoringData(monitoring);
          
          if (validationResult.isValid) {
            // Processar para mapa de infestação
            await _integrationService.processMonitoringForInfestation(monitoring);
            processedCount++;
          } else {
            Logger.warning('⚠️ [INTEGRAÇÃO] Monitoramento ${monitoring.id} inválido - ${validationResult.qualityLevel}');
            errorCount++;
          }
        } catch (e) {
          Logger.error('❌ [INTEGRAÇÃO] Erro ao processar monitoramento ${monitoring.id}: $e');
          errorCount++;
        }
      }
      
      // 3. Registrar histórico de confiabilidade
      final talhoes = await _getUniqueTalhoes(database);
      for (final talhaoId in talhoes) {
        final talhaoName = await _getTalhaoName(database, talhaoId);
        await _historyService.recordConfidenceHistory(talhaoId, talhaoName);
      }
      
      // 4. Executar análise automática de alertas
      await _alertsService.runAutomaticAnalysis();
      
      Logger.info('✅ [INTEGRAÇÃO] Sincronização concluída - Processados: $processedCount, Erros: $errorCount');
      
      return errorCount == 0;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro na sincronização: $e');
      return false;
    }
  }

  /// Verifica sincronização de dados
  Future<Map<String, dynamic>> _checkDataSynchronization() async {
    final issues = <String>[];
    double penalty = 0.0;
    
    try {
      final database = await _appDatabase.database;
      
      // Verificar se há monitoramentos
      final monitoringCount = await database.rawQuery('SELECT COUNT(*) as count FROM monitorings');
      final totalMonitorings = monitoringCount.first['count'] as int;
      
      if (totalMonitorings == 0) {
        issues.add('CRÍTICO: Nenhum monitoramento encontrado');
        penalty += 50.0;
      }
      
      // Verificar se há pontos de infestação
      final infestationCount = await database.rawQuery('SELECT COUNT(*) as count FROM infestation_points');
      final totalInfestations = infestationCount.first['count'] as int;
      
      if (totalInfestations == 0) {
        issues.add('CRÍTICO: Nenhum ponto de infestação no mapa');
        penalty += 50.0;
      }
      
      // Verificar proporção monitoramento/infestação
      if (totalMonitorings > 0 && totalInfestations == 0) {
        issues.add('CRÍTICO: Monitoramentos não geraram pontos de infestação');
        penalty += 40.0;
      }
      
      // Verificar dados órfãos
      final orphanedPoints = await database.rawQuery('''
        SELECT COUNT(*) as count FROM infestation_points ip
        LEFT JOIN monitorings m ON ip.monitoring_id = m.id
        WHERE m.id IS NULL
      ''');
      final orphanedCount = orphanedPoints.first['count'] as int;
      
      if (orphanedCount > 0) {
        issues.add('AVISO: $orphanedCount pontos órfãos encontrados');
        penalty += 10.0;
      }
      
    } catch (e) {
      issues.add('ERRO: Falha na verificação de sincronização: $e');
      penalty += 30.0;
    }
    
    return {
      'issues': issues,
      'penalty': penalty,
    };
  }

  /// Verifica validação de dados
  Future<Map<String, dynamic>> _checkDataValidation() async {
    final issues = <String>[];
    double penalty = 0.0;
    
    try {
      final database = await _appDatabase.database;
      
      // Buscar monitoramentos recentes
      final recentMonitorings = await _getRecentMonitorings(database, days: 7);
      
      if (recentMonitorings.isNotEmpty) {
        // Validar dados
        final validationResult = await _validationService.validateExecutiveReportData(recentMonitorings);
        
        if (validationResult.confidenceScore < 70.0) {
          issues.add('CRÍTICO: Qualidade de dados baixa (${validationResult.confidenceScore.toStringAsFixed(1)}%)');
          penalty += 30.0;
        } else if (validationResult.confidenceScore < 85.0) {
          issues.add('AVISO: Qualidade de dados moderada (${validationResult.confidenceScore.toStringAsFixed(1)}%)');
          penalty += 15.0;
        }
        
        // Verificar avisos específicos
        for (final warning in validationResult.warnings) {
          issues.add('AVISO: $warning');
          penalty += 5.0;
        }
      }
      
    } catch (e) {
      issues.add('ERRO: Falha na validação de dados: $e');
      penalty += 20.0;
    }
    
    return {
      'issues': issues,
      'penalty': penalty,
    };
  }

  /// Verifica precisão espacial
  Future<Map<String, dynamic>> _checkSpatialAccuracy() async {
    final issues = <String>[];
    double penalty = 0.0;
    
    try {
      final database = await _appDatabase.database;
      
      // Verificar precisão GPS
      final gpsResults = await database.rawQuery('''
        SELECT AVG(gps_accuracy) as avg_accuracy, MAX(gps_accuracy) as max_accuracy, COUNT(*) as count
        FROM monitoring_points
        WHERE gps_accuracy IS NOT NULL
      ''');
      
      if (gpsResults.isNotEmpty) {
        final avgAccuracy = gpsResults.first['avg_accuracy'] as double? ?? 0.0;
        final maxAccuracy = gpsResults.first['max_accuracy'] as double? ?? 0.0;
        final pointCount = gpsResults.first['count'] as int? ?? 0;
        
        if (pointCount > 0) {
          if (avgAccuracy > 20.0) {
            issues.add('CRÍTICO: Precisão GPS muito baixa (média: ${avgAccuracy.toStringAsFixed(1)}m)');
            penalty += 25.0;
          } else if (avgAccuracy > 10.0) {
            issues.add('AVISO: Precisão GPS moderada (média: ${avgAccuracy.toStringAsFixed(1)}m)');
            penalty += 10.0;
          }
          
          if (maxAccuracy > 50.0) {
            issues.add('CRÍTICO: Alguns pontos com precisão GPS muito baixa (máx: ${maxAccuracy.toStringAsFixed(1)}m)');
            penalty += 15.0;
          }
        }
      }
      
    } catch (e) {
      issues.add('ERRO: Falha na verificação de precisão GPS: $e');
      penalty += 15.0;
    }
    
    return {
      'issues': issues,
      'penalty': penalty,
    };
  }

  /// Verifica consistência temporal
  Future<Map<String, dynamic>> _checkTemporalConsistency() async {
    final issues = <String>[];
    double penalty = 0.0;
    
    try {
      final database = await _appDatabase.database;
      
      // Verificar monitoramentos antigos
      final oldMonitorings = await database.rawQuery('''
        SELECT COUNT(*) as count FROM monitorings
        WHERE created_at < datetime('now', '-30 days')
      ''');
      final oldCount = oldMonitorings.first['count'] as int;
      
      if (oldCount > 0) {
        issues.add('AVISO: $oldCount monitoramentos antigos (>30 dias)');
        penalty += 5.0;
      }
      
      // Verificar lacunas temporais
      final gaps = await database.rawQuery('''
        SELECT talhao_id, MAX(created_at) as last_monitoring, COUNT(*) as count
        FROM monitorings
        GROUP BY talhao_id
        HAVING last_monitoring < datetime('now', '-14 days')
      ''');
      
      if (gaps.isNotEmpty) {
        issues.add('CRÍTICO: ${gaps.length} talhões sem monitoramento recente (>14 dias)');
        penalty += 20.0;
      }
      
    } catch (e) {
      issues.add('ERRO: Falha na verificação temporal: $e');
      penalty += 10.0;
    }
    
    return {
      'issues': issues,
      'penalty': penalty,
    };
  }

  /// Verifica qualidade dos dados
  Future<Map<String, dynamic>> _checkDataQuality() async {
    final issues = <String>[];
    double penalty = 0.0;
    
    try {
      final database = await _appDatabase.database;
      
      // Verificar dados incompletos
      final incompleteData = await database.rawQuery('''
        SELECT COUNT(*) as count FROM monitoring_points
        WHERE latitude = 0.0 OR longitude = 0.0
      ''');
      final incompleteCount = incompleteData.first['count'] as int;
      
      if (incompleteCount > 0) {
        issues.add('CRÍTICO: $incompleteCount pontos com coordenadas inválidas');
        penalty += 20.0;
      }
      
      // Verificar ocorrências sem observações
      final noNotes = await database.rawQuery('''
        SELECT COUNT(*) as count FROM occurrences
        WHERE notes IS NULL OR notes = ''
      ''');
      final noNotesCount = noNotes.first['count'] as int;
      
      if (noNotesCount > 0) {
        issues.add('AVISO: $noNotesCount ocorrências sem observações');
        penalty += 5.0;
      }
      
      // Verificar infestações com índice 0
      final zeroInfestations = await database.rawQuery('''
        SELECT COUNT(*) as count FROM occurrences
        WHERE infestation_index = 0.0
      ''');
      final zeroCount = zeroInfestations.first['count'] as int;
      
      if (zeroCount > 0) {
        issues.add('AVISO: $zeroCount ocorrências com índice de infestação zero');
        penalty += 3.0;
      }
      
    } catch (e) {
      issues.add('ERRO: Falha na verificação de qualidade: $e');
      penalty += 10.0;
    }
    
    return {
      'issues': issues,
      'penalty': penalty,
    };
  }

  /// Gera recomendações de integração
  List<String> _generateIntegrationRecommendations(List<String> issues, double syncScore) {
    final recommendations = <String>[];
    
    if (syncScore < 50.0) {
      recommendations.addAll([
        'Ação imediata necessária',
        'Revisar todos os dados de monitoramento',
        'Verificar configuração do sistema',
        'Contatar suporte técnico',
      ]);
    } else if (syncScore < 70.0) {
      recommendations.addAll([
        'Melhorar qualidade dos dados',
        'Completar informações faltantes',
        'Verificar precisão GPS',
        'Ajustar frequência de monitoramento',
      ]);
    } else if (syncScore < 90.0) {
      recommendations.addAll([
        'Otimizar processo de coleta',
        'Padronizar observações',
        'Melhorar precisão GPS',
      ]);
    } else {
      recommendations.addAll([
        'Manter padrão atual',
        'Monitorar indicadores',
        'Otimizar continuamente',
      ]);
    }
    
    return recommendations;
  }

  /// Determina status de integração
  ModuleIntegrationStatus _determineIntegrationStatus(double syncScore, List<String> issues) {
    if (syncScore < 30.0) return ModuleIntegrationStatus.outOfSync;
    if (syncScore < 50.0) return ModuleIntegrationStatus.validationFailed;
    if (syncScore < 70.0) return ModuleIntegrationStatus.dataMissing;
    if (syncScore < 85.0) return ModuleIntegrationStatus.gpsInaccurate;
    if (syncScore < 95.0) return ModuleIntegrationStatus.temporalInconsistent;
    return ModuleIntegrationStatus.synchronized;
  }

  /// Busca todos os monitoramentos
  Future<List<Monitoring>> _getAllMonitorings(Database database) async {
    try {
      final results = await database.query('monitorings', orderBy: 'created_at DESC');
      
      List<Monitoring> monitorings = [];
      for (final row in results) {
        final monitoring = Monitoring.fromMap(row);
        final points = await _getPointsByMonitoringId(database, monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao buscar monitoramentos: $e');
      return [];
    }
  }

  /// Busca monitoramentos recentes
  Future<List<Monitoring>> _getRecentMonitorings(Database database, {int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final results = await database.query(
        'monitorings',
        where: 'created_at >= ?',
        whereArgs: [cutoffDate.toIso8601String()],
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
      Logger.error('❌ [INTEGRAÇÃO] Erro ao buscar monitoramentos recentes: $e');
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
      Logger.error('❌ [INTEGRAÇÃO] Erro ao buscar pontos: $e');
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
      Logger.error('❌ [INTEGRAÇÃO] Erro ao buscar ocorrências: $e');
      return [];
    }
  }

  /// Busca talhões únicos
  Future<List<String>> _getUniqueTalhoes(Database database) async {
    try {
      final results = await database.rawQuery('SELECT DISTINCT plot_id FROM monitorings');
      return results.map((row) => row['plot_id'] as String).toList();
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao buscar talhões: $e');
      return [];
    }
  }

  /// Busca nome do talhão
  Future<String> _getTalhaoName(Database database, String talhaoId) async {
    try {
      final results = await database.query(
        'talhoes',
        where: 'id = ?',
        whereArgs: [talhaoId],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return results.first['name'] as String;
      }
      
      return 'Talhão $talhaoId';
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao buscar nome do talhão: $e');
      return 'Talhão $talhaoId';
    }
  }
}
