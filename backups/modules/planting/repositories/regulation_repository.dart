import '../models/regulation_model.dart';
import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class RegulationRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'plantadeira_regulagem';

  Future<void> insert(RegulationModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RegulationModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'dateTime DESC');
    return maps.map((map) => RegulationModel.fromMap(map)).toList();
  }

  Future<RegulationModel?> getById(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return RegulationModel.fromMap(maps.first);
  }

  Future<void> delete(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
