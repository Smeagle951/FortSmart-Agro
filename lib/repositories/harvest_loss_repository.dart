import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/harvest_loss.dart';

/// Repositório para operações com cálculos de perdas na colheita
class HarvestLossRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'harvest_losses';

  /// Cria a tabela de perdas na colheita no banco de dados
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        plotId TEXT NOT NULL,
        cropId TEXT NOT NULL,
        grainsPerArea REAL NOT NULL,
        sampleAreaSize REAL NOT NULL,
        thousandGrainWeight REAL NOT NULL,
        sampleCount INTEGER NOT NULL,
        imageUrls TEXT,
        assessmentDate TEXT NOT NULL,
        responsiblePerson TEXT NOT NULL,
        observations TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (plotId) REFERENCES plots (id) ON DELETE CASCADE,
        FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Insere um novo cálculo de perdas na colheita no banco de dados
  Future<String> insert(HarvestLoss harvestLoss) async {
    final db = await _database.database;
    await db.insert(
      _tableName,
      harvestLoss.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return harvestLoss.id;
  }

  /// Atualiza um cálculo de perdas na colheita existente
  Future<int> update(HarvestLoss harvestLoss) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      harvestLoss.toMap(),
      where: 'id = ?',
      whereArgs: [harvestLoss.id],
    );
  }

  /// Remove um cálculo de perdas na colheita
  Future<int> delete(String id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém um cálculo de perdas na colheita pelo ID
  Future<HarvestLoss?> getById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return HarvestLoss.fromMap(maps.first);
  }
  
  /// Obtém um cálculo de perdas na colheita pelo ID (alias para getById)
  Future<HarvestLoss?> getHarvestLossById(String id) async {
    return await getById(id);
  }

  /// Obtém todos os cálculos de perdas na colheita
  Future<List<HarvestLoss>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => HarvestLoss.fromMap(maps[i]));
  }
  
  /// Obtém todos os cálculos de perdas na colheita (alias para getAll)
  Future<List<HarvestLoss>> getAllHarvestLosses() async {
    return await getAll();
  }
  
  /// Insere um novo cálculo de perdas na colheita no banco de dados (alias para insert)
  Future<String> insertHarvestLoss(HarvestLoss harvestLoss) async {
    return await insert(harvestLoss);
  }
  
  /// Atualiza um cálculo de perdas na colheita existente (alias para update)
  Future<int> updateHarvestLoss(HarvestLoss harvestLoss) async {
    return await update(harvestLoss);
  }
  
  /// Exclui um cálculo de perdas na colheita (alias para delete)
  Future<int> deleteHarvestLoss(String id) async {
    return await delete(id);
  }

  /// Obtém todos os cálculos de perdas na colheita para um talhão específico
  Future<List<HarvestLoss>> getByPlotId(String plotId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'plotId = ?',
      whereArgs: [plotId],
    );
    return List.generate(maps.length, (i) => HarvestLoss.fromMap(maps[i]));
  }

  /// Obtém todos os cálculos de perdas na colheita para uma cultura específica
  Future<List<HarvestLoss>> getByCropId(String cropId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'cropId = ?',
      whereArgs: [cropId],
    );
    return List.generate(maps.length, (i) => HarvestLoss.fromMap(maps[i]));
  }

  /// Obtém todos os cálculos de perdas na colheita para uma cultura específica
  Future<List<HarvestLoss>> getHarvestLossesByCrop(String cropName) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cropName = ?',
        whereArgs: [cropName],
      );
      
      final harvestLosses = List.generate(maps.length, (i) {
        return HarvestLoss.fromMap(maps[i]);
      });
      
      return harvestLosses;
    } catch (e) {
      print('Erro ao obter perdas na colheita por cultura: $e');
      return [];
    }
  }

  /// Obtém os cálculos de perdas na colheita pendentes de sincronização
  Future<List<HarvestLoss>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => HarvestLoss.fromMap(maps[i]));
  }

  /// Marca um cálculo de perdas na colheita como sincronizado
  Future<int> markAsSynced(String id) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém a contagem total de cálculos de perdas na colheita
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
