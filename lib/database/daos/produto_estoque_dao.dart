import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../base_repository.dart';
import '../../models/produto_estoque.dart';
import '../../utils/logger.dart';

class ProdutoEstoqueDao extends BaseRepository<ProdutoEstoque> {
  static const String _tableName = 'produtos_estoque';
  
  ProdutoEstoqueDao() : super(_tableName);
  
  @override
  String get entityName => 'ProdutoEstoque';
  
  @override
  ProdutoEstoque fromMap(Map<String, dynamic> map) {
    return ProdutoEstoque.fromMap(map);
  }
  
  @override
  Map<String, dynamic> toMap(ProdutoEstoque entity) {
    return entity.toMap();
  }
  
  @override
  String? getId(ProdutoEstoque entity) {
    return entity.id;
  }

  /// Obtém a instância do banco de dados
  Future<Database> _getDatabase() async {
    return await database;
  }

  /// Cria a tabela de produtos de estoque se não existir
  Future<void> _createTableIfNotExists(Database db) async {
    const createTableSQL = '''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id_produto TEXT PRIMARY KEY,
        nome_produto TEXT NOT NULL,
        tipo_produto TEXT NOT NULL,
        unidade TEXT NOT NULL,
        preco_unitario REAL NOT NULL,
        saldo_atual REAL NOT NULL DEFAULT 0,
        fornecedor TEXT,
        numero_lote TEXT,
        local_armazenagem TEXT,
        data_validade TEXT,
        observacoes TEXT,
        fazenda_id TEXT,
        data_criacao TEXT NOT NULL,
        data_atualizacao TEXT NOT NULL,
        is_sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''';

    await db.execute(createTableSQL);
  }

