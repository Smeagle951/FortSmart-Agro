import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/talhao_model.dart';
import '../models/safra_model.dart';
import '../models/poligono_model.dart';
import '../database/talhao_database.dart';
import '../utils/logger.dart';
import '../utils/app_config.dart';

/// Serviço de cache robusto para o módulo talhões
/// Implementa cache de 12 horas com funcionalidade offline completa
class TalhaoCacheService {
  static final TalhaoCacheService _instance = TalhaoCacheService._internal();
  factory TalhaoCacheService() => _instance;
  TalhaoCacheService._internal();

  // Cache em memória
  List<TalhaoModel>? _cachedTalhoes;
  Map<String, TalhaoModel> _talhaoById = {};
  
  // Timestamps para controle de validade
  DateTime? _lastCacheUpdate;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;
  
  // Configurações de cache
  static const Duration _cacheDuration = Duration(hours: 12);
  static const Duration _syncInterval = Duration(hours: 1);
  static const int _maxRetryAttempts = 3;
  
  // Status de conectividade
  bool _isOnline = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Controle de sincronização
  bool _isSyncing = false;
  int _consecutiveFailures = 0;
  
  // Banco de dados
  final TalhaoDatabase _database = TalhaoDatabase();
  
  /// Inicializa o serviço de cache
  Future<void> initialize() async {
    try {
      // Carregar dados do cache persistente
      await _loadPersistentCache();
      
      // Configurar monitoramento de conectividade
      await _setupConnectivityMonitoring();
      
      // Verificar se precisa sincronizar
      await _checkAndSyncIfNeeded();
      
      Logger.info('TalhaoCacheService inicializado com sucesso');
    } catch (e) {
      Logger.error('Erro ao inicializar TalhaoCacheService: $e');
    }
  }
  
