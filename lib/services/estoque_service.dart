import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço para gerenciamento de estoque
/// Responsável por verificação de disponibilidade e baixa automática
class EstoqueService {
  static final EstoqueService _instance = EstoqueService._internal();
  factory EstoqueService() => _instance;
  EstoqueService._internal();

  /// Verifica se há estoque suficiente para um produto
  Future<EstoqueVerificacao> verificarEstoque({
    required String produtoId,
    required double quantidadeNecessaria,
    String? loteCodigo,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      String query = '''
        SELECT * FROM estoque 
        WHERE produto_id = ? 
        AND quantidade_disponivel > 0
      ''';
      
      List<dynamic> args = [produtoId];
      
      if (loteCodigo != null && loteCodigo.isNotEmpty) {
        query += ' AND lote_codigo = ?';
        args.add(loteCodigo);
      }
      
      query += ' ORDER BY data_validade ASC';
      
      final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
      
      if (result.isEmpty) {
        return EstoqueVerificacao(
          disponivel: false,
          quantidadeDisponivel: 0,
          quantidadeNecessaria: quantidadeNecessaria,
          mensagem: 'Produto não encontrado no estoque',
          lotesDisponiveis: [],
        );
      }
      
      double quantidadeTotal = 0;
      List<EstoqueLote> lotesDisponiveis = [];
      
      for (final row in result) {
        final lote = EstoqueLote.fromMap(row);
        quantidadeTotal += lote.quantidadeDisponivel;
        lotesDisponiveis.add(lote);
      }
      
      final disponivel = quantidadeTotal >= quantidadeNecessaria;
      
      return EstoqueVerificacao(
        disponivel: disponivel,
        quantidadeDisponivel: quantidadeTotal,
        quantidadeNecessaria: quantidadeNecessaria,
        mensagem: disponivel 
          ? 'Estoque suficiente' 
          : 'Estoque insuficiente. Disponível: ${quantidadeTotal.toStringAsFixed(2)}',
        lotesDisponiveis: lotesDisponiveis,
      );
    } catch (e) {
      Logger.error('Erro ao verificar estoque: $e');
      return EstoqueVerificacao(
        disponivel: false,
        quantidadeDisponivel: 0,
        quantidadeNecessaria: quantidadeNecessaria,
        mensagem: 'Erro ao verificar estoque: $e',
        lotesDisponiveis: [],
      );
    }
  }

  /// Verifica estoque para múltiplos produtos
  Future<List<EstoqueVerificacao>> verificarEstoqueMultiplos(
    List<EstoqueVerificacaoRequest> produtos,
  ) async {
    final verificacoes = <EstoqueVerificacao>[];
    
    for (final produto in produtos) {
      final verificacao = await verificarEstoque(
        produtoId: produto.produtoId,
        quantidadeNecessaria: produto.quantidadeNecessaria,
        loteCodigo: produto.loteCodigo,
      );
      verificacoes.add(verificacao);
    }
    
    return verificacoes;
  }

