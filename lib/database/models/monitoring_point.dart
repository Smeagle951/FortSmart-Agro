import 'dart:convert';

/// Modelo de banco de dados para ponto de monitoramento
class MonitoringPoint {
  final String id;
  final String? monitoringId;
  final int plotId;
  final String plotName;
  final int? cropId;
  final String? cropName;
  final double latitude;
  final double longitude;
  final String? audioPath;
  final String? observations;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String? metadata;
  final int? plantasAvaliadas;
  final double? gpsAccuracy;
  final bool isManualEntry;

  MonitoringPoint({
    required this.id,
    this.monitoringId,
    required this.plotId,
    required this.plotName,
    this.cropId,
    this.cropName,
    required this.latitude,
    required this.longitude,
    this.audioPath,
    this.observations,
    this.images,
    required this.createdAt,
    this.updatedAt,
    required this.isSynced,
    this.metadata,
    this.plantasAvaliadas,
    this.gpsAccuracy,
    required this.isManualEntry,
  });

  factory MonitoringPoint.fromMap(Map<String, dynamic> map) {
    return MonitoringPoint(
      id: map['id'] ?? '',
      monitoringId: map['monitoringId'],
      plotId: map['plotId']?.toInt() ?? 0,
      plotName: map['plotName'] ?? '',
      cropId: map['cropId']?.toInt(),
      cropName: map['cropName'],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      audioPath: map['audioPath'],
      observations: map['observations'],
      images: List<String>.from(map['images'] ?? []),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      isSynced: map['isSynced'] == 1,
      metadata: map['metadata'],
      plantasAvaliadas: map['plantasAvaliadas']?.toInt(),
      gpsAccuracy: map['gpsAccuracy']?.toDouble(),
      isManualEntry: map['isManualEntry'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monitoringId': monitoringId,
      'plotId': plotId,
      'plotName': plotName,
      'cropId': cropId,
      'cropName': cropName,
      'latitude': latitude,
      'longitude': longitude,
      'audioPath': audioPath,
      'observations': observations,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'metadata': metadata,
      'plantasAvaliadas': plantasAvaliadas,
      'gpsAccuracy': gpsAccuracy,
      'isManualEntry': isManualEntry ? 1 : 0,
    };
  }

  String toJson() => json.encode(toMap());

  factory MonitoringPoint.fromJson(String source) => MonitoringPoint.fromMap(json.decode(source));

  /// Converte para o modelo de domínio
  Map<String, dynamic> toDomainModel() {
    return {
      'id': id,
      'monitoringId': monitoringId,
      'plotId': plotId,
      'plotName': plotName,
      'cropId': cropId,
      'cropName': cropName,
      'latitude': latitude,
      'longitude': longitude,
      'audioPath': audioPath,
      'observations': observations,
      'images': images,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isSynced': isSynced,
      'metadata': metadata,
      'plantasAvaliadas': plantasAvaliadas,
      'gpsAccuracy': gpsAccuracy,
      'isManualEntry': isManualEntry,
    };
  }

  MonitoringPoint copyWith({
    String? id,
    String? monitoringId,
    int? plotId,
    String? plotName,
    int? cropId,
    String? cropName,
    double? latitude,
    double? longitude,
    String? audioPath,
    String? observations,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? metadata,
    int? plantasAvaliadas,
    double? gpsAccuracy,
    bool? isManualEntry,
  }) {
    return MonitoringPoint(
      id: id ?? this.id,
      monitoringId: monitoringId ?? this.monitoringId,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      audioPath: audioPath ?? this.audioPath,
      observations: observations ?? this.observations,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      metadata: metadata ?? this.metadata,
      plantasAvaliadas: plantasAvaliadas ?? this.plantasAvaliadas,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      isManualEntry: isManualEntry ?? this.isManualEntry,
    );
  }

  @override
  String toString() {
    return 'MonitoringPoint(id: $id, monitoringId: $monitoringId, plotId: $plotId, plotName: $plotName, latitude: $latitude, longitude: $longitude, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringPoint &&
        other.id == id &&
        other.monitoringId == monitoringId &&
        other.plotId == plotId &&
        other.plotName == plotName &&
        other.cropId == cropId &&
        other.cropName == cropName &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.audioPath == audioPath &&
        other.observations == observations &&
        other.images == images &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isSynced == isSynced &&
        other.metadata == metadata &&
        other.plantasAvaliadas == plantasAvaliadas &&
        other.gpsAccuracy == gpsAccuracy &&
        other.isManualEntry == isManualEntry;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        monitoringId.hashCode ^
        plotId.hashCode ^
        plotName.hashCode ^
        cropId.hashCode ^
        cropName.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        audioPath.hashCode ^
        observations.hashCode ^
        images.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isSynced.hashCode ^
        metadata.hashCode ^
        plantasAvaliadas.hashCode ^
        gpsAccuracy.hashCode ^
        isManualEntry.hashCode;
  }
}
