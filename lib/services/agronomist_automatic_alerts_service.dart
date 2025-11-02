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

/// Tipo de alerta automático
enum AutomaticAlertType {
  dataQuality,
  gpsAccuracy,
  temporalConsistency,
  infestationSeverity,
  monitoringGap,
  systemRecommendation,
}

/// Severidade do alerta
enum AlertSeverity {
  info,
  warning,
  critical,
  urgent,
}

/// Alerta automático
class AutomaticAlert {
  final String id;
  final AutomaticAlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String talhaoId;
  final String talhaoName;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final List<String> recommendedActions;

  AutomaticAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.talhaoId,
    required this.talhaoName,
    required this.createdAt,
    this.resolvedAt,
    required this.isActive,
    required this.metadata,
    required this.recommendedActions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'severity': severity.toString(),
      'title': title,
      'message': message,
      'talhao_id': talhaoId,
      'talhao_name': talhaoName,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'metadata': jsonEncode(metadata),
      'recommended_actions': jsonEncode(recommendedActions),
    };
  }

  static AutomaticAlert fromMap(Map<String, dynamic> map) {
    return AutomaticAlert(
      id: map['id'] as String,
      type: AutomaticAlertType.values.firstWhere((e) => e.toString() == map['type']),
      severity: AlertSeverity.values.firstWhere((e) => e.toString() == map['severity']),
      title: map['title'] as String,
      message: map['message'] as String,
      talhaoId: map['talhao_id'] as String,
      talhaoName: map['talhao_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      resolvedAt: map['resolved_at'] != null ? DateTime.parse(map['resolved_at'] as String) : null,
      isActive: (map['is_active'] as int) == 1,
      metadata: jsonDecode(map['metadata'] as String),
      recommendedActions: List<String>.from(jsonDecode(map['recommended_actions'] as String)),
    );
  }
}

/// Serviço de alertas automáticos
/// Gera alertas inteligentes baseados em análise de dados
class AgronomistAutomaticAlertsService {
  final AppDatabase _appDatabase = AppDatabase();
  final AgronomistDataValidationService _validationService = AgronomistDataValidationService();
  final AgronomistConfidenceHistoryService _historyService = AgronomistConfidenceHistoryService();

  /// Executa análise automática e gera alertas
  Future<List<AutomaticAlert>> runAutomaticAnalysis() async {
    try {
      Logger.info('🔍 [ALERTAS] Executando análise automática...');
      
      final alerts = <AutomaticAlert>[];
      
      // 1. Análise de qualidade de dados
      final dataQualityAlerts = await _analyzeDataQuality();
      alerts.addAll(dataQualityAlerts);
      
      // 2. Análise de precisão GPS
      final gpsAlerts = await _analyzeGPSAccuracy();
      alerts.addAll(gpsAlerts);
      
      // 3. Análise de consistência temporal
      final temporalAlerts = await _analyzeTemporalConsistency();
      alerts.addAll(temporalAlerts);
      
      // 4. Análise de severidade de infestação
      final severityAlerts = await _analyzeInfestationSeverity();
      alerts.addAll(severityAlerts);
      
      // 5. Análise de lacunas de monitoramento
      final gapAlerts = await _analyzeMonitoringGaps();
      alerts.addAll(gapAlerts);
      
      // 6. Recomendações do sistema
      final recommendationAlerts = await _generateSystemRecommendations();
      alerts.addAll(recommendationAlerts);
      
      // Salvar alertas no banco
      await _saveAlerts(alerts);
      
      Logger.info('✅ [ALERTAS] ${alerts.length} alertas gerados');
      
      return alerts;
      
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na análise automática: $e');
      return [];
    }
  }

  /// Obtém alertas ativos
  Future<List<AutomaticAlert>> getActiveAlerts({String? talhaoId}) async {
    try {
      final database = await _appDatabase.database;
      
      String whereClause = 'is_active = 1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      final results = await database.query(
        'automatic_alerts',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      
      return results.map((row) => AutomaticAlert.fromMap(row)).toList();
      
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro ao obter alertas: $e');
      return [];
    }
  }