  /// Realiza baixa automática de estoque
  Future<EstoqueBaixaResult> realizarBaixaEstoque({
    required String produtoId,
    required double quantidade,
    String? loteCodigo,
    String? prescricaoId,
    String? observacoes,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar estoque disponível
      final verificacao = await verificarEstoque(
        produtoId: produtoId,
        quantidadeNecessaria: quantidade,
        loteCodigo: loteCodigo,
      );
      
      if (!verificacao.disponivel) {
        return EstoqueBaixaResult(
          sucesso: false,
          mensagem: verificacao.mensagem,
          quantidadeBaixada: 0,
        );
      }
      
      // Realizar baixa por lote (FIFO - First In, First Out)
      double quantidadeRestante = quantidade;
      double quantidadeTotalBaixada = 0;
      
      for (final lote in verificacao.lotesDisponiveis) {
        if (quantidadeRestante <= 0) break;
        
        final quantidadeBaixar = quantidadeRestante > lote.quantidadeDisponivel 
          ? lote.quantidadeDisponivel 
          : quantidadeRestante;
        
        // Atualizar quantidade no lote
        await db.update(
          'estoque',
          {
            'quantidade_disponivel': lote.quantidadeDisponivel - quantidadeBaixar,
            'ultima_atualizacao': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [lote.id],
        );
        
        // Registrar movimento de estoque
        await db.insert('estoque_movimentos', {
          'produto_id': produtoId,
          'lote_id': lote.id,
          'tipo_movimento': 'SAIDA',
          'quantidade': quantidadeBaixar,
          'data_movimento': DateTime.now().toIso8601String(),
          'prescricao_id': prescricaoId,
          'observacoes': observacoes ?? 'Baixa automática por prescrição',
        });
        
        quantidadeRestante -= quantidadeBaixar;
        quantidadeTotalBaixada += quantidadeBaixar;
      }
      
      return EstoqueBaixaResult(
        sucesso: true,
        mensagem: 'Baixa realizada com sucesso',
        quantidadeBaixada: quantidadeTotalBaixada,
      );
    } catch (e) {
      Logger.error('Erro ao realizar baixa de estoque: $e');
      return EstoqueBaixaResult(
        sucesso: false,
        mensagem: 'Erro ao realizar baixa: $e',
        quantidadeBaixada: 0,
      );
    }
  }

  /// Realiza baixa para múltiplos produtos
  Future<List<EstoqueBaixaResult>> realizarBaixaMultiplos(
    List<EstoqueBaixaRequest> produtos,
    String? prescricaoId,
  ) async {
    final resultados = <EstoqueBaixaResult>[];
    
    for (final produto in produtos) {
      final resultado = await realizarBaixaEstoque(
        produtoId: produto.produtoId,
        quantidade: produto.quantidade,
        loteCodigo: produto.loteCodigo,
        prescricaoId: prescricaoId,
        observacoes: produto.observacoes,
      );
      resultados.add(resultado);
    }
    
    return resultados;
  }

  /// Reserva estoque para uma prescrição (sem baixar)
  Future<EstoqueReservaResult> reservarEstoque({
    required String prescricaoId,
    required List<EstoqueVerificacaoRequest> produtos,
    Duration? validadeReserva = const Duration(hours: 24),
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar disponibilidade
      final verificacoes = await verificarEstoqueMultiplos(produtos);
      
      for (final verificacao in verificacoes) {
        if (!verificacao.disponivel) {
          return EstoqueReservaResult(
            sucesso: false,
            mensagem: 'Estoque insuficiente: ${verificacao.mensagem}',
            prescricaoId: prescricaoId,
          );
        }
      }
      
      // Criar reserva
      final dataExpiracao = DateTime.now().add(validadeReserva!);
      
      await db.insert('estoque_reservas', {
        'prescricao_id': prescricaoId,
        'data_reserva': DateTime.now().toIso8601String(),
        'data_expiracao': dataExpiracao.toIso8601String(),
        'status': 'ATIVA',
      });
      
      // Registrar produtos da reserva
      for (final produto in produtos) {
        await db.insert('estoque_reserva_produtos', {
          'prescricao_id': prescricaoId,
          'produto_id': produto.produtoId,
          'quantidade_reservada': produto.quantidadeNecessaria,
          'lote_codigo': produto.loteCodigo,
        });
      }
      
      return EstoqueReservaResult(
        sucesso: true,
        mensagem: 'Estoque reservado com sucesso',
        prescricaoId: prescricaoId,
      );
    } catch (e) {
      Logger.error('Erro ao reservar estoque: $e');
      return EstoqueReservaResult(
        sucesso: false,
        mensagem: 'Erro ao reservar estoque: $e',
        prescricaoId: prescricaoId,
      );
    }
  }

  /// Cancela reserva de estoque
  Future<bool> cancelarReserva(String prescricaoId) async {
    try {
      final db = await AppDatabase.instance.database;
      
      await db.update(
        'estoque_reservas',
        {'status': 'CANCELADA'},
        where: 'prescricao_id = ?',
        whereArgs: [prescricaoId],
      );
      
      return true;
    } catch (e) {
      Logger.error('Erro ao cancelar reserva: $e');
      return false;
    }
  }

  /// Obtém histórico de movimentos de estoque
  Future<List<EstoqueMovimento>> obterHistoricoMovimentos({
    String? produtoId,
    String? prescricaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? limite,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      
      String query = 'SELECT * FROM estoque_movimentos WHERE 1=1';
      List<dynamic> args = [];
      
      if (produtoId != null) {
        query += ' AND produto_id = ?';
        args.add(produtoId);
      }
      
      if (prescricaoId != null) {
        query += ' AND prescricao_id = ?';
        args.add(prescricaoId);
      }
      
      if (dataInicio != null) {
        query += ' AND data_movimento >= ?';
        args.add(dataInicio.toIso8601String());
      }
      
      if (dataFim != null) {
        query += ' AND data_movimento <= ?';
        args.add(dataFim.toIso8601String());
      }
      
      query += ' ORDER BY data_movimento DESC';
      
      if (limite != null) {
        query += ' LIMIT ?';
        args.add(limite);
      }
      
      final List<Map<String, dynamic>> result = await db.rawQuery(query, args);
      
      return result.map((row) => EstoqueMovimento.fromMap(row)).toList();
    } catch (e) {
      Logger.error('Erro ao obter histórico de movimentos: $e');
      return [];
    }
  }

  /// Obtém relatório de estoque atual
  Future<List<EstoqueRelatorio>> obterRelatorioEstoque() async {
    try {
      final db = await AppDatabase.instance.database;
      
      const query = '''
        SELECT 
          e.produto_id,
          p.nome as produto_nome,
          e.lote_codigo,
          e.quantidade_disponivel,
          e.data_validade,
          e.preco_unitario,
          (e.quantidade_disponivel * e.preco_unitario) as valor_total
        FROM estoque e
        JOIN produtos p ON e.produto_id = p.id
        WHERE e.quantidade_disponivel > 0
        ORDER BY p.nome, e.data_validade
      ''';
      
      final List<Map<String, dynamic>> result = await db.rawQuery(query);
      
      return result.map((row) => EstoqueRelatorio.fromMap(row)).toList();
    } catch (e) {
      Logger.error('Erro ao obter relatório de estoque: $e');
      return [];
    }
  }
}

/// Modelos para o serviço de estoque

class EstoqueVerificacao {
  final bool disponivel;
  final double quantidadeDisponivel;
  final double quantidadeNecessaria;
  final String mensagem;
  final List<EstoqueLote> lotesDisponiveis;

