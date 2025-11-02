import 'dart:convert';

/// Modelo de banco de dados para monitoramento
class Monitoring {
  final String id;
  final String plotId;
  final String plotName;
  final String cropId;
  final String cropName;
  final String? cropType;
  final DateTime date;
  final String route;
  final bool isCompleted;
  final bool isSynced;
  final int severity;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? metadata;
  final String? technicianName;
  final String? technicianIdentification;
  final double? latitude;
  final double? longitude;
  final String? pests;
  final String? diseases;
  final String? weeds;
  final String? images;
  final String? observations;
  final String? recommendations;

  Monitoring({
    required this.id,
    required this.plotId,
    required this.plotName,
    required this.cropId,
    required this.cropName,
    this.cropType,
    required this.date,
    required this.route,
    required this.isCompleted,
    required this.isSynced,
    required this.severity,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.technicianName,
    this.technicianIdentification,
    this.latitude,
    this.longitude,
    this.pests,
    this.diseases,
    this.weeds,
    this.images,
    this.observations,
    this.recommendations,
  });

  factory Monitoring.fromMap(Map<String, dynamic> map) {
    return Monitoring(
      id: map['id'] ?? '',
      plotId: map['plot_id'] ?? '',
      plotName: map['plotName'] ?? '',
      cropId: map['crop_id'] ?? '',
      cropName: map['cropName'] ?? '',
      cropType: map['cropType'],
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      route: map['route'] ?? '[]',
      isCompleted: map['isCompleted'] == 1,
      isSynced: map['isSynced'] == 1,
      severity: map['severity']?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      metadata: map['metadata'],
      technicianName: map['technicianName'],
      technicianIdentification: map['technicianIdentification'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      pests: map['pests'],
      diseases: map['diseases'],
      weeds: map['weeds'],
      images: map['images'],
      observations: map['observations'],
      recommendations: map['recommendations'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plot_id': plotId,
      'plotName': plotName,
      'crop_id': cropId,
      'cropName': cropName,
      'cropType': cropType,
      'date': date.toIso8601String(),
      'route': route,
      'isCompleted': isCompleted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'severity': severity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'technicianName': technicianName,
      'technicianIdentification': technicianIdentification,
      'latitude': latitude,
      'longitude': longitude,
      'pests': pests,
      'diseases': diseases,
      'weeds': weeds,
      'images': images,
      'observations': observations,
      'recommendations': recommendations,
    };
  }

  String toJson() => json.encode(toMap());

  factory Monitoring.fromJson(String source) => Monitoring.fromMap(json.decode(source));

  /// Converte para o modelo de domínio
  Map<String, dynamic> toDomainModel() {
    return {
      'id': id,
      'plotId': int.tryParse(plotId) ?? 0,
      'plotName': plotName,
      'cropId': int.tryParse(cropId) ?? 0,
      'cropName': cropName,
      'cropType': cropType,
      'date': date,
      'route': _parseRoute(route),
      'isCompleted': isCompleted,
      'isSynced': isSynced,
      'severity': severity,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'metadata': metadata,
      'technicianName': technicianName,
      'technicianIdentification': technicianIdentification,
      'latitude': latitude,
      'longitude': longitude,
      'pests': _parseJsonList(pests),
      'diseases': _parseJsonList(diseases),
      'weeds': _parseJsonList(weeds),
      'images': _parseStringList(images),
      'observations': observations,
      'recommendations': recommendations,
    };
  }

  /// Parse da rota
  static List<Map<String, dynamic>> _parseRoute(String route) {
    if (route.isEmpty) return [];
    try {
      final List<dynamic> parsed = jsonDecode(route);
      return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Parse de lista JSON
  static List<Map<String, dynamic>> _parseJsonList(String? data) {
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> parsed = jsonDecode(data);
      return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Parse de lista de strings
  static List<String> _parseStringList(String? data) {
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> parsed = jsonDecode(data);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Monitoring copyWith({
    String? id,
    String? plotId,
    String? plotName,
    String? cropId,
    String? cropName,
    String? cropType,
    DateTime? date,
    String? route,
    bool? isCompleted,
    bool? isSynced,
    int? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
    String? technicianName,
    String? technicianIdentification,
    double? latitude,
    double? longitude,
    String? pests,
    String? diseases,
    String? weeds,
    String? images,
    String? observations,
    String? recommendations,
  }) {
    return Monitoring(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      cropType: cropType ?? this.cropType,
      date: date ?? this.date,
      route: route ?? this.route,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      technicianName: technicianName ?? this.technicianName,
      technicianIdentification: technicianIdentification ?? this.technicianIdentification,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pests: pests ?? this.pests,
      diseases: diseases ?? this.diseases,
      weeds: weeds ?? this.weeds,
      images: images ?? this.images,
      observations: observations ?? this.observations,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  @override
  String toString() {
    return 'Monitoring(id: $id, plotId: $plotId, plotName: $plotName, cropId: $cropId, cropName: $cropName, date: $date, isCompleted: $isCompleted, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Monitoring &&
        other.id == id &&
        other.plotId == plotId &&
        other.plotName == plotName &&
        other.cropId == cropId &&
        other.cropName == cropName &&
        other.cropType == cropType &&
        other.date == date &&
        other.route == route &&
        other.isCompleted == isCompleted &&
        other.isSynced == isSynced &&
        other.severity == severity &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.metadata == metadata &&
        other.technicianName == technicianName &&
        other.technicianIdentification == technicianIdentification &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.pests == pests &&
        other.diseases == diseases &&
        other.weeds == weeds &&
        other.images == images &&
        other.observations == observations &&
        other.recommendations == recommendations;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        plotId.hashCode ^
        plotName.hashCode ^
        cropId.hashCode ^
        cropName.hashCode ^
        cropType.hashCode ^
        date.hashCode ^
        route.hashCode ^
        isCompleted.hashCode ^
        isSynced.hashCode ^
        severity.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        metadata.hashCode ^
        technicianName.hashCode ^
        technicianIdentification.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        pests.hashCode ^
        diseases.hashCode ^
        weeds.hashCode ^
        images.hashCode ^
        observations.hashCode ^
        recommendations.hashCode;
  }
}
