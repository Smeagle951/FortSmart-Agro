import 'package:flutter/foundation.dart';
import '../utils/logger.dart';
import 'simple_background_service.dart';
import 'offline_tile_provider.dart';
import 'connectivity_monitor_service.dart';
import 'offline_map_cache_service.dart';

/// Inicializador seguro do app que não quebra se algum serviço falhar
class SafeAppInitializer {
  static final SafeAppInitializer _instance = SafeAppInitializer._internal();
  factory SafeAppInitializer() => _instance;
  SafeAppInitializer._internal();

  bool _isInitialized = false;
  final Map<String, bool> _serviceStatus = {};

  /// Inicializa todos os serviços de forma segura
  Future<void> initializeApp() async {
    if (_isInitialized) return;

    try {
      Logger.info('🚀 Iniciando inicialização segura do app...');

      // Lista de serviços para inicializar
      final services = [
        _initializeConnectivity,
        _initializeOfflineCache,
        _initializeTileProvider,
        _initializeBackgroundService,
      ];

      // Inicializar serviços em paralelo com tratamento individual de erro
      final futures = services.map((service) => service().catchError((e) {
        Logger.error('⚠️ Serviço falhou na inicialização: $e');
        return false; // Retorna false se falhar
      }));

      final results = await Future.wait(futures);

      // Verificar quais serviços foram inicializados com sucesso
      final serviceNames = [
        'ConnectivityService',
        'OfflineCacheService', 
        'TileProvider',
        'BackgroundService',
      ];

      for (int i = 0; i < serviceNames.length; i++) {
        _serviceStatus[serviceNames[i]] = results[i] == true;
        Logger.info('${results[i] ? '✅' : '❌'} ${serviceNames[i]}: ${results[i] ? 'OK' : 'FALHOU'}');
      }

      _isInitialized = true;
      
      final successCount = results.where((r) => r == true).length;
      Logger.info('🎉 Inicialização concluída: $successCount/${services.length} serviços OK');
      
    } catch (e) {
      Logger.error('❌ Erro crítico na inicialização: $e');
      // Continua mesmo com erro crítico
      _isInitialized = true;
    }
  }

  /// Inicializa serviço de conectividade
  Future<bool> _initializeConnectivity() async {
    try {
      final service = ConnectivityMonitorService();
      await service.initialize();
      Logger.info('✅ ConnectivityService inicializado');
      return true;
    } catch (e) {
      Logger.error('❌ ConnectivityService falhou: $e');
      return false;
    }
  }

  /// Inicializa cache offline
  Future<bool> _initializeOfflineCache() async {
    try {
      final service = OfflineMapCacheService();
      await service.initialize();
      Logger.info('✅ OfflineCacheService inicializado');
      return true;
    } catch (e) {
      Logger.error('❌ OfflineCacheService falhou: $e');
      return false;
    }
  }

  /// Inicializa tile provider offline
  Future<bool> _initializeTileProvider() async {
    try {
      final provider = OfflineTileProvider();
      await provider.initialize();
      Logger.info('✅ TileProvider inicializado');
      return true;
    } catch (e) {
      Logger.error('❌ TileProvider falhou: $e');
      return false;
    }
  }

  /// Inicializa serviço de background
  Future<bool> _initializeBackgroundService() async {
    try {
      final service = SimpleBackgroundService();
      await service.initialize();
      Logger.info('✅ BackgroundService inicializado');
      return true;
    } catch (e) {
      Logger.error('❌ BackgroundService falhou: $e');
      return false;
    }
  }

  /// Inicia serviços de background se estiverem funcionando
  Future<void> startBackgroundServices() async {
    if (!_isInitialized) {
      await initializeApp();
    }

    // Só inicia background service se ele foi inicializado com sucesso
    if (_serviceStatus['BackgroundService'] == true) {
      try {
        final service = SimpleBackgroundService();
        await service.startBackgroundProcessing();
        Logger.info('✅ Serviços de background iniciados');
      } catch (e) {
        Logger.error('❌ Erro ao iniciar serviços de background: $e');
      }
    } else {
      Logger.warning('⚠️ BackgroundService não disponível, pulando inicialização');
    }
  }

  /// Obtém status dos serviços
  Map<String, bool> getServiceStatus() => Map.from(_serviceStatus);

  /// Verifica se um serviço específico está funcionando
  bool isServiceWorking(String serviceName) {
    return _serviceStatus[serviceName] ?? false;
  }

  /// Obtém resumo do status
  String getStatusSummary() {
    if (!_isInitialized) return 'Não inicializado';
    
    final total = _serviceStatus.length;
    final working = _serviceStatus.values.where((v) => v).length;
    
    return '$working/$total serviços funcionando';
  }

  /// Verifica se está inicializado
  bool get isInitialized => _isInitialized;
}
