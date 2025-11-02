import 'dart:collection';
import 'dart:convert';
import '../utils/logger.dart';

/// Classe para gerenciar o cache em memória do banco de dados
class DatabaseCacheManager {
  static final DatabaseCacheManager _instance = DatabaseCacheManager._internal();
  
  // Cache principal usando LRU (Least Recently Used)
  final Map<String, _CacheEntry> _cache = LinkedHashMap<String, _CacheEntry>();
  
  // Estatísticas de uso do cache
  int _hits = 0;
  int _misses = 0;
  int _puts = 0;
  int _evictions = 0;
  
  // Configurações do cache
  final int _maxSize = 1000; // Número máximo de itens no cache
  final Duration _defaultExpiration = Duration(minutes: 30); // Tempo padrão de expiração
  
  factory DatabaseCacheManager() {
    return _instance;
  }
  
  DatabaseCacheManager._internal();
  
  /// Obtém um item do cache
  Future<T?> get<T>(String namespace, String key) async {
    final cacheKey = _getCacheKey(namespace, key);
    final entry = _cache[cacheKey];
    
    if (entry == null) {
      _misses++;
      return null;
    }
    
    // Verificar se o item expirou
    if (entry.isExpired()) {
      _cache.remove(cacheKey);
      _misses++;
      return null;
    }
    
    // Mover o item para o final da lista (LRU)
    _cache.remove(cacheKey);
    _cache[cacheKey] = entry;
    
    _hits++;
    return entry.value as T?;
  }
  
  /// Obtém uma lista de itens do cache
  Future<List<T>?> getList<T>(String key) async {
    final result = await get<List<dynamic>>(key, 'list');
    if (result == null) {
      return null;
    }
    
    return result.cast<T>();
  }
  
  /// Adiciona um item ao cache
  Future<void> put<T>(String namespace, String key, T value, {Duration? expiration}) async {
    final cacheKey = _getCacheKey(namespace, key);
    
    // Verificar se é necessário remover itens antigos (LRU)
    if (_cache.length >= _maxSize && !_cache.containsKey(cacheKey)) {
      _evictOldest();
    }
    
    final expirationTime = DateTime.now().add(expiration ?? _defaultExpiration);
    _cache[cacheKey] = _CacheEntry(value, expirationTime);
    _puts++;
  }
  
  /// Adiciona uma lista de itens ao cache
  Future<void> putList<T>(String key, List<T> value, {Duration? expiration}) async {
    await put(key, 'list', value, expiration: expiration);
  }
  
  /// Invalida um item do cache
  Future<void> invalidate(String namespace, String key) async {
    final cacheKey = _getCacheKey(namespace, key);
    _cache.remove(cacheKey);
  }
  
  /// Invalida todos os itens de um namespace
  Future<void> invalidateNamespace(String namespace) async {
    final keysToRemove = _cache.keys.where((k) => k.startsWith('$namespace:')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
  
  /// Invalida uma lista específica do cache
  Future<void> invalidateList(String key) async {
    await invalidate(key, 'list');
  }
  
  /// Alias para invalidate para compatibilidade com código existente
  Future<void> invalidateCache(String key) async {
    // Tenta invalidar tanto como namespace quanto como chave específica
    await invalidateNamespace(key);
    
    // Se a chave contém ':', tenta invalidar como chave específica
    if (key.contains(':')) {
      final parts = key.split(':');
      if (parts.length >= 2) {
        await invalidate(parts[0], parts[1]);
      }
    }
  }
  
  /// Limpa todo o cache
  Future<void> clear() async {
    _cache.clear();
  }
  
  /// Obtém estatísticas de uso do cache
  Map<String, dynamic> getStatistics() {
    final total = _hits + _misses;
    final hitRatio = total > 0 ? _hits / total : 0.0;
    
    return {
      'hits': _hits,
      'misses': _misses,
      'puts': _puts,
      'evictions': _evictions,
      'size': _cache.length,
      'maxSize': _maxSize,
      'hitRatio': hitRatio,
    };
  }
  
  /// Gera a chave de cache combinando namespace e key
  String _getCacheKey(String namespace, String key) {
    return '$namespace:$key';
  }
  
  /// Remove o item mais antigo do cache (LRU)
  void _evictOldest() {
    if (_cache.isEmpty) return;
    
    final oldestKey = _cache.keys.first;
    _cache.remove(oldestKey);
    _evictions++;
  }
}

/// Classe interna para armazenar um item no cache com tempo de expiração
class _CacheEntry {
  final dynamic value;
  final DateTime expirationTime;
  
  _CacheEntry(this.value, this.expirationTime);
  
  bool isExpired() {
    return DateTime.now().isAfter(expirationTime);
  }
}
