import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Classe de configuração global do aplicativo
class AppConfig {
  // Configurações de API
  static String apiBaseUrl = 'https://api.fortsmartagro.com';
  static String apiToken = '';  // Será definido durante a inicialização
  static String appVersion = '1.0.0';  // Será atualizado durante a inicialização
  
  // URL para verificação de conectividade
  static String pingUrl = 'https://api.fortsmartagro.com/ping';
  
  // Configurações de sincronização
  static const int syncIntervalMinutes = 15;
  static const int maxSyncRetries = 3;
  static const int oldDataRetentionDays = 30;
  static const int syncBatchSize = 10; // Número de amostras para sincronizar por lote
  static const int maxSyncBatchSize = 50; // Número máximo de amostras para buscar para sincronização
  static const int maxParallelUploads = 2; // Número máximo de uploads paralelos
  static const int connectionTimeoutSeconds = 30; // Timeout para conexões
  static const int uploadTimeoutSeconds = 60; // Timeout para uploads
  static const int backoffInitialSeconds = 2; // Tempo inicial para backoff exponencial
  static const int backoffMaxSeconds = 60; // Tempo máximo para backoff exponencial
  static const int syncProgressUpdateIntervalMs = 500; // Intervalo para atualização do progresso
  static const bool syncPhotosOnMeteredConnection = false; // Sincronizar fotos em conexões limitadas
  static const bool syncOnlyOnWifi = false; // Sincronizar apenas em WiFi
  static const bool prioritizeCompleteSamples = true; // Priorizar amostras completas
  static const bool avoidPoorConnections = true; // Evitar sincronização em conexões de baixa qualidade
  static const bool avoidMeteredConnections = true; // Evitar sincronização em conexões limitadas (metered)
  static const int minSyncIntervalMinutes = 5; // Intervalo mínimo entre sincronizações
  static const bool skipPhotoUploadOnPoorConnection = true; // Pular upload de fotos em conexões ruins
  static const int syncStrategy = 0; // 0=auto, 1=wifi, 2=manual
  static const bool enableAutoCleanup = true; // Habilitar limpeza automática
  
  // Configurações de banco de dados
  static const String dbName = 'fortsmartagro.db';
  static const int dbVersion = 1;
  static const bool enableDetailedLogging = kDebugMode;
  static const bool autoBackupEnabled = true;
  static const int backupIntervalHours = 24; // Intervalo entre backups automáticos
  static const int maxBackupCount = 5; // Número máximo de backups a manter
  static const bool verifyDbIntegrityOnStartup = true; // Verificar integridade do banco ao iniciar
  static const bool autoRepairDb = true; // Reparar automaticamente problemas de banco
  static const int dbIntegrityCheckIntervalHours = 12; // Intervalo para verificação de integridade
  static const int maxDatabaseSizeMB = 100; // Tamanho máximo do banco de dados em MB
  static const bool compactDatabaseOnStartup = false; // Compactar banco de dados ao iniciar
  static const bool validateDataBeforeSync = true; // Validar dados antes de sincronizar
  
  // Configurações de imagens
  static const int maxImageSizeKB = 1024; // Tamanho máximo de imagem em KB
  static const int maxUploadImageSizeKB = 800; // Tamanho máximo para upload de imagem em KB
  static const int maxPhotoSizeBytes = 1024 * 1024; // Tamanho máximo de foto em bytes (1MB)
  static const int imageQuality = 80; // Qualidade da compressão de imagens (0-100)
  static const int photoCompressionQuality = 70; // Qualidade da compressão de fotos (0-100)
  static const int thumbnailSize = 300; // Tamanho do thumbnail em pixels
  static const bool compressImagesBeforeUpload = true; // Comprimir imagens antes de enviar
  static const bool compressPhotosBeforeUpload = true; // Comprimir fotos antes de enviar
  static const bool generateThumbnails = true; // Gerar miniaturas para exibição rápida
  static const bool keepOriginalImages = false; // Manter imagens originais após compressão
  static const int maxImageDimension = 1920; // Dimensão máxima para imagens (largura ou altura)
  static const int photoMaxWidth = 1280; // Largura máxima para fotos
  static const int photoMaxHeight = 1280; // Altura máxima para fotos
  
