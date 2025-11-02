import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utilitários para mapas offline
class OfflineMapUtils {
  /// Obtém o diretório de mapas offline
  static Future<Directory> getOfflineMapsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory(path.join(appDir.path, 'offline_maps'));
    
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    
    return offlineDir;
  }

  /// Obtém o diretório de um talhão específico
  static Future<Directory> getTalhaoDirectory(String talhaoId) async {
    final offlineDir = await getOfflineMapsDirectory();
    final talhaoDir = Directory(path.join(offlineDir.path, talhaoId));
    
    if (!await talhaoDir.exists()) {
      await talhaoDir.create(recursive: true);
    }
    
    return talhaoDir;
  }

  /// Obtém o caminho de um tile específico
  static Future<String> getTilePath({
    required String talhaoId,
    required int z,
    required int x,
    required int y,
    String extension = 'png',
  }) async {
    final talhaoDir = await getTalhaoDirectory(talhaoId);
    return path.join(talhaoDir.path, '$z', '$x', '$y.$extension');
  }

  /// Verifica se um tile existe localmente
  static Future<bool> tileExists({
    required String talhaoId,
    required int z,
    required int x,
    required int y,
  }) async {
    final tilePath = await getTilePath(
      talhaoId: talhaoId,
      z: z,
      x: x,
      y: y,
    );
    return await File(tilePath).exists();
  }

  /// Calcula o tamanho do diretório de um talhão
  static Future<int> calculateDirectorySize(String talhaoId) async {
    try {
      final talhaoDir = await getTalhaoDirectory(talhaoId);
      int totalSize = 0;
      
      await for (final entity in talhaoDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Formata tamanho em bytes para string legível
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Limpa tiles antigos de um talhão
  static Future<void> cleanupOldTiles(String talhaoId) async {
    try {
      final talhaoDir = await getTalhaoDirectory(talhaoId);
      if (await talhaoDir.exists()) {
        await talhaoDir.delete(recursive: true);
      }
    } catch (e) {
      // Ignorar erros de limpeza
    }
  }

  /// Verifica se há espaço suficiente para o download
  static Future<bool> hasEnoughSpace(int requiredBytes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      
      // Verificar espaço disponível (aproximado)
      // Em dispositivos móveis, isso pode não ser 100% preciso
      return true; // Por enquanto, sempre retorna true
    } catch (e) {
      return false;
    }
  }

  /// Obtém estatísticas de uso de espaço
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final offlineDir = await getOfflineMapsDirectory();
      int totalSize = 0;
      int fileCount = 0;
      
      if (await offlineDir.exists()) {
        await for (final entity in offlineDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
            fileCount++;
          }
        }
      }
      
      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'formattedSize': formatBytes(totalSize),
      };
    } catch (e) {
      return {
        'totalSize': 0,
        'fileCount': 0,
        'formattedSize': '0 B',
      };
    }
  }

  /// Gera URL de tile do MapTiler
  static String generateMapTilerUrl({
    required int z,
    required int x,
    required int y,
    required String apiKey,
    String mapType = 'satellite',
  }) {
    switch (mapType) {
      case 'satellite':
        return 'https://api.maptiler.com/maps/satellite/256/$z/$x/$y.jpg?key=$apiKey';
      case 'streets':
        return 'https://api.maptiler.com/maps/streets/256/$z/$x/$y.png?key=$apiKey';
      case 'outdoors':
        return 'https://api.maptiler.com/maps/outdoor/256/$z/$x/$y.png?key=$apiKey';
      case 'hybrid':
        return 'https://api.maptiler.com/maps/hybrid/256/$z/$x/$y.jpg?key=$apiKey';
      default:
        return 'https://api.maptiler.com/maps/satellite/256/$z/$x/$y.jpg?key=$apiKey';
    }
  }

  /// Valida se um polígono é válido
  static bool isValidPolygon(List<dynamic> polygon) {
    if (polygon.length < 3) return false;
    
    // Verificar se todos os pontos têm coordenadas válidas
    for (final point in polygon) {
      if (point is! Map || 
          !point.containsKey('latitude') || 
          !point.containsKey('longitude')) {
        return false;
      }
      
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;
      
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return false;
      }
    }
    
    return true;
  }

  /// Calcula a área de um polígono em hectares
  static double calculatePolygonArea(List<dynamic> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      final lat1 = polygon[j]['latitude'] as double;
      final lng1 = polygon[j]['longitude'] as double;
      final lat2 = polygon[i]['latitude'] as double;
      final lng2 = polygon[i]['longitude'] as double;
      
      area += (lng2 - lng1) * (lat2 + lat1);
      j = i;
    }
    
    return (area.abs() / 2.0) * 11100000; // Converter para hectares
  }
}
