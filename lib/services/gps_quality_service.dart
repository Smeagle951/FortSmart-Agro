import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

/// Serviço para monitorar a qualidade do GPS
class GpsQualityService {
  static final GpsQualityService _instance = GpsQualityService._internal();
  factory GpsQualityService() => _instance;
  GpsQualityService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _qualityTimer;
  
  // Stream para notificar sobre mudanças na qualidade do GPS
  final _qualityController = StreamController<GpsQualityStatus>.broadcast();
  Stream<GpsQualityStatus> get qualityStream => _qualityController.stream;
  
  // Histórico de posições para análise
  final List<Position> _positionHistory = [];
  static const int _maxHistorySize = 50;
  
  // Status atual
  GpsQualityLevel _currentStatus = GpsQualityLevel.unknown;
  
  /// Inicializa o monitoramento de qualidade do GPS
  Future<void> initialize() async {
    try {
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          Logger.error('Permissão de localização negada');
          return;
        }
      }
      
      // Iniciar monitoramento contínuo
      _startQualityMonitoring();
      
      Logger.info('Serviço de qualidade GPS inicializado');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de qualidade GPS: $e');
    }
  }
  
  /// Inicia o monitoramento contínuo
  void _startQualityMonitoring() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // 1 metro
        timeLimit: Duration(seconds: 30),
      ),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        Logger.error('Erro no stream de posição: $error');
        _updateQualityStatus(GpsQualityLevel.error);
      },
    );
    
    // Timer para análise periódica da qualidade
    _qualityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _analyzeQuality();
    });
  }
  
  /// Processa atualização de posição
  void _onPositionUpdate(Position position) {
    // Adicionar à história
    _positionHistory.add(position);
    
    // Manter apenas as últimas posições
    if (_positionHistory.length > _maxHistorySize) {
      _positionHistory.removeAt(0);
    }
    
    // Analisar qualidade imediatamente
    _analyzeQuality();
  }
  
  /// Analisa a qualidade do GPS
  void _analyzeQuality() {
    if (_positionHistory.isEmpty) {
      _updateQualityStatus(GpsQualityLevel.unknown);
      return;
    }
    
    try {
      final quality = _calculateQuality();
      _updateQualityStatus(quality);
    } catch (e) {
      Logger.error('Erro ao analisar qualidade GPS: $e');
      _updateQualityStatus(GpsQualityLevel.error);
    }
  }
  
  /// Calcula a qualidade do GPS
  GpsQualityLevel _calculateQuality() {
    final recentPositions = _positionHistory.take(10).toList();
    if (recentPositions.isEmpty) return GpsQualityLevel.unknown;
    
    // 1. Análise de precisão
    final avgAccuracy = recentPositions.map((p) => p.accuracy).reduce((a, b) => a + b) / recentPositions.length;
    
    // 2. Análise de velocidade (para detectar movimento real vs. erro)
    double avgSpeed = 0;
    if (recentPositions.length > 1) {
      for (int i = 1; i < recentPositions.length; i++) {
        final distance = Geolocator.distanceBetween(
          recentPositions[i - 1].latitude,
          recentPositions[i - 1].longitude,
          recentPositions[i].latitude,
          recentPositions[i].longitude,
        );
        final timeDiff = recentPositions[i].timestamp.difference(recentPositions[i - 1].timestamp).inSeconds;
        if (timeDiff > 0) {
          avgSpeed += distance / timeDiff;
        }
      }
      avgSpeed /= (recentPositions.length - 1);
    }
    
    // 3. Análise de consistência (variação entre posições)
    double consistency = 0;
    if (recentPositions.length > 2) {
      final center = _calculateCenter(recentPositions);
      for (final position in recentPositions) {
        final distance = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          position.latitude,
          position.longitude,
        );
        consistency += distance;
      }
      consistency /= recentPositions.length;
    }
    
    // 4. Análise de altitude (se disponível)
    bool hasAltitude = recentPositions.any((p) => p.altitude != 0);
    
    // 5. Análise de heading (se disponível)
    bool hasHeading = recentPositions.any((p) => p.heading != 0);
    
    // Determinar qualidade baseada nos critérios
    return _determineQuality(
      accuracy: avgAccuracy,
      speed: avgSpeed,
      consistency: consistency,
      hasAltitude: hasAltitude,
      hasHeading: hasHeading,
    );
  }
  
  /// Determina a qualidade baseada nos parâmetros
  GpsQualityLevel _determineQuality({
    required double accuracy,
    required double speed,
    required double consistency,
    required bool hasAltitude,
    required bool hasHeading,
  }) {
    // Critérios para qualidade excelente
    if (accuracy <= 3 && consistency <= 2 && hasAltitude && hasHeading) {
      return GpsQualityLevel.excellent;
    }
    
    // Critérios para qualidade boa
    if (accuracy <= 5 && consistency <= 5) {
      return GpsQualityLevel.good;
    }
    
    // Critérios para qualidade moderada
    if (accuracy <= 10 && consistency <= 10) {
      return GpsQualityLevel.moderate;
    }
    
    // Critérios para qualidade ruim
    if (accuracy <= 20) {
      return GpsQualityLevel.poor;
    }
    
    // Qualidade muito ruim
    return GpsQualityLevel.veryPoor;
  }
  
  /// Calcula o centro de um conjunto de posições
  Position _calculateCenter(List<Position> positions) {
    double lat = 0, lng = 0;
    for (final position in positions) {
      lat += position.latitude;
      lng += position.longitude;
    }
    
    return Position(
      latitude: lat / positions.length,
      longitude: lng / positions.length,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
  
  /// Atualiza o status de qualidade
  void _updateQualityStatus(GpsQualityLevel status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _qualityController.add(GpsQualityStatus(
        quality: status,
        timestamp: DateTime.now(),
        accuracy: _getCurrentAccuracy(),
        satelliteCount: _getCurrentSatelliteCount(),
        signalStrength: _getCurrentSignalStrength(),
      ));
      
      Logger.info('Qualidade GPS alterada para: $status');
    }
  }
  
  /// Obtém a precisão atual
  double _getCurrentAccuracy() {
    if (_positionHistory.isEmpty) return 0;
    return _positionHistory.last.accuracy;
  }
  
  /// Obtém o número de satélites (estimativa)
  int _getCurrentSatelliteCount() {
    if (_positionHistory.isEmpty) return 0;
    
    // Estimativa baseada na precisão
    final accuracy = _positionHistory.last.accuracy;
    if (accuracy <= 3) return 8;
    if (accuracy <= 5) return 6;
    if (accuracy <= 10) return 4;
    if (accuracy <= 20) return 2;
    return 1;
  }
  
  /// Obtém a força do sinal (estimativa)
  double _getCurrentSignalStrength() {
    if (_positionHistory.isEmpty) return 0;
    
    // Estimativa baseada na precisão e consistência
    final accuracy = _positionHistory.last.accuracy;
    final consistency = _calculateConsistency();
    
    double strength = 100;
    
    // Reduzir baseado na precisão
    if (accuracy > 20) strength -= 50;
    else if (accuracy > 10) strength -= 30;
    else if (accuracy > 5) strength -= 15;
    else if (accuracy > 3) strength -= 5;
    
    // Reduzir baseado na consistência
    if (consistency > 10) strength -= 30;
    else if (consistency > 5) strength -= 15;
    else if (consistency > 2) strength -= 5;
    
    return strength.clamp(0, 100);
  }
  
  /// Calcula a consistência atual
  double _calculateConsistency() {
    if (_positionHistory.length < 3) return 0;
    
    final recentPositions = _positionHistory.take(5).toList();
    final center = _calculateCenter(recentPositions);
    
    double totalDistance = 0;
    for (final position in recentPositions) {
      totalDistance += Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        position.latitude,
        position.longitude,
      );
    }
    
    return totalDistance / recentPositions.length;
  }
  
  /// Obtém o status atual da qualidade
  GpsQualityStatus getCurrentStatus() {
    return GpsQualityStatus(
      quality: _currentStatus,
      timestamp: DateTime.now(),
      accuracy: _getCurrentAccuracy(),
      satelliteCount: _getCurrentSatelliteCount(),
      signalStrength: _getCurrentSignalStrength(),
    );
  }
  
  /// Obtém estatísticas detalhadas
  Map<String, dynamic> getDetailedStats() {
    if (_positionHistory.isEmpty) {
      return {
        'quality': _currentStatus.toString(),
        'accuracy': 0,
        'satelliteCount': 0,
        'signalStrength': 0,
        'positionCount': 0,
        'lastUpdate': null,
      };
    }
    
    final lastPosition = _positionHistory.last;
    final avgAccuracy = _positionHistory.map((p) => p.accuracy).reduce((a, b) => a + b) / _positionHistory.length;
    
    return {
      'quality': _currentStatus.toString(),
      'accuracy': avgAccuracy,
      'currentAccuracy': lastPosition.accuracy,
      'satelliteCount': _getCurrentSatelliteCount(),
      'signalStrength': _getCurrentSignalStrength(),
      'positionCount': _positionHistory.length,
      'lastUpdate': lastPosition.timestamp.toIso8601String(),
      'consistency': _calculateConsistency(),
      'hasAltitude': lastPosition.altitude != 0,
      'hasHeading': lastPosition.heading != 0,
    };
  }
  
  /// Verifica se o GPS está funcionando adequadamente
  bool isGpsWorking() {
    return _currentStatus != GpsQualityLevel.unknown && 
           _currentStatus != GpsQualityLevel.error &&
           _currentStatus != GpsQualityLevel.veryPoor;
  }
  
  /// Obtém recomendações para melhorar a qualidade
  List<String> getImprovementRecommendations() {
    final recommendations = <String>[];
    
    switch (_currentStatus) {
      case GpsQualityLevel.unknown:
        recommendations.add('Verifique se o GPS está ativado');
        recommendations.add('Saia de ambientes fechados');
        break;
      case GpsQualityLevel.veryPoor:
        recommendations.add('Mova-se para uma área mais aberta');
        recommendations.add('Evite proximidade com edifícios altos');
        recommendations.add('Aguarde alguns minutos para estabilização');
        break;
      case GpsQualityLevel.poor:
        recommendations.add('Tente uma posição mais elevada');
        recommendations.add('Evite interferências eletrônicas');
        break;
      case GpsQualityLevel.moderate:
        recommendations.add('A qualidade está aceitável para uso básico');
        recommendations.add('Para maior precisão, use em área aberta');
        break;
      case GpsQualityLevel.good:
        recommendations.add('Qualidade boa para a maioria das aplicações');
        break;
      case GpsQualityLevel.excellent:
        recommendations.add('Qualidade excelente - ideal para uso profissional');
        break;
      case GpsQualityLevel.error:
        recommendations.add('Erro no GPS - reinicie o aplicativo');
        recommendations.add('Verifique as permissões de localização');
        break;
    }
    
    return recommendations;
  }
  
  /// Para o monitoramento
  void dispose() {
    _positionSubscription?.cancel();
    _qualityTimer?.cancel();
    _qualityController.close();
  }
}

