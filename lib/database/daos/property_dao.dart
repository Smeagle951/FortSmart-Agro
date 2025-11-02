import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/property.dart';

class PropertyDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'properties';

  // Inserir uma nova propriedade
  Future<int> insert(Property property) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      property.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar uma propriedade existente
  Future<int> update(Property property) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      property.toMap(),
      where: 'id = ?',
      whereArgs: [property.id],
    );
  }

  // Excluir uma propriedade
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter uma propriedade pelo ID
  Future<Property?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Property.fromMap(maps.first);
    }
    return null;
  }

  // Obter todas as propriedades
  Future<List<Property>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    
    return List.generate(maps.length, (i) {
      return Property.fromMap(maps[i]);
    });
  }

  // Obter propriedades pendentes de sincronização
  Future<List<Property>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status != 1',
    );
    
    return List.generate(maps.length, (i) {
      return Property.fromMap(maps[i]);
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
}
