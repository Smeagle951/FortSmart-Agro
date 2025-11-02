import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço de diagnóstico para o histórico de monitoramento
/// Verifica tabelas, dados e integridade
class MonitoringHistoryDiagnosticService {
  static final MonitoringHistoryDiagnosticService _instance = MonitoringHistoryDiagnosticService._internal();
  factory MonitoringHistoryDiagnosticService() => _instance;
  MonitoringHistoryDiagnosticService._internal();

  final AppDatabase _database = AppDatabase();

  /// Executa diagnóstico completo do histórico de monitoramento
  Future<Map<String, dynamic>> runFullDiagnostic() async {
    try {
      Logger.info('🔍 Iniciando diagnóstico completo do histórico de monitoramento...');
      
      final results = <String, dynamic>{};
      
      // 1. Verificar tabelas existentes
      results['tables'] = await _checkTables();
      
      // 2. Verificar dados em cada tabela
      results['data_counts'] = await _checkDataCounts();
      
      // 3. Verificar estrutura das tabelas
      results['table_structures'] = await _checkTableStructures();
      
      // 4. Verificar dados recentes
      results['recent_data'] = await _checkRecentData();
      
      // 5. Verificar integridade dos dados
      results['data_integrity'] = await _checkDataIntegrity();
      
      Logger.info('✅ Diagnóstico completo finalizado');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      return {'error': e.toString()};
    }
  }

