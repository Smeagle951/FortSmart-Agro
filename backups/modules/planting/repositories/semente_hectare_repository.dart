import 'package:sqflite/sqflite.dart';
import '../models/semente_hectare_model.dart';
import '../../../database/app_database.dart';

class SementeHectareRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'semente_hectare';

  Future<void> insert(SementeHectareModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(SementeHectareModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.update(
      table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<List<SementeHectareModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'data_calculo DESC');
    return List.generate(maps.length, (i) {
      return SementeHectareModel.fromMap(maps[i]);
    });
  }

  Future<List<SementeHectareModel>> getByFilters({int? culturaId, int? variedadeId, String? dataCalculo}) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (culturaId != null) {
      whereClause += 'cultura_id = ?';
      whereArgs.add(culturaId);
    }
    
    if (variedadeId != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'variedade_id = ?';
      whereArgs.add(variedadeId);
    }
    
    if (dataCalculo != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += "date(data_calculo) = date(?)";
      whereArgs.add(dataCalculo);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data_calculo DESC',
    );
    
    return List.generate(maps.length, (i) {
      return SementeHectareModel.fromMap(maps[i]);
    });
  }

  Future<SementeHectareModel?> getById(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return SementeHectareModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> delete(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
