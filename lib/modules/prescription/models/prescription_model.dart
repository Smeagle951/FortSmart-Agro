import 'package:flutter/material.dart';

/// Modelo principal de prescrição agrícola
class PrescriptionModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final double areaTalhao;
  final TipoAplicacao tipoAplicacao;
  final String? equipamento;
  final double capacidadeTanque;
  final double vazaoPorHectare;
  final bool doseFracionada;
  final String? bicoSelecionado;
  final double vazaoBico;
  final double pressaoBico;
  final List<PrescriptionProduct> produtos;
  final DateTime dataPrescricao;
  final String operador;
  final String? observacoes;
  final StatusPrescricao status;
  final double volumeTotalCalda;
  final int numeroTanques;
  final double custoTotal;
  final double custoPorHectare;
  final String? anexos;
  final DateTime? dataExecucao;
  final String? operadorExecucao;

  PrescriptionModel({
    required this.id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.areaTalhao,
    required this.tipoAplicacao,
    this.equipamento,
    required this.capacidadeTanque,
    required this.vazaoPorHectare,
    required this.doseFracionada,
    this.bicoSelecionado,
    required this.vazaoBico,
    required this.pressaoBico,
    required this.produtos,
    required this.dataPrescricao,
    required this.operador,
    this.observacoes,
    required this.status,
    required this.volumeTotalCalda,
    required this.numeroTanques,
    required this.custoTotal,
    required this.custoPorHectare,
    this.anexos,
    this.dataExecucao,
    this.operadorExecucao,
  });

  /// Calcula volume total da calda
  double calcularVolumeTotalCalda() {
    return areaTalhao * vazaoPorHectare;
  }

  /// Calcula número de tanques necessários
  int calcularNumeroTanques() {
    return (volumeTotalCalda / capacidadeTanque).ceil();
  }

  /// Calcula quantidade de produto por tanque
  double calcularProdutoPorTanque(PrescriptionProduct produto) {
    return produto.dosePorHectare * (capacidadeTanque / vazaoPorHectare);
  }

  /// Calcula quantidade total de produto necessária
  double calcularProdutoTotal(PrescriptionProduct produto) {
    return produto.dosePorHectare * areaTalhao;
  }

  /// Calcula custo total da prescrição
  double calcularCustoTotal() {
    return produtos.fold(0.0, (total, produto) {
      final quantidadeTotal = calcularProdutoTotal(produto);
      return total + (quantidadeTotal * produto.precoUnitario);
    });
  }

  /// Calcula custo por hectare
  double calcularCustoPorHectare() {
    return areaTalhao > 0 ? custoTotal / areaTalhao : 0.0;
  }

  /// Verifica se há estoque suficiente para todos os produtos
  bool temEstoqueSuficiente() {
    return produtos.every((produto) => produto.temEstoqueSuficiente());
  }

  /// Retorna produtos com estoque insuficiente
  List<PrescriptionProduct> produtosComEstoqueInsuficiente() {
    return produtos.where((produto) => !produto.temEstoqueSuficiente()).toList();
  }

  /// Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'area_talhao': areaTalhao,
      'tipo_aplicacao': tipoAplicacao.name,
      'equipamento': equipamento,
      'capacidade_tanque': capacidadeTanque,
      'vazao_por_hectare': vazaoPorHectare,
      'dose_fracionada': doseFracionada ? 1 : 0,
      'bico_selecionado': bicoSelecionado,
      'vazao_bico': vazaoBico,
      'pressao_bico': pressaoBico,
      'produtos': produtos.map((p) => p.toMap()).toList(),
      'data_prescricao': dataPrescricao.toIso8601String(),
      'operador': operador,
      'observacoes': observacoes,
      'status': status.name,
      'volume_total_calda': volumeTotalCalda,
      'numero_tanques': numeroTanques,
      'custo_total': custoTotal,
      'custo_por_hectare': custoPorHectare,
      'anexos': anexos,
      'data_execucao': dataExecucao?.toIso8601String(),
      'operador_execucao': operadorExecucao,
    };
  }

  /// Cria a partir de Map
  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      talhaoNome: map['talhao_nome'],
      areaTalhao: map['area_talhao']?.toDouble() ?? 0.0,
      tipoAplicacao: TipoAplicacao.values.firstWhere(
        (e) => e.name == map['tipo_aplicacao'],
        orElse: () => TipoAplicacao.terrestre,
      ),
      equipamento: map['equipamento'],
      capacidadeTanque: map['capacidade_tanque']?.toDouble() ?? 0.0,
      vazaoPorHectare: map['vazao_por_hectare']?.toDouble() ?? 0.0,
      doseFracionada: map['dose_fracionada'] == 1,
      bicoSelecionado: map['bico_selecionado'],
      vazaoBico: map['vazao_bico']?.toDouble() ?? 0.0,
      pressaoBico: map['pressao_bico']?.toDouble() ?? 0.0,
      produtos: (map['produtos'] as List<dynamic>?)
          ?.map((p) => PrescriptionProduct.fromMap(p))
          .toList() ?? [],
      dataPrescricao: DateTime.parse(map['data_prescricao']),
      operador: map['operador'],
      observacoes: map['observacoes'],
      status: StatusPrescricao.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusPrescricao.pendente,
      ),
      volumeTotalCalda: map['volume_total_calda']?.toDouble() ?? 0.0,
      numeroTanques: map['numero_tanques'] ?? 0,
      custoTotal: map['custo_total']?.toDouble() ?? 0.0,
      custoPorHectare: map['custo_por_hectare']?.toDouble() ?? 0.0,
      anexos: map['anexos'],
      dataExecucao: map['data_execucao'] != null 
          ? DateTime.parse(map['data_execucao']) 
          : null,
      operadorExecucao: map['operador_execucao'],
    );
  }

  /// Cria uma cópia com alterações
  PrescriptionModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    double? areaTalhao,
    TipoAplicacao? tipoAplicacao,
    String? equipamento,
    double? capacidadeTanque,
    double? vazaoPorHectare,
    bool? doseFracionada,
    String? bicoSelecionado,
    double? vazaoBico,
    double? pressaoBico,
    List<PrescriptionProduct>? produtos,
    DateTime? dataPrescricao,
    String? operador,
    String? observacoes,
    StatusPrescricao? status,
    double? volumeTotalCalda,
    int? numeroTanques,
    double? custoTotal,
    double? custoPorHectare,
    String? anexos,
    DateTime? dataExecucao,
    String? operadorExecucao,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      areaTalhao: areaTalhao ?? this.areaTalhao,
      tipoAplicacao: tipoAplicacao ?? this.tipoAplicacao,
      equipamento: equipamento ?? this.equipamento,
      capacidadeTanque: capacidadeTanque ?? this.capacidadeTanque,
      vazaoPorHectare: vazaoPorHectare ?? this.vazaoPorHectare,
      doseFracionada: doseFracionada ?? this.doseFracionada,
      bicoSelecionado: bicoSelecionado ?? this.bicoSelecionado,
      vazaoBico: vazaoBico ?? this.vazaoBico,
      pressaoBico: pressaoBico ?? this.pressaoBico,
      produtos: produtos ?? this.produtos,
      dataPrescricao: dataPrescricao ?? this.dataPrescricao,
      operador: operador ?? this.operador,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      volumeTotalCalda: volumeTotalCalda ?? this.volumeTotalCalda,
      numeroTanques: numeroTanques ?? this.numeroTanques,
      custoTotal: custoTotal ?? this.custoTotal,
      custoPorHectare: custoPorHectare ?? this.custoPorHectare,
      anexos: anexos ?? this.anexos,
      dataExecucao: dataExecucao ?? this.dataExecucao,
      operadorExecucao: operadorExecucao ?? this.operadorExecucao,
    );
  }
}

