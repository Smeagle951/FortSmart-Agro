/// Modelo que representa um registro de colheita agrícola com integração completa
class ColheitaModel {
  final int? id;            // ID interno legado (mantido para compatibilidade)
  final String? stringId;   // ID string para integração com novos módulos
  
  // IDs de contexto agrícola - Podem ser int (legado) ou string (novo formato)
  final dynamic talhaoId;   // ID do talhão (plot)
  final dynamic safraId;    // ID da safra (harvest season)
  final dynamic culturaId;  // ID da cultura (crop)
  
  final int variedadeId;
  final String dataColheita;
  final double areaColhida;
  final double produtividade;
  final double umidade;
  final String observacoes;
  final String fotos;
  final String createdAt;

  ColheitaModel({
    this.id,
    this.stringId,
    required this.talhaoId,
    this.safraId,
    required this.culturaId,
    required this.variedadeId,
    required this.dataColheita,
    required this.areaColhida,
    required this.produtividade,
    required this.umidade,
    this.observacoes = '',
    this.fotos = '',
    String? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'string_id': stringId,
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'data_colheita': dataColheita,
      'area_colhida': areaColhida,
      'produtividade': produtividade,
      'umidade': umidade,
      'observacoes': observacoes,
      'fotos': fotos,
      'created_at': createdAt,
    };
  }

  factory ColheitaModel.fromMap(Map<String, dynamic> map) {
    return ColheitaModel(
      id: map['id'],
      stringId: map['string_id'],
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      dataColheita: map['data_colheita'],
      areaColhida: map['area_colhida'],
      produtividade: map['produtividade'],
      umidade: map['umidade'],
      observacoes: map['observacoes'] ?? '',
      fotos: map['fotos'] ?? '',
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  ColheitaModel copyWith({
    int? id,
    String? stringId,
    dynamic talhaoId,
    dynamic safraId,
    dynamic culturaId,
    int? variedadeId,
    String? dataColheita,
    double? areaColhida,
    double? produtividade,
    double? umidade,
    String? observacoes,
    String? fotos,
    String? createdAt,
  }) {
    return ColheitaModel(
      id: id ?? this.id,
      stringId: stringId ?? this.stringId,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      dataColheita: dataColheita ?? this.dataColheita,
      areaColhida: areaColhida ?? this.areaColhida,
      produtividade: produtividade ?? this.produtividade,
      umidade: umidade ?? this.umidade,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
