/// Modelo para produtos aplicados em aplicações
class ProdutoAplicadoModel {
  final String produtoId;
  final String nome;
  final double doseHa;
  final String unidade;
  final double estoqueAtual;
  final String? principioAtivo;
  final String? categoria;
  final String? status;

  const ProdutoAplicadoModel({
    required this.produtoId,
    required this.nome,
    required this.doseHa,
    required this.unidade,
    required this.estoqueAtual,
    this.principioAtivo,
    this.categoria,
    this.status,
  });

  /// Cria a partir de Map
  factory ProdutoAplicadoModel.fromMap(Map<String, dynamic> map) {
    return ProdutoAplicadoModel(
      produtoId: map['produtoId'] ?? '',
      nome: map['nome'] ?? '',
      doseHa: (map['doseHa'] ?? map['dosePorHectare'] ?? 0.0).toDouble(),
      unidade: map['unidade'] ?? '',
      estoqueAtual: (map['estoqueAtual'] ?? map['estoqueDisponivel'] ?? 0.0).toDouble(),
      principioAtivo: map['principioAtivo'],
      categoria: map['categoria'],
      status: map['status'],
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'produtoId': produtoId,
      'nome': nome,
      'doseHa': doseHa,
      'unidade': unidade,
      'estoqueAtual': estoqueAtual,
      'principioAtivo': principioAtivo,
      'categoria': categoria,
      'status': status,
    };
  }

  /// Cria uma cópia com campos alterados
  ProdutoAplicadoModel copyWith({
    String? produtoId,
    String? nome,
    double? doseHa,
    String? unidade,
    double? estoqueAtual,
    String? principioAtivo,
    String? categoria,
    String? status,
  }) {
    return ProdutoAplicadoModel(
      produtoId: produtoId ?? this.produtoId,
      nome: nome ?? this.nome,
      doseHa: doseHa ?? this.doseHa,
      unidade: unidade ?? this.unidade,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      principioAtivo: principioAtivo ?? this.principioAtivo,
      categoria: categoria ?? this.categoria,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'ProdutoAplicadoModel(nome: $nome, doseHa: $doseHa $unidade, estoque: $estoqueAtual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProdutoAplicadoModel && other.nome == nome;
  }

  @override
  int get hashCode => nome.hashCode;
}
