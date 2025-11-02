import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../base_repository.dart';
import '../../models/aplicacao.dart';
import '../../utils/logger.dart';

class AplicacaoDao extends BaseRepository<Aplicacao> {
  static const String _tableName = 'aplicacoes';
  
  AplicacaoDao() : super(_tableName);
  
  @override
  String get entityName => 'Aplicacao';
  
  @override
  Aplicacao fromMap(Map<String, dynamic> map) {
    return Aplicacao.fromMap(map);
  }
  
  @override
  Map<String, dynamic> toMap(Aplicacao entity) {
    return entity.toMap();
  }
  
  @override
  String? getId(Aplicacao entity) {
    return entity.id;
  }

  /// Obtém a instância do banco de dados
  Future<Database> _getDatabase() async {
    return await database;
  }

  /// Cria a tabela de aplicações se não existir
  Future<void> _createTableIfNotExists(Database db) async {
    const createTableSQL = '''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id_aplicacao TEXT PRIMARY KEY,
        id_talhao TEXT NOT NULL,
        id_produto TEXT NOT NULL,
        dose_por_ha REAL NOT NULL,
        area_aplicada_ha REAL NOT NULL,
        preco_unitario_momento REAL NOT NULL,
        data_aplicacao TEXT NOT NULL,
        operador TEXT,
        equipamento TEXT,
        condicoes_climaticas TEXT,
        observacoes TEXT,
        fazenda_id TEXT,
        data_criacao TEXT NOT NULL,
        data_atualizacao TEXT NOT NULL,
        is_sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''';

    await db.execute(createTableSQL);
  }

  /// Insere uma nova aplicação
  Future<String> insert(Aplicacao aplicacao) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      await db.insert(
        _tableName,
        aplicacao.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('✅ Aplicação inserida: ${aplicacao.id}');
      return aplicacao.id;
    } catch (e) {
      Logger.error('❌ Erro ao inserir aplicação: $e');
      rethrow;
    }
  }

  /// Atualiza uma aplicação existente
  Future<bool> update(Aplicacao aplicacao) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final result = await db.update(
        _tableName,
        aplicacao.toMap(),
        where: 'id_aplicacao = ?',
        whereArgs: [aplicacao.id],
      );

      Logger.info('✅ Aplicação atualizada: ${aplicacao.id}');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar aplicação: $e');
      rethrow;
    }
  }

  /// Remove uma aplicação
  Future<bool> delete(String id) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final result = await db.delete(
        _tableName,
        where: 'id_aplicacao = ?',
        whereArgs: [id],
      );

      Logger.info('✅ Aplicação removida: $id');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao remover aplicação: $e');
      rethrow;
    }
  }

  /// Busca uma aplicação pelo ID
  Future<Aplicacao?> getById(String id) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id_aplicacao = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Aplicacao.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicação por ID: $e');
      return null;
    }
  }

  /// Busca todas as aplicações
  Future<List<Aplicacao>> buscarTodas() async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'data_aplicacao DESC',
      );

      return maps.map((map) => Aplicacao.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar todas as aplicações: $e');
      return [];
    }
  }

  /// Busca aplicações por talhão
  Future<List<Aplicacao>> buscarPorTalhao(String talhaoId) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id_talhao = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_aplicacao DESC',
      );

      return maps.map((map) => Aplicacao.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações por talhão: $e');
      return [];
    }
  }

  /// Busca aplicações por período
  Future<List<Aplicacao>> buscarPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoId,
  }) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      String whereClause = 'data_aplicacao >= ? AND data_aplicacao <= ?';
      List<dynamic> whereArgs = [
        dataInicio.toIso8601String(),
        dataFim.toIso8601String(),
      ];

      if (talhaoId != null) {
        whereClause += ' AND id_talhao = ?';
        whereArgs.add(talhaoId);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_aplicacao DESC',
      );

      return maps.map((map) => Aplicacao.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações por período: $e');
      return [];
    }
  }

  /// Busca aplicações por produto
  Future<List<Aplicacao>> buscarPorProduto(String produtoId) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id_produto = ?',
        whereArgs: [produtoId],
        orderBy: 'data_aplicacao DESC',
      );

      return maps.map((map) => Aplicacao.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações por produto: $e');
      return [];
    }
  }

  /// Busca aplicações por fazenda
  Future<List<Aplicacao>> buscarPorFazenda(String fazendaId) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'fazenda_id = ?',
        whereArgs: [fazendaId],
        orderBy: 'data_aplicacao DESC',
      );

      return maps.map((map) => Aplicacao.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar aplicações por fazenda: $e');
      return [];
    }
  }

  /// Calcula o custo total de aplicações por período
  Future<double> calcularCustoTotalPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? talhaoId,
  }) async {
    try {
      final aplicacoes = await buscarPorPeriodo(
        dataInicio: dataInicio,
        dataFim: dataFim,
        talhaoId: talhaoId,
      );

      return aplicacoes.fold<double>(0.0, (total, aplicacao) => total + aplicacao.custoTotal);
    } catch (e) {
      Logger.error('❌ Erro ao calcular custo total por período: $e');
      return 0.0;
    }
  }

  /// Calcula o custo total de aplicações por talhão
  Future<double> calcularCustoTotalPorTalhao(String talhaoId) async {
    try {
      final aplicacoes = await buscarPorTalhao(talhaoId);
      return aplicacoes.fold<double>(0.0, (total, aplicacao) => total + aplicacao.custoTotal);
    } catch (e) {
      Logger.error('❌ Erro ao calcular custo total por talhão: $e');
      return 0.0;
    }
  }

  /// Obtém estatísticas de aplicações
  Future<Map<String, dynamic>> obterEstatisticas({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? talhaoId,
  }) async {
    try {
      final aplicacoes = await buscarPorPeriodo(
        dataInicio: dataInicio ?? DateTime.now().subtract(Duration(days: 30)),
        dataFim: dataFim ?? DateTime.now(),
        talhaoId: talhaoId,
      );

      if (aplicacoes.isEmpty) {
        return {
          'totalAplicacoes': 0,
          'custoTotal': 0.0,
          'areaTotal': 0.0,
          'custoMedioPorHa': 0.0,
          'produtosUtilizados': 0,
        };
      }

      final custoTotal = aplicacoes.fold<double>(0.0, (total, aplicacao) => total + aplicacao.custoTotal);
      final areaTotal = aplicacoes.fold<double>(0.0, (total, aplicacao) => total + aplicacao.areaAplicadaHa);
      final produtosUtilizados = aplicacoes.map((a) => a.produtoId).toSet().length;

      return {
        'totalAplicacoes': aplicacoes.length,
        'custoTotal': custoTotal,
        'areaTotal': areaTotal,
        'custoMedioPorHa': areaTotal > 0 ? custoTotal / areaTotal : 0.0,
        'produtosUtilizados': produtosUtilizados,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {
        'totalAplicacoes': 0,
        'custoTotal': 0.0,
        'areaTotal': 0.0,
        'custoMedioPorHa': 0.0,
        'produtosUtilizados': 0,
      };
    }
  }
}
