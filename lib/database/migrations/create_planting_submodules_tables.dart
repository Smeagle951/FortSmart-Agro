import 'package:sqflite/sqflite.dart';

/// Migração para criar as tabelas dos submódulos de plantio
Future<void> createPlantingSubmodulesTables(Database db) async {
  print('🔄 Criando tabelas dos submódulos de plantio...');

  // Desabilitar FOREIGN KEY constraints para estas tabelas
  await db.execute('PRAGMA foreign_keys = OFF');

  // Tabela planting_cv (CV% do plantio)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS planting_cv (
      id TEXT PRIMARY KEY,
      talhao_id TEXT NOT NULL,
      talhao_nome TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      cultura_nome TEXT NOT NULL,
      data_plantio TEXT NOT NULL,
      comprimento_linha_amostrada REAL NOT NULL,
      espacamento_entre_linhas REAL NOT NULL,
      distancias_entre_sementes TEXT NOT NULL,
      media_espacamento REAL NOT NULL,
      desvio_padrao REAL NOT NULL,
      coeficiente_variacao REAL NOT NULL,
      plantas_por_metro REAL NOT NULL,
      populacao_estimada_hectare REAL NOT NULL,
      classificacao TEXT NOT NULL,
      observacoes TEXT,
      meta_populacao_hectare REAL,
      meta_plantas_metro REAL,
      diferenca_populacao_percentual REAL,
      diferenca_plantas_metro_percentual REAL,
      status_comparacao_populacao TEXT,
      status_comparacao_plantas_metro TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      sync_status INTEGER DEFAULT 0
    )
  ''');

  // Índices para planting_cv
  await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_talhao_id ON planting_cv (talhao_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_cultura_id ON planting_cv (cultura_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_data_plantio ON planting_cv (data_plantio)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_planting_cv_sync_status ON planting_cv (sync_status)');

  // Tabela estande_plantas (Estande de Plantas)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS estande_plantas (
      id TEXT PRIMARY KEY,
      talhao_id TEXT NOT NULL,
      talhao_nome TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      cultura_nome TEXT NOT NULL,
      data_emergencia TEXT NOT NULL,
      comprimento_linha_amostrada REAL NOT NULL,
      espacamento_entre_linhas REAL NOT NULL,
      plantas_por_linha TEXT NOT NULL,
      total_plantas INTEGER NOT NULL,
      plantas_por_metro REAL NOT NULL,
      plantas_por_hectare REAL NOT NULL,
      eficiencia_emergencia REAL,
      populacao_ideal REAL,
      diferenca_populacao_percentual REAL,
      status_estande TEXT NOT NULL,
      observacoes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      sync_status INTEGER DEFAULT 0
    )
  ''');

  // Índices para estande_plantas
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_talhao_id ON estande_plantas (talhao_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_cultura_id ON estande_plantas (cultura_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_data_emergencia ON estande_plantas (data_emergencia)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantas_sync_status ON estande_plantas (sync_status)');

  // Tabela phenological_records (Evolução Fenológica)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS phenological_records (
      id TEXT PRIMARY KEY,
      talhao_id TEXT NOT NULL,
      talhao_nome TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      cultura_nome TEXT NOT NULL,
      data_registro TEXT NOT NULL,
      fase_fenologica TEXT NOT NULL,
      percentual_plantas INTEGER NOT NULL,
      observacoes TEXT,
      fotos TEXT,
      coordenadas TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      sync_status INTEGER DEFAULT 0
    )
  ''');

  // Índices para phenological_records
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_records_talhao_id ON phenological_records (talhao_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_records_cultura_id ON phenological_records (cultura_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_records_data_registro ON phenological_records (data_registro)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_records_sync_status ON phenological_records (sync_status)');

  // Tabela phenological_alerts (Alertas Fenológicos)
  await db.execute('''
    CREATE TABLE IF NOT EXISTS phenological_alerts (
      id TEXT PRIMARY KEY,
      talhao_id TEXT NOT NULL,
      talhao_nome TEXT NOT NULL,
      cultura_id TEXT NOT NULL,
      cultura_nome TEXT NOT NULL,
      data_alerta TEXT NOT NULL,
      tipo_alerta TEXT NOT NULL,
      fase_fenologica TEXT NOT NULL,
      percentual_esperado INTEGER,
      percentual_atual INTEGER,
      status_alerta TEXT NOT NULL,
      observacoes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      sync_status INTEGER DEFAULT 0
    )
  ''');

  // Índices para phenological_alerts
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_alerts_talhao_id ON phenological_alerts (talhao_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_alerts_cultura_id ON phenological_alerts (cultura_id)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_alerts_data_alerta ON phenological_alerts (data_alerta)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_phenological_alerts_sync_status ON phenological_alerts (sync_status)');

  // Reabilitar FOREIGN KEY constraints
  await db.execute('PRAGMA foreign_keys = ON');

  print('✅ Tabelas dos submódulos de plantio criadas com sucesso!');
}
