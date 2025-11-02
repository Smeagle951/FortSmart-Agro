import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

/// Coordenadas de um tile de mapa
class TileCoordinates {
  final int x;
  final int y;
  final int z;
  
  TileCoordinates(this.x, this.y, this.z);
  
  @override
  String toString() => 'Tile($z/$x/$y)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TileCoordinates &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }
  
  @override
  int get hashCode => Object.hash(x, y, z);
}

/// Serviço para gerenciar o cache de tiles de mapa
class MapCacheService {
  static final MapCacheService _instance = MapCacheService._internal();
  
  factory MapCacheService() {
    return _instance;
  }
  
  MapCacheService._internal();
  
  bool _initialized = false;
  late String _cacheDirectory;
  
  /// Inicializa o serviço de cache
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = '${appDir.path}/map_cache';
      
      final cacheDir = Directory(_cacheDirectory);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      _initialized = true;
      debugPrint('MapCacheService inicializado: $_cacheDirectory');
    } catch (e) {
      debugPrint('Erro ao inicializar MapCacheService: $e');
    }
  }
  
  /// Pré-carrega tiles para uma região específica
  Future<void> preCacheTiles(
    String urlTemplate,
    LatLngBounds bounds,
    int minZoom,
    int maxZoom, {
    Function(double)? onProgress,
  }) async {
    await initialize();
    
    final tiles = _calculateTilesInBounds(bounds, minZoom, maxZoom);
    int downloaded = 0;
    int total = tiles.length;
    
    for (final tile in tiles) {
      final url = _getUrl(urlTemplate, tile);
      final success = await _downloadAndCacheTile(url, tile);
      if (success) downloaded++;
      
      if (onProgress != null) {
        onProgress(downloaded / total);
      }
    }
    
    debugPrint('Cache concluído: $downloaded/$total tiles baixados');
  }
  
  /// Calcula os tiles dentro de uma região geográfica
  List<TileCoordinates> _calculateTilesInBounds(LatLngBounds bounds, int minZoom, int maxZoom) {
    final result = <TileCoordinates>[];
    
    for (int z = minZoom; z <= maxZoom; z++) {
      final minX = _longitudeToTileX(bounds.southWest.longitude, z);
      final maxX = _longitudeToTileX(bounds.northEast.longitude, z);
      final minY = _latitudeToTileY(bounds.northEast.latitude, z);
      final maxY = _latitudeToTileY(bounds.southWest.latitude, z);
      
      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          result.add(TileCoordinates(x, y, z));
        }
      }
    }
    
    return result;
  }
  
  /// Converte longitude para coordenada X do tile
  int _longitudeToTileX(double longitude, int zoom) {
    return ((longitude + 180.0) / 360.0 * math.pow(2, zoom)).floor();
  }
  
  /// Converte latitude para coordenada Y do tile
  int _latitudeToTileY(double latitude, int zoom) {
    final latRad = latitude * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * math.pow(2, zoom)).floor();
  }
  
  /// Gera a URL para um tile específico
  String _getUrl(String urlTemplate, TileCoordinates tile) {
    return urlTemplate
      .replaceAll('{z}', '${tile.z}')
      .replaceAll('{x}', '${tile.x}')
      .replaceAll('{y}', '${tile.y}')
      .replaceAll('{s}', _getRandomSubdomain());
  }
  
  /// Retorna um subdomínio aleatório para balanceamento de carga
  String _getRandomSubdomain() {
    final subdomains = ['a', 'b', 'c'];
    return subdomains[math.Random().nextInt(subdomains.length)];
  }
  
  /// Baixa e armazena um tile específico
  Future<bool> _downloadAndCacheTile(String url, TileCoordinates tile) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tileFile = await _getTileFile(tile);
        await tileFile.writeAsBytes(response.bodyBytes);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erro ao baixar tile $tile: $e');
      return false;
    }
  }
  
  /// Obtém o arquivo para um tile específico
  Future<File> _getTileFile(TileCoordinates tile) async {
    await initialize();
    final tileDir = Directory('${_cacheDirectory}/${tile.z}/${tile.x}');
    if (!await tileDir.exists()) {
      await tileDir.create(recursive: true);
    }
    return File('${tileDir.path}/${tile.y}.png');
  }
  
  /// Verifica se um tile está em cache
  Future<bool> isTileCached(TileCoordinates tile) async {
    final file = await _getTileFile(tile);
    return file.exists();
  }
  
  /// Obtém um tile do cache
  Future<Uint8List?> getCachedTile(TileCoordinates tile) async {
    try {
      final file = await _getTileFile(tile);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao ler tile do cache: $e');
      return null;
    }
  }
  
  /// Limpa o cache de mapas
  Future<void> clearCache() async {
    await initialize();
    
    try {
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      _initialized = false;
      await initialize();
    } catch (e) {
      debugPrint('Erro ao limpar cache de mapas: $e');
    }
  }
  
  /// Obtém o tamanho do cache em bytes
  Future<int> getCacheSize() async {
    await initialize();
    
    int totalSize = 0;
    try {
      final cacheDir = Directory(_cacheDirectory);
      if (await cacheDir.exists()) {
        await for (final file in cacheDir.list(recursive: true, followLinks: false)) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao calcular tamanho do cache: $e');
    }
    
    return totalSize;
  }
  
  /// Cria um provedor de tiles com cache
  CachedTileProvider createTileProvider(String urlTemplate) {
    return CachedTileProvider(_getCachedTileAdapter);
  }
  
  /// Adaptador para converter entre tipos de coordenadas
  Future<Uint8List?> _getCachedTileAdapter(Coords<num> coords) async {
    final tile = TileCoordinates(coords.x.toInt(), coords.y.toInt(), coords.z.toInt());
    return await getCachedTile(tile);
  }
  
  /// Baixa e armazena em cache os tiles de mapa para uma região específica
  Future<void> cacheMapRegion({
    required List<double> bounds, // [minLat, minLng, maxLat, maxLng]
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    Function(double)? onProgress,
  }) async {
    final latLngBounds = LatLngBounds(
      LatLng(bounds[0], bounds[1]),
      LatLng(bounds[2], bounds[3]),
    );
    
    await preCacheTiles(urlTemplate, latLngBounds, minZoom, maxZoom, onProgress: onProgress);
  }
}

