/// Configurações do módulo de mapas offline
class OfflineMapsConfig {
  // Configurações de download
  static const int defaultZoomMin = 13;
  static const int defaultZoomMax = 18;
  static const int maxConcurrentDownloads = 3;
  static const Duration downloadTimeout = Duration(seconds: 30);
  
  // Configurações de armazenamento
  static const int cleanupDaysOld = 30;
  static const double maxStorageGB = 5.0; // Máximo de 5GB para mapas offline
  
  // Configurações de tiles
  static const double defaultTileSizeKB = 15.0;
  static const String defaultMapType = 'satellite';
  
  // Configurações de API
  static const String mapTilerApiKey = 'KQAa9lY3N0TR17zxhk9u';
  static const String mapTilerBaseUrl = 'https://api.maptiler.com';
  
  // URLs de tiles do MapTiler
  static const Map<String, String> mapTilerUrls = {
    'satellite': 'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=$mapTilerApiKey',
    'streets': 'https://api.maptiler.com/maps/streets/256/{z}/{x}/{y}.png?key=$mapTilerApiKey',
    'outdoors': 'https://api.maptiler.com/maps/outdoor/256/{z}/{x}/{y}.png?key=$mapTilerApiKey',
    'hybrid': 'https://api.maptiler.com/maps/hybrid/256/{z}/{x}/{y}.jpg?key=$mapTilerApiKey',
    'basic': 'https://api.maptiler.com/maps/basic/256/{z}/{x}/{y}.png?key=$mapTilerApiKey',
  };
  
  // Configurações de UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 16.0;
  
  // Configurações de validação
  static const int minPolygonPoints = 3;
  static const double minAreaHectares = 0.1;
  static const double maxAreaHectares = 10000.0;
  
  /// Obtém URL de tile por tipo de mapa
  static String getTileUrl(String mapType, int z, int x, int y) {
    final template = mapTilerUrls[mapType] ?? mapTilerUrls['satellite']!;
    return template
        .replaceAll('{z}', z.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());
  }
  
  /// Valida configurações de zoom
  static bool isValidZoomRange(int zoomMin, int zoomMax) {
    return zoomMin >= 1 && 
           zoomMax <= 22 && 
           zoomMin <= zoomMax &&
           (zoomMax - zoomMin) <= 10;
  }
  
  /// Valida área do talhão
  static bool isValidArea(double area) {
    return area >= minAreaHectares && area <= maxAreaHectares;
  }
  
  /// Calcula tamanho estimado do download em MB
  static double calculateEstimatedSize({
    required int totalTiles,
    double tileSizeKB = defaultTileSizeKB,
  }) {
    return (totalTiles * tileSizeKB) / 1024; // Converter para MB
  }
  
  /// Verifica se há espaço suficiente
  static bool hasEnoughSpace(double requiredMB) {
    return requiredMB <= (maxStorageGB * 1024); // Converter GB para MB
  }
}
