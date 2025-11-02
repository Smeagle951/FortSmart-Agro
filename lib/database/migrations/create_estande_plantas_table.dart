import 'package:sqflite/sqflite.dart';

/// Cria a tabela de estande de plantas no banco de dados
/// NOTA: Esta migration está obsoleta. O schema correto está em app_database.dart
/// Mantida apenas para compatibilidade com código legado
Future<void> createEstandePlantasTable(Database db) async {
  // Schema unificado em snake_case
  await db.execute('''
    CREATE TABLE IF NOT EXISTS estande_plantas (
      id TEXT PRIMARY KEY,
      talhao_id TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      data_emergencia TEXT,
      data_avaliacao TEXT,
      dias_apos_emergencia INTEGER,
      metros_lineares_medidos REAL,
      plantas_contadas INTEGER,
      espacamento REAL,
      plantas_por_metro REAL,
      plantas_por_hectare REAL,
      populacao_ideal REAL,
      eficiencia REAL,
      fotos TEXT,
      observacoes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      sync_status INTEGER DEFAULT 0,
      FOREIGN KEY (talhao_id) REFERENCES talhoes(id) ON DELETE CASCADE
    )
  ''');
  
  // Criar índices para melhorar performance
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_talhao_id ON estande_plantas (talhao_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_cultura_id ON estande_plantas (cultura_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_data_avaliacao ON estande_plantas (data_avaliacao)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_sync_status ON estande_plantas (sync_status)');
} 