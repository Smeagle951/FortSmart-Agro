class CalibragemAduboModel {
  final int? id;
  final String nome;
  final DateTime dataRegulagem;
  final bool coletaPorLinha; // true = gramas por linha, false = gramas em todas as linhas
  final double gramasColetadas;
  final double distanciaPercorrida; // em metros
  final int numeroLinhas;
  final double espacamentoEntreLinhas; // em cm
  final double valorDesejado; // em kg/ha ou sacas/ha
  final bool usaUnidadeSacas; // true = sacas/ha, false = kg/ha
  final int engrenagemMotora;
  final int engrenagemMovida;
  
  // Campos para integração com outros módulos
  final String? talhaoId;
  final String? culturaId;
  
  // Resultados calculados
  final double kgPorHa;
  final double sacasPorHa;
  final double erroPorcentagem; // em relação à meta
  
  // Metadados
  final DateTime createdAt;

  CalibragemAduboModel({
    this.id,
    required this.nome,
    required this.dataRegulagem,
    required this.coletaPorLinha,
    required this.gramasColetadas,
    required this.distanciaPercorrida,
    required this.numeroLinhas,
    required this.espacamentoEntreLinhas,
    required this.valorDesejado,
    required this.usaUnidadeSacas,
    required this.engrenagemMotora,
    required this.engrenagemMovida,
    required this.kgPorHa,
    required this.sacasPorHa,
    required this.erroPorcentagem,
    this.talhaoId,
    this.culturaId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data_regulagem': dataRegulagem.toIso8601String(),
      'coleta_por_linha': coletaPorLinha ? 1 : 0,
      'gramas_coletadas': gramasColetadas,
      'distancia_percorrida': distanciaPercorrida,
      'numero_linhas': numeroLinhas,
      'espacamento_entre_linhas': espacamentoEntreLinhas,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'valor_desejado': valorDesejado,
      'usa_unidade_sacas': usaUnidadeSacas ? 1 : 0,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
      'kg_por_ha': kgPorHa,
      'sacas_por_ha': sacasPorHa,
      'erro_porcentagem': erroPorcentagem,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CalibragemAduboModel.fromMap(Map<String, dynamic> map) {
    return CalibragemAduboModel(
      id: map['id'],
      nome: map['nome'],
      dataRegulagem: DateTime.parse(map['data_regulagem']),
      coletaPorLinha: map['coleta_por_linha'] == 1,
      gramasColetadas: map['gramas_coletadas'],
      distanciaPercorrida: map['distancia_percorrida'],
      numeroLinhas: map['numero_linhas'],
      espacamentoEntreLinhas: map['espacamento_entre_linhas'],
      valorDesejado: map['valor_desejado'],
      usaUnidadeSacas: map['usa_unidade_sacas'] == 1,
      engrenagemMotora: map['engrenagem_motora'],
      engrenagemMovida: map['engrenagem_movida'],
      kgPorHa: map['kg_por_ha'],
      sacasPorHa: map['sacas_por_ha'],
      erroPorcentagem: map['erro_porcentagem'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Calcula a área percorrida em hectares
  static double calcularAreaPercorrida(double distancia, int numeroLinhas, double espacamentoEntreLinhas) {
    // Área percorrida (m²) = distância (m) × (nº de linhas × espaçamento entre linhas (cm) / 100)
    double areaPercorridaM2 = distancia * (numeroLinhas * espacamentoEntreLinhas / 100);
    // Área em hectares = m² / 10.000
    return areaPercorridaM2 / 10000;
  }

  /// Calcula a quantidade de adubo aplicado em kg/ha
  static double calcularKgPorHa(double gramasColetadas, bool coletaPorLinha, int numeroLinhas, double areaPercorridaHa) {
    if (areaPercorridaHa == 0) return 0;
    
    // Se a coleta foi por linha, multiplica pelo número de linhas
    double totalGramas = coletaPorLinha ? gramasColetadas * numeroLinhas : gramasColetadas;
    
    // Converte gramas para kg
    double totalKg = totalGramas / 1000;
    
    // kg/ha = total em kg / área em hectares
    return totalKg / areaPercorridaHa;
  }

  /// Converte kg/ha para sacas/ha (1 saca = 50kg por padrão)
  static double calcularSacasPorHa(double kgPorHa, [double pesoDaSaca = 50.0]) {
    return kgPorHa / pesoDaSaca;
  }

  /// Calcula o erro percentual em relação à meta
  static double calcularErroPorcentagem(double valorAtual, double valorDesejado, bool emSacas) {
    // Certifica-se de estar comparando na mesma unidade
    double valorAtualComparado = emSacas ? valorAtual : valorAtual; // já está em kg/ha
    double valorDesejadoComparado = valorDesejado;
    
    // Erro = ((Real - Desejado) / Desejado) * 100
    return ((valorAtualComparado - valorDesejadoComparado) / valorDesejadoComparado) * 100;
  }
}
