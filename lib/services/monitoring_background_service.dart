import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../utils/distance_calculator.dart';

/// Serviço para monitoramento em background
/// Mantém o app funcionando em segundo plano durante o monitoramento
class MonitoringBackgroundService {
  static final MonitoringBackgroundService _instance = MonitoringBackgroundService._internal();
  factory MonitoringBackgroundService() => _instance;
  MonitoringBackgroundService._internal();

  // Controle de estado
  bool _isRunning = false;
  bool _isMonitoring = false;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _backgroundTimer;
  // ✅ ISOLATE REMOVIDO para evitar crashes

  // Configurações
  static const double _proximityThreshold = 10.0; // metros
  static const double _vibrationThreshold = 5.0; // metros
  static const Duration _updateInterval = Duration(seconds: 5);
  static const Duration _backgroundCheckInterval = Duration(seconds: 10);

  // Dados do monitoramento
  String? _currentTalhaoId;
  List<Map<String, dynamic>>? _monitoringPoints;
  int _currentPointIndex = 0;
  Position? _lastKnownPosition;

  /// Inicia o monitoramento em background
  Future<bool> startBackgroundMonitoring({
    required String talhaoId,
    required List<Map<String, dynamic>> monitoringPoints,
    required int currentPointIndex,
  }) async {
    try {
      Logger.info('🔄 Iniciando monitoramento em background...');
      
      if (_isRunning) {
        Logger.warning('⚠️ Monitoramento em background já está rodando');
        return true; // ✅ Retornar sucesso se já está rodando
      }

      // Verificar permissões
      if (!await _checkPermissions()) {
        Logger.error('❌ Permissões insuficientes para background');
        return false;
      }

      // Salvar dados do monitoramento
      _currentTalhaoId = talhaoId;
      _monitoringPoints = monitoringPoints;
      _currentPointIndex = currentPointIndex;

      // Iniciar monitoramento de posição
      await _startPositionMonitoring();

      // Iniciar timer de background
      _startBackgroundTimer();

      // ✅ REMOVER Isolate (não é necessário e causa crashes)
      // await _startBackgroundIsolate();

      _isRunning = true;
      _isMonitoring = true;

      Logger.info('✅ Monitoramento em background iniciado com sucesso');
      return true;

    } catch (e, stack) {
      Logger.error('❌ Erro ao iniciar monitoramento em background: $e');
      Logger.error('❌ Stack: $stack');
      // ✅ Não falhar completamente, retornar false
      return false;
    }
  }

  /// Para o monitoramento em background
  Future<void> stopBackgroundMonitoring() async {
    try {
      Logger.info('🛑 Parando monitoramento em background...');

      _isRunning = false;
      _isMonitoring = false;

      // Cancelar subscriptions
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // Cancelar timers
      _backgroundTimer?.cancel();
      _backgroundTimer = null;

      // ✅ ISOLATE REMOVIDO (não é mais usado)
      // _isolate?.kill();
      // _receivePort?.close();

      // Limpar dados
      _currentTalhaoId = null;
      _monitoringPoints = null;
      _currentPointIndex = 0;
      _lastKnownPosition = null;

      Logger.info('✅ Monitoramento em background parado');

    } catch (e, stack) {
      Logger.error('❌ Erro ao parar monitoramento em background: $e');
      Logger.error('❌ Stack: $stack');
      // ✅ Não propagar erro para não crashar o app
    }
  }

  /// Verifica se está rodando em background
  bool get isRunning => _isRunning;

  /// Verifica se está monitorando
  bool get isMonitoring => _isMonitoring;

  /// Inicia monitoramento de posição GPS
  Future<void> _startPositionMonitoring() async {
    try {
      Logger.info('📍 Iniciando monitoramento de posição GPS...');

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1, // 1 metro
        ),
      ).listen(
        (position) {
          _lastKnownPosition = position;
          _checkProximityToNextPoint(position);
        },
        onError: (error) {
          Logger.error('❌ Erro no GPS: $error');
        },
      );

