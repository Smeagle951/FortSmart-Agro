import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/penetrometro_reading_model.dart';

/// Repositório para persistência das leituras do penetrômetro
class PenetrometroReadingRepository {
  Database? _db;
  static const String _tableName = 'penetrometro_readings';

  /// Inicializa o banco de dados
  Future<void> init() async {
    try {
      final dbPath = await getDatabasesPath();
      _db = await openDatabase(
        join(dbPath, 'fortsmart_penetrometro.db'),
        version: 1,
        onCreate: (db, version) async {
          await _createTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 1) {
            await _createTable(db);
          }
        },
      );
    } catch (e) {
      throw Exception('Erro ao inicializar banco de dados: $e');
    }
  }

  /// Cria a tabela de leituras
  Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profundidade REAL NOT NULL,
        resistencia REAL NOT NULL,
        timestamp TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        deviceId TEXT NOT NULL,
        point_code TEXT,
        talhao_id INTEGER,
        synced INTEGER DEFAULT 0,
        observacoes TEXT,
        foto_path TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Índices para performance
    await db.execute('''
      CREATE INDEX idx_device_id ON $_tableName(deviceId)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_talhao_id ON $_tableName(talhao_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_synced ON $_tableName(synced)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');
  }

  /// Insere uma nova leitura
  Future<int> insertReading(PenetrometroReading reading) async {
    if (_db == null) await init();
    
    try {
      final id = await _db!.insert(_tableName, reading.toMap());
      return id;
    } catch (e) {
      throw Exception('Erro ao inserir leitura: $e');
    }
  }

  /// Insere múltiplas leituras em lote
  Future<void> insertReadingsBatch(List<PenetrometroReading> readings) async {
    if (_db == null) await init();
    
    try {
      final batch = _db!.batch();
      for (final reading in readings) {
        batch.insert(_tableName, reading.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao inserir leituras em lote: $e');
    }
  }

  /// Busca leitura por ID
  Future<PenetrometroReading?> getReadingById(int id) async {
    if (_db == null) await init();
    
    try {
      final maps = await _db!.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return PenetrometroReading.fromMap(maps.first);
    } catch (e) {
      throw Exception('Erro ao buscar leitura por ID: $e');
    }
  }

  /// Busca todas as leituras
  Future<List<PenetrometroReading>> getAllReadings({
    int? limit,
    int? offset,
    String? orderBy,
    bool? ascending,
  }) async {
    if (_db == null) await init();
    
    try {
      final maps = await _db!.query(
        _tableName,
        limit: limit,
        offset: offset,
        orderBy: orderBy ?? 'timestamp DESC',
      );
      
      return maps.map((map) => PenetrometroReading.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar leituras: $e');
    }
  }

  /// Busca leituras por talhão
  Future<List<PenetrometroReading>> getReadingsByTalhao(int talhaoId) async {
    if (_db == null) await init();
    
    try {
      final maps = await _db!.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'timestamp DESC',
      );
      
      return maps.map((map) => PenetrometroReading.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar leituras por talhão: $e');
    }
  }

  /// Busca leituras por dispositivo
  Future<List<PenetrometroReading>> getReadingsByDevice(String deviceId) async {
    if (_db == null) await init();
    
    try {
      final maps = await _db!.query(
        _tableName,
        where: 'deviceId = ?',
        whereArgs: [deviceId],
        orderBy: 'timestamp DESC',
      );
      
      return maps.map((map) => PenetrometroReading.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar leituras por dispositivo: $e');
    }
  }

  /// Busca leituras não sincronizadas
  Future<List<PenetrometroReading>> getUnsyncedReadings() async {
    if (_db == null) await init();
    
    try {
      final maps = await _db!.query(
        _tableName,
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );
      
      return maps.map((map) => PenetrometroReading.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar leituras não sincronizadas: $e');
    }
  }

  /// Busca leituras por período
  Future<List<PenetrometroReading>> getReadingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_db == null) await init();
    
    try {
      final maps = await _db!.query(
        _tableName,
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'timestamp DESC',
      );
      
      return maps.map((map) => PenetrometroReading.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar leituras por período: $e');
    }
  }

  /// Atualiza uma leitura
  Future<int> updateReading(PenetrometroReading reading) async {
    if (_db == null) await init();
    
    try {
      return await _db!.update(
        _tableName,
        reading.toMap(),
        where: 'id = ?',
        whereArgs: [reading.id],
      );
    } catch (e) {
      throw Exception('Erro ao atualizar leitura: $e');
    }
  }

  /// Marca leitura como sincronizada
  Future<int> markAsSynced(int id) async {
    if (_db == null) await init();
    
    try {
      return await _db!.update(
        _tableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Erro ao marcar como sincronizada: $e');
    }
  }

  /// Marca múltiplas leituras como sincronizadas
  Future<void> markAsSyncedBatch(List<int> ids) async {
    if (_db == null) await init();
    
    try {
      final batch = _db!.batch();
      for (final id in ids) {
        batch.update(
          _tableName,
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao marcar leituras como sincronizadas: $e');
    }
  }

  /// Deleta uma leitura
  Future<int> deleteReading(int id) async {
    if (_db == null) await init();
    
    try {
      return await _db!.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Erro ao deletar leitura: $e');
    }
  }

  /// Deleta leituras por talhão
  Future<int> deleteReadingsByTalhao(int talhaoId) async {
    if (_db == null) await init();
    
    try {
      return await _db!.delete(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
      );
    } catch (e) {
      throw Exception('Erro ao deletar leituras por talhão: $e');
    }
  }

  /// Deleta leituras antigas (mais de X dias)
  Future<int> deleteOldReadings(int daysOld) async {
    if (_db == null) await init();
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      return await _db!.delete(
        _tableName,
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
    } catch (e) {
      throw Exception('Erro ao deletar leituras antigas: $e');
    }
  }

  /// Conta total de leituras
  Future<int> getTotalReadings() async {
    if (_db == null) await init();
    
    try {
      final result = await _db!.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar leituras: $e');
    }
  }

  /// Conta leituras não sincronizadas
  Future<int> getUnsyncedCount() async {
    if (_db == null) await init();
    
    try {
      final result = await _db!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE synced = 0'
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar leituras não sincronizadas: $e');
    }
  }

  /// Estatísticas gerais
  Future<Map<String, dynamic>> getStatistics() async {
    if (_db == null) await init();
    
    try {
      final total = await getTotalReadings();
      final unsynced = await getUnsyncedCount();
      
      // Média de resistência
      final avgResult = await _db!.rawQuery(
        'SELECT AVG(resistencia) as avg_resistencia FROM $_tableName'
      );
      final avgResistencia = avgResult.first['avg_resistencia'] as double? ?? 0.0;
      
      // Média de profundidade
      final avgProfResult = await _db!.rawQuery(
        'SELECT AVG(profundidade) as avg_profundidade FROM $_tableName'
      );
      final avgProfundidade = avgProfResult.first['avg_profundidade'] as double? ?? 0.0;
      
      // Data da primeira leitura
      final firstResult = await _db!.rawQuery(
        'SELECT MIN(timestamp) as first_reading FROM $_tableName'
      );
      final firstReading = firstResult.first['first_reading'] as String?;
      
      // Data da última leitura
      final lastResult = await _db!.rawQuery(
        'SELECT MAX(timestamp) as last_reading FROM $_tableName'
      );
      final lastReading = lastResult.first['last_reading'] as String?;
      
      return {
        'total_readings': total,
        'unsynced_readings': unsynced,
        'avg_resistencia': avgResistencia,
        'avg_profundidade': avgProfundidade,
        'first_reading': firstReading,
        'last_reading': lastReading,
      };
    } catch (e) {
      throw Exception('Erro ao calcular estatísticas: $e');
    }
  }

  /// Fecha o banco de dados
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
