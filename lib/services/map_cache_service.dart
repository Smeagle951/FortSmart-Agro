import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import '../utils/maptiler_constants.dart';

/// Serviço para gerenciar cache de mapas offline
class MapCacheService {
  static const String _cacheTableName = 'map_tiles_cache';
  static const String _cacheIndexTableName = 'map_tiles_cache_index';
  static const String _syncTableName = 'historico_sincronizacao';
  
  Database? _database;
  final String _baseUrl = 'https://api.maptiler.com/maps/satellite/256';
  
  /// Inicializa o serviço de cache
  Future<void> initialize() async {
    if (_database != null) return;
    
    final dbPath = await _getDatabasePath();
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
    
    print('🗺️ MapCacheService inicializado');
  }
  
  /// Cria as tabelas necessárias
  Future<void> _onCreate(Database db, int version) async {
    // Tabela principal de cache de tiles
    await db.execute('''
      CREATE TABLE $_cacheTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        z INTEGER NOT NULL,
        tile_data BLOB NOT NULL,
        created_at TEXT NOT NULL,
        last_accessed TEXT NOT NULL,
        UNIQUE(x, y, z)
      )
    ''');
    
    // Tabela de índice para busca rápida
    await db.execute('''
      CREATE TABLE $_cacheIndexTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        z INTEGER NOT NULL,
        file_path TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(x, y, z)
      )
    ''');
    
    // Tabela de histórico de sincronização
    await db.execute('''
      CREATE TABLE $_syncTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_type TEXT NOT NULL,
        status TEXT NOT NULL,
        data_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        error_message TEXT
      )
    ''');
    
    // Criar índices para performance
    await db.execute('CREATE INDEX idx_tiles_coords ON $_cacheTableName (x, y, z)');
    await db.execute('CREATE INDEX idx_tiles_created ON $_cacheTableName (created_at)');
    await db.execute('CREATE INDEX idx_sync_type ON $_syncTableName (sync_type)');
    
    print('🗺️ Tabelas de cache de mapa criadas');
  }
  
