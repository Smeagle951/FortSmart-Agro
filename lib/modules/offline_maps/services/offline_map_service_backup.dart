import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:latlong2/latlong.dart';
import '../models/offline_map_model.dart';
import '../models/offline_map_status.dart';
import '../utils/offline_map_utils.dart';
import '../utils/tile_calculator.dart';
import 'tile_download_service.dart';
import '../../../services/database_service.dart';

/// Serviço principal para gerenciamento de mapas offline
class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final TileDownloadService _tileDownloadService = TileDownloadService();
  final Map<String, StreamController<OfflineMapModel>> _downloadStreams = {};

  /// Inicializa o banco de dados
  Future<void> init() async {
    try {
      // Criar tabela se não existir
      await _createTables();
      print('✅ OfflineMapService inicializado com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar OfflineMapService: $e');
      rethrow;
    }
  }

  /// Cria as tabelas necessárias
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS offline_maps (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        talhao_name TEXT NOT NULL,
        fazenda_id TEXT,
        fazenda_name TEXT,
        polygon TEXT NOT NULL,
        area REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'not_downloaded',
        last_download TEXT,
        last_update TEXT,
        zoom_min INTEGER NOT NULL DEFAULT 13,
        zoom_max INTEGER NOT NULL DEFAULT 18,
        local_path TEXT,
        total_tiles INTEGER,
        downloaded_tiles INTEGER,
        error_message TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_offline_maps_talhao_id ON offline_maps(talhao_id);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_offline_maps_status ON offline_maps(status);
    ''');
  }

  /// Obtém o banco de dados
  Future<Database> get database async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  /// Cria um novo mapa offline
  Future<OfflineMapModel> createOfflineMap({
    required String talhaoId,
    required String talhaoName,
    required List<dynamic> polygon,
    required double area,
    String? fazendaId,
    String? fazendaName,
    int zoomMin = 13,
    int zoomMax = 18,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await database;
    
    // Converter polígono para LatLng
    final latLngPolygon = polygon.map((point) {
      if (point is Map) {
        return LatLng(point['latitude'] ?? 0.0, point['longitude'] ?? 0.0);
      }
      return LatLng(0.0, 0.0);
    }).toList();

    final offlineMap = OfflineMapModel.create(
      talhaoId: talhaoId,
      talhaoName: talhaoName,
      polygon: latLngPolygon,
      area: area,
      fazendaId: fazendaId,
      fazendaName: fazendaName,
      zoomMin: zoomMin,
      zoomMax: zoomMax,
      metadata: metadata,
    );

    await db.insert('offline_maps', offlineMap.toMap());
    return offlineMap;
  }

  /// Lista todos os mapas offline
  Future<List<OfflineMapModel>> getAllOfflineMaps() async {
    final db = await database;
    final maps = await db.query('offline_maps', orderBy: 'created_at DESC');
    
    return maps.map((map) => OfflineMapModel.fromMap(map)).toList();
  }

  /// Obtém um mapa offline por ID
  Future<OfflineMapModel?> getOfflineMap(String id) async {
    final db = await database;
    final maps = await db.query(
      'offline_maps',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return OfflineMapModel.fromMap(maps.first);
  }

  /// Obtém mapas offline por talhão
  Future<List<OfflineMapModel>> getOfflineMapsByTalhao(String talhaoId) async {
    final db = await database;
    final maps = await db.query(
      'offline_maps',
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => OfflineMapModel.fromMap(map)).toList();
  }

  /// Atualiza um mapa offline
  Future<void> updateOfflineMap(OfflineMapModel offlineMap) async {
    final db = await database;
    await db.update(
      'offline_maps',
      offlineMap.toMap(),
      where: 'id = ?',
      whereArgs: [offlineMap.id],
    );
  }

  /// Remove um mapa offline
  Future<void> deleteOfflineMap(String id) async {
    final db = await database;
    await db.delete(
      'offline_maps',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Limpar tiles do diretório
    final offlineMap = await getOfflineMap(id);
    if (offlineMap != null) {
      await OfflineMapUtils.cleanupOldTiles(offlineMap.talhaoId);
    }
  }

  /// Inicia download de um mapa offline
  Future<Stream<OfflineMapModel>> downloadOfflineMap(
    String offlineMapId, {
    String mapType = 'satellite',
  }) async {
    final offlineMap = await getOfflineMap(offlineMapId);
    if (offlineMap == null) {
      throw Exception('Mapa offline não encontrado');
    }

    // Criar stream controller se não existir
    if (!_downloadStreams.containsKey(offlineMapId)) {
      _downloadStreams[offlineMapId] = StreamController<OfflineMapModel>.broadcast();
    }

    // Atualizar status para downloading
    final updatedMap = offlineMap.copyWith(
      status: OfflineMapStatus.downloading,
      updatedAt: DateTime.now(),
    );
    await updateOfflineMap(updatedMap);
    _downloadStreams[offlineMapId]!.add(updatedMap);

    try {
      // Calcular tiles necessários
      final totalTiles = TileCalculator.calculateTotalTiles(
        polygon: offlineMap.polygon,
        zoomMin: offlineMap.zoomMin,
        zoomMax: offlineMap.zoomMax,
      );

      // Atualizar total de tiles
      final mapWithTotalTiles = updatedMap.copyWith(
        totalTiles: totalTiles,
        downloadedTiles: 0,
      );
      await updateOfflineMap(mapWithTotalTiles);
      _downloadStreams[offlineMapId]!.add(mapWithTotalTiles);

      // Fazer download dos tiles
      final result = await _tileDownloadService.downloadTalhaoTiles(
        offlineMap: mapWithTotalTiles,
        mapType: mapType,
        onProgress: (downloaded, total) {
          final progressMap = mapWithTotalTiles.copyWith(
            downloadedTiles: downloaded,
          );
          updateOfflineMap(progressMap);
          _downloadStreams[offlineMapId]!.add(progressMap);
        },
        onComplete: () {
          final completedMap = mapWithTotalTiles.copyWith(
            status: OfflineMapStatus.downloaded,
            lastDownload: DateTime.now(),
            downloadedTiles: totalTiles,
          );
          updateOfflineMap(completedMap);
          _downloadStreams[offlineMapId]!.add(completedMap);
          _downloadStreams[offlineMapId]!.close();
          _downloadStreams.remove(offlineMapId);
        },
        onError: (error) {
          final errorMap = mapWithTotalTiles.copyWith(
            status: OfflineMapStatus.error,
            errorMessage: error,
          );
          updateOfflineMap(errorMap);
          _downloadStreams[offlineMapId]!.add(errorMap);
          _downloadStreams[offlineMapId]!.close();
          _downloadStreams.remove(offlineMapId);
        },
      );

      return _downloadStreams[offlineMapId]!.stream;
    } catch (e) {
      final errorMap = updatedMap.copyWith(
        status: OfflineMapStatus.error,
        errorMessage: e.toString(),
      );
      await updateOfflineMap(errorMap);
      _downloadStreams[offlineMapId]!.add(errorMap);
      _downloadStreams[offlineMapId]!.close();
      _downloadStreams.remove(offlineMapId);
      rethrow;
    }
  }

  /// Pausa download de um mapa offline
  Future<void> pauseDownload(String offlineMapId) async {
    final offlineMap = await getOfflineMap(offlineMapId);
    if (offlineMap == null) return;

    final pausedMap = offlineMap.copyWith(
      status: OfflineMapStatus.paused,
      updatedAt: DateTime.now(),
    );
    await updateOfflineMap(pausedMap);

    // Fechar stream se existir
    if (_downloadStreams.containsKey(offlineMapId)) {
      _downloadStreams[offlineMapId]!.close();
      _downloadStreams.remove(offlineMapId);
    }
  }

  /// Retoma download de um mapa offline
  Future<Stream<OfflineMapModel>> resumeDownload(
    String offlineMapId, {
    String mapType = 'satellite',
  }) async {
    return downloadOfflineMap(offlineMapId, mapType: mapType);
  }

  /// Verifica se um talhão tem mapas offline
  Future<bool> hasOfflineMaps(String talhaoId) async {
    final maps = await getOfflineMapsByTalhao(talhaoId);
    return maps.any((map) => map.status == OfflineMapStatus.downloaded);
  }

  /// Obtém estatísticas de uso
  Future<Map<String, dynamic>> getStorageStats() async {
    final stats = await OfflineMapUtils.getStorageStats();
    final maps = await getAllOfflineMaps();
    
    int totalMaps = maps.length;
    int downloadedMaps = maps.where((m) => m.status == OfflineMapStatus.downloaded).length;
    int downloadingMaps = maps.where((m) => m.status == OfflineMapStatus.downloading).length;
    
    return {
      ...stats,
      'totalMaps': totalMaps,
      'downloadedMaps': downloadedMaps,
      'downloadingMaps': downloadingMaps,
    };
  }

  /// Limpa mapas antigos
  Future<void> cleanupOldMaps({int daysOld = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final oldMaps = await db.query(
      'offline_maps',
      where: 'created_at < ? AND status = ?',
      whereArgs: [cutoffDate.toIso8601String(), OfflineMapStatus.notDownloaded.name],
    );

    for (final map in oldMaps) {
      await deleteOfflineMap(map['id'] as String);
    }
  }

  /// Fecha o serviço
  Future<void> dispose() async {
    for (final controller in _downloadStreams.values) {
      await controller.close();
    }
    _downloadStreams.clear();
    await _database?.close();
    _database = null;
  }
}
