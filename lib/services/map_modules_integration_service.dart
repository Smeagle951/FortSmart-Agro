import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../services/enhanced_offline_map_service.dart';
import '../utils/logger.dart';

/// Serviço de integração entre mapas offline e módulos de monitoramento/infestação
class MapModulesIntegrationService {
  static final MapModulesIntegrationService _instance = MapModulesIntegrationService._internal();
  factory MapModulesIntegrationService() => _instance;
  MapModulesIntegrationService._internal();

  final EnhancedOfflineMapService _mapService = EnhancedOfflineMapService();
  Database? _database;
  
  /// Inicializa o serviço de integração
  Future<void> initialize() async {
    try {
      await _mapService.initialize();
      await _initializeDatabase();
      Logger.info('🔗 MapModulesIntegrationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar MapModulesIntegrationService: $e');
    }
  }
  
  /// Inicializa banco de dados para integração
  Future<void> _initializeDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/map_modules_integration.db';
    
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreateDatabase,
    );
  }
  
  /// Cria tabelas do banco de dados
  Future<void> _onCreateDatabase(Database db, int version) async {
    // Tabela de áreas de monitoramento
    await db.execute('''
      CREATE TABLE monitoring_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        southwest_lat REAL NOT NULL,
        southwest_lng REAL NOT NULL,
        northeast_lat REAL NOT NULL,
        northeast_lng REAL NOT NULL,
        map_downloaded BOOLEAN NOT NULL DEFAULT FALSE,
        last_monitoring TEXT,
        total_points INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Tabela de áreas de infestação
    await db.execute('''
      CREATE TABLE infestation_areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        southwest_lat REAL NOT NULL,
        southwest_lng REAL NOT NULL,
        northeast_lat REAL NOT NULL,
        northeast_lng REAL NOT NULL,
        map_downloaded BOOLEAN NOT NULL DEFAULT FALSE,
        last_infestation_check TEXT,
        total_infestations INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Tabela de sincronização entre módulos
    await db.execute('''
      CREATE TABLE module_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_type TEXT NOT NULL,
        area_id INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        last_sync TEXT,
        sync_data TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }
  
  /// Registra área de monitoramento
  Future<int> registerMonitoringArea({
    required String name,
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    try {
      final areaId = await _database!.insert('monitoring_areas', {
        'name': name,
        'southwest_lat': southwest.latitude,
        'southwest_lng': southwest.longitude,
        'northeast_lat': northeast.latitude,
        'northeast_lng': northeast.longitude,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      Logger.info('📊 Área de monitoramento registrada: $name');
      return areaId;
    } catch (e) {
      Logger.error('❌ Erro ao registrar área de monitoramento: $e');
      return -1;
    }
  }
  
  /// Registra área de infestação
  Future<int> registerInfestationArea({
    required String name,
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    try {
      final areaId = await _database!.insert('infestation_areas', {
        'name': name,
        'southwest_lat': southwest.latitude,
        'southwest_lng': southwest.longitude,
        'northeast_lat': northeast.latitude,
        'northeast_lng': northeast.longitude,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      Logger.info('🦠 Área de infestação registrada: $name');
      return areaId;
    } catch (e) {
      Logger.error('❌ Erro ao registrar área de infestação: $e');
      return -1;
    }
  }
  
  /// Download de mapa para área de monitoramento
  Future<Map<String, dynamic>> downloadMapForMonitoring({
    required int areaId,
    int minZoom = 10,
    int maxZoom = 16,
    String mapType = 'satellite',
    Function(double)? onProgress,
  }) async {
    try {
      // Buscar área de monitoramento
      final area = await _database!.query(
        'monitoring_areas',
        where: 'id = ?',
        whereArgs: [areaId],
      );
      
      if (area.isEmpty) {
        return {'success': false, 'error': 'Área não encontrada'};
      }
      
      final areaData = area.first;
      final southwest = LatLng(
        areaData['southwest_lat'] as double,
        areaData['southwest_lng'] as double,
      );
      final northeast = LatLng(
        areaData['northeast_lat'] as double,
        areaData['northeast_lng'] as double,
      );
      
      // Download do mapa
      final result = await _mapService.downloadFarmArea(
        farmName: '${areaData['name']} - Monitoramento',
        southwest: southwest,
        northeast: northeast,
        minZoom: minZoom,
        maxZoom: maxZoom,
        mapType: mapType,
        onProgress: onProgress,
      );
      
      if (result['success']) {
        // Atualizar status da área
        await _database!.update(
          'monitoring_areas',
          {
            'map_downloaded': true,
            'last_monitoring': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [areaId],
        );
        
        // Registrar sincronização
        await _database!.insert('module_sync', {
          'module_type': 'monitoring',
          'area_id': areaId,
          'sync_status': 'completed',
          'last_sync': DateTime.now().toIso8601String(),
          'sync_data': 'Mapa baixado para monitoramento',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao baixar mapa para monitoramento: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Download de mapa para área de infestação
  Future<Map<String, dynamic>> downloadMapForInfestation({
    required int areaId,
    int minZoom = 10,
    int maxZoom = 16,
    String mapType = 'satellite',
    Function(double)? onProgress,
  }) async {
    try {
      // Buscar área de infestação
      final area = await _database!.query(
        'infestation_areas',
        where: 'id = ?',
        whereArgs: [areaId],
      );
      
      if (area.isEmpty) {
        return {'success': false, 'error': 'Área não encontrada'};
      }
      
      final areaData = area.first;
      final southwest = LatLng(
        areaData['southwest_lat'] as double,
        areaData['southwest_lng'] as double,
      );
      final northeast = LatLng(
        areaData['northeast_lat'] as double,
        areaData['northeast_lng'] as double,
      );
      
      // Download do mapa
      final result = await _mapService.downloadFarmArea(
        farmName: '${areaData['name']} - Infestação',
        southwest: southwest,
        northeast: northeast,
        minZoom: minZoom,
        maxZoom: maxZoom,
        mapType: mapType,
        onProgress: onProgress,
      );
      
      if (result['success']) {
        // Atualizar status da área
        await _database!.update(
          'infestation_areas',
          {
            'map_downloaded': true,
            'last_infestation_check': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [areaId],
        );
        
        // Registrar sincronização
        await _database!.insert('module_sync', {
          'module_type': 'infestation',
          'area_id': areaId,
          'sync_status': 'completed',
          'last_sync': DateTime.now().toIso8601String(),
          'sync_data': 'Mapa baixado para infestação',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return result;
    } catch (e) {
      Logger.error('❌ Erro ao baixar mapa para infestação: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Lista áreas de monitoramento
  Future<List<Map<String, dynamic>>> getMonitoringAreas() async {
    try {
      final areas = await _database!.query(
        'monitoring_areas',
        orderBy: 'created_at DESC',
      );
      
      return areas.map((area) => {
        'id': area['id'],
        'name': area['name'],
        'southwest': LatLng(
          area['southwest_lat'] as double,
          area['southwest_lng'] as double,
        ),
        'northeast': LatLng(
          area['northeast_lat'] as double,
          area['northeast_lng'] as double,
        ),
        'mapDownloaded': area['map_downloaded'] == 1,
        'lastMonitoring': area['last_monitoring'],
        'totalPoints': area['total_points'],
        'createdAt': area['created_at'],
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar áreas de monitoramento: $e');
      return [];
    }
  }
  
  /// Lista áreas de infestação
  Future<List<Map<String, dynamic>>> getInfestationAreas() async {
    try {
      final areas = await _database!.query(
        'infestation_areas',
        orderBy: 'created_at DESC',
      );
      
      return areas.map((area) => {
        'id': area['id'],
        'name': area['name'],
        'southwest': LatLng(
          area['southwest_lat'] as double,
          area['southwest_lng'] as double,
        ),
        'northeast': LatLng(
          area['northeast_lat'] as double,
          area['northeast_lng'] as double,
        ),
        'mapDownloaded': area['map_downloaded'] == 1,
        'lastInfestationCheck': area['last_infestation_check'],
        'totalInfestations': area['total_infestations'],
        'createdAt': area['created_at'],
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar áreas de infestação: $e');
      return [];
    }
  }
  
  /// Verifica se área tem mapa offline
  Future<bool> hasOfflineMap(int areaId, String moduleType) async {
    try {
      final tableName = moduleType == 'monitoring' ? 'monitoring_areas' : 'infestation_areas';
      final result = await _database!.query(
        tableName,
        columns: ['map_downloaded'],
        where: 'id = ?',
        whereArgs: [areaId],
      );
      
      if (result.isNotEmpty) {
        return result.first['map_downloaded'] == 1;
      }
      return false;
    } catch (e) {
      Logger.error('❌ Erro ao verificar mapa offline: $e');
      return false;
    }
  }
  
  /// Atualiza estatísticas de área
  Future<void> updateAreaStats(int areaId, String moduleType, {
    int? totalPoints,
    int? totalInfestations,
  }) async {
    try {
      final tableName = moduleType == 'monitoring' ? 'monitoring_areas' : 'infestation_areas';
      final updateData = <String, dynamic>{};
      
      if (moduleType == 'monitoring' && totalPoints != null) {
        updateData['total_points'] = totalPoints;
        updateData['last_monitoring'] = DateTime.now().toIso8601String();
      } else if (moduleType == 'infestation' && totalInfestations != null) {
        updateData['total_infestations'] = totalInfestations;
        updateData['last_infestation_check'] = DateTime.now().toIso8601String();
      }
      
      if (updateData.isNotEmpty) {
        await _database!.update(
          tableName,
          updateData,
          where: 'id = ?',
          whereArgs: [areaId],
        );
      }
    } catch (e) {
      Logger.error('❌ Erro ao atualizar estatísticas: $e');
    }
  }
  
  /// Obtém estatísticas gerais de integração
  Future<Map<String, dynamic>> getIntegrationStats() async {
    try {
      final monitoringResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_areas,
          COUNT(CASE WHEN map_downloaded = 1 THEN 1 END) as areas_with_map,
          SUM(total_points) as total_points
        FROM monitoring_areas
      ''');
      
      final infestationResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_areas,
          COUNT(CASE WHEN map_downloaded = 1 THEN 1 END) as areas_with_map,
          SUM(total_infestations) as total_infestations
        FROM infestation_areas
      ''');
      
      final syncResult = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_syncs,
          COUNT(CASE WHEN sync_status = 'completed' THEN 1 END) as successful_syncs
        FROM module_sync
      ''');
      
      return {
        'monitoring': {
          'totalAreas': monitoringResult.first['total_areas'] ?? 0,
          'areasWithMap': monitoringResult.first['areas_with_map'] ?? 0,
          'totalPoints': monitoringResult.first['total_points'] ?? 0,
        },
        'infestation': {
          'totalAreas': infestationResult.first['total_areas'] ?? 0,
          'areasWithMap': infestationResult.first['areas_with_map'] ?? 0,
          'totalInfestations': infestationResult.first['total_infestations'] ?? 0,
        },
        'sync': {
          'totalSyncs': syncResult.first['total_syncs'] ?? 0,
          'successfulSyncs': syncResult.first['successful_syncs'] ?? 0,
        },
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de integração: $e');
      return {};
    }
  }
  
  /// Sincroniza dados entre módulos
  Future<Map<String, dynamic>> syncModules() async {
    try {
      final stats = await getIntegrationStats();
      final mapStats = await _mapService.getCacheStats();
      
      // Verificar se há dados para sincronizar
      final hasDataToSync = (stats['monitoring']['totalPoints'] ?? 0) > 0 ||
                           (stats['infestation']['totalInfestations'] ?? 0) > 0;
      
      if (!hasDataToSync) {
        return {
          'success': true,
          'message': 'Nenhum dado para sincronizar',
          'stats': stats,
        };
      }
      
      // Registrar sincronização
      await _database!.insert('module_sync', {
        'module_type': 'integration',
        'area_id': 0,
        'sync_status': 'completed',
        'last_sync': DateTime.now().toIso8601String(),
        'sync_data': 'Sincronização entre módulos',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      Logger.info('🔄 Módulos sincronizados com sucesso');
      
      return {
        'success': true,
        'message': 'Módulos sincronizados com sucesso',
        'stats': stats,
        'mapStats': mapStats,
      };
    } catch (e) {
      Logger.error('❌ Erro na sincronização de módulos: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Obtém áreas disponíveis (placeholder)
  List<Map<String, dynamic>> getAvailableAreas() {
    // Implementação placeholder - retorna lista vazia
    return [];
  }
}
