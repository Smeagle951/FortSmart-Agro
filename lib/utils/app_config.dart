class AppConfig {
  // Configurações de API
  static const String apiBaseUrl = 'https://api.fortsmartagro.com';
  static const String apiToken = '';
  
  // Configurações de sincronização
  static const bool autoSyncOnConnectivityChange = true;
  static const bool createBackupBeforeSync = true;
  static const bool checkImagesBeforeSync = true;
  static const bool cleanupOrphanedImagesAfterSync = true;
  
  // Configurações de imagem
  static const int photoMaxWidth = 1280;
  static const int photoCompressionQuality = 80;
  static const int maxUploadImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int minRequiredSpaceMB = 100;

  static var apiUrl;

  static var api_url;

  static var api_token; // 100MB de espaço mínimo
}
