import 'package:latlong2/latlong.dart';

/// Ponto térmico para heatmap
class ThermalPoint {
  final LatLng position;
  final double intensity;
  final String colorCode;
  final double distanceWeight;
  final Map<String, dynamic> metadata;

  ThermalPoint({
    required this.position,
    required this.intensity,
    required this.colorCode,
    required this.distanceWeight,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'position': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },
      'intensity': intensity,
      'colorCode': colorCode,
      'distanceWeight': distanceWeight,
      'metadata': metadata,
    };
  }

  factory ThermalPoint.fromMap(Map<String, dynamic> map) {
    final positionMap = map['position'] as Map<String, dynamic>;
    return ThermalPoint(
      position: LatLng(
        positionMap['latitude'] as double,
        positionMap['longitude'] as double,
      ),
      intensity: map['intensity'] as double,
      colorCode: map['colorCode'] as String,
      distanceWeight: map['distanceWeight'] as double,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Resultado do heatmap térmico
class ThermalHeatmapResult {
  final String talhaoId;
  final List<ThermalPoint> thermalPoints;
  final double minIntensity;
  final double maxIntensity;
  final double averageIntensity;
  final String calculationMethod;
  final DateTime generatedAt;
  final Map<String, dynamic> metadata;

  ThermalHeatmapResult({
    required this.talhaoId,
    required this.thermalPoints,
    required this.minIntensity,
    required this.maxIntensity,
    required this.averageIntensity,
    required this.calculationMethod,
    required this.generatedAt,
    this.metadata = const {},
  });

  /// Obtém pontos por faixa de intensidade
  List<ThermalPoint> getPointsByIntensityRange(double min, double max) {
    return thermalPoints.where((point) => 
      point.intensity >= min && point.intensity <= max
    ).toList();
  }

  /// Obtém pontos críticos (intensidade alta)
  List<ThermalPoint> getCriticalPoints() {
    return getPointsByIntensityRange(75.0, 100.0);
  }

  /// Obtém pontos de atenção (intensidade média)
  List<ThermalPoint> getAttentionPoints() {
    return getPointsByIntensityRange(50.0, 74.9);
  }

  /// Obtém pontos normais (intensidade baixa)
  List<ThermalPoint> getNormalPoints() {
    return getPointsByIntensityRange(0.0, 49.9);
  }

  /// Calcula estatísticas do heatmap
  Map<String, dynamic> getStatistics() {
    final criticalPoints = getCriticalPoints();
    final attentionPoints = getAttentionPoints();
    final normalPoints = getNormalPoints();

    return {
      'total_points': thermalPoints.length,
      'critical_points': criticalPoints.length,
      'attention_points': attentionPoints.length,
      'normal_points': normalPoints.length,
      'critical_percentage': thermalPoints.isNotEmpty 
          ? (criticalPoints.length / thermalPoints.length) * 100 
          : 0.0,
      'attention_percentage': thermalPoints.isNotEmpty 
          ? (attentionPoints.length / thermalPoints.length) * 100 
          : 0.0,
      'normal_percentage': thermalPoints.isNotEmpty 
          ? (normalPoints.length / thermalPoints.length) * 100 
          : 0.0,
      'intensity_range': {
        'min': minIntensity,
        'max': maxIntensity,
        'average': averageIntensity,
        'range': maxIntensity - minIntensity,
      },
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'thermalPoints': thermalPoints.map((p) => p.toMap()).toList(),
      'minIntensity': minIntensity,
      'maxIntensity': maxIntensity,
      'averageIntensity': averageIntensity,
      'calculationMethod': calculationMethod,
      'generatedAt': generatedAt.toIso8601String(),
      'metadata': metadata,
      'statistics': getStatistics(),
    };
  }

  factory ThermalHeatmapResult.fromMap(Map<String, dynamic> map) {
    return ThermalHeatmapResult(
      talhaoId: map['talhaoId'] as String,
      thermalPoints: (map['thermalPoints'] as List)
          .map((p) => ThermalPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      minIntensity: map['minIntensity'] as double,
      maxIntensity: map['maxIntensity'] as double,
      averageIntensity: map['averageIntensity'] as double,
      calculationMethod: map['calculationMethod'] as String,
      generatedAt: DateTime.parse(map['generatedAt'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}
