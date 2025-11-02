import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/inventory.dart';

class InventoryDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'inventory';

  // Inserir um novo item de estoque
  Future<int> insert(InventoryItem item) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar um item de estoque existente
  Future<int> update(InventoryItem item) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Excluir um item de estoque
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter um item de estoque pelo ID
  Future<InventoryItem?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return InventoryItem.fromMap(maps.first);
    }
    return null;
  }

  // Obter todos os itens de estoque
  Future<List<InventoryItem>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    
    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  // Obter itens de estoque por categoria
  Future<List<InventoryItem>> getByCategory(String category) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
    );
    
    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  // Obter itens com estoque baixo
  Future<List<InventoryItem>> getLowStock(double threshold) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'quantity <= ?',
      whereArgs: [threshold],
    );
    
    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  // Obter itens pendentes de sincronização
  Future<List<InventoryItem>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status != 1',
    );
    
    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
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
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar itens por nome ou código
  Future<List<InventoryItem>> searchItems(String query) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    
    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }
}
