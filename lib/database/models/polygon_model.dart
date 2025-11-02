// Modelos para SQLite puro (sem Drift)

class PolygonModel {
  final int? id;
  final String name;
  final String method; // 'manual', 'caminhada', 'importado'
  final String coordinates; // GeoJSON Polygon/MultiPolygon
  final double areaHa;
  final double perimeterM;
  final double distanceM;
  final String createdAt;
  final String? updatedAt;
  final String? fazendaId;
  final String? culturaId;
  final String? safraId;

  PolygonModel({
    this.id,
    required this.name,
    required this.method,
    required this.coordinates,
    required this.areaHa,
    required this.perimeterM,
    this.distanceM = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.fazendaId,
    this.culturaId,
    this.safraId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'coordinates': coordinates,
      'area_ha': areaHa,
      'perimeter_m': perimeterM,
      'distance_m': distanceM,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'fazenda_id': fazendaId,
      'cultura_id': culturaId,
      'safra_id': safraId,
    };
  }

  factory PolygonModel.fromMap(Map<String, dynamic> map) {
    return PolygonModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      method: map['method'] as String,
      coordinates: map['coordinates'] as String,
      areaHa: (map['area_ha'] as num).toDouble(),
      perimeterM: (map['perimeter_m'] as num).toDouble(),
      distanceM: (map['distance_m'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      fazendaId: map['fazenda_id'] as String?,
      culturaId: map['cultura_id'] as String?,
      safraId: map['safra_id'] as String?,
    );
  }

  /// Cria uma cópia do modelo com campos atualizados
  PolygonModel copyWith({
    int? id,
    String? name,
    String? method,
    String? coordinates,
    double? areaHa,
    double? perimeterM,
    double? distanceM,
    String? createdAt,
    String? updatedAt,
    String? fazendaId,
    String? culturaId,
    String? safraId,
  }) {
    return PolygonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      coordinates: coordinates ?? this.coordinates,
      areaHa: areaHa ?? this.areaHa,
      perimeterM: perimeterM ?? this.perimeterM,
      distanceM: distanceM ?? this.distanceM,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fazendaId: fazendaId ?? this.fazendaId,
      culturaId: culturaId ?? this.culturaId,
      safraId: safraId ?? this.safraId,
    );
  }
}

class TrackModel {
  final int? id;
  final int? polygonId;
  final double lat;
  final double lon;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final String ts;
  final String? status; // 'active', 'paused', 'finished'

  TrackModel({
    this.id,
    this.polygonId,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.ts,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'polygon_id': polygonId,
      'lat': lat,
      'lon': lon,
      'accuracy': accuracy,
      'speed': speed,
      'bearing': bearing,
      'ts': ts,
      'status': status,
    };
  }

  factory TrackModel.fromMap(Map<String, dynamic> map) {
    return TrackModel(
      id: map['id'] as int?,
      polygonId: map['polygon_id'] as int?,
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      bearing: (map['bearing'] as num?)?.toDouble(),
      ts: map['ts'] as String,
      status: map['status'] as String?,
    );
  }
}
