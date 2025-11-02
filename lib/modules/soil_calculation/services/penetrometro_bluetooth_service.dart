import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/penetrometro_reading_model.dart';
import '../models/penetrometro_device_model.dart';

/// Serviço para comunicação Bluetooth com penetrômetro
class PenetrometroBluetoothService {
  final FlutterReactiveBle _ble;
  final Uuid serviceUuid;
  final Uuid charUuid;

  // Streams
  final StreamController<PenetrometroReading> _readingController = 
      StreamController<PenetrometroReading>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
  final StreamController<DiscoveredDevice> _deviceController = 
      StreamController<DiscoveredDevice>.broadcast();

  // Estado
  DiscoveredDevice? _connectedDevice;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<BleStatus>? _statusSub;
  
  bool _isScanning = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  // Configurações
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;

  PenetrometroBluetoothService({
    required this.serviceUuid,
    required this.charUuid,
  }) : _ble = FlutterReactiveBle() {
    _initStatusListener();
  }

  /// Streams públicos
  Stream<PenetrometroReading> get readings => _readingController.stream;
  Stream<String> get status => _statusController.stream;
  Stream<DiscoveredDevice> get discoveredDevices => _deviceController.stream;
  
  /// Getters de estado
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  DiscoveredDevice? get connectedDevice => _connectedDevice;

  /// Inicializa listener de status do Bluetooth
  void _initStatusListener() {
    _statusSub = _ble.statusStream.listen((status) {
      String statusText;
      switch (status) {
        case BleStatus.unknown:
          statusText = 'Status desconhecido';
          break;
        case BleStatus.unsupported:
          statusText = 'Bluetooth não suportado';
          break;
        case BleStatus.unauthorized:
          statusText = 'Permissão negada';
          break;
        case BleStatus.poweredOff:
          statusText = 'Bluetooth desligado';
          break;
        case BleStatus.locationServicesDisabled:
          statusText = 'Localização desabilitada';
          break;
        case BleStatus.ready:
          statusText = 'Pronto para conectar';
          break;
      }
      _statusController.add(statusText);
    });
  }

