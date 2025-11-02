import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/inventory_product_model.dart';

class InventoryProductRepository {
  final AppDatabase _appDatabase = AppDatabase();
  
  // Nome da tabela
  static const String tableName = 'inventory_products';
  
  // Colunas da tabela
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnCategory = 'category';
  static const String columnClass = 'class';
  static const String columnUnit = 'unit';
  static const String columnMinStock = 'min_stock';
  static const String columnMaxStock = 'max_stock';
  static const String columnCurrentStock = 'current_stock';
  static const String columnPrice = 'price';
  static const String columnSupplier = 'supplier';
  static const String columnBatchNumber = 'batch_number';
  static const String columnExpirationDate = 'expiration_date';
  static const String columnManufacturingDate = 'manufacturing_date';
  static const String columnRegistrationNumber = 'registration_number';
  static const String columnActiveIngredient = 'active_ingredient';
  static const String columnConcentration = 'concentration';
  static const String columnFormulation = 'formulation';
  static const String columnToxicityClass = 'toxicity_class';
  static const String columnApplicationMethod = 'application_method';
  static const String columnWaitingPeriod = 'waiting_period';
  static const String columnNotes = 'notes';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsSynced = 'is_synced';
  
  // Construtor
  InventoryProductRepository();
  
  // Getter para o database
  Future<Database> get database => _appDatabase.database;
  
  // Criar tabela
  Future<void> createTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnDescription TEXT,
        $columnCategory TEXT NOT NULL,
        $columnClass TEXT NOT NULL,
        $columnUnit TEXT NOT NULL,
        $columnMinStock REAL NOT NULL DEFAULT 0,
        $columnMaxStock REAL,
        $columnCurrentStock REAL NOT NULL DEFAULT 0,
        $columnPrice REAL,
        $columnSupplier TEXT,
        $columnBatchNumber TEXT,
        $columnExpirationDate TEXT,
        $columnManufacturingDate TEXT,
        $columnRegistrationNumber TEXT,
        $columnActiveIngredient TEXT,
        $columnConcentration TEXT,
        $columnFormulation TEXT,
        $columnToxicityClass TEXT,
        $columnApplicationMethod TEXT,
        $columnWaitingPeriod INTEGER,
        $columnNotes TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnIsSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
  
