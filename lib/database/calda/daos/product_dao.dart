import 'package:sqflite/sqflite.dart';
import '../calda_database.dart';
import '../../../models/calda/product.dart';

/// DAO para operações com produtos
class ProductDao {
  static const String _tableName = 'products';

  /// Adiciona um novo produto
  static Future<int> insert(Product product) async {
    final db = await CaldaDatabase.database;
    return await db.insert(_tableName, product.toMap());
  }

  /// Busca todos os produtos
  static Future<List<Product>> findAll() async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  /// Busca produto por ID
  static Future<Product?> findById(int id) async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  /// Atualiza um produto
  static Future<int> update(Product product) async {
    final db = await CaldaDatabase.database;
    return await db.update(
      _tableName,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Remove um produto
  static Future<int> delete(int id) async {
    final db = await CaldaDatabase.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca produtos por fabricante
  static Future<List<Product>> findByManufacturer(String manufacturer) async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'manufacturer = ?',
      whereArgs: [manufacturer],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  /// Busca produtos por formulação
  static Future<List<Product>> findByFormulation(String formulation) async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'formulation = ?',
      whereArgs: [formulation],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
}
