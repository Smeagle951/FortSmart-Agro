import 'dart:math';
// Importar o adaptador global em vez do Google Maps
import 'map_imports.dart' as maps;

/// Utilitários para cálculos geográficos
class GeoUtils {
  /// Calcula a área de um polígono em hectares
  /// Usa a fórmula de Gauss (ou Shoelace)
  static double calculatePolygonArea(List<maps.LatLng> points) {
    if (points.length < 3) return 0;
    
    // Converter coordenadas para UTM (aproximação)
    // Usamos a fórmula haversine para calcular a distância entre pontos
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      
      // Coordenadas do ponto atual e do próximo ponto
      final maps.LatLng p1 = points[i];
      final maps.LatLng p2 = points[j];
      
      // Convertendo para metros (aproximação usando a fórmula haversine)
      final double x1 = _longitudeToMeters(p1.longitude, p1.latitude);
      final double y1 = _latitudeToMeters(p1.latitude);
      final double x2 = _longitudeToMeters(p2.longitude, p2.latitude);
      final double y2 = _latitudeToMeters(p2.latitude);
      
      area += (x1 * y2) - (x2 * y1);
    }
    
    // Valor absoluto da área dividido por 2
    area = (area.abs() / 2.0);
    
    // Converter de metros quadrados para hectares
    return area / 10000.0;
  }
  
  /// Converte longitude para metros (aproximação)
  static double _longitudeToMeters(double longitude, double latitude) {
    // Raio da Terra em metros
    const double earthRadius = 6378137.0;
    
    // Converter para radianos
    final double latRad = _toRadians(latitude);
    final double lonRad = _toRadians(longitude);
    
    // Longitude em metros
    return earthRadius * lonRad * cos(latRad);
  }
  
  /// Converte latitude para metros (aproximação)
  static double _latitudeToMeters(double latitude) {
    // Raio da Terra em metros
    const double earthRadius = 6378137.0;
    
    // Converter para radianos
    final double latRad = _toRadians(latitude);
    
    // Latitude em metros
    return earthRadius * latRad;
  }
  
  /// Converte graus para radianos
  static double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
  
  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(maps.LatLng p1, maps.LatLng p2) {
    // Raio da Terra em metros
    const double earthRadius = 6378137.0;
    
    // Converter para radianos
    final double lat1 = _toRadians(p1.latitude);
    final double lon1 = _toRadians(p1.longitude);
    final double lat2 = _toRadians(p2.latitude);
    final double lon2 = _toRadians(p2.longitude);
    
    // Fórmula haversine
    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;
    double a = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Verifica se um ponto está dentro de um polígono usando o algoritmo ray casting
  /// Retorna true se o ponto estiver dentro do polígono, false caso contrário
  static bool isPointInPolygon(maps.LatLng point, List<maps.LatLng> polygon) {
    // Se o polígono tiver menos de 3 pontos, não é um polígono válido
    if (polygon.length < 3) return false;
    
    // Implementação do algoritmo ray casting (ou point-in-polygon)
    bool isInside = false;
    int i = 0, j = polygon.length - 1;
    
    for (i = 0; i < polygon.length; i++) {
      // Verifica se o ponto está em um dos vértices do polígono
      if (polygon[i].latitude == point.latitude && polygon[i].longitude == point.longitude) {
        return true; // O ponto está exatamente em um vértice
      }
      
      // Verifica se o raio cruza a aresta do polígono
      if ((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
          (point.latitude - polygon[i].latitude) / 
          (polygon[j].latitude - polygon[i].latitude) + 
          polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    
    return isInside;
  }
}