  /// Verifica quais tabelas existem
  Future<Map<String, bool>> _checkTables() async {
    try {
      final db = await _database.database;
      final tables = [
        'monitoring_history',
        'monitoring_sessions',
        'monitoring_points',
        'monitoring_occurrences',
        'infestacoes_monitoramento',
        'infestation_map',
      ];
      
      final results = <String, bool>{};
      
      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
        );
        results[table] = result.isNotEmpty;
        Logger.info('📋 Tabela $table: ${result.isNotEmpty ? "EXISTE" : "NÃO EXISTE"}');
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao verificar tabelas: $e');
      return {};
    }
  }

  /// Verifica contagem de dados em cada tabela
  Future<Map<String, int>> _checkDataCounts() async {
    try {
      final db = await _database.database;
      final tables = [
        'monitoring_history',
        'monitoring_sessions',
        'monitoring_points',
        'monitoring_occurrences',
        'infestacoes_monitoramento',
        'infestation_map',
      ];
      
      final results = <String, int>{};
      
      for (final table in tables) {
        try {
          final result = await db.rawQuery("SELECT COUNT(*) as count FROM $table");
          final count = result.first['count'] as int;
          results[table] = count;
          Logger.info('📊 Tabela $table: $count registros');
        } catch (e) {
          results[table] = -1; // Tabela não existe ou erro
          Logger.warning('⚠️ Erro ao contar $table: $e');
        }
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao verificar contagens: $e');
      return {};
    }
  }

  /// Verifica estrutura das tabelas
  Future<Map<String, List<String>>> _checkTableStructures() async {
    try {
      final db = await _database.database;
      final tables = [
        'monitoring_history',
        'monitoring_sessions',
        'monitoring_points',
        'monitoring_occurrences',
        'infestacoes_monitoramento',
      ];
      
      final results = <String, List<String>>{};
      
      for (final table in tables) {
        try {
          final columns = await db.rawQuery("PRAGMA table_info($table)");
          final columnNames = columns.map((c) => c['name'] as String).toList();
          results[table] = columnNames;
          Logger.info('🏗️ Estrutura $table: ${columnNames.join(', ')}');
        } catch (e) {
          results[table] = [];
          Logger.warning('⚠️ Erro ao verificar estrutura $table: $e');
        }
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao verificar estruturas: $e');
      return {};
    }
  }

  /// Verifica dados recentes
  Future<Map<String, dynamic>> _checkRecentData() async {
    try {
      final db = await _database.database;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final results = <String, dynamic>{};
      
      // Verificar monitoring_history
      try {
        final historyData = await db.query(
          'monitoring_history',
          where: 'created_at > ?',
          whereArgs: [weekAgo.toIso8601String()],
          orderBy: 'created_at DESC',
          limit: 5,
        );
        results['monitoring_history_recent'] = historyData;
        Logger.info('📚 Histórico recente: ${historyData.length} registros');
      } catch (e) {
        Logger.warning('⚠️ Erro ao verificar histórico recente: $e');
      }
      
      // Verificar monitoring_sessions
      try {
        final sessionsData = await db.query(
          'monitoring_sessions',
          where: 'created_at > ?',
          whereArgs: [weekAgo.toIso8601String()],
          orderBy: 'created_at DESC',
          limit: 5,
        );
        results['monitoring_sessions_recent'] = sessionsData;
        Logger.info('📋 Sessões recentes: ${sessionsData.length} registros');
      } catch (e) {
        Logger.warning('⚠️ Erro ao verificar sessões recentes: $e');
      }
      
      // Verificar infestacoes_monitoramento
      try {
        final infestacaoData = await db.query(
          'infestacoes_monitoramento',
          where: 'data_hora > ?',
          whereArgs: [weekAgo.toIso8601String()],
          orderBy: 'data_hora DESC',
          limit: 5,
        );
        results['infestacoes_recent'] = infestacaoData;
        Logger.info('🐛 Infestações recentes: ${infestacaoData.length} registros');
      } catch (e) {
        Logger.warning('⚠️ Erro ao verificar infestações recentes: $e');
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados recentes: $e');
      return {};
    }
  }

  /// Verifica integridade dos dados
  Future<Map<String, dynamic>> _checkDataIntegrity() async {
    try {
      final db = await _database.database;
      final results = <String, dynamic>{};
      
      // Verificar se há dados órfãos
      try {
        final orphanOccurrences = await db.rawQuery('''
          SELECT mo.id, mo.session_id 
          FROM monitoring_occurrences mo 
          LEFT JOIN monitoring_sessions ms ON mo.session_id = ms.id 
          WHERE ms.id IS NULL
        ''');
        results['orphan_occurrences'] = orphanOccurrences.length;
        Logger.info('🔍 Ocorrências órfãs: ${orphanOccurrences.length}');
      } catch (e) {
        Logger.warning('⚠️ Erro ao verificar ocorrências órfãs: $e');
      }
      
      // Verificar se há dados duplicados
      try {
        final duplicateSessions = await db.rawQuery('''
          SELECT id, COUNT(*) as count 
          FROM monitoring_sessions 
          GROUP BY id 
          HAVING COUNT(*) > 1
        ''');
        results['duplicate_sessions'] = duplicateSessions.length;
        Logger.info('🔍 Sessões duplicadas: ${duplicateSessions.length}');
      } catch (e) {
        Logger.warning('⚠️ Erro ao verificar sessões duplicadas: $e');
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ Erro ao verificar integridade: $e');
      return {};
    }
  }

  /// Cria dados de teste para verificar funcionamento
  Future<bool> createTestData() async {
    try {
      Logger.info('🧪 Criando dados de teste...');
      
      final db = await _database.database;
      final now = DateTime.now();
      
      // Criar sessão de teste
      await db.insert('monitoring_sessions', {
        'id': 'test_session_${now.millisecondsSinceEpoch}',
        'fazenda_id': 'fazenda_1',
        'talhao_id': 'talhao_teste',
        'cultura_id': 'cultura_teste',
        'amostragem_padrao_plantas_por_ponto': 10,
        'started_at': now.toIso8601String(),
        'finished_at': now.toIso8601String(),
        'status': 'finalized',
        'device_id': 'test_device',
        'catalog_version': '1.0',
        'sync_state': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      // Criar ponto de teste
      await db.insert('monitoring_points', {
        'id': 'test_point_${now.millisecondsSinceEpoch}',
        'session_id': 'test_session_${now.millisecondsSinceEpoch}',
        'talhao_id': 'talhao_teste',
        'latitude': -23.5505,
        'longitude': -46.6333,
        'plants_evaluated': 10,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      // Criar ocorrência de teste
      await db.insert('monitoring_occurrences', {
        'id': 'test_occurrence_${now.millisecondsSinceEpoch}',
        'session_id': 'test_session_${now.millisecondsSinceEpoch}',
        'point_id': 'test_point_${now.millisecondsSinceEpoch}',
        'organism_id': 1,
        'valor_bruto': 5.0,
        'observacao': 'Teste de ocorrência',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      // Criar registro no histórico
      await db.insert('monitoring_history', {
        'id': 'test_history_${now.millisecondsSinceEpoch}',
        'monitoring_id': 'test_session_${now.millisecondsSinceEpoch}',
        'plot_id': 'talhao_teste',
        'plot_name': 'Talhão Teste',
        'crop_id': 'cultura_teste',
        'crop_name': 'Cultura Teste',
        'date': now.toIso8601String(),
        'points_data': '[]',
        'occurrences_data': '[]',
        'severity': 5.0,
        'technician_name': 'Técnico Teste',
        'observations': 'Dados de teste',
        'created_at': now.toIso8601String(),
        'expires_at': now.add(const Duration(days: 7)).toIso8601String(),
      });
      
      Logger.info('✅ Dados de teste criados com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao criar dados de teste: $e');
      return false;
    }
  }

  /// Limpa dados de teste
  Future<bool> clearTestData() async {
    try {
      Logger.info('🧹 Limpando dados de teste...');
      
      final db = await _database.database;
      
      // Limpar dados de teste
      await db.delete('monitoring_history', where: 'id LIKE ?', whereArgs: ['test_%']);
      await db.delete('monitoring_occurrences', where: 'id LIKE ?', whereArgs: ['test_%']);
      await db.delete('monitoring_points', where: 'id LIKE ?', whereArgs: ['test_%']);
      await db.delete('monitoring_sessions', where: 'id LIKE ?', whereArgs: ['test_%']);
      
      Logger.info('✅ Dados de teste limpos');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados de teste: $e');
      return false;
    }
  }
}
