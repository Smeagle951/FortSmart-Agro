import '../config/env_config.dart';

/// Configuração centralizada de APIs do projeto
class APIConfig {
  // MapTiler API Configuration (carregada de forma segura)
  static String get mapTilerAPIKey => EnvConfig.mapTilerApiKey;
  static String get mapTilerBaseUrl => EnvConfig.mapTilerBaseUrl;
  
  // MapTiler Map Types URLs (geradas dinamicamente)
  static Map<String, String> get mapTilerUrls => {
    'satellite': '$mapTilerBaseUrl/tiles/satellite-v2/{z}/{x}/{y}.jpg?key=$mapTilerAPIKey',
    'streets': '$mapTilerBaseUrl/tiles/streets-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey',
    'outdoors': '$mapTilerBaseUrl/tiles/outdoor-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey',
    'topo': '$mapTilerBaseUrl/tiles/topo-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey',
    'hybrid': '$mapTilerBaseUrl/tiles/hybrid/{z}/{x}/{y}.png?key=$mapTilerAPIKey',
    'basic': '$mapTilerBaseUrl/tiles/basic-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey',
  };
  
  // Fallback URLs
  static const String openStreetMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String arcGISUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  
  // Geocoding API
  static String get mapTilerGeocodingUrl => '${mapTilerBaseUrl}/geocoding/{query}.json?key=$mapTilerAPIKey';
  
  // Directions API
  static String get mapTilerDirectionsUrl => '${mapTilerBaseUrl}/directions/v2/route?key=$mapTilerAPIKey';
  
  // Elevation API
  static String get mapTilerElevationUrl => '${mapTilerBaseUrl}/elevation/{coordinates}?key=$mapTilerAPIKey';
  
  /// Obtém URL do mapa por tipo
  static String getMapTilerUrl(String mapType) {
    return mapTilerUrls[mapType] ?? mapTilerUrls['satellite']!;
  }
  
  /// Obtém tipos de mapa disponíveis
  static List<String> getAvailableMapTypes() {
    return mapTilerUrls.keys.toList();
  }
  
  /// Verifica se MapTiler está configurado
  static bool isMapTilerConfigured() {
    return mapTilerAPIKey.isNotEmpty && 
           mapTilerAPIKey != 'KQAa9lY3N0TR17zxhk9u' && 
           mapTilerAPIKey != 'sua_chave_api_aqui';
  }
  
  /// Obtém URL de fallback
  static String getFallbackUrl() {
    // Usar OpenStreetMap como fallback
    return openStreetMapUrl;
  }
}
