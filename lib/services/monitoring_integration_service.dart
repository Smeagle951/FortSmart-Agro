import '../../database/app_database.dart';
import '../../modules/infestation_map/services/infestacao_integration_service.dart';
import '../../services/monitoring_resume_service.dart';
import '../../utils/logger.dart';

/// Serviço de integração entre módulos de Monitoramento, Mapa de Infestação e Relatórios
class MonitoringIntegrationService {
  static const String _tag = 'MonitoringIntegrationService';
  
  late InfestacaoIntegrationService _infestacaoService;
  late MonitoringResumeService _resumeService;

  MonitoringIntegrationService() {
    _infestacaoService = InfestacaoIntegrationService();
    _resumeService = MonitoringResumeService();
  }

  /// Processa dados de monitoramento e integra com outros módulos
  Future<Map<String, dynamic>> processMonitoringData({
    required String talhaoId,
    required String monitoringId,
    required List<Map<String, dynamic>> occurrences,
  }) async {
    try {
      Logger.info('$_tag: 🔄 Processando dados de monitoramento...');
      
      // 1. Validar dados de entrada
      final validationResult = await _validateMonitoringData(
        talhaoId: talhaoId,
        monitoringId: monitoringId,
        occurrences: occurrences,
      );
      
      if (!validationResult['valid']) {
        return {
          'success': false,
          'error': validationResult['error'],
          'stage': 'validation',
        };
      }

      // 2. Processar ocorrências no módulo de infestação
      final infestationResult = await _processInfestationData(
        talhaoId: talhaoId,
        occurrences: occurrences,
      );

      if (!infestationResult['success']) {
        Logger.warning('$_tag: ⚠️ Falha no processamento de infestação: ${infestationResult['error']}');
      }

      // 3. Atualizar resumo do talhão
      final summaryResult = await _updateTalhaoSummary(talhaoId);

      // 4. Gerar alertas se necessário
      final alertsResult = await _generateAlerts(talhaoId);

      // 5. Preparar dados para relatórios
      final reportsData = await _prepareReportsData(talhaoId, monitoringId);

      Logger.info('$_tag: ✅ Dados processados com sucesso');
      
      return {
        'success': true,
        'infestation': infestationResult,
        'summary': summaryResult,
        'alerts': alertsResult,
        'reports_data': reportsData,
        'timestamp': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao processar dados de monitoramento: $e');
      return {
        'success': false,
        'error': e.toString(),
        'stage': 'processing',
      };
    }
  }

  /// Valida dados de monitoramento
  Future<Map<String, dynamic>> _validateMonitoringData({
    required String talhaoId,
    required String monitoringId,
    required List<Map<String, dynamic>> occurrences,
  }) async {
    try {
      // Verificar se o talhão existe
      final db = await AppDatabase.instance.database;
      final talhaoExists = await db.query(
        'talhoes',
        where: 'id = ?',
        whereArgs: [int.tryParse(talhaoId)],
        limit: 1,
      );

      if (talhaoExists.isEmpty) {
        return {
          'valid': false,
          'error': 'Talhão não encontrado: $talhaoId',
        };
      }

      // Validar ocorrências
      for (final occurrence in occurrences) {
        if (occurrence['latitude'] == null || occurrence['longitude'] == null) {
          return {
            'valid': false,
            'error': 'Coordenadas GPS obrigatórias para todas as ocorrências',
          };
        }

        if (occurrence['organismo_name'] == null || occurrence['organismo_name'].toString().isEmpty) {
          return {
            'valid': false,
            'error': 'Nome do organismo obrigatório',
          };
        }
      }

      return {'valid': true};
    } catch (e) {
      return {
        'valid': false,
        'error': 'Erro na validação: $e',
      };
    }
  }

  /// Processa dados de infestação
  Future<Map<String, dynamic>> _processInfestationData({
    required String talhaoId,
    required List<Map<String, dynamic>> occurrences,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];

      for (final occurrence in occurrences) {
        final result = await _infestacaoService.processMonitoringData({
          'talhao_id': talhaoId,
          'ponto_id': occurrence['ponto_id']?.toString(),
          'latitude': occurrence['latitude'],
          'longitude': occurrence['longitude'],
          'organismo_name': occurrence['organismo_name'],
          'organismo_type': occurrence['organismo_type'],
          'infestation_percentage': occurrence['infestation_percentage'],
          'severity_level': occurrence['severity_level'],
          'quantity': occurrence['quantity'],
          'unit': occurrence['unit'],
          'observations': occurrence['observations'],
          'images': occurrence['images'] ?? [],
          'timestamp': occurrence['timestamp'],
          'gps_accuracy': occurrence['gps_accuracy'],
          'monitoring_session_id': occurrence['monitoring_session_id'],
        });

        results.add(result);
      }

      final successCount = results.where((r) => r['success'] == true).length;
      
      return {
        'success': successCount == occurrences.length,
        'processed_count': successCount,
        'total_count': occurrences.length,
        'results': results,
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao processar dados de infestação: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Atualiza resumo do talhão
  Future<Map<String, dynamic>> _updateTalhaoSummary(String talhaoId) async {
    try {
      // Buscar dados de infestação do talhão
      final infestationData = await _infestacaoService.getInfestationDataForTalhao(
        talhaoId: talhaoId,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      if (infestationData.isEmpty) {
        return {
          'success': true,
          'message': 'Nenhum dado de infestação encontrado',
        };
      }

      // Calcular estatísticas
      double totalSeverity = 0;
      int totalOccurrences = 0;
      final organismCounts = <String, int>{};
      final severityLevels = <String, int>{};

      for (final data in infestationData) {
        final severity = data['percentual'] as double? ?? 0;
        final organism = data['subtipo'] as String? ?? 'Desconhecido';
        final level = data['nivel'] as String? ?? 'Baixo';

        totalSeverity += severity;
        totalOccurrences++;
        
        organismCounts[organism] = (organismCounts[organism] ?? 0) + 1;
        severityLevels[level] = (severityLevels[level] ?? 0) + 1;
      }

      final averageSeverity = totalOccurrences > 0 ? totalSeverity / totalOccurrences : 0;

      // Atualizar tabela de resumo
      final db = await AppDatabase.instance.database;
      await db.insert(
        'infestation_summary',
        {
          'talhao_id': int.tryParse(talhaoId),
          'total_occurrences': totalOccurrences,
          'average_severity': averageSeverity,
          'severity_level': _determineOverallLevel(averageSeverity),
          'top_organism': organismCounts.isNotEmpty 
            ? organismCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
          'last_updated': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {
        'success': true,
        'average_severity': averageSeverity,
        'total_occurrences': totalOccurrences,
        'organism_counts': organismCounts,
        'severity_levels': severityLevels,
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao atualizar resumo do talhão: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gera alertas baseados nos dados de infestação
  Future<Map<String, dynamic>> _generateAlerts(String talhaoId) async {
    try {
      // Buscar dados recentes
      final db = await AppDatabase.instance.database;
      final recentData = await db.query(
        'infestation_data',
        where: 'talhao_id = ? AND julianday(?) - julianday(data_hora) <= 7',
        whereArgs: [int.tryParse(talhaoId), DateTime.now().toIso8601String()],
        orderBy: 'data_hora DESC',
      );

      final alerts = <Map<String, dynamic>>[];

      for (final data in recentData) {
        final severity = data['percentual'] as double? ?? 0;
        final organism = data['subtipo'] as String? ?? 'Desconhecido';
        final level = data['nivel'] as String? ?? 'Baixo';

        // Gerar alerta para níveis altos ou críticos
        if (severity >= 50) {
          alerts.add({
            'talhao_id': talhaoId,
            'organismo_name': organism,
            'level': level,
            'severity': severity,
            'description': 'Alto nível de infestação detectado: $organism (${severity.toStringAsFixed(1)}%)',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // Salvar alertas no banco
      for (final alert in alerts) {
        await db.insert(
          'infestation_alert',
          alert,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return {
        'success': true,
        'alerts_generated': alerts.length,
        'alerts': alerts,
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao gerar alertas: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Prepara dados para relatórios agronômicos
  Future<Map<String, dynamic>> _prepareReportsData(String talhaoId, String monitoringId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Buscar dados do talhão
      final talhaoData = await db.query(
        'talhoes',
        where: 'id = ?',
        whereArgs: [int.tryParse(talhaoId)],
        limit: 1,
      );

      // Buscar dados de infestação
      final infestationData = await db.query(
        'infestation_data',
        where: 'talhao_id = ?',
        whereArgs: [int.tryParse(talhaoId)],
        orderBy: 'data_hora DESC',
      );

      // Buscar dados de monitoramento
      final monitoringData = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [monitoringId],
        limit: 1,
      );

      return {
        'talhao': talhaoData.isNotEmpty ? talhaoData.first : null,
        'infestation_data': infestationData,
        'monitoring_data': monitoringData.isNotEmpty ? monitoringData.first : null,
        'prepared_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao preparar dados para relatórios: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Determina nível geral baseado na severidade média
  String _determineOverallLevel(double averageSeverity) {
    if (averageSeverity >= 75) return 'CRITICO';
    if (averageSeverity >= 50) return 'ALTO';
    if (averageSeverity >= 25) return 'MODERADO';
    return 'BAIXO';
  }

  /// Obtém status de integração entre módulos
  Future<Map<String, dynamic>> getIntegrationStatus() async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar tabelas principais
      final tables = [
        'talhoes',
        'infestation_data',
        'monitoring_sessions',
        'monitoring_points',
        'infestation_summary',
        'infestation_alert',
      ];

      final tableStatus = <String, bool>{};
      
      for (final table in tables) {
        try {
          await db.rawQuery('SELECT COUNT(*) FROM $table LIMIT 1');
          tableStatus[table] = true;
        } catch (e) {
          tableStatus[table] = false;
        }
      }

      final allTablesExist = tableStatus.values.every((exists) => exists);

      return {
        'success': true,
        'all_modules_ready': allTablesExist,
        'table_status': tableStatus,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar status de integração: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}