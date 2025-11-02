import '../models/stock_model.dart';
import '../../../database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class StockRepository {
  final AppDatabase _database = AppDatabase();
  final String table = 'estoque';

  Future<void> insert(StockModel model) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<StockModel>> getAll() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: 'dateTime DESC');
    return maps.map((map) => StockModel.fromMap(map)).toList();
  }

  Future<StockModel?> getById(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return StockModel.fromMap(maps.first);
  }

  Future<void> delete(String id) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<StockModel>> getUnsynced() async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(table, where: 'isSynced = 0');
    return maps.map((map) => StockModel.fromMap(map)).toList();
  }

  /// Obtém todas as movimentações de estoque de um produto específico
  /// 
  /// [productId] - ID do produto
  Future<List<StockModel>> getByProductId(String productId) async {
    await _database.ensureDatabaseOpen();
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      table, 
      where: 'product = ?', 
      whereArgs: [productId],
      orderBy: 'dateTime DESC'
    );
    return maps.map((map) => StockModel.fromMap(map)).toList();
  }
}
