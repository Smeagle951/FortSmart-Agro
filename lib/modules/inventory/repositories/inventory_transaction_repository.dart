import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../models/inventory_transaction_model.dart';

class InventoryTransactionRepository {
  final AppDatabase _appDatabase = AppDatabase();
  
  // Nome da tabela
  static const String tableName = 'inventory_transactions';
  
  // Colunas da tabela
  static const String columnId = 'id';
  static const String columnProductId = 'product_id';
  static const String columnTransactionType = 'transaction_type';
  static const String columnQuantity = 'quantity';
  static const String columnUnit = 'unit';
  static const String columnBatchNumber = 'batch_number';
  static const String columnExpirationDate = 'expiration_date';
  static const String columnApplicationId = 'application_id';
  static const String columnPlotId = 'plot_id';
  static const String columnCropId = 'crop_id';
  static const String columnNotes = 'notes';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsSynced = 'is_synced';
  
  // Construtor
  InventoryTransactionRepository();
  
  // Getter para o database
  Future<Database> get database => _appDatabase.database;
  
  // Criar tabela
  Future<void> createTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnProductId TEXT NOT NULL,
        $columnTransactionType TEXT NOT NULL,
        $columnQuantity REAL NOT NULL,
        $columnUnit TEXT NOT NULL,
        $columnBatchNumber TEXT,
        $columnExpirationDate TEXT,
        $columnApplicationId TEXT,
        $columnPlotId TEXT,
        $columnCropId TEXT,
        $columnNotes TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnIsSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY ($columnProductId) REFERENCES inventory_products (id) ON DELETE CASCADE
      )
    ''');
  }
  
  // Inserir uma transação
  Future<int> insert(InventoryTransactionModel transaction) async {
    final db = await database;
    return await db.insert(
      tableName,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Atualizar uma transação
  Future<int> update(InventoryTransactionModel transaction) async {
    final db = await database;
    return await db.update(
      tableName,
      transaction.toMap(),
      where: '$columnId = ?',
      whereArgs: [transaction.id],
    );
  }
  
  // Excluir uma transação
  Future<int> delete(String id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  
  // Obter uma transação pelo ID
  Future<InventoryTransactionModel?> getById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return InventoryTransactionModel.fromMap(maps.first);
  }
  
  // Obter todas as transações
  Future<List<InventoryTransactionModel>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações paginadas
  Future<List<InventoryTransactionModel>> getPaginated({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    final db = await database;
    String whereClause = '';
    List<Object> whereArgs = [];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'WHERE $columnNotes LIKE ?';
      whereArgs = ['%$searchQuery%'];
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      $whereClause
      ORDER BY $columnCreatedAt DESC
      LIMIT ? OFFSET ?
    ''', [...whereArgs, limit, offset]);
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações por produto
  Future<List<InventoryTransactionModel>> getByProductId(
    String productId, {
    int? limit,
    int? offset,
    String? orderBy,
    bool? descending,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnProductId = ?',
      whereArgs: [productId],
      orderBy: orderBy != null 
          ? '${descending == true ? '$orderBy DESC' : orderBy}'
          : '$columnCreatedAt DESC',
      limit: limit,
      offset: offset,
    );
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações por número do lote
  Future<List<InventoryTransactionModel>> getByBatchNumber(String batchNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnBatchNumber = ?',
      whereArgs: [batchNumber],
      orderBy: '$columnCreatedAt DESC',
    );
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações por aplicação
  Future<List<InventoryTransactionModel>> getByApplicationId(String applicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnApplicationId = ?',
      whereArgs: [applicationId],
      orderBy: '$columnCreatedAt DESC',
    );
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações por tipo
  Future<List<InventoryTransactionModel>> getByType(String transactionType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnTransactionType = ?',
      whereArgs: [transactionType],
      orderBy: '$columnCreatedAt DESC',
    );
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações por período
  Future<List<InventoryTransactionModel>> getByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnCreatedAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: '$columnCreatedAt DESC',
    );
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter transações filtradas
  Future<List<InventoryTransactionModel>> getFiltered({
    String? productId,
    String? transactionType,
    String? batchNumber,
    String? applicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    List<String> whereConditions = [];
    List<Object> whereArgs = [];
    
    if (productId != null && productId.isNotEmpty) {
      whereConditions.add('$columnProductId = ?');
      whereArgs.add(productId);
    }
    
    if (transactionType != null && transactionType.isNotEmpty) {
      whereConditions.add('$columnTransactionType = ?');
      whereArgs.add(transactionType);
    }
    
    if (batchNumber != null && batchNumber.isNotEmpty) {
      whereConditions.add('$columnBatchNumber = ?');
      whereArgs.add(batchNumber);
    }
    
    if (applicationId != null && applicationId.isNotEmpty) {
      whereConditions.add('$columnApplicationId = ?');
      whereArgs.add(applicationId);
    }
    
    if (startDate != null && endDate != null) {
      whereConditions.add('$columnCreatedAt BETWEEN ? AND ?');
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }
    
    String whereClause = '';
    if (whereConditions.isNotEmpty) {
      whereClause = 'WHERE ${whereConditions.join(' AND ')}';
    }
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $tableName 
      $whereClause
      ORDER BY $columnCreatedAt DESC
    ''', whereArgs);
    
    return List.generate(maps.length, (i) => InventoryTransactionModel.fromMap(maps[i]));
  }
  
  // Obter saldo de um produto
  Future<double> getProductBalance(String productId) async {
    final db = await database;
    
    // Calcular entrada total
    final entradaResult = await db.rawQuery('''
      SELECT COALESCE(SUM($columnQuantity), 0) as total
      FROM $tableName 
      WHERE $columnProductId = ? AND $columnTransactionType = 'entrada'
    ''', [productId]);
    
    final entradaTotal = entradaResult.first['total'] as double? ?? 0.0;
    
    // Calcular saída total
    final saidaResult = await db.rawQuery('''
      SELECT COALESCE(SUM($columnQuantity), 0) as total
      FROM $tableName 
      WHERE $columnProductId = ? AND $columnTransactionType = 'saida'
    ''', [productId]);
    
    final saidaTotal = saidaResult.first['total'] as double? ?? 0.0;
    
    return entradaTotal - saidaTotal;
  }
  
  // Obter estatísticas de transações
  Future<Map<String, dynamic>> getTransactionStats() async {
    final db = await database;
    
    final totalTransactions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName')
    ) ?? 0;
    
    final entradaTransactions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE $columnTransactionType = "entrada"')
    ) ?? 0;
    
    final saidaTransactions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE $columnTransactionType = "saida"')
    ) ?? 0;
    
    final entradaResult = await db.rawQuery('SELECT COALESCE(SUM($columnQuantity), 0) as total FROM $tableName WHERE $columnTransactionType = "entrada"');
    final totalEntrada = entradaResult.first['total'] as double? ?? 0.0;
    
    final saidaResult = await db.rawQuery('SELECT COALESCE(SUM($columnQuantity), 0) as total FROM $tableName WHERE $columnTransactionType = "saida"');
    final totalSaida = saidaResult.first['total'] as double? ?? 0.0;
    
    return {
      'total_transactions': totalTransactions,
      'entrada_transactions': entradaTransactions,
      'saida_transactions': saidaTransactions,
      'total_entrada': totalEntrada,
      'total_saida': totalSaida,
      'saldo_total': totalEntrada - totalSaida,
    };
  }
}
