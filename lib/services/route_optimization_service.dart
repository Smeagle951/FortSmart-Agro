import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../utils/logger.dart';

/// Serviço para otimização de rotas e cálculo de caminhos
class RouteOptimizationService {
  static final RouteOptimizationService _instance = RouteOptimizationService._internal();
  factory RouteOptimizationService() => _instance;
  RouteOptimizationService._internal();

  /// Calcula rota otimizada entre dois pontos
  List<LatLng> calculateOptimizedRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    bool avoidObstacles = true,
  }) {
    try {
      Logger.info('🛣️ Calculando rota otimizada: ${start.toString()} → ${end.toString()}');
      
      // Se há waypoints, usar algoritmo de otimização
      if (waypoints != null && waypoints.isNotEmpty) {
        return _calculateRouteWithWaypoints(start, end, waypoints);
      }
      
      // Rota direta com pontos intermediários
      return _calculateDirectRoute(start, end, avoidObstacles);
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular rota: $e');
      return [start, end]; // Fallback: rota direta
    }
  }

  /// Calcula rota direta com pontos intermediários
  List<LatLng> _calculateDirectRoute(LatLng start, LatLng end, bool avoidObstacles) {
    final distance = _calculateDistance(start, end);
    final segments = _getOptimalSegments(distance);
    
    final routePoints = <LatLng>[start];
    
    for (int i = 1; i < segments; i++) {
      final ratio = i / segments;
      final point = _interpolatePoint(start, end, ratio);
      routePoints.add(point);
    }
    
    routePoints.add(end);
    
    // Aplicar suavização se necessário
    if (avoidObstacles) {
      return _smoothRoute(routePoints);
    }
    
    return routePoints;
  }

  /// Calcula rota com waypoints usando algoritmo de otimização
  List<LatLng> _calculateRouteWithWaypoints(LatLng start, LatLng end, List<LatLng> waypoints) {
    // Ordenar waypoints pela distância (algoritmo simples)
    final sortedWaypoints = _sortWaypointsByDistance(start, waypoints);
    
    final routePoints = <LatLng>[start];
    
    // Adicionar waypoints ordenados
    for (final waypoint in sortedWaypoints) {
      routePoints.add(waypoint);
    }
    
    routePoints.add(end);
    
    // Suavizar rota final
    return _smoothRoute(routePoints);
  }

  /// Ordena waypoints pela distância
  List<LatLng> _sortWaypointsByDistance(LatLng start, List<LatLng> waypoints) {
    final distances = <LatLng, double>{};
    
    for (final waypoint in waypoints) {
      distances[waypoint] = _calculateDistance(start, waypoint);
    }
    
    // Ordenar por distância
    final sortedEntries = distances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sortedEntries.map((entry) => entry.key).toList();
  }

  /// Calcula número ótimo de segmentos baseado na distância
  int _getOptimalSegments(double distance) {
    if (distance < 100) return 5;      // < 100m: 5 segmentos
    if (distance < 500) return 10;     // < 500m: 10 segmentos
    if (distance < 1000) return 15;    // < 1km: 15 segmentos
    return 20;                         // > 1km: 20 segmentos
  }

  /// Interpola ponto entre dois pontos
  LatLng _interpolatePoint(LatLng start, LatLng end, double ratio) {
    final lat = start.latitude + (end.latitude - start.latitude) * ratio;
    final lng = start.longitude + (end.longitude - start.longitude) * ratio;
    return LatLng(lat, lng);
  }

  /// Suaviza rota para evitar obstáculos
  List<LatLng> _smoothRoute(List<LatLng> routePoints) {
    if (routePoints.length < 3) return routePoints;
    
    final smoothedRoute = <LatLng>[routePoints.first];
    
    for (int i = 1; i < routePoints.length - 1; i++) {
      final prev = routePoints[i - 1];
      final current = routePoints[i];
      final next = routePoints[i + 1];
      
      // Aplicar suavização simples
      final smoothedLat = (prev.latitude + current.latitude + next.latitude) / 3;
      final smoothedLng = (prev.longitude + current.longitude + next.longitude) / 3;
      
      smoothedRoute.add(LatLng(smoothedLat, smoothedLng));
    }
    
    smoothedRoute.add(routePoints.last);
    
    return smoothedRoute;
  }

  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Calcula bearing entre dois pontos
  double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final deltaLng = (end.longitude - start.longitude) * math.pi / 180;
    
    final y = math.sin(deltaLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// Calcula distância total de uma rota
  double calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistance(route[i], route[i + 1]);
    }
    
    return totalDistance;
  }

  /// Verifica se um ponto está dentro de um polígono
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    
    bool inside = false;
    
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
           (point.latitude - polygon[i].latitude) / 
           (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        inside = !inside;
      }
    }
    
    return inside;
  }

  /// Encontra o ponto mais próximo em uma rota
  LatLng findNearestPointOnRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return point;
    
    double minDistance = double.infinity;
    LatLng nearestPoint = route.first;
    
    for (final routePoint in route) {
      final distance = _calculateDistance(point, routePoint);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = routePoint;
      }
    }
    
    return nearestPoint;
  }

  /// Calcula tempo estimado para percorrer uma rota
  Duration estimateRouteTime(List<LatLng> route, double speedKmh) {
    final distance = calculateRouteDistance(route);
    final speedMs = speedKmh / 3.6; // Converter km/h para m/s
    final timeSeconds = distance / speedMs;
    
    return Duration(seconds: timeSeconds.round());
  }

  /// Otimiza rota para minimizar distância
  List<LatLng> optimizeRouteForDistance(List<LatLng> route) {
    if (route.length <= 2) return route;
    
    // Algoritmo simples de otimização (2-opt)
    List<LatLng> optimizedRoute = List.from(route);
    bool improved = true;
    
    while (improved) {
      improved = false;
      
      for (int i = 1; i < optimizedRoute.length - 2; i++) {
        for (int j = i + 1; j < optimizedRoute.length; j++) {
          final newRoute = _twoOptSwap(optimizedRoute, i, j);
          final currentDistance = calculateRouteDistance(optimizedRoute);
          final newDistance = calculateRouteDistance(newRoute);
          
          if (newDistance < currentDistance) {
            optimizedRoute = newRoute;
            improved = true;
          }
        }
      }
    }
    
    return optimizedRoute;
  }

  /// Aplica swap 2-opt em uma rota
  List<LatLng> _twoOptSwap(List<LatLng> route, int i, int j) {
    final newRoute = <LatLng>[];
    
    // Adicionar pontos de 0 a i-1
    newRoute.addAll(route.sublist(0, i));
    
    // Adicionar pontos de i a j em ordem reversa
    newRoute.addAll(route.sublist(i, j + 1).reversed);
    
    // Adicionar pontos de j+1 ao final
    if (j + 1 < route.length) {
      newRoute.addAll(route.sublist(j + 1));
    }
    
    return newRoute;
  }

  /// Obtém estatísticas da rota
  Map<String, dynamic> getRouteStats(List<LatLng> route) {
    if (route.isEmpty) {
      return {
        'distance': 0.0,
        'points': 0,
        'estimatedTime': Duration.zero,
        'averageSpeed': 0.0,
      };
    }
    
    final distance = calculateRouteDistance(route);
    final estimatedTime = estimateRouteTime(route, 5.0); // 5 km/h caminhando
    
    return {
      'distance': distance,
      'points': route.length,
      'estimatedTime': estimatedTime,
      'averageSpeed': 5.0, // km/h
      'distanceFormatted': _formatDistance(distance),
      'timeFormatted': _formatDuration(estimatedTime),
    };
  }

  /// Formata distância para exibição
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Formata duração para exibição
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else {
      return '${duration.inMinutes}min';
    }
  }
}
