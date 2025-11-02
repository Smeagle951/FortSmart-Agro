/// Configurações do módulo de infestação
class InfestationConfig {
  // Configurações de cálculo
  static const double defaultTimeDecayFactor = 14.0; // dias
  static const double minAccuracyWeight = 0.5;
  static const double maxAccuracyWeight = 1.0;
  static const double defaultAlertThreshold = 0.7;
  
  // Configurações de heatmap
  static const double defaultHexSize = 50.0; // metros
  static const int maxHexagons = 1000;
  
  // Configurações de cache
  static const Duration cacheTTL = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // Configurações de performance
  static const int maxPointsPerRequest = 10000;
  static const int maxTalhoesPerRequest = 100;
  
  // Configurações de alertas
  static const List<String> defaultAlertLevels = ['ALTO', 'CRITICO'];
  static const Duration alertExpiration = Duration(days: 30);
  
  // Configurações de visualização
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;
  
  // Configurações de cores
  static const Map<String, String> levelColors = {
    'BAIXO': '#4CAF50',
    'MODERADO': '#FF9800',
    'ALTO': '#FF5722',
    'CRITICO': '#F44336',
  };
  
  // Configurações de API
  static const String apiBaseUrl = '/api/infestation';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Configurações de sincronização
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxSyncRetries = 5;
  
  // Configurações de logging
  static const bool enableDebugLogs = true;
  static const bool enablePerformanceLogs = true;
  static const bool enableErrorLogs = true;
}
