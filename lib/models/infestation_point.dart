import 'package:uuid/uuid.dart';

/// Modelo para representar um ponto de infestação georreferenciado
/// Contém dados de monitoramento coletados em campo
class InfestationPoint {
  final String id;
  final double latitude;
  final double longitude;
  final String organismId;
  final String organismName;
  final int count; // Quantidade observada
  final String unit; // Unidade de medição (ex: "insetos/m²", "folhas/m²")
  final double? accuracy; // Precisão GPS em metros
  final DateTime collectedAt;
  final String? notes; // Observações adicionais
  final String? collectorId; // ID do coletor
  final String talhaoId; // ID do talhão
  final String? talhaoName; // Nome do talhão para facilitar consultas

  InfestationPoint({
    String? id,
    required this.latitude,
    required this.longitude,
    required this.organismId,
    required this.organismName,
    required this.count,
    required this.unit,
    this.accuracy,
    DateTime? collectedAt,
    this.notes,
    this.collectorId,
    required this.talhaoId,
    this.talhaoName,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.collectedAt = collectedAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'organism_id': organismId,
      'organism_name': organismName,
      'count': count,
      'unit': unit,
      'accuracy': accuracy,
      'collected_at': collectedAt.toIso8601String(),
      'notes': notes,
      'collector_id': collectorId,
      'talhao_id': talhaoId,
      'talhao_name': talhaoName,
    };
  }

  /// Cria a partir de Map
  factory InfestationPoint.fromMap(Map<String, dynamic> map) {
    return InfestationPoint(
      id: map['id'] as String?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      organismId: map['organism_id'] as String,
      organismName: map['organism_name'] as String,
      count: map['count'] as int,
      unit: map['unit'] as String,
      accuracy: map['accuracy'] as double?,
      collectedAt: DateTime.parse(map['collected_at'] as String),
      notes: map['notes'] as String?,
      collectorId: map['collector_id'] as String?,
      talhaoId: map['talhao_id'] as String,
      talhaoName: map['talhao_name'] as String?,
    );
  }

  /// Cria uma cópia com novos valores
  InfestationPoint copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? organismId,
    String? organismName,
    int? count,
    String? unit,
    double? accuracy,
    DateTime? collectedAt,
    String? notes,
    String? collectorId,
    String? talhaoId,
    String? talhaoName,
  }) {
    return InfestationPoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      organismId: organismId ?? this.organismId,
      organismName: organismName ?? this.organismName,
      count: count ?? this.count,
      unit: unit ?? this.unit,
      accuracy: accuracy ?? this.accuracy,
      collectedAt: collectedAt ?? this.collectedAt,
      notes: notes ?? this.notes,
      collectorId: collectorId ?? this.collectorId,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoName: talhaoName ?? this.talhaoName,
    );
  }

  /// Calcula a distância até outro ponto em metros
  double distanceTo(InfestationPoint other) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = other.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (other.latitude - latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (other.longitude - longitude) * (3.14159265359 / 180);

    final double a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() *
        (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    final double c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  /// Verifica se o ponto está dentro de um raio específico de outro ponto
  bool isWithinRadius(InfestationPoint other, double radiusMeters) {
    return distanceTo(other) <= radiusMeters;
  }

  /// Obtém o peso baseado na precisão GPS
  double get accuracyWeight {
    if (accuracy == null) return 1.0;
    // Peso inversamente proporcional à precisão
    // accuracy = 0m → peso = 1.0
    // accuracy = 10m → peso = 0.5
    return (1.0 / (1.0 + (accuracy! / 10.0))).clamp(0.5, 1.0);
  }

  /// Obtém o peso baseado na recência (decay exponencial)
  double get timeWeight {
    final int daysSinceCollection = DateTime.now().difference(collectedAt).inDays;
    const double decayFactor = 14.0; // τ = 14 dias
    return (-daysSinceCollection / decayFactor).exp().clamp(0.1, 1.0);
  }

  @override
  String toString() {
    return 'InfestationPoint(id: $id, lat: $latitude, lng: $longitude, '
           'organism: $organismName, count: $count $unit, '
           'talhao: $talhaoName, collected: $collectedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfestationPoint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Extensão para operações matemáticas
extension MathExtensions on double {
  double sin() => this.sin();
  double cos() => this.cos();
  double asin() => this.asin();
  double sqrt() => this.sqrt();
  double exp() => this.exp();
}
