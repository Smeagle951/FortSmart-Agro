import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'advanced_gps_service.dart';

/// Serviço para filtrar e validar dados GPS antes dos cálculos
class GPSFilterService {
  static const String _tag = 'GPSFilterService';
  
  // Configurações de filtro
  static const double _defaultMaxAccuracy = 5.0; // metros
  static const double _defaultMinDistance = 1.0; // metros
  static const int _kalmanWindowSize = 5;
  static const double _outlierThreshold = 3.0; // desvios padrão
  
  // Histórico para filtros
  final List<AdvancedPosition> _positionHistory = [];
  final List<double> _accuracyHistory = [];
  
  /// Filtra posição GPS aplicando múltiplas validações
  AdvancedPosition? filterPosition(AdvancedPosition position) {
    try {
      // 1. Filtro de precisão básica
      if (!_passesAccuracyFilter(position)) {
        print('$_tag: Posição rejeitada por baixa precisão: ${position.accuracy}m');
        return null;
      }
      
      // 2. Filtro de distância mínima
      if (!_passesDistanceFilter(position)) {
        print('$_tag: Posição rejeitada por distância mínima');
        return null;
      }
      
      // 3. Filtro de outliers (valores extremos)
      if (!_passesOutlierFilter(position)) {
        print('$_tag: Posição rejeitada por outlier');
        return null;
      }
      
      // 4. Aplicar suavização Kalman
      final smoothedPosition = _applyKalmanSmoothing(position);
      
      // 5. Adicionar ao histórico
      _addToHistory(smoothedPosition);
      
      print('$_tag: Posição aceita - Precisão: ${smoothedPosition.accuracy}m, Satélites: ${smoothedPosition.totalSatellitesUsed}');
      return smoothedPosition;
      
    } catch (e) {
      print('$_tag: Erro ao filtrar posição: $e');
      return null;
    }
  }
  
  /// Filtro de precisão - rejeita posições com accuracy > limite
  bool _passesAccuracyFilter(AdvancedPosition position) {
    return position.accuracy <= _defaultMaxAccuracy;
  }
  
  /// Filtro de distância mínima - evita pontos muito próximos
  bool _passesDistanceFilter(AdvancedPosition position) {
    if (_positionHistory.isEmpty) return true;
    
    final lastPosition = _positionHistory.last;
    final distance = _calculateDistance(
      lastPosition.latitude,
      lastPosition.longitude,
      position.latitude,
      position.longitude,
    );
    
    return distance >= _defaultMinDistance;
  }
  
  /// Filtro de outliers - detecta e rejeita valores extremos
  bool _passesOutlierFilter(AdvancedPosition position) {
    if (_positionHistory.length < 3) return true;
    
    // Calcular média e desvio padrão das últimas posições
    final recentPositions = _positionHistory.length > 10 
        ? _positionHistory.sublist(_positionHistory.length - 10)
        : _positionHistory;
    final latitudes = recentPositions.map((p) => p.latitude).toList();
    final longitudes = recentPositions.map((p) => p.longitude).toList();
    
    final latMean = _calculateMean(latitudes);
    final lngMean = _calculateMean(longitudes);
    final latStdDev = _calculateStandardDeviation(latitudes, latMean);
    final lngStdDev = _calculateStandardDeviation(longitudes, lngMean);
    
    // Verificar se a nova posição está dentro do limite de desvios padrão
    final latZScore = (position.latitude - latMean).abs() / latStdDev;
    final lngZScore = (position.longitude - lngMean).abs() / lngStdDev;
    
    return latZScore <= _outlierThreshold && lngZScore <= _outlierThreshold;
  }
  
