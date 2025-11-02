import 'package:latlong2/latlong.dart';

/// Modelo para representar uma amostra de solo
class SoilSample {
  final String id;
  final String farmId;
  final String plotId;
  final String sampleName;
  final String description;
  final LatLng location;
  final double depth;
  final DateTime samplingDate;
  final String samplerName;
  final Map<String, dynamic> analysisResults;
  final int syncStatus; // 0 = pendente, 1 = sincronizado, 2 = erro
  final DateTime? syncDate;
  final String? syncErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  SoilSample({
    required this.id,
    required this.farmId,
    required this.plotId,
    required this.sampleName,
    required this.description,
    required this.location,
    required this.depth,
    required this.samplingDate,
    required this.samplerName,
    required this.analysisResults,
    this.syncStatus = 0,
    this.syncDate,
    this.syncErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de um Map
  factory SoilSample.fromMap(Map<String, dynamic> map) {
    return SoilSample(
      id: map['id'] ?? '',
      farmId: map['farmId'] ?? '',
      plotId: map['plotId'] ?? '',
      sampleName: map['sampleName'] ?? '',
      description: map['description'] ?? '',
      location: LatLng(
        map['latitude'] ?? 0.0,
        map['longitude'] ?? 0.0,
      ),
      depth: (map['depth'] ?? 0.0).toDouble(),
      samplingDate: DateTime.parse(map['samplingDate'] ?? DateTime.now().toIso8601String()),
      samplerName: map['samplerName'] ?? '',
      analysisResults: Map<String, dynamic>.from(map['analysisResults'] ?? {}),
      syncStatus: map['syncStatus'] ?? 0,
      syncDate: map['syncDate'] != null ? DateTime.parse(map['syncDate']) : null,
      syncErrorMessage: map['syncErrorMessage'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'plotId': plotId,
      'sampleName': sampleName,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'depth': depth,
      'samplingDate': samplingDate.toIso8601String(),
      'samplerName': samplerName,
      'analysisResults': analysisResults,
      'syncStatus': syncStatus,
      'syncDate': syncDate?.toIso8601String(),
      'syncErrorMessage': syncErrorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma cópia com alterações
  SoilSample copyWith({
    String? id,
    String? farmId,
    String? plotId,
    String? sampleName,
    String? description,
    LatLng? location,
    double? depth,
    DateTime? samplingDate,
    String? samplerName,
    Map<String, dynamic>? analysisResults,
    int? syncStatus,
    DateTime? syncDate,
    String? syncErrorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoilSample(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      plotId: plotId ?? this.plotId,
      sampleName: sampleName ?? this.sampleName,
      description: description ?? this.description,
      location: location ?? this.location,
      depth: depth ?? this.depth,
      samplingDate: samplingDate ?? this.samplingDate,
      samplerName: samplerName ?? this.samplerName,
      analysisResults: analysisResults ?? this.analysisResults,
      syncStatus: syncStatus ?? this.syncStatus,
      syncDate: syncDate ?? this.syncDate,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SoilSample(id: $id, sampleName: $sampleName, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoilSample && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
