/// Constantes para MapTiler
class MapTilerConstants {
  // API Key do MapTiler
  static const String apiKey = 'KQAa9lY3N0TR17zxhk9u';
  
  // URLs dos tiles para flutter_map
  static String get satelliteUrl => 
    'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=$apiKey';
  
  static String get satelliteUrlTemplate => 
    'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=$apiKey';
  
  // URL do mapa satélite (visualização web)
  static String get satelliteWebUrl => 
    'https://api.maptiler.com/maps/satellite/?key=$apiKey';
  
  // Style JSON para MapLibre/Mapbox GL
  static String get satelliteStyleUrl => 
    'https://api.maptiler.com/maps/satellite/style.json?key=$apiKey';
  
  static String get streetsUrl => 
    'https://api.maptiler.com/maps/streets/256/{z}/{x}/{y}.png?key=$apiKey';
  
  static String get outdoorUrl => 
    'https://api.maptiler.com/maps/outdoor/256/{z}/{x}/{y}.png?key=$apiKey';
  
  static String get basicUrl => 
    'https://api.maptiler.com/maps/basic/256/{z}/{x}/{y}.png?key=$apiKey';
  
  // Configurações do mapa
  static const double minZoom = 1.0;
  static const double maxZoom = 22.0;
  static const double defaultZoom = 13.0;
  
  // Centro padrão (Brasília)
  static const double defaultLatitude = -15.7801;
  static const double defaultLongitude = -47.9292;
  
  // User agent
  static const String userAgent = 'com.fortsmartagro.app';
}