/// Provedor de tiles que usa o cache local
class CachedTileProvider extends TileProvider {
  final Future<Uint8List?> Function(Coords<num>) _getCachedTile;
  
  CachedTileProvider(this._getCachedTile);
  
  @override
  ImageProvider getImage(Coords<num> coords, TileLayer options) {
    return CachedTileImageProvider(
      urlTemplate: options.urlTemplate ?? '',
      coords: coords,
      getCachedTile: _getCachedTile,
      headers: options.additionalOptions,
    );
  }
  
  @override
  Map<String, String> get headers => {};
}

/// Provedor de imagem para tiles em cache ou rede
class CachedTileImageProvider extends ImageProvider<CachedTileImageProvider> {
  final String urlTemplate;
  final Coords<num> coords;
  final Future<Uint8List?> Function(Coords<num>) getCachedTile;
  final Map<String, String> headers;
  
  CachedTileImageProvider({
    required this.urlTemplate,
    required this.coords,
    required this.getCachedTile,
    this.headers = const {},
  });
  
  @override
  Future<CachedTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedTileImageProvider>(this);
  }
  
  @override
  ImageStreamCompleter loadImage(CachedTileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: 'CachedTileImageProvider',
    );
  }
  
  Future<ui.Codec> _loadAsync(CachedTileImageProvider key, ImageDecoderCallback decode) async {
    try {
      // Primeiro tenta carregar do cache
      final cachedData = await getCachedTile(coords);
      if (cachedData != null) {
        final buffer = await ImmutableBuffer.fromUint8List(cachedData);
        return decode(buffer);
      }
      
      // Se não estiver em cache, carrega da rede
      final url = urlTemplate
          .replaceAll('{x}', coords.x.toString())
          .replaceAll('{y}', coords.y.toString())
          .replaceAll('{z}', coords.z.toString())
          .replaceAll('{s}', _getRandomSubdomain());
      
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }
      
      final buffer = await ImmutableBuffer.fromUint8List(response.bodyBytes);
      return decode(buffer);
    } catch (e) {
      debugPrint('Erro ao carregar tile: $e');
      rethrow;
    }
  }
  
  String _getRandomSubdomain() {
    final subdomains = ['a', 'b', 'c'];
    return subdomains[math.Random().nextInt(subdomains.length)];
  }
  
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedTileImageProvider &&
        other.urlTemplate == urlTemplate &&
        other.coords.x == coords.x &&
        other.coords.y == coords.y &&
        other.coords.z == coords.z;
  }
  
  @override
  int get hashCode => Object.hash(urlTemplate, coords.x, coords.y, coords.z);
}
