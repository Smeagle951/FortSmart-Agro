import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Classe para gerenciar o ID único do dispositivo
class DeviceIdManager {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  /// Obtém o ID único do dispositivo
  /// Se não existir, gera um novo ID e o salva
  static Future<String> getDeviceId() async {
    // Se já temos o ID em cache, retorna imediatamente
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    // Se não existe um ID salvo, gera um novo
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint('Novo ID de dispositivo gerado: $deviceId');
    } else {
      debugPrint('ID de dispositivo existente: $deviceId');
    }

    // Salva em cache para acesso rápido
    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Verifica se o ID do dispositivo já foi gerado
  static Future<bool> hasDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_deviceIdKey);
  }

  /// Limpa o ID do dispositivo (uso apenas para testes)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _cachedDeviceId = null;
    debugPrint('ID de dispositivo removido');
  }
}
