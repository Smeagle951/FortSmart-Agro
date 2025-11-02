import 'package:sqflite/sqflite.dart';
import '../../database/app_database.dart';

class EstoqueDao {
  final AppDatabase _database = AppDatabase.instance;

  // Inserir produto de estoque
  Future<void> inserirProduto({
    required String id,
    required String tipo,
    required String cultura,
    String? variedade,
    required String unidade,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('estoque_produto', {
      'id': id,
      'tipo': tipo,
      'cultura': cultura,
      'variedade': variedade,
      'unidade': unidade,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  // Inserir lote de estoque
  Future<void> inserirLote({
    required String id,
    required String produtoId,
    String? lote,
    required double qntdTotal,
    required double custoUnitario,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert('estoque_lote', {
      'id': id,
      'produto_id': produtoId,
      'lote': lote,
      'qntd_total': qntdTotal,
      'qntd_disponivel': qntdTotal,
      'custo_unitario': custoUnitario,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });
  }

  // Buscar lotes disponíveis por produto
  Future<List<Map<String, dynamic>>> buscarLotesDisponiveis(String produtoId) async {
    final db = await _database.database;
    
    final rows = await db.rawQuery(
      '''
      SELECT el.id, el.lote, el.qntd_disponivel, el.custo_unitario, ep.unidade
      FROM estoque_lote el
      JOIN estoque_produto ep ON ep.id = el.produto_id
      WHERE el.produto_id = ? AND el.qntd_disponivel > 0 
        AND el.deleted_at IS NULL AND ep.deleted_at IS NULL
      ORDER BY el.custo_unitario ASC
      ''',
      [produtoId],
    );
    
    return rows;
  }

  // Apontar saída de estoque (transação)
  Future<void> apontarSaidaEstoque({
    required String plantioId,
    required String loteId,
    required double quantidade,
  }) async {
    final db = await _database.database;
    
    // Verificar disponibilidade
    final lote = await db.query(
      'estoque_lote',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [loteId],
    );
    
    if (lote.isEmpty) {
      throw Exception('Lote não encontrado');
    }
    
    final disponivel = (lote.first['qntd_disponivel'] as num).toDouble();
    
    if (quantidade <= 0) {
      throw Exception('Quantidade deve ser maior que zero');
    }
    
    if (quantidade > disponivel) {
      throw Exception('Quantidade indisponível. Disponível: $disponivel');
    }
    
    final now = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      // Inserir apontamento
      await txn.insert('apontamento_estoque', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'plantio_id': plantioId,
        'lote_id': loteId,
        'quantidade': quantidade,
        'created_at': now,
        'updated_at': now,
        'deleted_at': null,
      });
      
      // Atualizar quantidade disponível
      await txn.update(
        'estoque_lote',
        {
          'qntd_disponivel': disponivel - quantidade,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [loteId],
      );
    });
  }

  // Buscar apontamentos por plantio
  Future<List<Map<String, dynamic>>> buscarApontamentosPlantio(String plantioId) async {
    final db = await _database.database;
    
    final rows = await db.rawQuery(
      '''
      SELECT 
        ae.id,
        ae.quantidade,
        ae.created_at,
        el.lote,
        el.custo_unitario,
        ep.cultura,
        ep.variedade,
        ep.unidade,
        (ae.quantidade * el.custo_unitario) as custo_total
      FROM apontamento_estoque ae
      JOIN estoque_lote el ON el.id = ae.lote_id
      JOIN estoque_produto ep ON ep.id = el.produto_id
      WHERE ae.plantio_id = ? 
        AND ae.deleted_at IS NULL 
        AND el.deleted_at IS NULL 
        AND ep.deleted_at IS NULL
      ORDER BY ae.created_at DESC
      ''',
      [plantioId],
    );
    
    return rows;
  }

  // Buscar custo total por plantio
  Future<double?> buscarCustoTotalPlantio(String plantioId) async {
    final db = await _database.database;
    
    final result = await db.rawQuery(
      '''
      SELECT SUM(ae.quantidade * el.custo_unitario) as custo_total
      FROM apontamento_estoque ae
      JOIN estoque_lote el ON el.id = ae.lote_id
      WHERE ae.plantio_id = ? 
        AND ae.deleted_at IS NULL 
        AND el.deleted_at IS NULL
      ''',
      [plantioId],
    );
    
    if (result.isNotEmpty && result.first['custo_total'] != null) {
      return (result.first['custo_total'] as num).toDouble();
    }
    
    return null;
  }

  // Buscar produtos por tipo e cultura
  Future<List<Map<String, dynamic>>> buscarProdutos({
    String? tipo,
    String? cultura,
  }) async {
    final db = await _database.database;
    
    String whereClause = 'deleted_at IS NULL';
    List<dynamic> whereArgs = [];
    
    if (tipo != null) {
      whereClause += ' AND tipo = ?';
      whereArgs.add(tipo);
    }
    
    if (cultura != null) {
      whereClause += ' AND cultura = ?';
      whereArgs.add(cultura);
    }
    
    final rows = await db.query(
      'estoque_produto',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'cultura, variedade',
    );
    
    return rows;
  }

  // Verificar se produto tem lotes disponíveis
  Future<bool> verificarProdutoDisponivel(String produtoId) async {
    final db = await _database.database;
    
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM estoque_lote
      WHERE produto_id = ? 
        AND qntd_disponivel > 0 
        AND deleted_at IS NULL
      ''',
      [produtoId],
    );
    
    return (result.first['total'] as int) > 0;
  }

  // Buscar resumo de estoque por produto
  Future<List<Map<String, dynamic>>> buscarResumoEstoque() async {
    final db = await _database.database;
    
    final rows = await db.rawQuery(
      '''
      SELECT 
        ep.id as produto_id,
        ep.tipo,
        ep.cultura,
        ep.variedade,
        ep.unidade,
        SUM(el.qntd_disponivel) as total_disponivel,
        COUNT(el.id) as total_lotes,
        AVG(el.custo_unitario) as custo_medio
      FROM estoque_produto ep
      LEFT JOIN estoque_lote el ON el.produto_id = ep.id AND el.deleted_at IS NULL
      WHERE ep.deleted_at IS NULL
      GROUP BY ep.id
      HAVING total_disponivel > 0
      ORDER BY ep.cultura, ep.variedade
      ''',
    );
    
    return rows;
  }

  // Reverter apontamento (para correções)
  Future<void> reverterApontamento(String apontamentoId) async {
    final db = await _database.database;
    
    // Buscar apontamento
    final apontamento = await db.query(
      'apontamento_estoque',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [apontamentoId],
    );
    
    if (apontamento.isEmpty) {
      throw Exception('Apontamento não encontrado');
    }
    
    final quantidade = (apontamento.first['quantidade'] as num).toDouble();
    final loteId = apontamento.first['lote_id'] as String;
    final now = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      // Marcar apontamento como deletado
      await txn.update(
        'apontamento_estoque',
        {'deleted_at': now, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [apontamentoId],
      );
      
      // Restaurar quantidade no lote
      await txn.rawUpdate(
        '''
        UPDATE estoque_lote 
        SET qntd_disponivel = qntd_disponivel + ?, updated_at = ?
        WHERE id = ?
        ''',
        [quantidade, now, loteId],
      );
    });
  }
}
