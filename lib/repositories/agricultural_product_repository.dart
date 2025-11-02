import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/agricultural_product.dart';

/// Repositório para operações com produtos agrícolas
class AgriculturalProductRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'agricultural_products';

  /// Cria a tabela de produtos agrícolas no banco de dados
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        manufacturer TEXT,
        type INTEGER NOT NULL,
        activeIngredient TEXT,
        concentration TEXT,
        registrationNumber TEXT,
        safetyInterval TEXT,
        applicationInstructions TEXT,
        dosageRecommendation TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        fazendaId TEXT
      )
    ''');
  }

  /// Insere um novo produto agrícola no banco de dados
  Future<String> insert(AgriculturalProduct product) async {
    final db = await _database.database;
    await db.insert(
      _tableName,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return product.id;
  }

  /// Atualiza um produto agrícola existente
  Future<int> update(AgriculturalProduct product) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Remove um produto agrícola
  Future<int> delete(String id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém um produto agrícola pelo ID
  Future<AgriculturalProduct?> getById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return AgriculturalProduct.fromMap(maps.first);
  }

  /// Obtém todos os produtos agrícolas
  Future<List<AgriculturalProduct>> getAll({String? fazendaId}) async {
    final db = await _database.database;
    
    List<Map<String, dynamic>> maps;

    if (fazendaId != null) {
      maps = await db.query(
        _tableName,
        where: 'fazendaId = ?',
        whereArgs: [fazendaId],
      );
    } else {
      maps = await db.query(_tableName);
    }

    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }

  /// Obtém todos os produtos de um tipo específico
  Future<List<AgriculturalProduct>> getByType(ProductType type) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [type.index],
    );
    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }
  
  /// Obtém todos os produtos de um tipo específico usando o índice
  Future<List<AgriculturalProduct>> getByTypeIndex(int typeIndex) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [typeIndex],
    );
    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }

  /// Obtém todos os herbicidas
  Future<List<AgriculturalProduct>> getHerbicides() async {
    return getByType(ProductType.herbicide);
  }

  /// Obtém todos os inseticidas
  Future<List<AgriculturalProduct>> getInsecticides() async {
    return getByType(ProductType.insecticide);
  }

  /// Obtém todos os fungicidas
  Future<List<AgriculturalProduct>> getFungicides() async {
    return getByType(ProductType.fungicide);
  }

  /// Obtém todos os fertilizantes
  Future<List<AgriculturalProduct>> getFertilizers() async {
    return getByType(ProductType.fertilizer);
  }

  /// Obtém todos os produtos por fabricante
  Future<List<AgriculturalProduct>> getByManufacturer(String manufacturer) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'manufacturer LIKE ?',
      whereArgs: ['%$manufacturer%'],
    );
    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }

  /// Obtém os produtos agrícolas pendentes de sincronização
  Future<List<AgriculturalProduct>> getPendingSync() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }

  /// Marca um produto agrícola como sincronizado
  Future<int> markAsSynced(String id) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém a contagem total de produtos agrícolas
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  /// Obtém produtos por tipo usando string
  Future<List<AgriculturalProduct>> getProductsByType(String typeStr) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [_getTypeIndex(typeStr)],
    );
    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }
  
  /// Obtém produtos por múltiplos tipos usando strings
  Future<List<AgriculturalProduct>> getProductsByTypes(List<String> typeStrs) async {
    if (typeStrs.isEmpty) return [];
    
    final db = await _database.database;
    final List<int> typeIndices = typeStrs.map((t) => _getTypeIndex(t)).toList();
    
    final placeholders = List.filled(typeIndices.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category IN ($placeholders)',
      whereArgs: typeIndices,
    );
    
    return List.generate(maps.length, (i) => AgriculturalProduct.fromMap(maps[i]));
  }
  
  /// Converte string de tipo para índice de enum
  int _getTypeIndex(String typeStr) {
    switch (typeStr.toUpperCase()) {
      case 'HERBICIDE':
        return ProductType.herbicide.index;
      case 'INSECTICIDE':
        return ProductType.insecticide.index;
      case 'FUNGICIDE':
        return ProductType.fungicide.index;
      case 'FERTILIZER':
        return ProductType.fertilizer.index;
      case 'GROWTH':
        return ProductType.growth.index;
      case 'ADJUVANT':
        return ProductType.adjuvant.index;
      case 'SEED':
      case 'CROP':
        return ProductType.seed.index;
      case 'PEST':
      case 'DISEASE':
      case 'WEED':
        return ProductType.other.index;
      default:
        return ProductType.other.index;
    }
  }
}