  /// Insere um novo produto de estoque
  Future<String> insert(ProdutoEstoque produto) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      await db.insert(
        _tableName,
        produto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Logger.info('✅ Produto de estoque inserido: ${produto.id}');
      return produto.id;
    } catch (e) {
      Logger.error('❌ Erro ao inserir produto de estoque: $e');
      rethrow;
    }
  }

  /// Atualiza um produto de estoque existente
  Future<bool> update(ProdutoEstoque produto) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final result = await db.update(
        _tableName,
        produto.toMap(),
        where: 'id_produto = ?',
        whereArgs: [produto.id],
      );

      Logger.info('✅ Produto de estoque atualizado: ${produto.id}');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar produto de estoque: $e');
      rethrow;
    }
  }

  /// Remove um produto de estoque
  Future<bool> delete(String id) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final result = await db.delete(
        _tableName,
        where: 'id_produto = ?',
        whereArgs: [id],
      );

      Logger.info('✅ Produto de estoque removido: $id');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao remover produto de estoque: $e');
      rethrow;
    }
  }

  /// Busca um produto de estoque pelo ID
  Future<ProdutoEstoque?> getById(String id) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id_produto = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return ProdutoEstoque.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar produto de estoque por ID: $e');
      return null;
    }
  }

  /// Busca todos os produtos de estoque
  Future<List<ProdutoEstoque>> buscarTodos() async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'nome_produto ASC',
      );

      return maps.map((map) => ProdutoEstoque.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar todos os produtos de estoque: $e');
      return [];
    }
  }

  /// Busca produtos de estoque por tipo
  Future<List<ProdutoEstoque>> buscarPorTipo(TipoProduto tipo) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'tipo_produto = ?',
        whereArgs: [tipo.name],
        orderBy: 'nome_produto ASC',
      );

      return maps.map((map) => ProdutoEstoque.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos por tipo: $e');
      return [];
    }
  }

  /// Busca produtos de estoque por fazenda
  Future<List<ProdutoEstoque>> buscarPorFazenda(String fazendaId) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'fazenda_id = ?',
        whereArgs: [fazendaId],
        orderBy: 'nome_produto ASC',
      );

      return maps.map((map) => ProdutoEstoque.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos por fazenda: $e');
      return [];
    }
  }

  /// Busca produtos de estoque por nome
  Future<List<ProdutoEstoque>> buscarPorNome(String nome) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'nome_produto LIKE ?',
        whereArgs: ['%$nome%'],
        orderBy: 'nome_produto ASC',
      );

      return maps.map((map) => ProdutoEstoque.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos por nome: $e');
      return [];
    }
  }

  /// Busca produtos com estoque baixo
  Future<List<ProdutoEstoque>> buscarComEstoqueBaixo({double limite = 10.0}) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'saldo_atual <= ?',
        whereArgs: [limite],
        orderBy: 'saldo_atual ASC',
      );

      return maps.map((map) => ProdutoEstoque.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos com estoque baixo: $e');
      return [];
    }
  }

  /// Busca produtos vencidos ou próximos do vencimento
  Future<List<ProdutoEstoque>> buscarVencidosOuProximosVencimento({int diasAntes = 30}) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final dataLimite = DateTime.now().add(Duration(days: diasAntes)).toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'data_validade IS NOT NULL AND data_validade <= ?',
        whereArgs: [dataLimite],
        orderBy: 'data_validade ASC',
      );

      return maps.map((map) => ProdutoEstoque.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar produtos vencidos: $e');
      return [];
    }
  }

  /// Atualiza o saldo de um produto
  Future<bool> atualizarSaldo(String produtoId, double novoSaldo) async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final result = await db.update(
        _tableName,
        {
          'saldo_atual': novoSaldo,
          'data_atualizacao': DateTime.now().toIso8601String(),
        },
        where: 'id_produto = ?',
        whereArgs: [produtoId],
      );

      Logger.info('✅ Saldo atualizado para produto $produtoId: $novoSaldo');
      return result > 0;
    } catch (e) {
      Logger.error('❌ Erro ao atualizar saldo: $e');
      return false;
    }
  }

  /// Decrementa o saldo de um produto
  Future<bool> decrementarSaldo(String produtoId, double quantidade) async {
    try {
      final produto = await getById(produtoId);
      if (produto == null) {
        Logger.error('❌ Produto não encontrado: $produtoId');
        return false;
      }

      if (produto.saldoAtual < quantidade) {
        Logger.error('❌ Saldo insuficiente para produto $produtoId');
        return false;
      }

      final novoSaldo = produto.saldoAtual - quantidade;
      return await atualizarSaldo(produtoId, novoSaldo);
    } catch (e) {
      Logger.error('❌ Erro ao decrementar saldo: $e');
      return false;
    }
  }

  /// Incrementa o saldo de um produto
  Future<bool> incrementarSaldo(String produtoId, double quantidade) async {
    try {
      final produto = await getById(produtoId);
      if (produto == null) {
        Logger.error('❌ Produto não encontrado: $produtoId');
        return false;
      }

      final novoSaldo = produto.saldoAtual + quantidade;
      return await atualizarSaldo(produtoId, novoSaldo);
    } catch (e) {
      Logger.error('❌ Erro ao incrementar saldo: $e');
      return false;
    }
  }

  /// Obtém estatísticas de estoque
  Future<Map<String, dynamic>> obterEstatisticas() async {
    try {
      final db = await _getDatabase();
      await _createTableIfNotExists(db);

      final produtos = await buscarTodos();

      if (produtos.isEmpty) {
        return {
          'totalProdutos': 0,
          'valorTotalEstoque': 0.0,
          'produtosComEstoqueBaixo': 0,
          'produtosVencidos': 0,
          'tiposProduto': {},
        };
      }

      final valorTotalEstoque = produtos.fold(0.0, (total, produto) => total + produto.valorTotalLote);
      final produtosComEstoqueBaixo = produtos.where((p) => p.saldoAtual <= 10.0).length;
      final produtosVencidos = produtos.where((p) => p.dataValidade != null && p.dataValidade!.isBefore(DateTime.now())).length;

      final tiposProduto = <String, int>{};
      for (final produto in produtos) {
        final tipo = produto.tipo.name;
        tiposProduto[tipo] = (tiposProduto[tipo] ?? 0) + 1;
      }

      return {
        'totalProdutos': produtos.length,
        'valorTotalEstoque': valorTotalEstoque,
        'produtosComEstoqueBaixo': produtosComEstoqueBaixo,
        'produtosVencidos': produtosVencidos,
        'tiposProduto': tiposProduto,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de estoque: $e');
      return {
        'totalProdutos': 0,
        'valorTotalEstoque': 0.0,
        'produtosComEstoqueBaixo': 0,
        'produtosVencidos': 0,
        'tiposProduto': {},
      };
    }
  }

  /// Verifica se há estoque suficiente para um produto
  Future<bool> verificarEstoqueSuficiente(String produtoId, double quantidadeNecessaria) async {
    try {
      final produto = await getById(produtoId);
      if (produto == null) {
        return false;
      }

      return produto.saldoAtual >= quantidadeNecessaria;
    } catch (e) {
      Logger.error('❌ Erro ao verificar estoque: $e');
      return false;
    }
  }
}
