import 'dart:convert';

/// Modelo para representar um cálculo de sementes
class SeedCalculation {
  final int? id;
  final int talhaoId;
  final int culturaId;
  final int variedadeId;
  final double populacao;
  final double pesoMilSementes;
  final double germinacao;
  final double pureza;
  final String tipoCalculo; // 'hectare' ou 'metro'
  final double resultadoKgHectare;
  final double resultadoSementeMetro;
  final String? observacoes;
  final String? fotos;
  final String dataCalculo;
  final String createdAt;
  
  // Propriedades adicionais para compatibilidade com código existente
  String get nome => "Cálculo de Sementes - ${dataCalculo}";
  double get resultadoSementesMetro => resultadoSementeMetro;
  double get resultadoKgHa => resultadoKgHectare;

  SeedCalculation({
    this.id,
    required this.talhaoId,
    required this.culturaId,
    required this.variedadeId,
    required this.populacao,
    required this.pesoMilSementes,
    required this.germinacao,
    required this.pureza,
    required this.tipoCalculo,
    required this.resultadoKgHectare,
    required this.resultadoSementeMetro,
    this.observacoes,
    this.fotos,
    String? dataCalculo,
    String? createdAt,
  }) : 
      this.dataCalculo = dataCalculo ?? DateTime.now().toIso8601String(),
      this.createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'populacao': populacao,
      'peso_mil_sementes': pesoMilSementes,
      'germinacao': germinacao,
      'pureza': pureza,
      'tipo_calculo': tipoCalculo,
      'resultado_kg_hectare': resultadoKgHectare,
      'resultado_semente_metro': resultadoSementeMetro,
      'observacoes': observacoes,
      'fotos': fotos,
      'data_calculo': dataCalculo,
      'created_at': createdAt,
    };
  }

  factory SeedCalculation.fromMap(Map<String, dynamic> map) {
    return SeedCalculation(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      populacao: map['populacao']?.toDouble() ?? 0.0,
      pesoMilSementes: map['peso_mil_sementes']?.toDouble() ?? 0.0,
      germinacao: map['germinacao']?.toDouble() ?? 0.0,
      pureza: map['pureza']?.toDouble() ?? 0.0,
      tipoCalculo: map['tipo_calculo'] ?? 'hectare',
      resultadoKgHectare: map['resultado_kg_hectare']?.toDouble() ?? 0.0,
      resultadoSementeMetro: map['resultado_semente_metro']?.toDouble() ?? 0.0,
      observacoes: map['observacoes'],
      fotos: map['fotos'],
      dataCalculo: map['data_calculo'],
      createdAt: map['created_at'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SeedCalculation.fromJson(String source) => 
      SeedCalculation.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SeedCalculation(id: $id, talhaoId: $talhaoId, culturaId: $culturaId, variedadeId: $variedadeId, populacao: $populacao, pesoMilSementes: $pesoMilSementes, germinacao: $germinacao, pureza: $pureza, tipoCalculo: $tipoCalculo, resultadoKgHectare: $resultadoKgHectare, resultadoSementeMetro: $resultadoSementeMetro)';
  }

  /// Cálculo por hectare: (População * PMS * 100) / (Germinação * Pureza * 1000)
  static double calcularKgPorHectare(
      double populacao, double pesoMilSementes, double germinacao, double pureza) {
    // Verificar para evitar divisão por zero
    if (germinacao <= 0 || pureza <= 0) {
      return 0;
    }
    return (populacao * pesoMilSementes * 100) / (germinacao * pureza * 1000);
  }

  /// Cálculo de sementes por metro: (População / 10000) * Espaçamento em cm
  static double calcularSementesPorMetro(
      double populacao, double espacamento) {
    return (populacao / 10000) * espacamento;
  }

  /// Cálculo completo com base nos parâmetros
  static Map<String, double> calcular({
    required double populacao,
    required double pesoMilSementes,
    required double germinacao,
    required double pureza,
    double espacamento = 50, // espaçamento padrão em cm se não for fornecido
  }) {
    final kgPorHectare = calcularKgPorHectare(
        populacao, pesoMilSementes, germinacao, pureza);
    final sementesPorMetro = calcularSementesPorMetro(populacao, espacamento);

    return {
      'kg_por_hectare': kgPorHectare,
      'sementes_por_metro': sementesPorMetro,
    };
  }

  SeedCalculation copyWith({
    int? id,
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    double? populacao,
    double? pesoMilSementes,
    double? germinacao,
    double? pureza,
    String? tipoCalculo,
    double? resultadoKgHectare,
    double? resultadoSementeMetro,
    String? observacoes,
    String? fotos,
    String? dataCalculo,
    String? createdAt,
  }) {
    return SeedCalculation(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      populacao: populacao ?? this.populacao,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      germinacao: germinacao ?? this.germinacao,
      pureza: pureza ?? this.pureza,
      tipoCalculo: tipoCalculo ?? this.tipoCalculo,
      resultadoKgHectare: resultadoKgHectare ?? this.resultadoKgHectare,
      resultadoSementeMetro: resultadoSementeMetro ?? this.resultadoSementeMetro,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      dataCalculo: dataCalculo ?? this.dataCalculo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
