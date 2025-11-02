import 'dart:math';
import 'package:latlong2/latlong.dart';

class DrawingVertex {
  final String id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? source; // 'gps', 'manual', 'imported'

  DrawingVertex({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.source,
  });

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  // Calcular distância até outro vértice
  double distanceTo(DrawingVertex other) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = other.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (other.latitude - latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (other.longitude - longitude) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Verificar se o vértice é válido
  bool get isValid {
    return latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180 &&
           accuracy >= 0;
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  // Criar a partir de JSON
  factory DrawingVertex.fromJson(Map<String, dynamic> json) {
    return DrawingVertex(
      id: json['id'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      source: json['source'],
    );
  }

  // Criar a partir de Map do banco
  factory DrawingVertex.fromMap(Map<String, dynamic> map) {
    return DrawingVertex(
      id: map['id']?.toString() ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      accuracy: (map['accuracy'] ?? 0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      source: map['source']?.toString(),
    );
  }

  // Converter para Map para o banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  // Copiar com alterações
  DrawingVertex copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    String? source,
  }) {
    return DrawingVertex(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingVertex &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DrawingVertex(id: $id, lat: $latitude, lng: $longitude)';
}
