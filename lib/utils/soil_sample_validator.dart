import '../models/soil_sample.dart';
import 'logger.dart';
import 'dart:math';
import 'package:intl/intl.dart'; // Adicionado para usar o DateFormat

/// Utilitário para validar e formatar dados de amostras de solo
class SoilSampleValidator {
  /// Valida uma amostra de solo completa
  static bool validateSoilSample(SoilSample sample) {
    try {
      // Verificar campos obrigatórios
      if (sample.plotId <= 0) {
        Logger.log('Validação falhou: ID do talhão inválido');
        return false;
      }
      
      if (sample.samplePoints.isEmpty) {
        Logger.log('Validação falhou: Nenhum ponto de amostragem');
        return false;
      }
      
      // Validar cada ponto de amostragem
      for (final point in sample.samplePoints) {
        if (!validateSamplePoint(point)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('Erro ao validar amostra de solo', e);
      return false;
    }
  }
  
  /// Valida um ponto de amostragem
  static bool validateSamplePoint(SoilSamplePoint point) {
    try {
      // Verificar coordenadas geográficas
      if (point.latitude == 0 || point.longitude == 0) {
        Logger.log('Validação falhou: Latitude ou longitude inválida');
        return false;
      }
      
      if (point.latitude < -90 || point.latitude > 90) {
        Logger.log('Validação falhou: Latitude inválida (${point.latitude})');
        return false;
      }
      
      if (point.longitude < -180 || point.longitude > 180) {
        Logger.log('Validação falhou: Longitude inválida (${point.longitude})');
        return false;
      }
      
      // Verificar profundidade
      if (point.depth == null || point.depth! <= 0) {
        Logger.log('Validação falhou: Profundidade inválida');
        return false;
      }
      
      return true;
    } catch (e) {
      Logger.error('Erro ao validar ponto de amostragem', e);
      return false;
    }
  }
  
  /// Formata as coordenadas geográficas para exibição
  static String formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final longDirection = longitude >= 0 ? 'E' : 'W';
    
    final latAbs = latitude.abs();
    final longAbs = longitude.abs();
    
    final latDegrees = latAbs.floor();
    final latMinutes = ((latAbs - latDegrees) * 60).floor();
    final latSeconds = ((latAbs - latDegrees - latMinutes / 60) * 3600).toStringAsFixed(2);
    
    final longDegrees = longAbs.floor();
    final longMinutes = ((longAbs - longDegrees) * 60).floor();
    final longSeconds = ((longAbs - longDegrees - longMinutes / 60) * 3600).toStringAsFixed(2);
    
    return '$latDegrees°$latMinutes\'$latSeconds" $latDirection, $longDegrees°$longMinutes\'$longSeconds" $longDirection';
  }
  
  /// Formata a profundidade para exibição
  static String formatDepth(double depthInCm) {
    if (depthInCm < 100) {
      return '$depthInCm cm';
    } else {
      final meters = depthInCm / 100;
      return '${meters.toStringAsFixed(2)} m';
    }
  }
  
  /// Gera um resumo da amostra de solo
  static String generateSampleSummary(SoilSample sample) {
    final pointCount = sample.samplePoints.length;
    final date = sample.startDate;
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    
    return 'Amostra coletada em $formattedDate com $pointCount pontos.';
  }
  
  /// Verifica se há problemas com a amostra e retorna mensagens de aviso
  static List<String> checkForWarnings(SoilSample sample) {
    final warnings = <String>[];
    
    // Verificar se há poucos pontos de amostragem
    if (sample.samplePoints.length < 3) {
      warnings.add('Poucos pontos de amostragem. Recomenda-se pelo menos 3 pontos.');
    }
    
    // Verificar se há pontos sem foto
    final pointsWithoutPhotos = sample.samplePoints
        .where((point) => point.photoUrl == null || point.photoUrl!.isEmpty)
        .length;
    
    if (pointsWithoutPhotos > 0) {
      warnings.add('$pointsWithoutPhotos ${pointsWithoutPhotos == 1 ? 'ponto está' : 'pontos estão'} sem foto.');
    }
    
    // Verificar se há pontos muito próximos
    for (int i = 0; i < sample.samplePoints.length; i++) {
      for (int j = i + 1; j < sample.samplePoints.length; j++) {
        final point1 = sample.samplePoints[i];
        final point2 = sample.samplePoints[j];
        
        final distance = _calculateDistance(
          point1.latitude, point1.longitude,
          point2.latitude, point2.longitude
        );
        
        // Se a distância for menor que 5 metros
        if (distance < 5) {
          warnings.add('Pontos ${i+1} e ${j+1} estão muito próximos (${distance.toStringAsFixed(2)}m).');
        }
      }
    }
    
    return warnings;
  }
  
  /// Calcula a distância aproximada entre dois pontos geográficos em metros
  /// Usando a fórmula de Haversine
  static double _calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2
  ) {
    const earthRadius = 6371000; // metros
    
    // Converter para radianos
    final phi1 = lat1 * (pi / 180);
    final phi2 = lat2 * (pi / 180);
    final deltaPhi = (lat2 - lat1) * (pi / 180);
    final deltaLambda = (lon2 - lon1) * (pi / 180);
    
    final a = _sin2(deltaPhi / 2) + 
              cos(phi1) * cos(phi2) * 
              _sin2(deltaLambda / 2);
    final sqrtA = sqrt(a);
    final sqrtOneMinusA = sqrt(1 - a);
    final c = 2 * atan2(sqrtA, sqrtOneMinusA);
    
    return earthRadius * c;
  }
  
  // Funções matemáticas auxiliares
  static double _sin2(double x) => sin(x) * sin(x);
  static double _sin(double x) => sin(x);
  static double _cos(double x) => cos(x);
  static double _atan2(double y, double x) => atan2(y, x);
  static double _sqrt(double x) => sqrt(x);
}
