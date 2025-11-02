/// Modelo para dados GeoJSON
class GeoJSONData {
  final String dataType;
  final List<Map<String, dynamic>> features;
  final Map<String, dynamic>? bounds;
  final Map<String, dynamic>? statistics;
  final Map<String, dynamic>? metadata;
  final DateTime? importDate;

  GeoJSONData({
    required this.dataType,
    required this.features,
    this.bounds,
    this.statistics,
    this.metadata,
    this.importDate,
  });

  /// Cria GeoJSONData a partir de um Map
  factory GeoJSONData.fromMap(Map<String, dynamic> map) {
    return GeoJSONData(
      dataType: map['dataType'] ?? 'unknown',
      features: List<Map<String, dynamic>>.from(map['features'] ?? []),
      bounds: map['bounds'],
      statistics: map['statistics'],
      metadata: map['metadata'],
      importDate: map['importDate'] != null 
          ? DateTime.tryParse(map['importDate'].toString())
          : null,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'dataType': dataType,
      'features': features,
      'bounds': bounds,
      'statistics': statistics,
      'metadata': metadata,
      'importDate': importDate?.toIso8601String(),
    };
  }

  /// Obtém o número total de features
  int get featureCount => features.length;

  /// Verifica se há dados válidos
  bool get hasValidData => features.isNotEmpty;

  /// Obtém todas as coordenadas dos pontos
  List<List<double>> get allCoordinates {
    final coordinates = <List<double>>[];
    
    for (final feature in features) {
      final geometry = feature['geometry'];
      if (geometry != null && geometry['coordinates'] != null) {
        final coords = geometry['coordinates'];
        if (coords is List) {
          if (coords.isNotEmpty && coords[0] is num) {
            // Point
            coordinates.add([coords[0].toDouble(), coords[1].toDouble()]);
          } else if (coords.isNotEmpty && coords[0] is List) {
            // LineString ou Polygon
            for (final coord in coords) {
              if (coord is List && coord.length >= 2) {
                coordinates.add([coord[0].toDouble(), coord[1].toDouble()]);
              }
            }
          }
        }
      }
    }
    
    return coordinates;
  }

  /// Calcula os limites (bounds) dos dados
  Map<String, double>? calculateBounds() {
    final coords = allCoordinates;
    if (coords.isEmpty) return null;

    double minLat = coords[0][1];
    double maxLat = coords[0][1];
    double minLng = coords[0][0];
    double maxLng = coords[0][0];

    for (final coord in coords) {
      final lng = coord[0];
      final lat = coord[1];
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }
}
