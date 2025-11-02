import 'package:latlong2/latlong.dart';
import 'env_config.dart';

/// Configuração do MapTiler
class MapTilerConfig {
  // Chave da API carregada de forma segura
  static String get apiKey => EnvConfig.mapTilerApiKey;
  
  // URLs dos tiles (geradas dinamicamente)
  static String get satelliteUrl => '${EnvConfig.mapTilerBaseUrl}/tiles/satellite-v2/{z}/{x}/{y}.jpg?key=$apiKey';
  static String get streetUrl => '${EnvConfig.mapTilerBaseUrl}/tiles/streets-v2/{z}/{x}/{y}.png?key=$apiKey';
  static String get terrainUrl => '${EnvConfig.mapTilerBaseUrl}/tiles/terrain-v2/{z}/{x}/{y}.png?key=$apiKey';
  static String get mapTileUrl => streetUrl; // URL padrão para mapas
  
  // Configurações padrão
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;
  
  // Coordenadas padrão (serão definidas dinamicamente pela localização GPS)
  static double defaultLat = -23.5505; // Fallback para São Paulo se GPS não disponível
  static double defaultLng = -46.6333; // Fallback para São Paulo se GPS não disponível
  
  /// Define as coordenadas padrão baseadas na localização atual do dispositivo
  static void setDefaultLocation(double latitude, double longitude) {
    defaultLat = latitude;
    defaultLng = longitude;
  }
  
  /// Obtém as coordenadas padrão atuais
  static LatLng get defaultLocation => LatLng(defaultLat, defaultLng);
}
