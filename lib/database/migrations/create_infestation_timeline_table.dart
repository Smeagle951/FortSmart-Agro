import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela de timeline de infestação
class CreateInfestationTimelineTable {
  static const String tableName = 'infestation_timeline';
  
  /// Cria a tabela de timeline de infestação
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id TEXT NOT NULL,
        organismo_id TEXT NOT NULL,
        data_ocorrencia DATETIME NOT NULL,
        quantidade INTEGER NOT NULL,
        nivel TEXT NOT NULL,
        percentual REAL NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        usuario_id TEXT,
        observacao TEXT,
        foto_paths TEXT,
        sync_status TEXT DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        server_id TEXT,
        last_sync_error TEXT,
        attempts_sync INTEGER DEFAULT 0
      )
    ''');
    
    // Criar índices para performance
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_infestation_timeline_talhao_organismo 
      ON $tableName (talhao_id, organismo_id)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_infestation_timeline_data 
      ON $tableName (data_ocorrencia)
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_infestation_timeline_sync 
      ON $tableName (sync_status)
    ''');
  }
  
  /// Remove a tabela (para rollback)
  static Future<void> dropTable(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $tableName');
  }
}
