import '../database/app_database.dart';

class InventoryService {
  final AppDatabase _database = AppDatabase();

  // Obtém a contagem de itens com estoque baixo
  Future<int> getLowStockItemsCount() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM inventory_items 
        WHERE current_quantity <= minimum_quantity
      ''');
      
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      // Para fins de demonstração, retorna um valor simulado
      return 5;
    }
  }

  // Obtém os itens com estoque baixo
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('''
        SELECT * FROM inventory_items 
        WHERE current_quantity <= minimum_quantity
        ORDER BY (minimum_quantity - current_quantity) DESC
      ''');
      
      return result;
    } catch (e) {
      // Para fins de demonstração, retorna dados simulados
      return [
        {
          'id': '1',
          'name': 'Fertilizante NPK',
          'current_quantity': 50,
          'minimum_quantity': 100,
          'unit': 'kg',
        },
        {
          'id': '2',
          'name': 'Herbicida Glifosato',
          'current_quantity': 10,
          'minimum_quantity': 20,
          'unit': 'L',
        },
        {
          'id': '3',
          'name': 'Inseticida Deltametrina',
          'current_quantity': 5,
          'minimum_quantity': 15,
          'unit': 'L',
        },
        {
          'id': '4',
          'name': 'Sementes de Soja',
          'current_quantity': 200,
          'minimum_quantity': 500,
          'unit': 'kg',
        },
        {
          'id': '5',
          'name': 'Fungicida Triazol',
          'current_quantity': 8,
          'minimum_quantity': 10,
          'unit': 'L',
        },
      ];
    }
  }

  // Obtém o valor total do estoque
  Future<double> getTotalInventoryValue() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('''
        SELECT SUM(current_quantity * unit_price) as total_value 
        FROM inventory_items
      ''');
      
      return result.first['total_value'] as double? ?? 0.0;
    } catch (e) {
      // Para fins de demonstração, retorna um valor simulado
      return 125000.0;
    }
  }

  // Obtém a distribuição de itens por categoria
  Future<List<Map<String, dynamic>>> getInventoryByCategory() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('''
        SELECT category, COUNT(*) as count, SUM(current_quantity * unit_price) as value
        FROM inventory_items
        GROUP BY category
        ORDER BY value DESC
      ''');
      
      return result;
    } catch (e) {
      // Para fins de demonstração, retorna dados simulados
      return [
        {'category': 'Fertilizantes', 'count': 8, 'value': 45000.0},
        {'category': 'Defensivos', 'count': 12, 'value': 35000.0},
        {'category': 'Sementes', 'count': 5, 'value': 30000.0},
        {'category': 'Combustíveis', 'count': 3, 'value': 10000.0},
        {'category': 'Outros', 'count': 7, 'value': 5000.0},
      ];
    }
  }

  // Obtém o total de itens no estoque
  Future<int> getTotalItemsCount() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM inventory_items
      ''');
      
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      // Para fins de demonstração, retorna um valor simulado
      return 25;
    }
  }

  getAllItems() {}
}
