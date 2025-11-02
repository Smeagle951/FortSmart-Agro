import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

/// Calculadora específica para o modo caminhada GPS
/// Implementa Shoelace + UTM para área e Haversine para perímetro
class GpsWalkCalculator {
  // Constantes geodésicas
  static const double _earthRadius = 6371000.0; // Raio médio da Terra em metros
  static const double _metersPerHectare = 10000.0; // 1 hectare = 10.000 m²
  
  // Constantes UTM
  static const double _utmFalseEasting = 500000.0;
  static const double _utmFalseNorthing = 10000000.0;
  static const double _utmScaleFactor = 0.9996;
  static const double _utmOriginLatitude = 0.0;
  static const double _utmOriginLongitude = -87.0; // Zona UTM 16 (Brasil central)
  
  /// Calcula área de polígono usando Shoelace em UTM
  /// Converte pontos GPS (lat/lon WGS84) para UTM (x,y em metros)
  static double calculatePolygonAreaHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    try {
      // Converter todos os pontos para UTM
      final utmPoints = points.map((point) => _latLngToUtm(point)).toList();
      
      // Aplicar algoritmo Shoelace
      double area = 0.0;
      final n = utmPoints.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        area += utmPoints[i]['x']! * utmPoints[j]['y']!;
        area -= utmPoints[j]['x']! * utmPoints[i]['y']!;
      }
      
      // Área em m²
      final areaM2 = (area.abs() / 2.0);
      
      // Converter para hectares
      return areaM2 / _metersPerHectare;
      
    } catch (e) {
      print('❌ Erro no cálculo de área Shoelace+UTM: $e');
      return 0.0;
    }
  }
  
  /// Calcula perímetro usando fórmula de Haversine
  /// Soma das distâncias entre pontos consecutivos
  static double calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    try {
      double perimeter = 0.0;
      final n = points.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        perimeter += haversineDistance(points[i], points[j]);
      }
      
      return perimeter;
      
    } catch (e) {
      print('❌ Erro no cálculo de perímetro Haversine: $e');
      return 0.0;
    }
  }
  
  /// Calcula distância entre dois pontos usando fórmula de Haversine
  static double haversineDistance(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
              cos(lat1Rad) * cos(lat2Rad) *
              sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return _earthRadius * c;
  }
  
  /// Converte coordenadas LatLng para UTM
  static Map<String, double> _latLngToUtm(LatLng point) {
    final latRad = point.latitude * pi / 180;
    final lonRad = point.longitude * pi / 180;
    
    // Calcular zona UTM (simplificado para Brasil central)
    final zone = 22; // Zona UTM para Brasil central
    
    // Calcular longitude central da zona
    final lon0 = (zone - 1) * 6 - 180 + 3;
    final lon0Rad = lon0 * pi / 180;
    
    // Calcular diferença de longitude
    final deltaLon = lonRad - lon0Rad;
    
    // Calcular coordenadas UTM
    final n = _utmScaleFactor / sqrt(1 + _eccentricitySquared * pow(cos(latRad), 2));
    final t = tan(latRad);
    final c = _eccentricitySquared * pow(cos(latRad), 2) / (1 - _eccentricitySquared);
    final a = cos(latRad) * deltaLon;
    
    final m = _earthRadius * ((1 - _eccentricitySquared / 4 - 3 * pow(_eccentricitySquared, 2) / 64 - 5 * pow(_eccentricitySquared, 3) / 256) * latRad -
                              (3 * _eccentricitySquared / 8 + 3 * pow(_eccentricitySquared, 2) / 32 + 45 * pow(_eccentricitySquared, 3) / 1024) * sin(2 * latRad) +
                              (15 * pow(_eccentricitySquared, 2) / 256 + 45 * pow(_eccentricitySquared, 3) / 1024) * sin(4 * latRad) -
                              (35 * pow(_eccentricitySquared, 3) / 3072) * sin(6 * latRad));
    
    final x = _utmFalseEasting + n * (a + (1 - t * t + c) * pow(a, 3) / 6 + (5 - 18 * t * t + pow(t, 4) + 72 * c - 58 * _eccentricitySquared) * pow(a, 5) / 120);
    final y = _utmFalseNorthing + m + n * t * (pow(a, 2) / 2 + (5 - t * t + 9 * c + 4 * pow(c, 2)) * pow(a, 4) / 24 + (61 - 58 * t * t + pow(t, 4) + 600 * c - 330 * _eccentricitySquared) * pow(a, 6) / 720);
    
    return {'x': x, 'y': y};
  }
  
  // Constantes para cálculo UTM
  static const double _eccentricitySquared = 0.00669438; // WGS84
  
  /// Valida se um polígono é válido
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Verificar se não há pontos duplicados consecutivos
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].latitude == points[i + 1].latitude &&
          points[i].longitude == points[i + 1].longitude) {
        return false;
      }
    }
    
    // Verificar se o primeiro e último ponto são diferentes
    if (points.first.latitude == points.last.latitude && 
        points.first.longitude == points.last.longitude) {
      return false;
    }
    
    return true;
  }
  
  /// Fecha polígono automaticamente se necessário
  static List<LatLng> closePolygon(List<LatLng> points) {
    if (points.length < 3) return points;
    
    final firstPoint = points.first;
    final lastPoint = points.last;
    
    // Calcular distância entre primeiro e último ponto
    final distance = haversineDistance(firstPoint, lastPoint);
    
    // Se a distância for maior que 5 metros, adicionar o primeiro ponto no final
    if (distance > 5.0) {
      final closedPoints = List<LatLng>.from(points);
      closedPoints.add(firstPoint);
      return closedPoints;
    }
    
    return points;
  }
  
  /// Calcula métricas completas do polígono
  static Map<String, double> calculatePolygonMetrics(List<LatLng> points) {
    if (points.length < 3) {
      return {
        'area': 0.0,
        'perimeter': 0.0,
        'vertices': 0.0,
        'isValid': 0.0,
      };
    }
    
    final area = calculatePolygonAreaHectares(points);
    final perimeter = calculatePolygonPerimeter(points);
    final isValid = isValidPolygon(points) ? 1.0 : 0.0;
    
    return {
      'area': area,
      'perimeter': perimeter,
      'vertices': points.length.toDouble(),
      'isValid': isValid,
    };
  }
  
  /// Formata área em hectares no padrão brasileiro
  static String formatAreaBrazilian(double areaHectares, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'pt_BR');
    return '${formatter.format(areaHectares)} ha';
  }
  
  /// Formata perímetro em metros no padrão brasileiro
  static String formatPerimeterBrazilian(double perimeterMeters, {int decimals = 1}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'pt_BR');
    return '${formatter.format(perimeterMeters)} m';
  }
}
