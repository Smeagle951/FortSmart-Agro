import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/logger.dart';

/// Repositório otimizado para monitoramentos com alta performance
class MonitoringRepository {
  final AppDatabase _appDatabase = AppDatabase();

  final String table = 'monitorings';
  final String pointsTable = 'monitoring_points';
  final String occurrencesTable = 'occurrences';
  final String alertsTable = 'monitoring_alerts';

  /// Inicializa as tabelas de monitoramento
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando tabelas de monitoramento...');
      
      final db = await _appDatabase.database;
      
      // Tabela principal de monitoramentos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $table (
          id TEXT PRIMARY KEY,
          plot_id TEXT NOT NULL,
          plotName TEXT,
          crop_id TEXT NOT NULL,
          cropName TEXT,
          cropType TEXT,
          date TEXT NOT NULL,
          route TEXT,
          isCompleted INTEGER DEFAULT 0,
          isSynced INTEGER DEFAULT 0,
          severity INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          metadata TEXT,
          technicianName TEXT,
          technicianIdentification TEXT,
          latitude REAL,
          longitude REAL,
          pests TEXT,
          diseases TEXT,
          weeds TEXT,
          images TEXT,
          observations TEXT,
          recommendations TEXT,
          sync_status INTEGER DEFAULT 0,
          remote_id INTEGER
        )
      ''');
      
      // Tabela de pontos de monitoramento
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $pointsTable (
          id TEXT PRIMARY KEY,
          monitoringId TEXT,
          plotId INTEGER NOT NULL,
          plotName TEXT,
          cropId INTEGER,
          cropName TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          audioPath TEXT,
          observations TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          isSynced INTEGER DEFAULT 0,
          metadata TEXT,
          plantasAvaliadas INTEGER,
          gpsAccuracy REAL,
          isManualEntry INTEGER DEFAULT 0,
          sync_status INTEGER DEFAULT 0,
          remote_id INTEGER,
          FOREIGN KEY (monitoringId) REFERENCES $table (id) ON DELETE CASCADE
        )
      ''');
      
      // Tabela de ocorrências
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $occurrencesTable (
          id TEXT PRIMARY KEY,
          pointId TEXT NOT NULL,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          infestationIndex REAL NOT NULL,
          affectedSections TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0,
          remote_id INTEGER,
          FOREIGN KEY (pointId) REFERENCES $pointsTable (id) ON DELETE CASCADE
        )
      ''');
      
      // Tabela de alertas de monitoramento
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $alertsTable (
          id TEXT PRIMARY KEY,
          monitoring_id TEXT NOT NULL,
          organism_name TEXT NOT NULL,
          alert_level TEXT NOT NULL,
          severity REAL NOT NULL,
          created_at TEXT NOT NULL,
          is_read INTEGER DEFAULT 0,
          FOREIGN KEY (monitoring_id) REFERENCES $table (id) ON DELETE CASCADE
        )
      ''');
      
      Logger.info('✅ Tabelas de monitoramento inicializadas com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabelas de monitoramento: $e');
      rethrow;
    }
  }

  /// Cria um novo monitoramento
  Future<String> create(Monitoring monitoring) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert(
        table,
        monitoring.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Monitoramento criado: ${monitoring.id}');
      return monitoring.id;
    } catch (e) {
      Logger.error('❌ Erro ao criar monitoramento: $e');
      rethrow;
    }
  }

  /// Atualiza um monitoramento existente
  Future<void> update(Monitoring monitoring) async {
    try {
      final db = await _appDatabase.database;
      
      await db.update(
        table,
        monitoring.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [monitoring.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Monitoramento atualizado: ${monitoring.id}');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar monitoramento: $e');
      rethrow;
    }
  }

  /// Exclui um monitoramento
  Future<void> delete(String id) async {
    try {
      final db = await _appDatabase.database;
      
      await db.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      Logger.info('✅ Monitoramento excluído: $id');
    } catch (e) {
      Logger.error('❌ Erro ao excluir monitoramento: $e');
      rethrow;
    }
  }

  /// Obtém um monitoramento por ID
  Future<Monitoring?> getById(String id) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        final monitoring = Monitoring.fromMap(maps.first);
        // Carregar pontos do monitoramento
        final points = await getPointsByMonitoringId(id);
        return monitoring.copyWith(points: points);
      }
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter monitoramento por ID: $e');
      return null;
    }
  }

  /// Obtém todos os monitoramentos
  Future<List<Monitoring>> getAll() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        orderBy: 'created_at DESC',
      );
      
      List<Monitoring> monitorings = [];
      for (var map in maps) {
        final monitoring = Monitoring.fromMap(map);
        final points = await getPointsByMonitoringId(monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao obter todos os monitoramentos: $e');
      return [];
    }
  }

  /// Obtém monitoramentos por talhão
  Future<List<Monitoring>> getMonitoringsByPlot(int plotId) async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        where: 'plot_id = ?',
        whereArgs: [plotId.toString()],
        orderBy: 'created_at DESC',
      );
      
      List<Monitoring> monitorings = [];
      for (var map in maps) {
        final monitoring = Monitoring.fromMap(map);
        final points = await getPointsByMonitoringId(monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao obter monitoramentos por talhão: $e');
      return [];
    }
  }

  /// Obtém monitoramentos por cultura
  Future<List<Monitoring>> getMonitoringsByCrop(int cropId) async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        where: 'crop_id = ?',
        whereArgs: [cropId.toString()],
        orderBy: 'created_at DESC',
      );
      
      List<Monitoring> monitorings = [];
      for (var map in maps) {
        final monitoring = Monitoring.fromMap(map);
        final points = await getPointsByMonitoringId(monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao obter monitoramentos por cultura: $e');
      return [];
    }
  }

  /// Obtém monitoramentos recentes
  Future<List<Monitoring>> getRecentMonitorings({int limit = 10}) async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      List<Monitoring> monitorings = [];
      for (var map in maps) {
        final monitoring = Monitoring.fromMap(map);
        final points = await getPointsByMonitoringId(monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao obter monitoramentos recentes: $e');
      return [];
    }
  }

  /// Cria um ponto de monitoramento
  Future<String> createPoint(MonitoringPoint point) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert(
        pointsTable,
        point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Criar ocorrências do ponto
      for (var occurrence in point.occurrences) {
        await createOccurrence(occurrence, point.id);
      }
      
      Logger.info('✅ Ponto de monitoramento criado: ${point.id}');
      return point.id;
    } catch (e) {
      Logger.error('❌ Erro ao criar ponto de monitoramento: $e');
      rethrow;
    }
  }

  /// Obtém pontos por monitoramento
  Future<List<MonitoringPoint>> getPointsByMonitoringId(String monitoringId) async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        pointsTable,
        where: 'monitoringId = ?',
        whereArgs: [monitoringId],
        orderBy: 'created_at ASC',
      );
      
      List<MonitoringPoint> points = [];
      for (var map in maps) {
        final point = MonitoringPoint.fromMap(map);
        final occurrences = await getOccurrencesByPointId(point.id);
        points.add(point.copyWith(occurrences: occurrences));
      }
      
      return points;
    } catch (e) {
      Logger.error('❌ Erro ao obter pontos por monitoramento: $e');
      return [];
    }
  }

  /// Cria uma ocorrência
  Future<String> createOccurrence(Occurrence occurrence, String pointId) async {
    try {
      final db = await _appDatabase.database;
      
      final occurrenceMap = occurrence.toMap();
      occurrenceMap['pointId'] = pointId;
      
      await db.insert(
        occurrencesTable,
        occurrenceMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Ocorrência criada: ${occurrence.id}');
      return occurrence.id;
    } catch (e) {
      Logger.error('❌ Erro ao criar ocorrência: $e');
      rethrow;
    }
  }

  /// Obtém ocorrências por ponto
  Future<List<Occurrence>> getOccurrencesByPointId(String pointId) async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        occurrencesTable,
        where: 'pointId = ?',
        whereArgs: [pointId],
        orderBy: 'createdAt ASC',
      );
      
      return maps.map((map) => Occurrence.fromMap(map)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter ocorrências por ponto: $e');
      return [];
    }
  }

  /// Atualiza alertas de monitoramento
  Future<void> updateMonitoringAlerts(List<Map<String, dynamic>> alerts) async {
    try {
      final db = await _appDatabase.database;
      
      for (var alert in alerts) {
        await db.insert(
          alertsTable,
          {
            'id': alert['id'],
            'monitoring_id': alert['monitoring_id'],
            'organism_name': alert['organism_name'],
            'alert_level': alert['alert_level'],
            'severity': alert['severity'],
            'created_at': DateTime.now().toIso8601String(),
            'is_read': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      Logger.info('✅ Alertas de monitoramento atualizados');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar alertas de monitoramento: $e');
      rethrow;
    }
  }

  /// Obtém estatísticas de monitoramento
  Future<Map<String, dynamic>> getMonitoringStatistics() async {
    try {
      final db = await _appDatabase.database;
      
      final totalMonitorings = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table')
      ) ?? 0;
      
      final completedMonitorings = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table WHERE isCompleted = 1')
      ) ?? 0;
      
      final totalPoints = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $pointsTable')
      ) ?? 0;
      
      final totalOccurrences = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $occurrencesTable')
      ) ?? 0;
      
      return {
        'total_monitorings': totalMonitorings,
        'completed_monitorings': completedMonitorings,
        'total_points': totalPoints,
        'total_occurrences': totalOccurrences,
        'completion_rate': totalMonitorings > 0 ? (completedMonitorings / totalMonitorings) * 100 : 0,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de monitoramento: $e');
      return {};
    }
  }

  /// Salva um monitoramento completo
  Future<bool> saveMonitoring(Monitoring monitoring) async {
    try {
      final db = await _appDatabase.database;
      
      final monitoringMap = monitoring.toMap();
      
      await db.insert(
        table,
        monitoringMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Salvar pontos do monitoramento
      for (var point in monitoring.points) {
        final pointMap = point.toMap();
        pointMap['monitoringId'] = monitoring.id;
        
        await db.insert(
          pointsTable,
          pointMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      Logger.info('✅ Monitoramento salvo: ${monitoring.id}');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao salvar monitoramento: $e');
      return false;
    }
  }

  /// Salva um ponto de monitoramento
  Future<bool> saveMonitoringPoint(MonitoringPoint point) async {
    try {
      final db = await _appDatabase.database;
      
      final pointMap = point.toMap();
      
      await db.insert(
        pointsTable,
        pointMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Ponto de monitoramento salvo: ${point.id}');
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao salvar ponto de monitoramento: $e');
      return false;
    }
  }

  /// Obtém monitoramentos não sincronizados
  Future<List<Monitoring>> getUnsyncedMonitorings() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        where: 'isSynced = ? OR sync_status = ?',
        whereArgs: [0, 0],
        orderBy: 'created_at ASC',
      );
      
      List<Monitoring> monitorings = [];
      for (var map in maps) {
        final monitoring = Monitoring.fromMap(map);
        final points = await getPointsByMonitoringId(monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao obter monitoramentos não sincronizados: $e');
      return [];
    }
  }

  /// Obtém monitoramentos por IDs
  Future<List<Monitoring>> getMonitoringsByIds(List<String> ids) async {
    try {
      final db = await _appDatabase.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      final List<Map<String, dynamic>> maps = await db.query(
        table,
        where: 'id IN ($placeholders)',
        whereArgs: ids,
        orderBy: 'created_at DESC',
      );
      
      List<Monitoring> monitorings = [];
      for (var map in maps) {
        final monitoring = Monitoring.fromMap(map);
        final points = await getPointsByMonitoringId(monitoring.id);
        monitorings.add(monitoring.copyWith(points: points));
      }
      
      return monitorings;
    } catch (e) {
      Logger.error('❌ Erro ao obter monitoramentos por IDs: $e');
      return [];
    }
  }

  /// Marca monitoramentos como sincronizados
  Future<void> markAsSynced(List<String> ids) async {
    try {
      final db = await _appDatabase.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      
      await db.update(
        table,
        {
          'isSynced': 1,
          'sync_status': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      
      Logger.info('✅ Monitoramentos marcados como sincronizados: ${ids.length}');
    } catch (e) {
      Logger.error('❌ Erro ao marcar monitoramentos como sincronizados: $e');
      rethrow;
    }
  }

  /// Deleta monitoramentos com mais de 15 dias (EXPIRAÇÃO AUTOMÁTICA)
  Future<int> deleteExpiredMonitorings({int expirationDays = 15}) async {
    try {
      final db = await _appDatabase.database;
      
      // Calcular data de corte (15 dias atrás)
      final cutoffDate = DateTime.now().subtract(Duration(days: expirationDays));
      final cutoffDateStr = cutoffDate.toIso8601String();
      
      Logger.info('🗑️ Deletando monitoramentos anteriores a: $cutoffDateStr ($expirationDays dias)');
      
      // Buscar IDs dos monitoramentos que serão deletados
      final expiredMaps = await db.query(
        table,
        columns: ['id'],
        where: 'created_at < ?',
        whereArgs: [cutoffDateStr],
      );
      
      final expiredIds = expiredMaps.map((m) => m['id'] as String).toList();
      Logger.info('📊 Monitoramentos expirados encontrados: ${expiredIds.length}');
      
      if (expiredIds.isEmpty) {
        Logger.info('✅ Nenhum monitoramento expirado para deletar');
        return 0;
      }
      
      // Deletar dados relacionados primeiro (devido a foreign keys)
      for (final id in expiredIds) {
        // Deletar ocorrências
        await db.delete(
          occurrencesTable,
          where: 'pointId IN (SELECT id FROM $pointsTable WHERE monitoringId = ?)',
          whereArgs: [id],
        );
        
        // Deletar pontos
        await db.delete(
          pointsTable,
          where: 'monitoringId = ?',
          whereArgs: [id],
        );
        
        // Deletar alertas
        await db.delete(
          alertsTable,
          where: 'monitoring_id = ?',
          whereArgs: [id],
        );
      }
      
      // Deletar monitoramentos expirados
      final deletedCount = await db.delete(
        table,
        where: 'created_at < ?',
        whereArgs: [cutoffDateStr],
      );
      
      Logger.info('✅ $deletedCount monitoramentos expirados deletados automaticamente');
      return deletedCount;
    } catch (e) {
      Logger.error('❌ Erro ao deletar monitoramentos expirados: $e');
      return 0;
    }
  }

  /// Deleta um monitoramento específico por ID (DELEÇÃO MANUAL)
  Future<bool> deleteMonitoringById(String id) async {
    try {
      final db = await _appDatabase.database;
      
      Logger.info('🗑️ Deletando monitoramento manualmente: $id');
      
      // Deletar ocorrências primeiro
      final occurrencesDeleted = await db.delete(
        occurrencesTable,
        where: 'pointId IN (SELECT id FROM $pointsTable WHERE monitoringId = ?)',
        whereArgs: [id],
      );
      Logger.info('📋 $occurrencesDeleted ocorrências deletadas');
      
      // Deletar pontos
      final pointsDeleted = await db.delete(
        pointsTable,
        where: 'monitoringId = ?',
        whereArgs: [id],
      );
      Logger.info('📍 $pointsDeleted pontos deletados');
      
      // Deletar alertas
      final alertsDeleted = await db.delete(
        alertsTable,
        where: 'monitoring_id = ?',
        whereArgs: [id],
      );
      Logger.info('🔔 $alertsDeleted alertas deletados');
      
      // Deletar monitoramento
      final deleted = await db.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (deleted > 0) {
        Logger.info('✅ Monitoramento deletado com sucesso: $id');
        return true;
      } else {
        Logger.warning('⚠️ Monitoramento não encontrado: $id');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erro ao deletar monitoramento: $e');
      return false;
    }
  }

  /// Deleta todos os monitoramentos de um talhão
  Future<int> deleteMonitoringsByPlotId(String plotId) async {
    try {
      final db = await _appDatabase.database;
      
      Logger.info('🗑️ Deletando todos os monitoramentos do talhão: $plotId');
      
      // Buscar IDs dos monitoramentos do talhão
      final maps = await db.query(
        table,
        columns: ['id'],
        where: 'plot_id = ?',
        whereArgs: [plotId],
      );
      
      final ids = maps.map((m) => m['id'] as String).toList();
      Logger.info('📊 ${ids.length} monitoramentos encontrados para deletar');
      
      // Deletar cada monitoramento individualmente (para garantir cascata)
      int totalDeleted = 0;
      for (final id in ids) {
        final success = await deleteMonitoringById(id);
        if (success) totalDeleted++;
      }
      
      Logger.info('✅ $totalDeleted monitoramentos deletados do talhão $plotId');
      return totalDeleted;
    } catch (e) {
      Logger.error('❌ Erro ao deletar monitoramentos do talhão: $e');
      return 0;
    }
  }
}