  EstoqueVerificacao({
    required this.disponivel,
    required this.quantidadeDisponivel,
    required this.quantidadeNecessaria,
    required this.mensagem,
    required this.lotesDisponiveis,
  });
}

class EstoqueVerificacaoRequest {
  final String produtoId;
  final double quantidadeNecessaria;
  final String? loteCodigo;

  EstoqueVerificacaoRequest({
    required this.produtoId,
    required this.quantidadeNecessaria,
    this.loteCodigo,
  });
}

class EstoqueBaixaResult {
  final bool sucesso;
  final String mensagem;
  final double quantidadeBaixada;

  EstoqueBaixaResult({
    required this.sucesso,
    required this.mensagem,
    required this.quantidadeBaixada,
  });
}

class EstoqueBaixaRequest {
  final String produtoId;
  final double quantidade;
  final String? loteCodigo;
  final String? observacoes;

  EstoqueBaixaRequest({
    required this.produtoId,
    required this.quantidade,
    this.loteCodigo,
    this.observacoes,
  });
}

class EstoqueReservaResult {
  final bool sucesso;
  final String mensagem;
  final String prescricaoId;

  EstoqueReservaResult({
    required this.sucesso,
    required this.mensagem,
    required this.prescricaoId,
  });
}

class EstoqueLote {
  final String id;
  final String produtoId;
  final String loteCodigo;
  final double quantidadeDisponivel;
  final DateTime dataValidade;
  final double precoUnitario;

  EstoqueLote({
    required this.id,
    required this.produtoId,
    required this.loteCodigo,
    required this.quantidadeDisponivel,
    required this.dataValidade,
    required this.precoUnitario,
  });

  factory EstoqueLote.fromMap(Map<String, dynamic> map) {
    return EstoqueLote(
      id: map['id'],
      produtoId: map['produto_id'],
      loteCodigo: map['lote_codigo'],
      quantidadeDisponivel: map['quantidade_disponivel']?.toDouble() ?? 0,
      dataValidade: DateTime.parse(map['data_validade']),
      precoUnitario: map['preco_unitario']?.toDouble() ?? 0,
    );
  }
}

class EstoqueMovimento {
  final String id;
  final String produtoId;
  final String loteId;
  final String tipoMovimento;
  final double quantidade;
  final DateTime dataMovimento;
  final String? prescricaoId;
  final String? observacoes;

  EstoqueMovimento({
    required this.id,
    required this.produtoId,
    required this.loteId,
    required this.tipoMovimento,
    required this.quantidade,
    required this.dataMovimento,
    this.prescricaoId,
    this.observacoes,
  });

  factory EstoqueMovimento.fromMap(Map<String, dynamic> map) {
    return EstoqueMovimento(
      id: map['id'],
      produtoId: map['produto_id'],
      loteId: map['lote_id'],
      tipoMovimento: map['tipo_movimento'],
      quantidade: map['quantidade']?.toDouble() ?? 0,
      dataMovimento: DateTime.parse(map['data_movimento']),
      prescricaoId: map['prescricao_id'],
      observacoes: map['observacoes'],
    );
  }
}

class EstoqueRelatorio {
  final String produtoId;
  final String produtoNome;
  final String loteCodigo;
  final double quantidadeDisponivel;
  final DateTime dataValidade;
  final double precoUnitario;
  final double valorTotal;

  EstoqueRelatorio({
    required this.produtoId,
    required this.produtoNome,
    required this.loteCodigo,
    required this.quantidadeDisponivel,
    required this.dataValidade,
    required this.precoUnitario,
    required this.valorTotal,
  });

  factory EstoqueRelatorio.fromMap(Map<String, dynamic> map) {
    return EstoqueRelatorio(
      produtoId: map['produto_id'],
      produtoNome: map['produto_nome'],
      loteCodigo: map['lote_codigo'],
      quantidadeDisponivel: map['quantidade_disponivel']?.toDouble() ?? 0,
      dataValidade: DateTime.parse(map['data_validade']),
      precoUnitario: map['preco_unitario']?.toDouble() ?? 0,
      valorTotal: map['valor_total']?.toDouble() ?? 0,
    );
  }
}
