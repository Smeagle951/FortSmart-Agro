import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela agricultural_products
class CreateAgriculturalProductsTable {
  static Future<void> createAgriculturalProductsTable(Database db) async {
    try {
      print('🔄 Criando tabela agricultural_products...');
      
      // Verificar se a tabela já existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='agricultural_products'"
      );
      
      if (tables.isNotEmpty) {
        print('✅ Tabela agricultural_products já existe');
        return;
      }
      
      // Criar a tabela agricultural_products com a estrutura completa
      await db.execute('''
        CREATE TABLE IF NOT EXISTS agricultural_products (
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
          fazendaId TEXT,
          description TEXT,
          colorValue TEXT,
          tags TEXT,
          parentId TEXT
        )
      ''');
      
      print('✅ Tabela agricultural_products criada com sucesso');
      
    } catch (e) {
      print('❌ Erro ao criar tabela agricultural_products: $e');
      rethrow;
    }
  }
}
