import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço de diagnóstico para o módulo de inventário
class InventoryDiagnosticService {
  final AppDatabase _appDatabase = AppDatabase();
  
  /// Executa diagnóstico completo do módulo de inventário
  Future<Map<String, dynamic>> runFullDiagnostic() async {
    try {
      Logger.info('🔍 [INVENTORY_DIAGNOSTIC] Iniciando diagnóstico completo...');
      
      final results = <String, dynamic>{};
      
      // 1. Verificar estrutura das tabelas
      results['table_structure'] = await _checkTableStructure();
      
      // 2. Verificar dados existentes
      results['data_counts'] = await _checkDataCounts();
      
      // 3. Verificar integridade dos dados
      results['data_integrity'] = await _checkDataIntegrity();
      
      // 4. Testar operações básicas
      results['basic_operations'] = await _testBasicOperations();
      
      // 5. Verificar índices
      results['indexes'] = await _checkIndexes();
      
      Logger.info('✅ [INVENTORY_DIAGNOSTIC] Diagnóstico completo finalizado');
      return results;
      
    } catch (e) {
      Logger.error('❌ [INVENTORY_DIAGNOSTIC] Erro no diagnóstico: $e');
      return {
        'error': e.toString(),
        'status': 'failed',
      };
    }
  }
  
  /// Verifica estrutura das tabelas
  Future<Map<String, dynamic>> _checkTableStructure() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Tabelas principais do inventário
      final tables = [
        'inventory',
        'inventory_movements',
        'inventory_products',
      ];
      
      for (final table in tables) {
        try {
          final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
          results[table] = {
            'exists': tableInfo.isNotEmpty,
            'columns': tableInfo.length,
            'structure': tableInfo.map((c) => {
              'name': c['name'],
              'type': c['type'],
              'notnull': c['notnull'],
              'pk': c['pk'],
            }).toList(),
          };
        } catch (e) {
          results[table] = {
            'exists': false,
            'error': e.toString(),
          };
        }
      }
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica contagem de dados
  Future<Map<String, dynamic>> _checkDataCounts() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Contar registros em cada tabela
      final tables = [
        'inventory',
        'inventory_movements',
        'inventory_products',
      ];
      
      for (final table in tables) {
        try {
          final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $table')
          ) ?? 0;
          
          results[table] = {
            'count': count,
            'has_data': count > 0,
          };
        } catch (e) {
          results[table] = {
            'count': 0,
            'has_data': false,
            'error': e.toString(),
          };
        }
      }
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica integridade dos dados
  Future<Map<String, dynamic>> _checkDataIntegrity() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar dados de inventário
      final inventoryData = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN name IS NULL OR name = '' THEN 1 END) as null_name,
          COUNT(CASE WHEN category IS NULL OR category = '' THEN 1 END) as null_category,
          COUNT(CASE WHEN quantity IS NULL THEN 1 END) as null_quantity
        FROM inventory
      ''');
      
      results['inventory_data'] = inventoryData.first;
      
      // Verificar dados de produtos
      final productsData = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN name IS NULL OR name = '' THEN 1 END) as null_name,
          COUNT(CASE WHEN category IS NULL OR category = '' THEN 1 END) as null_category,
          COUNT(CASE WHEN current_stock IS NULL THEN 1 END) as null_stock
        FROM inventory_products
      ''');
      
      results['products_data'] = productsData.first;
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Testa operações básicas
  Future<Map<String, dynamic>> _testBasicOperations() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Testar inserção na tabela inventory_products
      try {
        final testProduct = {
          'id': 'test_product_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Produto Teste',
          'description': 'Produto para teste de diagnóstico',
          'category': 'Teste',
          'class': 'Teste',
          'unit': 'un',
          'min_stock': 0.0,
          'current_stock': 1.0,
          'price': 10.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        };
        
        final insertResult = await db.insert('inventory_products', testProduct);
        results['insert_test'] = {
          'success': true,
          'inserted_id': insertResult,
        };
        
        // Testar busca
        final searchResult = await db.query(
          'inventory_products',
          where: 'id = ?',
          whereArgs: [testProduct['id']],
        );
        
        results['search_test'] = {
          'success': true,
          'found': searchResult.isNotEmpty,
        };
        
        // Testar atualização
        final updateResult = await db.update(
          'inventory_products',
          {'name': 'Produto Teste Atualizado'},
          where: 'id = ?',
          whereArgs: [testProduct['id']],
        );
        
        results['update_test'] = {
          'success': true,
          'updated_rows': updateResult,
        };
        
        // Testar exclusão
        final deleteResult = await db.delete(
          'inventory_products',
          where: 'id = ?',
          whereArgs: [testProduct['id']],
        );
        
        results['delete_test'] = {
          'success': true,
          'deleted_rows': deleteResult,
        };
        
      } catch (e) {
        results['basic_operations'] = {
          'success': false,
          'error': e.toString(),
        };
      }
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Verifica índices
  Future<Map<String, dynamic>> _checkIndexes() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar índices da tabela inventory_products
      final indexes = await db.rawQuery('''
        SELECT name, sql FROM sqlite_master 
        WHERE type='index' AND tbl_name='inventory_products'
      ''');
      
      results['inventory_products_indexes'] = {
        'count': indexes.length,
        'indexes': indexes.map((idx) => {
          'name': idx['name'],
          'sql': idx['sql'],
        }).toList(),
      };
      
      return results;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Gera dados de teste se necessário
  Future<Map<String, dynamic>> generateTestDataIfNeeded() async {
    try {
      final db = await _appDatabase.database;
      final results = <String, dynamic>{};
      
      // Verificar se há dados na tabela inventory_products
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM inventory_products')
      ) ?? 0;
      
      if (count == 0) {
        Logger.info('🔄 [INVENTORY_DIAGNOSTIC] Gerando dados de teste...');
        
        // Adicionar dados de exemplo
        await _addSampleProducts(db);
        
        results['test_data_created'] = true;
        results['test_records'] = 3;
        Logger.info('✅ [INVENTORY_DIAGNOSTIC] Dados de teste criados');
      } else {
        results['test_data_created'] = false;
        results['existing_records'] = count;
        Logger.info('ℹ️ [INVENTORY_DIAGNOSTIC] Dados já existem: $count registros');
      }
      
      return results;
    } catch (e) {
      Logger.error('❌ [INVENTORY_DIAGNOSTIC] Erro ao gerar dados de teste: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Adiciona produtos de exemplo
  Future<void> _addSampleProducts(Database db) async {
    final products = [
      {
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
      },
      {
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
      },
      {
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
      },
    ];
    
    for (final product in products) {
      await db.insert('inventory_products', product);
    }
  }
}
