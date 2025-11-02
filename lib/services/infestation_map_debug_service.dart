import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import '../modules/infestation_map/repositories/infestation_repository.dart';
import '../modules/infestation_map/models/models.dart';
import 'monitoring_infestation_integration_service.dart';

/// Serviço de diagnóstico para o mapa de infestação
/// Identifica e corrige problemas na integração entre módulos
class InfestationMapDebugService {
  final AppDatabase _appDatabase = AppDatabase();
  final MonitoringInfestationIntegrationService _integrationService = MonitoringInfestationIntegrationService();

  /// Executa diagnóstico completo do sistema de infestação
  Future<Map<String, dynamic>> runFullDiagnostic() async {
    try {
      Logger.info('🔍 [DEBUG] Iniciando diagnóstico completo do sistema de infestação...');
      
      final results = <String, dynamic>{};
      
      // 1. Verificar dados de monitoramento
      final monitoringData = await _checkMonitoringData();
      results['monitoring'] = monitoringData;
      
      // 2. Verificar integração
      final integrationData = await _checkIntegration();
      results['integration'] = integrationData;
      
      // 3. Verificar dados de infestação
      final infestationData = await _checkInfestationData();
      results['infestation'] = infestationData;
      
      // 4. Verificar fluxo completo
      final flowData = await _checkDataFlow();
      results['flow'] = flowData;
      
      // 5. Gerar recomendações
      final recommendations = _generateRecommendations(results);
      results['recommendations'] = recommendations;
      
      Logger.info('✅ [DEBUG] Diagnóstico completo finalizado');
      return results;
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro no diagnóstico: $e');
      return {
        'error': e.toString(),
        'monitoring': {},
        'integration': {},
        'infestation': {},
        'flow': {},
        'recommendations': ['Erro no diagnóstico: $e'],
      };
    }
  }

  /// Verifica dados de monitoramento
  Future<Map<String, dynamic>> _checkMonitoringData() async {
    try {
      final database = await _appDatabase.database;
      
      // Contar monitoramentos
      final monitoringCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM monitorings')
      ) ?? 0;
      
      // Contar pontos de monitoramento
      final pointsCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM monitoring_points')
      ) ?? 0;
      
