import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../models/monitoring_point.dart';
import '../../../utils/logger.dart';

/// Dados de um hexágono individual
class HexbinData {
  final String id;
  final LatLng center;
  final List<LatLng> vertices;
  final double infestationValue;
  final int pointCount;
  final String level;
  final Map<String, dynamic> metadata;

  HexbinData({
    required this.id,
    required this.center,
    required this.vertices,
    required this.infestationValue,
    required this.pointCount,
    required this.level,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'vertices': vertices.map((v) => {'lat': v.latitude, 'lng': v.longitude}).toList(),
      'infestationValue': infestationValue,
      'pointCount': pointCount,
      'level': level,
      'metadata': metadata,
    };
  }

  /// Converte para GeoJSON Feature
  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          vertices.map((v) => [v.longitude, v.latitude]).toList()
        ],
      },
      'properties': {
        'id': id,
        'infestationValue': infestationValue,
        'pointCount': pointCount,
        'level': level,
        'metadata': metadata,
      },
    };
  }
}

/// Serviço para geração de dados de hexbin para heatmaps
class HexbinService {
  static const double _earthRadius = 6371000.0; // metros
  
  /// Gera dados de hexbin para um conjunto de pontos de monitoramento
  /// Com otimização de performance baseada no zoom
  Future<List<HexbinData>> generateHexbinData(
    List<MonitoringPoint> points, {
    required List<LatLng> polygonBounds,
    double hexSize = 50.0, // metros
    String? organismoId,
    double? currentZoom, // Zoom atual do mapa
    int? maxPointsForDetail = 1000, // Máximo de pontos para detalhamento
  }) async {
    try {
      Logger.info('🔷 Gerando dados de hexbin para ${points.length} pontos');
      
      if (points.isEmpty || polygonBounds.isEmpty) {
        Logger.warning('⚠️ Dados insuficientes para gerar hexbin');
        return [];
      }

      // 1. Verificar se deve gerar hexbin baseado no zoom e quantidade de pontos
      if (!_shouldGenerateHexbin(currentZoom, points.length, maxPointsForDetail)) {
        Logger.info('⏭️ Pulando geração de hexbin - zoom baixo ou muitos pontos');
        return [];
      }

      // 2. Ajustar tamanho do hexágono baseado no zoom
      final adjustedHexSize = _adjustHexSizeForZoom(hexSize, currentZoom);
      Logger.info('🔷 Tamanho do hexágono ajustado: ${adjustedHexSize}m (zoom: $currentZoom)');

      // 3. Calcular bounding box do polígono
      final bbox = _calculateBoundingBox(polygonBounds);
      
      // 4. Gerar grade de hexágonos
      final hexagons = _generateHexagonGrid(bbox, adjustedHexSize);
      
      // 5. Atribuir pontos aos hexágonos
      final hexbinData = _assignPointsToHexagons(points, hexagons, organismoId);
      
      // 6. Calcular valores de infestação para cada hexágono
      final result = _calculateHexagonInfestationValues(hexbinData);
      
      Logger.info('✅ Hexbin gerado: ${result.length} hexágonos');
      return result;
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de hexbin: $e');
      return [];
    }
  }

  /// Verifica se deve gerar hexbin baseado no zoom e quantidade de pontos
  bool _shouldGenerateHexbin(double? zoom, int pointCount, int? maxPoints) {
    // Se zoom não especificado, sempre gerar
    if (zoom == null) return true;
    
    // Zoom mínimo para gerar hexbin (nível 14)
    const double minZoomForHexbin = 14.0;
    
    // Se zoom muito baixo, não gerar hexbin
    if (zoom < minZoomForHexbin) {
      Logger.info('🔍 Zoom muito baixo ($zoom < $minZoomForHexbin) - pulando hexbin');
      return false;
    }
    
    // Se muitos pontos, não gerar hexbin para performance
    if (maxPoints != null && pointCount > maxPoints) {
      Logger.info('📊 Muitos pontos ($pointCount > $maxPoints) - pulando hexbin');
      return false;
    }
    
    return true;
  }
  
