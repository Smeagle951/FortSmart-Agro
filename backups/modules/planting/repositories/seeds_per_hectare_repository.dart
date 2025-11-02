import '../models/seeds_per_hectare_model.dart';
import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SeedsPerHectareRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'sementes_por_hectare';

  Future<void> insert(SeedsPerHectareModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SeedsPerHectareModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'dateTime DESC');
    return maps.map((map) => SeedsPerHectareModel.fromMap(map)).toList();
  }

  Future<SeedsPerHectareModel?> getById(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SeedsPerHectareModel.fromMap(maps.first);
  }

  Future<void> delete(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
