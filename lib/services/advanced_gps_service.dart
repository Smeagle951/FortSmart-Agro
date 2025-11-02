import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'gps_filter_service.dart';

/// Estados do serviço de GPS avançado
enum AdvancedGPSStatus {
  idle,           // Parado
  initializing,   // Inicializando
  ready,          // Pronto para captura
  recording,      // Gravando
  paused,         // Pausado
  finished,       // Finalizado
  error           // Erro
}

/// Tipos de sistemas de satélites suportados
enum SatelliteSystem {
  gps,        // Sistema GPS (EUA)
  glonass,    // Sistema GLONASS (Rússia)
  galileo,    // Sistema Galileo (Europa)
  beidou,     // Sistema BeiDou (China)
  qzss,       // Sistema QZSS (Japão)
  irnss       // Sistema IRNSS (Índia)
}

/// Informações detalhadas de satélites
class SatelliteInfo {
  final SatelliteSystem system;
  final int satelliteId;
  final double elevation;    // Elevação em graus
  final double azimuth;      // Azimute em graus
  final double snr;          // Signal-to-Noise Ratio
  final bool usedInFix;      // Se foi usado no cálculo da posição

  SatelliteInfo({
    required this.system,
    required this.satelliteId,
    required this.elevation,
    required this.azimuth,
    required this.snr,
    required this.usedInFix,
  });

  @override
  String toString() {
    return 'SatelliteInfo(system: $system, id: $satelliteId, elevation: ${elevation.toStringAsFixed(1)}°, azimuth: ${azimuth.toStringAsFixed(1)}°, snr: ${snr.toStringAsFixed(1)}dB, used: $usedInFix)';
  }
}

/// Informações detalhadas de posição GPS
class AdvancedPosition {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;           // Precisão em metros
  final double speed;              // Velocidade em m/s
  final double heading;            // Direção em graus
  final DateTime timestamp;
  final List<SatelliteInfo> satellites;
  final Map<SatelliteSystem, int> satellitesBySystem;
  final double hdop;               // Horizontal Dilution of Precision
  final double vdop;               // Vertical Dilution of Precision
  final double pdop;               // Position Dilution of Precision
  final bool isHighAccuracy;       // Se a precisão é alta (< 5m)

  AdvancedPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.timestamp,
    required this.satellites,
    required this.satellitesBySystem,
    required this.hdop,
    required this.vdop,
    required this.pdop,
    required this.isHighAccuracy,
  });

  /// Converte para LatLng
  LatLng get position => LatLng(latitude, longitude);

  /// Obtém informações de qualidade do sinal
  String get qualityInfo {
    if (accuracy <= 2.0) return 'Excelente';
    if (accuracy <= 5.0) return 'Muito Boa';
    if (accuracy <= 10.0) return 'Boa';
    if (accuracy <= 20.0) return 'Regular';
    return 'Baixa';
  }

  /// Obtém total de satélites utilizados
  int get totalSatellitesUsed => satellites.where((s) => s.usedInFix).length;

  /// Obtém total de satélites visíveis
  int get totalSatellitesVisible => satellites.length;

  @override
  String toString() {
    return 'AdvancedPosition(lat: ${latitude.toStringAsFixed(6)}, lng: ${longitude.toStringAsFixed(6)}, accuracy: ${accuracy.toStringAsFixed(1)}m, satellites: ${totalSatellitesUsed}/${totalSatellitesVisible}, quality: $qualityInfo)';
  }
}

/// Serviço de GPS avançado com suporte a múltiplos sistemas de satélites
class AdvancedGPSService extends ChangeNotifier {
  static const String _tag = 'AdvancedGPSService';
  
  // Estado do serviço
  AdvancedGPSStatus _status = AdvancedGPSStatus.idle;
  AdvancedPosition? _lastPosition;
  List<AdvancedPosition> _positionHistory = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _statusTimer;
  
  // Serviço de filtros
  final GPSFilterService _filterService = GPSFilterService();
  
  // Configurações
  LocationAccuracy _desiredAccuracy = LocationAccuracy.bestForNavigation;
  int _distanceFilter = 1; // metros
  Duration _timeLimit = const Duration(seconds: 30);
  double _minAccuracy = 20.0; // metros
  
  // Callbacks
  Function(AdvancedPosition)? onPositionUpdate;
  Function(String)? onError;
  Function(AdvancedGPSStatus)? onStatusChange;
  
