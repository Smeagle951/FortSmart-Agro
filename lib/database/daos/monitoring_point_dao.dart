import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/monitoring_point.dart';
import '../../utils/logger.dart';

/// DAO para operações de pontos de monitoramento no banco de dados
class MonitoringPointDao {
  final AppDatabase _database = AppDatabase();
  static const String _tag = 'MonitoringPointDao';

  /// Obtém todos os pontos de monitoramento
  Future<List<MonitoringPoint>> getAll() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('monitoring_points');
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter todos os pontos: $e');
      return [];
    }
  }

  /// Obtém ponto de monitoramento por ID
  Future<MonitoringPoint?> getById(String id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return MonitoringPoint.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('$_tag: Erro ao obter ponto por ID: $e');
      return null;
    }
  }

  /// Obtém pontos por ID do monitoramento
  Future<List<MonitoringPoint>> getByMonitoringId(String monitoringId) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'monitoringId = ?',
        whereArgs: [monitoringId],
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos por monitoramento: $e');
      return [];
    }
  }

  /// Obtém pontos por talhão
  Future<List<MonitoringPoint>> getByPlotId(int plotId) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'plotId = ?',
        whereArgs: [plotId],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos por talhão: $e');
      return [];
    }
  }

  /// Obtém pontos não sincronizados
  Future<List<MonitoringPoint>> getUnsynced() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'isSynced = 0',
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos não sincronizados: $e');
      return [];
    }
  }

  /// Obtém pontos recentes
  Future<List<MonitoringPoint>> getRecent({int limit = 20}) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos recentes: $e');
      return [];
    }
  }

  /// Insere um ponto de monitoramento
  Future<bool> insert(MonitoringPoint point) async {
    try {
      final db = await _database.database;
      await db.insert(
        'monitoring_points',
        point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('$_tag: Ponto inserido com sucesso: ${point.id}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao inserir ponto: $e');
      return false;
    }
  }

  /// Atualiza um ponto de monitoramento
  Future<bool> update(MonitoringPoint point) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitoring_points',
        point.toMap(),
        where: 'id = ?',
        whereArgs: [point.id],
      );
      
      Logger.info('$_tag: Ponto atualizado com sucesso: ${point.id}');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao atualizar ponto: $e');
      return false;
    }
  }

  /// Remove um ponto de monitoramento
  Future<bool> delete(String id) async {
    try {
      final db = await _database.database;
      await db.delete(
        'monitoring_points',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Ponto removido com sucesso: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao remover ponto: $e');
      return false;
    }
  }

  /// Marca ponto como sincronizado
  Future<bool> markAsSynced(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitoring_points',
        {
          'isSynced': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('$_tag: Ponto marcado como sincronizado: $id');
      return true;
    } catch (e) {
      Logger.error('$_tag: Erro ao marcar ponto como sincronizado: $e');
      return false;
    }
  }

  /// Obtém pontos por coordenadas (proximidade)
  Future<List<MonitoringPoint>> getByLocation(double lat, double lng, double radiusKm) async {
    try {
      final db = await _database.database;
      
      // Fórmula de Haversine para calcular distância
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT *, 
        (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
        cos(radians(longitude) - radians(?)) + sin(radians(?)) * 
        sin(radians(latitude)))) AS distance
        FROM monitoring_points 
        HAVING distance <= ?
        ORDER BY distance ASC
      ''', [lat, lng, lat, radiusKm]);
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos por localização: $e');
      return [];
    }
  }

  /// Obtém estatísticas de pontos
  Future<Map<String, dynamic>> getStats() async {
    try {
      final db = await _database.database;
      
      // Total de pontos
      final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM monitoring_points');
      final total = totalResult.first['total'] as int;
      
      // Pontos sincronizados
      final syncedResult = await db.rawQuery(
        'SELECT COUNT(*) as synced FROM monitoring_points WHERE isSynced = 1'
      );
      final synced = syncedResult.first['synced'] as int;
      
      // Pontos com GPS preciso
      final accurateGpsResult = await db.rawQuery('''
        SELECT COUNT(*) as accurate FROM monitoring_points 
        WHERE gpsAccuracy IS NULL OR gpsAccuracy <= 5.0
      ''');
      final accurateGps = accurateGpsResult.first['accurate'] as int;
      
      // Pontos por talhão
      final byPlotResult = await db.rawQuery('''
        SELECT plotId, COUNT(*) as count 
        FROM monitoring_points 
        GROUP BY plotId
      ''');
      
      final Map<String, int> byPlot = {};
      for (var row in byPlotResult) {
        byPlot[row['plotId'].toString()] = row['count'] as int;
      }
      
      // Pontos por período (últimos 30 dias)
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final recentResult = await db.rawQuery('''
        SELECT COUNT(*) as recent FROM monitoring_points 
        WHERE created_at >= ?
      ''', [thirtyDaysAgo.toIso8601String()]);
      final recent = recentResult.first['recent'] as int;
      
      return {
        'total': total,
        'synced': synced,
        'accurate_gps': accurateGps,
        'recent_30_days': recent,
        'by_plot': byPlot,
        'sync_rate': total > 0 ? (synced / total * 100).roundToDouble() : 0.0,
        'gps_accuracy_rate': total > 0 ? (accurateGps / total * 100).roundToDouble() : 0.0,
      };
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas: $e');
      return {};
    }
  }

  /// Busca pontos por texto
  Future<List<MonitoringPoint>> search(String query) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'plotName LIKE ? OR cropName LIKE ? OR observations LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar pontos: $e');
      return [];
    }
  }

  /// Obtém pontos por período
  Future<List<MonitoringPoint>> getByPeriod(DateTime start, DateTime end) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'created_at BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos por período: $e');
      return [];
    }
  }

  /// Obtém pontos com ocorrências
  Future<List<MonitoringPoint>> getWithOccurrences() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT mp.* FROM monitoring_points mp
        INNER JOIN monitoring_occurrences mo ON mp.id = mo.monitoring_point_id
        GROUP BY mp.id
        ORDER BY mp.created_at DESC
      ''');
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos com ocorrências: $e');
      return [];
    }
  }

  /// Obtém pontos pendentes de sincronização
  Future<List<MonitoringPoint>> getPendingSync() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'monitoring_points',
        where: 'isSynced = 0',
        orderBy: 'created_at ASC',
      );
      
      return List.generate(maps.length, (i) {
        return MonitoringPoint.fromMap(maps[i]);
      });
    } catch (e) {
      Logger.error('$_tag: Erro ao obter pontos pendentes: $e');
      return [];
    }
  }

  /// Atualiza status de sincronização
  Future<bool> updateSyncStatus(String id, int syncStatus, String? remoteId) async {
    try {
      final db = await _database.database;
      await db.update(
        'monitoring_points',
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
