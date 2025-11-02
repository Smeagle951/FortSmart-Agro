// import 'package:sqflite/sqflite.dart'; // Não utilizado
import '../../../database/app_database.dart';
import '../models/colheita_model.dart';

class ColheitaRepository {
  static const String _tableName = 'colheita';
  final AppDatabase _database = AppDatabase.instance;

  Future<List<ColheitaModel>> getAll() async {
    final db = await _database.ensureDatabaseOpen();
    final colheitas = await db.query(_tableName);
    return colheitas.map((map) => ColheitaModel.fromMap(map)).toList();
  }

  Future<List<ColheitaModel>> getByFilters({
    int? talhaoId,
    int? culturaId,
    String? dataInicio,
    String? dataFim,
  }) async {
    final db = await _database.ensureDatabaseOpen();
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (talhaoId != null) {
      whereClause += 'talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    if (culturaId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'cultura_id = ?';
      whereArgs.add(culturaId);
    }
    
    if (dataInicio != null && dataFim != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data_colheita BETWEEN ? AND ?';
      whereArgs.addAll([dataInicio, dataFim]);
    } else if (dataInicio != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data_colheita >= ?';
      whereArgs.add(dataInicio);
    } else if (dataFim != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data_colheita <= ?';
      whereArgs.add(dataFim);
    }
    
    final colheitas = await db.query(
      _tableName,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'data_colheita DESC',
    );
    
    return colheitas.map((map) => ColheitaModel.fromMap(map)).toList();
  }

  Future<ColheitaModel?> getById(int id) async {
    final db = await _database.ensureDatabaseOpen();
    final colheitas = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (colheitas.isEmpty) return null;
    return ColheitaModel.fromMap(colheitas.first);
  }

  Future<int> insert(ColheitaModel colheita) async {
    final db = await _database.ensureDatabaseOpen();
    return await db.insert(_tableName, colheita.toMap());
  }

  Future<int> update(ColheitaModel colheita) async {
    final db = await _database.ensureDatabaseOpen();
    return await db.update(
      _tableName,
      colheita.toMap(),
      where: 'id = ?',
      whereArgs: [colheita.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _database.ensureDatabaseOpen();
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