  /// Obtém o caminho do banco de dados
  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/map_cache.db';
  }
  
  /// Verifica se um tile está em cache
  Future<bool> isTileCached(int x, int y, int z) async {
    await initialize();
    
    final result = await _database!.query(
      _cacheTableName,
      where: 'x = ? AND y = ? AND z = ?',
      whereArgs: [x, y, z],
      limit: 1,
    );
    
    return result.isNotEmpty;
  }
  
  /// Obtém um tile do cache
  Future<Uint8List?> getTile(int x, int y, int z) async {
    await initialize();
    
    final result = await _database!.query(
      _cacheTableName,
      columns: ['tile_data'],
      where: 'x = ? AND y = ? AND z = ?',
      whereArgs: [x, y, z],
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      // Atualizar último acesso
      await _database!.update(
        _cacheTableName,
        {'last_accessed': DateTime.now().toIso8601String()},
        where: 'x = ? AND y = ? AND z = ?',
        whereArgs: [x, y, z],
      );
      
      return result.first['tile_data'] as Uint8List;
    }
    
    return null;
  }
  
  /// Salva um tile no cache
  Future<void> saveTile(int x, int y, int z, Uint8List tileData) async {
    await initialize();
    
    final now = DateTime.now().toIso8601String();
    
    await _database!.insert(
      _cacheTableName,
      {
        'x': x,
        'y': y,
        'z': z,
        'tile_data': tileData,
        'created_at': now,
        'last_accessed': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// Baixa um tile da internet e salva no cache
  Future<Uint8List?> downloadAndCacheTile(int x, int y, int z) async {
    try {
      final url = '$_baseUrl/$z/$x/$y.png';
      print('🔄 Baixando tile: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FortSmartAgro/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final tileData = response.bodyBytes;
        await saveTile(x, y, z, tileData);
        print('✅ Tile $z/$x/$y baixado com sucesso');
        return tileData;
      } else {
        print('❌ Erro HTTP ${response.statusCode} ao baixar tile $z/$x/$y');
      }
    } catch (e) {
      print('❌ Erro ao baixar tile $z/$x/$y: $e');
    }
    
    return null;
  }
  
  /// Calcula tiles necessários para uma área
  List<Map<String, int>> calculateTilesForArea(
    LatLng southwest,
    LatLng northeast,
    int minZoom,
    int maxZoom,
  ) {
    final tiles = <Map<String, int>>[];
    
    for (int z = minZoom; z <= maxZoom; z++) {
      final minTile = _latLngToTile(southwest, z);
      final maxTile = _latLngToTile(northeast, z);
      
      for (int x = minTile['x']!; x <= maxTile['x']!; x++) {
        for (int y = minTile['y']!; y <= maxTile['y']!; y++) {
          tiles.add({'x': x, 'y': y, 'z': z});
        }
      }
    }
    
    return tiles;
  }
  
  /// Converte coordenadas para tile
  Map<String, int> _latLngToTile(LatLng latLng, int zoom) {
    final n = pow(2.0, zoom.toDouble());
    final xtile = ((latLng.longitude + 180) / 360 * n).floor();
    final ytile = ((1 - log(tan(latLng.latitude * pi / 180) + 1 / cos(latLng.latitude * pi / 180)) / pi) / 2 * n).floor();
    
    return {'x': xtile, 'y': ytile};
  }
  
  /// Baixa área completa para cache offline
  Future<Map<String, dynamic>> downloadAreaForOffline({
    required LatLng southwest,
    required LatLng northeast,
    required int minZoom,
    required int maxZoom,
    Function(int current, int total)? onProgress,
  }) async {
    await initialize();
    
    final tiles = calculateTilesForArea(southwest, northeast, minZoom, maxZoom);
    final totalTiles = tiles.length;
    int downloadedTiles = 0;
    int failedTiles = 0;
    
    print('🗺️ Iniciando download de $totalTiles tiles para cache offline...');
    
    for (final tile in tiles) {
      try {
        final tileData = await downloadAndCacheTile(
          tile['x']!,
          tile['y']!,
          tile['z']!,
        );
        
        if (tileData != null) {
          downloadedTiles++;
        } else {
          failedTiles++;
        }
        
        onProgress?.call(downloadedTiles, totalTiles);
        
        // Pequena pausa para não sobrecarregar o servidor
        await Future.delayed(Duration(milliseconds: 50));
      } catch (e) {
        failedTiles++;
        print('❌ Erro ao baixar tile: $e');
      }
    }
    
    // Registrar sincronização
    await _recordSync('map_download', 'completed', downloadedTiles);
    
    return {
      'total': totalTiles,
      'downloaded': downloadedTiles,
      'failed': failedTiles,
      'success': downloadedTiles > 0,
    };
  }
  
  /// Verifica se o cache está atualizado
  Future<bool> isCacheUpToDate() async {
    await initialize();
    
    final result = await _database!.query(
      _syncTableName,
      where: 'sync_type = ? AND status = ?',
      whereArgs: ['map_download', 'completed'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (result.isEmpty) return false;
    
    final lastSync = DateTime.parse(result.first['created_at'] as String);
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    // Considera atualizado se foi sincronizado nas últimas 24 horas
    return difference.inHours < 24;
  }
  
  /// Registra uma sincronização
  Future<void> _recordSync(String type, String status, int dataCount, {String? errorMessage}) async {
    await initialize();
    
    await _database!.insert(
      _syncTableName,
      {
        'sync_type': type,
        'status': status,
        'data_count': dataCount,
        'created_at': DateTime.now().toIso8601String(),
        'completed_at': status == 'completed' ? DateTime.now().toIso8601String() : null,
        'error_message': errorMessage,
      },
    );
  }
  
  /// Limpa cache antigo (mais de 7 dias)
  Future<void> cleanupOldCache() async {
    await initialize();
    
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7)).toIso8601String();
    
    final deleted = await _database!.delete(
      _cacheTableName,
      where: 'created_at < ?',
      whereArgs: [sevenDaysAgo],
    );
    
    print('🗑️ Limpados $deleted tiles antigos do cache');
  }
  
  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();
    
    final tileCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM $_cacheTableName')
    ) ?? 0;
    
    final cacheSize = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT SUM(LENGTH(tile_data)) FROM $_cacheTableName')
    ) ?? 0;
    
    final lastSync = await _database!.query(
      _syncTableName,
      where: 'sync_type = ? AND status = ?',
      whereArgs: ['map_download', 'completed'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    return {
      'tileCount': tileCount,
      'cacheSizeMB': (cacheSize / (1024 * 1024)).toStringAsFixed(2),
      'lastSync': lastSync.isNotEmpty ? lastSync.first['created_at'] : null,
      'isUpToDate': await isCacheUpToDate(),
    };
  }
  
  /// Fecha o banco de dados
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
  
  /// Obtém o provedor de tiles para uso offline
  TileProvider getTileProvider() {
    return CachedNetworkTileProvider();
  }
}

/// Classe personalizada para tiles com cache
class CachedNetworkTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      '${options.urlTemplate?.replaceAll('{x}', coordinates.x.toString()).replaceAll('{y}', coordinates.y.toString()).replaceAll('{z}', coordinates.z.toString()) ?? ''}',
      headers: const {'User-Agent': 'FortSmartAgro/1.0'},
    );
  }
}

// Funções auxiliares - usando as funções nativas do dart:math
