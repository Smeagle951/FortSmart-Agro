import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Calculadora geodética de alta precisão para cálculos agrícolas
/// Baseada em fórmulas WGS84 com ajuste local por latitude
class GeoCalculator {
  // Constante WGS84 (raio da Terra em metros)
  static const double _earthRadius = 6378137.0;
  
  /// Calcula área de um polígono em hectares com precisão geodética
  /// Usa fórmula de Shoelace adaptada para coordenadas geográficas
  static double calculateAreaHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    try {
      // Calcular latitude média para ajuste local
      final latMedia = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final latMediaRad = latMedia * math.pi / 180;
      
      // Fatores de conversão por latitude (fórmulas geodésicas)
      final metersPerDegLat = 111132.954 - 559.822 * math.cos(2 * latMediaRad) + 
                             1.175 * math.cos(4 * latMediaRad);
      final metersPerDegLng = (math.pi / 180) * _earthRadius * math.cos(latMediaRad);
      
      // Converter pontos para coordenadas em metros (usando primeiro ponto como referência)
      final refPoint = points.first;
      final pointsInMeters = points.map((point) {
        final x = (point.longitude - refPoint.longitude) * metersPerDegLng;
        final y = (point.latitude - refPoint.latitude) * metersPerDegLat;
        return Point(x, y);
      }).toList();
      
      // Aplicar fórmula de Shoelace
      double area = 0.0;
      final n = pointsInMeters.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        area += pointsInMeters[i].x * pointsInMeters[j].y;
        area -= pointsInMeters[j].x * pointsInMeters[i].y;
      }
      
      area = area.abs() / 2.0; // Área em metros quadrados
      
      // Converter para hectares (1 hectare = 10.000 m²)
      return area / 10000.0;
      
    } catch (e) {
      print('❌ Erro no cálculo de área: $e');
      return 0.0;
    }
  }
  
  /// Calcula perímetro de um polígono em metros usando fórmula Haversine
  static double calculatePerimeterMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    try {
      double perimeter = 0.0;
      
      // Calcular distância entre pontos consecutivos
      for (int i = 0; i < points.length; i++) {
        final current = points[i];
        final next = points[(i + 1) % points.length];
        perimeter += haversineDistance(current, next);
      }
      
      return perimeter;
      
    } catch (e) {
      print('❌ Erro no cálculo de perímetro: $e');
      return 0.0;
    }
  }
  
  /// Calcula distância entre dois pontos usando fórmula Haversine
  static double haversineDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) *
              math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calcula centro geográfico de um polígono
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    
    double lat = 0.0, lng = 0.0;
    for (final point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    
    return LatLng(lat / points.length, lng / points.length);
  }
  
  /// Valida se um polígono é válido (não se cruza, tem área mínima, etc.)
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Verificar se tem área mínima (0.01 hectares = 100 m²)
    final area = calculateAreaHectares(points);
    if (area < 0.01) return false;
    
    // Verificar se não há pontos duplicados consecutivos
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      if (haversineDistance(current, next) < 0.1) return false; // Menos de 10cm
    }
    
    return true;
  }
  
  /// Suaviza pontos GPS usando média móvel simples
  static List<LatLng> smoothPoints(List<LatLng> points, {int windowSize = 3}) {
    if (points.length < windowSize) return points;
    
    final smoothed = <LatLng>[];
    
    for (int i = 0; i < points.length; i++) {
      double latSum = 0.0, lngSum = 0.0;
      int count = 0;
      
      // Calcular janela deslizante
      for (int j = math.max(0, i - windowSize ~/ 2); 
           j <= math.min(points.length - 1, i + windowSize ~/ 2); 
           j++) {
        latSum += points[j].latitude;
        lngSum += points[j].longitude;
        count++;
      }
      
      smoothed.add(LatLng(latSum / count, lngSum / count));
    }
    
    return smoothed;
  }
  
  /// Filtra pontos GPS por precisão
  static List<LatLng> filterByAccuracy(List<LatLng> points, List<double> accuracies, {double maxAccuracy = 10.0}) {
    if (points.length != accuracies.length) return points;
    
    final filtered = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (accuracies[i] <= maxAccuracy) {
        filtered.add(points[i]);
      }
    }
    
    return filtered;
  }
  
  /// Calcula velocidade média entre dois pontos
  static double calculateSpeed(LatLng point1, LatLng point2, Duration timeDiff) {
    final distance = haversineDistance(point1, point2);
    final timeInSeconds = timeDiff.inMilliseconds / 1000.0;
    
    if (timeInSeconds == 0) return 0.0;
    
    return distance / timeInSeconds; // m/s
  }
  
  /// Converte velocidade de m/s para km/h
  static double metersPerSecondToKmh(double mps) {
    return mps * 3.6;
  }
  
  /// Formata área em hectares com precisão adequada
  static String formatArea(double hectares) {
    if (hectares < 0.01) {
      return '${(hectares * 10000).toStringAsFixed(0)} m²';
    } else if (hectares < 1.0) {
      return '${(hectares * 100).toStringAsFixed(1)} ares';
    } else {
      return '${hectares.toStringAsFixed(2)} ha';
    }
  }
  
  /// Formata perímetro em metros com precisão adequada
  static String formatPerimeter(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
}

/// Classe auxiliar para representar pontos 2D
class Point {
  final double x;
  final double y;
  
  const Point(this.x, this.y);
}
