class CalibragemSementesModel {
  final int? id;
  final String nome;
  final DateTime dataRegulagem;
  final double sementesPorMetro;
  final double sementesColetadas;
  final int? linhasColetadas;
  final double espacamentoEntreLinhas;
  final double? populacaoDesejada; // em mil plantas/ha (opcional)
  
  // Campos para disco de sementes (plantadeira a vácuo)
  final bool usaDiscoEngrenagens;
  final int? numeroFurosNoDisco;
  final int? engrenagemMotora;
  final int? engrenagemMovida;
  final int? numeroLinhasPlantadeira;
  
  // Campos para integração com outros módulos
  final String? talhaoId;
  final String? talhaoNome;
  final int? culturaId;
  final String? culturaNome;
  
  // Resultados calculados
  final double plantasPorMetro;
  final double plantasPorHectare;
  final double plantasPorMetroQuadrado;
  final double? erroPorcentagem; // em relação à meta (se informada)

  // Metadados
  final DateTime createdAt;

  CalibragemSementesModel({
    this.id,
    required this.nome,
    required this.dataRegulagem,
    required this.sementesPorMetro,
    required this.sementesColetadas,
    this.linhasColetadas,
    required this.espacamentoEntreLinhas,
    this.populacaoDesejada,
    this.usaDiscoEngrenagens = false,
    this.numeroFurosNoDisco,
    this.engrenagemMotora,
    this.engrenagemMovida,
    this.numeroLinhasPlantadeira,
    this.talhaoId,
    this.talhaoNome,
    this.culturaId,
    this.culturaNome,
    required this.plantasPorMetro,
    required this.plantasPorHectare,
    required this.plantasPorMetroQuadrado,
    this.erroPorcentagem,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data_regulagem': dataRegulagem.toIso8601String(),
      'sementes_por_metro': sementesPorMetro,
      'sementes_coletadas': sementesColetadas,
      'linhas_coletadas': linhasColetadas,
      'espacamento_entre_linhas': espacamentoEntreLinhas,
      'populacao_desejada': populacaoDesejada,
      'usa_disco_engrenagens': usaDiscoEngrenagens ? 1 : 0,
      'numero_furos_no_disco': numeroFurosNoDisco,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
      'numero_linhas_plantadeira': numeroLinhasPlantadeira,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'plantas_por_metro': plantasPorMetro,
      'plantas_por_hectare': plantasPorHectare,
      'plantas_por_metro_quadrado': plantasPorMetroQuadrado,
      'erro_porcentagem': erroPorcentagem,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CalibragemSementesModel.fromMap(Map<String, dynamic> map) {
    return CalibragemSementesModel(
      id: map['id'],
      nome: map['nome'],
      dataRegulagem: DateTime.parse(map['data_regulagem']),
      sementesPorMetro: map['sementes_por_metro'],
      sementesColetadas: map['sementes_coletadas'],
      linhasColetadas: map['linhas_coletadas'],
      espacamentoEntreLinhas: map['espacamento_entre_linhas'],
      populacaoDesejada: map['populacao_desejada'],
      usaDiscoEngrenagens: map['usa_disco_engrenagens'] == 1,
      numeroFurosNoDisco: map['numero_furos_no_disco'],
      engrenagemMotora: map['engrenagem_motora'],
      engrenagemMovida: map['engrenagem_movida'],
      numeroLinhasPlantadeira: map['numero_linhas_plantadeira'],
      talhaoId: map['talhao_id'],
      talhaoNome: map['talhao_nome'],
      culturaId: map['cultura_id'],
      culturaNome: map['cultura_nome'],
      plantasPorMetro: map['plantas_por_metro'],
      plantasPorHectare: map['plantas_por_hectare'],
      plantasPorMetroQuadrado: map['plantas_por_metro_quadrado'],
      erroPorcentagem: map['erro_porcentagem'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Calcula sementes por metro baseado nos dados coletados
  static double calcularSementesPorMetro(double sementesColetadas, int linhasColetadas) {
    if (linhasColetadas == 0) return 0;
    return sementesColetadas / linhasColetadas;
  }

  /// Calcula sementes por metro para plantadeira a vácuo
  static double calcularSementesPorMetroVacuo(int numeroFuros, int engrenagemMotora, int engrenagemMovida) {
    if (engrenagemMovida == 0) return 0;
    // Relação de Transmissão = Engrenagem motora / Engrenagem movida
    double relacaoTransmissao = engrenagemMotora / engrenagemMovida;
    // Sementes por metro = Número de furos × Relação
    return numeroFuros * relacaoTransmissao;
  }

  /// Calcula plantas por hectare
  static double calcularPlantasPorHectare(double sementesPorMetro, double espacamentoEntreLinhas) {
    // Converte espaçamento para metros (se estiver em cm)
    double espacamentoMetros = espacamentoEntreLinhas / 100;
    // Plantas/ha = sementes/m × (10.000 / espaçamento em metros)
    return sementesPorMetro * (10000 / espacamentoMetros);
  }

  /// Calcula o erro percentual em relação à meta de população
  static double calcularErroPorcentagem(double plantasPorHectare, double populacaoDesejada) {
    // Converte população desejada de mil/ha para plantas/ha
    double populacaoPlantasPorHa = populacaoDesejada * 1000;
    // Erro = ((Real - Desejado) / Desejado) * 100
    return ((plantasPorHectare - populacaoPlantasPorHa) / populacaoPlantasPorHa) * 100;
  }
}