  // Configurações de armazenamento
  static const int minRequiredStorageMB = 100; // Espaço mínimo necessário em MB
  static const int cleanupThresholdMB = 50; // Limpar dados antigos quando espaço disponível estiver abaixo deste valor
  static const bool cleanupOrphanedImages = true; // Limpar imagens órfãs (sem referência no banco)
  static const int orphanedImageRetentionDays = 7; // Dias para manter imagens órfãs
  static const bool autoCleanupEnabled = true; // Limpeza automática de dados antigos
  static const int storageCheckIntervalHours = 24; // Intervalo para verificação de armazenamento
  static const int maxCacheSizeMB = 50; // Tamanho máximo do cache em MB
  static const int maxLogSizeMB = 10; // Tamanho máximo dos logs em MB
  static const int maxLogFileCount = 20; // Número máximo de arquivos de log
  
  // Configurações de recuperação e resiliência
  static const int maxRecoveryAttempts = 3; // Número máximo de tentativas de recuperação
  static const bool enableOfflineRecovery = true; // Habilitar recuperação offline
  static const bool keepFailedSyncLogs = true; // Manter logs de sincronizações falhas
  static const int failedSyncLogRetentionDays = 7; // Dias para manter logs de sincronizações falhas
  static const bool enableAutoRetryFailedSync = true; // Tentar novamente sincronizações falhas automaticamente
  static const int autoRetryIntervalMinutes = 30; // Intervalo para tentar novamente sincronizações falhas
  static const bool createBackupBeforeSync = true; // Criar backup antes de sincronizar
  static const bool validateDataIntegrity = true; // Validar integridade dos dados
  static const int maxSyncFailuresBeforeReset = 5; // Número máximo de falhas antes de resetar
  static const bool enableSyncRecovery = true; // Habilitar recuperação de sincronização
  
  // Configurações de monitoramento de conectividade
  static const int connectivityCheckIntervalSeconds = 60; // Intervalo para verificação de conectividade
  static const int minSignalStrengthForSync = 2; // Força mínima do sinal para sincronização (0-4)
  static const bool monitorNetworkQuality = true; // Monitorar qualidade da rede
  static const int networkQualityThreshold = 70; // Limiar de qualidade da rede (0-100)
  static const bool enableNetworkLogging = true; // Habilitar log de rede
  static const int networkLogRetentionDays = 3; // Dias para manter logs de rede
  
  // Configurações de relatórios
  static const int minSpaceForReportGeneration = 50 * 1024 * 1024; // Espaço mínimo para geração de relatórios (50MB)
  static const int maxReportSizeBytes = 10 * 1024 * 1024; // Tamanho máximo de relatório em bytes (10MB)
  static const int reportRetentionDays = 30; // Dias para manter relatórios antigos
  
  // Diretórios da aplicação
  static String _appDocumentsPath = '';
  static String _appTempPath = '';
  static String _dbPath = '';
  static String _backupsPath = '';
  static String _reportsPath = '';
  static String _imagesPath = '';
  static String _logsPath = '';
  static String _cachePath = '';
  
  // Getters para diretórios
  static String get documentsPath => _appDocumentsPath;
  static String get tempPath => _appTempPath;
  static String get dbPath => _dbPath;
  static String get backupsPath => _backupsPath;
  static String get reportsPath => _reportsPath;
  static String get imagesPath => _imagesPath;
  static String get logsPath => _logsPath;
  static String get cachePath => _cachePath;
  
  // Inicializar configurações
  static Future<void> initialize() async {
    try {
      // Obter informações do pacote
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      
      // Inicializar diretórios
      await _initializePaths();
      
      // Carregar token de API (em um app real, isso viria de um armazenamento seguro)
      await _loadApiToken();
      
      // Ajustar URLs com base no ambiente (debug/release)
      if (kDebugMode) {
        apiBaseUrl = 'https://dev-api.fortsmartagro.com';
        pingUrl = 'https://dev-api.fortsmartagro.com/ping';
      }
    } catch (e) {
      debugPrint('Erro ao inicializar AppConfig: $e');
    }
  }
  
