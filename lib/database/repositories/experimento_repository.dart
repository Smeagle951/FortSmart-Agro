import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/experimento_model.dart';

/// Repositório para gerenciar experimentos no banco de dados
class ExperimentoRepository {
  static const String _tableName = 'experimentos';

  /// Cria a tabela de experimentos se não existir
  Future<void> _createTableIfNotExists() async {
    final db = await DatabaseHelper.instance.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT NOT NULL,
        objetivo TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        data_inicio INTEGER NOT NULL,
        data_fim INTEGER,
        status TEXT NOT NULL,
        delineamento TEXT NOT NULL,
        numero_repeticoes INTEGER NOT NULL,
        numero_tratamentos INTEGER NOT NULL,
        cultura TEXT NOT NULL,
        variedade TEXT NOT NULL,
        responsavel_tecnico TEXT NOT NULL,
        crm_responsavel TEXT NOT NULL,
        instituicao TEXT NOT NULL,
        protocolo TEXT NOT NULL,
        variaveis_resposta TEXT NOT NULL,
        variaveis_ambientais TEXT NOT NULL,
        observacoes TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Insere um novo experimento
  Future<void> insertExperimento(ExperimentoModel experimento) async {
    await _createTableIfNotExists();
    final db = await DatabaseHelper.instance.database;
    await db.insert(_tableName, experimento.toMap());
  }

  /// Atualiza um experimento existente
  Future<void> updateExperimento(ExperimentoModel experimento) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tableName,
      experimento.toMap(),
      where: 'id = ?',
      whereArgs: [experimento.id],
    );
  }

  /// Remove um experimento
  Future<void> deleteExperimento(String experimentoId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [experimentoId],
    );
  }

  /// Busca experimento por ID
  Future<ExperimentoModel?> getExperimentoById(String experimentoId) async {
    final db = await DatabaseHelper.instance.database;
    
    final experimentoMaps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [experimentoId],
    );
    
    if (experimentoMaps.isEmpty) return null;
    
    return ExperimentoModel.fromMap(experimentoMaps.first);
  }

  /// Busca experimentos por talhão
  Future<List<ExperimentoModel>> getExperimentosByTalhaoId(String talhaoId) async {
    final db = await DatabaseHelper.instance.database;
    
    final experimentoMaps = await db.query(
      _tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'data_inicio DESC',
    );
    
    return experimentoMaps.map((map) => ExperimentoModel.fromMap(map)).toList();
  }

  /// Busca todos os experimentos
  Future<List<ExperimentoModel>> getAllExperimentos() async {
    final db = await DatabaseHelper.instance.database;
    
    final experimentoMaps = await db.query(
      _tableName,
      orderBy: 'data_inicio DESC',
    );
    
    return experimentoMaps.map((map) => ExperimentoModel.fromMap(map)).toList();
  }

  /// Busca experimentos ativos
  Future<List<ExperimentoModel>> getExperimentosAtivos() async {
    final db = await DatabaseHelper.instance.database;
    
    final experimentoMaps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: ['em_andamento'],
      orderBy: 'data_inicio DESC',
    );
    
    return experimentoMaps.map((map) => ExperimentoModel.fromMap(map)).toList();
  }

  /// Busca experimentos por status
  Future<List<ExperimentoModel>> getExperimentosByStatus(String status) async {
    final db = await DatabaseHelper.instance.database;
    
    final experimentoMaps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'data_inicio DESC',
    );
    
    return experimentoMaps.map((map) => ExperimentoModel.fromMap(map)).toList();
  }

  /// Busca experimentos por cultura
  Future<List<ExperimentoModel>> getExperimentosByCultura(String cultura) async {
    final db = await DatabaseHelper.instance.database;
    
    final experimentoMaps = await db.query(
      _tableName,
      where: 'cultura = ?',
      whereArgs: [cultura],
      orderBy: 'data_inicio DESC',
    );
    
    return experimentoMaps.map((map) => ExperimentoModel.fromMap(map)).toList();
  }

  /// Conta o total de experimentos
  Future<int> getTotalExperimentos() async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Conta experimentos por status
  Future<Map<String, int>> getContagemPorStatus() async {
    final db = await DatabaseHelper.instance.database;
    
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY status
    ''');
    
    final Map<String, int> contagem = {};
    for (final row in result) {
      contagem[row['status'] as String] = row['count'] as int;
    }
    
    return contagem;
  }

  /// Alias para compatibilidade com telas existentes
  Future<void> insert(ExperimentoModel experimento) async {
    return insertExperimento(experimento);
  }

  Future<void> update(ExperimentoModel experimento) async {
    return updateExperimento(experimento);
  }

  Future<void> delete(String id) async {
    return deleteExperimento(id);
  }

  Future<ExperimentoModel?> getById(String id) async {
    return getExperimentoById(id);
  }

  Future<List<ExperimentoModel>> getAll() async {
    return getAllExperimentos();
  }
}
