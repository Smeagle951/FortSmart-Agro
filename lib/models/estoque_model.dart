/// Modelo para representar um item de estoque
class EstoqueModel {
  final String id;
  final String produtoId;
  final String produtoNome;
  final String loteCodigo;
  final double quantidadeDisponivel;
  final String unidade;
  final DateTime dataValidade;
  final double precoUnitario;
  final DateTime dataEntrada;
  final DateTime ultimaAtualizacao;
  final String? fornecedor;
  final String? observacoes;

  EstoqueModel({
    required this.id,
    required this.produtoId,
    required this.produtoNome,
    required this.loteCodigo,
    required this.quantidadeDisponivel,
    required this.unidade,
    required this.dataValidade,
    required this.precoUnitario,
    required this.dataEntrada,
    required this.ultimaAtualizacao,
    this.fornecedor,
    this.observacoes,
  });

  factory EstoqueModel.fromMap(Map<String, dynamic> map) {
    return EstoqueModel(
      id: map['id'],
      produtoId: map['produto_id'],
      produtoNome: map['produto_nome'] ?? '',
      loteCodigo: map['lote_codigo'],
      quantidadeDisponivel: map['quantidade_disponivel']?.toDouble() ?? 0,
      unidade: map['unidade'],
      dataValidade: DateTime.parse(map['data_validade']),
      precoUnitario: map['preco_unitario']?.toDouble() ?? 0,
      dataEntrada: DateTime.parse(map['data_entrada']),
      ultimaAtualizacao: DateTime.parse(map['ultima_atualizacao']),
      fornecedor: map['fornecedor'],
      observacoes: map['observacoes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto_id': produtoId,
      'produto_nome': produtoNome,
      'lote_codigo': loteCodigo,
      'quantidade_disponivel': quantidadeDisponivel,
      'unidade': unidade,
      'data_validade': dataValidade.toIso8601String(),
      'preco_unitario': precoUnitario,
      'data_entrada': dataEntrada.toIso8601String(),
      'ultima_atualizacao': ultimaAtualizacao.toIso8601String(),
      'fornecedor': fornecedor,
      'observacoes': observacoes,
    };
  }

  EstoqueModel copyWith({
    String? id,
    String? produtoId,
    String? produtoNome,
    String? loteCodigo,
    double? quantidadeDisponivel,
    String? unidade,
    DateTime? dataValidade,
    double? precoUnitario,
    DateTime? dataEntrada,
    DateTime? ultimaAtualizacao,
    String? fornecedor,
    String? observacoes,
  }) {
    return EstoqueModel(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      produtoNome: produtoNome ?? this.produtoNome,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      quantidadeDisponivel: quantidadeDisponivel ?? this.quantidadeDisponivel,
      unidade: unidade ?? this.unidade,
      dataValidade: dataValidade ?? this.dataValidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      dataEntrada: dataEntrada ?? this.dataEntrada,
      ultimaAtualizacao: ultimaAtualizacao ?? this.ultimaAtualizacao,
      fornecedor: fornecedor ?? this.fornecedor,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  /// Calcula o valor total do estoque
  double get valorTotal => quantidadeDisponivel * precoUnitario;

  /// Verifica se o produto está próximo do vencimento (30 dias)
  bool get proximoVencimento {
    final hoje = DateTime.now();
    final diasParaVencimento = dataValidade.difference(hoje).inDays;
    return diasParaVencimento <= 30 && diasParaVencimento > 0;
  }

  /// Verifica se o produto está vencido
  bool get vencido => dataValidade.isBefore(DateTime.now());

  /// Verifica se o estoque está baixo (menos de 10% do preço unitário)
  bool get estoqueBaixo => quantidadeDisponivel < (precoUnitario * 0.1);
}