  // Inicializar diretórios da aplicação
  static Future<void> _initializePaths() async {
    try {
      // Diretório de documentos
      final appDocDir = await getApplicationDocumentsDirectory();
      _appDocumentsPath = appDocDir.path;
      
      // Diretório temporário
      final appTempDir = await getTemporaryDirectory();
      _appTempPath = appTempDir.path;
      
      // Diretório de banco de dados
      final dbDir = await getDatabasesPath();
      _dbPath = path.join(dbDir, dbName);
      
      // Diretório de backups
      _backupsPath = path.join(_appDocumentsPath, 'backups');
      await Directory(_backupsPath).create(recursive: true);
      
      // Diretório de relatórios
      _reportsPath = path.join(_appDocumentsPath, 'reports');
      await Directory(_reportsPath).create(recursive: true);
      
      // Diretório de imagens
      _imagesPath = path.join(_appDocumentsPath, 'images');
      await Directory(_imagesPath).create(recursive: true);
      
      // Diretório de logs
      _logsPath = path.join(_appDocumentsPath, 'logs');
      await Directory(_logsPath).create(recursive: true);
      
      // Diretório de cache
      _cachePath = path.join(_appTempPath, 'cache');
      await Directory(_cachePath).create(recursive: true);
    } catch (e) {
      debugPrint('Erro ao inicializar diretórios: $e');
    }
  }
  
  // Carregar token de API
  static Future<void> _loadApiToken() async {
    // Em um app real, isso carregaria de um armazenamento seguro como o flutter_secure_storage
    // Por enquanto, usamos um valor de exemplo
    apiToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.exemplo';
  }
  
  // Atualizar token de API após login
  static Future<void> updateApiToken(String token) async {
    apiToken = token;
    // Em um app real, salvar em armazenamento seguro
  }
  
  // Limpar token (logout)
  static Future<void> clearApiToken() async {
    apiToken = '';
    // Em um app real, remover do armazenamento seguro
  }
  
  // Verificar espaço disponível
  static Future<int> getAvailableStorageMB() async {
    try {
      final directory = Directory(_appDocumentsPath);
      final stat = await directory.stat();
      
      // Esta é uma implementação simplificada
      // Em um cenário real, seria necessário usar APIs específicas da plataforma
      // para obter o espaço livre real do dispositivo
      return 500; // Retorna 500MB como exemplo
    } catch (e) {
      debugPrint('Erro ao verificar espaço disponível: $e');
      return 0;
    }
  }
  
  // Verificar se há espaço suficiente
  static Future<bool> hasEnoughStorage() async {
    final availableSpace = await getAvailableStorageMB();
    return availableSpace >= minRequiredStorageMB;
  }
  
  // Verificar se é necessário limpar dados antigos
  static Future<bool> needsStorageCleanup() async {
    final availableSpace = await getAvailableStorageMB();
    return availableSpace < cleanupThresholdMB;
  }
  
  // Obter caminho para um novo arquivo de backup
  static String getBackupFilePath() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(_backupsPath, 'backup_$timestamp.db');
  }
  
  // Obter caminho para um novo arquivo de log
  static String getLogFilePath() {
    final date = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    return path.join(_logsPath, 'log_$date.txt');
  }
  
  // Obter caminho para um arquivo temporário
  static String getTempFilePath(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(_appTempPath, '${prefix}_$timestamp.$extension');
  }
  
  // Obter caminho para uma nova imagem
  static String getNewImagePath(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(_imagesPath, '${prefix}_$timestamp.jpg');
  }
  
  // Obter caminho para um novo thumbnail
  static String getNewThumbnailPath(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(_imagesPath, 'thumb_${prefix}_$timestamp.jpg');
  }
  
  // Obter caminho para um novo relatório
  static String getNewReportPath(String prefix) {
    final date = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    return path.join(_reportsPath, '${prefix}_$date.pdf');
  }
  
  // Obter caminho para um arquivo de cache
  static String getCacheFilePath(String key) {
    return path.join(_cachePath, key);
  }
}

