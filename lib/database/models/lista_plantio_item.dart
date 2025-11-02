class ListaPlantioItem {
  final String id;
  final String variedade;
  final String cultura;
  final String talhaoNome;
  final String? subareaNome;
  final DateTime dataPlantio;
  final double populacaoPorM;
  final double populacaoHa;
  final double espacamentoCm;
  final double? custoHa;
  final int? dae;

  ListaPlantioItem({
    required this.id,
    required this.variedade,
    required this.cultura,
    required this.talhaoNome,
    this.subareaNome,
    required this.dataPlantio,
    required this.populacaoPorM,
    required this.populacaoHa,
    required this.espacamentoCm,
    this.custoHa,
    this.dae,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'variedade': variedade,
      'cultura': cultura,
      'talhao_nome': talhaoNome,
      'subarea_nome': subareaNome,
      'data_plantio': dataPlantio.toIso8601String(),
      'populacao_por_m': populacaoPorM,
      'populacao_ha': populacaoHa,
      'espacamento_cm': espacamentoCm,
      'custo_ha': custoHa,
      'dae': dae,
    };
  }

  factory ListaPlantioItem.fromMap(Map<String, dynamic> map) {
    return ListaPlantioItem(
      id: map['id'] as String,
      variedade: map['variedade'] as String,
      cultura: map['cultura'] as String,
      talhaoNome: map['talhao_nome'] as String,
      subareaNome: map['subarea_nome'] as String?,
      dataPlantio: DateTime.parse(map['data_plantio'] as String),
      populacaoPorM: (map['populacao_por_m'] as num).toDouble(),
      populacaoHa: (map['populacao_ha'] as num).toDouble(),
      espacamentoCm: (map['espacamento_cm'] as num).toDouble(),
      custoHa: map['custo_ha'] == null ? null : (map['custo_ha'] as num).toDouble(),
      dae: map['dae'] == null ? null : (map['dae'] as num).toInt(),
    );
  }

  ListaPlantioItem copyWith({
    String? id,
    String? variedade,
    String? cultura,
    String? talhaoNome,
    String? subareaNome,
    DateTime? dataPlantio,
    double? populacaoPorM,
    double? populacaoHa,
    double? espacamentoCm,
    double? custoHa,
    int? dae,
  }) {
    return ListaPlantioItem(
      id: id ?? this.id,
      variedade: variedade ?? this.variedade,
      cultura: cultura ?? this.cultura,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      subareaNome: subareaNome ?? this.subareaNome,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      populacaoPorM: populacaoPorM ?? this.populacaoPorM,
      populacaoHa: populacaoHa ?? this.populacaoHa,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      custoHa: custoHa ?? this.custoHa,
      dae: dae ?? this.dae,
    );
  }

  @override
  String toString() {
    return 'ListaPlantioItem(id: $id, variedade: $variedade, cultura: $cultura, talhaoNome: $talhaoNome, subareaNome: $subareaNome, dataPlantio: $dataPlantio, populacaoPorM: $populacaoPorM, populacaoHa: $populacaoHa, espacamentoCm: $espacamentoCm, custoHa: $custoHa, dae: $dae)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListaPlantioItem &&
        other.id == id &&
        other.variedade == variedade &&
        other.cultura == cultura &&
        other.talhaoNome == talhaoNome &&
        other.subareaNome == subareaNome &&
        other.dataPlantio == dataPlantio &&
        other.populacaoPorM == populacaoPorM &&
        other.populacaoHa == populacaoHa &&
        other.espacamentoCm == espacamentoCm &&
        other.custoHa == custoHa &&
        other.dae == dae;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        variedade.hashCode ^
        cultura.hashCode ^
        talhaoNome.hashCode ^
        subareaNome.hashCode ^
        dataPlantio.hashCode ^
        populacaoPorM.hashCode ^
        populacaoHa.hashCode ^
        espacamentoCm.hashCode ^
        custoHa.hashCode ^
        dae.hashCode;
  }
}
