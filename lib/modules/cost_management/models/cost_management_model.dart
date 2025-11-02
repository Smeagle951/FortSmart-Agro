class CostManagementModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final double areaHa;
  final DateTime dataAplicacao;
  final String operador;
  final String equipamento;
  final String observacoes;
  final double custoTotal;
  final double custoPorHectare;
  final List<CostProductModel> produtos;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final bool sincronizado;

  CostManagementModel({
    required this.id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.areaHa,
    required this.dataAplicacao,
    required this.operador,
    required this.equipamento,
    required this.observacoes,
    required this.custoTotal,
    required this.custoPorHectare,
    required this.produtos,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.sincronizado = false,
  });

  factory CostManagementModel.fromJson(Map<String, dynamic> json) {
    return CostManagementModel(
      id: json['id'] ?? '',
      talhaoId: json['talhaoId'] ?? '',
      talhaoNome: json['talhaoNome'] ?? '',
      areaHa: (json['areaHa'] ?? 0.0).toDouble(),
      dataAplicacao: DateTime.parse(json['dataAplicacao'] ?? DateTime.now().toIso8601String()),
      operador: json['operador'] ?? '',
      equipamento: json['equipamento'] ?? '',
      observacoes: json['observacoes'] ?? '',
      custoTotal: (json['custoTotal'] ?? 0.0).toDouble(),
      custoPorHectare: (json['custoPorHectare'] ?? 0.0).toDouble(),
      produtos: (json['produtos'] as List<dynamic>?)
          ?.map((e) => CostProductModel.fromJson(e))
          .toList() ?? [],
      dataCriacao: DateTime.parse(json['dataCriacao'] ?? DateTime.now().toIso8601String()),
      dataAtualizacao: DateTime.parse(json['dataAtualizacao'] ?? DateTime.now().toIso8601String()),
      sincronizado: json['sincronizado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'talhaoNome': talhaoNome,
      'areaHa': areaHa,
      'dataAplicacao': dataAplicacao.toIso8601String(),
      'operador': operador,
      'equipamento': equipamento,
      'observacoes': observacoes,
      'custoTotal': custoTotal,
      'custoPorHectare': custoPorHectare,
      'produtos': produtos.map((e) => e.toJson()).toList(),
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'sincronizado': sincronizado,
    };
  }

  CostManagementModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    double? areaHa,
    DateTime? dataAplicacao,
    String? operador,
    String? equipamento,
    String? observacoes,
    double? custoTotal,
    double? custoPorHectare,
    List<CostProductModel>? produtos,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? sincronizado,
  }) {
    return CostManagementModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      areaHa: areaHa ?? this.areaHa,
      dataAplicacao: dataAplicacao ?? this.dataAplicacao,
      operador: operador ?? this.operador,
      equipamento: equipamento ?? this.equipamento,
      observacoes: observacoes ?? this.observacoes,
      custoTotal: custoTotal ?? this.custoTotal,
      custoPorHectare: custoPorHectare ?? this.custoPorHectare,
      produtos: produtos ?? this.produtos,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// Calcula o total necessário de um produto
  double calcularTotalProduto(CostProductModel produto) {
    return produto.dosePorHa * areaHa;
  }
}

class CostProductModel {
  final String id;
  final String nome;
  final String tipo;
  final String unidade;
  final double dosePorHa;
  final double precoUnitario;
  final double quantidade;
  final double custoTotal;

  CostProductModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidade,
    required this.dosePorHa,
    required this.precoUnitario,
    required this.quantidade,
    required this.custoTotal,
  });

  factory CostProductModel.fromJson(Map<String, dynamic> json) {
    return CostProductModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      unidade: json['unidade'] ?? '',
      dosePorHa: (json['dosePorHa'] ?? 0.0).toDouble(),
      precoUnitario: (json['precoUnitario'] ?? 0.0).toDouble(),
      quantidade: (json['quantidade'] ?? 0.0).toDouble(),
      custoTotal: (json['custoTotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'unidade': unidade,
      'dosePorHa': dosePorHa,
      'precoUnitario': precoUnitario,
      'quantidade': quantidade,
      'custoTotal': custoTotal,
    };
  }
}
