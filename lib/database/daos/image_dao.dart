import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/image.dart';

class ImageDao {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'images';

  // Inserir uma nova imagem
  Future<int> insert(MonitoringImage image) async {
    final db = await _database.database;
    return await db.insert(
      _tableName,
      image.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Atualizar uma imagem existente
  Future<int> update(MonitoringImage image) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      image.toMap(),
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }

  // Excluir uma imagem
  Future<int> delete(int id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obter uma imagem pelo ID
  Future<MonitoringImage?> getById(int id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return MonitoringImage.fromMap(maps.first);
    }
    return null;
  }

  // Obter todas as imagens de um monitoramento
  Future<List<MonitoringImage>> getByMonitoringId(int monitoringId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'monitoring_id = ?',
      whereArgs: [monitoringId],
    );
    
    return List.generate(maps.length, (i) {
      return MonitoringImage.fromMap(maps[i]);
    });
  }

  // Obter imagens pendentes de sincronização
  Future<List<MonitoringImage>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_status != 1',
    );
    
    return List.generate(maps.length, (i) {
      return MonitoringImage.fromMap(maps[i]);
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
