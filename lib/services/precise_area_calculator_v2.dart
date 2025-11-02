import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Calculadora de área precisa V2 - Padrão do módulo talhões
class PreciseAreaCalculatorV2 {
  /// Calcula a área de um desenho manual usando a fórmula de Shoelace
  static double calculateManualDrawingArea(List<LatLng> pontos) {
    if (pontos.length < 3) return 0.0;
    
    // Converter para coordenadas UTM para cálculo preciso
    final utmCoords = _converterParaUTM(pontos);
    
    // Aplicar fórmula de Shoelace
    double area = 0.0;
    final n = utmCoords.length;
    
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += utmCoords[i].x * utmCoords[j].y;
      area -= utmCoords[j].x * utmCoords[i].y;
    }
    
    area = (area.abs() / 2.0) / 10000; // Converter de m² para hectares
    return area;
  }
  
  /// Calcula o perímetro de um polígono
  static double calculatePerimeter(List<LatLng> pontos) {
    if (pontos.length < 2) return 0.0;
    
    double perimetro = 0.0;
    
    for (int i = 0; i < pontos.length; i++) {
      final j = (i + 1) % pontos.length;
      perimetro += _calcularDistancia(pontos[i], pontos[j]);
    }
    
    return perimetro;
  }
  
  /// Converte coordenadas lat/lng para UTM
  static List<UTMCoord> _converterParaUTM(List<LatLng> pontos) {
    if (pontos.isEmpty) return [];
    
    // Calcular meridiano central baseado na longitude média
    final longitudeMedia = pontos.map((p) => p.longitude).reduce((a, b) => a + b) / pontos.length;
    final meridianoCentral = (longitudeMedia / 6).floor() * 6 + 3;
    
    // Parâmetros WGS84
    const double a = 6378137.0; // Semi-eixo maior
    const double e2 = 0.00669438; // Excentricidade ao quadrado
    const double k0 = 0.9996; // Fator de escala
    const double x0 = 500000; // Falso leste
    
    // Calcular latitude média para falso norte
    final latitudeMedia = pontos.map((p) => p.latitude).reduce((a, b) => a + b) / pontos.length;
    final double y0 = latitudeMedia < 0 ? 10000000 : 0;
    
    final List<UTMCoord> coordenadasUtm = [];
    
    for (final coord in pontos) {
      final phi = coord.latitude * pi / 180; // Latitude em radianos
      final lambda = coord.longitude * pi / 180; // Longitude em radianos
      final lambda0 = meridianoCentral * pi / 180; // Meridiano central em radianos
      
      // Cálculo de N (raio de curvatura da primeira vertical)
      final N = a / sqrt(1 - e2 * sin(phi) * sin(phi));
      
      // Cálculo do arco meridional M
      final M = a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * phi
          - (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * sin(2 * phi)
          + (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * sin(4 * phi)
          - (35 * e2 * e2 * e2 / 3072) * sin(6 * phi));
      
      // Coordenadas UTM simplificadas
      final x = k0 * N * (lambda - lambda0) * cos(phi) + x0;
      final y = k0 * (M + N * tan(phi) * pow(lambda - lambda0, 2) / 2) + y0;
      
      coordenadasUtm.add(UTMCoord(x, y));
    }
    
    return coordenadasUtm;
  }
  
  /// Calcula a distância entre dois pontos usando a fórmula de Haversine
  static double _calcularDistancia(LatLng ponto1, LatLng ponto2) {
    const double raioTerra = 6371000; // Raio da Terra em metros
    
    final lat1Rad = ponto1.latitude * pi / 180;
    final lat2Rad = ponto2.latitude * pi / 180;
    final deltaLatRad = (ponto2.latitude - ponto1.latitude) * pi / 180;
    final deltaLngRad = (ponto2.longitude - ponto1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return raioTerra * c;
  }
}

/// Classe para coordenadas UTM
class UTMCoord {
  final double x;
  final double y;
  
  UTMCoord(this.x, this.y);
}
