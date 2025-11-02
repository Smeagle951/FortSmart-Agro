import 'package:sqflite/sqflite.dart';
import '../models/infestation_timeline_model.dart';
import '../../../utils/logger.dart';

/// Repositório para gerenciar dados da timeline de infestação
class InfestationTimelineRepository {
  final Database _database;
  static const String _tableName = 'infestation_timeline';

  InfestationTimelineRepository(this._database);

  /// Inicializa a tabela
  Future<void> createTable() async {
    try {
      await _database.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          data_ocorrencia DATETIME NOT NULL,
          quantidade INTEGER NOT NULL,
          nivel TEXT NOT NULL,
          percentual REAL NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          usuario_id TEXT,
          observacao TEXT,
          foto_paths TEXT,
          sync_status TEXT DEFAULT 'pending',
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          server_id TEXT,
          last_sync_error TEXT,
          attempts_sync INTEGER DEFAULT 0
        )
      ''');
      
      // Criar índices para performance
      await _database.execute('''
        CREATE INDEX IF NOT EXISTS idx_infestation_timeline_talhao_organismo 
        ON $_tableName (talhao_id, organismo_id)
      ''');
      
      await _database.execute('''
        CREATE INDEX IF NOT EXISTS idx_infestation_timeline_data 
        ON $_tableName (data_ocorrencia)
      ''');
      
      await _database.execute('''
        CREATE INDEX IF NOT EXISTS idx_infestation_timeline_sync 
        ON $_tableName (sync_status)
      ''');
      
      Logger.info('✅ Tabela infestation_timeline criada com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao criar tabela infestation_timeline: $e');
      rethrow;
    }
  }

  /// Insere uma nova entrada na timeline
  Future<String> insert(InfestationTimelineModel timeline) async {
    try {
      await _database.insert(
        _tableName,
        timeline.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      Logger.info('✅ Timeline inserida: ${timeline.id}');
      return timeline.id;
    } catch (e) {
      Logger.error('❌ Erro ao inserir timeline: $e');
      rethrow;
    }
  }

  /// Atualiza uma entrada na timeline
  Future<void> update(InfestationTimelineModel timeline) async {
    try {
      await _database.update(
        _tableName,
        timeline.toMap(),
        where: 'id = ?',
        whereArgs: [timeline.id],
      );
      Logger.info('✅ Timeline atualizada: ${timeline.id}');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar timeline: $e');
      rethrow;
    }
  }

  /// Remove uma entrada da timeline
  Future<void> delete(String id) async {
    try {
      await _database.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      Logger.info('✅ Timeline removida: $id');
    } catch (e) {
      Logger.error('❌ Erro ao remover timeline: $e');
      rethrow;
    }
  }

  /// Busca uma entrada por ID
  Future<InfestationTimelineModel?> getById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return InfestationTimelineModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar timeline por ID: $e');
      return null;
    }
  }

  /// Busca todas as entradas
  Future<List<InfestationTimelineModel>> getAll() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        _tableName,
        orderBy: 'data_ocorrencia DESC',
      );

      return maps.map((map) => InfestationTimelineModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar todas as timelines: $e');
      return [];
    }
  }

  /// Busca timeline por talhão e organismo
  Future<List<InfestationTimelineModel>> getByTalhaoAndOrganismo(
    String talhaoId,
    String organismoId, {
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      String whereClause = 'talhao_id = ? AND organismo_id = ?';
      List<dynamic> whereArgs = [talhaoId, organismoId];

      if (dataInicio != null) {
        whereClause += ' AND data_ocorrencia >= ?';
        whereArgs.add(dataInicio.toIso8601String());
      }

      if (dataFim != null) {
        whereClause += ' AND data_ocorrencia <= ?';
        whereArgs.add(dataFim.toIso8601String());
      }

      final List<Map<String, dynamic>> maps = await _database.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_ocorrencia ASC',
      );

      return maps.map((map) => InfestationTimelineModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar timeline por talhão e organismo: $e');
      return [];
    }
  }

  /// Busca timeline por talhão
  Future<List<InfestationTimelineModel>> getByTalhao(String talhaoId) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_ocorrencia DESC',
      );

      return maps.map((map) => InfestationTimelineModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar timeline por talhão: $e');
      return [];
    }
  }

  /// Busca timeline por organismo
  Future<List<InfestationTimelineModel>> getByOrganismo(String organismoId) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        _tableName,
        where: 'organismo_id = ?',
        whereArgs: [organismoId],
        orderBy: 'data_ocorrencia DESC',
      );

      return maps.map((map) => InfestationTimelineModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar timeline por organismo: $e');
      return [];
    }
  }

  /// Busca entradas pendentes de sincronização
  Future<List<InfestationTimelineModel>> getPendingSync() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        _tableName,
        where: 'sync_status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at ASC',
      );

      return maps.map((map) => InfestationTimelineModel.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar timelines pendentes: $e');
      return [];
    }
  }

  /// Atualiza status de sincronização
  Future<void> updateSyncStatus(
    String id,
    String status, {
    String? serverId,
    String? error,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'sync_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (serverId != null) {
        updateData['server_id'] = serverId;
      }

      if (error != null) {
        updateData['last_sync_error'] = error;
        updateData['attempts_sync'] = await _incrementAttempts(id);
      }

      await _database.update(
        _tableName,
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );

      Logger.info('✅ Status de sync atualizado: $id -> $status');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar status de sync: $e');
      rethrow;
    }
  }

  /// Incrementa contador de tentativas de sincronização
  Future<int> _incrementAttempts(String id) async {
    try {
      final result = await _database.rawQuery(
        'SELECT attempts_sync FROM $_tableName WHERE id = ?',
        [id],
      );

      if (result.isNotEmpty) {
        final currentAttempts = result.first['attempts_sync'] as int? ?? 0;
        return currentAttempts + 1;
      }
      return 1;
    } catch (e) {
      Logger.error('❌ Erro ao incrementar tentativas: $e');
      return 1;
    }
  }

  /// Remove entradas antigas (mais de 1 ano)
  Future<int> cleanupOldEntries() async {
    try {
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      
      final result = await _database.delete(
        _tableName,
        where: 'data_ocorrencia < ?',
        whereArgs: [oneYearAgo.toIso8601String()],
      );

      Logger.info('✅ $result entradas antigas removidas da timeline');
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao limpar entradas antigas: $e');
      return 0;
    }
  }

  /// Obtém estatísticas da timeline
  Future<Map<String, dynamic>> getStats() async {
    try {
      final totalResult = await _database.rawQuery(
        'SELECT COUNT(*) as total FROM $_tableName',
      );
      
      final pendingResult = await _database.rawQuery(
        'SELECT COUNT(*) as pending FROM $_tableName WHERE sync_status = ?',
        ['pending'],
      );

      final lastWeekResult = await _database.rawQuery(
        'SELECT COUNT(*) as last_week FROM $_tableName WHERE data_ocorrencia >= ?',
        [DateTime.now().subtract(const Duration(days: 7)).toIso8601String()],
      );

      return {
        'total_entries': totalResult.first['total'] ?? 0,
        'pending_sync': pendingResult.first['pending'] ?? 0,
        'last_week_entries': lastWeekResult.first['last_week'] ?? 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas da timeline: $e');
      return {};
    }
  }
}
