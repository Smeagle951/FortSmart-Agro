import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:latlong2/latlong.dart' as latlong2;

import '../widgets/error_dialog.dart';

/// Classe utilitária para funções relacionadas à localização
class LocationUtils {
  /// Verifica se o serviço de localização está habilitado
  static Future<bool> checkLocationService(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Serviço de Localização Desativado',
          message: 'Por favor, ative o serviço de localização do dispositivo para usar esta funcionalidade.',
        );
      }
      return false;
    }
    return true;
  }

  /// Solicita permissão de localização (incluindo background se especificado)
  static Future<bool> requestLocationPermission(BuildContext context, {bool requestBackground = false}) async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ErrorDialog.show(
            context,
            title: 'Permissão Negada',
            message: 'É necessário permitir o acesso à localização para usar esta funcionalidade.',
          );
        }
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Permissão Negada Permanentemente',
          message: 'As permissões de localização estão permanentemente negadas. Por favor, habilite-as nas configurações do dispositivo.',
        );
      }
      return false;
    }
    
    // CORREÇÃO: Solicitar permissão de background se necessário
    if (requestBackground && permission != LocationPermission.always) {
      if (context.mounted) {
        // Mostrar diálogo explicativo antes de solicitar permissão sempre
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissão de Localização em Background'),
            content: const Text(
              'Para habilitar o rastreamento GPS em background, o aplicativo precisa de permissão '
              'para acessar sua localização "o tempo todo".\n\n'
              'Isso permitirá que você use recursos como rastreamento de operações agrícolas mesmo '
              'quando o aplicativo estiver em segundo plano.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Não agora'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Permitir'),
              ),
            ],
          ),
        );
        
        if (shouldRequest == true) {
          // No Android 11+, precisa abrir as configurações para o usuário escolher "sempre"
          await Geolocator.openLocationSettings();
          
          // Verificar novamente após voltar das configurações
          await Future.delayed(const Duration(seconds: 2));
          final newPermission = await Geolocator.checkPermission();
          
          if (newPermission != LocationPermission.always && context.mounted) {
            ErrorDialog.show(
              context,
              title: 'Permissão de Background',
              message: 'Para habilitar o rastreamento em background, selecione "Permitir o tempo todo" nas configurações de localização.',
            );
          }
          
          return newPermission == LocationPermission.always;
        }
      }
    }
    
    return true;
  }

  /// Verifica se a permissão de localização em background está concedida
  static Future<bool> hasBackgroundLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Obtém a posição atual do dispositivo
  static Future<latlong2.LatLng?> getCurrentPosition(BuildContext context) async {
    try {
      // Verificar serviço e permissões
      bool serviceEnabled = await checkLocationService(context);
      if (!serviceEnabled) return null;
      
      bool permissionGranted = await requestLocationPermission(context);
      if (!permissionGranted) return null;
      
      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return latlong2.LatLng(position.latitude, position.longitude);
    } catch (e) {
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Erro de Localização',
          message: 'Não foi possível obter a localização atual: $e',
        );
      }
      return null;
    }
  }

  /// Obtém a posição atual do dispositivo sem contexto
  static Future<Position> getCurrentPositionWithoutContext() async {
    // Verificar se o serviço está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado');
    }
    
    // Verificar permissões
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissões de localização permanentemente negadas');
    }
    
    // Obter posição atual
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(latlong2.LatLng point1, latlong2.LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Calcula o centro de um conjunto de pontos
  static latlong2.LatLng calculateCenter(List<latlong2.LatLng> points) {
    if (points.isEmpty) {
      // Retornar um ponto padrão se não houver pontos
      return latlong2.LatLng(-15.7801, -47.9292); // Brasil
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return latlong2.LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }

  /// Calcula os limites de um conjunto de pontos
  static google_maps.LatLngBounds calculateBounds(List<latlong2.LatLng> points) {
    if (points.isEmpty) {
      // Retornar limites padrão se não houver pontos
      return google_maps.LatLngBounds(
        southwest: google_maps.LatLng(-23.6821, -70.5963), // Extremo sudoeste do Brasil
        northeast: google_maps.LatLng(5.2719, -34.7299),   // Extremo nordeste do Brasil
      );
    }
    
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;
    
    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    
    // Usando o LatLngBounds do google_maps para compatibilidade
    return google_maps.LatLngBounds(
      southwest: google_maps.LatLng(minLat, minLng),
      northeast: google_maps.LatLng(maxLat, maxLng),
    );
  }
}
