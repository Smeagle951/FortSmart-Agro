import '../database/app_database.dart';
import '../models/crop_management.dart';
import 'base_repository.dart';

/// Repositório para gerenciar culturas
class CropManagementRepository extends BaseRepository<Crop> {
  final AppDatabase _database = AppDatabase();

  @override
  String get tableName => 'farm_crops';
  
  @override
  String get entityName => 'crop';
  
  @override
  Crop fromMap(Map<String, dynamic> map) => Crop.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Crop entity) => entity.toMap();
  
  @override
  String getId(Crop entity) => entity.id;

  /// Cria a tabela de culturas no banco de dados
  Future<void> createTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        origin INTEGER NOT NULL,
        createdBy TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Insere dados padrão de culturas
  Future<void> insertDefaultCrops() async {
    final List<Crop> defaultCrops = [
      Crop(name: 'Soja'),
      Crop(name: 'Milho'),
      Crop(name: 'Algodão'),
      Crop(name: 'Feijão'),
      Crop(name: 'Girassol'),
      Crop(name: 'Arroz'),
      Crop(name: 'Sorgo'),
      Crop(name: 'Gergelim'),
      Crop(name: 'Cana-de-açúcar'),
      Crop(name: 'Tomate'),
    ];

    for (var crop in defaultCrops) {
      try {
        await insert(crop);
      } catch (e) {
        print('Erro ao inserir cultura padrão ${crop.name}: $e');
      }
    }
  }

  /// Verifica se existem culturas no banco de dados
  Future<bool> hasAnyData() async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> result = await db.query(
        tableName,
        limit: 1,
      );
      
      return result.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar existência de culturas: $e');
      return false;
    }
  }

  /// Obtém culturas por nome
  Future<List<Crop>> searchByName(String name) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$name%'],
      );
      
      return List.generate(maps.length, (i) {
        return Crop.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar culturas por nome: $e');
      return [];
    }
  }
}

/// Repositório para gerenciar itens de cultura (pragas e doenças)
class CropItemRepository extends BaseRepository<CropItem> {
  final AppDatabase _database = AppDatabase();

  @override
  String get tableName => 'crop_items';
  
  @override
  String get entityName => 'crop_item';
  
  @override
  CropItem fromMap(Map<String, dynamic> map) => CropItem.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(CropItem entity) => entity.toMap();
  
  @override
  String getId(CropItem entity) => entity.id;

  /// Cria a tabela de itens de cultura no banco de dados
  Future<void> createTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        cropId TEXT NOT NULL,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        origin INTEGER NOT NULL,
        createdBy TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (cropId) REFERENCES farm_crops (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Insere dados padrão de pragas e doenças
  Future<void> insertDefaultItems() async {
    final cropRepo = CropManagementRepository();
    final crops = await cropRepo.getAll();
    
    if (crops.isEmpty) return;
    
    // Mapa de itens padrão por cultura
    final Map<String, List<Map<String, dynamic>>> defaultItemsByCrop = {
      'Soja': [
        {'name': 'Lagarta-da-soja', 'type': ItemType.pest},
        {'name': 'Percevejo-marrom', 'type': ItemType.pest},
        {'name': 'Ferrugem asiática', 'type': ItemType.disease},
        {'name': 'Mofo branco', 'type': ItemType.disease},
      ],
      'Milho': [
        {'name': 'Lagarta-do-cartucho', 'type': ItemType.pest},
        {'name': 'Cigarrinha-do-milho', 'type': ItemType.pest},
        {'name': 'Ferrugem comum', 'type': ItemType.disease},
        {'name': 'Mancha branca', 'type': ItemType.disease},
      ],
      'Algodão': [
        {'name': 'Bicudo-do-algodoeiro', 'type': ItemType.pest},
        {'name': 'Lagarta-rosada', 'type': ItemType.pest},
        {'name': 'Ramulária', 'type': ItemType.disease},
        {'name': 'Ramulose', 'type': ItemType.disease},
      ],
    };
    
    for (var crop in crops) {
      if (defaultItemsByCrop.containsKey(crop.name)) {
        final items = defaultItemsByCrop[crop.name]!;
        for (var item in items) {
          try {
            await insert(CropItem(
              cropId: crop.id,
              name: item['name'] as String,
              type: item['type'] as ItemType,
            ));
          } catch (e) {
            print('Erro ao inserir item padrão ${item['name']} para ${crop.name}: $e');
          }
        }
      }
    }
  }

  /// Obtém itens por cultura
  Future<List<CropItem>> getByCropId(String cropId) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cropId = ?',
        whereArgs: [cropId],
      );
      
      return List.generate(maps.length, (i) {
        return CropItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar itens por cultura: $e');
      return [];
    }
  }

