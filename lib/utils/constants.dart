class AppConstants {
  // Cores principais
  static const int primaryColorValue = 0xFF2196F3;
  static const int secondaryColorValue = 0xFF1976D2;
  static const int accentColorValue = 0xFF64B5F6;
  
  // Strings
  static const String appName = 'FortSmart Agro';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema completo de gestão agrícola';
  
  // Configurações de mapa
  static const double defaultZoom = 15.0;
  static const double minZoom = 10.0;
  static const double maxZoom = 20.0;
  
  // Configurações de localização
  static const int locationUpdateInterval = 1000; // 1 segundo
  static const int locationUpdateDistance = 10; // 10 metros
  
  // Configurações de armazenamento
  static const String databaseName = 'fortsmart_agro.db';
  static const int databaseVersion = 1;
  
  // Chaves de preferências
  static const String keyThemeMode = 'theme_mode';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyUserLocation = 'user_location';
  static const String keySavedRoutes = 'saved_routes';
  
  // URLs e APIs
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String mapTilerApiKey = 'TiQt1yLZoL6EmShd1flj';
  static const String reverseGeocodingUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  
  // Mensagens
  static const String locationPermissionDenied = 'Permissão de localização negada';
  static const String locationServiceDisabled = 'Serviço de localização desabilitado';
  static const String locationError = 'Erro ao obter localização';
  static const String networkError = 'Erro de conexão';
  static const String unknownError = 'Erro desconhecido';
  
  // Animações
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 3);
  
  // Tamanhos
  static const double buttonHeight = 56.0;
  static const double cardRadius = 12.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double padding = 16.0;
  static const double margin = 8.0;
  static const int maxLocationHistory = 1000;
}