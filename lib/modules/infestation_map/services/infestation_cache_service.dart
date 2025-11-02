import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/logger.dart';

/// Serviço de cache para otimizar performance do módulo de infestação
class InfestationCacheService {
  static final InfestationCacheService _instance = InfestationCacheService._internal();
  factory InfestationCacheService() => _instance;
  InfestationCacheService._internal();

  // Chaves de cache
  static const String _cacheKeyPrefix = 'infestation_cache_';
  static const String _talhaoCoordinatesKey = 'talhao_coordinates';
  static const String _organismThresholdsKey = 'organism_thresholds';
  static const String _infestationStatsKey = 'infestation_stats';
  static const String _heatmapDataKey = 'heatmap_data';
  static const String _lastUpdateKey = 'last_update';

  // Configurações de cache
  static const Duration _defaultExpiration = Duration(hours: 1);
  static const Duration _coordinatesExpiration = Duration(hours: 6); // Coordenadas mudam menos
  static const Duration _thresholdsExpiration = Duration(hours: 12); // Thresholds mudam raramente

  /// Obtém dados do cache
  Future<T?> getFromCache<T>(String key, {Duration? expiration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      
      // Verificar se existe no cache
      if (!prefs.containsKey(cacheKey)) {
        Logger.info('📦 Cache miss para: $key');
        return null;
      }

      // Verificar expiração
      final lastUpdate = prefs.getInt(_getCacheKey(_lastUpdateKey)) ?? 0;
      final expirationTime = expiration ?? _defaultExpiration;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastUpdate > expirationTime.inMilliseconds) {
        Logger.info('⏰ Cache expirado para: $key');
        await _removeFromCache(key);
        return null;
      }

      // Retornar dados do cache
      final data = prefs.getString(cacheKey);
      if (data != null) {
        Logger.info('✅ Cache hit para: $key');
        return _deserializeData<T>(data);
      }

      return null;
    } catch (e) {
      Logger.error('❌ Erro ao acessar cache: $e');
      return null;
    }
  }

  /// Salva dados no cache
  Future<bool> saveToCache<T>(String key, T data, {Duration? expiration}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      
      // Serializar dados
      final serializedData = _serializeData(data);
      if (serializedData == null) {
        Logger.error('❌ Erro ao serializar dados para cache: $key');
        return false;
      }

      // Salvar dados
      final success = await prefs.setString(cacheKey, serializedData);
      
      // Atualizar timestamp
      if (success) {
        await prefs.setInt(_getCacheKey(_lastUpdateKey), DateTime.now().millisecondsSinceEpoch);
        Logger.info('💾 Dados salvos no cache: $key');
      }

      return success;
    } catch (e) {
      Logger.error('❌ Erro ao salvar no cache: $e');
      return false;
    }
  }

  /// Remove dados do cache
  Future<bool> _removeFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(key);
      final success = await prefs.remove(cacheKey);
      
      if (success) {
        Logger.info('🗑️ Dados removidos do cache: $key');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao remover do cache: $e');
      return false;
    }
  }

  /// Limpa todo o cache
  Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      Logger.info('🧹 Cache limpo completamente');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao limpar cache: $e');
      return false;
    }
  }

  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      
      final stats = <String, dynamic>{
        'total_keys': keys.length,
        'cache_size_bytes': 0,
        'last_update': null,
        'expired_keys': 0,
        'valid_keys': 0,
      };

      int totalSize = 0;
      int expiredCount = 0;
      int validCount = 0;
      DateTime? lastUpdate;

      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          totalSize += data.length;
          
          if (key.endsWith(_lastUpdateKey)) {
            final timestamp = prefs.getInt(key) ?? 0;
            lastUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else {
            // Verificar se não está expirado
            final lastUpdateKey = _getCacheKey(_lastUpdateKey);
            final lastUpdateTimestamp = prefs.getInt(lastUpdateKey) ?? 0;
            final now = DateTime.now().millisecondsSinceEpoch;
            
            if (now - lastUpdateTimestamp > _defaultExpiration.inMilliseconds) {
              expiredCount++;
            } else {
              validCount++;
            }
          }
        }
      }

      stats['cache_size_bytes'] = totalSize;
      stats['last_update'] = lastUpdate?.toIso8601String();
      stats['expired_keys'] = expiredCount;
      stats['valid_keys'] = validCount;

      return stats;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do cache: $e');
      return {};
    }
  }

  /// Cache específico para coordenadas de talhões
  Future<Map<String, dynamic>?> getTalhaoCoordinatesCache(String talhaoId) async {
    return getFromCache<Map<String, dynamic>>(
      '${_talhaoCoordinatesKey}_$talhaoId',
      expiration: _coordinatesExpiration,
    );
  }

  /// Salva coordenadas de talhão no cache
  Future<bool> cacheTalhaoCoordinates(String talhaoId, Map<String, dynamic> coordinates) async {
    return saveToCache(
      '${_talhaoCoordinatesKey}_$talhaoId',
      coordinates,
      expiration: _coordinatesExpiration,
    );
  }

  /// Cache específico para thresholds de organismos
  Future<Map<String, dynamic>?> getOrganismThresholdsCache() async {
    return getFromCache<Map<String, dynamic>>(
      _organismThresholdsKey,
      expiration: _thresholdsExpiration,
    );
  }

  /// Salva thresholds de organismos no cache
  Future<bool> cacheOrganismThresholds(Map<String, dynamic> thresholds) async {
    return saveToCache(
      _organismThresholdsKey,
      thresholds,
      expiration: _thresholdsExpiration,
    );
  }

  /// Cache específico para estatísticas de infestação
  Future<Map<String, dynamic>?> getInfestationStatsCache(String talhaoId) async {
    return getFromCache<Map<String, dynamic>>(
      '${_infestationStatsKey}_$talhaoId',
      expiration: _defaultExpiration,
    );
  }

  /// Salva estatísticas de infestação no cache
  Future<bool> cacheInfestationStats(String talhaoId, Map<String, dynamic> stats) async {
    return saveToCache(
      '${_infestationStatsKey}_$talhaoId',
      stats,
      expiration: _defaultExpiration,
    );
  }

  /// Cache específico para dados de heatmap
  Future<Map<String, dynamic>?> getHeatmapDataCache(String talhaoId) async {
    return getFromCache<Map<String, dynamic>>(
      '${_heatmapDataKey}_$talhaoId',
      expiration: _defaultExpiration,
    );
  }

  /// Salva dados de heatmap no cache
  Future<bool> cacheHeatmapData(String talhaoId, Map<String, dynamic> heatmapData) async {
    return saveToCache(
      '${_heatmapDataKey}_$talhaoId',
      heatmapData,
      expiration: _defaultExpiration,
    );
  }

  /// Invalida cache específico
  Future<bool> invalidateCache(String key) async {
    return _removeFromCache(key);
  }

  /// Invalida cache de talhão específico
  Future<bool> invalidateTalhaoCache(String talhaoId) async {
    final keys = [
      '${_talhaoCoordinatesKey}_$talhaoId',
      '${_infestationStatsKey}_$talhaoId',
      '${_heatmapDataKey}_$talhaoId',
    ];
    
    bool success = true;
    for (final key in keys) {
      success &= await _removeFromCache(key);
    }
    
    if (success) {
      Logger.info('🔄 Cache invalidado para talhão: $talhaoId');
    }
    
    return success;
  }

  /// Invalida cache de organismos
  Future<bool> invalidateOrganismCache() async {
    return _removeFromCache(_organismThresholdsKey);
  }

  // Métodos auxiliares
  String _getCacheKey(String key) => '$_cacheKeyPrefix$key';

  String? _serializeData<T>(T data) {
    try {
      if (data is Map || data is List) {
        return jsonEncode(data);
      } else if (data is String) {
        return data;
      } else if (data is num || data is bool) {
        return data.toString();
      } else {
        return jsonEncode(data);
      }
    } catch (e) {
      Logger.error('❌ Erro ao serializar dados: $e');
      return null;
    }
  }

  T? _deserializeData<T>(String data) {
    try {
      if (T == String) {
        return data as T;
      } else if (T == int) {
        return int.parse(data) as T;
      } else if (T == double) {
        return double.parse(data) as T;
      } else if (T == bool) {
        return (data == 'true') as T;
      } else {
        return jsonDecode(data) as T;
      }
    } catch (e) {
      Logger.error('❌ Erro ao deserializar dados: $e');
      return null;
    }
  }

  /// Verifica se o cache está disponível
  Future<bool> isCacheAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return true;
    } catch (e) {
      Logger.warning('⚠️ Cache não disponível: $e');
      return false;
    }
  }

  /// Obtém tamanho do cache em MB
  Future<double> getCacheSizeMB() async {
    try {
      final stats = await getCacheStats();
      final sizeBytes = stats['cache_size_bytes'] as int? ?? 0;
      return sizeBytes / (1024 * 1024); // Converter para MB
    } catch (e) {
      Logger.error('❌ Erro ao obter tamanho do cache: $e');
      return 0.0;
    }
  }
}