  /// Obtém pragas por cultura
  Future<List<CropItem>> getPestsByCropId(String cropId) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cropId = ? AND type = ?',
        whereArgs: [cropId, ItemType.pest.index],
      );
      
      return List.generate(maps.length, (i) {
        return CropItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar pragas por cultura: $e');
      return [];
    }
  }

  /// Obtém doenças por cultura
  Future<List<CropItem>> getDiseasesByCropId(String cropId) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cropId = ? AND type = ?',
        whereArgs: [cropId, ItemType.disease.index],
      );
      
      return List.generate(maps.length, (i) {
        return CropItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar doenças por cultura: $e');
      return [];
    }
  }

  /// Obtém plantas daninhas por cultura
  Future<List<CropItem>> getWeedsByCropId(String cropId) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cropId = ? AND type = ?',
        whereArgs: [cropId, ItemType.weed.index],
      );
      
      return List.generate(maps.length, (i) {
        return CropItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar plantas daninhas por cultura: $e');
      return [];
    }
  }

}

/// Repositório para gerenciar plantas daninhas
class WeedRepository extends BaseRepository<Weed> {
  final AppDatabase _database = AppDatabase();

  @override
  String get tableName => 'weeds';
  
  @override
  String get entityName => 'weed';
  
  @override
  Weed fromMap(Map<String, dynamic> map) => Weed.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(Weed entity) => entity.toMap();
  
  @override
  String getId(Weed entity) => entity.id;

  /// Cria a tabela de plantas daninhas no banco de dados
  Future<void> createTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        origin INTEGER NOT NULL,
        createdBy TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Insere dados padrão de plantas daninhas
  Future<void> insertDefaultWeeds() async {
    final List<Weed> defaultWeeds = [
      Weed(name: 'Capim-amargoso'),
      Weed(name: 'Buva'),
      Weed(name: 'Picão-preto'),
      Weed(name: 'Caruru'),
      Weed(name: 'Capim-pé-de-galinha'),
      Weed(name: 'Trapoeraba'),
      Weed(name: 'Leiteiro'),
      Weed(name: 'Corda-de-viola'),
      Weed(name: 'Guanxuma'),
      Weed(name: 'Erva-quente'),
    ];

    for (var weed in defaultWeeds) {
      try {
        await insert(weed);
      } catch (e) {
        print('Erro ao inserir planta daninha padrão ${weed.name}: $e');
      }
    }
  }

  /// Obtém plantas daninhas por nome
  Future<List<Weed>> searchByName(String name) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$name%'],
      );
      
      return List.generate(maps.length, (i) {
        return Weed.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar plantas daninhas por nome: $e');
      return [];
    }
  }
}

/// Repositório para gerenciar níveis de alerta
class AlertLevelRepository extends BaseRepository<AlertLevelConfig> {
  final AppDatabase _database = AppDatabase();

  @override
  String get tableName => 'alert_levels';
  
  @override
  String get entityName => 'alert_level';
  
  @override
  AlertLevelConfig fromMap(Map<String, dynamic> map) => AlertLevelConfig.fromMap(map);
  
  @override
  Map<String, dynamic> toMap(AlertLevelConfig entity) => entity.toMap();
  
  @override
  String getId(AlertLevelConfig entity) => entity.id;

  /// Cria a tabela de níveis de alerta no banco de dados
  Future<void> createTable(dynamic db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        cropId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        itemType INTEGER NOT NULL,
        level INTEGER NOT NULL,
        minIndex INTEGER NOT NULL,
        maxIndex INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (cropId) REFERENCES farm_crops (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Obtém níveis de alerta por cultura e item
  Future<List<AlertLevelConfig>> getByCropAndItem(String cropId, String itemId, ItemType itemType) async {
    try {
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'cropId = ? AND itemId = ? AND itemType = ?',
        whereArgs: [cropId, itemId, itemType.index],
      );
      
      return List.generate(maps.length, (i) {
        return AlertLevelConfig.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao buscar níveis de alerta: $e');
      return [];
    }
  }

  /// Insere ou atualiza níveis de alerta padrão para um item
  Future<void> setDefaultAlertLevels(String userId, String cropId, String itemId, ItemType itemType) async {
    try {
      // Excluir níveis existentes
      await _database.ensureDatabaseOpen();
      final db = await _database.database;
      
      await db.delete(
        tableName,
        where: 'cropId = ? AND itemId = ? AND itemType = ?',
        whereArgs: [cropId, itemId, itemType.index],
      );
      
      // Inserir níveis padrão
      final List<AlertLevelConfig> defaultLevels = [
        AlertLevelConfig(
          userId: userId,
          cropId: cropId,
          itemId: itemId,
          itemType: itemType,
          level: AlertLevel.low,
          minIndex: 1,
          maxIndex: 3,
        ),
        AlertLevelConfig(
          userId: userId,
          cropId: cropId,
          itemId: itemId,
          itemType: itemType,
          level: AlertLevel.medium,
          minIndex: 4,
          maxIndex: 6,
        ),
        AlertLevelConfig(
          userId: userId,
          cropId: cropId,
          itemId: itemId,
          itemType: itemType,
          level: AlertLevel.high,
          minIndex: 7,
          maxIndex: 10,
        ),
      ];
      
      for (var level in defaultLevels) {
        await insert(level);
      }
    } catch (e) {
      print('Erro ao definir níveis de alerta padrão: $e');
    }
  }
}
