import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/logger.dart';

/// Serviço de rastreamento GPS em background
/// Funciona mesmo com a tela desligada usando flutter_foreground_task
class BackgroundGpsTrackingService {
  // Configurações de precisão
  static const double _maxAccuracy = 15.0; // metros
  static const double _minDistance = 0.5; // metros
  static const double _maxJumpDistance = 50.0; // metros
  static const int _maxJumpTime = 3; // segundos
  static const int _warmupPoints = 2;
  static const int _minIntervalMs = 1000; // 1 segundo entre pontos
  
  // Estado do rastreamento
  bool _isTracking = false;
  bool _isPaused = false;
  StreamSubscription<Position>? _positionSubscription;
  
  // Pontos e métricas
  final List<GpsPoint> _trackPoints = [];
  LatLng? _lastValidPoint;
  DateTime? _lastValidTime;
  double _totalDistance = 0.0;
  double _currentAccuracy = 0.0;
  int _warmupCount = 0;
  
  // Callbacks
  Function(List<LatLng>)? _onPointsChanged;
  Function(double)? _onDistanceChanged;
  Function(double)? _onAccuracyChanged;
  Function(String)? _onStatusChanged;
  Function(bool)? _onTrackingStateChanged;
  
  // Receive port para comunicação com o isolate
  ReceivePort? _receivePort;
  
  /// Inicia o rastreamento GPS em background
  Future<bool> startTracking({
    required Function(List<LatLng>) onPointsChanged,
    required Function(double) onDistanceChanged,
    required Function(double) onAccuracyChanged,
    required Function(String) onStatusChanged,
    required Function(bool) onTrackingStateChanged,
  }) async {
    try {
      Logger.info('🚀 Iniciando rastreamento GPS em background...');
      
      // Verificar se o GPS está habilitado
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        Logger.error('❌ Serviço de localização desabilitado');
        throw Exception('Serviço de localização desabilitado. Habilite o GPS nas configurações.');
      }
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }
      
      // Configurar callbacks
      _onPointsChanged = onPointsChanged;
      _onDistanceChanged = onDistanceChanged;
      _onAccuracyChanged = onAccuracyChanged;
      _onStatusChanged = onStatusChanged;
      _onTrackingStateChanged = onTrackingStateChanged;
      
      // Limpar estado anterior
      _resetTracking();
      
      // Ativar wakelock para manter o GPS ativo
      await WakelockPlus.enable();
      Logger.info('🔋 Wakelock ativado');
      
      // Inicializar foreground task
      await _initializeForegroundTask();
      
      // Iniciar foreground task
      final started = await FlutterForegroundTask.startService(
        notificationTitle: 'FortSmart Agro - GPS Ativo',
        notificationText: 'Rastreando localização...',
        callback: startGpsCallback,
      );
      
      if (started == null) {
        throw Exception('Não foi possível iniciar o serviço em background');
      }
      
      // Configurar stream de localização
      await _startLocationStream();
      
      _isTracking = true;
      _onTrackingStateChanged?.call(true);
      _onStatusChanged?.call('Rastreamento GPS em background ativo');
      
