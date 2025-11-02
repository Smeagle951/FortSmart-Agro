import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/variety.dart';
import '../utils/logger.dart';

class VarietyRepository {
  final AppDatabase _appDatabase = AppDatabase();
  final String tableName = 'varieties';

  Future<Database> get database async => await _appDatabase.database;

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cultura_id INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(Variety variety) async {
    final db = await database;
    return await db.insert(tableName, variety.toMap());
  }

  Future<int> update(Variety variety) async {
    final db = await database;
    return await db.update(
      tableName,
      variety.toMap(),
      where: 'id = ?',
      whereArgs: [variety.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Variety?> getById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Variety.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Variety>> getAll() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      return List.generate(maps.length, (i) => Variety.fromMap(maps[i]));
    } catch (e) {
      Logger.error('Erro ao obter variedades: $e');
      return [];
    }
  }

  Future<List<Variety>> getByCropId(String cropId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'crop_id = ?',
      whereArgs: [cropId],
    );
    return List.generate(maps.length, (i) => Variety.fromMap(maps[i]));
  }
  
  /// Método auxiliar que aceita tanto String quanto int como ID
  Future<Variety?> getVarietyById(dynamic id) async {
    if (id is int) {
      return await getById(id.toString());
    } else if (id is String) {
      int? numericId = int.tryParse(id);
      if (numericId != null) {
        return await getById(numericId.toString());
      }
    }
    return null;
  }
}
