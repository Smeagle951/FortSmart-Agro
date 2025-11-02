import '../models/experiment_model.dart';
import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class ExperimentRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'experimentos';

  Future<void> insert(ExperimentModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ExperimentModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'dateTime DESC');
    return maps.map((map) => ExperimentModel.fromMap(map)).toList();
  }

  Future<ExperimentModel?> getById(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ExperimentModel.fromMap(maps.first);
  }

  Future<void> delete(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
