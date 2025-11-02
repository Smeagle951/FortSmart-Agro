import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/penetrometro_reading_model.dart';
import '../models/penetrometro_device_model.dart';
import 'bluetooth_permission_service.dart';

/// Serviço avançado para comunicação Bluetooth com múltiplos tipos de penetrômetros
class PenetrometroBluetoothAdvancedService {
  final FlutterReactiveBle _ble;
  PenetrometroDeviceModel? _dispositivoAtual;

  // Streams
  final StreamController<PenetrometroReading> _readingController = 
      StreamController<PenetrometroReading>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
  final StreamController<DiscoveredDevice> _deviceController = 
      StreamController<DiscoveredDevice>.broadcast();
  final StreamController<List<PenetrometroDeviceModel>> _supportedDevicesController = 
      StreamController<List<PenetrometroDeviceModel>>.broadcast();

  // Estado
  DiscoveredDevice? _connectedDevice;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<BleStatus>? _statusSub;
  
  bool _isScanning = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  // Configurações
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;

  PenetrometroBluetoothAdvancedService() : _ble = FlutterReactiveBle();

  // Getters
  Stream<PenetrometroReading> get readingStream => _readingController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<DiscoveredDevice> get deviceStream => _deviceController.stream;
  Stream<List<PenetrometroDeviceModel>> get supportedDevicesStream => _supportedDevicesController.stream;
  
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  BleStatus get status => _ble.status;
  PenetrometroDeviceModel? get dispositivoAtual => _dispositivoAtual;

  /// Inicializa o serviço
  Future<void> inicializar() async {
    try {
      // Verifica prontidão do Bluetooth usando serviço nativo
      final readiness = await BluetoothPermissionService.checkBluetoothReadiness();
      
      if (!readiness['isReady']) {
        _statusController.add('Bluetooth não está pronto: ${readiness['issues'].join(', ')}');
        
        // Tenta corrigir problemas automaticamente
        if (readiness['hasPermissions'] != true) {
          await BluetoothPermissionService.ensurePermissions();
        }
        
        if (readiness['isEnabled'] != true) {
          await BluetoothPermissionService.ensureBluetoothEnabled();
        }
        
        // Verifica novamente após tentativas de correção
        final newReadiness = await BluetoothPermissionService.checkBluetoothReadiness();
        if (!newReadiness['isReady']) {
          _statusController.add('Não foi possível preparar o Bluetooth: ${newReadiness['issues'].join(', ')}');
          return;
        }
      }
      
      // Monitora status do Bluetooth
      _statusSub = _ble.statusStream.listen((status) {
        _statusController.add('Status Bluetooth: ${_statusToString(status)}');
        
        if (status == BleStatus.ready && _isConnected) {
          _reconectar();
        }
      });

      // Emite lista de dispositivos suportados
      _supportedDevicesController.add(PenetrometroDeviceModel.dispositivosSuportados);
      
      _statusController.add('Serviço inicializado - Bluetooth pronto');
    } catch (e) {
      _statusController.add('Erro ao inicializar: $e');
    }
  }

  /// Verifica permissões necessárias (usando serviço nativo)
  Future<void> _verificarPermissoes() async {
    final hasPermissions = await BluetoothPermissionService.hasAllPermissions();
    if (!hasPermissions) {
      throw Exception('Permissões Bluetooth não concedidas');
    }
  }

  /// Escaneia dispositivos disponíveis
  Future<void> escanearDispositivos() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _statusController.add('Escaneando dispositivos...');

      _scanSub = _ble.scanForDevices(
        withServices: [], // Escaneia todos os dispositivos
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true,
      ).listen(
        (device) {
          _deviceController.add(device);
          _verificarDispositivoSuportado(device);
        },
        onError: (error) {
          _statusController.add('Erro no scan: $error');
        },
      );

