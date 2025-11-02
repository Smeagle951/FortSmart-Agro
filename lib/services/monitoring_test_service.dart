import 'dart:convert';
import '../database/app_database.dart';
import '../database/migrations/create_monitoring_tables_unified.dart';
import '../utils/logger.dart';

/// Serviço de teste para verificar o funcionamento do sistema de monitoramento
class MonitoringTestService {
  static final MonitoringTestService _instance = MonitoringTestService._internal();
  factory MonitoringTestService() => _instance;
  MonitoringTestService._internal();

  final AppDatabase _database = AppDatabase();

  /// Executa teste completo do sistema de monitoramento
  Future<void> runFullTest() async {
    try {
      Logger.info('🧪 Iniciando teste completo do sistema de monitoramento...');
      
      // 1. Garantir que as tabelas existem
      await _ensureTablesExist();
      
      // 2. Inserir dados de teste
      await _insertTestData();
      
      // 3. Verificar se os dados foram inseridos
      await _verifyDataInsertion();
      
      // 4. Testar consulta do histórico
      await _testHistoryQuery();
      
      Logger.info('✅ Teste completo executado com sucesso!');
      
    } catch (e) {
      Logger.error('❌ Erro no teste completo: $e');
    }
  }

  /// Garante que as tabelas existem
  Future<void> _ensureTablesExist() async {
    try {
      Logger.info('🔧 Garantindo que as tabelas existem...');
      
      final db = await _database.database;
      await CreateMonitoringTablesUnified.up(db);
      
      Logger.info('✅ Tabelas verificadas/criadas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao garantir tabelas: $e');
      rethrow;
    }
  }

  /// Insere dados de teste
  Future<void> _insertTestData() async {
    try {
      Logger.info('📝 Inserindo dados de teste...');
      
      final db = await _database.database;
      final now = DateTime.now();
      
      // DADOS DE TESTE REMOVIDOS - Usar apenas dados reais
      Logger.info('⚠️ Serviço de teste desativado - use apenas dados reais');
      return;
      
      /* DADOS DE TESTE REMOVIDOS
      // Inserir ocorrências de teste
      final occurrence1Id = 'test_occurrence_1_${now.millisecondsSinceEpoch}';
      await db.insert('monitoring_occurrences', {
        'id': occurrence1Id,
        'point_id': 'point_1',
        'session_id': sessionId,
        'talhao_id': 'talhao_teste',
        'tipo': 'praga',
        'subtipo': 'Lagarta alfinete',
        'nivel': 'Médio',
        'percentual': 25,
        'quantidade': 5,
        'terco_planta': 'Médio',
        'observacao': 'Ocorrência de teste 1',
        'foto_paths': '[]',
        'latitude': -23.5505,
        'longitude': -46.6333,
        'data_hora': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'sincronizado': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      final occurrence2Id = 'test_occurrence_2_${now.millisecondsSinceEpoch}';
      await db.insert('monitoring_occurrences', {
        'id': occurrence2Id,
        'point_id': 'point_2',
        'session_id': sessionId,
        'talhao_id': 'talhao_teste',
        'tipo': 'doença',
        'subtipo': 'Ferrugem',
        'nivel': 'Alto',
        'percentual': 60,
        'quantidade': 3,
        'terco_planta': 'Baixeiro',
        'observacao': 'Ocorrência de teste 2',
        'foto_paths': '[]',
        'latitude': -23.5506,
        'longitude': -46.6334,
        'data_hora': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'sincronizado': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      // Inserir no histórico
      await db.insert('monitoring_history', {
        'id': 'test_history_${now.millisecondsSinceEpoch}',
        'monitoring_id': sessionId,
        'plot_id': 'talhao_teste',
        'plot_name': 'Talhão de Teste',
        'crop_id': 'cultura_teste',
        'crop_name': 'Soja',
        'date': now.toIso8601String(),
        'points_data': jsonEncode([
          {
            'id': 'point_1',
            'latitude': -23.5505,
            'longitude': -46.6333,
            'occurrences': [
              {
                'name': 'Lagarta alfinete',
                'type': 'praga',
                'infestationIndex': 25,
                'notes': 'Ocorrência de teste 1',
              }
            ],
            'observations': 'Ponto 1',
            'createdAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
          }
        ]),
        'occurrences_data': jsonEncode([
          {
            'name': 'Lagarta alfinete',
            'type': 'praga',
            'infestationIndex': 25,
            'notes': 'Ocorrência de teste 1',
            'pointId': 'point_1',
            'pointLatitude': -23.5505,
            'pointLongitude': -46.6333,
          }
        ]),
        'severity': 42.5,
        'technician_name': 'Técnico Teste',
        'observations': 'Monitoramento de teste',
        'created_at': now.toIso8601String(),
        'expires_at': now.add(const Duration(days: 7)).toIso8601String(),
      });
      
      Logger.info('✅ Dados de teste inseridos com sucesso');
      */ // FIM DO COMENTÁRIO - DADOS DE TESTE REMOVIDOS
      
    } catch (e) {
      Logger.error('❌ Erro ao inserir dados de teste: $e');
      rethrow;
    }
  }

