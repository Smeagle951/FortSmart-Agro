import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/prescription_item.dart';

class PrescriptionItemDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'prescription_items';

  // Inserir um novo item de prescrição
  Future<int> insert(PrescriptionItem item) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar um item de prescrição existente
  Future<int> update(PrescriptionItem item) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Excluir um item de prescrição
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Excluir todos os itens de uma prescrição
  Future<int> deleteByPrescriptionId(int prescriptionId) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
    );
  }

  // Obter um item de prescrição pelo ID
  Future<PrescriptionItem?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PrescriptionItem.fromMap(maps.first);
    }
    return null;
  }

  // Obter todos os itens para uma prescrição específica
  Future<List<PrescriptionItem>> getByPrescriptionId(int prescriptionId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return PrescriptionItem.fromMap(maps[i]);
    });
  }

  // Obter todos os itens que usam um produto específico
  Future<List<PrescriptionItem>> getByProductId(int productId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PrescriptionItem.fromMap(maps[i]);
    });
  }

  // Obter todos os itens de prescrição
  Future<List<PrescriptionItem>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PrescriptionItem.fromMap(maps[i]);
    });
  }

  // Inserir múltiplos itens de prescrição em uma transação
  Future<void> insertMultiple(List<PrescriptionItem> items) async {
    final db = await _database.database;
    
    await db.transaction((txn) async {
      for (var item in items) {
        await txn.insert(
          _tableName,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Atualizar status de sincronização
  Future<int> updateSyncStatus(int id, int syncStatus, {int? remoteId}) async {
    final db = await _database.database;
    final Map<String, dynamic> values = {
      'sync_status': syncStatus,
      if (remoteId != null) 'remote_id': remoteId,
    };
    
    return await db.update(
      _tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter itens de prescrição não sincronizados
  Future<List<PrescriptionItem>> getUnsyncedPrescriptionItems() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return PrescriptionItem.fromMap(maps[i]);
    });
  }
}
