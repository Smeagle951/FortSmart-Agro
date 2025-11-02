
import '../database/app_database.dart';
import '../models/monitoring_point.dart';

class MonitoringPointRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'monitoring_points';

  // Obter todos os pontos de monitoramento
  Future<List<MonitoringPoint>> getAllMonitoringPoints() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) => MonitoringPoint.fromMap(maps[i]));
  }

  // Obter pontos de monitoramento por monitoramento
  Future<List<MonitoringPoint>> getMonitoringPointsByMonitoring(int monitoringId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'monitoringId = ?',
      whereArgs: [monitoringId],
    );
    return List.generate(maps.length, (i) => MonitoringPoint.fromMap(maps[i]));
  }
  
  // Obter pontos de monitoramento por monitoringId (string)
  Future<List<MonitoringPoint>> getMonitoringPointsByMonitoringId(String monitoringId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'monitoringId = ?',
      whereArgs: [monitoringId],
    );
    return List.generate(maps.length, (i) => MonitoringPoint.fromMap(maps[i]));
  }

  // Obter pontos de monitoramento por talhão
  Future<List<MonitoringPoint>> getMonitoringPointsByPlot(int plotId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'plotId = ?',
      whereArgs: [plotId],
    );
    return List.generate(maps.length, (i) => MonitoringPoint.fromMap(maps[i]));
  }

  // Obter um ponto de monitoramento pelo ID
  Future<MonitoringPoint?> getMonitoringPointById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return MonitoringPoint.fromMap(maps.first);
    }
    return null;
  }

  // Salvar um ponto de monitoramento (inserir ou atualizar)
  Future<String> saveMonitoringPoint(MonitoringPoint point) async {
    final db = await _database.database;
    
    if (point.id != null) {
      // Atualizar ponto existente
      await db.update(
        table,
        point.toMap(),
        where: 'id = ?',
        whereArgs: [point.id],
      );
      return point.id;
    } else {
      // Inserir novo ponto
      await db.insert(table, point.toMap());
      return point.id;
    }
  }
  
  // Inserir um novo ponto de monitoramento
  Future<String> insertMonitoringPoint(MonitoringPoint point) async {
    final db = await _database.database;
    await db.insert(table, point.toMap());
    return point.id;
  }
  
  // Atualizar um ponto de monitoramento existente
  Future<bool> updateMonitoringPoint(MonitoringPoint point) async {
    // O id nunca será nulo pois é definido como não nulo na classe MonitoringPoint
    final db = await _database.database;
    final result = await db.update(
      table,
      point.toMap(),
      where: 'id = ?',
      whereArgs: [point.id],
    );
    return result > 0;
  }

  // Excluir um ponto de monitoramento
  Future<bool> deleteMonitoringPoint(int id) async {
    final db = await _database.database;
    final result = await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // Marcar pontos como sincronizados
  Future<void> markAsSynced(List<int> ids) async {
    final db = await _database.database;
    final batch = db.batch();
    
    for (final id in ids) {
      batch.update(
        table,
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    await batch.commit();
  }

  // Obter pontos não sincronizados
  Future<List<MonitoringPoint>> getUnsyncedPoints() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => MonitoringPoint.fromMap(maps[i]));
  }
}
