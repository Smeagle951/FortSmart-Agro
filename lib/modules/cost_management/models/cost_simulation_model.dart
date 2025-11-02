class CostSimulationModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final double areaHa;
  final List<SimulationProduct> produtos;
  final DateTime dataSimulacao;
  final double custoTotal;
  final double custoPorHectare;
  final String observacoes;

  CostSimulationModel({
    required this.id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.areaHa,
    required this.produtos,
    required this.dataSimulacao,
    required this.custoTotal,
    required this.custoPorHectare,
    this.observacoes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'area_ha': areaHa,
      'produtos': produtos.map((p) => p.toMap()).toList(),
      'data_simulacao': dataSimulacao.toIso8601String(),
      'custo_total': custoTotal,
      'custo_por_hectare': custoPorHectare,
      'observacoes': observacoes,
    };
  }

  factory CostSimulationModel.fromMap(Map<String, dynamic> map) {
    return CostSimulationModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      areaHa: (map['area_ha'] ?? 0.0).toDouble(),
      produtos: (map['produtos'] as List<dynamic>?)
          ?.map((p) => SimulationProduct.fromMap(p))
          .toList() ?? [],
      dataSimulacao: DateTime.parse(map['data_simulacao']),
      custoTotal: (map['custo_total'] ?? 0.0).toDouble(),
      custoPorHectare: (map['custo_por_hectare'] ?? 0.0).toDouble(),
      observacoes: map['observacoes'] ?? '',
    );
  }
}

class SimulationProduct {
  final String produtoId;
  final String nomeProduto;
  final String tipoProduto;
  final String unidade;
  final double dosePorHa;
  final double quantidadeTotal;
  final double precoUnitario;
  final double custoTotal;

  SimulationProduct({
    required this.produtoId,
    required this.nomeProduto,
    required this.tipoProduto,
    required this.unidade,
    required this.dosePorHa,
    required this.quantidadeTotal,
    required this.precoUnitario,
    required this.custoTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'produto_id': produtoId,
      'nome_produto': nomeProduto,
      'tipo_produto': tipoProduto,
      'unidade': unidade,
      'dose_por_ha': dosePorHa,
      'quantidade_total': quantidadeTotal,
      'preco_unitario': precoUnitario,
      'custo_total': custoTotal,
    };
  }

  factory SimulationProduct.fromMap(Map<String, dynamic> map) {
    return SimulationProduct(
      produtoId: map['produto_id'] ?? '',
      nomeProduto: map['nome_produto'] ?? '',
      tipoProduto: map['tipo_produto'] ?? '',
      unidade: map['unidade'] ?? '',
      dosePorHa: (map['dose_por_ha'] ?? 0.0).toDouble(),
      quantidadeTotal: (map['quantidade_total'] ?? 0.0).toDouble(),
      precoUnitario: (map['preco_unitario'] ?? 0.0).toDouble(),
      custoTotal: (map['custo_total'] ?? 0.0).toDouble(),
    );
  }
}