      Logger.info('✅ Rastreamento GPS em background iniciado com sucesso');
      return true;
      
    } catch (e) {
      Logger.error('❌ Erro ao iniciar rastreamento em background: $e');
      _onStatusChanged?.call('Erro ao iniciar rastreamento: $e');
      await WakelockPlus.disable();
      return false;
    }
  }
  
  /// Inicializa foreground task
  Future<void> _initializeForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fortsmart_gps_tracking',
        channelName: 'Rastreamento GPS',
        channelDescription: 'Rastreamento GPS em background para mapeamento de talhões',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // Ícone padrão do Android
        // icon: NotificationIcon(metaDataName: 'com.fortsmart.agro.notification_icon'),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000), // 1 segundo
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  
  /// Inicia stream de localização
  Future<void> _startLocationStream() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0, // Sem filtro de distância
      timeLimit: const Duration(seconds: 30),
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: _onPositionError,
      cancelOnError: false,
    );
    
    Logger.info('📡 Stream de localização iniciado');
  }
  
  /// Processa atualização de posição
  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) return;
    
    Logger.info('📍 Nova posição: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
    
    final point = GpsPoint.fromPosition(position);
    
    // Verificar se o ponto é válido
    if (!_isValidPoint(point)) {
      Logger.info('❌ Ponto rejeitado: ${point.rejectionReason}');
      return;
    }
    
    // Adicionar ponto
    _addPoint(point);
  }
  
  /// Verifica se um ponto é válido
  bool _isValidPoint(GpsPoint point) {
    // 1. Verificar accuracy
    if (point.accuracy > _maxAccuracy) {
      point.rejectionReason = 'Accuracy muito baixa: ${point.accuracy}m';
      return false;
    }
    
    // 2. Warm-up
    if (_warmupCount < _warmupPoints) {
      _warmupCount++;
      Logger.info('✨ Warm-up: $_warmupCount/$_warmupPoints');
      return true;
    }
    
    // 3. Verificar intervalo mínimo
    if (_lastValidTime != null) {
      final timeDiff = point.timestamp.difference(_lastValidTime!).inMilliseconds;
      if (timeDiff < _minIntervalMs) {
        point.rejectionReason = 'Intervalo muito curto: ${timeDiff}ms';
        return false;
      }
    }
    
    // 4. Verificar salto irreal
    if (_lastValidPoint != null && _lastValidTime != null) {
      final distance = _calculateDistance(_lastValidPoint!, point.toLatLng());
      final timeDiff = point.timestamp.difference(_lastValidTime!).inSeconds;
      
      if (distance > _maxJumpDistance && timeDiff < _maxJumpTime) {
        point.rejectionReason = 'Salto irreal: ${distance.toStringAsFixed(1)}m em ${timeDiff}s';
        return false;
      }
    }
    
    return true;
  }
  
  /// Adiciona um ponto válido
  void _addPoint(GpsPoint point) {
    _trackPoints.add(point);
    
    // Atualizar métricas
    if (_lastValidPoint != null) {
      final distance = _calculateDistance(_lastValidPoint!, point.toLatLng());
      _totalDistance += distance;
    }
    
    _lastValidPoint = point.toLatLng();
    _lastValidTime = point.timestamp;
    _currentAccuracy = point.accuracy;
    
    // Notificar mudanças
    final pointsList = _trackPoints.map((p) => p.toLatLng()).toList();
    _onPointsChanged?.call(pointsList);
    _onDistanceChanged?.call(_totalDistance);
    _onAccuracyChanged?.call(_currentAccuracy);
    
    // Atualizar notificação
    _updateNotification();
    
    Logger.info('✅ Ponto adicionado - Total: ${_trackPoints.length}, Distância: ${_totalDistance.toStringAsFixed(2)}m');
  }
  
  /// Atualiza notificação com progresso
  void _updateNotification() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'FortSmart Agro - GPS Ativo',
      notificationText: '${_trackPoints.length} pontos | ${(_totalDistance).toStringAsFixed(0)}m | Precisão: ${_currentAccuracy.toStringAsFixed(1)}m',
    );
  }
  
  /// Trata erro de posição
  void _onPositionError(dynamic error) {
    Logger.error('❌ Erro no GPS: $error');
    _onStatusChanged?.call('Erro no GPS: $error');
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  
  /// Pausa o rastreamento
  void pauseTracking() {
    if (!_isTracking) return;
    
    _isPaused = true;
    _onStatusChanged?.call('Rastreamento pausado');
    _onTrackingStateChanged?.call(false);
    
    FlutterForegroundTask.updateService(
      notificationTitle: 'FortSmart Agro - GPS Pausado',
      notificationText: 'Toque para continuar...',
    );
    
    Logger.info('⏸️ Rastreamento GPS pausado');
  }
  
  /// Retoma o rastreamento
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    
    _isPaused = false;
    _onStatusChanged?.call('Rastreamento retomado');
    _onTrackingStateChanged?.call(true);
    
    _updateNotification();
    
    Logger.info('▶️ Rastreamento GPS retomado');
  }
  
  /// Para o rastreamento
  Future<void> stopTracking() async {
    try {
      _isTracking = false;
      _isPaused = false;
      
      // Cancelar subscription
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      // Parar foreground task
      await FlutterForegroundTask.stopService();
      
      // Desativar wakelock
      await WakelockPlus.disable();
      
      _onTrackingStateChanged?.call(false);
      _onStatusChanged?.call('Rastreamento finalizado');
      
      Logger.info('⏹️ Rastreamento GPS finalizado - Total de pontos: ${_trackPoints.length}');
      
    } catch (e) {
      Logger.error('❌ Erro ao parar rastreamento: $e');
    }
  }
  
  /// Reseta o estado do rastreamento
  void _resetTracking() {
    _trackPoints.clear();
    _lastValidPoint = null;
    _lastValidTime = null;
    _totalDistance = 0.0;
    _currentAccuracy = 0.0;
    _warmupCount = 0;
  }
  
  /// Obtém pontos do rastreamento
  List<LatLng> getTrackPoints() {
    return _trackPoints.map((p) => p.toLatLng()).toList();
  }
  
  /// Obtém estatísticas do rastreamento
  Map<String, dynamic> getTrackingStats() {
    return {
      'totalPoints': _trackPoints.length,
      'totalDistance': _totalDistance,
      'currentAccuracy': _currentAccuracy,
      'isTracking': _isTracking,
      'isPaused': _isPaused,
      'warmupCompleted': _warmupCount >= _warmupPoints,
    };
  }
  
  /// Dispose do serviço
  void dispose() {
    stopTracking();
    _receivePort?.close();
  }
  
  // Getters
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  List<LatLng> get trackPoints => _trackPoints.map((p) => p.toLatLng()).toList();
  double get totalDistance => _totalDistance;
  double get currentAccuracy => _currentAccuracy;
  int get pointsCount => _trackPoints.length;
}

/// Callback para foreground task
@pragma('vm:entry-point')
void startGpsCallback() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}

/// Handler para foreground task
class GpsTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    Logger.info('🚀 GPS Task Handler iniciado');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Este método é chamado periodicamente (conforme interval definido)
    // Manter vazio pois o stream do Geolocator já cuida das atualizações
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    Logger.info('⏹️ GPS Task Handler destruído');
  }

  @override
  void onNotificationButtonPressed(String id) {
    Logger.info('🔘 Botão de notificação pressionado: $id');
  }

  @override
  void onNotificationPressed() {
    Logger.info('🔔 Notificação pressionada');
    FlutterForegroundTask.launchApp('/');
  }
}

/// Modelo para ponto GPS
class GpsPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final double? bearing;
  final DateTime timestamp;
  String? rejectionReason;
  
  GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    this.bearing,
    required this.timestamp,
    this.rejectionReason,
  });
  
  factory GpsPoint.fromPosition(Position position) {
    return GpsPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      bearing: position.heading,
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }
  
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
  
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'bearing': bearing,
      'timestamp': timestamp.toIso8601String(),
      'rejection_reason': rejectionReason,
    };
  }
}

