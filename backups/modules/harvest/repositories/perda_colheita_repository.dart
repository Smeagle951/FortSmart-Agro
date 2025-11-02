// import 'package:sqflite/sqflite.dart'; // Não utilizado
import '../../../database/app_database.dart';
import '../models/perda_colheita_model.dart';

class PerdaColheitaRepository {
  static const String _tableName = 'perda_colheita';
  final AppDatabase _database = AppDatabase.instance;

  Future<List<PerdaColheitaModel>> getAll() async {
    final db = await _database.ensureDatabaseOpen();
    final perdas = await db.query(_tableName);
    return perdas.map((map) => PerdaColheitaModel.fromMap(map)).toList();
  }

  Future<List<PerdaColheitaModel>> getByFilters({
    int? talhaoId,
    int? culturaId,
    String? dataInicio,
    String? dataFim,
    String? metodo,
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
    
    if (metodo != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'metodo = ?';
      whereArgs.add(metodo);
    }
    
    if (dataInicio != null && dataFim != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data_perda BETWEEN ? AND ?';
      whereArgs.addAll([dataInicio, dataFim]);
    } else if (dataInicio != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data_perda >= ?';
      whereArgs.add(dataInicio);
    } else if (dataFim != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data_perda <= ?';
      whereArgs.add(dataFim);
    }
    
    final perdas = await db.query(
      _tableName,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'data_perda DESC',
    );
    
    return perdas.map((map) => PerdaColheitaModel.fromMap(map)).toList();
  }

  Future<PerdaColheitaModel?> getById(int id) async {
    final db = await _database.ensureDatabaseOpen();
    final perdas = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (perdas.isEmpty) return null;
    return PerdaColheitaModel.fromMap(perdas.first);
  }

  Future<int> insert(PerdaColheitaModel perda) async {
    final db = await _database.ensureDatabaseOpen();
    return await db.insert(_tableName, perda.toMap());
  }

  Future<int> update(PerdaColheitaModel perda) async {
    final db = await _database.ensureDatabaseOpen();
    return await db.update(
      _tableName,
      perda.toMap(),
      where: 'id = ?',
      whereArgs: [perda.id],
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
