import 'package:uuid/uuid.dart';

/// Modelo para pontos geográficos de subáreas
class PontoModel {
  final String id;
  final double latitude;
  final double longitude;
  final String subareaId;

  const PontoModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.subareaId,
  });

  /// Cria um novo ponto
  factory PontoModel.create({
    required double latitude,
    required double longitude,
    required String subareaId,
  }) {
    return PontoModel(
      id: const Uuid().v4(),
      latitude: latitude,
      longitude: longitude,
      subareaId: subareaId,
    );
  }

  /// Cria uma cópia do ponto com campos alterados
  PontoModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? subareaId,
  }) {
    return PontoModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      subareaId: subareaId ?? this.subareaId,
    );
  }

  /// Converte para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'subarea_id': subareaId,
    };
  }

  /// Cria a partir de Map do banco
  factory PontoModel.fromMap(Map<String, dynamic> map) {
    return PontoModel(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      subareaId: map['subarea_id'],
    );
  }

  @override
  String toString() {
    return 'PontoModel(id: $id, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PontoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