/// Alias para AppConfig para compatibilidade com o código existente
class Config extends AppConfig {
  // Diretórios
  static String? _logsPath;
  static String get logsPath {
    if (_logsPath != null) return _logsPath!;
    throw Exception('logsPath não inicializado. Chame Config.initialize() primeiro.');
  }
  
  // Configurações de retenção
  static const int failedSyncLogRetentionDays = 7;
  
  // Configurações de armazenamento
  static const int minStorageForSyncMB = 100; // Espaço mínimo necessário para sincronização
  static const int minStorageForSyncRecoveryMB = 150; // Espaço mínimo necessário para recuperação de sincronização
  
  // Configurações de sincronização
  static const int maxSyncRetries = 3; // Número máximo de tentativas de sincronização
  static const int autoRetryIntervalMinutes = 30; // Intervalo para tentar novamente sincronizações falhas
  static const int networkQualityThreshold = 70; // Limiar de qualidade da rede (0-100)
  static const bool avoidPoorConnections = true; // Evitar sincronização em conexões de baixa qualidade
  static const int minStoragePerSampleMB = 10; // Espaço mínimo necessário por amostra
  static const bool enableSyncRecovery = true; // Habilitar recuperação de sincronização
  static const bool enableAutoRetryFailedSync = true; // Tentar novamente sincronizações falhas automaticamente
  
  // Configurações de conexão
  static const int minConnectionQualityForSync = 50; // Qualidade mínima de conexão para sincronização
  
  // Configurações de upload de imagens
  static const int maxUploadImageSizeKB = 1024; // Tamanho máximo para upload de imagens
  static const int maxImageDimension = 1920; // Dimensão máxima para imagens
  static const int imageQuality = 85; // Qualidade de compressão de imagens (0-100)
  static const int photoCompressionQuality = 80; // Qualidade de compressão para fotos
  static const int photoMaxWidth = 1280; // Largura máxima para fotos
  static const int photoMaxHeight = 1280; // Altura máxima para fotos
  static const int orphanedImageRetentionDays = 30; // Dias para manter imagens órfãs
  static const String imagesPath = 'images'; // Caminho relativo para armazenamento de imagens
  
  // Configurações de gerenciamento de upload
  static const int maxParallelUploads = 2; // Número máximo de uploads paralelos
  static const int uploadTimeoutSeconds = 60; // Timeout para uploads
  static const int backoffInitialSeconds = 2; // Tempo inicial para backoff exponencial
  static const int backoffMaxSeconds = 60; // Tempo máximo para backoff exponencial
  
  // Configurações de exportação
  static const String exportsPath = 'exports'; // Caminho relativo para exportações
  
  // Configurações de banco de dados
  static const String databasePath = 'fortsmartagro.db'; // Nome do arquivo de banco de dados
  
  // Propriedades de sincronização para compatibilidade com SyncService
  static bool get autoSyncOnConnectivityChange => true;
  static bool get createBackupBeforeSync => true;
  static bool get checkImagesBeforeSync => true;
  static bool get cleanupOrphanedImagesAfterSync => true;
  static int get maxUploadImageSizeBytes => 5 * 1024 * 1024; // 5MB
  
  /// Retorna a versão atual do aplicativo
  static Future<String> getAppVersion() async {
    return AppConfig.appVersion;
  }
  
  /// Inicializa as configurações
  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _logsPath = path.join(appDir.path, 'logs');
      
      // Criar diretório de logs se não existir
      final logsDir = Directory(_logsPath!);
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      // Inicializar outras configurações
      final packageInfo = await PackageInfo.fromPlatform();
      AppConfig.appVersion = packageInfo.version;
    } catch (e) {
      debugPrint('Erro ao inicializar configurações: $e');
    }
  }
}