/// Modelo de produto na prescrição
class PrescriptionProduct {
  final String id;
  final String nome;
  final TipoProduto tipo;
  final String unidade;
  final double dosePorHectare;
  final double precoUnitario;
  final double estoqueAtual;
  final String categoria;
  final String? observacoes;

  PrescriptionProduct({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidade,
    required this.dosePorHectare,
    required this.precoUnitario,
    required this.estoqueAtual,
    required this.categoria,
    this.observacoes,
  });

  /// Calcula quantidade total necessária para uma área
  double calcularQuantidadeNecessaria(double area) {
    return dosePorHectare * area;
  }

  /// Calcula custo total para uma área
  double calcularCustoTotal(double area) {
    return calcularQuantidadeNecessaria(area) * precoUnitario;
  }

  /// Verifica se há estoque suficiente para uma área
  bool temEstoqueParaArea(double area) {
    return estoqueAtual >= calcularQuantidadeNecessaria(area);
  }

  /// Verifica se há estoque suficiente (para prescrição atual)
  bool temEstoqueSuficiente() {
    return estoqueAtual > 0;
  }

  /// Retorna percentual de estoque disponível
  double percentualEstoqueDisponivel(double area) {
    final necessario = calcularQuantidadeNecessaria(area);
    return necessario > 0 ? (estoqueAtual / necessario) * 100 : 0.0;
  }

