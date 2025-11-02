class Plantio {
  final String id;
  final String talhaoId;
  final String? subareaId;
  final String cultura;
  final String variedade;
  final DateTime dataPlantio;
  final double? hectares; // Hectares plantados (quando tiver 2 variedades)
  final String? observacao;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Plantio({
    required this.id,
    required this.talhaoId,
    this.subareaId,
    required this.cultura,
    required this.variedade,
    required this.dataPlantio,
    this.hectares, // Opcional - só usado quando tiver múltiplas variedades
    this.observacao,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'subarea_id': subareaId,
      'cultura': cultura,
      'variedade': variedade,
      'data_plantio': dataPlantio.toIso8601String(),
      'hectares': hectares,
      'observacao': observacao,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Plantio.fromMap(Map<String, dynamic> map) {
    return Plantio(
      id: map['id'] as String,
      talhaoId: map['talhao_id'] as String,
      subareaId: map['subarea_id'] as String?,
      cultura: map['cultura'] as String,
      variedade: map['variedade'] as String,
      dataPlantio: DateTime.parse(map['data_plantio'] as String),
      hectares: map['hectares'] != null ? (map['hectares'] as num).toDouble() : null,
      observacao: map['observacao'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null 
          ? DateTime.parse(map['deleted_at'] as String) 
          : null,
    );
  }

  Plantio copyWith({
    String? id,
    String? talhaoId,
    String? subareaId,
    String? cultura,
    String? variedade,
    DateTime? dataPlantio,
    double? hectares,
    String? observacao,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Plantio(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      subareaId: subareaId ?? this.subareaId,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      hectares: hectares ?? this.hectares,
      observacao: observacao ?? this.observacao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Plantio(id: $id, talhaoId: $talhaoId, subareaId: $subareaId, cultura: $cultura, variedade: $variedade, dataPlantio: $dataPlantio, hectares: $hectares, observacao: $observacao, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Plantio &&
        other.id == id &&
        other.talhaoId == talhaoId &&
        other.subareaId == subareaId &&
        other.cultura == cultura &&
        other.variedade == variedade &&
        other.dataPlantio == dataPlantio &&
        other.hectares == hectares &&
        other.observacao == observacao &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        talhaoId.hashCode ^
        subareaId.hashCode ^
        cultura.hashCode ^
        variedade.hashCode ^
        dataPlantio.hashCode ^
        hectares.hashCode ^
        observacao.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        deletedAt.hashCode;
  }
}
