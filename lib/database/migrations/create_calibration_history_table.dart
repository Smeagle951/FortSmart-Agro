import 'package:sqflite/sqflite.dart';

/// Cria a tabela de histórico de calibrações no banco de dados
Future<void> createCalibrationHistoryTable(Database db) async {
  // Desabilitar FOREIGN KEY constraints para esta tabela
  await db.execute('PRAGMA foreign_keys = OFF');
  
  await db.execute('''
    CREATE TABLE IF NOT EXISTS calibration_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      talhao_id TEXT NOT NULL,
      talhao_name TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      cultura_name TEXT NOT NULL,
      disco_nome TEXT,
      furos_disco INTEGER,
      engrenagem_motora INTEGER,
      engrenagem_movida INTEGER,
      voltas_disco REAL,
      distancia_percorrida REAL,
      linhas_coletadas INTEGER,
      espacamento_cm REAL,
      meta_sementes_hectare INTEGER,
      relacao_transmissao REAL,
      sementes_totais INTEGER,
      sementes_por_metro REAL,
      sementes_por_hectare INTEGER,
      diferenca_meta_percentual REAL,
      status_calibracao TEXT NOT NULL DEFAULT 'normal',
      observacoes TEXT,
      data_calibracao TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  
  // Criar índices para melhorar performance
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibration_history_talhao_id ON calibration_history (talhao_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibration_history_cultura_id ON calibration_history (cultura_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibration_history_data_calibracao ON calibration_history (data_calibracao)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibration_history_status ON calibration_history (status_calibracao)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibration_history_created_at ON calibration_history (created_at)');
  
  // Reabilitar FOREIGN KEY constraints
  await db.execute('PRAGMA foreign_keys = ON');
}