  /// Verifica se os dados foram inseridos corretamente
  Future<void> _verifyDataInsertion() async {
    try {
      Logger.info('🔍 Verificando inserção de dados...');
      
      final db = await _database.database;
      
      // Verificar sessões
      final sessions = await db.query('monitoring_sessions');
      Logger.info('📊 Sessões encontradas: ${sessions.length}');
      
      // Verificar ocorrências
      final occurrences = await db.query('monitoring_occurrences');
      Logger.info('📊 Ocorrências encontradas: ${occurrences.length}');
      
      // Verificar histórico
      final history = await db.query('monitoring_history');
      Logger.info('📊 Histórico encontrado: ${history.length}');
      
      if (sessions.isNotEmpty && occurrences.isNotEmpty && history.isNotEmpty) {
        Logger.info('✅ Dados inseridos e verificados com sucesso');
      } else {
        Logger.warning('⚠️ Alguns dados não foram inseridos corretamente');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar inserção: $e');
      rethrow;
    }
  }

  /// Testa a consulta do histórico
  Future<void> _testHistoryQuery() async {
    try {
      Logger.info('🔍 Testando consulta do histórico...');
      
      final db = await _database.database;
      
      // Testar consulta similar ao MonitoringHistoryService
      final now = DateTime.now();
      final results = await db.query(
        'monitoring_history',
        where: 'expires_at > ?',
        whereArgs: [now.toIso8601String()],
        orderBy: 'created_at DESC',
        limit: 10,
      );
      
      Logger.info('📊 Resultados da consulta de histórico: ${results.length}');
      
      for (final row in results) {
        Logger.info('📋 Histórico: ${row['plot_name']} - ${row['date']} - Severidade: ${row['severity']}');
      }
      
      // Testar consulta de ocorrências
      final occurrencesResults = await db.query(
        'monitoring_occurrences',
        where: 'created_at > ?',
        whereArgs: [now.subtract(const Duration(days: 7)).toIso8601String()],
        orderBy: 'created_at DESC',
        limit: 10,
      );
      
      Logger.info('📊 Resultados da consulta de ocorrências: ${occurrencesResults.length}');
      
      for (final row in occurrencesResults) {
        Logger.info('📋 Ocorrência: ${row['subtipo']} - ${row['tipo']} - ${row['percentual']}%');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao testar consulta: $e');
      rethrow;
    }
  }

  /// Limpa dados de teste
  Future<void> cleanupTestData() async {
    try {
      Logger.info('🧹 Limpando dados de teste...');
      
      final db = await _database.database;
      
      await db.delete('monitoring_history', where: 'plot_id = ?', whereArgs: ['talhao_teste']);
      await db.delete('monitoring_occurrences', where: 'talhao_id = ?', whereArgs: ['talhao_teste']);
      await db.delete('monitoring_sessions', where: 'talhao_id = ?', whereArgs: ['talhao_teste']);
      
      Logger.info('✅ Dados de teste limpos');
      
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados de teste: $e');
    }
  }
}
