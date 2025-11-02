import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationHelper {
  /// Verifica e solicita permissões de localização
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Verifica as permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
  
  /// Obtém a localização atual do dispositivo
  Future<Position?> getCurrentLocation() async {
    try {
      // Verificar permissões primeiro
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }
      
      // Obter a posição atual com alta precisão
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return null;
    }
  }
  
  /// Método estático para obter a posição atual
  static Future<Position?> getCurrentPosition() async {
    try {
      // Verificar se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      // Obter a posição atual
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Erro ao obter posição atual: $e');
      return null;
    }
  }
  
  /// Alias para getCurrentPosition para compatibilidade com código existente
  static Future<Position> getCurrentLocationAlias() async {
    return getCurrentPosition() as Position;
  }

  /// Calcula a distância entre duas coordenadas em metros
  static double calculateDistance(
    double startLatitude, 
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Exibe um diálogo solicitando permissão de localização
  static Future<bool> showLocationPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissão de Localização'),
          content: const Text(
            'Para adicionar pontos de monitoramento, precisamos acessar sua localização. '
            'Por favor, conceda permissão quando solicitado.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Continuar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Verifica se a localização está dentro de um raio específico
  static bool isLocationWithinRadius({
    required double centerLatitude,
    required double centerLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(
      centerLatitude,
      centerLongitude,
      targetLatitude,
      targetLongitude,
    );
    
    return distance <= radiusInMeters;
  }
  
  /// Formata coordenadas para exibição
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
