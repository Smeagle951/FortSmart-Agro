import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Gerenciador de cache para o banco de dados
/// Implementa um sistema de cache em memória para reduzir o número de acessos ao banco de dados
class DatabaseCacheManager {
  static final DatabaseCacheManager _instance = DatabaseCacheManager._internal();
  factory DatabaseCacheManager() => _instance;
  DatabaseCacheManager._internal();

  // Cache para cada tipo de entidade
  final Map<String, _EntityCache> _caches = {};
  
  // Configurações de cache
  final int _defaultMaxSize = 100;
  final Duration _defaultExpiration = Duration(minutes: 10);
  
  /// Obtém ou cria um cache para uma entidade específica
  _EntityCache _getCache(String entityName) {
    if (!_caches.containsKey(entityName)) {
      _caches[entityName] = _EntityCache(
        maxSize: _defaultMaxSize,
        expiration: _defaultExpiration,
      );
    }
    return _caches[entityName]!;
  }
  
  /// Armazena um item no cache
  void put<T>(String entityName, String key, T value) {
    _getCache(entityName).put(key, value);
  }
  
  /// Armazena múltiplos itens no cache
  void putAll<T>(String entityName, Map<String, T> items) {
    final cache = _getCache(entityName);
    items.forEach((key, value) {
      cache.put(key, value);
    });
  }
  
  /// Obtém um item do cache
  T? get<T>(String entityName, String key) {
    return _getCache(entityName).get<T>(key);
  }
  
  /// Verifica se um item existe no cache
  bool contains(String entityName, String key) {
    return _getCache(entityName).contains(key);
  }
  
  /// Remove um item do cache
  void remove(String entityName, String key) {
    _getCache(entityName).remove(key);
  }
  
  /// Limpa o cache de uma entidade específica
  void clear(String entityName) {
    if (_caches.containsKey(entityName)) {
      _caches[entityName]!.clear();
    }
  }
  
  /// Limpa todos os caches
  void clearAll() {
    _caches.forEach((_, cache) => cache.clear());
  }
  
  /// Configura o tamanho máximo do cache para uma entidade
  void setMaxSize(String entityName, int maxSize) {
    _getCache(entityName).maxSize = maxSize;
  }
  
  /// Configura o tempo de expiração do cache para uma entidade
  void setExpiration(String entityName, Duration expiration) {
    _getCache(entityName).expiration = expiration;
  }
  
  /// Obtém estatísticas do cache
  Map<String, Map<String, dynamic>> getStats() {
    final stats = <String, Map<String, dynamic>>{};
    _caches.forEach((entityName, cache) {
      stats[entityName] = {
        'size': cache.size,
        'maxSize': cache.maxSize,
        'hits': cache.hits,
        'misses': cache.misses,
        'hitRatio': cache.hitRatio,
      };
    });
    return stats;
  }
}

/// Cache para uma entidade específica
class _EntityCache {
  // Configurações
  int maxSize;
  Duration expiration;
  
  // Estatísticas
  int hits = 0;
  int misses = 0;
  
  // Cache usando LinkedHashMap para manter a ordem de inserção/acesso
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap<String, _CacheEntry>();
  
  _EntityCache({
    required this.maxSize,
    required this.expiration,
  });
  
  /// Armazena um item no cache
  void put<T>(String key, T value) {
    // Verifica se precisa remover itens antigos
    _evictIfNeeded();
    
    // Adiciona o novo item
    _cache[key] = _CacheEntry<T>(
      value: value,
      timestamp: DateTime.now(),
    );
  }
  
  /// Obtém um item do cache
  T? get<T>(String key) {
    final entry = _cache[key];
    
    // Se não existe ou expirou, retorna null
    if (entry == null) {
      misses++;
      return null;
    }
    
    // Verifica se o item expirou
    if (DateTime.now().difference(entry.timestamp) > expiration) {
      _cache.remove(key);
      misses++;
      return null;
    }
    
    // Atualiza estatísticas e retorna o valor
    hits++;
    
    // Move o item para o final da lista (LRU)
    _cache.remove(key);
    _cache[key] = entry;
    
    return entry.value as T?;
  }
  
  /// Verifica se um item existe no cache
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    // Verifica se o item expirou
    if (DateTime.now().difference(entry.timestamp) > expiration) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }
  
  /// Remove um item do cache
  void remove(String key) {
    _cache.remove(key);
  }
  
  /// Limpa o cache
  void clear() {
    _cache.clear();
    hits = 0;
    misses = 0;
  }
  
  /// Remove itens antigos se o cache estiver cheio
  void _evictIfNeeded() {
    // Se o cache estiver cheio, remove os itens mais antigos
    while (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    
    // Remove itens expirados
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.difference(entry.timestamp) > expiration);
  }
  
  /// Tamanho atual do cache
  int get size => _cache.length;
  
  /// Taxa de acertos do cache
  double get hitRatio {
    final total = hits + misses;
    if (total == 0) return 0;
    return hits / total;
  }
}

/// Entrada do cache
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;
  
  _CacheEntry({
    required this.value,
    required this.timestamp,
  });
}
