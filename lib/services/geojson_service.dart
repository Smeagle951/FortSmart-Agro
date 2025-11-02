import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';

class GeoJSONService {
  /// Converte uma lista de LatLng para string GeoJSON
  static String latLngListToGeoJSONString(List<LatLng> points, {bool pretty = false}) {
    final coordinates = points.map((point) => [point.longitude, point.latitude]).toList();
    
    // Garantir que o polígono está fechado
    if (coordinates.isNotEmpty && coordinates.first != coordinates.last) {
      coordinates.add(coordinates.first);
    }
    
    final feature = {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [coordinates],
      },
      'properties': {},
    };
    
    final featureCollection = {
      'type': 'FeatureCollection',
      'features': [feature],
    };
    
    if (pretty) {
      return JsonEncoder.withIndent('  ').convert(featureCollection);
    } else {
      return jsonEncode(featureCollection);
    }
  }

  /// Converte string GeoJSON para lista de LatLng
  static List<LatLng> geoJSONStringToLatLngList(String geoJSONString) {
    try {
      final data = jsonDecode(geoJSONString);
      final features = data['features'] as List;
      
      if (features.isEmpty) return [];
      
      final geometry = features.first['geometry'];
      final coordinates = geometry['coordinates'][0] as List;
      
      return coordinates.map((coord) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();
    } catch (e) {
      print('Erro ao converter GeoJSON: $e');
      return [];
    }
  }

  /// Calcula área em hectares usando projeção planar e fórmula de Shoelace
  static double calculateAreaHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Calcular latitude média para projeção
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    
    // Fatores de conversão para metros
    final metersPerDegLat = 111132.954 - 559.822 * cos(2 * avgLat * pi / 180) + 
                           1.175 * cos(4 * avgLat * pi / 180);
    final metersPerDegLng = (pi / 180) * 6378137.0 * cos(avgLat * pi / 180);
    
    // Converter para coordenadas em metros
    final xy = points.map((p) => MapEntry(
      (p.longitude - points.first.longitude) * metersPerDegLng,
      (p.latitude - points.first.latitude) * metersPerDegLat,
    )).toList();
    
    // Aplicar fórmula de Shoelace
    double sum = 0.0;
    for (int i = 0; i < xy.length - 1; i++) {
      final x1 = xy[i].key;
      final y1 = xy[i].value;
      final x2 = xy[i + 1].key;
      final y2 = xy[i + 1].value;
      sum += (x1 * y2) - (x2 * y1);
    }
    
    // Fechar o polígono
    final x1 = xy.last.key;
    final y1 = xy.last.value;
    final x2 = xy.first.key;
    final y2 = xy.first.value;
    sum += (x1 * y2) - (x2 * y1);
    
    final areaM2 = sum.abs() / 2.0;
    return areaM2 / 10000.0; // Converter para hectares
  }

  /// Calcula perímetro em metros usando geodésicas
  static double calculatePerimeterMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      perimeter += _calculateGeodesicDistance(p1, p2);
    }
    
    // Fechar o polígono se necessário
    if (points.first != points.last) {
      perimeter += _calculateGeodesicDistance(points.last, points.first);
    }
    
    return perimeter;
  }

  /// Calcula a distância geodésica entre dois pontos
  static double _calculateGeodesicDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6378137.0; // Raio da Terra em metros
    
    final lat1 = p1.latitude * pi / 180;
    final lat2 = p2.latitude * pi / 180;
    final deltaLat = (p2.latitude - p1.latitude) * pi / 180;
    final deltaLng = (p2.longitude - p1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Formata área com vírgula como separador decimal (formato brasileiro)
  static String formatArea(double areaHa) {
    if (areaHa < 0.0001) return '0 m²';
    if (areaHa < 1.0) {
      return formatAreaM2(areaHa * 10000, decimalPlaces: 1);
    } else if (areaHa < 100.0) {
      return formatAreaHa(areaHa, decimalPlaces: 2);
    } else {
      return formatAreaHa(areaHa, decimalPlaces: 1);
    }
  }

  /// Formata área em hectares
  static String formatAreaHa(double areaHa, {int decimalPlaces = 2}) {
    return '${areaHa.toStringAsFixed(decimalPlaces).replaceAll('.', ',')} ha';
  }

  /// Formata área em metros quadrados
  static String formatAreaM2(double areaM2, {int decimalPlaces = 1}) {
    return '${areaM2.toStringAsFixed(decimalPlaces).replaceAll('.', ',')} m²';
  }

  /// Formata perímetro em metros
  static String formatPerimeter(double perimeterM) {
    if (perimeterM < 1000) {
      return '${perimeterM.toStringAsFixed(1).replaceAll('.', ',')} m';
    } else {
      return '${(perimeterM / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';
    }
  }
}