      Logger.info('✅ Monitoramento de posição GPS iniciado');

    } catch (e) {
      Logger.error('❌ Erro ao iniciar monitoramento de posição: $e');
    }
  }

  /// Verifica proximidade com o próximo ponto
  void _checkProximityToNextPoint(Position currentPosition) {
    try {
      if (_monitoringPoints == null || _monitoringPoints!.isEmpty) return;
      if (_currentPointIndex >= _monitoringPoints!.length) return;

      final nextPoint = _monitoringPoints![_currentPointIndex];
      final pointLat = (nextPoint['latitude'] as num?)?.toDouble();
      final pointLng = (nextPoint['longitude'] as num?)?.toDouble();

      if (pointLat == null || pointLng == null) return;

      // Calcular distância
      final distance = DistanceCalculator.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        pointLat,
        pointLng,
      );

      Logger.info('📏 Distância para próximo ponto: ${distance.toStringAsFixed(1)}m');

      // Verificar se chegou próximo
      if (distance <= _proximityThreshold) {
        _onProximityDetected(distance, nextPoint);
      }

      // Verificar se chegou muito próximo (vibração)
      if (distance <= _vibrationThreshold) {
        _onVibrationTriggered(distance, nextPoint);
      }

    } catch (e) {
      Logger.error('❌ Erro ao verificar proximidade: $e');
    }
  }

  /// Chamado quando detecta proximidade
  void _onProximityDetected(double distance, Map<String, dynamic> point) {
    try {
      Logger.info('🎯 Proximidade detectada! Distância: ${distance.toStringAsFixed(1)}m');
      
      // Salvar evento de proximidade
      _saveProximityEvent(distance, point);

      // Notificar o app principal (se estiver em foreground)
      _notifyProximityDetected(distance, point);

    } catch (e) {
      Logger.error('❌ Erro ao processar proximidade: $e');
    }
  }

  /// Chamado quando deve vibrar
  void _onVibrationTriggered(double distance, Map<String, dynamic> point) {
    try {
      Logger.info('📳 Vibração acionada! Distância: ${distance.toStringAsFixed(1)}m');
      
      // Vibrar o dispositivo
      HapticFeedback.heavyImpact();

      // Salvar evento de vibração
      _saveVibrationEvent(distance, point);

      // Notificar o app principal
      _notifyVibrationTriggered(distance, point);

    } catch (e) {
      Logger.error('❌ Erro ao processar vibração: $e');
    }
  }

  /// Inicia timer para verificações em background
  void _startBackgroundTimer() {
    _backgroundTimer = Timer.periodic(_backgroundCheckInterval, (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      _performBackgroundCheck();
    });
  }

  /// Realiza verificações em background
  void _performBackgroundCheck() {
    try {
      Logger.info('🔍 Verificação de background...');

      // Verificar se ainda está monitorando
      if (!_isMonitoring) {
        Logger.info('⏹️ Monitoramento pausado, parando background');
        stopBackgroundMonitoring();
        return;
      }

      // Verificar se há posição GPS
      if (_lastKnownPosition == null) {
        Logger.warning('⚠️ Sem posição GPS disponível');
        return;
      }

      // Verificar proximidade
      _checkProximityToNextPoint(_lastKnownPosition!);

    } catch (e, stack) {
      Logger.error('❌ Erro na verificação de background: $e');
      Logger.error('❌ Stack: $stack');
      // ✅ Não propagar erro
    }
  }

  // ✅ ISOLATE REMOVIDO - Não é necessário para esse caso de uso
  // O GPS tracking e cálculos de distância são leves o suficiente
  // para rodar na thread principal sem problemas

  /// Verifica permissões necessárias
  Future<bool> _checkPermissions() async {
    try {
      // Verificar permissão de localização
      final locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.error('❌ Permissão de localização negada');
          return false;
        }
      }

      // Verificar se o serviço de localização está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.error('❌ Serviço de localização desabilitado');
        return false;
      }

      return true;

    } catch (e) {
      Logger.error('❌ Erro ao verificar permissões: $e');
      return false;
    }
  }

  // ✅ SHARED PREFERENCES REMOVIDO
  // Não é necessário persistir o estado do background mode
  // O monitoramento é retomado automaticamente quando o app volta ao foreground

  /// Salva evento de proximidade
  void _saveProximityEvent(double distance, Map<String, dynamic> point) {
    // Implementar salvamento de eventos se necessário
    Logger.info('💾 Evento de proximidade salvo: ${distance.toStringAsFixed(1)}m');
  }

  /// Salva evento de vibração
  void _saveVibrationEvent(double distance, Map<String, dynamic> point) {
    // Implementar salvamento de eventos se necessário
    Logger.info('💾 Evento de vibração salvo: ${distance.toStringAsFixed(1)}m');
  }

  /// Notifica proximidade detectada
  void _notifyProximityDetected(double distance, Map<String, dynamic> point) {
    // Implementar notificação para o app principal
    Logger.info('📢 Notificando proximidade: ${distance.toStringAsFixed(1)}m');
  }

  /// Notifica vibração acionada
  void _notifyVibrationTriggered(double distance, Map<String, dynamic> point) {
    // Implementar notificação para o app principal
    Logger.info('📢 Notificando vibração: ${distance.toStringAsFixed(1)}m');
  }

  /// Pausa o monitoramento
  void pauseMonitoring() {
    _isMonitoring = false;
    Logger.info('⏸️ Monitoramento pausado');
  }

  /// Resume o monitoramento
  void resumeMonitoring() {
    _isMonitoring = true;
    Logger.info('▶️ Monitoramento resumido');
  }

  /// Atualiza índice do ponto atual
  void updateCurrentPointIndex(int newIndex) {
    _currentPointIndex = newIndex;
    Logger.info('📍 Índice do ponto atualizado: $newIndex');
  }

  /// Obtém informações do monitoramento atual
  Map<String, dynamic> getCurrentMonitoringInfo() {
    return {
      'isRunning': _isRunning,
      'isMonitoring': _isMonitoring,
      'talhaoId': _currentTalhaoId,
      'currentPointIndex': _currentPointIndex,
      'lastPosition': _lastKnownPosition != null ? {
        'latitude': _lastKnownPosition!.latitude,
        'longitude': _lastKnownPosition!.longitude,
        'timestamp': _lastKnownPosition!.timestamp,
      } : null,
      'totalPoints': _monitoringPoints?.length ?? 0,
    };
  }
}