/// Enum para níveis de qualidade do GPS
enum GpsQualityLevel {
  unknown,
  veryPoor,
  poor,
  moderate,
  good,
  excellent,
  error,
}

/// Classe para representar o status de qualidade do GPS
class GpsQualityStatus {
  final GpsQualityLevel quality;
  final DateTime timestamp;
  final double accuracy;
  final int satelliteCount;
  final double signalStrength;
  
  GpsQualityStatus({
    required this.quality,
    required this.timestamp,
    required this.accuracy,
    required this.satelliteCount,
    required this.signalStrength,
  });
  
  /// Obtém a cor associada à qualidade
  int get color {
    switch (quality) {
      case GpsQualityLevel.excellent:
        return 0xFF4CAF50; // Verde
      case GpsQualityLevel.good:
        return 0xFF8BC34A; // Verde claro
      case GpsQualityLevel.moderate:
        return 0xFFFFC107; // Amarelo
      case GpsQualityLevel.poor:
        return 0xFFFF9800; // Laranja
      case GpsQualityLevel.veryPoor:
        return 0xFFF44336; // Vermelho
      case GpsQualityLevel.error:
        return 0xFF9C27B0; // Roxo
      case GpsQualityLevel.unknown:
        return 0xFF9E9E9E; // Cinza
    }
  }
  
  /// Obtém o ícone associado à qualidade
  String get icon {
    switch (quality) {
      case GpsQualityLevel.excellent:
        return '📡';
      case GpsQualityLevel.good:
        return '📶';
      case GpsQualityLevel.moderate:
        return '📡';
      case GpsQualityLevel.poor:
        return '📶';
      case GpsQualityLevel.veryPoor:
        return '📡';
      case GpsQualityLevel.error:
        return '❌';
      case GpsQualityLevel.unknown:
        return '❓';
    }
  }
  
  @override
  String toString() {
    return 'GpsQualityStatus(quality: $quality, accuracy: ${accuracy.toStringAsFixed(1)}m, satellites: $satelliteCount, signal: ${signalStrength.toStringAsFixed(0)}%)';
  }
} 