      // Contar ocorrências
      final occurrencesCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM occurrences')
      ) ?? 0;
      
      // Buscar monitoramentos recentes
      final recentMonitorings = await database.query(
        'monitorings',
        orderBy: 'created_at DESC',
        limit: 5,
      );
      
      // Buscar ocorrências com infestações
      final infestationOccurrences = await database.query(
        'occurrences',
        where: 'infestation_index > 0',
        orderBy: 'infestation_index DESC',
        limit: 10,
      );
      
      return {
        'monitoringCount': monitoringCount,
        'pointsCount': pointsCount,
        'occurrencesCount': occurrencesCount,
        'recentMonitorings': recentMonitorings.length,
        'infestationOccurrences': infestationOccurrences.length,
        'hasData': monitoringCount > 0 && pointsCount > 0 && occurrencesCount > 0,
        'recentData': recentMonitorings.isNotEmpty,
        'infestationData': infestationOccurrences.isNotEmpty,
      };
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro ao verificar dados de monitoramento: $e');
      return {
        'error': e.toString(),
        'hasData': false,
      };
    }
  }

  /// Verifica integração entre módulos
  Future<Map<String, dynamic>> _checkIntegration() async {
    try {
      final database = await _appDatabase.database;
      
      // Verificar se há dados de infestação salvos
      final infestationCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM infestation_summaries')
      ) ?? 0;
      
      // Verificar se há alertas
      final alertsCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM infestation_alerts')
      ) ?? 0;
      
      // Verificar se a tabela existe
      final tableExists = await _checkTableExists('infestation_summaries');
      
      return {
        'infestationCount': infestationCount,
        'alertsCount': alertsCount,
        'tableExists': tableExists,
        'hasIntegrationData': infestationCount > 0 || alertsCount > 0,
      };
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro ao verificar integração: $e');
      return {
        'error': e.toString(),
        'hasIntegrationData': false,
      };
    }
  }

  /// Verifica dados de infestação
  Future<Map<String, dynamic>> _checkInfestationData() async {
    try {
      final repository = InfestationRepository();
      
      // Buscar todos os talhões
      final database = await _appDatabase.database;
      final talhoes = await database.query('talhoes');
      
      if (talhoes.isEmpty) {
        return {
          'hasTalhoes': false,
          'talhoesCount': 0,
          'infestationData': [],
        };
      }
      
      // Verificar dados de infestação para cada talhão
      final infestationData = <Map<String, dynamic>>[];
      
      for (final talhao in talhoes) {
        final talhaoId = talhao['id'] as String;
        final talhaoName = talhao['name'] as String;
        
        try {
          final summaries = await repository.getInfestationSummariesByTalhao(talhaoId);
          final alerts = await repository.getActiveInfestationAlerts(talhaoId: talhaoId);
          
          infestationData.add({
            'talhaoId': talhaoId,
            'talhaoName': talhaoName,
            'summariesCount': summaries.length,
            'alertsCount': alerts.length,
            'hasData': summaries.isNotEmpty || alerts.isNotEmpty,
          });
        } catch (e) {
          infestationData.add({
            'talhaoId': talhaoId,
            'talhaoName': talhaoName,
            'error': e.toString(),
            'hasData': false,
          });
        }
      }
      
      return {
        'hasTalhoes': talhoes.isNotEmpty,
        'talhoesCount': talhoes.length,
        'infestationData': infestationData,
        'totalSummaries': infestationData.fold(0, (sum, data) => sum + (data['summariesCount'] as int)),
        'totalAlerts': infestationData.fold(0, (sum, data) => sum + (data['alertsCount'] as int)),
      };
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro ao verificar dados de infestação: $e');
      return {
        'error': e.toString(),
        'hasTalhoes': false,
        'infestationData': [],
      };
    }
  }

  /// Verifica fluxo completo de dados
  Future<Map<String, dynamic>> _checkDataFlow() async {
    try {
      final database = await _appDatabase.database;
      
      // Buscar monitoramentos com ocorrências
      final monitoringsWithOccurrences = await database.rawQuery('''
        SELECT m.id, m.plot_id, m.created_at, COUNT(o.id) as occurrences_count
        FROM monitorings m
        LEFT JOIN monitoring_points mp ON m.id = mp.monitoring_id
        LEFT JOIN occurrences o ON mp.id = o.monitoring_point_id
        WHERE o.infestation_index > 0
        GROUP BY m.id, m.plot_id, m.created_at
        ORDER BY m.created_at DESC
        LIMIT 10
      ''');
      
      // Verificar se há dados processados
      final processedData = await database.rawQuery('''
        SELECT COUNT(*) as count
        FROM infestation_summaries
      ''');
      
      final processedCount = processedData.first['count'] as int;
      
      return {
        'monitoringsWithOccurrences': monitoringsWithOccurrences.length,
        'processedCount': processedCount,
        'hasFlow': monitoringsWithOccurrences.isNotEmpty,
        'isProcessed': processedCount > 0,
        'recentMonitorings': monitoringsWithOccurrences,
      };
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro ao verificar fluxo de dados: $e');
      return {
        'error': e.toString(),
        'hasFlow': false,
        'isProcessed': false,
      };
    }
  }

  /// Verifica se uma tabela existe
  Future<bool> _checkTableExists(String tableName) async {
    try {
      final database = await _appDatabase.database;
      final result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Gera recomendações baseadas no diagnóstico
  List<String> _generateRecommendations(Map<String, dynamic> results) {
    final recommendations = <String>[];
    
    final monitoring = results['monitoring'] as Map<String, dynamic>;
    final integration = results['integration'] as Map<String, dynamic>;
    final infestation = results['infestation'] as Map<String, dynamic>;
    final flow = results['flow'] as Map<String, dynamic>;
    
    // Verificar dados de monitoramento
    if (!monitoring['hasData']) {
      recommendations.add('❌ Nenhum dado de monitoramento encontrado');
      recommendations.add('💡 Registre pelo menos um monitoramento com ocorrências');
    } else if (!monitoring['infestationData']) {
      recommendations.add('⚠️ Monitoramentos encontrados, mas sem dados de infestação');
      recommendations.add('💡 Verifique se as ocorrências têm infestation_index > 0');
    }
    
    // Verificar integração
    if (!integration['tableExists']) {
      recommendations.add('❌ Tabelas de infestação não existem');
      recommendations.add('💡 Execute a criação das tabelas de infestação');
    } else if (!integration['hasIntegrationData']) {
      recommendations.add('⚠️ Tabelas existem, mas sem dados processados');
      recommendations.add('💡 Execute o processamento de monitoramentos para infestação');
    }
    
    // Verificar dados de infestação
    if (!infestation['hasTalhoes']) {
      recommendations.add('❌ Nenhum talhão encontrado');
      recommendations.add('💡 Crie pelo menos um talhão no sistema');
    } else {
      final totalSummaries = infestation['totalSummaries'] as int;
      if (totalSummaries == 0) {
        recommendations.add('⚠️ Talhões existem, mas sem dados de infestação');
        recommendations.add('💡 Execute o processamento de monitoramentos');
      }
    }
    
    // Verificar fluxo
    if (!flow['hasFlow']) {
      recommendations.add('❌ Nenhum monitoramento com ocorrências encontrado');
      recommendations.add('💡 Registre monitoramentos com infestation_index > 0');
    } else if (!flow['isProcessed']) {
      recommendations.add('⚠️ Monitoramentos existem, mas não foram processados');
      recommendations.add('💡 Execute o processamento automático');
    }
    
    // Recomendações de solução
    if (recommendations.isEmpty) {
      recommendations.add('✅ Sistema funcionando corretamente');
    } else {
      recommendations.add('');
      recommendations.add('🔧 SOLUÇÕES:');
      recommendations.add('1. Verifique se há monitoramentos salvos');
      recommendations.add('2. Execute o processamento de integração');
      recommendations.add('3. Recarregue o mapa de infestação');
      recommendations.add('4. Verifique os filtros aplicados');
    }
    
    return recommendations;
  }

  /// Força o processamento de todos os monitoramentos
  Future<Map<String, dynamic>> forceProcessAllMonitorings() async {
    try {
      Logger.info('🔄 [DEBUG] Forçando processamento de todos os monitoramentos...');
      
      final database = await _appDatabase.database;
      
      // Buscar todos os monitoramentos
      final monitorings = await database.query(
        'monitorings',
        orderBy: 'created_at DESC',
      );
      
      if (monitorings.isEmpty) {
        return {
          'success': false,
          'message': 'Nenhum monitoramento encontrado',
          'processed': 0,
        };
      }
      
      int processedCount = 0;
      int errorCount = 0;
      
      for (final monitoringMap in monitorings) {
        try {
          final monitoring = Monitoring.fromMap(monitoringMap);
          
          // Processar monitoramento para infestação
          final success = await _integrationService.processMonitoringForInfestation(monitoring);
          
          if (success) {
            processedCount++;
            Logger.info('✅ [DEBUG] Monitoramento ${monitoring.id} processado');
          } else {
            errorCount++;
            Logger.warning('⚠️ [DEBUG] Falha ao processar monitoramento ${monitoring.id}');
          }
        } catch (e) {
          errorCount++;
          Logger.error('❌ [DEBUG] Erro ao processar monitoramento: $e');
        }
      }
      
      Logger.info('✅ [DEBUG] Processamento concluído: $processedCount sucessos, $errorCount erros');
      
      return {
        'success': true,
        'message': 'Processamento concluído',
        'processed': processedCount,
        'errors': errorCount,
        'total': monitorings.length,
      };
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro no processamento forçado: $e');
      return {
        'success': false,
        'message': 'Erro no processamento: $e',
        'processed': 0,
        'errors': 1,
      };
    }
  }

  /// Cria dados de teste para verificação
  Future<Map<String, dynamic>> createTestData() async {
    try {
      Logger.info('🧪 [DEBUG] Criando dados de teste...');
      
      final database = await _appDatabase.database;
      
      // Verificar se já existem dados
      final existingCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM monitorings')
      ) ?? 0;
      
      if (existingCount > 0) {
        return {
          'success': false,
          'message': 'Já existem dados de monitoramento. Não é necessário criar dados de teste.',
          'existingCount': existingCount,
        };
      }
      
      // Criar dados de teste
      final testMonitoring = await _createTestMonitoring();
      
      return {
        'success': true,
        'message': 'Dados de teste criados com sucesso',
        'monitoringId': testMonitoring.id,
      };
      
    } catch (e) {
      Logger.error('❌ [DEBUG] Erro ao criar dados de teste: $e');
      return {
        'success': false,
        'message': 'Erro ao criar dados de teste: $e',
      };
    }
  }

  /// Cria um monitoramento de teste
  Future<Monitoring> _createTestMonitoring() async {
    final database = await _appDatabase.database;
    
    // Criar monitoramento de teste
    final monitoringId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    final talhaoId = 'test_talhao_1';
    
    await database.insert('monitorings', {
      'id': monitoringId,
      'plot_id': talhaoId,
      'date': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    // Criar ponto de monitoramento
    final pointId = 'test_point_${DateTime.now().millisecondsSinceEpoch}';
    await database.insert('monitoring_points', {
      'id': pointId,
      'monitoring_id': monitoringId,
      'latitude': -23.1234,
      'longitude': -46.5678,
      'gps_accuracy': 5.0,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Criar ocorrência de teste
    final occurrenceId = 'test_occurrence_${DateTime.now().millisecondsSinceEpoch}';
    await database.insert('occurrences', {
      'id': occurrenceId,
      'monitoring_point_id': pointId,
      'name': 'Teste Pragas',
      'type': 'pest',
      'infestation_index': 75.0,
      'notes': 'Ocorrência de teste',
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Criar talhão de teste se não existir
    try {
      await database.insert('talhoes', {
        'id': talhaoId,
        'name': 'Talhão de Teste',
        'area': 10.0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Talhão já existe
    }
    
    return Monitoring(
      id: monitoringId,
      plotId: int.parse(talhaoId),
      plotName: 'Talhão $talhaoId',
      cropId: '1',
      cropName: 'Soja',
      route: [],
      date: DateTime.now(),
      points: [
        MonitoringPoint(
          id: pointId,
          monitoringId: monitoringId,
          plotId: int.parse(talhaoId),
          plotName: 'Talhão $talhaoId',
          latitude: -23.1234,
          longitude: -46.5678,
          gpsAccuracy: 5.0,
          createdAt: DateTime.now(),
          occurrences: [
            Occurrence(
              id: occurrenceId,
              monitoringPointId: pointId,
              name: 'Teste Pragas',
              type: OccurrenceType.pest,
              infestationIndex: 75.0,
              affectedSections: [PlantSection.leaf],
              notes: 'Ocorrência de teste',
              createdAt: DateTime.now(),
            ),
          ],
        ),
      ],
    );
  }
}
