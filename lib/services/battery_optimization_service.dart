import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

/// Serviço para otimização de bateria durante navegação
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  // Configurações de otimização
  Timer? _optimizationTimer;
  bool _isOptimized = false;
  int _currentUpdateFrequency = 2; // segundos
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  
  // Configurações por distância
  static const Map<String, Map<String, dynamic>> _distanceConfigs = {
    'near': {
      'frequency': 1,
      'accuracy': LocationAccuracy.high,
      'description': 'Próximo ao ponto - Alta precisão',
    },
    'medium': {
      'frequency': 3,
      'accuracy': LocationAccuracy.medium,
      'description': 'Distância média - Precisão média',
    },
    'far': {
      'frequency': 5,
      'accuracy': LocationAccuracy.low,
      'description': 'Distante - Baixa precisão',
    },
  };

  /// Inicia otimização automática baseada na distância
  void startOptimization({
    required double distanceToTarget,
    required VoidCallback onConfigChanged,
  }) {
    _optimizationTimer?.cancel();
    
    _optimizationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateOptimization(distanceToTarget, onConfigChanged);
    });
    
    Logger.info('🔋 Otimização de bateria iniciada');
  }

  /// Para a otimização
  void stopOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    Logger.info('🔋 Otimização de bateria parada');
  }

  /// Atualiza configurações baseadas na distância
  void _updateOptimization(double distance, VoidCallback onConfigChanged) {
    String configKey;
    
    if (distance <= 50) {
      configKey = 'near';
    } else if (distance <= 200) {
      configKey = 'medium';
    } else {
      configKey = 'far';
    }
    
    final config = _distanceConfigs[configKey]!;
    final newFrequency = config['frequency'] as int;
    final newAccuracy = config['accuracy'] as LocationAccuracy;
    final description = config['description'] as String;
    
    // Atualizar apenas se houve mudança
    if (newFrequency != _currentUpdateFrequency || newAccuracy != _currentAccuracy) {
      _currentUpdateFrequency = newFrequency;
      _currentAccuracy = newAccuracy;
      _isOptimized = configKey != 'near';
      
      Logger.info('🔋 Configuração atualizada: $description (${newFrequency}s, ${_accuracyToString(newAccuracy)})');
      
      onConfigChanged();
    }
  }

  /// Converte LocationAccuracy para string
  String _accuracyToString(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Baixíssima';
      case LocationAccuracy.low:
        return 'Baixa';
      case LocationAccuracy.medium:
        return 'Média';
      case LocationAccuracy.high:
        return 'Alta';
      case LocationAccuracy.best:
        return 'Máxima';
      case LocationAccuracy.bestForNavigation:
        return 'Navegação';
    }
  }

  /// Obtém configurações atuais
  Map<String, dynamic> getCurrentConfig() {
    return {
      'frequency': _currentUpdateFrequency,
      'accuracy': _currentAccuracy,
      'isOptimized': _isOptimized,
      'description': _getCurrentDescription(),
    };
  }

  /// Obtém descrição da configuração atual
  String _getCurrentDescription() {
    if (_currentUpdateFrequency == 1) {
      return 'Próximo ao ponto - Alta precisão';
    } else if (_currentUpdateFrequency == 3) {
      return 'Distância média - Precisão média';
    } else {
      return 'Distante - Baixa precisão';
    }
  }

  /// Força otimização manual
  void forceOptimization(bool optimize) {
    _isOptimized = optimize;
    
    if (optimize) {
      _currentUpdateFrequency = 5;
      _currentAccuracy = LocationAccuracy.medium;
    } else {
      _currentUpdateFrequency = 2;
      _currentAccuracy = LocationAccuracy.high;
    }
    
    Logger.info('🔋 Otimização ${optimize ? "ATIVADA" : "DESATIVADA"} manualmente');
  }

  /// Obtém configurações de localização otimizadas
  LocationSettings getOptimizedLocationSettings() {
    return LocationSettings(
      accuracy: _currentAccuracy,
      distanceFilter: _isOptimized ? 10 : 5, // metros
      timeLimit: Duration(seconds: _isOptimized ? 5 : 3),
    );
  }

  /// Verifica se deve atualizar localização baseado na frequência
  bool shouldUpdateLocation(DateTime lastUpdate) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdate);
    return diff.inSeconds >= _currentUpdateFrequency;
  }

  /// Obtém estatísticas de otimização
  Map<String, dynamic> getOptimizationStats() {
    return {
      'isActive': _optimizationTimer != null,
      'isOptimized': _isOptimized,
      'updateFrequency': _currentUpdateFrequency,
      'accuracy': _accuracyToString(_currentAccuracy),
      'description': _getCurrentDescription(),
      'batterySavings': _calculateBatterySavings(),
    };
  }

  /// Calcula economia de bateria estimada
  String _calculateBatterySavings() {
    if (!_isOptimized) return '0%';
    
    // Estimativa baseada na redução de frequência
    final baseFrequency = 2; // frequência normal
    final savings = ((baseFrequency - _currentUpdateFrequency) / baseFrequency * 100).round();
    return '${savings}%';
  }

  /// Dispose do serviço
  void dispose() {
    stopOptimization();
  }
}
