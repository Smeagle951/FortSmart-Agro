import 'package:sqflite/sqflite.dart';
import '../models/plantio_model.dart';
import '../../../database/app_database.dart';

class PlantioRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'plantio';

  Future<void> insert(PlantioModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(PlantioModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.update(
      table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<List<PlantioModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'data_plantio DESC');
    return List.generate(maps.length, (i) {
      return PlantioModel.fromMap(maps[i]);
    });
  }

  Future<List<PlantioModel>> getByFilters({int? talhaoId, int? culturaId, int? ano, int? tratorId, int? plantadeiraId}) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (talhaoId != null) {
      whereClause += 'talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    if (culturaId != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'cultura_id = ?';
      whereArgs.add(culturaId);
    }
    
    if (ano != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      // Filtrar por ano da data de plantio
      whereClause += "strftime('%Y', data_plantio) = ?";
      whereArgs.add(ano.toString());
    }
    
    if (tratorId != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'trator_id = ?';
      whereArgs.add(tratorId);
    }
    
    if (plantadeiraId != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'plantadeira_id = ?';
      whereArgs.add(plantadeiraId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data_plantio DESC',
    );
    
    return List.generate(maps.length, (i) {
      return PlantioModel.fromMap(maps[i]);
    });
  }

  Future<PlantioModel?> getById(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return PlantioModel.fromMap(maps.first);
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
