import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo para Prescrição Agronômica Premium
class PrescricaoModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String? fazendaId;
  final String culturaId;
  final String culturaNome;
  final DateTime data;
  final String responsavelId;
  final String responsavelNome;
  final String tipoAplicacao; // Terrestre, Aérea, Drone
  final double volumeLHa;
  final double capacidadeTanqueL;
  final double volumeSegurancaL;
  final double areaTrabalhoHa;
  final String? observacoes;
  final String status; // Rascunho, Calculada, Finalizada, Executada
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Condições ambientais
  final double? temperatura;
  final double? umidade;
  final double? velocidadeVento;
  final String? horarioAplicacao;
  
  // Calibração
  final CalibracaoModel? calibracao;
  
  // Produtos
  final List<PrescricaoProdutoModel> produtos;
  
  // Resultados calculados
  final ResultadosCalculoModel? resultados;
  
  // Totais
  final TotaisPrescricaoModel? totais;

  PrescricaoModel({
    String? id,
    required this.talhaoId,
    required this.talhaoNome,
    this.fazendaId,
    required this.culturaId,
    required this.culturaNome,
    required this.data,
    required this.responsavelId,
    required this.responsavelNome,
    required this.tipoAplicacao,
    required this.volumeLHa,
    required this.capacidadeTanqueL,
    required this.volumeSegurancaL,
    required this.areaTrabalhoHa,
    this.observacoes,
    this.status = 'Rascunho',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.temperatura,
    this.umidade,
    this.velocidadeVento,
    this.horarioAplicacao,
    this.calibracao,
    List<PrescricaoProdutoModel>? produtos,
    this.resultados,
    this.totais,
  })  : id = id ?? const Uuid().v4(),
        produtos = produtos ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Cria uma cópia do objeto com os campos atualizados
  PrescricaoModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    DateTime? data,
    String? responsavelId,
    String? responsavelNome,
    String? tipoAplicacao,
    double? volumeLHa,
    double? capacidadeTanqueL,
    double? volumeSegurancaL,
    double? areaTrabalhoHa,
    String? observacoes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? temperatura,
    double? umidade,
    double? velocidadeVento,
    String? horarioAplicacao,
    CalibracaoModel? calibracao,
    List<PrescricaoProdutoModel>? produtos,
    ResultadosCalculoModel? resultados,
    TotaisPrescricaoModel? totais,
  }) {
    return PrescricaoModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      data: data ?? this.data,
      responsavelId: responsavelId ?? this.responsavelId,
      responsavelNome: responsavelNome ?? this.responsavelNome,
      tipoAplicacao: tipoAplicacao ?? this.tipoAplicacao,
      volumeLHa: volumeLHa ?? this.volumeLHa,
      capacidadeTanqueL: capacidadeTanqueL ?? this.capacidadeTanqueL,
      volumeSegurancaL: volumeSegurancaL ?? this.volumeSegurancaL,
      areaTrabalhoHa: areaTrabalhoHa ?? this.areaTrabalhoHa,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      temperatura: temperatura ?? this.temperatura,
      umidade: umidade ?? this.umidade,
      velocidadeVento: velocidadeVento ?? this.velocidadeVento,
      horarioAplicacao: horarioAplicacao ?? this.horarioAplicacao,
      calibracao: calibracao ?? this.calibracao,
      produtos: produtos ?? this.produtos,
      resultados: resultados ?? this.resultados,
      totais: totais ?? this.totais,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'fazenda_id': fazendaId ?? '',
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'data': data.toIso8601String(),
      'responsavel_id': responsavelId,
      'responsavel_nome': responsavelNome,
      'tipo_aplicacao': tipoAplicacao,
      'volume_l_ha': volumeLHa,
      'capacidade_tanque_l': capacidadeTanqueL,
      'volume_seguranca_l': volumeSegurancaL,
      'area_trabalho_ha': areaTrabalhoHa,
      'observacoes': observacoes ?? '',
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'temperatura': temperatura,
      'umidade': umidade,
      'velocidade_vento': velocidadeVento,
      'horario_aplicacao': horarioAplicacao ?? '',
      'calibracao': calibracao?.toMap() != null ? jsonEncode(calibracao!.toMap()) : null,
      'produtos': jsonEncode(produtos.map((p) => p.toMap()).toList()),
      'resultados': resultados?.toMap() != null ? jsonEncode(resultados!.toMap()) : null,
      'totais': totais?.toMap() != null ? jsonEncode(totais!.toMap()) : null,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory PrescricaoModel.fromMap(Map<String, dynamic> map) {
    return PrescricaoModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      talhaoNome: map['talhao_nome'],
      fazendaId: map['fazenda_id'],
      culturaId: map['cultura_id'],
      culturaNome: map['cultura_nome'],
      data: DateTime.parse(map['data']),
      responsavelId: map['responsavel_id'],
      responsavelNome: map['responsavel_nome'],
      tipoAplicacao: map['tipo_aplicacao'],
      volumeLHa: map['volume_l_ha'],
      capacidadeTanqueL: map['capacidade_tanque_l'],
      volumeSegurancaL: map['volume_seguranca_l'],
      areaTrabalhoHa: map['area_trabalho_ha'],
      observacoes: map['observacoes'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      temperatura: map['temperatura'],
      umidade: map['umidade'],
      velocidadeVento: map['velocidade_vento'],
      horarioAplicacao: map['horario_aplicacao'],
      calibracao: map['calibracao'] != null ? CalibracaoModel.fromMap(map['calibracao']) : null,
      produtos: List<PrescricaoProdutoModel>.from(
        map['produtos']?.map((x) => PrescricaoProdutoModel.fromMap(x)) ?? [],
      ),
      resultados: map['resultados'] != null ? ResultadosCalculoModel.fromMap(map['resultados']) : null,
      totais: map['totais'] != null ? TotaisPrescricaoModel.fromMap(map['totais']) : null,
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory PrescricaoModel.fromJson(String source) => PrescricaoModel.fromMap(jsonDecode(source));

  /// Calcula a capacidade efetiva do tanque
  double get capacidadeEfetivaL => capacidadeTanqueL - volumeSegurancaL;

  /// Verifica se a prescrição está pronta para cálculo
  bool get isReadyForCalculation {
    return talhaoId.isNotEmpty &&
           volumeLHa > 0 &&
           capacidadeTanqueL > 0 &&
           areaTrabalhoHa > 0 &&
           produtos.isNotEmpty;
  }

  /// Verifica se a prescrição pode ser finalizada
  bool get canBeFinalized {
    return status == 'Calculada' && resultados != null && totais != null;
  }
}

/// Modelo para dados de calibração
class CalibracaoModel {
  final String modoCalculo; // 'vazao_bico' ou 'volume_alvo'
  final int bicosAtivos;
  final double espacamentoM;
  final double larguraM;
  final double velocidadeKmh;
  final double? pressao;
  final double? vazaoBicoLMin;
  final double? vazaoTotalLMin;
  final double eficienciaCampo;
  final String? equipamento;
  final String? marcaModelo;

  CalibracaoModel({
    required this.modoCalculo,
    required this.bicosAtivos,
    required this.espacamentoM,
    required this.larguraM,
    required this.velocidadeKmh,
    this.pressao,
    this.vazaoBicoLMin,
    this.vazaoTotalLMin,
    this.eficienciaCampo = 0.85,
    this.equipamento,
    this.marcaModelo,
  });

  /// Cria uma cópia do objeto com os campos atualizados
  CalibracaoModel copyWith({
    String? modoCalculo,
    int? bicosAtivos,
    double? espacamentoM,
    double? larguraM,
    double? velocidadeKmh,
    double? pressao,
    double? vazaoBicoLMin,
    double? vazaoTotalLMin,
    double? eficienciaCampo,
    String? equipamento,
    String? marcaModelo,
  }) {
    return CalibracaoModel(
      modoCalculo: modoCalculo ?? this.modoCalculo,
      bicosAtivos: bicosAtivos ?? this.bicosAtivos,
      espacamentoM: espacamentoM ?? this.espacamentoM,
      larguraM: larguraM ?? this.larguraM,
      velocidadeKmh: velocidadeKmh ?? this.velocidadeKmh,
      pressao: pressao ?? this.pressao,
      vazaoBicoLMin: vazaoBicoLMin ?? this.vazaoBicoLMin,
      vazaoTotalLMin: vazaoTotalLMin ?? this.vazaoTotalLMin,
      eficienciaCampo: eficienciaCampo ?? this.eficienciaCampo,
      equipamento: equipamento ?? this.equipamento,
      marcaModelo: marcaModelo ?? this.marcaModelo,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'modo_calculo': modoCalculo,
      'bicos_ativos': bicosAtivos,
      'espacamento_m': espacamentoM,
      'largura_m': larguraM,
      'velocidade_kmh': velocidadeKmh,
      'pressao': pressao,
      'vazao_bico_l_min': vazaoBicoLMin,
      'vazao_total_l_min': vazaoTotalLMin,
      'eficiencia_campo': eficienciaCampo,
      'equipamento': equipamento,
      'marca_modelo': marcaModelo,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory CalibracaoModel.fromMap(Map<String, dynamic> map) {
    return CalibracaoModel(
      modoCalculo: map['modo_calculo'],
      bicosAtivos: map['bicos_ativos'],
      espacamentoM: map['espacamento_m'],
      larguraM: map['largura_m'],
      velocidadeKmh: map['velocidade_kmh'],
      pressao: map['pressao'],
      vazaoBicoLMin: map['vazao_bico_l_min'],
      vazaoTotalLMin: map['vazao_total_l_min'],
      eficienciaCampo: map['eficiencia_campo'] ?? 0.85,
      equipamento: map['equipamento'],
      marcaModelo: map['marca_modelo'],
    );
  }

  /// Calcula a largura da barra automaticamente
  double get larguraCalculadaM => bicosAtivos * espacamentoM;

  /// Calcula a vazão total se não fornecida
  double get vazaoTotalCalculadaLMin {
    if (vazaoTotalLMin != null) return vazaoTotalLMin!;
    if (vazaoBicoLMin != null) return vazaoBicoLMin! * bicosAtivos;
    return 0;
  }

  /// Calcula o volume teórico (L/ha)
  double calcularVolumeTeoricoLHa() {
    if (vazaoTotalCalculadaLMin <= 0 || velocidadeKmh <= 0 || larguraM <= 0) {
      return 0;
    }
    return (600 * vazaoTotalCalculadaLMin) / (velocidadeKmh * larguraM);
  }

  /// Calcula a vazão por bico necessária para um volume alvo
  double calcularVazaoBicoNecessariaLMin(double volumeAlvoLHa) {
    if (velocidadeKmh <= 0 || espacamentoM <= 0) {
      return 0;
    }
    return (volumeAlvoLHa * velocidadeKmh * espacamentoM) / 600;
  }
}

/// Modelo para produtos da prescrição
class PrescricaoProdutoModel {
  final String id;
  final String produtoId;
  final String produtoNome;
  final String unidade; // L/ha, mL/ha, kg/ha, g/ha, % v/v, % m/v
  final double dosePorHa;
  final double? densidade; // kg/L para líquidos
  final double? percentualVv; // Para adjuvantes
  final double? custoUnitario;
  final String? loteId;
  final String? loteCodigo;
  final double? estoqueDisponivel;
  final String? observacoes;
  final bool isAdjuvante;

  // Valores calculados
  final double? quantidadeTotal;
  final double? quantidadePorTanque;
  final double? quantidadeUltimoTanque;

  PrescricaoProdutoModel({
    String? id,
    required this.produtoId,
    required this.produtoNome,
    required this.unidade,
    required this.dosePorHa,
    this.densidade,
    this.percentualVv,
    this.custoUnitario,
    this.loteId,
    this.loteCodigo,
    this.estoqueDisponivel,
    this.observacoes,
    this.isAdjuvante = false,
    this.quantidadeTotal,
    this.quantidadePorTanque,
    this.quantidadeUltimoTanque,
  }) : id = id ?? const Uuid().v4();

  /// Cria uma cópia do objeto com os campos atualizados
  PrescricaoProdutoModel copyWith({
    String? id,
    String? produtoId,
    String? produtoNome,
    String? unidade,
    double? dosePorHa,
    double? densidade,
    double? percentualVv,
    double? custoUnitario,
    String? loteId,
    String? loteCodigo,
    double? estoqueDisponivel,
    String? observacoes,
    bool? isAdjuvante,
    double? quantidadeTotal,
    double? quantidadePorTanque,
    double? quantidadeUltimoTanque,
  }) {
    return PrescricaoProdutoModel(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      produtoNome: produtoNome ?? this.produtoNome,
      unidade: unidade ?? this.unidade,
      dosePorHa: dosePorHa ?? this.dosePorHa,
      densidade: densidade ?? this.densidade,
      percentualVv: percentualVv ?? this.percentualVv,
      custoUnitario: custoUnitario ?? this.custoUnitario,
      loteId: loteId ?? this.loteId,
      loteCodigo: loteCodigo ?? this.loteCodigo,
      estoqueDisponivel: estoqueDisponivel ?? this.estoqueDisponivel,
      observacoes: observacoes ?? this.observacoes,
      isAdjuvante: isAdjuvante ?? this.isAdjuvante,
      quantidadeTotal: quantidadeTotal ?? this.quantidadeTotal,
      quantidadePorTanque: quantidadePorTanque ?? this.quantidadePorTanque,
      quantidadeUltimoTanque: quantidadeUltimoTanque ?? this.quantidadeUltimoTanque,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto_id': produtoId,
      'produto_nome': produtoNome,
      'unidade': unidade,
      'dose_por_ha': dosePorHa,
      'densidade': densidade ?? 0.0,
      'percentual_vv': percentualVv ?? 0.0,
      'custo_unitario': custoUnitario ?? 0.0,
      'lote_id': loteId ?? '',
      'lote_codigo': loteCodigo ?? '',
      'estoque_disponivel': estoqueDisponivel ?? 0.0,
      'observacoes': observacoes ?? '',
      'is_adjuvante': isAdjuvante ? 1 : 0, // Converter bool para int
      'quantidade_total': quantidadeTotal ?? 0.0,
      'quantidade_por_tanque': quantidadePorTanque ?? 0.0,
      'quantidade_ultimo_tanque': quantidadeUltimoTanque ?? 0.0,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory PrescricaoProdutoModel.fromMap(Map<String, dynamic> map) {
    return PrescricaoProdutoModel(
      id: map['id'],
      produtoId: map['produto_id'],
      produtoNome: map['produto_nome'],
      unidade: map['unidade'],
      dosePorHa: map['dose_por_ha'],
      densidade: map['densidade'],
      percentualVv: map['percentual_vv'],
      custoUnitario: map['custo_unitario'],
      loteId: map['lote_id'],
      loteCodigo: map['lote_codigo'],
      estoqueDisponivel: map['estoque_disponivel'],
      observacoes: map['observacoes'],
      isAdjuvante: map['is_adjuvante'] ?? false,
      quantidadeTotal: map['quantidade_total'],
      quantidadePorTanque: map['quantidade_por_tanque'],
      quantidadeUltimoTanque: map['quantidade_ultimo_tanque'],
    );
  }

  /// Calcula a quantidade total necessária
  double calcularQuantidadeTotal(double areaTrabalhoHa) {
    if (isAdjuvante && percentualVv != null) {
      // Para adjuvantes % v/v, a quantidade é calculada por tanque
      return 0; // Será calculado por tanque
    }
    return dosePorHa * areaTrabalhoHa;
  }

  /// Calcula a quantidade por tanque
  double calcularQuantidadePorTanque(double haPorTanque, double volumeCaldaPorTanqueL) {
    if (isAdjuvante && percentualVv != null) {
      return (percentualVv! / 100) * volumeCaldaPorTanqueL;
    }
    return dosePorHa * haPorTanque;
  }

  /// Verifica se há estoque suficiente
  bool get temEstoqueSuficiente {
    if (estoqueDisponivel == null) return true;
    if (quantidadeTotal == null) return true;
    return estoqueDisponivel! >= quantidadeTotal!;
  }
}

/// Modelo para resultados do cálculo
class ResultadosCalculoModel {
  final double haPorTanque;
  final int numeroTanques;
  final double volumePorTanqueL;
  final double vazaoTotalLMin;
  final double tempoPorTanqueMin;
  final double tempoTotalH;
  final double capacidadeCampoHaH;
  final double eficienciaCampo;

  ResultadosCalculoModel({
    required this.haPorTanque,
    required this.numeroTanques,
    required this.volumePorTanqueL,
    required this.vazaoTotalLMin,
    required this.tempoPorTanqueMin,
    required this.tempoTotalH,
    required this.capacidadeCampoHaH,
    required this.eficienciaCampo,
  });

  /// Cria uma cópia do objeto com os campos atualizados
  ResultadosCalculoModel copyWith({
    double? haPorTanque,
    int? numeroTanques,
    double? volumePorTanqueL,
    double? vazaoTotalLMin,
    double? tempoPorTanqueMin,
    double? tempoTotalH,
    double? capacidadeCampoHaH,
    double? eficienciaCampo,
  }) {
    return ResultadosCalculoModel(
      haPorTanque: haPorTanque ?? this.haPorTanque,
      numeroTanques: numeroTanques ?? this.numeroTanques,
      volumePorTanqueL: volumePorTanqueL ?? this.volumePorTanqueL,
      vazaoTotalLMin: vazaoTotalLMin ?? this.vazaoTotalLMin,
      tempoPorTanqueMin: tempoPorTanqueMin ?? this.tempoPorTanqueMin,
      tempoTotalH: tempoTotalH ?? this.tempoTotalH,
      capacidadeCampoHaH: capacidadeCampoHaH ?? this.capacidadeCampoHaH,
      eficienciaCampo: eficienciaCampo ?? this.eficienciaCampo,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'ha_por_tanque': haPorTanque,
      'numero_tanques': numeroTanques,
      'volume_por_tanque_l': volumePorTanqueL,
      'vazao_total_l_min': vazaoTotalLMin,
      'tempo_por_tanque_min': tempoPorTanqueMin,
      'tempo_total_h': tempoTotalH,
      'capacidade_campo_ha_h': capacidadeCampoHaH,
      'eficiencia_campo': eficienciaCampo,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory ResultadosCalculoModel.fromMap(Map<String, dynamic> map) {
    return ResultadosCalculoModel(
      haPorTanque: map['ha_por_tanque'],
      numeroTanques: map['numero_tanques'],
      volumePorTanqueL: map['volume_por_tanque_l'],
      vazaoTotalLMin: map['vazao_total_l_min'],
      tempoPorTanqueMin: map['tempo_por_tanque_min'],
      tempoTotalH: map['tempo_total_h'],
      capacidadeCampoHaH: map['capacidade_campo_ha_h'],
      eficienciaCampo: map['eficiencia_campo'],
    );
  }
}

/// Modelo para totais da prescrição
class TotaisPrescricaoModel {
  final double custoPorHa;
  final double custoTotal;
  final double volumeTotalCaldaL;
  final Map<String, double> custosPorProduto;

  TotaisPrescricaoModel({
    required this.custoPorHa,
    required this.custoTotal,
    required this.volumeTotalCaldaL,
    required this.custosPorProduto,
  });

  /// Cria uma cópia do objeto com os campos atualizados
  TotaisPrescricaoModel copyWith({
    double? custoPorHa,
    double? custoTotal,
    double? volumeTotalCaldaL,
    Map<String, double>? custosPorProduto,
  }) {
    return TotaisPrescricaoModel(
      custoPorHa: custoPorHa ?? this.custoPorHa,
      custoTotal: custoTotal ?? this.custoTotal,
      volumeTotalCaldaL: volumeTotalCaldaL ?? this.volumeTotalCaldaL,
      custosPorProduto: custosPorProduto ?? this.custosPorProduto,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'custo_por_ha': custoPorHa,
      'custo_total': custoTotal,
      'volume_total_calda_l': volumeTotalCaldaL,
      'custos_por_produto': custosPorProduto,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory TotaisPrescricaoModel.fromMap(Map<String, dynamic> map) {
    return TotaisPrescricaoModel(
      custoPorHa: map['custo_por_ha'],
      custoTotal: map['custo_total'],
      volumeTotalCaldaL: map['volume_total_calda_l'],
      custosPorProduto: Map<String, double>.from(map['custos_por_produto'] ?? {}),
    );
  }
}
