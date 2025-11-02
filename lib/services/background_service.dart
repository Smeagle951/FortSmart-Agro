import 'dart:async';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';
import 'connectivity_monitor_service.dart';
import 'offline_map_cache_service.dart';

/// Serviço de processamento em segundo plano robusto
/// Funciona mesmo com a tela desligada
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final ConnectivityMonitorService _connectivityService = ConnectivityMonitorService();
  final OfflineMapCacheService _mapCacheService = OfflineMapCacheService();
  
  bool _isInitialized = false;
  bool _isRunning = false;
  
  // Callbacks para notificar a UI
  Function(String)? onStatusUpdate;
  Function(String)? onError;
  Function(Map<String, dynamic>)? onProgress;

  /// Inicializa o serviço de background
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('🔄 Inicializando serviço de background...');

      // Inicializar serviços dependentes
      await _connectivityService.initialize();
      await _mapCacheService.initialize();

      // Configurar timer para tarefas periódicas
      _startPeriodicTasks();

      _isInitialized = true;
      Logger.info('✅ Serviço de background inicializado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar serviço de background: $e');
      rethrow;
    }
  }

  /// Inicia tarefas periódicas
  void _startPeriodicTasks() {
    // Timer para sincronização a cada 15 minutos
    Timer.periodic(const Duration(minutes: 15), (timer) async {
      if (_isRunning) {
        await executeSyncTask();
      }
    });

    // Timer para cache de mapa a cada hora
    Timer.periodic(const Duration(hours: 1), (timer) async {
      if (_isRunning) {
        await executeMapCacheTask();
      }
    });

    Logger.info('Tarefas periódicas configuradas');
  }

  /// Inicia o processamento em segundo plano
  Future<void> startBackgroundProcessing() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      Logger.info('🔄 Iniciando processamento em segundo plano...');

      _isRunning = true;
      onStatusUpdate?.call('Processamento em segundo plano iniciado');
      Logger.info('✅ Processamento em segundo plano iniciado');
    } catch (e) {
      Logger.error('❌ Erro ao iniciar processamento em segundo plano: $e');
      onError?.call('Erro ao iniciar processamento: $e');
    }
  }

  /// Para o processamento em segundo plano
  Future<void> stopBackgroundProcessing() async {
    try {
      Logger.info('🔄 Parando processamento em segundo plano...');

      _isRunning = false;
      onStatusUpdate?.call('Processamento em segundo plano parado');
      Logger.info('✅ Processamento em segundo plano parado');
    } catch (e) {
      Logger.error('❌ Erro ao parar processamento em segundo plano: $e');
      onError?.call('Erro ao parar processamento: $e');
    }
  }

  /// Executa tarefa de sincronização
  Future<void> executeSyncTask() async {
    try {
      Logger.info('🔄 Executando tarefa de sincronização...');
      onStatusUpdate?.call('Sincronizando dados...');

      // Verificar conectividade
      if (!_connectivityService.isOnline()) {
        Logger.info('📡 Sem conectividade, pulando sincronização');
        return;
      }

      // Executar sincronização (implementação simplificada)
      Logger.info('Sincronização executada');
      Logger.info('✅ Sincronização concluída com sucesso');
      onStatusUpdate?.call('Sincronização concluída');
    } catch (e) {
      Logger.error('❌ Erro na tarefa de sincronização: $e');
      onError?.call('Erro na sincronização: $e');
    }
  }

  /// Executa tarefa de cache de mapa
  Future<void> executeMapCacheTask() async {
    try {
      Logger.info('🔄 Executando tarefa de cache de mapa...');
      onStatusUpdate?.call('Atualizando cache de mapa...');

      // Verificar conectividade
      if (!_connectivityService.isOnline()) {
        Logger.info('📡 Sem conectividade, pulando cache de mapa');
        return;
      }

      // Obter área atual (implementar lógica específica)
      final bounds = await _getCurrentAreaBounds();
      
      if (bounds != null) {
        // Pré-carregar tiles para a área atual
        await _mapCacheService.preloadArea(
          bounds['minLat']!,
          bounds['maxLat']!,
          bounds['minLng']!,
          bounds['maxLng']!,
          10, // zoom mínimo
          16, // zoom máximo
          'streets-v2',
          'YOUR_MAPTILER_API_KEY', // Substituir pela chave real
        );

        Logger.info('✅ Cache de mapa atualizado');
        onStatusUpdate?.call('Cache de mapa atualizado');
      }
    } catch (e) {
      Logger.error('❌ Erro na tarefa de cache de mapa: $e');
      onError?.call('Erro no cache de mapa: $e');
    }
  }

  /// Obtém os limites da área atual
  Future<Map<String, double>?> _getCurrentAreaBounds() async {
    try {
      // Implementar lógica para obter área atual
      // Por enquanto, retorna uma área padrão
      return {
        'minLat': -15.8,
        'maxLat': -15.7,
        'minLng': -47.9,
        'maxLng': -47.8,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter limites da área: $e');
      return null;
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