  /// Resolve um alerta
  Future<void> resolveAlert(String alertId) async {
    try {
      final database = await _appDatabase.database;
      
      await database.update(
        'automatic_alerts',
        {
          'is_active': 0,
          'resolved_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [alertId],
      );
      
      Logger.info('✅ [ALERTAS] Alerta $alertId resolvido');
      
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro ao resolver alerta: $e');
    }
  }

  /// Analisa qualidade de dados
  Future<List<AutomaticAlert>> _analyzeDataQuality() async {
    final alerts = <AutomaticAlert>[];
    
    try {
      final database = await _appDatabase.database;
      final talhoes = await database.query('talhoes');
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        // Buscar monitoramentos recentes
        final monitorings = await _getRecentMonitorings(database, talhaoId, days: 7);
        
        if (monitorings.isNotEmpty) {
          // Validar dados
          final validationResult = await _validationService.validateExecutiveReportData(monitorings);
          
          if (validationResult.confidenceScore < 70.0) {
            alerts.add(AutomaticAlert(
              id: 'data_quality_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
              type: AutomaticAlertType.dataQuality,
              severity: validationResult.confidenceScore < 50.0 ? AlertSeverity.critical : AlertSeverity.warning,
              title: 'Qualidade de Dados Baixa',
              message: 'Talhão $talhaoName apresenta qualidade de dados ${validationResult.qualityLevel.toLowerCase()} (${validationResult.confidenceScore.toStringAsFixed(1)}%)',
              talhaoId: talhaoId,
              talhaoName: talhaoName,
              createdAt: DateTime.now(),
              isActive: true,
              metadata: validationResult.metadata,
              recommendedActions: _generateDataQualityActions(validationResult),
            ));
          }
        }
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na análise de qualidade: $e');
    }
    
    return alerts;
  }

  /// Analisa precisão GPS
  Future<List<AutomaticAlert>> _analyzeGPSAccuracy() async {
    final alerts = <AutomaticAlert>[];
    
    try {
      final database = await _appDatabase.database;
      final talhoes = await database.query('talhoes');
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        // Buscar pontos com precisão GPS ruim
        final results = await database.rawQuery('''
          SELECT mp.id, mp.latitude, mp.longitude, mp.gps_accuracy, m.created_at
          FROM monitoring_points mp
          JOIN monitorings m ON mp.monitoring_id = m.id
          WHERE m.plot_id = ? AND mp.gps_accuracy > 15.0
          ORDER BY m.created_at DESC
          LIMIT 10
        ''', [talhaoId]);
        
        if (results.isNotEmpty) {
          final avgAccuracy = results.map((r) => r['gps_accuracy'] as double).reduce((a, b) => a + b) / results.length;
          
          alerts.add(AutomaticAlert(
            id: 'gps_accuracy_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
            type: AutomaticAlertType.gpsAccuracy,
            severity: avgAccuracy > 25.0 ? AlertSeverity.critical : AlertSeverity.warning,
            title: 'Precisão GPS Baixa',
            message: 'Talhão $talhaoName apresenta precisão GPS média de ${avgAccuracy.toStringAsFixed(1)}m (${results.length} pontos)',
            talhaoId: talhaoId,
            talhaoName: talhaoName,
            createdAt: DateTime.now(),
            isActive: true,
            metadata: {
              'averageAccuracy': avgAccuracy,
              'pointCount': results.length,
              'worstAccuracy': results.map((r) => r['gps_accuracy'] as double).reduce(max),
            },
            recommendedActions: [
              'Verificar configurações de GPS do dispositivo',
              'Repetir monitoramento em áreas com precisão baixa',
              'Usar pontos de referência conhecidos',
              'Aguardar melhor sinal de satélite',
            ],
          ));
        }
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na análise de GPS: $e');
    }
    
    return alerts;
  }

  /// Analisa consistência temporal
  Future<List<AutomaticAlert>> _analyzeTemporalConsistency() async {
    final alerts = <AutomaticAlert>[];
    
    try {
      final database = await _appDatabase.database;
      final talhoes = await database.query('talhoes');
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        // Verificar lacunas temporais
        final results = await database.rawQuery('''
          SELECT created_at, LAG(created_at) OVER (ORDER BY created_at) as prev_date
          FROM monitorings
          WHERE plot_id = ?
          ORDER BY created_at DESC
          LIMIT 10
        ''', [talhaoId]);
        
        if (results.length > 1) {
          for (int i = 1; i < results.length; i++) {
            final currentDate = DateTime.parse(results[i]['created_at'] as String);
            final prevDate = DateTime.parse(results[i-1]['created_at'] as String);
            final gap = currentDate.difference(prevDate).inDays;
            
            if (gap > 14) {
              alerts.add(AutomaticAlert(
                id: 'temporal_gap_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
                type: AutomaticAlertType.temporalConsistency,
                severity: gap > 30 ? AlertSeverity.critical : AlertSeverity.warning,
                title: 'Lacuna Temporal no Monitoramento',
                message: 'Talhão $talhaoName não foi monitorado por $gap dias',
                talhaoId: talhaoId,
                talhaoName: talhaoName,
                createdAt: DateTime.now(),
                isActive: true,
                metadata: {
                  'gapDays': gap,
                  'lastMonitoring': prevDate.toIso8601String(),
                  'currentDate': currentDate.toIso8601String(),
                },
                recommendedActions: [
                  'Agendar monitoramento imediato',
                  'Verificar se há problemas no talhão',
                  'Ajustar frequência de monitoramento',
                ],
              ));
              break; // Apenas um alerta por talhão
            }
          }
        }
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na análise temporal: $e');
    }
    
    return alerts;
  }

  /// Analisa severidade de infestação
  Future<List<AutomaticAlert>> _analyzeInfestationSeverity() async {
    final alerts = <AutomaticAlert>[];
    
    try {
      final database = await _appDatabase.database;
      final talhoes = await database.query('talhoes');
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        // Buscar infestações críticas
        final results = await database.rawQuery('''
          SELECT o.name, o.type, o.infestation_index, mp.latitude, mp.longitude, m.created_at
          FROM occurrences o
          JOIN monitoring_points mp ON o.monitoring_point_id = mp.id
          JOIN monitorings m ON mp.monitoring_id = m.id
          WHERE m.plot_id = ? AND o.infestation_index > 80.0
          ORDER BY m.created_at DESC
          LIMIT 5
        ''', [talhaoId]);
        
        if (results.isNotEmpty) {
          final criticalCount = results.length;
          final avgSeverity = results.map((r) => r['infestation_index'] as double).reduce((a, b) => a + b) / results.length;
          
          alerts.add(AutomaticAlert(
            id: 'infestation_severity_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
            type: AutomaticAlertType.infestationSeverity,
            severity: avgSeverity > 90.0 ? AlertSeverity.urgent : AlertSeverity.critical,
            title: 'Infestações Críticas Detectadas',
            message: 'Talhão $talhaoName apresenta $criticalCount infestações críticas (média: ${avgSeverity.toStringAsFixed(1)}%)',
            talhaoId: talhaoId,
            talhaoName: talhaoName,
            createdAt: DateTime.now(),
            isActive: true,
            metadata: {
              'criticalCount': criticalCount,
              'averageSeverity': avgSeverity,
              'organisms': results.map((r) => r['name'] as String).toSet().toList(),
            },
            recommendedActions: [
              'Ação imediata necessária',
              'Aplicar defensivos específicos',
              'Isolar área afetada',
              'Contatar agrônomo responsável',
              'Documentar com fotos',
            ],
          ));
        }
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na análise de severidade: $e');
    }
    
    return alerts;
  }

  /// Analisa lacunas de monitoramento
  Future<List<AutomaticAlert>> _analyzeMonitoringGaps() async {
    final alerts = <AutomaticAlert>[];
    
    try {
      final database = await _appDatabase.database;
      final talhoes = await database.query('talhoes');
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        // Verificar se há monitoramentos recentes
        final recentMonitorings = await _getRecentMonitorings(database, talhaoId, days: 7);
        
        if (recentMonitorings.isEmpty) {
          alerts.add(AutomaticAlert(
            id: 'monitoring_gap_${talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
            type: AutomaticAlertType.monitoringGap,
            severity: AlertSeverity.warning,
            title: 'Falta de Monitoramento Recente',
            message: 'Talhão $talhaoName não foi monitorado nos últimos 7 dias',
            talhaoId: talhaoId,
            talhaoName: talhaoName,
            createdAt: DateTime.now(),
            isActive: true,
            metadata: {
              'daysSinceLastMonitoring': 7,
              'recommendedFrequency': 'Semanal',
            },
            recommendedActions: [
              'Agendar monitoramento imediato',
              'Verificar se há problemas no talhão',
              'Ajustar frequência de monitoramento',
            ],
          ));
        }
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na análise de lacunas: $e');
    }
    
    return alerts;
  }

  /// Gera recomendações do sistema
  Future<List<AutomaticAlert>> _generateSystemRecommendations() async {
    final alerts = <AutomaticAlert>[];
    
    try {
      // Gerar benchmark de confiabilidade
      final benchmarks = await _historyService.generateConfidenceBenchmark();
      
      for (final benchmark in benchmarks) {
        if (benchmark.averageConfidence < 80.0) {
          alerts.add(AutomaticAlert(
            id: 'system_recommendation_${benchmark.talhaoId}_${DateTime.now().millisecondsSinceEpoch}',
            type: AutomaticAlertType.systemRecommendation,
            severity: benchmark.averageConfidence < 60.0 ? AlertSeverity.critical : AlertSeverity.warning,
            title: 'Recomendação de Melhoria',
            message: 'Talhão ${benchmark.talhaoName} pode melhorar sua confiabilidade (atual: ${benchmark.averageConfidence.toStringAsFixed(1)}%)',
            talhaoId: benchmark.talhaoId,
            talhaoName: benchmark.talhaoName,
            createdAt: DateTime.now(),
            isActive: true,
            metadata: benchmark.recommendations,
            recommendedActions: List<String>.from(benchmark.recommendations['actions'] ?? []),
          ));
        }
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro na geração de recomendações: $e');
    }
    
    return alerts;
  }

  /// Busca monitoramentos recentes
  Future<List<Monitoring>> _getRecentMonitorings(Database database, String talhaoId, {int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final results = await database.query(
        'monitorings',
        where: 'plot_id = ? AND created_at >= ?',
        whereArgs: [talhaoId, cutoffDate.toIso8601String()],
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
      Logger.error('❌ [ALERTAS] Erro ao buscar monitoramentos: $e');
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
      Logger.error('❌ [ALERTAS] Erro ao buscar pontos: $e');
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
      Logger.error('❌ [ALERTAS] Erro ao buscar ocorrências: $e');
      return [];
    }
  }

  /// Gera ações para qualidade de dados
  List<String> _generateDataQualityActions(DataValidationResult validationResult) {
    final actions = <String>[];
    
    if (validationResult.confidenceScore < 50.0) {
      actions.addAll([
        'Revisar todos os dados de monitoramento',
        'Completar informações faltantes',
        'Verificar precisão GPS',
        'Padronizar observações',
      ]);
    } else if (validationResult.confidenceScore < 70.0) {
      actions.addAll([
        'Melhorar qualidade dos dados',
        'Completar campos obrigatórios',
        'Verificar consistência temporal',
      ]);
    } else {
      actions.addAll([
        'Manter padrão atual',
        'Otimizar processo de coleta',
      ]);
    }
    
    return actions;
  }

  /// Salva alertas no banco
  Future<void> _saveAlerts(List<AutomaticAlert> alerts) async {
    try {
      final database = await _appDatabase.database;
      
      for (final alert in alerts) {
        await database.insert('automatic_alerts', alert.toMap());
      }
    } catch (e) {
      Logger.error('❌ [ALERTAS] Erro ao salvar alertas: $e');
    }
  }
}
