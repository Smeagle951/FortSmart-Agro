import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';
import '../utils/api_config.dart';

/// Serviço unificado para mapas offline com integração completa
class EnhancedOfflineMapService {
  static final EnhancedOfflineMapService _instance = EnhancedOfflineMapService._internal();
  factory EnhancedOfflineMapService() => _instance;
  EnhancedOfflineMapService._internal();

  static const String _cacheDirName = 'enhanced_map_cache';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB para fazendas completas
  static const Duration _tileExpiration = Duration(days: 30); // Cache mais longo
  
  Directory? _cacheDir;
  Database? _database;
  Map<String, DateTime> _tileTimestamps = {};
  
  /// Inicializa o serviço completo
  Future<void> initialize() async {
    try {
      // Inicializar diretório de cache
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      // Inicializar banco de dados
      await _initializeDatabase();
      
      // Carregar timestamps
      await _loadTileTimestamps();
      
      // Limpeza automática
      await _cleanupExpiredTiles();
      
      Logger.info('🗺️ EnhancedOfflineMapService inicializado: ${_cacheDir!.path}');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar EnhancedOfflineMapService: $e');
    }
  }
  
  /// Inicializa banco de dados SQLite
  Future<void> _initializeDatabase() async {
    final dbPath = '${_cacheDir!.path}/offline_maps.db';
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreateDatabase,
    );
  }
  
  /// Cria tabelas do banco de dados
  Future<void> _onCreateDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE map_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        southwest_lat REAL NOT NULL,
        southwest_lng REAL NOT NULL,
        northeast_lat REAL NOT NULL,
        northeast_lng REAL NOT NULL,
        min_zoom INTEGER NOT NULL,
        max_zoom INTEGER NOT NULL,
        map_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_sync TEXT,
        status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    
    await db.execute('''
      CREATE TABLE tile_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        z INTEGER NOT NULL,
        map_type TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        last_accessed TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE sync_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        area_id INTEGER NOT NULL,
        sync_type TEXT NOT NULL,
        status TEXT NOT NULL,
        tiles_downloaded INTEGER NOT NULL,
        total_size INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (area_id) REFERENCES map_areas (id)
      )
    ''');
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
      Logger.error('❌ Erro ao carregar timestamps: $e');
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
      Logger.error('❌ Erro ao salvar timestamps: $e');
    }
  }
  
  /// Gera chave única para o tile
  String _generateTileKey(int x, int y, int z, String mapType) {
    final key = '${mapType}_${z}_${x}_${y}';
    return md5.convert(utf8.encode(key)).toString();
  }
  
  /// Obtém caminho do arquivo de cache
  String _getTilePath(String tileKey) {
    return '${_cacheDir!.path}/$tileKey.png';
  }
  
  /// Verifica se o tile está em cache
  Future<bool> isTileCached(int x, int y, int z, String mapType) async {
    try {
      final tileKey = _generateTileKey(x, y, z, mapType);
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      if (!await tileFile.exists()) return false;
      
      // Verificar se não expirou
      final timestamp = _tileTimestamps[tileKey];
      if (timestamp == null) return false;
      
      final age = DateTime.now().difference(timestamp);
      return age < _tileExpiration;
    } catch (e) {
      Logger.error('❌ Erro ao verificar tile em cache: $e');
      return false;
    }
  }
  
  /// Obtém tile do cache
  Future<File?> getCachedTile(int x, int y, int z, String mapType) async {
    try {
      if (!await isTileCached(x, y, z, mapType)) return null;
      
      final tileKey = _generateTileKey(x, y, z, mapType);
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      if (await tileFile.exists()) {
        // Atualizar timestamp de acesso
        _tileTimestamps[tileKey] = DateTime.now();
        await _saveTileTimestamps();
        
        return tileFile;
      }
    } catch (e) {
      Logger.error('❌ Erro ao obter tile do cache: $e');
    }
    return null;
  }
  
  /// Baixa e armazena tile no cache
  Future<bool> cacheTile(int x, int y, int z, String mapType) async {
    try {
      final tileKey = _generateTileKey(x, y, z, mapType);
      final tilePath = _getTilePath(tileKey);
      final tileFile = File(tilePath);
      
      // Usar APIConfig para obter URL correta
      String url;
      if (APIConfig.isMapTilerConfigured()) {
        url = APIConfig.getMapTilerUrl(mapType)
            .replaceAll('{z}', z.toString())
            .replaceAll('{x}', x.toString())
            .replaceAll('{y}', y.toString());
      } else {
        // Fallback para OpenStreetMap
        url = APIConfig.getFallbackUrl()
            .replaceAll('{z}', z.toString())
            .replaceAll('{x}', x.toString())
            .replaceAll('{y}', y.toString());
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await tileFile.writeAsBytes(response.bodyBytes);
        
        // Atualizar timestamp
        _tileTimestamps[tileKey] = DateTime.now();
        await _saveTileTimestamps();
        
        // Registrar no banco de dados
        await _database!.insert('tile_cache', {
          'x': x,
          'y': y,
          'z': z,
          'map_type': mapType,
          'file_path': tilePath,
          'file_size': response.bodyBytes.length,
          'created_at': DateTime.now().toIso8601String(),
          'last_accessed': DateTime.now().toIso8601String(),
        });
        
        // Verificar tamanho do cache
        await _checkCacheSize();
        
        Logger.info('✅ Tile cacheado: $tileKey');
        return true;
      }
    } catch (e) {
      Logger.error('❌ Erro ao cachear tile: $e');
    }
    return false;
  }
  
  /// Download de área completa para fazenda
  Future<Map<String, dynamic>> downloadFarmArea({
    required String farmName,
    required LatLng southwest,
    required LatLng northeast,
    int minZoom = 10,
    int maxZoom = 18,
    String mapType = 'satellite',
    Function(double)? onProgress,
  }) async {
    try {
      Logger.info('🌾 Iniciando download de fazenda: $farmName');
      
      // Registrar área no banco
      final areaId = await _database!.insert('map_areas', {
        'name': farmName,
        'southwest_lat': southwest.latitude,
        'southwest_lng': southwest.longitude,
        'northeast_lat': northeast.latitude,
        'northeast_lng': northeast.longitude,
        'min_zoom': minZoom,
        'max_zoom': maxZoom,
        'map_type': mapType,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'downloading',
      });
      
      // Calcular tiles necessários
      final tiles = _calculateTilesForArea(southwest, northeast, minZoom, maxZoom);
      final totalTiles = tiles.length;
      int downloadedTiles = 0;
      int failedTiles = 0;
      int totalSize = 0;
      
      Logger.info('📊 Total de tiles para download: $totalTiles');
      
      for (final tile in tiles) {
        try {
          final x = tile['x'] as int;
          final y = tile['y'] as int;
          final z = tile['z'] as int;
          
          if (!await isTileCached(x, y, z, mapType)) {
            final success = await cacheTile(x, y, z, mapType);
            if (success) {
              downloadedTiles++;
              // Estimativa de tamanho
              totalSize += 15 * 1024; // ~15KB por tile
            } else {
              failedTiles++;
            }
          } else {
            downloadedTiles++;
          }
          
          // Atualizar progresso
          if (onProgress != null) {
            onProgress(downloadedTiles / totalTiles);
          }
          
          // Pequena pausa para não sobrecarregar
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failedTiles++;
          Logger.error('❌ Erro ao baixar tile: $e');
        }
      }
      
      // Atualizar status da área
      await _database!.update(
        'map_areas',
        {
          'status': failedTiles == 0 ? 'completed' : 'partial',
          'last_sync': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [areaId],
      );
      
      // Registrar sincronização
      await _database!.insert('sync_history', {
        'area_id': areaId,
        'sync_type': 'download',
        'status': failedTiles == 0 ? 'success' : 'partial',
        'tiles_downloaded': downloadedTiles,
        'total_size': totalSize,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      final result = {
        'success': downloadedTiles > 0,
        'totalTiles': totalTiles,
        'downloadedTiles': downloadedTiles,
        'failedTiles': failedTiles,
        'totalSize': totalSize,
        'areaId': areaId,
        'farmName': farmName,
      };
      
      Logger.info('✅ Download de fazenda concluído: $downloadedTiles/$totalTiles tiles');
      return result;
    } catch (e) {
      Logger.error('❌ Erro no download de fazenda: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Calcula tiles necessários para uma área
  List<Map<String, int>> _calculateTilesForArea(
    LatLng southwest,
    LatLng northeast,
    int minZoom,
    int maxZoom,
  ) {
    final tiles = <Map<String, int>>[];
    
    for (int z = minZoom; z <= maxZoom; z++) {
      final minTile = _latLngToTile(southwest.latitude, southwest.longitude, z);
      final maxTile = _latLngToTile(northeast.latitude, northeast.longitude, z);
      
      final minX = minTile['x'] as int;
      final maxX = maxTile['x'] as int;
      final minY = minTile['y'] as int;
      final maxY = maxTile['y'] as int;
      
      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          tiles.add({'x': x, 'y': y, 'z': z});
        }
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
  
  /// Funções matemáticas
  double radians(double degrees) => degrees * pi / 180;
  double log(double x) => log(x);
  double cos(double x) => cos(x);
  double tan(double x) => tan(x);
  
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
      Logger.error('❌ Erro ao verificar tamanho do cache: $e');
    }
  }
  
  /// Remove tiles antigos para liberar espaço
  Future<void> _cleanupOldTiles() async {
    try {
      // Buscar tiles mais antigos no banco
      final oldTiles = await _database!.query(
        'tile_cache',
        orderBy: 'last_accessed ASC',
        limit: 100, // Remover 100 tiles por vez
      );
      
      for (final tile in oldTiles) {
        final filePath = tile['file_path'] as String;
        final file = File(filePath);
        
        if (await file.exists()) {
          await file.delete();
        }
        
        await _database!.delete(
          'tile_cache',
          where: 'id = ?',
          whereArgs: [tile['id']],
        );
      }
      
      Logger.info('🧹 Removidos ${oldTiles.length} tiles antigos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar tiles antigos: $e');
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
        Logger.info('🧹 Removidos ${expiredKeys.length} tiles expirados');
      }
    } catch (e) {
      Logger.error('❌ Erro ao limpar tiles expirados: $e');
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
      Logger.error('❌ Erro ao remover tile: $e');
    }
  }
  
  /// Obtém estatísticas completas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final result = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_tiles,
          SUM(file_size) as total_size,
          COUNT(DISTINCT map_type) as map_types,
          COUNT(DISTINCT z) as zoom_levels
        FROM tile_cache
      ''');
      
      final areaResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_areas,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_areas
        FROM map_areas
      ''');
      
      final totalSize = result.first['total_size'] as int? ?? 0;
      final totalTiles = result.first['total_tiles'] as int? ?? 0;
      final totalAreas = areaResult.first['total_areas'] as int? ?? 0;
      final completedAreas = areaResult.first['completed_areas'] as int? ?? 0;
      
      return {
        'totalTiles': totalTiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).round(),
        'maxSizeMB': (_maxCacheSize / (1024 * 1024)).round(),
        'usagePercentage': (totalSize / _maxCacheSize * 100).round(),
        'mapTypes': result.first['map_types'] as int? ?? 0,
        'zoomLevels': result.first['zoom_levels'] as int? ?? 0,
        'totalAreas': totalAreas,
        'completedAreas': completedAreas,
        'isWorking': totalTiles > 0,
        'cachePath': _cacheDir?.path ?? 'Não inicializado',
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas: $e');
      return {
        'error': e.toString(),
        'isWorking': false,
      };
    }
  }
  
  /// Lista áreas baixadas
  Future<List<Map<String, dynamic>>> getDownloadedAreas() async {
    try {
      final result = await _database!.query(
        'map_areas',
        orderBy: 'created_at DESC',
      );
      
      return result.map((row) => {
        'id': row['id'],
        'name': row['name'],
        'southwest': LatLng(row['southwest_lat'] as double, row['southwest_lng'] as double),
        'northeast': LatLng(row['northeast_lat'] as double, row['northeast_lng'] as double),
        'minZoom': row['min_zoom'],
        'maxZoom': row['max_zoom'],
        'mapType': row['map_type'],
        'status': row['status'],
        'createdAt': row['created_at'],
        'lastSync': row['last_sync'],
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar áreas: $e');
      return [];
    }
  }
  
  /// Limpa todo o cache
  Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
      }
      
      if (_database != null) {
        await _database!.delete('tile_cache');
        await _database!.delete('map_areas');
        await _database!.delete('sync_history');
      }
      
      _tileTimestamps.clear();
      await _saveTileTimestamps();
      
      Logger.info('🧹 Cache limpo completamente');
    } catch (e) {
      Logger.error('❌ Erro ao limpar cache: $e');
    }
  }
  
  /// Verifica se o cache está funcionando offline
  Future<bool> isOfflineCacheWorking() async {
    try {
      final stats = await getCacheStats();
      return stats['isWorking'] == true && stats['totalTiles'] > 0;
    } catch (e) {
      Logger.error('❌ Erro ao verificar cache offline: $e');
      return false;
    }
  }

  /// Obtém estatísticas de armazenamento
  Map<String, dynamic> getStorageStats() {
    try {
      final stats = <String, dynamic>{};
      
      // Calcular tamanho do diretório de cache
      if (_cacheDir != null && _cacheDir!.existsSync()) {
        int totalSize = 0;
        final files = _cacheDir!.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        }
        stats['cacheSize'] = totalSize;
        stats['cacheSizeMB'] = (totalSize / (1024 * 1024)).toStringAsFixed(2);
      }
      
      // Número de tiles
      stats['totalTiles'] = _tileTimestamps.length;
      
      return stats;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de armazenamento: $e');
      return {};
    }
  }

  /// Obtém fila de download (placeholder)
  List<Map<String, dynamic>> getDownloadQueue() {
    // Implementação placeholder - retorna lista vazia
    return [];
  }

  /// Obtém histórico de downloads (placeholder)
  List<Map<String, dynamic>> getDownloadHistory() {
    // Implementação placeholder - retorna lista vazia
    return [];
  }

  /// Adiciona área à fila de download (placeholder)
  Future<void> addToDownloadQueue(String areaId, Map<String, dynamic> options) async {
    Logger.info('📥 Adicionando área $areaId à fila de download');
    // Implementação placeholder
  }

  /// Atualiza área (placeholder)
  Future<void> updateArea(String areaId) async {
    Logger.info('🔄 Atualizando área $areaId');
    // Implementação placeholder
  }
}
