import 'package:latlong2/latlong.dart';

/// 🚀 FORTSMART ORIGINAL - Normalizador de coordenadas geoespaciais
class CoordinateNormalizer {
  
  /// Normaliza uma lista de coordenadas
  static List<LatLng> normalize(List<LatLng> points) {
    if (points.isEmpty) return points;
    
    List<LatLng> normalized = [];
    
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Normalizar coordenadas
      final normalizedPoint = LatLng(
        _normalizeLatitude(point.latitude),
        _normalizeLongitude(point.longitude),
      );
      
      // Evitar pontos duplicados consecutivos
      if (normalized.isEmpty || normalized.last != normalizedPoint) {
        normalized.add(normalizedPoint);
      }
    }
    
    // Garantir que o polígono está fechado
    if (normalized.length >= 3 && normalized.first != normalized.last) {
      normalized.add(normalized.first);
    }
    
    return normalized;
  }
  
  /// Normaliza latitude para range válido
  static double _normalizeLatitude(double lat) {
    // Clamp para range válido
    if (lat < -90) return -90;
    if (lat > 90) return 90;
    
    // Arredondar para precisão razoável (6 casas decimais)
    return double.parse(lat.toStringAsFixed(6));
  }
  
  /// Normaliza longitude para range válido
  static double _normalizeLongitude(double lng) {
    // Normalizar para range -180 a 180
    while (lng < -180) lng += 360;
    while (lng > 180) lng -= 360;
    
    // Arredondar para precisão razoável (6 casas decimais)
    return double.parse(lng.toStringAsFixed(6));
  }
  
  /// Remove pontos muito próximos (simplificação)
  static List<LatLng> simplify(List<LatLng> points, {double tolerance = 0.0001}) {
    if (points.length <= 2) return points;
    
    List<LatLng> simplified = [points.first];
    
    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final last = simplified.last;
      
      // Calcular distância
      final distance = _calculateDistance(last, current);
      
      // Manter ponto se distância for maior que tolerância
      if (distance > tolerance) {
        simplified.add(current);
      }
    }
    
    // Adicionar último ponto se diferente do primeiro
    if (points.last != simplified.first) {
      simplified.add(points.last);
    }
    
    return simplified;
  }
  
  /// Calcula distância entre dois pontos (aproximação)
  static double _calculateDistance(LatLng point1, LatLng point2) {
    final latDiff = point1.latitude - point2.latitude;
    final lngDiff = point1.longitude - point2.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff);
  }
  
  /// Suaviza coordenadas (remove ruído)
  static List<LatLng> smooth(List<LatLng> points, {int windowSize = 3}) {
    if (points.length < windowSize) return points;
    
    List<LatLng> smoothed = [];
    
    for (int i = 0; i < points.length; i++) {
      if (i < windowSize ~/ 2 || i >= points.length - windowSize ~/ 2) {
        // Manter pontos das bordas
        smoothed.add(points[i]);
      } else {
        // Aplicar média móvel
        double latSum = 0;
        double lngSum = 0;
        int count = 0;
        
        for (int j = i - windowSize ~/ 2; j <= i + windowSize ~/ 2; j++) {
          if (j >= 0 && j < points.length) {
            latSum += points[j].latitude;
            lngSum += points[j].longitude;
            count++;
          }
        }
        
        smoothed.add(LatLng(latSum / count, lngSum / count));
      }
    }
    
    return smoothed;
  }
  
  /// Converte coordenadas para sistema de referência específico
  static List<LatLng> convertToWGS84(List<LatLng> points) {
    // WGS84 é o padrão do LatLng, então apenas normalizar
    return normalize(points);
  }
  
  /// Verifica se as coordenadas estão em WGS84
  static bool isWGS84(List<LatLng> points) {
    // Verificar se todas as coordenadas estão em range válido
    return points.every((point) => 
      point.latitude >= -90 && point.latitude <= 90 &&
      point.longitude >= -180 && point.longitude <= 180
    );
  }
  
  /// Aplica transformação de coordenadas (se necessário)
  static List<LatLng> transform(List<LatLng> points, {
    double offsetLat = 0,
    double offsetLng = 0,
    double scale = 1.0,
  }) {
    return points.map((point) => LatLng(
      (point.latitude + offsetLat) * scale,
      (point.longitude + offsetLng) * scale,
    )).toList();
  }

  /// Método de conveniência para normalização síncrona
  static List<LatLng> normalizeCoordinatesSync(List<LatLng> coordinates) {
    return normalize(coordinates);
  }
}