  // Getters
  AdvancedGPSStatus get status => _status;
  AdvancedPosition? get lastPosition => _lastPosition;
  List<AdvancedPosition> get positionHistory => List.unmodifiable(_positionHistory);
  bool get isReady => _status == AdvancedGPSStatus.ready;
  bool get isRecording => _status == AdvancedGPSStatus.recording;
  bool get isPaused => _status == AdvancedGPSStatus.paused;
  
  /// Inicializa o serviço de GPS
  Future<bool> initialize() async {
    try {
      _updateStatus(AdvancedGPSStatus.initializing);
      
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Serviço de localização desabilitado');
        return false;
      }

      // Verificar e solicitar permissões
      if (!await _requestPermissions()) {
        return false;
      }

      // Testar GPS com uma posição inicial
      try {
        final testPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: _desiredAccuracy,
          timeLimit: const Duration(seconds: 15),
        );
        
        if (testPosition.accuracy > 50.0) {
          _showError('GPS com baixa precisão inicial. Aguarde estabilização.');
        }
        
        print('$_tag: GPS inicializado com sucesso. Precisão inicial: ${testPosition.accuracy}m');
        
      } catch (e) {
        print('$_tag: Aviso - GPS pode estar lento: $e');
        // Não falhar aqui, apenas avisar
      }
      
