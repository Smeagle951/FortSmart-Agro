import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/aplicacao_model.dart';

/// Repositório para gerenciar aplicações no banco de dados
class AplicacaoRepository {
  static const String _tableName = 'aplicacoes';

  /// Insere uma nova aplicação
  Future<void> insertAplicacao(AplicacaoModel aplicacao) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_tableName, aplicacao.toMap());
  }

  /// Atualiza uma aplicação existente
  Future<void> updateAplicacao(AplicacaoModel aplicacao) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      _tableName,
      aplicacao.toMap(),
      where: 'id = ?',
      whereArgs: [aplicacao.id],
    );
  }

  /// Remove uma aplicação
  Future<void> deleteAplicacao(String aplicacaoId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [aplicacaoId],
    );
  }

  /// Busca aplicações por subárea
  Future<List<AplicacaoModel>> getAplicacoesBySubareaId(String subareaId) async {
    final db = await DatabaseHelper.instance.database;
    
    final aplicacaoMaps = await db.query(
      _tableName,
      where: 'subarea_id = ?',
      whereArgs: [subareaId],
      orderBy: 'data_aplicacao DESC',
    );
    
    return aplicacaoMaps.map((map) => AplicacaoModel.fromMap(map)).toList();
  }

  /// Busca aplicação por ID
  Future<AplicacaoModel?> getAplicacaoById(String aplicacaoId) async {
    final db = await DatabaseHelper.instance.database;
    
    final aplicacaoMaps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [aplicacaoId],
    );
    
    if (aplicacaoMaps.isEmpty) return null;
    
    return AplicacaoModel.fromMap(aplicacaoMaps.first);
  }

  /// Busca todas as aplicações
  Future<List<AplicacaoModel>> getAllAplicacoes() async {
    final db = await DatabaseHelper.instance.database;
    
    final aplicacaoMaps = await db.query(
      _tableName,
      orderBy: 'data_aplicacao DESC',
    );
    
    return aplicacaoMaps.map((map) => AplicacaoModel.fromMap(map)).toList();
  }

  /// Busca aplicação por ID (alias para getAplicacaoById)
  Future<AplicacaoModel?> getById(int id) async {
    return getAplicacaoById(id.toString());
  }

  /// Remove uma aplicação (alias para deleteAplicacao)
  Future<void> delete(String id) async {
    return deleteAplicacao(id);
  }

  /// Busca todas as aplicações (alias para getAllAplicacoes)
  Future<List<AplicacaoModel>> getAll() async {
    return getAllAplicacoes();
  }

  /// Insere uma aplicação (alias para insertAplicacao)
  Future<void> insert(AplicacaoModel aplicacao) async {
    return insertAplicacao(aplicacao);
  }

  /// Atualiza uma aplicação (alias para updateAplicacao)
  Future<void> update(AplicacaoModel aplicacao) async {
    return updateAplicacao(aplicacao);
  }
}