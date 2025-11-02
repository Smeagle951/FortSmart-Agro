import 'dart:convert';

/// Modelo para armazenar dados de calibragem por disco (vácuo)
class CalibragemDiscoModel {
  final int? id;
  final int furosDisco;
  final int engrenagemMotora;
  final int engrenagemMovida;
  final double espacamentoCm;
  final int linhasPlantadeira;
  final double? populacaoDesejada;
  final double relacao;
  final double sementesMetro;
  final double populacaoEstimativa;
  final double diferencaPopulacao;
  final String status;
  final DateTime data;
  final String? talhaoId;

  CalibragemDiscoModel({
    this.id,
    required this.furosDisco,
    required this.engrenagemMotora,
    required this.engrenagemMovida,
    required this.espacamentoCm,
    required this.linhasPlantadeira,
    this.populacaoDesejada,
    required this.relacao,
    required this.sementesMetro,
    required this.populacaoEstimativa,
    required this.diferencaPopulacao,
    required this.status,
    required this.data,
    this.talhaoId,
  });

  /// Cria uma cópia do modelo com os campos especificados alterados
  CalibragemDiscoModel copyWith({
    int? id,
    int? furosDisco,
    int? engrenagemMotora,
    int? engrenagemMovida,
    double? espacamentoCm,
    int? linhasPlantadeira,
    double? populacaoDesejada,
    double? relacao,
    double? sementesMetro,
    double? populacaoEstimativa,
    double? diferencaPopulacao,
    String? status,
    DateTime? data,
    String? talhaoId,
  }) {
    return CalibragemDiscoModel(
      id: id ?? this.id,
      furosDisco: furosDisco ?? this.furosDisco,
      engrenagemMotora: engrenagemMotora ?? this.engrenagemMotora,
      engrenagemMovida: engrenagemMovida ?? this.engrenagemMovida,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      linhasPlantadeira: linhasPlantadeira ?? this.linhasPlantadeira,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      relacao: relacao ?? this.relacao,
      sementesMetro: sementesMetro ?? this.sementesMetro,
      populacaoEstimativa: populacaoEstimativa ?? this.populacaoEstimativa,
      diferencaPopulacao: diferencaPopulacao ?? this.diferencaPopulacao,
      status: status ?? this.status,
      data: data ?? this.data,
      talhaoId: talhaoId ?? this.talhaoId,
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'furos_disco': furosDisco,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
      'espacamento_cm': espacamentoCm,
      'linhas_plantadeira': linhasPlantadeira,
      'populacao_desejada': populacaoDesejada,
      'relacao': relacao,
      'sementes_metro': sementesMetro,
      'populacao_estimativa': populacaoEstimativa,
      'diferenca_populacao': diferencaPopulacao,
      'status': status,
      'data': data.toIso8601String(),
      'talhao_id': talhaoId,
    };
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  factory CalibragemDiscoModel.fromMap(Map<String, dynamic> map) {
    return CalibragemDiscoModel(
      id: map['id'],
      furosDisco: map['furos_disco'],
      engrenagemMotora: map['engrenagem_motora'],
      engrenagemMovida: map['engrenagem_movida'],
      espacamentoCm: map['espacamento_cm'],
      linhasPlantadeira: map['linhas_plantadeira'],
      populacaoDesejada: map['populacao_desejada'],
      relacao: map['relacao'],
      sementesMetro: map['sementes_metro'],
      populacaoEstimativa: map['populacao_estimativa'],
      diferencaPopulacao: map['diferenca_populacao'],
      status: map['status'],
      data: DateTime.parse(map['data']),
      talhaoId: map['talhao_id'],
    );
  }

  /// Converte o modelo para JSON
  String toJson() => json.encode(toMap());

  /// Cria um modelo a partir de JSON
  factory CalibragemDiscoModel.fromJson(String source) => 
      CalibragemDiscoModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CalibragemDiscoModel(id: $id, furosDisco: $furosDisco, engrenagemMotora: $engrenagemMotora, engrenagemMovida: $engrenagemMovida, espacamentoCm: $espacamentoCm, linhasPlantadeira: $linhasPlantadeira, populacaoDesejada: $populacaoDesejada, relacao: $relacao, sementesMetro: $sementesMetro, populacaoEstimativa: $populacaoEstimativa, diferencaPopulacao: $diferencaPopulacao, status: $status, data: $data, talhaoId: $talhaoId)';
  }
}
