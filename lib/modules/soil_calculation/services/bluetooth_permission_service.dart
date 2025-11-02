import 'package:flutter/services.dart';

/// Serviço para gerenciar permissões Bluetooth nativas do Android
class BluetoothPermissionService {
  static const MethodChannel _channel = MethodChannel('bluetooth_permission');

  /// Verifica se todas as permissões Bluetooth estão concedidas
  static Future<bool> hasAllPermissions() async {
    try {
      final bool hasPermissions = await _channel.invokeMethod('hasAllPermissions');
      return hasPermissions;
    } catch (e) {
      print('Erro ao verificar permissões Bluetooth: $e');
      return false;
    }
  }

  /// Solicita permissões Bluetooth necessárias
  static Future<void> requestPermissions() async {
    try {
      await _channel.invokeMethod('requestPermissions');
    } catch (e) {
      print('Erro ao solicitar permissões Bluetooth: $e');
    }
  }

  /// Verifica se o Bluetooth está habilitado
  static Future<bool> isBluetoothEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod('isBluetoothEnabled');
      return isEnabled;
    } catch (e) {
      print('Erro ao verificar status do Bluetooth: $e');
      return false;
    }
  }

  /// Solicita para habilitar o Bluetooth
  static Future<void> requestEnableBluetooth() async {
    try {
      await _channel.invokeMethod('requestEnableBluetooth');
    } catch (e) {
      print('Erro ao solicitar habilitação do Bluetooth: $e');
    }
  }

  /// Verifica se o dispositivo suporta Bluetooth Low Energy
  static Future<bool> supportsBluetoothLE() async {
    try {
      final bool supportsLE = await _channel.invokeMethod('supportsBluetoothLE');
      return supportsLE;
    } catch (e) {
      print('Erro ao verificar suporte BLE: $e');
      return false;
    }
  }

  /// Verifica se o dispositivo suporta Bluetooth
  static Future<bool> supportsBluetooth() async {
    try {
      final bool supports = await _channel.invokeMethod('supportsBluetooth');
      return supports;
    } catch (e) {
      print('Erro ao verificar suporte Bluetooth: $e');
      return false;
    }
  }

  /// Obtém informações completas do dispositivo Bluetooth
  static Future<Map<String, dynamic>> getBluetoothInfo() async {
    try {
      final Map<dynamic, dynamic> info = await _channel.invokeMethod('getBluetoothInfo');
      return Map<String, dynamic>.from(info);
    } catch (e) {
      print('Erro ao obter informações Bluetooth: $e');
      return {};
    }
  }

  /// Obtém dispositivos Bluetooth pareados
  static Future<List<Map<String, dynamic>>> getPairedDevices() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod('getPairedDevices');
      return devices.map((device) => Map<String, dynamic>.from(device)).toList();
    } catch (e) {
      print('Erro ao obter dispositivos pareados: $e');
      return [];
    }
  }

  /// Verifica e solicita permissões se necessário
  static Future<bool> ensurePermissions() async {
    try {
      // Verifica se já tem permissões
      final hasPermissions = await hasAllPermissions();
      if (hasPermissions) {
        return true;
      }

      // Solicita permissões
      await requestPermissions();
      
      // Aguarda um pouco e verifica novamente
      await Future.delayed(const Duration(seconds: 1));
      return await hasAllPermissions();
    } catch (e) {
      print('Erro ao garantir permissões: $e');
      return false;
    }
  }

  /// Verifica e habilita Bluetooth se necessário
  static Future<bool> ensureBluetoothEnabled() async {
    try {
      // Verifica se Bluetooth está habilitado
      final isEnabled = await isBluetoothEnabled();
      if (isEnabled) {
        return true;
      }

      // Solicita para habilitar
      await requestEnableBluetooth();
      
      // Aguarda um pouco e verifica novamente
      await Future.delayed(const Duration(seconds: 2));
      return await isBluetoothEnabled();
    } catch (e) {
      print('Erro ao garantir Bluetooth habilitado: $e');
      return false;
    }
  }

  /// Verifica se o dispositivo está pronto para usar Bluetooth
  static Future<Map<String, dynamic>> checkBluetoothReadiness() async {
    try {
      final info = await getBluetoothInfo();
      
      return {
        'isReady': info['hasPermissions'] == true && 
                  info['isEnabled'] == true && 
                  info['supportsBluetoothLE'] == true,
        'hasPermissions': info['hasPermissions'] ?? false,
        'isEnabled': info['isEnabled'] ?? false,
        'supportsBluetoothLE': info['supportsBluetoothLE'] ?? false,
        'supportsBluetooth': info['supportsBluetooth'] ?? false,
        'deviceName': info['deviceName'] ?? 'Unknown',
        'deviceAddress': info['deviceAddress'] ?? 'Unknown',
        'androidVersion': info['androidVersion'] ?? 0,
        'issues': _getIssues(info),
      };
    } catch (e) {
      print('Erro ao verificar prontidão Bluetooth: $e');
      return {
        'isReady': false,
        'hasPermissions': false,
        'isEnabled': false,
        'supportsBluetoothLE': false,
        'supportsBluetooth': false,
        'deviceName': 'Unknown',
        'deviceAddress': 'Unknown',
        'androidVersion': 0,
        'issues': ['Erro ao verificar informações do dispositivo'],
      };
    }
  }

  /// Identifica problemas com o Bluetooth
  static List<String> _getIssues(Map<String, dynamic> info) {
    final List<String> issues = [];
    
    if (info['supportsBluetooth'] != true) {
      issues.add('Dispositivo não suporta Bluetooth');
    }
    
    if (info['supportsBluetoothLE'] != true) {
      issues.add('Dispositivo não suporta Bluetooth Low Energy (BLE)');
    }
    
    if (info['hasPermissions'] != true) {
      issues.add('Permissões Bluetooth não concedidas');
    }
    
    if (info['isEnabled'] != true) {
      issues.add('Bluetooth não está habilitado');
    }
    
    return issues;
  }
}
