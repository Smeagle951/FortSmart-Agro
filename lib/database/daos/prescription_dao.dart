import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/prescription.dart';

class PrescriptionDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'prescriptions';

  // Inserir uma nova prescrição
  Future<int> insert(Prescription prescription) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      prescription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar uma prescrição existente
  Future<int> update(Prescription prescription) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      prescription.toMap(),
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  // Excluir uma prescrição
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter uma prescrição pelo ID
  Future<Prescription?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Prescription.fromMap(maps.first);
    }
    return null;
  }

  // Obter todas as prescrições para um talhão específico
  Future<List<Prescription>> getByPlotId(int plotId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'plot_id = ?',
      whereArgs: [plotId],
      orderBy: 'prescription_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription.fromMap(maps[i]);
    });
  }

  // Obter todas as prescrições
  Future<List<Prescription>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'prescription_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription.fromMap(maps[i]);
    });
  }

  // Obter prescrições por período
  Future<List<Prescription>> getByDateRange(String startDate, String endDate) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'prescription_date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'prescription_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription.fromMap(maps[i]);
    });
  }

  // Obter prescrições por status
  Future<List<Prescription>> getByStatus(String status) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'prescription_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription.fromMap(maps[i]);
    });
  }
  
  // Obter prescrições por análise de solo
  Future<List<Prescription>> getBySoilAnalysisId(int soilAnalysisId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'soil_analysis_id = ?',
      whereArgs: [soilAnalysisId],
      orderBy: 'prescription_date DESC',
    );

    return List.generate(maps.length, (i) {
      return Prescription.fromMap(maps[i]);
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

  // Obter prescrições não sincronizadas
  Future<List<Prescription>> getUnsyncedPrescriptions() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return Prescription.fromMap(maps[i]);
    });
  }
}
