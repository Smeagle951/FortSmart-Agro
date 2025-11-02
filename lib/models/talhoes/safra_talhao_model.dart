import 'dart:convert';

/// Modelo para representar a relação entre safra e talhão
class SafraTalhaoModel {
  final String id;
  final String safraId;
  final String safraNome;
  final String talhaoId;
  final String talhaoNome;
  final String? culturaId;
  final String? culturaNome;
  final DateTime dataPlantio;
  final DateTime? dataColheita;
  final double areaHectares;
  final String status; // 'plantado', 'em_desenvolvimento', 'colhido', 'cancelado'
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafraTalhaoModel({
    required this.id,
    required this.safraId,
    required this.safraNome,
    required this.talhaoId,
    required this.talhaoNome,
    this.culturaId,
    this.culturaNome,
    required this.dataPlantio,
    this.dataColheita,
    required this.areaHectares,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafraTalhaoModel.fromMap(Map<String, dynamic> map) {
    return SafraTalhaoModel(
      id: map['id'] ?? '',
      safraId: map['safra_id'] ?? '',
      safraNome: map['safra_nome'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      culturaId: map['cultura_id'],
      culturaNome: map['cultura_nome'],
      dataPlantio: DateTime.parse(map['data_plantio']),
      dataColheita: map['data_colheita'] != null ? DateTime.parse(map['data_colheita']) : null,
      areaHectares: map['area_hectares']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'plantado',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'safra_id': safraId,
      'safra_nome': safraNome,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'data_plantio': dataPlantio.toIso8601String(),
      'data_colheita': dataColheita?.toIso8601String(),
      'area_hectares': areaHectares,
      'status': status,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory SafraTalhaoModel.fromJson(String source) => SafraTalhaoModel.fromMap(json.decode(source));

  /// Verifica se a safra está ativa
  bool get isActive {
    return status == 'plantado' || status == 'em_desenvolvimento';
  }

  /// Verifica se a safra foi colhida
  bool get isHarvested {
    return status == 'colhido';
  }

  /// Calcula a duração da safra em dias
  int get durationInDays {
    final endDate = dataColheita ?? DateTime.now();
    return endDate.difference(dataPlantio).inDays;
  }

  /// Obtém o status formatado
  String get statusDisplay {
    switch (status) {
      case 'plantado':
        return 'Plantado';
      case 'em_desenvolvimento':
        return 'Em Desenvolvimento';
      case 'colhido':
        return 'Colhido';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  /// Obtém a cor do status
  String get statusColor {
    switch (status) {
      case 'plantado':
        return '#4CAF50'; // Verde
      case 'em_desenvolvimento':
        return '#FF9800'; // Laranja
      case 'colhido':
        return '#2196F3'; // Azul
      case 'cancelado':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  SafraTalhaoModel copyWith({
    String? id,
    String? safraId,
    String? safraNome,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    DateTime? dataPlantio,
    DateTime? dataColheita,
    double? areaHectares,
    String? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafraTalhaoModel(
      id: id ?? this.id,
      safraId: safraId ?? this.safraId,
      safraNome: safraNome ?? this.safraNome,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      dataColheita: dataColheita ?? this.dataColheita,
      areaHectares: areaHectares ?? this.areaHectares,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SafraTalhaoModel(id: $id, safraId: $safraId, safraNome: $safraNome, talhaoId: $talhaoId, talhaoNome: $talhaoNome, culturaId: $culturaId, culturaNome: $culturaNome, dataPlantio: $dataPlantio, dataColheita: $dataColheita, areaHectares: $areaHectares, status: $status, metadata: $metadata, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SafraTalhaoModel &&
        other.id == id &&
        other.safraId == safraId &&
        other.safraNome == safraNome &&
        other.talhaoId == talhaoId &&
        other.talhaoNome == talhaoNome &&
        other.culturaId == culturaId &&
        other.culturaNome == culturaNome &&
        other.dataPlantio == dataPlantio &&
        other.dataColheita == dataColheita &&
        other.areaHectares == areaHectares &&
        other.status == status &&
        other.metadata == metadata &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        safraId.hashCode ^
        safraNome.hashCode ^
        talhaoId.hashCode ^
        talhaoNome.hashCode ^
        culturaId.hashCode ^
        culturaNome.hashCode ^
        dataPlantio.hashCode ^
        dataColheita.hashCode ^
        areaHectares.hashCode ^
        status.hashCode ^
        metadata.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
