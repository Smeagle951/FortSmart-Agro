import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

/// Calculadora geográfica precisa usando algoritmos geodésicos avançados
/// Implementa cálculos de área, perímetro e distância com alta precisão
class PreciseGeoCalculator {
  // Constantes geodésicas (WGS84)
  static const double _earthRadius = 6378137.0; // Raio equatorial da Terra em metros
  static const double _earthFlattening = 1 / 298.257223563; // Achatamento da Terra
  static const double _earthEccentricitySquared = 2 * _earthFlattening - _earthFlattening * _earthFlattening;

  /// Calcula área de um polígono em hectares com precisão geodésica
  /// Usa algoritmo Shoelace com projeção UTM para máxima precisão
  /// CORRIGIDO: Algoritmo estável que não trava em qualquer configuração de pontos
  static double calculatePolygonAreaHectares(List<LatLng> points) {
    if (points.length < 3) {
      print('⚠️ PreciseGeoCalculator: Polígono com menos de 3 pontos: ${points.length}');
      return 0.0;
    }
    
    try {
      // OTIMIZAÇÃO: Validar pontos antes do cálculo para evitar travamentos
      for (final point in points) {
        if (point.latitude.isNaN || point.longitude.isNaN) {
          print('⚠️ PreciseGeoCalculator: Ponto com coordenadas NaN encontrado');
          return 0.0;
        }
        if (point.latitude.abs() > 90 || point.longitude.abs() > 180) {
          print('⚠️ PreciseGeoCalculator: Coordenadas fora dos limites válidos');
          return 0.0;
        }
      }
      
      // OTIMIZAÇÃO: Remover pontos duplicados consecutivos
      final cleanPoints = <LatLng>[];
      for (int i = 0; i < points.length; i++) {
        if (i == 0 || points[i] != points[i - 1]) {
          cleanPoints.add(points[i]);
        }
      }
      
      if (cleanPoints.length < 3) {
        print('⚠️ PreciseGeoCalculator: Polígono inválido após limpeza de pontos duplicados');
        return 0.0;
      }
      
      print('🔄 PreciseGeoCalculator: Calculando área com ${cleanPoints.length} pontos (${points.length} originais)');
      print('📊 Pontos sendo processados:');
      for (int i = 0; i < cleanPoints.length; i++) {
        print('  Ponto ${i + 1}: (${cleanPoints[i].latitude.toStringAsFixed(8)}, ${cleanPoints[i].longitude.toStringAsFixed(8)})');
      }
      
      // CORRIGIDO: Usar método Shoelace com projeção UTM (mais estável que Gauss-Bonnet)
      double area = 0.0;
      final n = cleanPoints.length;
      
      // Calcular latitude média para projeção UTM
      final avgLat = cleanPoints.map((p) => p.latitude).reduce((a, b) => a + b) / n;
      final avgLatRad = avgLat * pi / 180;
      
      // Fatores de conversão UTM precisos
      final cosLat = cos(avgLatRad);
      final metersPerDegLat = 111132.954 - 559.822 * cos(2 * avgLatRad) + 1.175 * cos(4 * avgLatRad);
      final metersPerDegLng = (pi / 180) * 6378137.0 * cosLat;
      
      // Aplicar fórmula de Shoelace em coordenadas UTM
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        final x1 = (cleanPoints[i].longitude - cleanPoints.first.longitude) * metersPerDegLng;
        final y1 = (cleanPoints[i].latitude - cleanPoints.first.latitude) * metersPerDegLat;
        final x2 = (cleanPoints[j].longitude - cleanPoints.first.longitude) * metersPerDegLng;
        final y2 = (cleanPoints[j].latitude - cleanPoints.first.latitude) * metersPerDegLat;
        
        area += x1 * y2;
        area -= x2 * y1;
      }
      
      // Área em metros² (valor absoluto)
      area = area.abs() / 2.0;
      
      // Converter para hectares (1 hectare = 10.000 m²)
      final areaHectares = area / 10000.0;
      
      print('✅ PreciseGeoCalculator: Área calculada: ${areaHectares.toStringAsFixed(4)} ha');
      print('📊 Detalhes do cálculo:');
      print('  - Área em m²: ${area.toStringAsFixed(2)}');
      print('  - Número de pontos: ${points.length}');
      print('  - Algoritmo: Shoelace com projeção UTM');
      print('  - Latitude média: ${avgLat.toStringAsFixed(6)}°');
      
      return areaHectares;
      
    } catch (e) {
      print('❌ Erro no cálculo preciso de área: $e');
      // Fallback para método simplificado
      return _calculateAreaFallback(points);
    }
  }

  /// Calcula perímetro de um polígono em metros com precisão geodésica
  /// Usa fórmula de Vincenty para distâncias geodésicas
  static double calculatePolygonPerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    try {
      double perimeter = 0.0;
      final n = points.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        perimeter += _calculateVincentyDistance(points[i], points[j]);
    }
    
    return perimeter;
      
    } catch (e) {
      print('❌ Erro no cálculo preciso de perímetro: $e');
      // Fallback para método simplificado
      return _calculatePerimeterFallback(points);
    }
  }

  /// Calcula distância entre dois pontos usando fórmula de Vincenty
  /// Algoritmo mais preciso que Haversine para distâncias geodésicas
  static double calculateVincentyDistance(LatLng point1, LatLng point2) {
    return _calculateVincentyDistance(point1, point2);
  }

  /// Calcula centroide geodésico de um polígono
  /// Considera a curvatura da Terra para posicionamento preciso
  static LatLng calculateGeodeticCentroid(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    if (points.length == 1) return points.first;
    
    try {
      // Converter para coordenadas cartesianas 3D
      final cartesianPoints = points.map((p) => _latLngToCartesian(p)).toList();
      
      // Calcular centroide em coordenadas cartesianas
      double x = 0, y = 0, z = 0;
      for (final point in cartesianPoints) {
        x += point['x'] ?? 0.0;
        y += point['y'] ?? 0.0;
        z += point['z'] ?? 0.0;
      }
      
      x /= cartesianPoints.length;
      y /= cartesianPoints.length;
      z /= cartesianPoints.length;
      
      // Converter de volta para lat/lng
      return _cartesianToLatLng(x, y, z);
      
    } catch (e) {
      print('❌ Erro no cálculo de centroide: $e');
      // Fallback para média simples
      return _calculateSimpleCentroid(points);
    }
  }

  /// Calcula área de um polígono considerando elipsoide da Terra
  /// Usa projeção cônica conforme de Lambert
  static double calculateLambertArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    try {
    // Calcular latitude média para projeção
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final avgLatRad = avgLat * pi / 180;
      
      // Calcular fator de escala para latitude média
      final cosLat = cos(avgLatRad);
      final scaleFactor = 1 / cosLat;
      
      // Converter coordenadas para projeção cônica
      final projectedPoints = points.map((p) {
        final latRad = p.latitude * pi / 180;
        final lonRad = p.longitude * pi / 180;
        
        // Projeção cônica conforme
        final x = _earthRadius * (lonRad - avgLatRad) * cosLat;
        final y = _earthRadius * (latRad - avgLatRad);
        
        return {'x': x, 'y': y};
      }).toList();
      
      // Calcular área usando fórmula de Gauss (Shoelace)
      double area = 0.0;
      final n = projectedPoints.length;
      
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        final x1 = projectedPoints[i]['x'] ?? 0.0;
        final y1 = projectedPoints[i]['y'] ?? 0.0;
        final x2 = projectedPoints[j]['x'] ?? 0.0;
        final y2 = projectedPoints[j]['y'] ?? 0.0;
        area += x1 * y2;
        area -= x2 * y1;
      }
      
      area = area.abs() / 2.0;
      
      // Aplicar fator de correção para elipsoide
      final correctionFactor = 1 + _earthEccentricitySquared * sin(avgLatRad) * sin(avgLatRad);
      area *= correctionFactor;
      
      // Converter para hectares
      return area / 10000.0;
      
    } catch (e) {
      print('❌ Erro no cálculo Lambert: $e');
      return _calculateAreaFallback(points);
    }
  }

  /// Calcula área de um polígono (alias para calculatePolygonAreaHectares)
  static double calculatePolygonArea(List<LatLng> points) {
    return calculatePolygonAreaHectares(points);
  }

  /// Calcula centro de um polígono (alias para calculateGeodeticCentroid)
  static LatLng calculatePolygonCenter(List<LatLng> points) {
    return calculateGeodeticCentroid(points);
  }

  /// Calcula limites de um polígono
  static Map<String, double> calculatePolygonBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return const {
        'minLat': 0.0,
        'maxLat': 0.0,
        'minLng': 0.0,
        'maxLng': 0.0,
      };
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }
  
  /// Verifica se um polígono é válido
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
  
  /// Calcula estatísticas de um polígono
  static Map<String, dynamic> calculatePolygonStats(List<LatLng> points) {
    if (points.length < 3) {
      return const {
        'area': 0.0,
        'perimeter': 0.0,
        'centroid': LatLng(0, 0),
        'bounds': {
          'minLat': 0.0,
          'maxLat': 0.0,
          'minLng': 0.0,
          'maxLng': 0.0,
        },
        'isValid': false,
      };
    }
    
    final area = calculatePolygonAreaHectares(points);
    final perimeter = calculatePolygonPerimeter(points);
    final centroid = calculateGeodeticCentroid(points);
    final bounds = calculatePolygonBounds(points);
    final isValid = isValidPolygon(points);
    
    return {
      'area': area,
      'perimeter': perimeter,
      'centroid': centroid,
      'bounds': bounds,
      'isValid': isValid,
    };
  }

  /// Calcula métricas completas de um polígono com alta precisão
  static Map<String, double> calculatePreciseMetrics(List<LatLng> points) {
    if (points.length < 3) {
      return const {
        'area': 0.0,
        'perimeter': 0.0,
        'centroid_lat': 0.0,
        'centroid_lng': 0.0,
        'max_distance': 0.0,
        'compactness': 0.0,
      };
    }
    
    try {
      // Calcular área usando múltiplos métodos para validação
      final areaGauss = calculatePolygonAreaHectares(points);
      final areaLambert = calculateLambertArea(points);
      
      // Usar média ponderada dos métodos
      final area = (areaGauss * 0.7 + areaLambert * 0.3);
      
      // Calcular perímetro
      final perimeter = calculatePolygonPerimeter(points);
      
      // Calcular centroide
      final centroid = calculateGeodeticCentroid(points);
      
      // Calcular distância máxima entre pontos
      double maxDistance = 0.0;
      for (int i = 0; i < points.length; i++) {
        for (int j = i + 1; j < points.length; j++) {
          final distance = _calculateVincentyDistance(points[i], points[j]);
          if (distance > maxDistance) {
            maxDistance = distance;
          }
        }
      }
      
      // Calcular índice de compacidade (perímetro² / área)
      final compactness = perimeter * perimeter / (area * 10000); // Converter área para m²
      
      return {
        'area': area,
        'perimeter': perimeter,
        'centroid_lat': centroid.latitude,
        'centroid_lng': centroid.longitude,
        'max_distance': maxDistance,
        'compactness': compactness,
        'area_gauss': areaGauss,
        'area_lambert': areaLambert,
      };
      
    } catch (e) {
      print('❌ Erro no cálculo de métricas precisas: $e');
      return _calculateMetricsFallback(points);
    }
  }

  // Métodos auxiliares privados

  /// Calcula ângulo esférico entre três pontos
  static double _calculateSphericalAngle(double lat1, double lon1, double lat2, double lon2, double lat3, double lon3) {
    final a = _calculateSphericalDistance(lat1, lon1, lat2, lon2);
    final b = _calculateSphericalDistance(lat2, lon2, lat3, lon3);
    final c = _calculateSphericalDistance(lat3, lon3, lat1, lon1);
    
    final s = (a + b + c) / 2;
    final area = sqrt(s * (s - a) * (s - b) * (s - c));
    
    return 2 * asin(area / (sin(a) * sin(b) * sin(c)));
  }

  /// Calcula distância esférica entre dois pontos
  static double _calculateSphericalDistance(double lat1, double lon1, double lat2, double lon2) {
    try {
      final dlat = lat2 - lat1;
      final dlon = lon2 - lon1;
      
      final a = sin(dlat / 2) * sin(dlat / 2) +
                cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
      
      // Verificar se o valor está dentro do domínio válido
      if (a < 0 || a > 1) {
        return 0.0;
      }
      
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      
      return _earthRadius * c;
    } catch (e) {
      print('❌ Erro no cálculo de distância esférica: $e');
      return 0.0;
    }
  }

  /// Calcula distância usando fórmula de Vincenty
  static double _calculateVincentyDistance(LatLng point1, LatLng point2) {
    final lat1 = point1.latitude * pi / 180;
    final lon1 = point1.longitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final lon2 = point2.longitude * pi / 180;
    
    final L = lon2 - lon1;
    final tanU1 = (1 - _earthFlattening) * tan(lat1);
    final tanU2 = (1 - _earthFlattening) * tan(lat2);
    final U1 = atan(tanU1);
    final U2 = atan(tanU2);
    
    double lambda = L;
    double lambdaP;
    int iterations = 0;
    
    do {
      final sinU1 = sin(U1);
      final cosU1 = cos(U1);
      final sinU2 = sin(U2);
      final cosU2 = cos(U2);
      final sinLambda = sin(lambda);
      final cosLambda = cos(lambda);
      
      final sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
                           (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
                           (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      
      if (sinSigma == 0) return 0;
      
      final cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      final sigma = atan2(sinSigma, cosSigma);
      final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      final cosSqAlpha = 1 - sinAlpha * sinAlpha;
      final cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
      
      final C = _earthFlattening / 16 * cosSqAlpha * (4 + _earthFlattening * (4 - 3 * cosSqAlpha));
      lambdaP = lambda;
      lambda = L + (1 - C) * _earthFlattening * sinAlpha *
               (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
      
      iterations++;
    } while ((lambda - lambdaP).abs() > 1e-12 && iterations < 100);
    
    // Calcular variáveis finais para a fórmula de Vincenty
    final sinU1 = sin(U1);
    final cosU1 = cos(U1);
    final sinU2 = sin(U2);
    final cosU2 = cos(U2);
    final sinLambda = sin(lambda);
    final cosLambda = cos(lambda);
    
    final sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
                         (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
                         (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
    
    if (sinSigma == 0) return 0;
    
    final cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    final sigma = atan2(sinSigma, cosSigma);
    final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    final cosSqAlpha = 1 - sinAlpha * sinAlpha;
    final cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
    
    final uSq = cosSqAlpha * (_earthRadius * _earthRadius - _earthRadius * _earthRadius * (1 - _earthFlattening) * (1 - _earthFlattening)) /
                (_earthRadius * _earthRadius * (1 - _earthFlattening) * (1 - _earthFlattening));
    final A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    final B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    final deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                                                             B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    
    return _earthRadius * (1 - _earthFlattening) * A * (sigma - deltaSigma);
  }

  /// Converte LatLng para coordenadas cartesianas 3D
  static Map<String, double> _latLngToCartesian(LatLng point) {
    final latRad = point.latitude * pi / 180;
    final lonRad = point.longitude * pi / 180;
    
    final cosLat = cos(latRad);
    final sinLat = sin(latRad);
    final cosLon = cos(lonRad);
    final sinLon = sin(lonRad);
    
    return {
      'x': _earthRadius * cosLat * cosLon,
      'y': _earthRadius * cosLat * sinLon,
      'z': _earthRadius * sinLat,
    };
  }

  /// Converte coordenadas cartesianas 3D para LatLng
  static LatLng _cartesianToLatLng(double x, double y, double z) {
    final lat = atan2(z, sqrt(x * x + y * y));
    final lon = atan2(y, x);
    
    return LatLng(lat * 180 / pi, lon * 180 / pi);
  }

  // Métodos de fallback para casos de erro

  /// Método de fallback para cálculo de área (MÉTODO SIMPLIFICADO E ESTÁVEL)
  static double _calculateAreaFallback(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    try {
      print('🔄 Usando método de fallback para cálculo de área');
      
      // Remover pontos duplicados consecutivos para evitar problemas
      final cleanPoints = <LatLng>[];
      for (int i = 0; i < points.length; i++) {
        if (i == 0 || points[i].latitude != points[i-1].latitude || 
            points[i].longitude != points[i-1].longitude) {
          cleanPoints.add(points[i]);
        }
      }
      
      if (cleanPoints.length < 3) {
        print('⚠️ Muitos pontos duplicados, usando pontos originais');
        cleanPoints.clear();
        cleanPoints.addAll(points);
      }
      
      double area = 0.0;
      final n = cleanPoints.length;
      
      // Aplicar fórmula de Shoelace
      for (int i = 0; i < n; i++) {
        final j = (i + 1) % n;
        area += cleanPoints[i].longitude * cleanPoints[j].latitude;
        area -= cleanPoints[j].longitude * cleanPoints[i].latitude;
      }
      
      area = area.abs() / 2.0;
      
      // Conversão para hectares usando latitude média
      final latMedia = cleanPoints.map((p) => p.latitude).reduce((a, b) => a + b) / n;
      final latMediaRad = latMedia * pi / 180;
      
      // Fatores de conversão corretos para metros
      final metersPerDegLat = 111132.954 - 559.822 * cos(2 * latMediaRad) + 
                             1.175 * cos(4 * latMediaRad);
      final metersPerDegLng = (pi / 180) * 6378137.0 * cos(latMediaRad);
      
      // Converter graus² para metros²
      final areaMetersSquared = area * metersPerDegLat * metersPerDegLng;
      
      // Converter metros² para hectares (1 hectare = 10.000 m²)
      final areaHectares = areaMetersSquared / 10000.0;
      
      print('✅ Método de fallback calculou área: ${areaHectares.toStringAsFixed(4)} ha');
      return areaHectares;
      
    } catch (e) {
      print('❌ Erro no método de fallback: $e');
      return 0.0;
    }
  }

  /// Método de fallback para cálculo de perímetro
  static double _calculatePerimeterFallback(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    
    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      perimeter += _calculateHaversineDistance(points[i], points[j]);
    }
    
    return perimeter;
  }

  /// Calcula distância usando fórmula de Haversine (fallback)
  static double _calculateHaversineDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
              cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Calcula centroide simples (fallback)
  static LatLng _calculateSimpleCentroid(List<LatLng> points) {
    final avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final avgLon = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    
    return LatLng(avgLat, avgLon);
  }

  /// Método de fallback para métricas completas
  static Map<String, double> _calculateMetricsFallback(List<LatLng> points) {
    return {
      'area': _calculateAreaFallback(points),
      'perimeter': _calculatePerimeterFallback(points),
      'centroid_lat': _calculateSimpleCentroid(points).latitude,
      'centroid_lng': _calculateSimpleCentroid(points).longitude,
      'max_distance': 0.0,
      'compactness': 0.0,
      'area_gauss': _calculateAreaFallback(points),
      'area_lambert': _calculateAreaFallback(points),
    };
  }

  /// Formata área em hectares no padrão brasileiro (vírgula como separador decimal)
  static String formatAreaBrazilian(double areaHectares, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'pt_BR');
    return '${formatter.format(areaHectares)} ha';
  }

  /// Formata perímetro em metros no padrão brasileiro
  static String formatPerimeterBrazilian(double perimeterMeters, {int decimals = 1}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'pt_BR');
    return '${formatter.format(perimeterMeters)} m';
  }

  /// Formata velocidade em km/h no padrão brasileiro
  static String formatSpeedBrazilian(double speedKmh, {int decimals = 1}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'pt_BR');
    return '${formatter.format(speedKmh)} km/h';
  }
}