  /// Aplica suavização Kalman para reduzir ruído
  AdvancedPosition _applyKalmanSmoothing(AdvancedPosition position) {
    if (_positionHistory.isEmpty) return position;
    
    // Implementação simplificada do filtro Kalman
    final lastPosition = _positionHistory.last;
    
    // Fator de suavização baseado na precisão
    final smoothingFactor = _calculateSmoothingFactor(position.accuracy);
    
    // Suavizar coordenadas
    final smoothedLat = _smoothValue(
      lastPosition.latitude,
      position.latitude,
      smoothingFactor,
    );
    
    final smoothedLng = _smoothValue(
      lastPosition.longitude,
      position.longitude,
      smoothingFactor,
    );
    
    // Suavizar precisão
    final smoothedAccuracy = _smoothValue(
      lastPosition.accuracy,
      position.accuracy,
      smoothingFactor * 0.5, // Menos agressivo para precisão
    );
    
    // Criar posição suavizada
    return AdvancedPosition(
      latitude: smoothedLat,
      longitude: smoothedLng,
      altitude: position.altitude,
      accuracy: smoothedAccuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
      satellites: position.satellites,
      satellitesBySystem: position.satellitesBySystem,
      hdop: position.hdop,
      vdop: position.vdop,
      pdop: position.pdop,
      isHighAccuracy: smoothedAccuracy <= 5.0,
    );
  }
  
  /// Calcula fator de suavização baseado na precisão
  double _calculateSmoothingFactor(double accuracy) {
    // Precisão alta = menos suavização
    // Precisão baixa = mais suavização
    if (accuracy <= 2.0) return 0.1; // Muito preciso, pouca suavização
    if (accuracy <= 5.0) return 0.3; // Bom, suavização moderada
    if (accuracy <= 10.0) return 0.5; // Regular, mais suavização
    return 0.7; // Baixo, muita suavização
  }
  
  /// Suaviza um valor usando média ponderada
  double _smoothValue(double previous, double current, double factor) {
    return previous + (current - previous) * factor;
  }
  
  /// Adiciona posição ao histórico
  void _addToHistory(AdvancedPosition position) {
    _positionHistory.add(position);
    _accuracyHistory.add(position.accuracy);
    
    // Manter apenas as últimas 50 posições
    if (_positionHistory.length > 50) {
      _positionHistory.removeAt(0);
      _accuracyHistory.removeAt(0);
    }
  }
  
