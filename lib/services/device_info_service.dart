import 'dart:io';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import '../utils/logger.dart';

/// Serviço para obter informações sobre o dispositivo e o aplicativo
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  
  bool _initialized = false;
  
  // Singleton pattern
  factory DeviceInfoService() {
    return _instance;
  }
  
  DeviceInfoService._internal();
  
  // Informações do aplicativo
  String _appName = 'FortSmartAgro';
  String _packageName = 'com.fortsmartagro.app';
  String _version = '1.0.0';
  String _buildNumber = '1';
  
  // Informações do dispositivo
  final Map<String, dynamic> _deviceData = {};
  
  /// Inicializa o serviço de informações do dispositivo
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      Logger.log('Inicializando serviço de informações do dispositivo...');
      
      // Comentado temporariamente
      /*
      // Obter informações do pacote
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      
      // Obter informações do dispositivo
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        _deviceData['model'] = androidInfo.model;
        _deviceData['brand'] = androidInfo.brand;
        _deviceData['androidVersion'] = androidInfo.version.release;
        _deviceData['sdkInt'] = androidInfo.version.sdkInt;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        _deviceData['model'] = iosInfo.model;
        _deviceData['systemName'] = iosInfo.systemName;
        _deviceData['systemVersion'] = iosInfo.systemVersion;
        _deviceData['name'] = iosInfo.name;
      }
      */
      
      // Adicionar informações básicas do dispositivo
      _deviceData['platform'] = Platform.operatingSystem;
      _deviceData['platformVersion'] = Platform.operatingSystemVersion;
      
      _initialized = true;
      Logger.log('Serviço de informações do dispositivo inicializado com sucesso');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de informações do dispositivo: $e');
    }
  }
  
  /// Retorna o nome do aplicativo
  String get appName => _appName;
  
  /// Retorna o nome do pacote do aplicativo
  String get packageName => _packageName;
  
  /// Retorna a versão do aplicativo
  String get version => _version;
  
  /// Retorna o número da build do aplicativo
  String get buildNumber => _buildNumber;
  
  /// Retorna a versão completa do aplicativo (versão + build)
  String get fullVersion => '$_version+$_buildNumber';
  
  /// Retorna o sistema operacional do dispositivo
  String get operatingSystem => Platform.operatingSystem;
  
  /// Retorna a versão do sistema operacional do dispositivo
  String get operatingSystemVersion => Platform.operatingSystemVersion;
  
  /// Retorna o modelo do dispositivo (simplificado)
  String get deviceModel {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return Platform.operatingSystem;
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }
  
  /// Retorna informações sobre o aplicativo
  Map<String, String> getAppInfo() {
    return {
      'appName': appName,
      'packageName': packageName,
      'version': version,
      'buildNumber': buildNumber,
    };
  }
  
  /// Retorna informações básicas do dispositivo como mapa
  Map<String, dynamic> getDeviceInfo() {
    return {
      'model': deviceModel,
      'os': operatingSystem,
      'osVersion': operatingSystemVersion,
    };
  }
  
  /// Retorna todas as informações do dispositivo e aplicativo
  Map<String, dynamic> getFullDeviceInfo() {
    if (!_initialized) {
      initialize();
    }
    
    return {
      'app': getAppInfo(),
      'device': getDeviceInfo(),
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
