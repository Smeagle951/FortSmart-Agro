import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/inventory_movement.dart';

class InventoryMovementDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'inventory_movements';

  // Inserir um novo movimento de estoque
  Future<int> insert(InventoryMovement movement) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      movement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar um movimento de estoque existente
  Future<int> update(InventoryMovement movement) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      movement.toMap(),
      where: 'id = ?',
      whereArgs: [movement.id],
    );
  }

  // Excluir um movimento de estoque
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter um movimento de estoque pelo ID
  Future<InventoryMovement?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return InventoryMovement.fromMap(maps.first);
    }
    return null;
  }

  // Obter todos os movimentos de estoque
  Future<List<InventoryMovement>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return InventoryMovement.fromMap(maps[i]);
    });
  }

  // Obter movimentos de estoque por item
  Future<List<InventoryMovement>> getByItemId(int itemId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return InventoryMovement.fromMap(maps[i]);
    });
  }

  // Obter movimentos de estoque por atividade
  Future<List<InventoryMovement>> getByActivityId(String activityId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return InventoryMovement.fromMap(maps[i]);
    });
  }

  // Obter movimentos de estoque por intervalo de data
  Future<List<InventoryMovement>> getByDateRange(String startDate, String endDate) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return InventoryMovement.fromMap(maps[i]);
    });
  }

  // Obter movimentos pendentes de sincronização
  Future<List<InventoryMovement>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status != 1',
    );
    
    return List.generate(maps.length, (i) {
      return InventoryMovement.fromMap(maps[i]);
    });
  }

  // Atualizar o status de sincronização
  Future<int> updateSyncStatus(int id, int syncStatus, int? remoteId) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      {
        'sync_status': syncStatus,
        'remote_id': remoteId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
