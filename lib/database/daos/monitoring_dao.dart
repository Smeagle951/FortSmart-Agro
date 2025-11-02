import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/monitoring.dart';
import '../../utils/logger.dart';

/// DAO para operações de monitoramento no banco de dados
class MonitoringDao {
  final AppDatabase _database = AppDatabase();
  static const String _tag = 'MonitoringDao';

  /// Obtém todos os monitoramentos
  Future<List<Monitoring>> getAll() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('monitorings');
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter todos os monitoramentos: $e');
      return [];
    }
  }

  /// Obtém monitoramento por ID
  Future<Monitoring?> getById(String id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return Monitoring.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramento por ID: $e');
      return null;
    }
  }

  /// Obtém monitoramentos por talhão
  Future<List<Monitoring>> getByPlotId(int plotId) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'plot_id = ?',
        whereArgs: [plotId.toString()],
        orderBy: 'date DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramentos por talhão: $e');
      return [];
    }
  }

  /// Obtém monitoramentos recentes
  Future<List<Monitoring>> getRecent({int limit = 10}) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramentos recentes: $e');
      return [];
    }
  }

  /// Obtém monitoramentos não sincronizados
  Future<List<Monitoring>> getUnsynced() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'isSynced = 0',
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramentos não sincronizados: $e');
      return [];
    }
  }

  /// Insere um monitoramento
  Future<bool> insert(Monitoring monitoring) async {
    try {
      final db = await _database.database;
      await db.insert(
        'monitorings',
        monitoring.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('$_tag: Monitoramento inserido com sucesso: ${monitoring.id}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao inserir monitoramento: $e');
      return false;
    }
  }

  /// Atualiza um monitoramento
  Future<bool> update(Monitoring monitoring) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitorings',
        monitoring.toMap(),
        where: 'id = ?',
        whereArgs: [monitoring.id],
      );
      
      Logger.info('$_tag: Monitoramento atualizado com sucesso: ${monitoring.id}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar monitoramento: $e');
      return false;
    }
  }

  /// Remove um monitoramento
  Future<bool> delete(String id) async {
    try {
      final db = await _database.database;
      await db.delete(
        'monitorings',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Monitoramento removido com sucesso: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao remover monitoramento: $e');
      return false;
    }
  }

  /// Marca monitoramento como sincronizado
  Future<bool> markAsSynced(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitorings',
        {
          'isSynced': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Monitoramento marcado como sincronizado: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao marcar monitoramento como sincronizado: $e');
      return false;
    }
  }

  /// Marca monitoramento como completado
  Future<bool> markAsCompleted(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitorings',
        {
          'isCompleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Monitoramento marcado como completado: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao marcar monitoramento como completado: $e');
      return false;
    }
  }

  /// Obtém estatísticas de monitoramento
  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await _database.database;
      
      // Total de monitoramentos
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM monitorings');
      final total = totalResult.first['total'] as int;
      
      // Monitoramentos completados
      final completedResult = await db.rawQuery(
        'SELECT COUNT(*) as completed FROM monitorings WHERE isCompleted = 1'
      );
      final completed = completedResult.first['completed'] as int;
      
      // Monitoramentos sincronizados
      final syncedResult = await db.rawQuery(
        'SELECT COUNT(*) as synced FROM monitorings WHERE isSynced = 1'
      );
      final synced = syncedResult.first['synced'] as int;
      
      // Monitoramentos por talhão
      final byPlotResult = await db.rawQuery('''
        SELECT plot_id, COUNT(*) as count 
        FROM monitorings 
        GROUP BY plot_id
      ''');
      
      final Map<String, int> byPlot = {};
      for (var row in byPlotResult) {
        byPlot[row['plot_id'].toString()] = row['count'] as int;
      }
      
      return {
        'total': total,
        'completed': completed,
        'synced': synced,
        'by_plot': byPlot,
        'completion_rate': total > 0 ? (completed / total * 100).roundToDouble() : 0.0,
        'sync_rate': total > 0 ? (synced / total * 100).roundToDouble() : 0.0,
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Busca monitoramentos por texto
  Future<List<Monitoring>> search(String query) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'plotName LIKE ? OR cropName LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar monitoramentos: $e');
      return [];
    }
  }

  /// Obtém monitoramentos por período
  Future<List<Monitoring>> getByPeriod(DateTime start, DateTime end) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date DESC',
      );
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramentos por período: $e');
      return [];
    }
  }

  /// Obtém monitoramentos pendentes de sincronização
  Future<List<Monitoring>> getPendingSync() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'isSynced = 0',
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) {
        return Monitoring.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter monitoramentos pendentes: $e');
      return [];
    }
  }

  /// Atualiza status de sincronização
  Future<bool> updateSyncStatus(String id, int syncStatus, String? remoteId) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitorings',
        {
          'isSynced': syncStatus,
          'remote_id': remoteId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Status de sincronização atualizado: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar status de sincronização: $e');
      return false;
    }
  }
}
