import 'package:sqflite/sqflite.dart';

/// Migração para corrigir a tabela talhoes adicionando colunas faltantes
class FixTalhoesTable {
  static Future<void> fixTalhoesTable(Database db) async {
    print('🔄 Corrigindo tabela talhoes - adicionando colunas faltantes...');
    
    try {
      // Verificar se a tabela existe
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='talhoes'"
      );
      
      if (tableCheck.isEmpty) {
        print('⚠️ Tabela talhoes não existe. Criando...');
        await _createTalhoesTable(db);
        return;
      }
      
      // Verificar colunas existentes
      final columns = await db.rawQuery('PRAGMA table_info(talhoes)');
      final columnNames = columns.map((col) => col['name'] as String).toList();
      
      print('📋 Colunas existentes: $columnNames');
      
      // Adicionar colunas faltantes
      final missingColumns = [
        'area',
        'created_at',
        'updated_at',
        'farm_id',
        'observacoes',
        'metadata',
        'version',
        'deleted_at',
        'sync_status',
        'crop_id',
        'safra_id'
      ];
      
      for (final column in missingColumns) {
        if (!columnNames.contains(column)) {
          print('➕ Adicionando coluna: $column');
          
          String columnType;
          String defaultValue;
          
          switch (column) {
            case 'area':
              columnType = 'REAL';
              defaultValue = '0.0';
              break;
            case 'created_at':
            case 'updated_at':
            case 'deleted_at':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            case 'farm_id':
            case 'observacoes':
              columnType = 'TEXT';
              defaultValue = "''";
              break;
            case 'metadata':
              columnType = 'TEXT';
              defaultValue = "'{}'";
              break;
            case 'version':
            case 'sync_status':
            case 'crop_id':
            case 'safra_id':
              columnType = 'INTEGER';
              defaultValue = '0';
              break;
            default:
              columnType = 'TEXT';
              defaultValue = "''";
          }
          
          await db.execute('ALTER TABLE talhoes ADD COLUMN $column $columnType DEFAULT $defaultValue');
          print('✅ Coluna $column adicionada com sucesso');
        } else {
          print('✅ Coluna $column já existe');
        }
      }
      
      print('✅ Tabela talhoes corrigida com sucesso!');
      
    } catch (e) {
      print('❌ Erro ao corrigir tabela talhoes: $e');
      rethrow;
    }
  }
  
  /// Cria a tabela talhoes se não existir
  static Future<void> _createTalhoesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS talhoes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        area REAL DEFAULT 0.0,
        sync_status INTEGER DEFAULT 0,
        crop_id INTEGER DEFAULT 0,
        safra_id INTEGER DEFAULT 0,
        created_at TEXT DEFAULT '',
        updated_at TEXT DEFAULT '',
        farm_id TEXT DEFAULT '',
        observacoes TEXT DEFAULT '',
        metadata TEXT DEFAULT '{}',
        version INTEGER DEFAULT 0,
        deleted_at TEXT DEFAULT NULL
      )
    ''');
    
    // Criar índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_name ON talhoes (name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_farm_id ON talhoes (farm_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_created_at ON talhoes (created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_sync_status ON talhoes (sync_status)');
    
    print('✅ Tabela talhoes criada com todas as colunas!');
  }
}