  /// Ajusta tamanho do hexágono baseado no zoom
  double _adjustHexSizeForZoom(double baseHexSize, double? zoom) {
    if (zoom == null) return baseHexSize;
    
    // Tamanhos baseados no zoom
    if (zoom >= 18) return baseHexSize * 0.5; // Zoom alto - hexágonos menores
    if (zoom >= 16) return baseHexSize * 0.75; // Zoom médio-alto
    if (zoom >= 14) return baseHexSize; // Zoom médio - tamanho padrão
    if (zoom >= 12) return baseHexSize * 1.5; // Zoom baixo - hexágonos maiores
    return baseHexSize * 2.0; // Zoom muito baixo - hexágonos muito grandes
  }
  
  /// Calcula o bounding box de um polígono
  Map<String, LatLng> _calculateBoundingBox(List<LatLng> polygon) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in polygon) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return {
      'southwest': LatLng(minLat, minLng),
      'northeast': LatLng(maxLat, maxLng),
    };
  }

  /// Gera uma grade de hexágonos dentro do bounding box
  List<Map<String, dynamic>> _generateHexagonGrid(
    Map<String, LatLng> bbox,
    double hexSize,
  ) {
    final hexagons = <Map<String, dynamic>>[];
    
    // Converter tamanho do hexágono para graus (aproximado)
    final hexSizeDegrees = hexSize / _earthRadius * (180 / pi);
    
    // Calcular número de hexágonos necessários
    final latDiff = bbox['northeast']!.latitude - bbox['southwest']!.latitude;
    final lngDiff = bbox['northeast']!.longitude - bbox['southwest']!.longitude;
    
    final latCount = (latDiff / hexSizeDegrees).ceil();
    final lngCount = (lngDiff / hexSizeDegrees).ceil();
    
    // Gerar hexágonos
    for (int i = 0; i < latCount; i++) {
      for (int j = 0; j < lngCount; j++) {
        final centerLat = bbox['southwest']!.latitude + (i * hexSizeDegrees);
        final centerLng = bbox['southwest']!.longitude + (j * hexSizeDegrees);
        
        // Ajustar longitude para linhas alternadas (padrão de favo de mel)
        final adjustedLng = centerLng + (i % 2 == 1 ? hexSizeDegrees / 2 : 0);
        
        final center = LatLng(centerLat, adjustedLng);
        final vertices = _calculateHexagonVertices(center, hexSizeDegrees);
        
        hexagons.add({
          'center': center,
          'vertices': vertices,
          'points': <MonitoringPoint>[],
        });
      }
    }
    
    return hexagons;
  }

  /// Calcula os vértices de um hexágono
  List<LatLng> _calculateHexagonVertices(LatLng center, double size) {
    final vertices = <LatLng>[];
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) - (pi / 6); // Rotacionar para alinhar com grade
      final lat = center.latitude + (size * cos(angle));
      final lng = center.longitude + (size * sin(angle) / cos(center.latitude * pi / 180));
      
      vertices.add(LatLng(lat, lng));
    }
    
    return vertices;
  }

  /// Atribui pontos aos hexágonos mais próximos
  List<Map<String, dynamic>> _assignPointsToHexagons(
    List<MonitoringPoint> points,
    List<Map<String, dynamic>> hexagons,
    String? organismoId,
  ) {
    for (final point in points) {
      // Filtrar por organismo se especificado
      if (organismoId != null) {
        final hasOrganism = point.occurrences.any((o) => o.name == organismoId);
        if (!hasOrganism) continue;
      }
      
      // Encontrar hexágono mais próximo
      LatLng? closestHexagon;
      double minDistance = double.infinity;
      
      for (final hexagon in hexagons) {
        final distance = _calculateDistance(point.latitude, point.longitude, 
                                         hexagon['center'].latitude, hexagon['center'].longitude);
        if (distance < minDistance) {
          minDistance = distance;
          closestHexagon = hexagon['center'];
        }
      }
      
      // Adicionar ponto ao hexágono mais próximo
      if (closestHexagon != null) {
        final hexagon = hexagons.firstWhere((h) => h['center'] == closestHexagon);
        (hexagon['points'] as List<MonitoringPoint>).add(point);
      }
    }
    
    return hexagons;
  }

  /// Calcula valores de infestação para cada hexágono
  List<HexbinData> _calculateHexagonInfestationValues(
    List<Map<String, dynamic>> hexagons,
  ) {
    final result = <HexbinData>[];
    
    for (int i = 0; i < hexagons.length; i++) {
      final hexagon = hexagons[i];
      final points = hexagon['points'] as List<MonitoringPoint>;
      
      if (points.isEmpty) continue;
      
      // Calcular valor médio de infestação
      double totalInfestation = 0.0;
      int validPoints = 0;
      
      for (final point in points) {
        if (point.occurrences.isNotEmpty) {
          final occurrence = point.occurrences.first;
          totalInfestation += occurrence.infestationIndex;
          validPoints++;
        }
      }
      
      if (validPoints == 0) continue;
      
      final avgInfestation = totalInfestation / validPoints;
      
      // Determinar nível de infestação
      final level = _determineInfestationLevel(avgInfestation);
      
      // Criar dados do hexágono
      final hexbinData = HexbinData(
        id: 'hex_${i}_${DateTime.now().millisecondsSinceEpoch}',
        center: hexagon['center'],
        vertices: hexagon['vertices'],
        infestationValue: avgInfestation,
        pointCount: validPoints,
        level: level,
        metadata: {
          'total_points': points.length,
          'valid_points': validPoints,
          'generated_at': DateTime.now().toIso8601String(),
        },
      );
      
      result.add(hexbinData);
    }
    
    return result;
  }

  /// Determina o nível de infestação baseado no valor
  String _determineInfestationLevel(double value) {
    if (value <= 25.0) return 'BAIXO';
    if (value <= 50.0) return 'MODERADO';
    if (value <= 75.0) return 'ALTO';
    return 'CRITICO';
  }

  /// Calcula distância entre duas coordenadas (fórmula de Haversine)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
               sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return _earthRadius * c;
  }

  /// Converte lista de hexágonos para GeoJSON FeatureCollection
  Map<String, dynamic> toGeoJsonFeatureCollection(List<HexbinData> hexagons) {
    return {
      'type': 'FeatureCollection',
      'features': hexagons.map((h) => h.toGeoJson()).toList(),
      'properties': {
        'generated_at': DateTime.now().toIso8601String(),
        'total_hexagons': hexagons.length,
        'source': 'FortSmart_Agro_Infestation_Module',
      },
    };
  }

  /// Otimiza o tamanho do hexágono baseado na densidade de pontos
  double calculateOptimalHexSize(
    List<MonitoringPoint> points,
    List<LatLng> polygonBounds,
  ) {
    if (points.isEmpty || polygonBounds.isEmpty) return 50.0;
    
    // Calcular área do polígono
    final area = _calculatePolygonArea(polygonBounds);
    
    // Calcular densidade de pontos
    final density = points.length / area;
    
    // Ajustar tamanho baseado na densidade
    if (density > 100) return 25.0;      // Muito denso
    if (density > 50) return 35.0;       // Denso
    if (density > 20) return 50.0;       // Médio
    if (density > 10) return 75.0;       // Baixo
    return 100.0;                         // Muito baixo
  }

  /// Calcula área aproximada de um polígono
  double _calculatePolygonArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      final j = (i + 1) % polygon.length;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para metros quadrados (aproximado)
    return area * _earthRadius * _earthRadius;
  }
}
