import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/logger.dart';
import 'map_cache_service.dart';
import 'offline_map_cache_service.dart';

/// TileProvider personalizado que integra cache offline com MapTiler
/// Funciona de forma híbrida: cache offline + fallback para internet
class OfflineTileProvider extends TileProvider {
  static final OfflineTileProvider _instance = OfflineTileProvider._internal();
  factory OfflineTileProvider() => _instance;
  OfflineTileProvider._internal();

  final MapCacheService _mapCacheService = MapCacheService();
  final OfflineMapCacheService _offlineCacheService = OfflineMapCacheService();
  
  bool _isInitialized = false;
  String _apiKey = 'KQAa9lY3N0TR17zxhk9u';
  
  /// Inicializa o provider de forma segura
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _mapCacheService.initialize();
      await _offlineCacheService.initialize();
      _isInitialized = true;
      
      Logger.info('✅ OfflineTileProvider inicializado com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar OfflineTileProvider: $e');
      // Continua funcionando mesmo se falhar a inicialização
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // Gerar URL do MapTiler
    final url = _buildMapTilerUrl(coordinates);
    
    // Retornar CachedNetworkImage que funciona offline se o tile estiver em cache
    return CachedNetworkImageProvider(
      url,
      headers: const {
        'User-Agent': 'FortSmartAgro/1.0',
      },
      cacheManager: _getCacheManager(),
    );
  }

  /// Constrói URL do MapTiler
  String _buildMapTilerUrl(TileCoordinates coordinates) {
    return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=$_apiKey'
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString());
  }

  /// Obtém cache manager personalizado
  dynamic _getCacheManager() {
    // Usar cache manager padrão que já funciona bem com flutter_map
    return null; // Usa o padrão do flutter_map
  }

  /// Verifica se um tile está disponível offline
  Future<bool> isTileAvailableOffline(int x, int y, int z) async {
    if (!_isInitialized) return false;
    
    try {
      return await _mapCacheService.isTileCached(x, y, z);
    } catch (e) {
      Logger.error('Erro ao verificar tile offline: $e');
      return false;
    }
  }

  /// Força download e cache de um tile específico
  Future<bool> cacheTile(int x, int y, int z) async {
    if (!_isInitialized) return false;
    
    try {
      final url = 'https://api.maptiler.com/maps/satellite/$z/$x/$y.jpg?key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        await _mapCacheService.saveTile(x, y, z, response.bodyBytes);
        return true;
      }
    } catch (e) {
      Logger.error('Erro ao cachear tile: $e');
    }
    
    return false;
  }

  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    if (!_isInitialized) return {'error': 'Não inicializado'};
    
    try {
      return await _mapCacheService.getCacheStats();
    } catch (e) {
      Logger.error('Erro ao obter estatísticas: $e');
      return {'error': e.toString()};
    }
  }

  /// Limpa cache antigo
  Future<void> cleanupCache() async {
    if (!_isInitialized) return;
    
    try {
      await _mapCacheService.cleanupOldCache();
      Logger.info('Cache limpo com sucesso');
    } catch (e) {
      Logger.error('Erro ao limpar cache: $e');
    }
  }
}

/// Widget helper para usar o OfflineTileProvider de forma fácil
class OfflineMapTileLayer extends StatelessWidget {
  final String? urlTemplate;
  final Map<String, String>? additionalOptions;
  final String? userAgentPackageName;
  final int? maxZoom;
  final int? minZoom;

  const OfflineMapTileLayer({
    super.key,
    this.urlTemplate,
    this.additionalOptions,
    this.userAgentPackageName,
    this.maxZoom,
    this.minZoom,
  });

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: urlTemplate ?? 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u',
      additionalOptions: additionalOptions,
      userAgentPackageName: userAgentPackageName ?? 'com.fortsmart.agro',
      maxZoom: maxZoom ?? 18,
      minZoom: minZoom ?? 1,
      tileProvider: OfflineTileProvider(),
    );
  }
}
