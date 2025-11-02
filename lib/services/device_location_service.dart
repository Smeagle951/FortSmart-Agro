import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../config/maptiler_config.dart';
import '../utils/logger.dart';

/// Serviço para obter a localização real do dispositivo
class DeviceLocationService {
  static DeviceLocationService? _instance;
  static DeviceLocationService get instance => _instance ??= DeviceLocationService._();
  
  DeviceLocationService._();
  
  LatLng? _currentLocation;
  bool _isLocationInitialized = false;
  
  /// Obtém a localização atual do dispositivo
  Future<LatLng?> getCurrentLocation() async {
    try {
      Logger.info('📍 Obtendo localização atual do dispositivo...');
      
      // Verificar se o GPS está habilitado
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        Logger.warning('⚠️ Serviço de localização desabilitado');
        return _getFallbackLocation();
      }
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.warning('⚠️ Permissão de localização negada');
          return _getFallbackLocation();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Logger.warning('⚠️ Permissão de localização negada permanentemente');
        return _getFallbackLocation();
      }
      
      // Obter localização atual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      final location = LatLng(position.latitude, position.longitude);
      _currentLocation = location;
      _isLocationInitialized = true;
      
      // Atualizar coordenadas padrão do MapTiler
      MapTilerConfig.setDefaultLocation(position.latitude, position.longitude);
      
      Logger.info('✅ Localização obtida: ${position.latitude}, ${position.longitude}');
      Logger.info('📊 Precisão: ${position.accuracy}m');
      
      return location;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter localização: $e');
      return _getFallbackLocation();
    }
  }
  
  /// Obtém a localização atual (cached ou nova)
  Future<LatLng?> getLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentLocation != null && _isLocationInitialized) {
      return _currentLocation;
    }
    
    return await getCurrentLocation();
  }
  
  /// Obtém localização de fallback (São Paulo)
  LatLng _getFallbackLocation() {
    Logger.info('🔄 Usando localização de fallback (São Paulo)');
    return const LatLng(-23.5505, -46.6333);
  }
  
  /// Verifica se a localização está disponível
  Future<bool> isLocationAvailable() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) return false;
      
      final permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied && 
             permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }
  
  /// Obtém informações detalhadas da localização
  Future<Map<String, dynamic>?> getLocationInfo() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': position.timestamp,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter informações de localização: $e');
      return null;
    }
  }
  
  /// Limpa o cache de localização
  void clearLocationCache() {
    _currentLocation = null;
    _isLocationInitialized = false;
  }
  
  /// Obtém a localização atual (cached)
  LatLng? get cachedLocation => _currentLocation;
  
  /// Verifica se a localização foi inicializada
  bool get isLocationInitialized => _isLocationInitialized;
}
