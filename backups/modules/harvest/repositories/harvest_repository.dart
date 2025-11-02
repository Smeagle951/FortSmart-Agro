import '../models/harvest_model.dart';
import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class HarvestRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'colheita';

  Future<void> insert(HarvestModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HarvestModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'dateTime DESC');
    return maps.map((map) => HarvestModel.fromMap(map)).toList();
  }

  Future<HarvestModel?> getById(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return HarvestModel.fromMap(maps.first);
  }

  Future<void> delete(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HarvestModel>> getUnsynced() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, where: 'isSynced = 0');
    return maps.map((map) => HarvestModel.fromMap(map)).toList();
  }
}
