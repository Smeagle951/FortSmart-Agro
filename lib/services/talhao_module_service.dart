import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fortsmart_agro/utils/map_global_adapter.dart';

import '../database/talhao_database.dart';
import '../services/talhao_cache_service.dart';
import '../services/kml_import_service.dart';
import '../utils/logger.dart';
import '../models/talhao_model.dart';

/// Serviço principal do módulo talhões
/// Integra cache, banco de dados e funcionalidades offline
class TalhaoModuleService {
  static final TalhaoModuleService _instance = TalhaoModuleService._internal();
  factory TalhaoModuleService() => _instance;
  TalhaoModuleService._internal();

  // Serviços do módulo
  final TalhaoDatabase _database = TalhaoDatabase();
  final TalhaoCacheService _cacheService = TalhaoCacheService();
  final KmlImportService _kmlImportService = KmlImportService();
  
  // Status do módulo
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Stream para notificar mudanças no status do módulo
  final _statusController = StreamController<TalhaoModuleStatus>.broadcast();
  Stream<TalhaoModuleStatus> get statusStream => _statusController.stream;
  
  /// Inicializa o módulo talhões
  Future<bool> initialize() async {
    if (_isInitialized || _isInitializing) {
      return _isInitialized;
    }
    
    try {
      _isInitializing = true;
      _notifyStatus(TalhaoModuleState.initializing);
      
      Logger.info('Inicializando módulo talhões...');
      
      // 1. Inicializar banco de dados
      await _initializeDatabase();
      
      // 2. Inicializar serviço de cache
      await _cacheService.initialize();
      
      // 3. Verificar integridade dos dados
      await _checkDataIntegrity();
      
      _isInitialized = true;
      _notifyStatus(TalhaoModuleState.ready);
      
      Logger.info('Módulo talhões inicializado com sucesso');
      return true;
    } catch (e) {
      Logger.error('Erro ao inicializar módulo talhões: $e');
      _notifyStatus(TalhaoModuleState.error, error: e.toString());
      return false;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Inicializa o banco de dados
  Future<void> _initializeDatabase() async {
    try {
      Logger.info('Inicializando banco de dados do módulo talhões...');
      
      // O banco de dados será inicializado automaticamente pelo DatabaseHelper
      // Aqui apenas verificamos se está funcionando
      final stats = await _database.getStats();
      Logger.info('Banco de dados inicializado: $stats');
    } catch (e) {
      Logger.error('Erro ao inicializar banco de dados: $e');
      rethrow;
    }
  }
  
  /// Verifica a integridade dos dados
  Future<void> _checkDataIntegrity() async {
    try {
      Logger.info('Verificando integridade dos dados...');
      
      // Verificar se há dados corrompidos
      final talhoes = await _cacheService.getTalhoes();
      
      int corruptedCount = 0;
      for (final talhao in talhoes) {
        if (talhao.poligonos.isEmpty || talhao.area <= 0) {
          corruptedCount++;
          Logger.info('Talhão com dados corrompidos: ${talhao.name}');
        }
      }
      
      if (corruptedCount > 0) {
        Logger.info('Encontrados $corruptedCount talhões com dados corrompidos');
        _notifyStatus(TalhaoModuleState.warning, message: '$corruptedCount talhões com dados corrompidos');
      } else {
        Logger.info('Integridade dos dados verificada com sucesso');
      }
    } catch (e) {
      Logger.error('Erro ao verificar integridade dos dados: $e');
    }
  }
  
  /// Obtém todos os talhões
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _cacheService.getTalhoes(forceRefresh: forceRefresh);
  }
  
  /// Obtém um talhão específico
  Future<TalhaoModel?> getTalhaoById(String id) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _cacheService.getTalhaoById(id);
  }
  
  /// Salva um talhão
  Future<bool> saveTalhao(TalhaoModel talhao) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _cacheService.saveTalhao(talhao);
  }
  
  /// Exclui um talhão
  Future<bool> deleteTalhao(String id) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _cacheService.deleteTalhao(id);
  }
  
  /// Importa arquivo KML
  Future<List<LatLng>?> importKmlFile(BuildContext context) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final result = await _kmlImportService.importKmlFile(context);
    return result; // Já retorna o tipo correto
  }
  
  /// Valida coordenadas importadas
  bool validateCoordinates(List<LatLng> coordinates, BuildContext context) {
    return _kmlImportService.validateCoordinates(coordinates, context);
  }
  
  /// Força sincronização
  Future<bool> forceSync() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _cacheService.forceSync();
  }
  
  /// Obtém estatísticas do módulo
  Future<Map<String, dynamic>> getModuleStats() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final dbStats = await _database.getStats();
    final cacheStats = _cacheService.getCacheStats();
    
    return {
      'database': dbStats,
      'cache': cacheStats,
      'module': {
        'isInitialized': _isInitialized,
        'isOnline': _cacheService.isOnline,
        'isSyncing': _cacheService.isSyncing,
        'cacheValid': _cacheService.isCacheValid,
        'lastUpdate': DateTime.now().toIso8601String(),
      },
    };
  }
  
  /// Limpa cache
  Future<void> clearCache() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _cacheService.clearCache();
  }
  
  /// Verifica se o módulo está pronto
  bool get isReady => _isInitialized;
  
  /// Verifica se está online
  bool get isOnline => _cacheService.isOnline;
  
  /// Verifica se está sincronizando
  bool get isSyncing => _cacheService.isSyncing;
  
  /// Notifica mudanças no status
  void _notifyStatus(TalhaoModuleState status, {String? error, String? message}) {
    _statusController.add(TalhaoModuleStatus(
      status: status,
      error: error,
      message: message,
      timestamp: DateTime.now(),
    ));
  }
  
  /// Dispose do serviço
  void dispose() {
    _statusController.close();
    _cacheService.dispose();
  }
}

/// Status do módulo talhões
class TalhaoModuleStatus {
  final TalhaoModuleState status;
  final String? error;
  final String? message;
  final DateTime timestamp;
  
  TalhaoModuleStatus({
    required this.status,
    this.error,
    this.message,
    required this.timestamp,
  });
}

/// Estados possíveis do módulo
enum TalhaoModuleState {
  initializing,
  ready,
  error,
  warning,
  syncing,
  offline,
} 