import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/colheita_model.dart';

/// Repositório para gerenciar colheitas no banco de dados
class ColheitaRepository {
  static const String _tableName = 'colheitas';

  /// Cria a tabela se não existir
  Future<void> _createTableIfNotExists() async {
    final db = await DatabaseHelper.instance.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        subarea_id TEXT NOT NULL,
        experimento_id TEXT NOT NULL,
        data_colheita INTEGER NOT NULL,
        tipo_colheita TEXT NOT NULL,
        area_colhida REAL NOT NULL,
        producao_total REAL NOT NULL,
        unidade_producao TEXT NOT NULL,
        produtividade REAL NOT NULL,
        unidade_produtividade TEXT NOT NULL,
        qualidade TEXT NOT NULL,
        umidade REAL NOT NULL,
        impurezas REAL NOT NULL,
        danos REAL NOT NULL,
        equipamento TEXT NOT NULL,
        observacoes TEXT NOT NULL,
        responsavel_colheita TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Insere uma nova colheita
  Future<void> insertColheita(ColheitaModel colheita) async {
    await _createTableIfNotExists();
    final db = await DatabaseHelper.instance.database;
    await db.insert(_tableName, colheita.toMap());
  }

  /// Atualiza uma colheita existente
  Future<void> updateColheita(ColheitaModel colheita) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tableName,
      colheita.toMap(),
      where: 'id = ?',
      whereArgs: [colheita.id],
    );
  }

  /// Remove uma colheita
  Future<void> deleteColheita(String colheitaId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [colheitaId],
    );
  }

  /// Busca colheitas por subárea
  Future<List<ColheitaModel>> getColheitasBySubareaId(String subareaId) async {
    final db = await DatabaseHelper.instance.database;
    
    final colheitaMaps = await db.query(
      _tableName,
      where: 'subarea_id = ?',
      whereArgs: [subareaId],
      orderBy: 'data_colheita DESC',
    );
    
    return colheitaMaps.map((map) => ColheitaModel.fromMap(map)).toList();
  }

  /// Busca colheita por ID
  Future<ColheitaModel?> getColheitaById(String colheitaId) async {
    final db = await DatabaseHelper.instance.database;
    
    final colheitaMaps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [colheitaId],
    );
    
    if (colheitaMaps.isEmpty) return null;
    
    return ColheitaModel.fromMap(colheitaMaps.first);
  }

  /// Busca todas as colheitas
  Future<List<ColheitaModel>> getAllColheitas() async {
    final db = await DatabaseHelper.instance.database;
    
    final colheitaMaps = await db.query(
      _tableName,
      orderBy: 'data_colheita DESC',
    );
    
    return colheitaMaps.map((map) => ColheitaModel.fromMap(map)).toList();
  }

  /// Alias para compatibilidade com telas existentes
  Future<void> insert(ColheitaModel colheita) async {
    return insertColheita(colheita);
  }

  Future<void> update(ColheitaModel colheita) async {
    return updateColheita(colheita);
  }

  Future<void> delete(String id) async {
    return deleteColheita(id);
  }

  Future<ColheitaModel?> getById(String id) async {
    return getColheitaById(id);
  }

  Future<List<ColheitaModel>> getAll() async {
    return getAllColheitas();
  }
}
