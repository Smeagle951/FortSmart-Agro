import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar o status do sistema (GPS, Conectividade, etc.)
class SystemStatusService {
  static final SystemStatusService _instance = SystemStatusService._internal();
  factory SystemStatusService() => _instance;
  SystemStatusService._internal();

  // Estado do GPS
  bool _gpsEnabled = false;
  bool _gpsPermissionGranted = false;
  double _gpsAccuracy = 0.0;
  int _satelliteCount = 0;
  int _activeSatellites = 0;
  Position? _currentPosition;
  
  // Estado da conectividade
  bool _isOnline = false;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  String _connectionSpeed = 'N/A';
  int _connectionLatency = 0;
  
  // Sistemas GNSS disponíveis
  Map<String, int> _gnssSystems = {
    'GPS': 0,
    'GLONASS': 0,
    'GALILEO': 0,
    'BEIDOU': 0,
    'QZSS': 0,
    'IRNSS': 0,
  };
  
  // Streams e timers
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _statusUpdateTimer;
  
  // Callbacks
  Function()? onStatusChanged;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      Logger.info('🚀 Inicializando SystemStatusService...');
      
      // Verificar permissões de localização
      await _checkLocationPermissions();
      
      // Verificar conectividade
      await _checkConnectivity();
      
      // Configurar monitoramento contínuo
      _setupMonitoring();
      
      Logger.info('✅ SystemStatusService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar SystemStatusService: $e');
    }
  }
  
  /// Verifica permissões de localização
  Future<void> _checkLocationPermissions() async {
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _gpsEnabled = serviceEnabled;
      
      if (!serviceEnabled) {
        Logger.warning('⚠️ Serviço de localização desabilitado');
        return;
      }
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      _gpsPermissionGranted = permission == LocationPermission.whileInUse ||
                             permission == LocationPermission.always;
      
      if (_gpsPermissionGranted && _gpsEnabled) {
        // Tentar obter posição inicial
        await _getInitialPosition();
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar permissões de localização: $e');
    }
  }
  
  /// Obtém posição inicial
  Future<void> _getInitialPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      _gpsAccuracy = position.accuracy;
      
      // Simular dados de satélites (em produção, isso viria de APIs específicas)
      _simulateSatelliteData();
      
      Logger.info('📍 Posição GPS obtida: ${position.latitude}, ${position.longitude}');
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao obter posição GPS: $e');
      _gpsAccuracy = 0.0;
      _satelliteCount = 0;
      _activeSatellites = 0;
    }
  }
  
  /// Simula dados de satélites (placeholder para implementação real)
  void _simulateSatelliteData() {
    if (_gpsEnabled && _gpsPermissionGranted) {
      // Simular dados baseados na precisão
      if (_gpsAccuracy < 5.0) {
        _satelliteCount = 12;
        _activeSatellites = 10;
        _gnssSystems = {
          'GPS': 6,
          'GLONASS': 3,
          'GALILEO': 2,
          'BEIDOU': 1,
          'QZSS': 0,
          'IRNSS': 0,
        };
      } else if (_gpsAccuracy < 15.0) {
        _satelliteCount = 8;
        _activeSatellites = 6;
        _gnssSystems = {
          'GPS': 4,
          'GLONASS': 2,
          'GALILEO': 1,
          'BEIDOU': 1,
          'QZSS': 0,
          'IRNSS': 0,
        };
      } else {
        _satelliteCount = 4;
        _activeSatellites = 3;
        _gnssSystems = {
          'GPS': 3,
          'GLONASS': 1,
          'GALILEO': 0,
          'BEIDOU': 0,
          'QZSS': 0,
          'IRNSS': 0,
        };
      }
    } else {
      _satelliteCount = 0;
      _activeSatellites = 0;
      _gnssSystems = {
        'GPS': 0,
        'GLONASS': 0,
        'GALILEO': 0,
        'BEIDOU': 0,
        'QZSS': 0,
        'IRNSS': 0,
      };
    }
  }
  
  /// Verifica conectividade
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _connectionType = connectivityResult;
      
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          _isOnline = true;
          _connectionSpeed = 'WiFi';
          _connectionLatency = 20;
          break;
        case ConnectivityResult.mobile:
          _isOnline = true;
          _connectionSpeed = '4G/5G';
          _connectionLatency = 50;
          break;
        case ConnectivityResult.ethernet:
          _isOnline = true;
          _connectionSpeed = 'Ethernet';
          _connectionLatency = 10;
          break;
        default:
          _isOnline = false;
          _connectionSpeed = 'N/A';
          _connectionLatency = 0;
      }
      
      Logger.info('🌐 Conectividade: ${_isOnline ? "Online" : "Offline"} (${_connectionSpeed})');
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar conectividade: $e');
      _isOnline = false;
      _connectionSpeed = 'N/A';
    }
  }
  
  /// Configura monitoramento contínuo
  void _setupMonitoring() {
    // Monitorar mudanças de conectividade
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _connectionType = result;
      _checkConnectivity();
      onStatusChanged?.call();
    });
    
    // Timer para atualizar status GPS periodicamente
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_gpsEnabled && _gpsPermissionGranted) {
        _updateGPSStatus();
      }
      onStatusChanged?.call();
    });
  }
  
  /// Atualiza status GPS
  Future<void> _updateGPSStatus() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      _currentPosition = position;
      _gpsAccuracy = position.accuracy;
      _simulateSatelliteData();
      
    } catch (e) {
      // Manter dados anteriores em caso de erro
      Logger.warning('⚠️ Erro ao atualizar GPS: $e');
    }
  }
  
  /// Solicita permissões de localização
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      _gpsPermissionGranted = permission == LocationPermission.whileInUse ||
                             permission == LocationPermission.always;
      
      if (_gpsPermissionGranted) {
        await _getInitialPosition();
      }
      
      onStatusChanged?.call();
      return _gpsPermissionGranted;
      
    } catch (e) {
      Logger.error('❌ Erro ao solicitar permissão: $e');
      return false;
    }
  }
  
  /// Abre configurações de localização
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
  
  /// Getters
  bool get gpsEnabled => _gpsEnabled;
  bool get gpsPermissionGranted => _gpsPermissionGranted;
  double get gpsAccuracy => _gpsAccuracy;
  int get satelliteCount => _satelliteCount;
  int get activeSatellites => _activeSatellites;
  Position? get currentPosition => _currentPosition;
  
  bool get isOnline => _isOnline;
  ConnectivityResult get connectionType => _connectionType;
  String get connectionSpeed => _connectionSpeed;
  int get connectionLatency => _connectionLatency;
  
  Map<String, int> get gnssSystems => Map.from(_gnssSystems);
  
  String get gpsStatusText {
    if (!_gpsEnabled) return 'GPS Desligado';
    if (!_gpsPermissionGranted) return 'Permissão Negada';
    if (_gpsAccuracy == 0.0) return 'Buscando Sinal...';
    return 'GPS Ativo';
  }
  
  String get connectivityStatusText {
    if (!_isOnline) return 'Sem Conexão';
    return 'Conectado ($_connectionSpeed)';
  }
  
  /// Limpa recursos
  void dispose() {
    _positionSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _statusUpdateTimer?.cancel();
  }
}