  /// Configura o monitoramento de conectividade
  Future<void> _setupConnectivityMonitoring() async {
    try {
      // Verificar conectividade inicial
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      // Configurar listener para mudanças de conectividade
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;
        
        // Se a conectividade foi restaurada, tentar sincronizar
        if (!wasOnline && _isOnline) {
          Logger.info('Conectividade restaurada, iniciando sincronização...');
          _syncDataIfNeeded();
        }
      });
    } catch (e) {
      Logger.error('Erro ao configurar monitoramento de conectividade: $e');
    }
  }
  
  /// Verifica se o cache está válido
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }
  
  /// Verifica se precisa sincronizar
  bool _shouldSync() {
    if (_isSyncing) return false;
    if (!_isOnline) return false;
    
    // Sincronizar se nunca foi sincronizado ou se passou muito tempo
    if (_lastSuccessfulSync == null) return true;
    if (DateTime.now().difference(_lastSuccessfulSync!) > _syncInterval) return true;
    
    // Sincronizar se houve muitas falhas consecutivas
    if (_consecutiveFailures >= _maxRetryAttempts) return true;
    
    return false;
  }
  
  /// Carrega cache persistente do disco
  Future<void> _loadPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('talhao_cache_data');
      final cacheTime = prefs.getString('talhao_cache_time');
      
      if (cacheData != null && cacheTime != null) {
        final cacheDateTime = DateTime.parse(cacheTime);
        
        // Verificar se o cache ainda é válido
        if (DateTime.now().difference(cacheDateTime) < _cacheDuration) {
          final List<dynamic> jsonList = jsonDecode(cacheData);
          _cachedTalhoes = jsonList.map((json) => TalhaoModel.fromJson(json)).toList();
          _lastCacheUpdate = cacheDateTime;
          
          // Reconstruir mapa por ID
          _talhaoById.clear();
          for (final talhao in _cachedTalhoes!) {
            _talhaoById[talhao.id] = talhao;
          }
          
          Logger.info('Cache persistente carregado: ${_cachedTalhoes!.length} talhões');
        }
      }
    } catch (e) {
      Logger.error('Erro ao carregar cache persistente: $e');
    }
  }
  
  /// Salva cache persistente no disco
  Future<void> _savePersistentCache() async {
    try {
      if (_cachedTalhoes == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final cacheData = jsonEncode(_cachedTalhoes!.map((t) => t.toJson()).toList());
      final cacheTime = DateTime.now().toIso8601String();
      
      await prefs.setString('talhao_cache_data', cacheData);
      await prefs.setString('talhao_cache_time', cacheTime);
      
      Logger.info('Cache persistente salvo: ${_cachedTalhoes!.length} talhões');
    } catch (e) {
      Logger.error('Erro ao salvar cache persistente: $e');
    }
  }
  
  /// Obtém todos os talhões (com cache)
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    try {
      // Se não for forçar refresh e o cache for válido, retornar do cache
      if (!forceRefresh && _isCacheValid() && _cachedTalhoes != null) {
        Logger.info('Retornando ${_cachedTalhoes!.length} talhões do cache');
        return _cachedTalhoes!;
      }
      
      // Carregar do banco de dados local
      final talhoes = await _database.listarTodos();
      
      // Atualizar cache
      _cachedTalhoes = talhoes;
      _lastCacheUpdate = DateTime.now();
      
      // Reconstruir mapa por ID
      _talhaoById.clear();
      for (final talhao in talhoes) {
        _talhaoById[talhao.id] = talhao;
      }
      
      // Salvar cache persistente
      await _savePersistentCache();
      
      // Verificar se precisa sincronizar
      _syncDataIfNeeded();
      
      Logger.info('Carregados ${talhoes.length} talhões do banco local');
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao obter talhões: $e');
      
      // Se houver erro e tivermos cache, retornar cache mesmo expirado
      if (_cachedTalhoes != null) {
        Logger.info('Retornando ${_cachedTalhoes!.length} talhões do cache (erro no banco)');
        return _cachedTalhoes!;
      }
      
      return [];
    }
  }
  
  /// Obtém um talhão específico por ID
  Future<TalhaoModel?> getTalhaoById(String id) async {
    try {
      // Verificar cache primeiro
      if (_talhaoById.containsKey(id)) {
        return _talhaoById[id];
      }
      
      // Se não estiver no cache, carregar todos os talhões
      await getTalhoes();
      
      return _talhaoById[id];
    } catch (e) {
      Logger.error('Erro ao obter talhão por ID: $e');
      return null;
    }
  }
  
  /// Salva um talhão (local e cache)
  Future<bool> saveTalhao(TalhaoModel talhao) async {
    try {
      // Salvar no banco de dados
      final success = await _database.salvarTalhao(talhao);
      
      if (success) {
        // Atualizar cache
        if (_cachedTalhoes != null) {
          final index = _cachedTalhoes!.indexWhere((t) => t.id == talhao.id);
          if (index != -1) {
            _cachedTalhoes![index] = talhao;
          } else {
            _cachedTalhoes!.add(talhao);
          }
          _talhaoById[talhao.id] = talhao;
        }
        
        // Salvar cache persistente
        await _savePersistentCache();
        
        Logger.info('Talhão salvo com sucesso: ${talhao.name}');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erro ao salvar talhão: $e');
      return false;
    }
  }
  
  /// Exclui um talhão
  Future<bool> deleteTalhao(String id) async {
    try {
      // Excluir do banco de dados
      final success = await _database.excluir(int.parse(id));
      
      if (success) {
        // Remover do cache
        if (_cachedTalhoes != null) {
          _cachedTalhoes!.removeWhere((t) => t.id == id);
          _talhaoById.remove(id);
        }
        
        // Salvar cache persistente
        await _savePersistentCache();
        
        Logger.info('Talhão excluído com sucesso: $id');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erro ao excluir talhão: $e');
      return false;
    }
  }
  
  /// Verifica e sincroniza dados se necessário
  Future<void> _checkAndSyncIfNeeded() async {
    if (_shouldSync()) {
      await _syncDataIfNeeded();
    }
  }
  
  /// Sincroniza dados com o servidor (se online)
  Future<void> _syncDataIfNeeded() async {
    if (!_shouldSync()) return;
    
    try {
      _isSyncing = true;
      _lastSyncAttempt = DateTime.now();
      
      Logger.info('Iniciando sincronização de talhões...');
      
      // Aqui seria implementada a sincronização real com o servidor
      // Por enquanto, apenas simular uma sincronização bem-sucedida
      
      // Simular delay de sincronização
      await Future.delayed(const Duration(seconds: 2));
      
      _lastSuccessfulSync = DateTime.now();
      _consecutiveFailures = 0;
      
      Logger.info('Sincronização concluída com sucesso');
    } catch (e) {
      _consecutiveFailures++;
      Logger.error('Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Força uma sincronização manual
  Future<bool> forceSync() async {
    try {
      if (!_isOnline) {
        Logger.info('Tentativa de sincronização sem conectividade');
        return false;
      }
      
      await _syncDataIfNeeded();
      return _lastSuccessfulSync != null;
    } catch (e) {
      Logger.error('Erro na sincronização forçada: $e');
      return false;
    }
  }
  
  /// Limpa todo o cache
  Future<void> clearCache() async {
    try {
      _cachedTalhoes = null;
      _talhaoById.clear();
      _lastCacheUpdate = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('talhao_cache_data');
      await prefs.remove('talhao_cache_time');
      
      Logger.info('Cache limpo com sucesso');
    } catch (e) {
      Logger.error('Erro ao limpar cache: $e');
    }
  }
  
  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedTalhoes': _cachedTalhoes?.length ?? 0,
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      'lastSyncAttempt': _lastSyncAttempt?.toIso8601String(),
      'lastSuccessfulSync': _lastSuccessfulSync?.toIso8601String(),
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'consecutiveFailures': _consecutiveFailures,
      'cacheValid': _isCacheValid(),
    };
  }
  
  /// Verifica se está online
  bool get isOnline => _isOnline;
  
  /// Verifica se está sincronizando
  bool get isSyncing => _isSyncing;
  
  /// Verifica se o cache está válido
  bool get isCacheValid => _isCacheValid();
  
  /// Dispose do serviço
  void dispose() {
    _connectivitySubscription?.cancel();
  }
} 