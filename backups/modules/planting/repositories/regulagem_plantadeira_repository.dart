import 'package:sqflite/sqflite.dart';
import '../models/regulagem_plantadeira_model.dart';
import '../../../database/app_database.dart';

class RegulagemPlantadeiraRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'regulagem_plantadeira';

  Future<void> insert(RegulagemPlantadeiraModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(RegulagemPlantadeiraModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.update(
      table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<List<RegulagemPlantadeiraModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'data_regulagem DESC');
    return List.generate(maps.length, (i) {
      return RegulagemPlantadeiraModel.fromMap(maps[i]);
    });
  }

  Future<List<RegulagemPlantadeiraModel>> getByFilters({int? culturaId, int? variedadeId, String? dataRegulagem, String? disco}) async {
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
    
    if (dataRegulagem != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += "date(data_regulagem) = date(?)";
      whereArgs.add(dataRegulagem);
    }
    
    if (disco != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'disco LIKE ?';
      whereArgs.add('%$disco%');
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data_regulagem DESC',
    );
    
    return List.generate(maps.length, (i) {
      return RegulagemPlantadeiraModel.fromMap(maps[i]);
    });
  }

  Future<RegulagemPlantadeiraModel?> getById(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return RegulagemPlantadeiraModel.fromMap(maps.first);
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
