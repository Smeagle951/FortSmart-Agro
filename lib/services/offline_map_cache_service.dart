import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

/// Serviço para cache offline de tiles do MapTiler
class OfflineMapCacheService {
  static final OfflineMapCacheService _instance = OfflineMapCacheService._internal();
  factory OfflineMapCacheService() => _instance;
  OfflineMapCacheService._internal();

  static const String _cacheDirName = 'map_cache';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _tileExpiration = Duration(days: 30);
  
  Directory? _cacheDir;
  Map<String, DateTime> _tileTimestamps = {};
  
  /// Inicializa o cache
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      await _loadTileTimestamps();
      await _cleanupExpiredTiles();
      
      Logger.info('Cache offline inicializado: ${_cacheDir!.path}');
    } catch (e) {
      Logger.error('Erro ao inicializar cache offline: $e');
    }
  }
  
  /// Gera chave única para o tile
  String _generateTileKey(int x, int y, int z, String style) {
    final key = '${style}_${z}_${x}_${y}';
    return md5.convert(utf8.encode(key)).toString();
  }
  
  /// Obtém caminho do arquivo de cache
  String _getTilePath(String tileKey) {
    return '${_cacheDir!.path}/$tileKey.png';
  }
  
  /// Carrega timestamps dos tiles
  Future<void> _loadTileTimestamps() async {
    try {
      final timestampFile = File('${_cacheDir!.path}/timestamps.json');
      if (await timestampFile.exists()) {
        final content = await timestampFile.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        _tileTimestamps = data.map((key, value) => 
          MapEntry(key, DateTime.parse(value)));
      }
    } catch (e) {
      Logger.error('Erro ao carregar timestamps: $e');
    }
  }
  
  /// Salva timestamps dos tiles
  Future<void> _saveTileTimestamps() async {
    try {
      final timestampFile = File('${_cacheDir!.path}/timestamps.json');
      final data = _tileTimestamps.map((key, value) => 
        MapEntry(key, value.toIso8601String()));
      await timestampFile.writeAsString(json.encode(data));
    } catch (e) {
      Logger.error('Erro ao salvar timestamps: $e');
    }
  }
  
  /// Verifica se o tile está em cache
  Future<bool> isTileCached(int x, int y, int z, String style) async {
    try {
      final tileKey = _generateTileKey(x, y, z, style);
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      if (!await tileFile.exists()) return false;
      
      // Verificar se não expirou
      final timestamp = _tileTimestamps[tileKey];
      if (timestamp == null) return false;
      
      final age = DateTime.now().difference(timestamp);
      return age < _tileExpiration;
    } catch (e) {
      Logger.error('Erro ao verificar tile em cache: $e');
      return false;
    }
  }
  
  /// Obtém tile do cache
  Future<File?> getCachedTile(int x, int y, int z, String style) async {
    try {
      if (!await isTileCached(x, y, z, style)) return null;
      
      final tileKey = _generateTileKey(x, y, z, style);
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      if (await tileFile.exists()) {
        return tileFile;
      }
    } catch (e) {
      Logger.error('Erro ao obter tile do cache: $e');
    }
    return null;
  }
  
  /// Baixa e armazena tile no cache
  Future<bool> cacheTile(int x, int y, int z, String style, String apiKey) async {
    try {
      final tileKey = _generateTileKey(x, y, z, style);
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      // URL do MapTiler
      final url = 'https://api.maptiler.com/tiles/$style/$z/$x/$y.png?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await tileFile.writeAsBytes(response.bodyBytes);
        
        // Atualizar timestamp
        _tileTimestamps[tileKey] = DateTime.now();
        await _saveTileTimestamps();
        
        // Verificar tamanho do cache
        await _checkCacheSize();
        
        Logger.info('Tile cacheado: $tileKey');
        return true;
      }
    } catch (e) {
      Logger.error('Erro ao cachear tile: $e');
    }
    return false;
  }
  
  /// Verifica e limita tamanho do cache
  Future<void> _checkCacheSize() async {
    try {
      int totalSize = 0;
      final files = await _cacheDir!.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          totalSize += await file.length();
        }
      }
      
      if (totalSize > _maxCacheSize) {
        await _cleanupOldTiles();
      }
    } catch (e) {
      Logger.error('Erro ao verificar tamanho do cache: $e');
    }
  }
  
  /// Remove tiles expirados
  Future<void> _cleanupExpiredTiles() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      for (final entry in _tileTimestamps.entries) {
        final age = now.difference(entry.value);
        if (age > _tileExpiration) {
          expiredKeys.add(entry.key);
        }
      }
      
      for (final key in expiredKeys) {
        await _removeTile(key);
      }
      
      if (expiredKeys.isNotEmpty) {
        Logger.info('Removidos ${expiredKeys.length} tiles expirados');
      }
    } catch (e) {
      Logger.error('Erro ao limpar tiles expirados: $e');
    }
  }
  
  /// Remove tiles antigos para liberar espaço
  Future<void> _cleanupOldTiles() async {
    try {
      // Ordenar por timestamp (mais antigos primeiro)
      final sortedEntries = _tileTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // Remover 20% dos tiles mais antigos
      final removeCount = (sortedEntries.length * 0.2).round();
      
      for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
        await _removeTile(sortedEntries[i].key);
      }
      
      Logger.info('Removidos $removeCount tiles antigos para liberar espaço');
    } catch (e) {
      Logger.error('Erro ao limpar tiles antigos: $e');
    }
  }
  
  /// Remove um tile específico
  Future<void> _removeTile(String tileKey) async {
    try {
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      if (await tileFile.exists()) {
        await tileFile.delete();
      }
      
      _tileTimestamps.remove(tileKey);
    } catch (e) {
      Logger.error('Erro ao remover tile: $e');
    }
  }
  
  /// Limpa todo o cache
  Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
      }
      
      _tileTimestamps.clear();
      await _saveTileTimestamps();
      
      Logger.info('Cache limpo completamente');
    } catch (e) {
      Logger.error('Erro ao limpar cache: $e');
    }
  }
  
  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      int totalFiles = 0;
      int totalSize = 0;
      int validFiles = 0;
      
      if (_cacheDir != null && await _cacheDir!.exists()) {
        final files = await _cacheDir!.list().toList();
        
        for (final file in files) {
          if (file is File && file.path.endsWith('.png')) {
            totalFiles++;
            final fileSize = await file.length();
            totalSize += fileSize;
            
            // Verificar se o arquivo é válido (não corrompido)
            if (fileSize > 0) {
              validFiles++;
            }
          }
        }
      }
      
      return {
        'totalFiles': totalFiles,
        'validFiles': validFiles,
        'totalSize': totalSize,
        'maxSize': _maxCacheSize,
        'usagePercentage': (totalSize / _maxCacheSize * 100).round(),
        'cachePath': _cacheDir?.path ?? 'Não inicializado',
        'isWorking': validFiles > 0,
        'lastUpdated': _tileTimestamps.isNotEmpty 
            ? _tileTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
            : null,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do cache: $e');
      return {
        'error': e.toString(),
        'isWorking': false,
      };
    }
  }

  /// Verifica se o cache está funcionando offline
  Future<bool> isOfflineCacheWorking() async {
    try {
      final stats = await getCacheStats();
      return stats['isWorking'] == true && stats['validFiles'] > 0;
    } catch (e) {
      Logger.error('❌ Erro ao verificar cache offline: $e');
      return false;
    }
  }

  /// Testa o cache offline baixando uma área pequena
  Future<bool> testOfflineCache(String apiKey) async {
    try {
      Logger.info('🧪 Testando cache offline...');
      
      // Área pequena para teste (Brasília)
      const testArea = {
        'minLat': -15.8,
        'maxLat': -15.7,
        'minLng': -47.9,
        'maxLng': -47.8,
      };
      
      await preloadArea(
        testArea['minLat']!,
        testArea['maxLat']!,
        testArea['minLng']!,
        testArea['maxLng']!,
        10, // zoom baixo para teste
        12, // zoom médio para teste
        'streets-v2',
        apiKey,
      );
      
      final isWorking = await isOfflineCacheWorking();
      Logger.info('✅ Teste de cache offline: ${isWorking ? 'SUCESSO' : 'FALHA'}');
      
      return isWorking;
    } catch (e) {
      Logger.error('❌ Erro no teste de cache offline: $e');
      return false;
    }
  }
  
  /// Pré-carrega tiles para uma área específica
  Future<void> preloadArea(
    double minLat, 
    double maxLat, 
    double minLng, 
    double maxLng, 
    int minZoom, 
    int maxZoom, 
    String style, 
    String apiKey, {
    Function(double)? onProgress,
  }) async {
    try {
      Logger.info('🔄 Iniciando pré-carregamento de área...');
      
      // Calcular total de tiles
      int totalTiles = 0;
      for (int z = minZoom; z <= maxZoom; z++) {
        final tiles = _getTilesForBounds(minLat, maxLat, minLng, maxLng, z);
        totalTiles += tiles.length;
      }
      
      int downloadedTiles = 0;
      
      for (int z = minZoom; z <= maxZoom; z++) {
        final tiles = _getTilesForBounds(minLat, maxLat, minLng, maxLng, z);
        
        for (final tile in tiles) {
          final x = tile['x'] as int;
          final y = tile['y'] as int;
          
          if (!await isTileCached(x, y, z, style)) {
            final success = await cacheTile(x, y, z, style, apiKey);
            if (success) {
              downloadedTiles++;
              
              // Atualizar progresso
              if (onProgress != null) {
                onProgress(downloadedTiles / totalTiles);
              }
            }
          } else {
            downloadedTiles++;
          }
          
          // Pequena pausa para não sobrecarregar
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      
      Logger.info('✅ Pré-carregamento concluído: $downloadedTiles/$totalTiles tiles');
    } catch (e) {
      Logger.error('❌ Erro no pré-carregamento: $e');
      rethrow;
    }
  }
  
  /// Calcula tiles necessários para uma área
  List<Map<String, int>> _getTilesForBounds(
    double minLat, 
    double maxLat, 
    double minLng, 
    double maxLng, 
    int zoom
  ) {
    final tiles = <Map<String, int>>[];
    
    final minTile = _latLngToTile(minLat, minLng, zoom);
    final maxTile = _latLngToTile(maxLat, maxLng, zoom);
    
    final minX = minTile['x'] as int;
    final maxX = maxTile['x'] as int;
    final minY = minTile['y'] as int;
    final maxY = maxTile['y'] as int;
    
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        tiles.add({'x': x, 'y': y, 'z': zoom});
      }
    }
    
    return tiles;
  }
  
  /// Converte lat/lng para coordenadas de tile
  Map<String, int> _latLngToTile(double lat, double lng, int zoom) {
    final n = pow(2.0, zoom).toDouble();
    final xtile = ((lng + 180) / 360 * n).floor();
    final ytile = ((1 - log(tan(radians(lat)) + 1 / cos(radians(lat))) / pi) / 2 * n).floor();
    
    return {'x': xtile, 'y': ytile};
  }
  
  double radians(double degrees) => degrees * pi / 180;
  double log(double x) => log(x);
  double cos(double x) => cos(x);
  double tan(double x) => tan(x);
} 