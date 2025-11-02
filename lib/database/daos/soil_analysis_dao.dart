import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/soil_analysis.dart';

class SoilAnalysisDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'soil_analyses';

  // Inserir uma nova análise de solo
  Future<int> insert(SoilAnalysis analysis) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      analysis.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar uma análise de solo existente
  Future<int> update(SoilAnalysis analysis) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      analysis.toMap(),
      where: 'id = ?',
      whereArgs: [analysis.id],
    );
  }

  // Excluir uma análise de solo
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter uma análise de solo pelo ID
  Future<SoilAnalysis?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SoilAnalysis.fromMap(maps.first);
    }
    return null;
  }

  // Obter todas as análises de solo para um monitoramento específico
  Future<List<SoilAnalysis>> getByMonitoringId(int monitoringId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'monitoring_id = ?',
      whereArgs: [monitoringId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return SoilAnalysis.fromMap(maps[i]);
    });
  }

  // Obter todas as análises de solo
  Future<List<SoilAnalysis>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return SoilAnalysis.fromMap(maps[i]);
    });
  }

  // Obter análises de solo por período
  Future<List<SoilAnalysis>> getByDateRange(String startDate, String endDate) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return SoilAnalysis.fromMap(maps[i]);
    });
  }
  
  // Obter análises de solo pendentes de sincronização
  Future<List<SoilAnalysis>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status != 1',
    );
    
    return List.generate(maps.length, (i) {
      return SoilAnalysis.fromMap(maps[i]);
    });
  }

  // Atualizar status de sincronização
  Future<int> updateSyncStatus(int id, int syncStatus, {int? remoteId}) async {
    final db = await _database.database;
    final Map<String, dynamic> values = {
      'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
    };
    
    return await db.update(
      _tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter análises de solo não sincronizadas
  Future<List<SoilAnalysis>> getUnsyncedSoilAnalyses() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return SoilAnalysis.fromMap(maps[i]);
    });
  }
}
