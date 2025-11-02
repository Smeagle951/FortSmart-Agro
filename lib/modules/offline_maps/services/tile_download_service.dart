import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/offline_map_model.dart';
import '../utils/offline_map_utils.dart';
import '../utils/tile_calculator.dart';

/// Serviço para download de tiles de mapas
class TileDownloadService {
  static final TileDownloadService _instance = TileDownloadService._internal();
  factory TileDownloadService() => _instance;
  TileDownloadService._internal();

  final String _mapTilerApiKey = 'KQAa9lY3N0TR17zxhk9u'; // Chave do MapTiler do FortSmart
  final int _maxConcurrentDownloads = 3;
  final Duration _timeout = const Duration(seconds: 30);

  /// Download de um tile específico
  Future<bool> downloadTile({
    required String talhaoId,
    required int z,
    required int x,
    required int y,
    String mapType = 'satellite',
    Function(int, int)? onProgress,
  }) async {
    try {
      // Verificar se o tile já existe
      if (await OfflineMapUtils.tileExists(
        talhaoId: talhaoId,
        z: z,
        x: x,
        y: y,
      )) {
        return true;
      }

      // Gerar URL do tile
      final url = OfflineMapUtils.generateMapTilerUrl(
        z: z,
        x: x,
        y: y,
        apiKey: _mapTilerApiKey,
        mapType: mapType,
      );

      // Fazer download
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FortSmartAgro/1.0',
          'Accept': 'image/*',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        // Salvar tile localmente
        final tilePath = await OfflineMapUtils.getTilePath(
          talhaoId: talhaoId,
          z: z,
          x: x,
          y: y,
        );

        // Criar diretório se não existir
        final tileFile = File(tilePath);
        await tileFile.parent.create(recursive: true);

        // Salvar arquivo
        await tileFile.writeAsBytes(response.bodyBytes);
        
        onProgress?.call(1, 1);
        return true;
      } else {
        print('❌ Erro ao baixar tile $z/$x/$y: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao baixar tile $z/$x/$y: $e');
      return false;
    }
  }

  /// Download de múltiplos tiles
  Future<Map<String, int>> downloadTiles({
    required String talhaoId,
    required List<Map<String, int>> tiles,
    String mapType = 'satellite',
    Function(int, int)? onProgress,
    Function()? onComplete,
    Function(String)? onError,
  }) async {
    int downloaded = 0;
    int failed = 0;
    int total = tiles.length;

    // Processar tiles em lotes para não sobrecarregar
    final batches = _createBatches(tiles, _maxConcurrentDownloads);

    for (final batch in batches) {
      final futures = batch.map((tile) => downloadTile(
        talhaoId: talhaoId,
        z: tile['z']!,
        x: tile['x']!,
        y: tile['y']!,
        mapType: mapType,
      )).toList();

      final results = await Future.wait(futures);

      for (final success in results) {
        if (success) {
          downloaded++;
        } else {
          failed++;
        }
      }

      onProgress?.call(downloaded + failed, total);
    }

    onComplete?.call();
    return {'downloaded': downloaded, 'failed': failed};
  }

  /// Download de tiles para um talhão
  Future<Map<String, int>> downloadTalhaoTiles({
    required OfflineMapModel offlineMap,
    String mapType = 'satellite',
    Function(int, int)? onProgress,
    Function()? onComplete,
    Function(String)? onError,
  }) async {
    try {
      // Calcular tiles necessários
      final tiles = TileCalculator.calculateTilesForPolygon(
        polygon: offlineMap.polygon,
        zoomMin: offlineMap.zoomMin,
        zoomMax: offlineMap.zoomMax,
      );

      if (tiles.isEmpty) {
        onError?.call('Nenhum tile encontrado para o talhão');
        return {'downloaded': 0, 'failed': 0};
      }

      // Filtrar tiles que estão dentro do polígono
      final filteredTiles = TileCalculator.filterTilesInPolygon(
        tiles: tiles,
        polygon: offlineMap.polygon,
      );

      print('📥 Baixando ${filteredTiles.length} tiles para ${offlineMap.talhaoName}');

      // Fazer download
      return await downloadTiles(
        talhaoId: offlineMap.talhaoId,
        tiles: filteredTiles,
        mapType: mapType,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );
    } catch (e) {
      onError?.call('Erro ao calcular tiles: $e');
      return {'downloaded': 0, 'failed': 0};
    }
  }

  /// Verifica se um tile está disponível online
  Future<bool> isTileAvailable({
    required int z,
    required int x,
    required int y,
    String mapType = 'satellite',
  }) async {
    try {
      final url = OfflineMapUtils.generateMapTilerUrl(
        z: z,
        x: x,
        y: y,
        apiKey: _mapTilerApiKey,
        mapType: mapType,
      );

      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FortSmartAgro/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Obtém informações de um tile
  Future<Map<String, dynamic>?> getTileInfo({
    required int z,
    required int x,
    required int y,
    String mapType = 'satellite',
  }) async {
    try {
      final url = OfflineMapUtils.generateMapTilerUrl(
        z: z,
        x: x,
        y: y,
        apiKey: _mapTilerApiKey,
        mapType: mapType,
      );

      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FortSmartAgro/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'size': int.tryParse(response.headers['content-length'] ?? '0') ?? 0,
          'type': response.headers['content-type'] ?? 'image/jpeg',
          'lastModified': response.headers['last-modified'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cria lotes de tiles para download
  List<List<Map<String, int>>> _createBatches(
    List<Map<String, int>> tiles,
    int batchSize,
  ) {
    final batches = <List<Map<String, int>>>[];
    
    for (int i = 0; i < tiles.length; i += batchSize) {
      final end = (i + batchSize < tiles.length) ? i + batchSize : tiles.length;
      batches.add(tiles.sublist(i, end));
    }
    
    return batches;
  }

  /// Limpa tiles de um talhão
  Future<void> cleanupTalhaoTiles(String talhaoId) async {
    try {
      await OfflineMapUtils.cleanupOldTiles(talhaoId);
    } catch (e) {
      print('❌ Erro ao limpar tiles do talhão $talhaoId: $e');
    }
  }

  /// Verifica integridade dos tiles baixados
  Future<Map<String, dynamic>> verifyTilesIntegrity({
    required String talhaoId,
    required List<Map<String, int>> tiles,
  }) async {
    int validTiles = 0;
    int invalidTiles = 0;
    int totalSize = 0;

    for (final tile in tiles) {
      final tilePath = await OfflineMapUtils.getTilePath(
        talhaoId: talhaoId,
        z: tile['z']!,
        x: tile['x']!,
        y: tile['y']!,
      );

      final tileFile = File(tilePath);
      if (await tileFile.exists()) {
        final size = await tileFile.length();
        if (size > 0) {
          validTiles++;
          totalSize += size;
        } else {
          invalidTiles++;
        }
      } else {
        invalidTiles++;
      }
    }

    return {
      'validTiles': validTiles,
      'invalidTiles': invalidTiles,
      'totalSize': totalSize,
      'integrity': validTiles / tiles.length,
    };
  }
}
