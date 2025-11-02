import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/models/crop_management.dart';
import 'package:sqflite/sqflite.dart';

/// Repositório para gerenciar os níveis de alerta
class AlertLevelRepository {
  final AppDatabase _database = AppDatabase();

  /// Cria um novo nível de alerta
  Future<String> create(AlertLevelConfig config) async {
    final db = await _database.database;
    
    await db.insert(
      'alert_level_configs',
      {
        'id': config.id,
        'crop_id': config.cropId,
        'item_id': config.itemId,
        'item_type': config.itemType.toString().split('.').last,
        'user_id': config.userId,
        'level': config.level.index,
        'min_index': config.minIndex,
        'max_index': config.maxIndex,
        'created_at': config.createdAt.toIso8601String(),
        'updated_at': config.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return config.id;
  }

  /// Atualiza um nível de alerta existente
  Future<void> update(AlertLevelConfig config) async {
    final db = await _database.database;
    
    await db.update(
      'alert_level_configs',
      {
        'crop_id': config.cropId,
        'item_id': config.itemId,
        'item_type': config.itemType.toString().split('.').last,
        'user_id': config.userId,
        'level': config.level.index,
        'min_index': config.minIndex,
        'max_index': config.maxIndex,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  /// Exclui um nível de alerta
  Future<void> delete(String id) async {
    final db = await _database.database;
    
    await db.delete(
      'alert_level_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém um nível de alerta pelo ID
  Future<AlertLevelConfig?> getById(String id) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'alert_level_configs',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return _mapToAlertLevelConfig(maps.first);
  }

  /// Obtém todos os níveis de alerta para uma cultura específica
  Future<List<AlertLevelConfig>> getAllForCrop(String cropId) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'alert_level_configs',
      where: 'crop_id = ?',
      whereArgs: [cropId],
    );
    
    return List.generate(maps.length, (i) {
      return _mapToAlertLevelConfig(maps[i]);
    });
  }

  /// Obtém todos os níveis de alerta para um item específico
  Future<List<AlertLevelConfig>> getAllForItem(String itemId, ItemType itemType) async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'alert_level_configs',
      where: 'item_id = ? AND item_type = ?',
      whereArgs: [itemId, itemType.toString().split('.').last],
    );
    
    return List.generate(maps.length, (i) {
      return _mapToAlertLevelConfig(maps[i]);
    });
  }

  /// Obtém todos os níveis de alerta
  Future<List<AlertLevelConfig>> getAlertLevels() async {
    final db = await _database.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'alert_level_configs',
    );
    
    return List.generate(maps.length, (i) {
      return _mapToAlertLevelConfig(maps[i]);
    });
  }

  /// Converte um mapa para um objeto AlertLevelConfig
  AlertLevelConfig _mapToAlertLevelConfig(Map<String, dynamic> map) {
    return AlertLevelConfig(
      id: map['id'],
      cropId: map['crop_id'],
      itemId: map['item_id'],
      itemType: _stringToItemType(map['item_type']),
      userId: map['user_id'],
      level: AlertLevel.values[map['level']],
      minIndex: map['min_index'],
      maxIndex: map['max_index'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Converte uma string para o enum ItemType
  ItemType _stringToItemType(String type) {
    switch (type.toLowerCase()) {
      case 'pest':
        return ItemType.pest;
      case 'disease':
        return ItemType.disease;
      default:
        return ItemType.pest;
    }
  }
}

