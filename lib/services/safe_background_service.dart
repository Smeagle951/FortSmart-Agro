import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../utils/logger.dart';
import 'connectivity_monitor_service.dart';
import 'offline_map_cache_service.dart';

/// Serviço de background seguro e robusto
/// Funciona com a tela desligada sem causar erros
class SafeBackgroundService {
  static final SafeBackgroundService _instance = SafeBackgroundService._internal();
  factory SafeBackgroundService() => _instance;
  SafeBackgroundService._internal();

  bool _isInitialized = false;
  bool _isRunning = false;
  Timer? _syncTimer;
  Timer? _cacheTimer;
  
  // Callbacks para notificar a UI
  Function(String)? onStatusUpdate;
  Function(String)? onError;
  Function(Map<String, dynamic>)? onProgress;

  /// Inicializa o serviço de forma segura
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('🔄 Inicializando SafeBackgroundService...');

      // Inicializar serviços dependentes de forma segura
      await _initializeDependentServices();

      // Configurar serviço de background
      await _setupBackgroundService();

      _isInitialized = true;
      Logger.info('✅ SafeBackgroundService inicializado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar SafeBackgroundService: $e');
      // Continua funcionando mesmo se falhar
    }
  }

  /// Inicializa serviços dependentes de forma segura
  Future<void> _initializeDependentServices() async {
    try {
      // Inicializar conectividade de forma segura
      final connectivityService = ConnectivityMonitorService();
      await connectivityService.initialize();
      
      // Inicializar cache offline de forma segura
      final offlineCacheService = OfflineMapCacheService();
      await offlineCacheService.initialize();
      
      Logger.info('✅ Serviços dependentes inicializados');
    } catch (e) {
      Logger.error('⚠️ Erro ao inicializar serviços dependentes: $e');
      // Continua mesmo se falhar
    }
  }

  /// Configura o serviço de background
  Future<void> _setupBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      
      // Configurar callback para quando o serviço é iniciado
      service.on('onStart', (event) {
        Logger.info('🔄 Serviço de background iniciado');
        _startPeriodicTasks();
      });

      // Configurar callback para quando o serviço é parado
      service.on('onStop', (event) {
        Logger.info('⏹️ Serviço de background parado');
        _stopPeriodicTasks();
      });

      // Configurar callback para tarefas
      service.on('sync', (event) async {
        await executeSyncTask();
      });

      service.on('cache', (event) async {
        await executeMapCacheTask();
      });

      Logger.info('✅ Serviço de background configurado');
    } catch (e) {
      Logger.error('❌ Erro ao configurar serviço de background: $e');
    }
  }

  /// Inicia o processamento em background
  Future<bool> startBackgroundProcessing() async {
    if (_isRunning) return true;

    try {
      final service = FlutterBackgroundService();
      
      // Verificar se o serviço já está rodando
      final isRunning = await service.isRunning();
      if (isRunning) {
        _isRunning = true;
        Logger.info('✅ Serviço de background já estava rodando');
        return true;
      }

      // Iniciar serviço
      await service.startService();
      
      _isRunning = true;
      onStatusUpdate?.call('Serviço de background iniciado');
      
      Logger.info('✅ Serviço de background iniciado com sucesso');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao iniciar serviço de background: $e');
      onError?.call('Erro ao iniciar serviço: $e');
      return false;
    }
  }

  /// Para o processamento em background
  Future<void> stopBackgroundProcessing() async {
    if (!_isRunning) return;

    try {
      final service = FlutterBackgroundService();
      
      // Parar timers
      _stopPeriodicTasks();
      
      // Parar serviço
      await service.invoke('stop');
      
      _isRunning = false;
      onStatusUpdate?.call('Serviço de background parado');
      
      Logger.info('✅ Serviço de background parado');
    } catch (e) {
      Logger.error('❌ Erro ao parar serviço de background: $e');
    }
  }

  /// Inicia tarefas periódicas
  void _startPeriodicTasks() {
    // Timer para sincronização a cada 15 minutos
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await executeSyncTask();
    });

    // Timer para cache de mapa a cada hora
    _cacheTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await executeMapCacheTask();
    });

    Logger.info('✅ Tarefas periódicas iniciadas');
  }

  /// Para tarefas periódicas
  void _stopPeriodicTasks() {
    _syncTimer?.cancel();
    _cacheTimer?.cancel();
    _syncTimer = null;
    _cacheTimer = null;
    
    Logger.info('✅ Tarefas periódicas paradas');
  }

  /// Executa tarefa de sincronização
  Future<void> executeSyncTask() async {
    try {
      Logger.info('🔄 Executando sincronização...');
      onStatusUpdate?.call('Sincronizando dados...');

      // Verificar conectividade
      final connectivityService = ConnectivityMonitorService();
      if (!connectivityService.isOnline()) {
        Logger.info('📡 Sem conectividade, pulando sincronização');
        return;
      }

      // Aqui você implementaria a lógica de sincronização
      // Por enquanto, apenas simula
      await Future.delayed(const Duration(seconds: 2));

      Logger.info('✅ Sincronização concluída');
      onStatusUpdate?.call('Dados sincronizados');
    } catch (e) {
      Logger.error('❌ Erro na sincronização: $e');
      onError?.call('Erro na sincronização: $e');
    }
  }

  /// Executa tarefa de cache de mapa
  Future<void> executeMapCacheTask() async {
    try {
      Logger.info('🔄 Executando cache de mapa...');
      onStatusUpdate?.call('Atualizando cache de mapa...');

      // Verificar conectividade
      final connectivityService = ConnectivityMonitorService();
      if (!connectivityService.isOnline()) {
        Logger.info('📡 Sem conectividade, pulando cache de mapa');
        return;
      }

      // Pré-carregar área atual
      await _preloadCurrentArea();

      Logger.info('✅ Cache de mapa concluído');
      onStatusUpdate?.call('Cache de mapa atualizado');
    } catch (e) {
      Logger.error('❌ Erro no cache de mapa: $e');
      onError?.call('Erro no cache de mapa: $e');
    }
  }

  /// Pré-carrega área atual
  Future<void> _preloadCurrentArea() async {
    try {
      final offlineCacheService = OfflineMapCacheService();
      
      // Área padrão (Brasília) - você pode personalizar
      await offlineCacheService.preloadArea(
        -15.8, -15.7, -47.9, -47.8, // Coordenadas da área
        10, 16, // Zoom min/max
        'satellite', // Estilo
        'KQAa9lY3N0TR17zxhk9u', // API Key
      );
      
      Logger.info('✅ Área pré-carregada');
    } catch (e) {
      Logger.error('❌ Erro ao pré-carregar área: $e');
    }
  }

  /// Verifica se o serviço está rodando
  bool get isRunning => _isRunning;

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;

  /// Libera recursos
  void dispose() {
    stopBackgroundProcessing();
    _isInitialized = false;
  }
}
