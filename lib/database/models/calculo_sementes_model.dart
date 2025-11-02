import 'package:uuid/uuid.dart';

class CalculoSementesModel {
  final String id;
  final String? talhaoId;
  final String? safraId;
  final String? culturaId;
  final String? plantioId;
  final double espacamentoCm;
  final int? populacaoDesejada;
  final double? germinacaoPercent;
  final double? purezaPercent;
  final double? sementesPorMetro;
  final double? sementesPorHectare;
  final double? pesoMilSementes;
  final int? totalSementes;
  final double? totalKg;
  final double? kgPorHectare;          // Kg/ha sem ajuste
  final double? kgPorHectareAjustado;  // Kg/ha ajustado com germinação e pureza
  final double? kgUtilizado;           // Kg já utilizados
  final double? kgFaltando;            // Kg faltando para completar
  final double? areaHa;                // Área do talhão em hectares
  final String? status;                // Status do cálculo (ex: 'OK', 'Crítico')
  final String? origemCalculo;         // 'espacamento', 'populacao', 'sementes_metro'
  final String dataCriacao;

  CalculoSementesModel({
    required this.id,
    this.talhaoId,
    this.safraId,
    this.culturaId,
    this.plantioId,
    required this.espacamentoCm,
    this.populacaoDesejada,
    this.germinacaoPercent,
    this.purezaPercent,
    this.sementesPorMetro,
    this.sementesPorHectare,
    this.pesoMilSementes,
    this.totalSementes,
    this.totalKg,
    this.kgPorHectare,
    this.kgPorHectareAjustado,
    this.kgUtilizado,
    this.kgFaltando,
    this.areaHa,
    this.status,
    this.origemCalculo,
    required this.dataCriacao,
  });

  // Construtor para criar um novo cálculo
  factory CalculoSementesModel.novo({
    required String? talhaoId,
    required String? safraId,
    String? culturaId,
    String? plantioId,
    required double espacamentoCm,
    int? populacaoDesejada,
    double? germinacaoPercent,
    double? purezaPercent,
    double? sementesPorMetro,
    double? sementesPorHectare,
    double? pesoMilSementes,
    int? totalSementes,
    double? totalKg,
    double? kgPorHectare,
    double? kgPorHectareAjustado,
    double? kgUtilizado,
    double? kgFaltando,
    double? areaHa,
    String? status,
    String? origemCalculo,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    return CalculoSementesModel(
      id: uuid.v4(),
      talhaoId: talhaoId,
      safraId: safraId,
      culturaId: culturaId,
      plantioId: plantioId,
      espacamentoCm: espacamentoCm,
      populacaoDesejada: populacaoDesejada,
      germinacaoPercent: germinacaoPercent,
      purezaPercent: purezaPercent,
      sementesPorMetro: sementesPorMetro,
      sementesPorHectare: sementesPorHectare,
      pesoMilSementes: pesoMilSementes,
      totalSementes: totalSementes,
      totalKg: totalKg,
      kgPorHectare: kgPorHectare,
      kgPorHectareAjustado: kgPorHectareAjustado,
      kgUtilizado: kgUtilizado,
      kgFaltando: kgFaltando,
      areaHa: areaHa,
      status: status,
      origemCalculo: origemCalculo,
      dataCriacao: now.toIso8601String(),
    );
  }

  // Construtor para criar a partir de um Map (banco de dados)
  factory CalculoSementesModel.fromMap(Map<String, dynamic> map) {
    return CalculoSementesModel(
      id: map['id'],
      talhaoId: map['id_talhao'],
      safraId: map['id_safra'],
      culturaId: map['id_cultura'],
      plantioId: map['id_plantio'],
      espacamentoCm: map['espacamento_cm']?.toDouble() ?? 0.0,
      populacaoDesejada: map['populacao_desejada'],
      germinacaoPercent: map['germinacao_percent']?.toDouble(),
      purezaPercent: map['pureza_percent']?.toDouble(),
      sementesPorMetro: map['sementes_por_metro']?.toDouble(),
      sementesPorHectare: map['sementes_por_hectare']?.toDouble(),
      pesoMilSementes: map['peso_mil_sementes']?.toDouble(),
      totalSementes: map['total_sementes'],
      totalKg: map['total_kg']?.toDouble(),
      kgPorHectare: map['kg_por_hectare']?.toDouble(),
      kgPorHectareAjustado: map['kg_por_hectare_ajustado']?.toDouble(),
      kgUtilizado: map['kg_utilizado']?.toDouble(),
      kgFaltando: map['kg_faltando']?.toDouble(),
      areaHa: map['area_ha']?.toDouble(),
      status: map['status'],
      origemCalculo: map['origem_calculo'],
      dataCriacao: map['data_criacao'],
    );
  }

  // Método para converter para Map (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_talhao': talhaoId,
      'id_safra': safraId,
      'id_cultura': culturaId,
      'id_plantio': plantioId,
      'espacamento_cm': espacamentoCm,
      'populacao_desejada': populacaoDesejada,
      'germinacao_percent': germinacaoPercent,
      'pureza_percent': purezaPercent,
      'sementes_por_metro': sementesPorMetro,
      'sementes_por_hectare': sementesPorHectare,
      'peso_mil_sementes': pesoMilSementes,
      'total_sementes': totalSementes,
      'total_kg': totalKg,
      'kg_por_hectare': kgPorHectare,
      'kg_por_hectare_ajustado': kgPorHectareAjustado,
      'kg_utilizado': kgUtilizado,
      'kg_faltando': kgFaltando,
      'area_ha': areaHa,
      'status': status,
      'origem_calculo': origemCalculo,
      'data_criacao': dataCriacao,
    };
  }

  // Método para criar uma cópia com alterações
  CalculoSementesModel copyWith({
    String? id,
    String? talhaoId,
    String? safraId,
    String? culturaId,
    String? plantioId,
    double? espacamentoCm,
    int? populacaoDesejada,
    double? germinacaoPercent,
    double? purezaPercent,
    double? sementesPorMetro,
    double? sementesPorHectare,
    double? pesoMilSementes,
    int? totalSementes,
    double? totalKg,
    double? kgPorHectare,
    double? kgPorHectareAjustado,
    double? kgUtilizado,
    double? kgFaltando,
    double? areaHa,
    String? status,
    String? origemCalculo,
    String? dataCriacao,
  }) {
    return CalculoSementesModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      plantioId: plantioId ?? this.plantioId,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      germinacaoPercent: germinacaoPercent ?? this.germinacaoPercent,
      purezaPercent: purezaPercent ?? this.purezaPercent,
      sementesPorMetro: sementesPorMetro ?? this.sementesPorMetro,
      sementesPorHectare: sementesPorHectare ?? this.sementesPorHectare,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      totalSementes: totalSementes ?? this.totalSementes,
      totalKg: totalKg ?? this.totalKg,
      kgPorHectare: kgPorHectare ?? this.kgPorHectare,
      kgPorHectareAjustado: kgPorHectareAjustado ?? this.kgPorHectareAjustado,
      kgUtilizado: kgUtilizado ?? this.kgUtilizado,
      kgFaltando: kgFaltando ?? this.kgFaltando,
      areaHa: areaHa ?? this.areaHa,
      status: status ?? this.status,
      origemCalculo: origemCalculo ?? this.origemCalculo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
