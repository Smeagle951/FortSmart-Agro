import 'package:uuid/uuid.dart';

enum TipoProduto {
  herbicida,
  inseticida,
  fungicida,
  fertilizante,
  adjuvante,
  semente,
  outro,
}

class ProdutoEstoque {
  final String id;
  final String nome;
  final TipoProduto tipo;
  final String unidade;
  final double precoUnitario;
  final double saldoAtual;
  final String? fornecedor;
  final String? numeroLote;
  final String? localArmazenagem;
  final DateTime? dataValidade;
  final String? observacoes;
  final String? fazendaId;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final bool isSincronizado;

  // Campo calculado
  double get valorTotalLote => saldoAtual * precoUnitario;

  ProdutoEstoque({
    String? id,
    required this.nome,
    required this.tipo,
    required this.unidade,
    required this.precoUnitario,
    this.saldoAtual = 0,
    this.fornecedor,
    this.numeroLote,
    this.localArmazenagem,
    this.dataValidade,
    this.observacoes,
    this.fazendaId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    this.isSincronizado = false,
  }) : 
    id = id ?? const Uuid().v4(),
    dataCriacao = dataCriacao ?? DateTime.now(),
    dataAtualizacao = dataAtualizacao ?? DateTime.now();

  factory ProdutoEstoque.fromMap(Map<String, dynamic> map) {
    return ProdutoEstoque(
      id: map['id_produto'] ?? map['id'],
      nome: map['nome_produto'] ?? map['nome'],
      tipo: _parseTipoProduto(map['tipo_produto'] ?? map['tipo']),
      unidade: map['unidade'],
      precoUnitario: (map['preco_unitario'] as num?)?.toDouble() ?? 0.0,
      saldoAtual: (map['saldo_atual'] as num?)?.toDouble() ?? 0.0,
      fornecedor: map['fornecedor'],
      numeroLote: map['numero_lote'],
      localArmazenagem: map['local_armazenagem'],
      dataValidade: map['data_validade'] != null 
          ? DateTime.parse(map['data_validade']) 
          : null,
      observacoes: map['observacoes'],
      fazendaId: map['fazenda_id'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      dataAtualizacao: DateTime.parse(map['data_atualizacao']),
      isSincronizado: map['is_sincronizado'] == 1 || map['is_sincronizado'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_produto': id,
      'nome_produto': nome,
      'tipo_produto': tipo.name,
      'unidade': unidade,
      'preco_unitario': precoUnitario,
      'saldo_atual': saldoAtual,
      'fornecedor': fornecedor,
      'numero_lote': numeroLote,
      'local_armazenagem': localArmazenagem,
      'data_validade': dataValidade?.toIso8601String(),
      'observacoes': observacoes,
      'fazenda_id': fazendaId,
      'data_criacao': dataCriacao.toIso8601String(),
      'data_atualizacao': dataAtualizacao.toIso8601String(),
      'is_sincronizado': isSincronizado ? 1 : 0,
    };
  }

  static TipoProduto _parseTipoProduto(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'herbicida': return TipoProduto.herbicida;
      case 'inseticida': return TipoProduto.inseticida;
      case 'fungicida': return TipoProduto.fungicida;
      case 'fertilizante': return TipoProduto.fertilizante;
      case 'adjuvante': return TipoProduto.adjuvante;
      case 'semente': return TipoProduto.semente;
      default: return TipoProduto.outro;
    }
  }

  ProdutoEstoque copyWith({
    String? nome,
    TipoProduto? tipo,
    String? unidade,
    double? precoUnitario,
    double? saldoAtual,
    String? fornecedor,
    String? numeroLote,
    String? localArmazenagem,
    DateTime? dataValidade,
    String? observacoes,
    String? fazendaId,
    bool? isSincronizado,
  }) {
    return ProdutoEstoque(
      id: id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      unidade: unidade ?? this.unidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      saldoAtual: saldoAtual ?? this.saldoAtual,
      fornecedor: fornecedor ?? this.fornecedor,
      numeroLote: numeroLote ?? this.numeroLote,
      localArmazenagem: localArmazenagem ?? this.localArmazenagem,
      dataValidade: dataValidade ?? this.dataValidade,
      observacoes: observacoes ?? this.observacoes,
      fazendaId: fazendaId ?? this.fazendaId,
      dataCriacao: dataCriacao,
      dataAtualizacao: DateTime.now(),
      isSincronizado: isSincronizado ?? this.isSincronizado,
    );
  }

  @override
  String toString() {
    return 'ProdutoEstoque(id: $id, nome: $nome, tipo: $tipo, precoUnitario: $precoUnitario, saldoAtual: $saldoAtual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProdutoEstoque && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
