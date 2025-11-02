import '../models/stand_model.dart';
import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class StandRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'estande_plantio';

  Future<void> insert(StandModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StandModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'dateTime DESC');
    return maps.map((map) => StandModel.fromMap(map)).toList();
  }

  Future<StandModel?> getById(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return StandModel.fromMap(maps.first);
  }

  Future<void> delete(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