      _updateStatus(AdvancedGPSStatus.ready);
      return true;
      
    } catch (e) {
      print('$_tag: Erro ao inicializar GPS: $e');
      _showError('Erro ao inicializar GPS: $e');
      _updateStatus(AdvancedGPSStatus.error);
      return false;
    }
  }

  /// Solicita permissões necessárias
  Future<bool> _requestPermissions() async {
    try {
      // Verificar permissão de localização
      LocationPermission locationPermission = await Geolocator.checkPermission();
      
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
        if (locationPermission == LocationPermission.denied) {
          _showError('Permissão de localização negada');
          return false;
        }
      }
      
      if (locationPermission == LocationPermission.deniedForever) {
        _showError('Permissão de localização negada permanentemente');
        return false;
      }

      // Para Android, verificar permissão de localização em background
      if (Platform.isAndroid) {
        final backgroundPermission = await Permission.locationAlways.request();
        if (!backgroundPermission.isGranted) {
          print('$_tag: Aviso - Permissão de localização em background não concedida');
        }
      }

      return true;
      
    } catch (e) {
      print('$_tag: Erro ao solicitar permissões: $e');
      _showError('Erro ao solicitar permissões: $e');
      return false;
    }
  }

  /// Inicia captura de posições GPS
  Future<bool> startPositionCapture() async {
    try {
      if (_status != AdvancedGPSStatus.ready) {
        _showError('GPS não está pronto. Inicialize primeiro.');
        return false;
      }

      _updateStatus(AdvancedGPSStatus.recording);
      _positionHistory.clear();
      
      // Configurar stream de posições com alta precisão
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: _desiredAccuracy,
          distanceFilter: _distanceFilter,
          timeLimit: _timeLimit,
        ),
      ).listen(
        _onPositionUpdate,
        onError: (error) {
          print('$_tag: Erro no stream GPS: $error');
          _handleStreamError(error);
        },
      );
      
      print('$_tag: Captura de posições iniciada');
      return true;
      
    } catch (e) {
      print('$_tag: Erro ao iniciar captura: $e');
      _showError('Erro ao iniciar captura GPS: $e');
      _updateStatus(AdvancedGPSStatus.error);
      return false;
    }
  }

  /// Para captura de posições
  void stopPositionCapture() {
    _positionStreamSubscription?.cancel();
    _statusTimer?.cancel();
    _updateStatus(AdvancedGPSStatus.finished);
    print('$_tag: Captura de posições finalizada');
  }

  /// Pausa captura de posições
  void pausePositionCapture() {
    if (_status == AdvancedGPSStatus.recording) {
      _positionStreamSubscription?.cancel();
      _statusTimer?.cancel();
      _updateStatus(AdvancedGPSStatus.paused);
      print('$_tag: Captura de posições pausada');
    }
  }

  /// Retoma captura de posições
  Future<bool> resumePositionCapture() async {
    if (_status == AdvancedGPSStatus.paused) {
      return await startPositionCapture();
    }
    return false;
  }

  /// Obtém posição atual com alta precisão
  Future<AdvancedPosition?> getCurrentPosition() async {
    try {
      if (_status == AdvancedGPSStatus.idle) {
        await initialize();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _desiredAccuracy,
        timeLimit: _timeLimit,
      );

      return _convertToAdvancedPosition(position);
      
    } catch (e) {
      print('$_tag: Erro ao obter posição atual: $e');
      _showError('Erro ao obter posição atual: $e');
      return null;
    }
  }

  /// Processa atualização de posição
  void _onPositionUpdate(Position position) {
    try {
      final advancedPosition = _convertToAdvancedPosition(position);
      
      // Aplicar filtros antes de aceitar a posição
      final filteredPosition = _filterService.filterPosition(advancedPosition);
      
      if (filteredPosition == null) {
        print('$_tag: Posição rejeitada pelos filtros');
        return;
      }
      
      _lastPosition = filteredPosition;
      _positionHistory.add(filteredPosition);
      
      // Manter apenas as últimas 100 posições
      if (_positionHistory.length > 100) {
        _positionHistory.removeAt(0);
      }
      
      // Chamar callback
      onPositionUpdate?.call(filteredPosition);
      
      print('$_tag: Posição filtrada aceita: ${filteredPosition.toString()}');
      notifyListeners();
      
    } catch (e) {
      print('$_tag: Erro ao processar posição: $e');
      _showError('Erro ao processar posição: $e');
    }
  }

  /// Converte Position para AdvancedPosition
  AdvancedPosition _convertToAdvancedPosition(Position position) {
    // Simular informações de satélites (em um app real, isso viria do hardware)
    final satellites = _generateSatelliteInfo(position);
    final satellitesBySystem = _groupSatellitesBySystem(satellites);
    
    return AdvancedPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
      satellites: satellites,
      satellitesBySystem: satellitesBySystem,
      hdop: _calculateHDOP(position.accuracy),
      vdop: _calculateVDOP(position.accuracy),
      pdop: _calculatePDOP(position.accuracy),
      isHighAccuracy: position.accuracy <= 5.0,
    );
  }

  /// Gera informações simuladas de satélites
  List<SatelliteInfo> _generateSatelliteInfo(Position position) {
    final satellites = <SatelliteInfo>[];
    final systems = SatelliteSystem.values;
    
    // Simular 8-15 satélites visíveis
    final totalSatellites = 8 + (DateTime.now().millisecond % 8);
    final usedSatellites = (totalSatellites * 0.7).round(); // 70% usados no fix
    
    for (int i = 0; i < totalSatellites; i++) {
      final system = systems[i % systems.length];
      final isUsed = i < usedSatellites;
      
      satellites.add(SatelliteInfo(
        system: system,
        satelliteId: i + 1,
        elevation: 10.0 + (i * 5.0) % 80.0,
        azimuth: (i * 45.0) % 360.0,
        snr: isUsed ? 35.0 + (i * 2.0) % 15.0 : 20.0 + (i * 1.0) % 10.0,
        usedInFix: isUsed,
      ));
    }
    
    return satellites;
  }

  /// Agrupa satélites por sistema
  Map<SatelliteSystem, int> _groupSatellitesBySystem(List<SatelliteInfo> satellites) {
    final Map<SatelliteSystem, int> grouped = {};
    
    for (final satellite in satellites) {
      grouped[satellite.system] = (grouped[satellite.system] ?? 0) + 1;
    }
    
    return grouped;
  }

  /// Calcula HDOP (Horizontal Dilution of Precision)
  double _calculateHDOP(double accuracy) {
    // Fórmula simplificada baseada na precisão
    return (accuracy / 2.0).clamp(0.5, 10.0);
  }

  /// Calcula VDOP (Vertical Dilution of Precision)
  double _calculateVDOP(double accuracy) {
    // VDOP geralmente é maior que HDOP
    return (accuracy / 1.5).clamp(0.8, 15.0);
  }

  /// Calcula PDOP (Position Dilution of Precision)
  double _calculatePDOP(double accuracy) {
    // PDOP é a combinação de HDOP e VDOP
    final hdop = _calculateHDOP(accuracy);
    final vdop = _calculateVDOP(accuracy);
    return (hdop * hdop + vdop * vdop).clamp(1.0, 20.0);
  }

  /// Trata erros do stream GPS
  void _handleStreamError(dynamic error) {
    String errorMessage = 'Erro GPS desconhecido';
    
    if (error.toString().contains('TimeoutException')) {
      errorMessage = 'Timeout GPS: Aguardando sinal. Verifique se está em área aberta.';
    } else if (error.toString().contains('LocationServiceDisabledException')) {
      errorMessage = 'GPS desabilitado. Ative o GPS nas configurações.';
    } else if (error.toString().contains('PermissionDeniedException')) {
      errorMessage = 'Permissão de localização negada.';
    } else {
      errorMessage = 'Erro na captura GPS: $error';
    }
    
    _showError(errorMessage);
  }

  /// Atualiza status do serviço
  void _updateStatus(AdvancedGPSStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onStatusChange?.call(newStatus);
      notifyListeners();
    }
  }

  /// Mostra erro
  void _showError(String message) {
    print('$_tag: $message');
    onError?.call(message);
  }

  /// Obtém estatísticas do GPS
  Map<String, dynamic> getGPSStatistics() {
    if (_positionHistory.isEmpty) {
      return {
        'total_positions': 0,
        'average_accuracy': 0.0,
        'best_accuracy': 0.0,
        'worst_accuracy': 0.0,
        'total_satellites_used': 0,
        'total_satellites_visible': 0,
        'systems_used': <String>[],
        'filter_statistics': _filterService.getFilterStatistics(),
      };
    }

    final accuracies = _positionHistory.map((p) => p.accuracy).toList();
    final satellitesUsed = _positionHistory.map((p) => p.totalSatellitesUsed).toList();
    final satellitesVisible = _positionHistory.map((p) => p.totalSatellitesVisible).toList();
    
    final systemsUsed = <String>{};
    for (final position in _positionHistory) {
      for (final system in position.satellitesBySystem.keys) {
        systemsUsed.add(system.toString().split('.').last.toUpperCase());
      }
    }

    return {
      'total_positions': _positionHistory.length,
      'average_accuracy': accuracies.reduce((a, b) => a + b) / accuracies.length,
      'best_accuracy': accuracies.reduce((a, b) => a < b ? a : b),
      'worst_accuracy': accuracies.reduce((a, b) => a > b ? a : b),
      'average_satellites_used': satellitesUsed.reduce((a, b) => a + b) / satellitesUsed.length,
      'average_satellites_visible': satellitesVisible.reduce((a, b) => a + b) / satellitesVisible.length,
      'systems_used': systemsUsed.toList(),
      'high_accuracy_positions': _positionHistory.where((p) => p.isHighAccuracy).length,
      'filter_statistics': _filterService.getFilterStatistics(),
    };
  }

  /// Obtém posições filtradas adequadas para cálculo de área
  List<AdvancedPosition> getFilteredPositionsForAreaCalculation() {
    return _filterService.getFilteredPositionsForAreaCalculation();
  }

  /// Obtém pontos de polígono filtrados
  List<LatLng> getFilteredPolygonPoints({double maxAccuracy = 5.0}) {
    final positions = getFilteredPositionsForAreaCalculation();
    final points = positions.map((p) => p.position).toList();
    return _filterService.filterPolygonPoints(points, maxAccuracy: maxAccuracy);
  }

  /// Valida qualidade de um polígono
  bool validatePolygonQuality(List<LatLng> points) {
    return _filterService.validatePolygonQuality(points);
  }

  /// Obtém estatísticas dos filtros
  Map<String, dynamic> getFilterStatistics() {
    return _filterService.getFilterStatistics();
  }

  /// Limpa histórico de posições
  void clearPositionHistory() {
    _positionHistory.clear();
    _filterService.clearHistory();
    print('$_tag: Histórico de posições limpo');
  }

  /// Configura precisão desejada
  void setDesiredAccuracy(LocationAccuracy accuracy) {
    _desiredAccuracy = accuracy;
    print('$_tag: Precisão configurada para: $accuracy');
  }

  /// Configura filtro de distância
  void setDistanceFilter(int meters) {
    _distanceFilter = meters;
    print('$_tag: Filtro de distância configurado para: ${meters}m');
  }

  /// Configura precisão mínima aceitável
  void setMinAccuracy(double meters) {
    _minAccuracy = meters;
    print('$_tag: Precisão mínima configurada para: ${meters}m');
  }

  /// Abre configurações de localização
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abre configurações do app
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }
}

/// Extensões para facilitar o uso
extension AdvancedGPSServiceExtensions on AdvancedGPSService {
  /// Obtém informações de qualidade do GPS
  String getQualityInfo() {
    if (_lastPosition == null) return 'Sem dados';
    return _lastPosition!.qualityInfo;
  }

  /// Verifica se o GPS está funcionando bem
  bool isGPSWorkingWell() {
    if (_lastPosition == null) return false;
    return _lastPosition!.isHighAccuracy && _lastPosition!.totalSatellitesUsed >= 4;
  }

  /// Obtém lista de sistemas de satélites ativos
  List<String> getActiveSatelliteSystems() {
    if (_lastPosition == null) return [];
    return _lastPosition!.satellitesBySystem.keys
        .map((s) => s.toString().split('.').last.toUpperCase())
        .toList();
  }
}
