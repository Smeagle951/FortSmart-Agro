import 'package:uuid/uuid.dart';

/// Modelo para representar um cálculo de sementes por hectare
class SementeHectareModel {
  final String id;
  final String? talhaoId;
  final String culturaId;
  final String? variedadeId;
  final double espacamentoCm;
  final int populacaoDesejada;
  final double densidadeMetro;
  final double germinacaoPercentual;
  final double pesoMilSementes;
  final int sementesHa;
  final double kgHa;
  final double sacasHa;
  final double sementesMetroLinear;
  final String? observacoes;
  final DateTime dataCriacao;
  final bool sincronizado;

  SementeHectareModel({
    String? id,
    this.talhaoId,
    required this.culturaId,
    this.variedadeId,
    required this.espacamentoCm,
    required this.populacaoDesejada,
    required this.densidadeMetro,
    required this.germinacaoPercentual,
    required this.pesoMilSementes,
    required this.sementesHa,
    required this.kgHa,
    required this.sacasHa,
    required this.sementesMetroLinear,
    this.observacoes,
    DateTime? dataCriacao,
    this.sincronizado = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.dataCriacao = dataCriacao ?? DateTime.now();

  /// Cria uma cópia do modelo com os campos atualizados
  SementeHectareModel copyWith({
    String? id,
    String? talhaoId,
    String? culturaId,
    String? variedadeId,
    double? espacamentoCm,
    int? populacaoDesejada,
    double? densidadeMetro,
    double? germinacaoPercentual,
    double? pesoMilSementes,
    int? sementesHa,
    double? kgHa,
    double? sacasHa,
    double? sementesMetroLinear,
    String? observacoes,
    DateTime? dataCriacao,
    bool? sincronizado,
  }) {
    return SementeHectareModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      densidadeMetro: densidadeMetro ?? this.densidadeMetro,
      germinacaoPercentual: germinacaoPercentual ?? this.germinacaoPercentual,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      sementesHa: sementesHa ?? this.sementesHa,
      kgHa: kgHa ?? this.kgHa,
      sacasHa: sacasHa ?? this.sacasHa,
      sementesMetroLinear: sementesMetroLinear ?? this.sementesMetroLinear,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'espacamento_cm': espacamentoCm,
      'populacao_desejada': populacaoDesejada,
      'densidade_metro': densidadeMetro,
      'germinacao_percentual': germinacaoPercentual,
      'peso_mil_sementes': pesoMilSementes,
      'sementes_ha': sementesHa,
      'kg_ha': kgHa,
      'sacas_ha': sacasHa,
      'sementes_metro_linear': sementesMetroLinear,
      'observacoes': observacoes,
      'data_criacao': dataCriacao.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory SementeHectareModel.fromMap(Map<String, dynamic> map) {
    return SementeHectareModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      espacamentoCm: map['espacamento_cm'],
      populacaoDesejada: map['populacao_desejada'],
      densidadeMetro: map['densidade_metro'],
      germinacaoPercentual: map['germinacao_percentual'],
      pesoMilSementes: map['peso_mil_sementes'],
      sementesHa: map['sementes_ha'],
      kgHa: map['kg_ha'],
      sacasHa: map['sacas_ha'],
      sementesMetroLinear: map['sementes_metro_linear'],
      observacoes: map['observacoes'],
      dataCriacao: DateTime.parse(map['data_criacao']),
      sincronizado: map['sincronizado'] == 1,
    );
  }
}
