/// Modelo que representa um registro de plantio agrícola com integração completa
class PlantioModel {
  final int? id;            // ID interno legado (mantido para compatibilidade)
  final String? stringId;   // ID string para integração com novos módulos
  
  // IDs de contexto agrícola - Podem ser int (legado) ou string (novo formato)
  final dynamic talhaoId;   // ID do talhão (plot)
  final dynamic safraId;    // ID da safra (harvest season)
  final dynamic culturaId;  // ID da cultura (crop)
  
  final int variedadeId;
  final DateTime dataPlantio;
  final int tratorId;
  final int plantadeiraId;
  final double populacao;
  final double espacamento;
  final String? observacoes;
  final List<String>? fotos;
  final DateTime createdAt;

  PlantioModel({
    this.id,
    this.stringId,
    required this.talhaoId,
    this.safraId,
    required this.culturaId,
    required this.variedadeId,
    required this.dataPlantio,
    required this.tratorId,
    required this.plantadeiraId,
    required this.populacao,
    required this.espacamento,
    this.observacoes,
    this.fotos,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'string_id': stringId,
      'talhao_id': talhaoId,
      'safra_id': safraId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'data_plantio': dataPlantio.toIso8601String(),
      'trator_id': tratorId,
      'plantadeira_id': plantadeiraId,
      'populacao': populacao,
      'espacamento': espacamento,
      'observacoes': observacoes,
      'fotos': fotos?.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PlantioModel.fromMap(Map<String, dynamic> map) {
    return PlantioModel(
      id: map['id'],
      stringId: map['string_id'],
      talhaoId: map['talhao_id'],
      safraId: map['safra_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      dataPlantio: DateTime.parse(map['data_plantio']),
      tratorId: map['trator_id'],
      plantadeiraId: map['plantadeira_id'],
      populacao: map['populacao'],
      espacamento: map['espacamento'],
      observacoes: map['observacoes'],
      fotos: map['fotos'] != null && map['fotos'].toString().isNotEmpty
          ? map['fotos'].toString().split(',')
          : [],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  PlantioModel copyWith({
    int? id,
    String? stringId,
    dynamic talhaoId,
    dynamic safraId,
    dynamic culturaId,
    int? variedadeId,
    DateTime? dataPlantio,
    int? tratorId,
    int? plantadeiraId,
    double? populacao,
    double? espacamento,
    String? observacoes,
    List<String>? fotos,
    DateTime? createdAt,
  }) {
    return PlantioModel(
      id: id ?? this.id,
      stringId: stringId ?? this.stringId,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      tratorId: tratorId ?? this.tratorId,
      plantadeiraId: plantadeiraId ?? this.plantadeiraId,
      populacao: populacao ?? this.populacao,
      espacamento: espacamento ?? this.espacamento,
      observacoes: observacoes ?? this.observacoes,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
