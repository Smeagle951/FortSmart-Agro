class PerdaColheitaModel {
  final int? id;
  final int talhaoId;
  final int culturaId;
  final int variedadeId;
  final String dataPerda;
  final String metodo; // 'peso_mil_graos' ou 'peso_total'
  final int? espigas;
  final int? graosPerdidos;
  final double? pesoMilGraos;
  final double? pesoColetado;
  final double areaAmostrada;
  final double resultadoPerdaKgHa;
  final double resultadoPerdaScHa;
  final String observacoes;
  final String fotos;
  final String createdAt;

  PerdaColheitaModel({
    this.id,
    required this.talhaoId,
    required this.culturaId,
    required this.variedadeId,
    required this.dataPerda,
    required this.metodo,
    this.espigas,
    this.graosPerdidos,
    this.pesoMilGraos,
    this.pesoColetado,
    required this.areaAmostrada,
    required this.resultadoPerdaKgHa,
    required this.resultadoPerdaScHa,
    this.observacoes = '',
    this.fotos = '',
    String? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'data_perda': dataPerda,
      'metodo': metodo,
      'espigas': espigas,
      'graos_perdidos': graosPerdidos,
      'peso_mil_graos': pesoMilGraos,
      'peso_coletado': pesoColetado,
      'area_amostrada': areaAmostrada,
      'resultado_perda_kg_ha': resultadoPerdaKgHa,
      'resultado_perda_sc_ha': resultadoPerdaScHa,
      'observacoes': observacoes,
      'fotos': fotos,
      'created_at': createdAt,
    };
  }

  factory PerdaColheitaModel.fromMap(Map<String, dynamic> map) {
    return PerdaColheitaModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      dataPerda: map['data_perda'],
      metodo: map['metodo'],
      espigas: map['espigas'],
      graosPerdidos: map['graos_perdidos'],
      pesoMilGraos: map['peso_mil_graos'],
      pesoColetado: map['peso_coletado'],
      areaAmostrada: map['area_amostrada'],
      resultadoPerdaKgHa: map['resultado_perda_kg_ha'],
      resultadoPerdaScHa: map['resultado_perda_sc_ha'],
      observacoes: map['observacoes'] ?? '',
      fotos: map['fotos'] ?? '',
      createdAt: map['created_at'],
    );
  }

  PerdaColheitaModel copyWith({
    int? id,
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    String? dataPerda,
    String? metodo,
    int? espigas,
    int? graosPerdidos,
    double? pesoMilGraos,
    double? pesoColetado,
    double? areaAmostrada,
    double? resultadoPerdaKgHa,
    double? resultadoPerdaScHa,
    String? observacoes,
    String? fotos,
    String? createdAt,
  }) {
    return PerdaColheitaModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      dataPerda: dataPerda ?? this.dataPerda,
      metodo: metodo ?? this.metodo,
      espigas: espigas ?? this.espigas,
      graosPerdidos: graosPerdidos ?? this.graosPerdidos,
      pesoMilGraos: pesoMilGraos ?? this.pesoMilGraos,
      pesoColetado: pesoColetado ?? this.pesoColetado,
      areaAmostrada: areaAmostrada ?? this.areaAmostrada,
      resultadoPerdaKgHa: resultadoPerdaKgHa ?? this.resultadoPerdaKgHa,
      resultadoPerdaScHa: resultadoPerdaScHa ?? this.resultadoPerdaScHa,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Métodos para calcular a perda em kg/ha
  static double calcularPerdaMilGraos(int espigas, int graosPerdidos, double pesoMilGraos, double areaAmostrada) {
    // Cálculo: (grãos perdidos / 1000) * peso de mil grãos / área amostrada * 10000
    return (graosPerdidos / 1000) * pesoMilGraos / areaAmostrada * 10000;
  }

  static double calcularPerdaPesoTotal(double pesoColetado, double areaAmostrada) {
    // Cálculo: peso coletado / área amostrada * 10000
    return pesoColetado / areaAmostrada * 10000;
  }

  // Converter kg/ha para sacas/ha (considerando saca de 60kg)
  static double kgParaSacas(double kgHa) {
    return kgHa / 60;
  }
}
