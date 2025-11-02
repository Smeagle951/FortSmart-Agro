import 'package:sqflite/sqflite.dart';
import '../calda_database.dart';
import '../../../models/calda/calda_recipe.dart';
import '../../../models/calda/product.dart';
import 'product_dao.dart';

/// DAO para operações com receitas
class RecipeDao {
  static const String _tableName = 'recipes';
  static const String _recipeProductsTable = 'recipe_products';

  /// Adiciona uma nova receita
  static Future<int> insert(CaldaRecipe recipe) async {
    final db = await CaldaDatabase.database;
    final recipeId = await db.insert(_tableName, recipe.toMap());
    
    // Adiciona os produtos da receita
    for (Product product in recipe.products) {
      await db.insert(_recipeProductsTable, {
        'recipe_id': recipeId,
        'product_id': product.id,
      });
    }
    
    return recipeId;
  }

  /// Busca todas as receitas
  static Future<List<CaldaRecipe>> findAll() async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    
    List<CaldaRecipe> recipes = [];
    for (Map<String, dynamic> map in maps) {
      final recipe = CaldaRecipe.fromMap(map);
      final products = await _getProductsForRecipe(recipe.id!);
      recipes.add(recipe.copyWith(products: products));
    }
    
    return recipes;
  }

  /// Busca receita por ID
  static Future<CaldaRecipe?> findById(int id) async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      final recipe = CaldaRecipe.fromMap(maps.first);
      final products = await _getProductsForRecipe(id);
      return recipe.copyWith(products: products);
    }
    
    return null;
  }

  /// Atualiza uma receita
  static Future<int> update(CaldaRecipe recipe) async {
    final db = await CaldaDatabase.database;
    
    // Remove produtos antigos
    await db.delete(
      _recipeProductsTable,
      where: 'recipe_id = ?',
      whereArgs: [recipe.id],
    );
    
    // Atualiza receita
    final result = await db.update(
      _tableName,
      recipe.toMap(),
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
    
    // Adiciona novos produtos
    for (Product product in recipe.products) {
      await db.insert(_recipeProductsTable, {
        'recipe_id': recipe.id,
        'product_id': product.id,
      });
    }
    
    return result;
  }

  /// Remove uma receita
  static Future<int> delete(int id) async {
    final db = await CaldaDatabase.database;
    
    // Remove produtos da receita
    await db.delete(
      _recipeProductsTable,
      where: 'recipe_id = ?',
      whereArgs: [id],
    );
    
    // Remove receita
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca produtos de uma receita
  static Future<List<Product>> _getProductsForRecipe(int recipeId) async {
    final db = await CaldaDatabase.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* FROM products p
      INNER JOIN recipe_products rp ON p.id = rp.product_id
      WHERE rp.recipe_id = ?
    ''', [recipeId]);
    
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
}
