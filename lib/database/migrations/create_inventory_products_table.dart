import 'package:sqflite/sqflite.dart';
import '../app_database.dart';

/// Migração para criar a tabela inventory_products
class CreateInventoryProductsTable {
  static const String tableName = 'inventory_products';
  
  /// Executa a migração para criar a tabela inventory_products
  static Future<void> createTable(Database db) async {
    try {
      print('🔄 Criando tabela inventory_products...');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableName (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          class TEXT NOT NULL,
          unit TEXT NOT NULL,
          min_stock REAL NOT NULL DEFAULT 0,
          max_stock REAL,
          current_stock REAL NOT NULL DEFAULT 0,
          price REAL,
          supplier TEXT,
          batch_number TEXT,
          expiration_date TEXT,
          manufacturing_date TEXT,
          registration_number TEXT,
          active_ingredient TEXT,
          concentration TEXT,
          formulation TEXT,
          toxicity_class TEXT,
          application_method TEXT,
          waiting_period INTEGER,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      
      // Criar índices para melhor performance
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_inventory_products_name 
        ON $tableName (name)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_inventory_products_category 
        ON $tableName (category)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_inventory_products_class 
        ON $tableName (class)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_inventory_products_current_stock 
        ON $tableName (current_stock)
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_inventory_products_expiration_date 
        ON $tableName (expiration_date)
      ''');
      
      print('✅ Tabela inventory_products criada com sucesso');
      
    } catch (e) {
      print('❌ Erro ao criar tabela inventory_products: $e');
      rethrow;
    }
  }
  
  /// Verifica se a tabela existe
  static Future<bool> tableExists(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name='$tableName'
      ''');
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao verificar existência da tabela inventory_products: $e');
      return false;
    }
  }
  
  /// Obtém informações sobre a tabela
  static Future<Map<String, dynamic>> getTableInfo(Database db) async {
    try {
      final result = await db.rawQuery('''
        PRAGMA table_info($tableName)
      ''');
      
      return {
        'exists': result.isNotEmpty,
        'columns': result.length,
        'structure': result,
      };
    } catch (e) {
      print('❌ Erro ao obter informações da tabela inventory_products: $e');
      return {
        'exists': false,
        'columns': 0,
        'structure': [],
        'error': e.toString(),
      };
    }
  }
  
  /// Adiciona dados de exemplo se a tabela estiver vazia
  static Future<void> addSampleData(Database db) async {
    try {
      // Verificar se já existem dados
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final existingCount = count.first['count'] as int;
      
      if (existingCount > 0) {
        print('ℹ️ Tabela inventory_products já possui dados ($existingCount registros)');
        return;
      }
      
      print('🔄 Adicionando dados de exemplo na tabela inventory_products...');
      
      // Inserir dados de exemplo
      await db.insert(tableName, {
        'id': 'sample_herbicide_1',
        'name': 'Glifosato 480',
        'description': 'Herbicida sistêmico para controle de plantas daninhas',
        'category': 'Herbicida',
        'class': 'Sistêmico',
        'unit': 'L',
        'min_stock': 5.0,
        'max_stock': 100.0,
        'current_stock': 25.0,
        'price': 45.50,
        'supplier': 'AgroTech Ltda',
        'batch_number': 'GT2024001',
        'expiration_date': '2025-12-31',
        'manufacturing_date': '2024-01-15',
        'registration_number': '123456789',
        'active_ingredient': 'Glifosato',
        'concentration': '480 g/L',
        'formulation': 'Concentrado Emulsionável',
        'toxicity_class': 'Classe II',
        'application_method': 'Pulverização',
        'waiting_period': 7,
        'notes': 'Produto para uso agrícola',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });
      
      await db.insert(tableName, {
        'id': 'sample_insecticide_1',
        'name': 'Deltametrina 25',
        'description': 'Inseticida piretróide para controle de pragas',
        'category': 'Inseticida',
        'class': 'Piretróide',
        'unit': 'L',
        'min_stock': 3.0,
        'max_stock': 50.0,
        'current_stock': 15.0,
        'price': 78.90,
        'supplier': 'CropProtect S.A.',
        'batch_number': 'DT2024002',
        'expiration_date': '2025-06-30',
        'manufacturing_date': '2024-02-10',
        'registration_number': '987654321',
        'active_ingredient': 'Deltametrina',
        'concentration': '25 g/L',
        'formulation': 'Concentrado Emulsionável',
        'toxicity_class': 'Classe I',
        'application_method': 'Pulverização',
        'waiting_period': 14,
        'notes': 'Produto altamente eficaz',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });
      
      await db.insert(tableName, {
        'id': 'sample_fertilizer_1',
        'name': 'NPK 20-10-10',
        'description': 'Fertilizante granulado NPK',
        'category': 'Fertilizante',
        'class': 'NPK',
        'unit': 'kg',
        'min_stock': 100.0,
        'max_stock': 1000.0,
        'current_stock': 500.0,
        'price': 2.50,
        'supplier': 'FertilAgro Ltda',
        'batch_number': 'NPK2024003',
        'expiration_date': '2026-03-31',
        'manufacturing_date': '2024-03-01',
        'registration_number': '456789123',
        'active_ingredient': 'NPK',
        'concentration': '20-10-10',
        'formulation': 'Granulado',
        'toxicity_class': 'Classe III',
        'application_method': 'Aplicação no solo',
        'waiting_period': 0,
        'notes': 'Fertilizante balanceado',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });
      
      print('✅ Dados de exemplo adicionados na tabela inventory_products');
      
    } catch (e) {
      print('❌ Erro ao adicionar dados de exemplo: $e');
      rethrow;
    }
  }
}
