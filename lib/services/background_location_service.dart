import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  Timer? _keepAliveTimer;
  
  // Callbacks
  Function(Position)? onLocationUpdate;
  Function(String)? onError;
  Function()? onTrackingStarted;
  Function()? onTrackingStopped;

  /// Inicia o rastreamento de localização em segundo plano
  Future<bool> startBackgroundTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onError,
    Function()? onTrackingStarted,
    Function()? onTrackingStopped,
    Duration updateInterval = const Duration(seconds: 10),
    double distanceFilter = 10.0, // metros
  }) async {
    try {
      Logger.info('🔄 Iniciando rastreamento de localização em segundo plano...');

      // Verificar permissões
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        Logger.error('❌ Permissões de localização não concedidas');
        onError?.call('Permissões de localização não concedidas');
        return false;
      }

      // Verificar se o serviço de localização está habilitado
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        Logger.error('❌ Serviço de localização desabilitado');
        onError?.call('Serviço de localização desabilitado');
        return false;
      }

      // Configurar callbacks
      this.onLocationUpdate = onLocationUpdate;
      this.onError = onError;
      this.onTrackingStarted = onTrackingStarted;
      this.onTrackingStopped = onTrackingStopped;

      // Manter tela ligada
      await WakelockPlus.enable();
      Logger.info('✅ Wakelock ativado');

      // Configurar opções de localização
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metros
        timeLimit: Duration(seconds: 30),
      );

      // Iniciar stream de localização
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          Logger.info('📍 Nova posição: ${position.latitude}, ${position.longitude}');
          onLocationUpdate?.call(position);
        },
        onError: (error) {
          Logger.error('❌ Erro no rastreamento: $error');
          onError?.call(error.toString());
        },
      );

      // Timer para manter o serviço ativo
      _keepAliveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        Logger.info('💓 Keep-alive: Serviço de localização ativo');
      });

      _isTracking = true;
      onTrackingStarted?.call();
      
      Logger.info('✅ Rastreamento de localização iniciado com sucesso');
      return true;

    } catch (e) {
      Logger.error('❌ Erro ao iniciar rastreamento: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Para o rastreamento de localização
  Future<void> stopBackgroundTracking() async {
    try {
      Logger.info('🛑 Parando rastreamento de localização...');

      // Parar stream de localização
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      // Parar timer de keep-alive
      _keepAliveTimer?.cancel();
      _keepAliveTimer = null;

      // Desativar wakelock
      await WakelockPlus.disable();
      Logger.info('✅ Wakelock desativado');

      _isTracking = false;
      onTrackingStopped?.call();

      Logger.info('✅ Rastreamento de localização parado com sucesso');

    } catch (e) {
      Logger.error('❌ Erro ao parar rastreamento: $e');
    }
  }

  /// Verifica se está rastreando
  bool get isTracking => _isTracking;

  /// Obtém a posição atual uma vez
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        Logger.error('❌ Permissões de localização não concedidas');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      Logger.info('📍 Posição atual: ${position.latitude}, ${position.longitude}');
      return position;

    } catch (e) {
      Logger.error('❌ Erro ao obter posição atual: $e');
      return null;
    }
  }

  /// Verifica e solicita permissões necessárias
  Future<bool> _checkPermissions() async {
    try {
      // Verificar permissão de localização
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.error('❌ Permissão de localização negada');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.error('❌ Permissão de localização negada permanentemente');
        return false;
      }

      // Verificar permissão de localização em segundo plano (Android)
      if (Platform.isAndroid) {
        final backgroundPermission = await Permission.locationAlways.request();
        if (backgroundPermission != PermissionStatus.granted) {
          Logger.warning('⚠️ Permissão de localização em segundo plano não concedida');
          // Continuar mesmo sem permissão de segundo plano
        }
      }

      Logger.info('✅ Permissões de localização concedidas');
      return true;

    } catch (e) {
      Logger.error('❌ Erro ao verificar permissões: $e');
      return false;
    }
  }

  /// Calcula distância entre duas posições
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Verifica se o serviço de localização está habilitado
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Abre as configurações de localização
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abre as configurações de permissões
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Dispose do serviço
  void dispose() {
    stopBackgroundTracking();
  }
}
