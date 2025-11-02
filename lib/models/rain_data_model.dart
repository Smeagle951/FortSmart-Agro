/// Modelo de dados para persistência de chuva
class RainDataModel {
  final String id;
  final String stationId;
  final String stationName;
  final double rainfall; // em mm
  final String rainType;
  final DateTime dateTime;
  final String? notes;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  RainDataModel({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.rainfall,
    required this.rainType,
    required this.dateTime,
    this.notes,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'station_id': stationId,
      'station_name': stationName,
      'rainfall': rainfall,
      'rain_type': rainType,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria a partir de Map
  factory RainDataModel.fromMap(Map<String, dynamic> map) {
    return RainDataModel(
      id: map['id'] as String,
      stationId: map['station_id'] as String,
      stationName: map['station_name'] as String,
      rainfall: map['rainfall'] as double,
      rainType: map['rain_type'] as String,
      dateTime: DateTime.parse(map['date_time'] as String),
      notes: map['notes'] as String?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Cria um novo registro
  factory RainDataModel.create({
    required String stationId,
    required String stationName,
    required double rainfall,
    required String rainType,
    required DateTime dateTime,
    String? notes,
    required double latitude,
    required double longitude,
  }) {
    final now = DateTime.now();
    return RainDataModel(
      id: '${stationId}_${now.millisecondsSinceEpoch}',
      stationId: stationId,
      stationName: stationName,
      rainfall: rainfall,
      rainType: rainType,
      dateTime: dateTime,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria cópia com dados atualizados
  RainDataModel copyWith({
    String? id,
    String? stationId,
    String? stationName,
    double? rainfall,
    String? rainType,
    DateTime? dateTime,
    String? notes,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RainDataModel(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      rainfall: rainfall ?? this.rainfall,
      rainType: rainType ?? this.rainType,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RainDataModel(id: $id, stationId: $stationId, rainfall: $rainfall, dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RainDataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo para estatísticas de chuva
class RainStatisticsModel {
  final String stationId;
  final String stationName;
  final double totalRainfall;
  final double averageRainfall;
  final double maxRainfall;
  final double minRainfall;
  final int totalRecords;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String periodType; // 'weekly', 'monthly', 'quarterly', 'yearly'

  RainStatisticsModel({
    required this.stationId,
    required this.stationName,
    required this.totalRainfall,
    required this.averageRainfall,
    required this.maxRainfall,
    required this.minRainfall,
    required this.totalRecords,
    required this.periodStart,
    required this.periodEnd,
    required this.periodType,
  });

  Map<String, dynamic> toMap() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'total_rainfall': totalRainfall,
      'average_rainfall': averageRainfall,
      'max_rainfall': maxRainfall,
      'min_rainfall': minRainfall,
      'total_records': totalRecords,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period_type': periodType,
    };
  }

  factory RainStatisticsModel.fromMap(Map<String, dynamic> map) {
    return RainStatisticsModel(
      stationId: map['station_id'] as String,
      stationName: map['station_name'] as String,
      totalRainfall: map['total_rainfall'] as double,
      averageRainfall: map['average_rainfall'] as double,
      maxRainfall: map['max_rainfall'] as double,
      minRainfall: map['min_rainfall'] as double,
      totalRecords: map['total_records'] as int,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      periodType: map['period_type'] as String,
    );
  }
}
