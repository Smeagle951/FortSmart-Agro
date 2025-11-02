import 'dart:math';
// Importar o adaptador global em vez do Google Maps
import 'map_imports.dart' as maps;

/// Classe utilitária para calcular áreas de polígonos
class AreaCalculator {
  /// Calcula a área de um polígono em hectares
  /// 
  /// Utiliza o algoritmo do Shoelace (Gauss's area formula) para calcular
  /// a área de um polígono a partir de suas coordenadas.
  static double calculateArea(List<maps.LatLng> points) {
    return calculateAreaInHectares(points);
  }
  
  /// Calcula a área de um polígono em hectares
  /// 
  /// Utiliza o algoritmo do Shoelace (Gauss's area formula) para calcular
  /// a área de um polígono a partir de suas coordenadas.
  static double calculateAreaInHectares(List<maps.LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Converter coordenadas para UTM para maior precisão
    final utmPoints = _convertToUtm(points);
    
    // Calcular área usando o algoritmo do Shoelace (Gauss's area formula)
    double area = 0.0;
    for (int i = 0; i < utmPoints.length; i++) {
      int j = (i + 1) % utmPoints.length;
      area += utmPoints[i].x * utmPoints[j].y;
      area -= utmPoints[j].x * utmPoints[i].y;
    }
    
    area = area.abs() / 2.0;
    
    // Converter de metros quadrados para hectares (1 hectare = 10.000 m²)
    return area / 10000.0;
  }
  
  /// Converte coordenadas geográficas (lat/lng) para UTM (metros)
  /// 
  /// Esta é uma implementação simplificada da conversão para UTM.
  /// Para aplicações que exigem alta precisão, considere usar uma biblioteca
  /// de projeção cartográfica completa.
  static List<Point<double>> _convertToUtm(List<maps.LatLng> points) {
    if (points.isEmpty) return [];
    
    // Calcular o centro do polígono para usar como referência
    double centerLat = 0.0;
    double centerLng = 0.0;
    
    for (var point in points) {
      centerLat += point.latitude;
      centerLng += point.longitude;
    }
    
    centerLat /= points.length;
    centerLng /= points.length;
    
    // Fator de conversão aproximado (em metros por grau)
    // 111,320 metros por grau de latitude
    // 111,320 * cos(latitude) metros por grau de longitude
    final double latFactor = 111320.0;
    final double lngFactor = 111320.0 * cos(centerLat * pi / 180.0);
    
    // Converter pontos para UTM
    final List<Point<double>> utmPoints = [];
    
    for (var point in points) {
      final double x = (point.longitude - centerLng) * lngFactor;
      final double y = (point.latitude - centerLat) * latFactor;
      utmPoints.add(Point(x, y));
    }
    
    return utmPoints;
  }
}
