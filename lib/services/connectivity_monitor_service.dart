import 'dart:async';
import 'dart:math' as math;

import '../utils/logger.dart';

/// Enum para definir o tipo de conexão
enum ConnectivityResult {
  wifi,
  mobile,
  none
}

/// Enum para definir a qualidade da conexão
enum ConnectionQuality {
  unknown,
  poor,
  fair,
  good,
  excellent
}

/// Enum para definir o tipo de conexão
enum ConnectionType {
  none,
  wifi,
  mobile,
  other
}

/// Enum para definir o status de conectividade
enum ConnectivityStatus {
  connected,
  disconnected
}

/// Classe para representar detalhes completos do status da conectividade
class ConnectivityStatusDetails {
  final ConnectivityResult connectivityResult;
  final ConnectivityStatus status;
  final ConnectionType connectionType;
  final ConnectionQuality connectionQuality;
  final String? wifiName;
  final String? wifiBSSID;
  final bool isMetered;
  final int changeCount;
  final DateTime? lastChange;

  ConnectivityStatusDetails({
    required this.connectivityResult,
    required this.status,
    required this.connectionType,
    required this.connectionQuality,
    this.wifiName,
    this.wifiBSSID,
    required this.isMetered,
    required this.changeCount,
    this.lastChange,
  });

  /// Converte o status para um mapa
  Map<String, dynamic> toMap() {
    return {
      'connectivityResult': connectivityResult.toString(),
      'status': status.toString(),
      'connectionType': connectionType.toString(),
      'connectionQuality': connectionQuality.toString(),
      'wifiName': wifiName,
      'wifiBSSID': wifiBSSID,
      'isMetered': isMetered,
      'changeCount': changeCount,
      'lastChange': lastChange?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ConnectivityStatusDetails: ${toMap().entries.map((e) => '${e.key}=${e.value}').join(', ')}';
  }
}

/// Serviço responsável pelo monitoramento de conectividade
class ConnectivityMonitorService {
  static final ConnectivityMonitorService _instance = ConnectivityMonitorService._internal();
  
  Timer? _connectivityTimer;
  ConnectivityResult _lastConnectivityResult = ConnectivityResult.wifi; // Assumindo conexão por padrão
  String? _wifiName = "WiFi";
  String? _wifiBSSID = "00:00:00:00:00:00";
  bool _isMetered = false;
  int _connectionChangeCount = 0;
  DateTime? _lastConnectionChange;
  ConnectionQuality _lastConnectionQuality = ConnectionQuality.unknown;
  
  // Stream para notificar sobre mudanças na conectividade
  final _connectivityController = StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get connectivityStream => _connectivityController.stream;
  
  // Stream para notificar sobre qualidade da conexão
  final _connectionQualityController = StreamController<ConnectionQuality>.broadcast();
  Stream<ConnectionQuality> get connectionQualityStream => _connectionQualityController.stream;
  
  // Singleton pattern
  factory ConnectivityMonitorService() {
    return _instance;
  }
  
  ConnectivityMonitorService._internal();
  
  /// Inicializa o serviço de monitoramento
  Future<void> initialize() async {
    try {
      // Simular conectividade inicial
      await _checkConnectivity();
      
      // Simular monitoramento de mudanças com timer
      _connectivityTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
        // Simular mudanças aleatórias de conectividade para testes
        final random = DateTime.now().millisecond % 10;
        if (random < 8) {
          // 80% do tempo estará no WiFi
          _handleConnectivityChange(ConnectivityResult.wifi);
        } else if (random < 9) {
          // 10% do tempo estará no mobile
          _handleConnectivityChange(ConnectivityResult.mobile);
        } else {
          // 10% do tempo estará sem conexão
          _handleConnectivityChange(ConnectivityResult.none);
        }
      });
      
