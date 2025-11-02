import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../repositories/organism_catalog_repository.dart';

/// Script para corrigir problemas de integridade na tabela organism_catalog
class OrganismCatalogFixer {
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogRepository _repository = OrganismCatalogRepository();

  /// Executa a correção completa
  Future<void> fixDatabaseIntegrity() async {
    print('🔧 Iniciando correção da integridade do banco de dados...');
    
    try {
      // 1. Garantir que a tabela crops existe e tem os dados necessários
      await _ensureCropsTable();
      
      // 2. Limpar e recriar a tabela organism_catalog
      await _recreateOrganismCatalogTable();
      
      // 3. Inserir dados padrão
      await _repository.insertDefaultData();
      
      print('✅ Correção concluída com sucesso!');
    } catch (e) {
      print('❌ Erro durante a correção: $e');
      rethrow;
    }
  }

  /// Garante que a tabela crops existe com os dados necessários
  Future<void> _ensureCropsTable() async {
    final db = await _database.database;
    
    print('📋 Verificando tabela crops...');
    
    // Criar tabela crops se não existir
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crops (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sync_status INTEGER NOT NULL DEFAULT 0,
        remote_id INTEGER
      )
    ''');
    
    // Lista de culturas necessárias
    final requiredCrops = [
      {'id': '1', 'name': 'Algodão', 'description': 'Cultura do algodão'},
      {'id': '2', 'name': 'Soja', 'description': 'Cultura da soja'},
      {'id': '3', 'name': 'Milho', 'description': 'Cultura do milho'},
      {'id': '4', 'name': 'Feijão', 'description': 'Cultura do feijão'},
      {'id': '5', 'name': 'Arroz', 'description': 'Cultura do arroz'},
      {'id': '6', 'name': 'Trigo', 'description': 'Cultura do trigo'},
      {'id': '7', 'name': 'Café', 'description': 'Cultura do café'},
      {'id': '8', 'name': 'Cana-de-açúcar', 'description': 'Cultura da cana-de-açúcar'},
    ];
    
    // Inserir culturas se não existirem
    for (final crop in requiredCrops) {
      try {
        await db.insert(
          'crops',
          {
            'id': crop['id'],
            'name': crop['name'],
            'description': crop['description'],
            'sync_status': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        print('✅ Cultura ${crop['name']} verificada/inserida');
      } catch (e) {
        print('⚠️ Erro ao inserir cultura ${crop['name']}: $e');
      }
    }
  }

  /// Recria a tabela organism_catalog
  Future<void> _recreateOrganismCatalogTable() async {
    final db = await _database.database;
    
    print('🔄 Recriando tabela organism_catalog...');
    
    // Remover tabela existente se houver
    try {
      await db.execute('DROP TABLE IF EXISTS organism_catalog');
      print('🗑️ Tabela antiga removida');
    } catch (e) {
      print('⚠️ Erro ao remover tabela antiga: $e');
    }
    
    // Criar nova tabela
    await db.execute('''
      CREATE TABLE organism_catalog (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientific_name TEXT,
        type TEXT NOT NULL,
        crop_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        low_limit INTEGER NOT NULL,
        medium_limit INTEGER NOT NULL,
        high_limit INTEGER NOT NULL,
        description TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    print('✅ Nova tabela organism_catalog criada');
  }

  /// Verifica se a correção foi bem-sucedida
  Future<bool> verifyFix() async {
    try {
      final organisms = await _repository.getAll();
      print('📊 Verificação: ${organisms.length} organismos carregados');
      return organisms.isNotEmpty;
    } catch (e) {
      print('❌ Erro na verificação: $e');
      return false;
    }
  }
}

/// Função para executar a correção
Future<void> fixOrganismCatalog() async {
  final fixer = OrganismCatalogFixer();
  
  try {
    await fixer.fixDatabaseIntegrity();
    final success = await fixer.verifyFix();
    
    if (success) {
      print('🎉 Correção concluída com sucesso!');
    } else {
      print('⚠️ Correção pode não ter sido totalmente bem-sucedida');
    }
  } catch (e) {
    print('❌ Falha na correção: $e');
  }
}