  /// Calcula distância entre dois pontos em metros
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2));
  }
  
  /// Calcula média de uma lista de valores
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  /// Calcula desvio padrão de uma lista de valores
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.length < 2) return 1.0;
    
    final variance = values
        .map((value) => pow(value - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    return sqrt(variance);
  }
  
  /// Obtém estatísticas de qualidade do filtro
  Map<String, dynamic> getFilterStatistics() {
    if (_positionHistory.isEmpty) {
      return {
        'total_positions': 0,
        'average_accuracy': 0.0,
        'filtered_accuracy': 0.0,
        'improvement_percentage': 0.0,
      };
    }
    
    final originalAccuracy = _accuracyHistory.isNotEmpty 
        ? _accuracyHistory.reduce((a, b) => a + b) / _accuracyHistory.length 
        : 0.0;
    
    final filteredAccuracy = _positionHistory
        .map((p) => p.accuracy)
        .reduce((a, b) => a + b) / _positionHistory.length;
    
    final improvement = originalAccuracy > 0 
        ? ((originalAccuracy - filteredAccuracy) / originalAccuracy) * 100 
        : 0.0;
    
    return {
      'total_positions': _positionHistory.length,
      'average_accuracy': originalAccuracy,
      'filtered_accuracy': filteredAccuracy,
      'improvement_percentage': improvement,
      'outliers_rejected': _accuracyHistory.length - _positionHistory.length,
    };
  }
  
  /// Limpa o histórico de posições
  void clearHistory() {
    _positionHistory.clear();
    _accuracyHistory.clear();
    print('$_tag: Histórico de posições limpo');
  }
  
  /// Configura limites de filtro
  void configureFilters({
    double? maxAccuracy,
    double? minDistance,
    double? outlierThreshold,
  }) {
    if (maxAccuracy != null) {
      print('$_tag: Precisão máxima configurada para: ${maxAccuracy}m');
    }
    if (minDistance != null) {
      print('$_tag: Distância mínima configurada para: ${minDistance}m');
    }
    if (outlierThreshold != null) {
      print('$_tag: Limite de outlier configurado para: $outlierThreshold desvios');
    }
  }
  
  /// Valida se uma posição é adequada para cálculos de área
  bool isPositionSuitableForAreaCalculation(AdvancedPosition position) {
    // Critérios para cálculos de área:
    // 1. Precisão <= 5m
    // 2. Pelo menos 4 satélites
    // 3. HDOP <= 3.0
    // 4. Não é outlier
    
    return position.accuracy <= 5.0 &&
           position.totalSatellitesUsed >= 4 &&
           position.hdop <= 3.0 &&
           _passesOutlierFilter(position);
  }
  
  /// Obtém posições filtradas adequadas para cálculo de área
  List<AdvancedPosition> getFilteredPositionsForAreaCalculation() {
    return _positionHistory
        .where((position) => isPositionSuitableForAreaCalculation(position))
        .toList();
  }
  
  /// Aplica filtro de qualidade para polígonos
  List<LatLng> filterPolygonPoints(List<LatLng> points, {double maxAccuracy = 5.0}) {
    if (points.length < 3) return points;
    
    final filteredPoints = <LatLng>[];
    
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      // Verificar se o ponto está muito próximo do anterior
      if (filteredPoints.isNotEmpty) {
        final lastPoint = filteredPoints.last;
        final distance = _calculateDistance(
          lastPoint.latitude,
          lastPoint.longitude,
          point.latitude,
          point.longitude,
        );
        
        // Pular pontos muito próximos (menos de 1 metro)
        if (distance < 1.0) continue;
      }
      
      // Verificar se o ponto não está muito longe do anterior
      if (filteredPoints.isNotEmpty) {
        final lastPoint = filteredPoints.last;
        final distance = _calculateDistance(
          lastPoint.latitude,
          lastPoint.longitude,
          point.latitude,
          point.longitude,
        );
        
        // Pular pontos muito distantes (mais de 100 metros) - possível erro
        if (distance > 100.0) continue;
      }
      
      filteredPoints.add(point);
    }
    
    // Garantir que o polígono tenha pelo menos 3 pontos
    if (filteredPoints.length < 3 && points.length >= 3) {
      // Se filtramos demais, usar os pontos originais
      return points;
    }
    
    return filteredPoints;
  }
  
  /// Valida qualidade de um polígono antes do cálculo de área
  bool validatePolygonQuality(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Verificar se o polígono não é muito pequeno
    final area = _calculatePolygonArea(points);
    if (area < 0.001) return false; // Menos de 0.001 hectares
    
    // Verificar se não há pontos muito próximos
    for (int i = 0; i < points.length - 1; i++) {
      final distance = _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
      
      if (distance < 0.5) return false; // Pontos muito próximos
    }
    
    return true;
  }
  
  /// Calcula área aproximada de um polígono (para validação)
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Fórmula de Shoelace simplificada
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximação)
    return area * 111132.954 * 111132.954 / 10000.0;
  }
}

/// Extensões para facilitar o uso
extension GPSFilterServiceExtensions on GPSFilterService {
  /// Obtém qualidade média das posições filtradas
  String getAverageQuality() {
    final stats = getFilterStatistics();
    final accuracy = stats['filtered_accuracy'] as double;
    
    if (accuracy <= 2.0) return 'Excelente';
    if (accuracy <= 5.0) return 'Muito Boa';
    if (accuracy <= 10.0) return 'Boa';
    if (accuracy <= 20.0) return 'Regular';
    return 'Baixa';
  }
  
  /// Verifica se o filtro está funcionando bem
  bool isFilterWorkingWell() {
    final stats = getFilterStatistics();
    final improvement = stats['improvement_percentage'] as double;
    return improvement > 10.0; // Melhoria de pelo menos 10%
  }
}