  /// Verifica e solicita permissões necessárias
  Future<bool> checkPermissions() async {
    try {
      // Verifica se Bluetooth está ligado
      final bleStatus = _ble.status;
      if (bleStatus != BleStatus.ready) {
        _statusController.add('Bluetooth não está pronto: $bleStatus');
        return false;
      }

      // Solicita permissões
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.locationWhenInUse,
      ];

      final results = await permissions.request();
      
      for (final permission in permissions) {
        if (!results[permission]!.isGranted) {
          _statusController.add('Permissão negada: $permission');
          return false;
        }
      }

      return true;
    } catch (e) {
      _statusController.add('Erro ao verificar permissões: $e');
      return false;
    }
  }

  /// Escaneia dispositivos (filtra pelo service UUID ou nome)
  Stream<DiscoveredDevice> scanForDevices({String? nameFilter, Duration? timeout}) {
    if (_isScanning) {
      throw Exception('Já está escaneando');
    }

    _isScanning = true;
    _statusController.add('Escaneando dispositivos...');

    final stream = _ble.scanForDevices(
      withServices: [serviceUuid],
      scanMode: ScanMode.lowLatency,
    );

    _scanSub = stream.listen(
      (device) {
        if (nameFilter == null || (device.name?.contains(nameFilter) ?? false)) {
          _deviceController.add(device);
        }
      },
      onError: (error) {
        _statusController.add('Erro no scan: $error');
        _isScanning = false;
      },
      onDone: () {
        _isScanning = false;
        _statusController.add('Scan finalizado');
      },
    );

    // Timeout automático
    if (timeout != null) {
      Timer(timeout, () {
        stopScan();
      });
    }

    return stream.where((device) => 
        nameFilter == null || (device.name?.contains(nameFilter) ?? false));
  }

  /// Para o scan
  void stopScan() {
    _scanSub?.cancel();
    _isScanning = false;
    _statusController.add('Scan interrompido');
  }

  /// Conecta ao dispositivo com reconexão automática
  Future<bool> connectToDevice(String deviceId) async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      _statusController.add('Conectando ao dispositivo...');
      _reconnectAttempts = 0;

      _connection?.cancel();
      _connection = _ble.connectToDevice(
        id: deviceId,
        connectionTimeout: _connectionTimeout,
      ).listen(
        (update) async {
          switch (update.connectionState) {
            case DeviceConnectionState.connected:
              _isConnected = true;
              _reconnectAttempts = 0;
              _statusController.add('Conectado com sucesso');
              await _startNotifications(deviceId);
              break;
              
            case DeviceConnectionState.disconnected:
              _isConnected = false;
              _statusController.add('Desconectado');
              _scheduleReconnect(deviceId);
              break;
              
            case DeviceConnectionState.connecting:
              _statusController.add('Conectando...');
              break;
              
            case DeviceConnectionState.disconnecting:
              _statusController.add('Desconectando...');
              break;
          }
        },
        onError: (error) {
          _statusController.add('Erro de conexão: $error');
          _isConnected = false;
          _scheduleReconnect(deviceId);
        },
      );

      return true;
    } catch (e) {
      _statusController.add('Erro ao conectar: $e');
      return false;
    }
  }

  /// Agenda reconexão automática
  void _scheduleReconnect(String deviceId) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _statusController.add('Máximo de tentativas de reconexão atingido');
      return;
    }

    _reconnectAttempts++;
    _statusController.add('Tentando reconectar em ${_reconnectDelay.inSeconds}s... (${_reconnectAttempts}/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isConnected) {
        connectToDevice(deviceId);
      }
    });
  }

  /// Inicia notificações (subscribe)
  Future<void> _startNotifications(String deviceId) async {
    try {
      _notifySub?.cancel();
      
      _notifySub = _ble.subscribeToCharacteristic(
        QualifiedCharacteristic(
          serviceId: serviceUuid,
          characteristicId: charUuid,
          deviceId: deviceId,
        ),
      ).listen(
        (data) async {
          try {
            final reading = await _parseReading(data, deviceId);
            if (reading != null && reading.isValid) {
              _readingController.add(reading);
            }
          } catch (e) {
            _statusController.add('Erro ao processar leitura: $e');
          }
        },
        onError: (error) {
          _statusController.add('Erro nas notificações: $error');
        },
      );

      _statusController.add('Notificações iniciadas');
    } catch (e) {
      _statusController.add('Erro ao iniciar notificações: $e');
    }
  }

  /// Parse dos bytes conforme protocolo do fabricante
  Future<PenetrometroReading?> _parseReading(List<int> data, String deviceId) async {
    try {
      // EXEMPLO: suponha que o dispositivo envia string ASCII: "DEP:12.3;MPA:2.45"
      final s = utf8.decode(data);
      
      // Proteção básica
      if (!s.contains('MPA') && !s.contains('DEP')) {
        return null;
      }

      final parts = s.split(';');
      double profundidade = 0;
      double resistencia = 0;

      for (var part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('DEP:')) {
          profundidade = double.tryParse(trimmed.substring(4)) ?? 0;
        } else if (trimmed.startsWith('MPA:')) {
          resistencia = double.tryParse(trimmed.substring(4)) ?? 0;
        }
      }

      // Validação básica
      if (profundidade <= 0 || resistencia < 0) {
        return null;
      }

      // Pega GPS atual
      final position = await _getCurrentPositionSafe();
      if (position == null) {
        _statusController.add('GPS indisponível - usando coordenadas padrão');
        // Pode usar coordenadas padrão ou última posição conhecida
      }

      return PenetrometroReading.fromBluetooth(
        profundidadeCm: profundidade,
        resistenciaMpa: resistencia,
        deviceId: deviceId,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
      );
    } catch (e) {
      _statusController.add('Erro no parse: $e');
      return null;
    }
  }

  /// Parse para dados binários (caso o dispositivo use formato binário)
  Future<PenetrometroReading?> _parseBinaryReading(List<int> data, String deviceId) async {
    try {
      if (data.length < 8) return null; // Mínimo 8 bytes

      final byteData = ByteData.sublistView(Uint8List.fromList(data));
      
      // Exemplo: 4 bytes para profundidade (float32) + 4 bytes para resistência (float32)
      final profundidade = byteData.getFloat32(0, Endian.little);
      final resistencia = byteData.getFloat32(4, Endian.little);

      if (profundidade <= 0 || resistencia < 0) return null;

      final position = await _getCurrentPositionSafe();
      
      return PenetrometroReading.fromBluetooth(
        profundidadeCm: profundidade,
        resistenciaMpa: resistencia,
        deviceId: deviceId,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
      );
    } catch (e) {
      _statusController.add('Erro no parse binário: $e');
      return null;
    }
  }

  /// Pega posição GPS com timeout e fallback
  Future<Position?> _getCurrentPositionSafe({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: timeout,
      );
    } catch (e) {
      _statusController.add('Erro GPS: $e');
      return null;
    }
  }

  /// Desconecta do dispositivo
  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      await _notifySub?.cancel();
      await _connection?.cancel();
      
      _isConnected = false;
      _connectedDevice = null;
      _statusController.add('Desconectado');
    } catch (e) {
      _statusController.add('Erro ao desconectar: $e');
    }
  }

  /// Limpa recursos
  void dispose() {
    _reconnectTimer?.cancel();
    _scanSub?.cancel();
    _notifySub?.cancel();
    _connection?.cancel();
    _statusSub?.cancel();
    
    _readingController.close();
    _statusController.close();
    _deviceController.close();
  }

  /// Método para testar com dados simulados (desenvolvimento)
  void simularLeitura() {
    final reading = PenetrometroReading.fromBluetooth(
      profundidadeCm: 20.0 + (DateTime.now().millisecond % 20),
      resistenciaMpa: 1.0 + (DateTime.now().millisecond % 30) / 10,
      deviceId: 'SIMULADO',
      latitude: -23.5505,
      longitude: -46.6333,
    );
    
    _readingController.add(reading);
  }
}
