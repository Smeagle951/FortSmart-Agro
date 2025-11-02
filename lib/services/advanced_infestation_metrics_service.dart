import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import '../models/infestacao_model.dart';
import '../utils/logger.dart';
import 'package:latlong2/latlong.dart';

/// Serviço para métricas avançadas de infestação
/// 
/// Este serviço calcula métricas georreferenciadas agregadas,
/// incluindo médias por talhão e dados para heatmaps.
class AdvancedInfestationMetricsService {
  static final AdvancedInfestationMetricsService _instance = 
      AdvancedInfestationMetricsService._internal();
  
  factory AdvancedInfestationMetricsService() => _instance;
  
  AdvancedInfestationMetricsService._internal();
  
  Database? _database;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      _database = await AppDatabase().database;
      Logger.info('✅ [METRICS] Serviço de métricas avançadas inicializado');
    } catch (e) {
      Logger.error('❌ [METRICS] Erro ao inicializar serviço: $e');
      rethrow;
    }
  }
  
  /// Calcula métricas agregadas por talhão
  Future<Map<String, dynamic>> calculateTalhaoAggregatedMetrics({
    int? talhaoId,
    String? organismoId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (_database == null) {
        await initialize();
      }
      
      Logger.info('🔄 [METRICS] Calculando métricas agregadas por talhão...');
      
      // Construir query base
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organism_id = ?';
        whereArgs.add(organismoId);
      }
      
      if (startDate != null) {
        whereClause += ' AND data_hora_ocorrencia >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND data_hora_ocorrencia <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      // Query para métricas por talhão
      final talhaoMetrics = await _database!.rawQuery('''
        SELECT 
          talhao_id,
          organism_id,
          COUNT(*) as total_ocorrencias,
          AVG(infestacao_percent) as media_infestacao,
          AVG(intensidade_media) as media_intensidade,
          AVG(frequencia_percent) as media_frequencia,
          AVG(indice_percent) as media_indice,
          MIN(data_hora_ocorrencia) as primeira_ocorrencia,
          MAX(data_hora_ocorrencia) as ultima_ocorrencia,
          COUNT(DISTINCT organism_id) as tipos_organismos,
          AVG(latitude) as centro_latitude,
          AVG(longitude) as centro_longitude
        FROM infestation_map 
        WHERE $whereClause
        GROUP BY talhao_id, organism_id
        ORDER BY media_infestacao DESC
      ''', whereArgs);
      
      // Query para estatísticas gerais
      final generalStats = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_ocorrencias,
          COUNT(DISTINCT talhao_id) as total_talhoes,
          COUNT(DISTINCT organism_id) as total_organismos,
          AVG(infestacao_percent) as media_geral_infestacao,
          AVG(intensidade_media) as media_geral_intensidade,
          MIN(data_hora_ocorrencia) as primeira_ocorrencia_geral,
          MAX(data_hora_ocorrencia) as ultima_ocorrencia_geral
        FROM infestation_map 
        WHERE $whereClause
      ''', whereArgs);
      
      // Query para distribuição por nível
      final levelDistribution = await _database!.rawQuery('''
        SELECT 
          nivel,
          COUNT(*) as quantidade,
          AVG(infestacao_percent) as media_percentual
        FROM infestation_map 
        WHERE $whereClause
        GROUP BY nivel
        ORDER BY 
          CASE nivel 
            WHEN 'critico' THEN 4
            WHEN 'alto' THEN 3
            WHEN 'medio' THEN 2
            WHEN 'baixo' THEN 1
            ELSE 0
          END DESC
      ''', whereArgs);
      
      // Query para tendência temporal (últimos 30 dias)
      final temporalTrend = await _database!.rawQuery('''
        SELECT 
          DATE(data_hora_ocorrencia) as data,
          COUNT(*) as ocorrencias_dia,
          AVG(infestacao_percent) as media_dia
        FROM infestation_map 
        WHERE $whereClause 
          AND data_hora_ocorrencia >= datetime('now', '-30 days')
        GROUP BY DATE(data_hora_ocorrencia)
        ORDER BY data DESC
        LIMIT 30
      ''', whereArgs);
      
      final result = {
        'talhao_metrics': talhaoMetrics,
        'general_stats': generalStats.isNotEmpty ? generalStats.first : {},
        'level_distribution': levelDistribution,
        'temporal_trend': temporalTrend,
        'calculated_at': DateTime.now().toIso8601String(),
        'filters': {
          'talhao_id': talhaoId,
          'organismo_id': organismoId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      };
      
      Logger.info('✅ [METRICS] Métricas calculadas: ${talhaoMetrics.length} talhões');
      return result;
      
    } catch (e) {
      Logger.error('❌ [METRICS] Erro ao calcular métricas: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Gera dados para heatmap por talhão
  Future<Map<String, dynamic>> generateTalhaoHeatmapData({
    int? talhaoId,
    String? organismoId,
    double hexSize = 50.0, // metros
  }) async {
    try {
      if (_database == null) {
        await initialize();
      }
      
      Logger.info('🔄 [METRICS] Gerando dados de heatmap...');
      
      // Query para obter pontos de infestação
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organism_id = ?';
        whereArgs.add(organismoId);
      }
      
      final points = await _database!.rawQuery('''
        SELECT 
          latitude,
          longitude,
          infestacao_percent,
          intensidade_media,
          nivel,
          organism_id,
          data_hora_ocorrencia
        FROM infestation_map 
        WHERE $whereClause
          AND latitude IS NOT NULL 
          AND longitude IS NOT NULL
        ORDER BY data_hora_ocorrencia DESC
      ''', whereArgs);
      
      if (points.isEmpty) {
        return {
          'heatmap_data': [],
          'message': 'Nenhum ponto encontrado para gerar heatmap',
        };
      }
      
      // Gerar grid hexagonal
      final heatmapData = _generateHexagonalGrid(points, hexSize);
      
      // Calcular estatísticas do heatmap
      final stats = _calculateHeatmapStats(heatmapData);
      
      final result = {
        'heatmap_data': heatmapData,
        'stats': stats,
        'total_points': points.length,
        'hex_size_meters': hexSize,
        'generated_at': DateTime.now().toIso8601String(),
      };
      
      Logger.info('✅ [METRICS] Heatmap gerado: ${heatmapData.length} hexágonos');
      return result;
      
    } catch (e) {
      Logger.error('❌ [METRICS] Erro ao gerar heatmap: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Gera grid hexagonal para heatmap
  List<Map<String, dynamic>> _generateHexagonalGrid(
    List<Map<String, dynamic>> points,
    double hexSize,
  ) {
    if (points.isEmpty) return [];
    
    // Calcular bounding box dos pontos
    double minLat = points.first['latitude'] as double;
    double maxLat = points.first['latitude'] as double;
    double minLng = points.first['longitude'] as double;
    double maxLng = points.first['longitude'] as double;
    
    for (final point in points) {
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    
    // Converter hexSize de metros para graus (aproximado)
    final latDegreePerMeter = 1.0 / 111320.0; // 1 grau ≈ 111.32 km
    final lngDegreePerMeter = 1.0 / (111320.0 * cos(minLat * 3.14159 / 180.0));
    
    final hexLatSize = hexSize * latDegreePerMeter;
    final hexLngSize = hexSize * lngDegreePerMeter;
    
    // Gerar grid hexagonal
    final hexagons = <Map<String, dynamic>>[];
    final hexMap = <String, List<Map<String, dynamic>>>{};
    
    // Agrupar pontos por hexágono
    for (final point in points) {
      final lat = point['latitude'] as double;
      final lng = point['longitude'] as double;
      
      // Calcular coordenadas do hexágono
      final hexLat = (lat / hexLatSize).floor() * hexLatSize;
      final hexLng = (lng / hexLngSize).floor() * hexLngSize;
      
      final hexKey = '${hexLat.toStringAsFixed(6)}_${hexLng.toStringAsFixed(6)}';
      
      if (!hexMap.containsKey(hexKey)) {
        hexMap[hexKey] = [];
      }
      hexMap[hexKey]!.add(point);
    }
    
    // Processar cada hexágono
    for (final entry in hexMap.entries) {
      final hexPoints = entry.value;
      if (hexPoints.isEmpty) continue;
      
      // Calcular métricas do hexágono
      final avgInfestation = hexPoints
          .map((p) => p['infestacao_percent'] as double)
          .reduce((a, b) => a + b) / hexPoints.length;
      
      final avgIntensity = hexPoints
          .map((p) => p['intensidade_media'] as double)
          .reduce((a, b) => a + b) / hexPoints.length;
      
      final level = _determineInfestationLevel(avgInfestation);
      final color = _getInfestationColor(level);
      
      // Gerar vértices do hexágono
      final centerLat = hexPoints
          .map((p) => p['latitude'] as double)
          .reduce((a, b) => a + b) / hexPoints.length;
      final centerLng = hexPoints
          .map((p) => p['longitude'] as double)
          .reduce((a, b) => a + b) / hexPoints.length;
      
      final vertices = _generateHexagonVertices(
        LatLng(centerLat, centerLng),
        hexLatSize,
        hexLngSize,
      );
      
      hexagons.add({
        'id': entry.key,
        'center': {
          'latitude': centerLat,
          'longitude': centerLng,
        },
        'vertices': vertices.map((v) => {
          'latitude': v.latitude,
          'longitude': v.longitude,
        }).toList(),
        'avg_infestation': avgInfestation,
        'avg_intensity': avgIntensity,
        'level': level,
        'color': color,
        'point_count': hexPoints.length,
        'points': hexPoints,
      });
    }
    
    return hexagons;
  }
  
  /// Gera vértices de um hexágono
  List<LatLng> _generateHexagonVertices(
    LatLng center,
    double latSize,
    double lngSize,
  ) {
    final vertices = <LatLng>[];
    
    for (int i = 0; i < 6; i++) {
      final angle = i * 60.0 * 3.14159 / 180.0; // 60 graus em radianos
      final lat = center.latitude + latSize * cos(angle);
      final lng = center.longitude + lngSize * sin(angle);
      vertices.add(LatLng(lat, lng));
    }
    
    return vertices;
  }
  
  /// Calcula estatísticas do heatmap
  Map<String, dynamic> _calculateHeatmapStats(
    List<Map<String, dynamic>> heatmapData,
  ) {
    if (heatmapData.isEmpty) {
      return {
        'total_hexagons': 0,
        'avg_infestation': 0.0,
        'max_infestation': 0.0,
        'min_infestation': 0.0,
        'level_distribution': {},
      };
    }
    
    final infestations = heatmapData
        .map((h) => h['avg_infestation'] as double)
        .toList();
    
    final levelCounts = <String, int>{};
    for (final hex in heatmapData) {
      final level = hex['level'] as String;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }
    
    return {
      'total_hexagons': heatmapData.length,
      'avg_infestation': infestations.reduce((a, b) => a + b) / infestations.length,
      'max_infestation': infestations.reduce((a, b) => a > b ? a : b),
      'min_infestation': infestations.reduce((a, b) => a < b ? a : b),
      'level_distribution': levelCounts,
    };
  }
  
  /// Determina nível de infestação baseado no percentual
  String _determineInfestationLevel(double percent) {
    if (percent >= 75) return 'critico';
    if (percent >= 50) return 'alto';
    if (percent >= 25) return 'medio';
    return 'baixo';
  }
  
  /// Obtém cor baseada no nível de infestação
  String _getInfestationColor(String level) {
    switch (level) {
      case 'critico':
        return '#FF0000'; // Vermelho
      case 'alto':
        return '#FFA500'; // Laranja
      case 'medio':
        return '#FFFF00'; // Amarelo
      case 'baixo':
        return '#00FF00'; // Verde
      default:
        return '#808080'; // Cinza
    }
  }
  
  /// Exporta dados integrados em GeoJSON
  Future<File> exportIntegrationData({
    String format = 'geojson',
    int? talhaoId,
    String? organismoId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (_database == null) {
        await initialize();
      }
      
      Logger.info('🔄 [METRICS] Exportando dados em formato $format...');
      
      // Obter dados de infestação
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organism_id = ?';
        whereArgs.add(organismoId);
      }
      
      if (startDate != null) {
        whereClause += ' AND data_hora_ocorrencia >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND data_hora_ocorrencia <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      final data = await _database!.rawQuery('''
        SELECT 
          id,
          talhao_id,
          organism_id,
          latitude,
          longitude,
          infestacao_percent,
          nivel,
          intensidade_media,
          frequencia_percent,
          indice_percent,
          data_hora_ocorrencia,
          observacao
        FROM infestation_map 
        WHERE $whereClause
          AND latitude IS NOT NULL 
          AND longitude IS NOT NULL
        ORDER BY data_hora_ocorrencia DESC
      ''', whereArgs);
      
      if (format.toLowerCase() == 'geojson') {
        return await _exportAsGeoJSON(data);
      } else if (format.toLowerCase() == 'csv') {
        return await _exportAsCSV(data);
      } else {
        throw Exception('Formato não suportado: $format');
      }
      
    } catch (e) {
      Logger.error('❌ [METRICS] Erro ao exportar dados: $e');
      rethrow;
    }
  }
  
  /// Exporta dados como GeoJSON
  Future<File> _exportAsGeoJSON(List<Map<String, dynamic>> data) async {
    final features = <Map<String, dynamic>>[];
    
    for (final record in data) {
      final feature = {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [
            record['longitude'] as double,
            record['latitude'] as double,
          ],
        },
        'properties': {
          'id': record['id'],
          'talhao_id': record['talhao_id'],
          'organism_id': record['organism_id'],
          'infestacao_percent': record['infestacao_percent'],
          'nivel': record['nivel'],
          'intensidade_media': record['intensidade_media'],
          'frequencia_percent': record['frequencia_percent'],
          'indice_percent': record['indice_percent'],
          'data_hora_ocorrencia': record['data_hora_ocorrencia'],
          'observacao': record['observacao'],
        },
      };
      features.add(feature);
    }
    
    final geoJson = {
      'type': 'FeatureCollection',
      'features': features,
      'metadata': {
        'exported_at': DateTime.now().toIso8601String(),
        'total_features': features.length,
        'source': 'FortSmart Agro - Módulo de Infestação',
      },
    };
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/infestation_data_${DateTime.now().millisecondsSinceEpoch}.geojson');
    await file.writeAsString(jsonEncode(geoJson));
    
    Logger.info('✅ [METRICS] GeoJSON exportado: ${file.path}');
    return file;
  }
  
  /// Exporta dados como CSV
  Future<File> _exportAsCSV(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      throw Exception('Nenhum dado para exportar');
    }
    
    final headers = data.first.keys.toList();
    final csvLines = <String>[];
    
    // Adicionar cabeçalho
    csvLines.add(headers.join(','));
    
    // Adicionar dados
    for (final record in data) {
      final values = headers.map((header) {
        final value = record[header];
        if (value == null) return '';
        if (value is String && value.contains(',')) {
          return '"$value"'; // Escapar vírgulas
        }
        return value.toString();
      }).toList();
      csvLines.add(values.join(','));
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/infestation_data_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvLines.join('\n'));
    
    Logger.info('✅ [METRICS] CSV exportado: ${file.path}');
    return file;
  }
  
  /// Obtém estatísticas de exportação
  Future<Map<String, dynamic>> getExportStats() async {
    try {
      if (_database == null) {
        await initialize();
      }
      
      final stats = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_records,
          COUNT(DISTINCT talhao_id) as total_talhoes,
          COUNT(DISTINCT organism_id) as total_organismos,
          MIN(data_hora_ocorrencia) as earliest_date,
          MAX(data_hora_ocorrencia) as latest_date
        FROM infestation_map
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
      ''');
      
      return stats.isNotEmpty ? stats.first : {};
    } catch (e) {
      Logger.error('❌ [METRICS] Erro ao obter estatísticas: $e');
      return {};
    }
  }
}
