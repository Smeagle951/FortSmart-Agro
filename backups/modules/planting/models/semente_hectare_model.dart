class SementeHectareModel {
  final int? id;
  final int? talhaoId; // Campo adicionado para talhão
  final int culturaId;
  final int variedadeId;
  final double populacao;
  final double pesoMilSementes;
  final double germinacao;
  final double pureza;
  final double resultadoKgHectare;
  final String? observacoes;
  final DateTime dataCalculo;
  final DateTime createdAt;

  SementeHectareModel({
    this.id,
    this.talhaoId, // Adicionado como parâmetro opcional
    required this.culturaId,
    required this.variedadeId,
    required this.populacao,
    required this.pesoMilSementes,
    required this.germinacao,
    required this.pureza,
    required this.resultadoKgHectare,
    this.observacoes,
    required this.dataCalculo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId, // Adicionado ao mapa
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'populacao': populacao,
      'peso_mil_sementes': pesoMilSementes,
      'germinacao': germinacao,
      'pureza': pureza,
      'resultado_kg_hectare': resultadoKgHectare,
      'observacoes': observacoes,
      'data_calculo': dataCalculo.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SementeHectareModel.fromMap(Map<String, dynamic> map) {
    return SementeHectareModel(
      id: map['id'],
      talhaoId: map['talhao_id'], // Adicionado ao construtor
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      populacao: map['populacao'],
      pesoMilSementes: map['peso_mil_sementes'],
      germinacao: map['germinacao'],
      pureza: map['pureza'],
      resultadoKgHectare: map['resultado_kg_hectare'],
      observacoes: map['observacoes'],
      dataCalculo: DateTime.parse(map['data_calculo']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Calcula a quantidade de sementes em kg/ha
  static double calcularSementesKgHa(double populacao, double pesoMilSementes, double germinacao, double pureza) {
    // Fórmula: (População * Peso de 1000 sementes) / (Germinação * Pureza * 100)
    // População = plantas/ha
    // Peso de 1000 sementes em gramas
    // Germinação e Pureza em percentual (ex: 85 para 85%)
    
    // Converte germinação e pureza para valores decimais (ex: 85% -> 0.85)
    double germinacaoDecimal = germinacao / 100;
    double purezaDecimal = pureza / 100;
    
    // Calcula quantidade de sementes em kg/ha
    return (populacao * pesoMilSementes) / (germinacaoDecimal * purezaDecimal * 1000);
  }

  SementeHectareModel copyWith({
    int? id,
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    double? populacao,
    double? pesoMilSementes,
    double? germinacao,
    double? pureza,
    double? resultadoKgHectare,
    String? observacoes,
    DateTime? dataCalculo,
    DateTime? createdAt,
  }) {
    return SementeHectareModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      populacao: populacao ?? this.populacao,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      germinacao: germinacao ?? this.germinacao,
      pureza: pureza ?? this.pureza,
      resultadoKgHectare: resultadoKgHectare ?? this.resultadoKgHectare,
      observacoes: observacoes ?? this.observacoes,
      dataCalculo: dataCalculo ?? this.dataCalculo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