      Logger.info('Serviço de monitoramento de conectividade inicializado (modo simulado)');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de monitoramento: $e');
    }
  }
  
  /// Verifica o estado atual da conectividade (simulado)
  Future<void> _checkConnectivity() async {
    try {
      // Simular uma verificação de conectividade
      // Assumir WiFi na maioria das vezes para simplificar
      final random = DateTime.now().millisecond % 10;
      if (random < 8) {
        _lastConnectivityResult = ConnectivityResult.wifi;
        _wifiName = "WiFi_Home";
        _wifiBSSID = "00:11:22:33:44:55";
        _isMetered = false;
      } else if (random < 9) {
        _lastConnectivityResult = ConnectivityResult.mobile;
        _wifiName = null;
        _wifiBSSID = null;
        _isMetered = true;
      } else {
        _lastConnectivityResult = ConnectivityResult.none;
        _wifiName = null;
        _wifiBSSID = null;
        _isMetered = false;
      }
      
      // Notificar sobre o estado atual
      _notifyConnectivityStatus();
      
      Logger.info('Conectividade verificada (simulada): ${_lastConnectivityResult.toString()}');
    } catch (e) {
      Logger.error('Erro ao verificar conectividade: $e');
    }
  }
  
  /// Manipula mudanças na conectividade
  void _handleConnectivityChange(ConnectivityResult result) {
    // Registrar mudança de conectividade
    _connectionChangeCount++;
    _lastConnectionChange = DateTime.now();
    
    // Atualizar resultado atual
    _lastConnectivityResult = result;
    
    // Verificar informações adicionais se conectado via WiFi
    if (result == ConnectivityResult.wifi) {
      _wifiName = "WiFi_Home";
      _wifiBSSID = "00:11:22:33:44:55";
      _isMetered = false;
    } else if (result == ConnectivityResult.mobile) {
      _wifiName = null;
      _wifiBSSID = null;
      _isMetered = true;
    } else {
      _wifiName = null;
      _wifiBSSID = null;
      _isMetered = false;
    }
    
    // Notificar sobre o estado atual
    _notifyConnectivityStatus();
    
    Logger.info('Conectividade alterada para: ${result.toString()}');
  }
  
  /// Notifica sobre o estado atual de conectividade
  void _notifyConnectivityStatus() {
    ConnectivityStatus status;
    
    switch (_lastConnectivityResult) {
      case ConnectivityResult.wifi:
        status = ConnectivityStatus.connected;
        break;
      case ConnectivityResult.mobile:
        status = ConnectivityStatus.connected;
        break;
      case ConnectivityResult.none:
        status = ConnectivityStatus.disconnected;
        break;
    }
    
    // Enviar notificação via stream
    _connectivityController.add(status);
    
    Logger.info('Status de conectividade notificado: $status');
  }
  
  /// Verifica se o dispositivo está online
  bool isOnline() {
    return _lastConnectivityResult != ConnectivityResult.none;
  }

  /// Obtém o nome do tipo de conexão
  String getConnectionTypeName() {
    switch (_lastConnectivityResult) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Dados Móveis';
      case ConnectivityResult.none:
      default:
        return 'Sem conexão';
    }
  }

  /// Obtém o nome da rede WiFi atual
  String? getWifiName() {
    return _wifiName;
  }

  /// Obtém o BSSID da rede WiFi atual
  String? getWifiBSSID() {
    return _wifiBSSID;
  }

  /// Verifica se a conexão atual é tarifada
  bool isConnectionMetered() {
    return _isMetered;
  }
  
  /// Obtém a qualidade da conexão (simulada)
  ConnectionQuality getConnectionQuality() {
    // Simular uma qualidade de conexão baseada no tipo
    if (_lastConnectivityResult == ConnectivityResult.none) {
      return ConnectionQuality.unknown;
    } else if (_lastConnectivityResult == ConnectivityResult.wifi) {
      // Para WiFi, simular conexão excelente na maioria das vezes
      final random = DateTime.now().millisecond % 10;
      if (random < 7) {
        return ConnectionQuality.excellent;
      } else if (random < 9) {
        return ConnectionQuality.good;
      } else {
        return ConnectionQuality.fair;
      }
    } else if (_lastConnectivityResult == ConnectivityResult.mobile) {
      // Para mobile, simular conexão boa na maioria das vezes
      final random = DateTime.now().millisecond % 10;
      if (random < 5) {
        return ConnectionQuality.good;
      } else if (random < 8) {
        return ConnectionQuality.fair;
      } else {
        return ConnectionQuality.poor;
      }
    }
    
    return ConnectionQuality.unknown;
  }
  
  /// Obtém o tipo de conexão atual
  ConnectionType getConnectionType() {
    switch (_lastConnectivityResult) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.none:
        return ConnectionType.none;
      default:
        return ConnectionType.other;
    }
  }
  
  /// Obtém o número de mudanças de conectividade
  int getConnectionChangeCount() {
    return _connectionChangeCount;
  }
  
  /// Obtém a data/hora da última mudança de conectividade
  DateTime? getLastConnectionChangeTime() {
    return _lastConnectionChange;
  }
  
  /// Método para verificar conectividade externamente
  Future<ConnectivityResult> checkConnectivity() async {
    await _checkConnectivity();
    return _lastConnectivityResult;
  }
  
  /// Verifica se a conexão atual é adequada para sincronização
  bool isSuitableForSync({bool requireWifi = false, bool avoidMetered = true}) {
    // Verificar se há conexão
    if (_lastConnectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    // Verificar se exige WiFi
    if (requireWifi && _lastConnectivityResult != ConnectivityResult.wifi) {
      return false;
    }
    
    // Verificar se deve evitar conexões tarifadas
    if (avoidMetered && _isMetered) {
      return false;
    }
    
    // Verificar qualidade da conexão
    final quality = getConnectionQuality();
    return quality != ConnectionQuality.poor;
  }
  
  /// Verifica se a conexão atual é adequada para upload de fotos
  bool isSuitableForPhotoUpload() {
    // Para upload de fotos, requer WiFi e boa qualidade de conexão
    return isSuitableForSync(requireWifi: true, avoidMetered: true) && 
           getConnectionQuality() == ConnectionQuality.excellent;
  }
  
  /// Encerra o serviço de monitoramento
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
    _connectionQualityController.close();
    Logger.info('Serviço de monitoramento de conectividade encerrado');
  }
}