  /// Getters para compatibilidade com código existente
  double get totalNecessario => dosePorHectare;
  double get custoTotal => precoUnitario;

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo.name,
      'unidade': unidade,
      'dose_por_hectare': dosePorHectare,
      'preco_unitario': precoUnitario,
      'estoque_atual': estoqueAtual,
      'categoria': categoria,
      'observacoes': observacoes,
    };
  }

  /// Cria a partir de Map
  factory PrescriptionProduct.fromMap(Map<String, dynamic> map) {
    return PrescriptionProduct(
      id: map['id'],
      nome: map['nome'],
      tipo: TipoProduto.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoProduto.defensivo,
      ),
      unidade: map['unidade'],
      dosePorHectare: map['dose_por_hectare']?.toDouble() ?? 0.0,
      precoUnitario: map['preco_unitario']?.toDouble() ?? 0.0,
      estoqueAtual: map['estoque_atual']?.toDouble() ?? 0.0,
      categoria: map['categoria'],
      observacoes: map['observacoes'],
    );
  }

  /// Cria uma cópia com alterações
  PrescriptionProduct copyWith({
    String? id,
    String? nome,
    TipoProduto? tipo,
    String? unidade,
    double? dosePorHectare,
    double? precoUnitario,
    double? estoqueAtual,
    String? categoria,
    String? observacoes,
  }) {
    return PrescriptionProduct(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      unidade: unidade ?? this.unidade,
      dosePorHectare: dosePorHectare ?? this.dosePorHectare,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      categoria: categoria ?? this.categoria,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

/// Modelo de bico de pulverização
class BicoPulverizacao {
  final String id;
  final String nome;
  final String codigo;
  final double vazaoLMin;
  final double pressaoBar;
  final String cor;
  final String descricao;
  final bool ativo;

  BicoPulverizacao({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.vazaoLMin,
    required this.pressaoBar,
    required this.cor,
    required this.descricao,
    required this.ativo,
  });

  /// Calcula vazão por hectare baseada na velocidade e espaçamento
  double calcularVazaoPorHectare(double velocidadeKmH, double espacamentoMetros) {
    // Fórmula: Vazão (L/ha) = (Vazão (L/min) * 600) / (Velocidade (km/h) * Espaçamento (m))
    return (vazaoLMin * 600) / (velocidadeKmH * espacamentoMetros);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'codigo': codigo,
      'vazao_l_min': vazaoLMin,
      'pressao_bar': pressaoBar,
      'cor': cor,
      'descricao': descricao,
      'ativo': ativo ? 1 : 0,
    };
  }

  factory BicoPulverizacao.fromMap(Map<String, dynamic> map) {
    return BicoPulverizacao(
      id: map['id'],
      nome: map['nome'],
      codigo: map['codigo'],
      vazaoLMin: map['vazao_l_min']?.toDouble() ?? 0.0,
      pressaoBar: map['pressao_bar']?.toDouble() ?? 0.0,
      cor: map['cor'],
      descricao: map['descricao'],
      ativo: map['ativo'] == 1,
    );
  }
}

/// Enums
enum TipoAplicacao {
  terrestre,
  aerea,
}

enum TipoProduto {
  defensivo,
  fertilizante,
  calcario,
  semente,
}

enum StatusPrescricao {
  pendente,
  aprovada,
  em_execucao,
  executada,
  cancelada,
}

/// Extensões para melhor usabilidade
extension TipoAplicacaoExtension on TipoAplicacao {
  String get displayName {
    switch (this) {
      case TipoAplicacao.terrestre:
        return 'Terrestre';
      case TipoAplicacao.aerea:
        return 'Aérea';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoAplicacao.terrestre:
        return Icons.agriculture;
      case TipoAplicacao.aerea:
        return Icons.flight;
    }
  }

  Color get color {
    switch (this) {
      case TipoAplicacao.terrestre:
        return Colors.green;
      case TipoAplicacao.aerea:
        return Colors.blue;
    }
  }
}

extension TipoProdutoExtension on TipoProduto {
  String get displayName {
    switch (this) {
      case TipoProduto.defensivo:
        return 'Defensivo';
      case TipoProduto.fertilizante:
        return 'Fertilizante';
      case TipoProduto.calcario:
        return 'Calcário';
      case TipoProduto.semente:
        return 'Semente';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoProduto.defensivo:
        return Icons.science;
      case TipoProduto.fertilizante:
        return Icons.eco;
      case TipoProduto.calcario:
        return Icons.landscape;
      case TipoProduto.semente:
        return Icons.grass;
    }
  }

  Color get color {
    switch (this) {
      case TipoProduto.defensivo:
        return Colors.red;
      case TipoProduto.fertilizante:
        return Colors.green;
      case TipoProduto.calcario:
        return Colors.brown;
      case TipoProduto.semente:
        return Colors.orange;
    }
  }
}

extension StatusPrescricaoExtension on StatusPrescricao {
  String get displayName {
    switch (this) {
      case StatusPrescricao.pendente:
        return 'Pendente';
      case StatusPrescricao.aprovada:
        return 'Aprovada';
      case StatusPrescricao.em_execucao:
        return 'Em Execução';
      case StatusPrescricao.executada:
        return 'Executada';
      case StatusPrescricao.cancelada:
        return 'Cancelada';
    }
  }

  IconData get icon {
    switch (this) {
      case StatusPrescricao.pendente:
        return Icons.schedule;
      case StatusPrescricao.aprovada:
        return Icons.check_circle;
      case StatusPrescricao.em_execucao:
        return Icons.play_circle;
      case StatusPrescricao.executada:
        return Icons.done_all;
      case StatusPrescricao.cancelada:
        return Icons.cancel;
    }
  }

  Color get color {
    switch (this) {
      case StatusPrescricao.pendente:
        return Colors.orange;
      case StatusPrescricao.aprovada:
        return Colors.green;
      case StatusPrescricao.em_execucao:
        return Colors.blue;
      case StatusPrescricao.executada:
        return Colors.purple;
      case StatusPrescricao.cancelada:
        return Colors.red;
    }
  }
}