  // Inserir um produto
  Future<int> insert(InventoryProductModel product) async {
    try {
      final db = await database;
      final productMap = product.toMap();
      
      print('🔄 Inserindo produto na tabela $tableName');
      print('📊 Dados do produto: $productMap');
      
      final result = await db.insert(
        tableName,
        productMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ Produto inserido com sucesso (ID: $result)');
      return result;
    } catch (e) {
      print('❌ Erro ao inserir produto: $e');
      print('📊 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  // Atualizar um produto
  Future<int> update(InventoryProductModel product) async {
    final db = await database;
    return await db.update(
      tableName,
      product.toMap(),
      where: '$columnId = ?',
      whereArgs: [product.id],
    );
  }
  
  // Excluir um produto
  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Obter um produto pelo ID
  Future<InventoryProductModel?> getById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return InventoryProductModel.fromMap(maps.first);
  }
  
  // Obter todos os produtos
  Future<List<InventoryProductModel>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Obter produtos paginados
  Future<List<InventoryProductModel>> getPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<Object> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE $columnName LIKE ? OR $columnDescription LIKE ?';
      whereArgs = ['%$searchQuery%', '%$searchQuery%'];
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      $whereClause
      ORDER BY $columnName ASC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Obter produtos filtrados
  Future<List<InventoryProductModel>> getFiltered({
    String? nameFilter,
    String? categoryFilter,
    int? typeFilter,
    String? classFilter,
    String? searchQuery,
    bool? lowStockFilter,
    bool? criticalStockFilter,
    bool? expiringFilter,
    bool? expiredFilter,
    bool? lowStockOnly,
    bool? nearExpirationOnly,
    int? limit,
    int? offset,
    String? orderBy,
    bool? descending,
  }) async {
    final db = await database;
    List<String> whereConditions = [];
    List<Object> whereArgs = [];
    
    if (nameFilter != null && nameFilter.isNotEmpty) {
      whereConditions.add('$columnName LIKE ?');
      whereArgs.add('%$nameFilter%');
    }
    
    if (typeFilter != null) {
      whereConditions.add('$columnCategory = ?');
      whereArgs.add(typeFilter);
    }
    
    if (classFilter != null && classFilter.isNotEmpty) {
      whereConditions.add('$columnClass = ?');
      whereArgs.add(classFilter);
    }
    
    if (lowStockFilter == true) {
      whereConditions.add('$columnCurrentStock <= $columnMinStock * 1.3');
    }
    
    if (criticalStockFilter == true) {
      whereConditions.add('$columnCurrentStock <= $columnMinStock');
    }
    
    if (expiringFilter == true) {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(Duration(days: 30));
      whereConditions.add('$columnExpirationDate BETWEEN ? AND ?');
      whereArgs.addAll([
        now.toIso8601String(),
        thirtyDaysFromNow.toIso8601String(),
      ]);
    }
    
    if (expiredFilter == true) {
      final now = DateTime.now();
      whereConditions.add('$columnExpirationDate < ?');
      whereArgs.add(now.toIso8601String());
    }
    
    String whereClause = '';
    if (whereConditions.isNotEmpty) {
      whereClause = 'WHERE ${whereConditions.join(' AND ')}';
    }
    
    // Ordenação
    String orderClause = 'ORDER BY $columnName ASC';
    if (orderBy != null) {
      final direction = descending == true ? 'DESC' : 'ASC';
      orderClause = 'ORDER BY $orderBy $direction';
    }
    
    // Paginação
    String limitClause = '';
    if (limit != null) {
      limitClause = 'LIMIT $limit';
      if (offset != null) {
        limitClause += ' OFFSET $offset';
      }
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      $whereClause
      $orderClause
      $limitClause
    ''', whereArgs);
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Buscar produtos por nome
  Future<List<InventoryProductModel>> searchByName(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnName LIKE ?',
      whereArgs: ['%$query%'],
    );
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Buscar produtos por categoria
  Future<List<InventoryProductModel>> getByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnCategory = ?',
      whereArgs: [category],
    );
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Buscar produtos por classe
  Future<List<InventoryProductModel>> getByClass(String productClass) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnClass = ?',
      whereArgs: [productClass],
    );
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Atualizar estoque de um produto
  Future<int> updateStock(String id, double newStock) async {
    final db = await database;
    return await db.update(
      tableName,
      {
        columnCurrentStock: newStock,
        columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Obter produtos com estoque baixo
  Future<List<InventoryProductModel>> getLowStockProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE $columnCurrentStock <= $columnMinStock
      ORDER BY $columnCurrentStock ASC
    ''');
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Obter produtos com estoque crítico
  Future<List<InventoryProductModel>> getCriticalStockProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE $columnCurrentStock = 0
      ORDER BY $columnName ASC
    ''');
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Obter produtos próximos do vencimento
  Future<List<InventoryProductModel>> getNearExpirationProducts() async {
    final db = await database;
    final thirtyDaysFromNow = DateTime.now().add(Duration(days: 30)).toIso8601String();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE $columnExpirationDate <= ? AND $columnExpirationDate > ?
      ORDER BY $columnExpirationDate ASC
    ''', [thirtyDaysFromNow, DateTime.now().toIso8601String()]);
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Obter produtos vencidos
  Future<List<InventoryProductModel>> getExpiredProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      WHERE $columnExpirationDate <= ?
      ORDER BY $columnExpirationDate ASC
    ''', [DateTime.now().toIso8601String()]);
    
    return List.generate(maps.length, (i) => InventoryProductModel.fromMap(maps[i]));
  }
  
  // Obter estatísticas do inventário
  Future<Map<String, dynamic>> getInventoryStats() async {
    final db = await database;
    
    final totalProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName')
    ) ?? 0;
    
    final lowStockCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE $columnCurrentStock <= $columnMinStock')
    ) ?? 0;
    
    final criticalStockCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE $columnCurrentStock = 0')
    ) ?? 0;
    
    final totalValueResult = await db.rawQuery('SELECT SUM($columnCurrentStock * $columnPrice) as total FROM $tableName WHERE $columnPrice IS NOT NULL');
    final totalValue = totalValueResult.first['total'] as double? ?? 0.0;
    
    return {
      'total_products': totalProducts,
      'low_stock_count': lowStockCount,
      'critical_stock_count': criticalStockCount,
      'total_value': totalValue,
    };
  }
}