      // Para o scan após 30 segundos
      Timer(const Duration(seconds: 30), () {
        pararScan();
      });

    } catch (e) {
      _isScanning = false;
      _statusController.add('Erro ao iniciar scan: $e');
    }
  }

  /// Obtém dispositivos Bluetooth pareados
  Future<List<DiscoveredDevice>> obterDispositivosPareados() async {
    try {
      // Em uma implementação real, você usaria o BluetoothAdapter.getBondedDevices()
      // Por enquanto, retorna uma lista vazia
      return [];
    } catch (e) {
      print('Erro ao obter dispositivos pareados: $e');
      return [];
    }
  }

  /// Verifica se um dispositivo está pareado
  Future<bool> isDispositivoPareado(String deviceId) async {
    try {
      final pareados = await obterDispositivosPareados();
      return pareados.any((device) => device.id == deviceId);
    } catch (e) {
      print('Erro ao verificar se dispositivo está pareado: $e');
      return false;
    }
  }

  /// Para o scan de dispositivos
  void pararScan() {
    _scanSub?.cancel();
    _isScanning = false;
    _statusController.add('Scan finalizado');
  }

  /// Verifica se o dispositivo é suportado
  void _verificarDispositivoSuportado(DiscoveredDevice device) {
    for (final supportedDevice in PenetrometroDeviceModel.dispositivosSuportados) {
      if (device.name.toLowerCase().contains(supportedDevice.nome.toLowerCase()) ||
          device.name.toLowerCase().contains(supportedDevice.fabricante.toLowerCase())) {
        _statusController.add('Dispositivo suportado encontrado: ${device.name}');
        break;
      }
    }
  }

  /// Conecta a um dispositivo específico
  Future<bool> conectarDispositivo(
    DiscoveredDevice device, 
    PenetrometroDeviceModel dispositivo,
  ) async {
    try {
      _dispositivoAtual = dispositivo;
      _statusController.add('Conectando a ${device.name}...');

      _connection = _ble.connectToDevice(
        id: device.id,
        connectionTimeout: _connectionTimeout,
      ).listen(
        (connectionState) {
          _statusController.add('Estado da conexão: ${_connectionStateToString(connectionState.connectionState)}');
          
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            _isConnected = true;
            _connectedDevice = device;
            _reconnectAttempts = 0;
            _iniciarNotificacoes();
          } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
            _isConnected = false;
            _pararNotificacoes();
            _reconectar();
          }
        },
        onError: (error) {
          _statusController.add('Erro na conexão: $error');
          _isConnected = false;
        },
      );

      return true;
    } catch (e) {
      _statusController.add('Erro ao conectar: $e');
      return false;
    }
  }

  /// Inicia as notificações do dispositivo
  void _iniciarNotificacoes() {
    if (_dispositivoAtual == null) return;

    try {
      _notifySub = _ble.subscribeToCharacteristic(
        QualifiedCharacteristic(
          serviceId: Uuid.parse(_dispositivoAtual!.serviceUuid),
          characteristicId: Uuid.parse(_dispositivoAtual!.characteristicUuid),
          deviceId: _connectedDevice!.id,
        ),
      ).listen(
        (data) => _processarDados(data),
        onError: (error) {
          _statusController.add('Erro nas notificações: $error');
        },
      );

      _statusController.add('Notificações iniciadas');
    } catch (e) {
      _statusController.add('Erro ao iniciar notificações: $e');
    }
  }

  /// Para as notificações
  void _pararNotificacoes() {
    _notifySub?.cancel();
    _notifySub = null;
  }

  /// Processa os dados recebidos do dispositivo
  void _processarDados(List<int> data) {
    _parsearDados(data).then((reading) {
      if (reading != null) {
        _readingController.add(reading);
      }
    }).catchError((e) {
      _statusController.add('Erro ao processar dados: $e');
    });
  }

  /// Parseia os dados recebidos baseado no protocolo do dispositivo
  Future<PenetrometroReading?> _parsearDados(List<int> data) async {
    if (_dispositivoAtual == null) return null;

    try {
      final config = _dispositivoAtual!.configuracoes;
      final endianness = config['endianness'] == 'big' ? Endian.big : Endian.little;
      
      double penetrometria = 0.0;
      double? temperatura;
      double? umidade;
      double? profundidade;

      // Parseia baseado no formato de dados
      switch (config['formato_dados']) {
        case 'float32':
          final bytes = Uint8List.fromList(data);
          final byteData = ByteData.sublistView(bytes);
          penetrometria = byteData.getFloat32(0, endianness);
          break;
          
        case 'float16':
          final bytes = Uint8List.fromList(data);
          final byteData = ByteData.sublistView(bytes);
          penetrometria = byteData.getFloat32(0, endianness) / 1000.0; // Conversão
          break;
          
        case 'uint16':
          final bytes = Uint8List.fromList(data);
          final byteData = ByteData.sublistView(bytes);
          penetrometria = byteData.getUint16(0, endianness) / 1000.0; // Conversão
          break;
          
        default:
          // Tenta parsear como string JSON
          final jsonString = String.fromCharCodes(data);
          final jsonData = jsonDecode(jsonString);
          penetrometria = (jsonData['penetrometria'] ?? 0.0).toDouble();
          temperatura = jsonData['temperatura']?.toDouble();
          umidade = jsonData['umidade']?.toDouble();
          profundidade = jsonData['profundidade']?.toDouble();
          break;
      }

      // Aplica precisão
      final precisao = (config['precisao'] ?? 0.01).toDouble();
      penetrometria = ((penetrometria / precisao).round() * precisao).toDouble();

      // Valida range
      final rangeMin = config['range_min'] ?? 0.0;
      final rangeMax = config['range_max'] ?? 10.0;
      if (penetrometria < rangeMin || penetrometria > rangeMax) {
        return null; // Dados inválidos
      }

      // Obtém posição GPS
      final posicao = await _obterPosicaoAtual();

      return PenetrometroReading.fromBluetooth(
        profundidadeCm: profundidade ?? 20.0,
        resistenciaMpa: penetrometria,
        deviceId: _dispositivoAtual!.id,
        latitude: posicao?.latitude ?? 0.0,
        longitude: posicao?.longitude ?? 0.0,
        observacoes: 'Leitura automática via Bluetooth - ${_dispositivoAtual!.nome}',
      );

    } catch (e) {
      print('Erro ao parsear dados: $e');
      return null;
    }
  }

  /// Obtém posição GPS atual
  Future<Position?> _obterPosicaoAtual() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Reconecta automaticamente
  void _reconectar() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _statusController.add('Máximo de tentativas de reconexão atingido');
      return;
    }

    if (_connectedDevice != null && _dispositivoAtual != null) {
      _reconnectAttempts++;
      _statusController.add('Tentativa de reconexão $_reconnectAttempts/$_maxReconnectAttempts');
      
      _reconnectTimer = Timer(_reconnectDelay, () {
        conectarDispositivo(_connectedDevice!, _dispositivoAtual!);
      });
    }
  }

  /// Desconecta do dispositivo
  Future<void> desconectar() async {
    try {
      _connection?.cancel();
      _pararNotificacoes();
      _reconnectTimer?.cancel();
      
      _isConnected = false;
      _connectedDevice = null;
      _dispositivoAtual = null;
      _reconnectAttempts = 0;
      
      _statusController.add('Dispositivo desconectado');
    } catch (e) {
      _statusController.add('Erro ao desconectar: $e');
    }
  }

  /// Limpa recursos
  void dispose() {
    _connection?.cancel();
    _notifySub?.cancel();
    _scanSub?.cancel();
    _statusSub?.cancel();
    _reconnectTimer?.cancel();
    
    _readingController.close();
    _statusController.close();
    _deviceController.close();
    _supportedDevicesController.close();
  }

  // Métodos auxiliares
  String _statusToString(BleStatus status) {
    switch (status) {
      case BleStatus.unknown:
        return 'Desconhecido';
      case BleStatus.unsupported:
        return 'Não suportado';
      case BleStatus.unauthorized:
        return 'Não autorizado';
      case BleStatus.poweredOff:
        return 'Desligado';
      case BleStatus.locationServicesDisabled:
        return 'Localização desabilitada';
      case BleStatus.ready:
        return 'Pronto';
    }
  }

  String _connectionStateToString(DeviceConnectionState state) {
    switch (state) {
      case DeviceConnectionState.disconnected:
        return 'Desconectado';
      case DeviceConnectionState.connecting:
        return 'Conectando';
      case DeviceConnectionState.connected:
        return 'Conectado';
      case DeviceConnectionState.disconnecting:
        return 'Desconectando';
    }
  }
}
