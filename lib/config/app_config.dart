/// Configurações gerais do aplicativo

class AppConfig {
  /// Versão do aplicativo
  static const String appVersion = '1.0.0';
  
  /// Nome do aplicativo
  static const String appName = 'FortSmart Agro';
  
  /// Ambiente (development, staging, production)
  static const String environment = 'development';
  
  /// URL base da API
  static const String apiBaseUrl = 'https://api.fortsmartagro.com/v1';
  
  /// Chave da API OpenWeatherMap
  static const String weatherApiKey = 'sua_chave_api_aqui';
  
  /// URL base da API de clima
  static const String weatherApiUrl = 'https://api.openweathermap.org/data/2.5';
  
  /// Tamanho máximo de imagem (em bytes)
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  
  /// Tamanho alvo para compressão de imagens (em KB)
  static const int targetCompressedImageSizeKB = 1024; // 1MB
  
  /// Intervalo de sincronização automática (em minutos)
  static const int autoSyncIntervalMinutes = 30;
  
  /// Intervalo de atualização de dados meteorológicos (em minutos)
  static const int weatherUpdateIntervalMinutes = 60;
  
  /// Número máximo de tentativas de sincronização
  static const int maxSyncRetries = 3;
  
  /// Tempo de cache para dados meteorológicos (em horas)
  static const int weatherCacheHours = 1;
  
  /// Tempo de cache para previsão do tempo (em horas)
  static const int forecastCacheHours = 6;
  
  /// Configurações de banco de dados
  static const DatabaseConfig database = DatabaseConfig(
    version: 1,
    name: 'fortsmartagro.db',
    maxSizeBytes: 50 * 1024 * 1024, // 50MB
  );
  
  /// Configurações de armazenamento
  static const StorageConfig storage = StorageConfig(
    maxCacheSizeMB: 100,
    cleanupThresholdMB: 80,
    imageCompressQuality: 85,
  );
}

/// Configurações de banco de dados
class DatabaseConfig {
  final int version;
  final String name;
  final int maxSizeBytes;
  
  const DatabaseConfig({
    required this.version,
    required this.name,
    required this.maxSizeBytes,
  });
}

/// Configurações de armazenamento
class StorageConfig {
  final int maxCacheSizeMB;
  final int cleanupThresholdMB;
  final int imageCompressQuality;
  
  const StorageConfig({
    required this.maxCacheSizeMB,
    required this.cleanupThresholdMB,
    required this.imageCompressQuality,
  });
}
