import 'package:sqflite/sqflite.dart';
import '../models/estande_model.dart';
import '../../../database/app_database.dart';

class EstandeRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'estande_plantas';

  Future<void> insert(EstandeModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(EstandeModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.update(
      table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<List<EstandeModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'data_avaliacao DESC');
    return List.generate(maps.length, (i) {
      return EstandeModel.fromMap(maps[i]);
    });
  }

  Future<List<EstandeModel>> getByFilters({int? talhaoId, int? culturaId, int? variedadeId, String? dataAvaliacao}) async {
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
    
    if (variedadeId != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'variedade_id = ?';
      whereArgs.add(variedadeId);
    }
    
    if (dataAvaliacao != null) {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += "date(data_avaliacao) = date(?)";
      whereArgs.add(dataAvaliacao);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'data_avaliacao DESC',
    );
    
    return List.generate(maps.length, (i) {
      return EstandeModel.fromMap(maps[i]);
    });
  }

  Future<EstandeModel?> getById(int id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return EstandeModel.fromMap(maps.first);
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
