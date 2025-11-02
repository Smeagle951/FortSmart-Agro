/// Modelo para pontos de coleta de chuva
class RainStationModel {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? color; // Cor personalizada do ícone

  RainStationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.color,
  });

  /// Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'color': color,
    };
  }

  /// Cria a partir de Map
  factory RainStationModel.fromMap(Map<String, dynamic> map) {
    return RainStationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      notes: map['notes'] as String?,
      color: map['color'] as String?,
    );
  }

  /// Cria um novo ponto de chuva
  factory RainStationModel.create({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    String? notes,
    String? color,
  }) {
    final now = DateTime.now();
    return RainStationModel(
      id: 'RAIN_STATION_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      color: color,
    );
  }

  /// Cria cópia com dados atualizados
  RainStationModel copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? color,
  }) {
    return RainStationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'RainStationModel(id: $id, name: $name, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RainStationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
