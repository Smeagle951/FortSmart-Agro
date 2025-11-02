class RegulagemPlantadeiraModel {
  final int? id;
  final String nome;
  final int numFurosDisco;
  final int engrenagemMotora;
  final int engrenagemMovida;
  final double distanciaPercorrida;
  final int? numLinhas;
  final double sementePorMetro;
  final double populacaoEstimada;
  final double relacaoTransmissao;
  final String? ajusteSugerido;
  final String? observacoes;
  final DateTime dataRegulagem;
  final DateTime createdAt;

  RegulagemPlantadeiraModel({
    this.id,
    required this.nome,
    required this.numFurosDisco,
    required this.engrenagemMotora,
    required this.engrenagemMovida,
    required this.distanciaPercorrida,
    this.numLinhas,
    required this.sementePorMetro,
    required this.populacaoEstimada,
    required this.relacaoTransmissao,
    this.ajusteSugerido,
    this.observacoes,
    required this.dataRegulagem,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'num_furos_disco': numFurosDisco,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
      'distancia_percorrida': distanciaPercorrida,
      'num_linhas': numLinhas,
      'semente_por_metro': sementePorMetro,
      'populacao_estimada': populacaoEstimada,
      'relacao_transmissao': relacaoTransmissao,
      'ajuste_sugerido': ajusteSugerido,
      'observacoes': observacoes,
      'data_regulagem': dataRegulagem.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RegulagemPlantadeiraModel.fromMap(Map<String, dynamic> map) {
    return RegulagemPlantadeiraModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      numFurosDisco: map['num_furos_disco'] ?? 0,
      engrenagemMotora: map['engrenagem_motora'] ?? 0,
      engrenagemMovida: map['engrenagem_movida'] ?? 0,
      distanciaPercorrida: (map['distancia_percorrida'] ?? 0).toDouble(),
      numLinhas: map['num_linhas'],
      sementePorMetro: (map['semente_por_metro'] ?? 0).toDouble(),
      populacaoEstimada: (map['populacao_estimada'] ?? 0).toDouble(),
      relacaoTransmissao: (map['relacao_transmissao'] ?? 0).toDouble(),
      ajusteSugerido: map['ajuste_sugerido'],
      observacoes: map['observacoes'],
      dataRegulagem: map['data_regulagem'] != null 
          ? DateTime.parse(map['data_regulagem']) 
          : DateTime.now(),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  /// Calcula a quantidade de sementes por metro
  static double calcularSementesPorMetro(double populacao, double espacamento) {
    // Sementes por metro = (População / 10000) * Espaçamento entre linhas
    return (populacao / 10000) * espacamento;
  }

  /// Calcula a velocidade ideal para plantio
  static double calcularVelocidadeIdeal(String tipoDisco, double populacao) {
    // Cálculo simplificado - na implementação real, precisaria considerar mais fatores
    // Este é apenas um exemplo
    double velocidadeBase = 5.0; // km/h
    
    if (populacao > 80000) {
      velocidadeBase -= 0.5;
    } else if (populacao < 50000) {
      velocidadeBase += 0.5;
    }
    
    // Ajuste pelo tipo de disco
    if (tipoDisco.contains('Precision') || tipoDisco.contains('Precisão')) {
      velocidadeBase += 1.0;
    }
    
    return velocidadeBase;
  }

  RegulagemPlantadeiraModel copyWith({
    int? id,
    String? nome,
    int? numFurosDisco,
    int? engrenagemMotora,
    int? engrenagemMovida,
    double? distanciaPercorrida,
    int? numLinhas,
    double? sementePorMetro,
    double? populacaoEstimada,
    double? relacaoTransmissao,
    String? ajusteSugerido,
    String? observacoes,
    DateTime? dataRegulagem,
    DateTime? createdAt,
  }) {
    return RegulagemPlantadeiraModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      numFurosDisco: numFurosDisco ?? this.numFurosDisco,
      engrenagemMotora: engrenagemMotora ?? this.engrenagemMotora,
      engrenagemMovida: engrenagemMovida ?? this.engrenagemMovida,
      distanciaPercorrida: distanciaPercorrida ?? this.distanciaPercorrida,
      numLinhas: numLinhas ?? this.numLinhas,
      sementePorMetro: sementePorMetro ?? this.sementePorMetro,
      populacaoEstimada: populacaoEstimada ?? this.populacaoEstimada,
      relacaoTransmissao: relacaoTransmissao ?? this.relacaoTransmissao,
      ajusteSugerido: ajusteSugerido ?? this.ajusteSugerido,
      observacoes: observacoes ?? this.observacoes,
      dataRegulagem: dataRegulagem ?? this.dataRegulagem,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
