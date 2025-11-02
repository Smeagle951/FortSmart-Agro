import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

/// Serviço para obter e gerenciar informações de localização
class LocationService {
  /// Verifica e solicita permissões de localização
  static Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Serviços de localização desabilitados');
      return false;
    }

    // Verificar permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permissões de localização negadas');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permissões de localização negadas permanentemente');
      return false;
    }

    return true;
  }

  /// Obtém a localização atual do usuário
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await _checkPermissions();
      
      if (!hasPermission) {
        return null;
      }
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return null;
    }
  }

  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(
    double startLatitude, 
    double startLongitude, 
    double endLatitude, 
    double endLongitude
  ) {
    return Geolocator.distanceBetween(
      startLatitude, 
      startLongitude, 
      endLatitude, 
      endLongitude
    );
  }

  static getCurrentPosition() {}
}
