import 'dart:math';

/// Utilitário para cálculos de distância e navegação
class DistanceCalculator {
  static const double earthRadius = 6371000; // Raio da Terra em metros

  /// Calcula a distância entre dois pontos usando a fórmula de Haversine
  /// Retorna a distância em metros
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Calcula o bearing (direção) entre dois pontos
  /// Retorna o ângulo em graus (0-360)
  static double calculateBearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    
    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    
    var bearing = atan2(y, x);
    bearing = _radiansToDegrees(bearing);
    bearing = (bearing + 360) % 360;
    
    return bearing;
  }

  /// Valida se as coordenadas são válidas
  static bool isValidCoordinate(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  /// Valida se a precisão GPS é aceitável
  static bool isGpsAccuracyAcceptable(double accuracy, {double maxAccuracy = 10.0}) {
    return accuracy <= maxAccuracy;
  }

  /// Converte graus para radianos
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Converte radianos para graus
  static double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  /// Formata distância para exibição
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Calcula se o usuário está próximo o suficiente do ponto
  static bool isNearPoint(double distance, {double threshold = 5.0}) {
    return distance <= threshold;
  }

  /// Calcula se o usuário chegou ao ponto
  static bool hasArrivedAtPoint(double distance, {double arrivalThreshold = 2.0}) {
    return distance <= arrivalThreshold;
  }
}