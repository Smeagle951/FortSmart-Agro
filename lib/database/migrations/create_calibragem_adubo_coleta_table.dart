import 'package:sqflite/sqflite.dart';

/// Cria a tabela de calibragem de adubo por coleta no banco de dados
Future<void> createCalibragemAduboColetaTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS calibragem_adubo_coleta (
      id TEXT PRIMARY KEY,
      talhaoId TEXT NOT NULL,
      culturaId TEXT NOT NULL,
      nomeFertilizante TEXT NOT NULL,
      tipoColeta TEXT NOT NULL,
      pesoColetado REAL NOT NULL,
      distancia REAL NOT NULL,
      linhas INTEGER NOT NULL,
      espacamento REAL NOT NULL,
      metaKgHa REAL NOT NULL,
      areaHa REAL,
      kgPorHa REAL,
      sacasPorHa REAL,
      diferencaMeta REAL,
      observacoes TEXT,
      sincronizado INTEGER NOT NULL DEFAULT 0,
      criadoEm TEXT NOT NULL,
      atualizadoEm TEXT NOT NULL,
      FOREIGN KEY (talhaoId) REFERENCES talhoes(id) ON DELETE CASCADE,
      FOREIGN KEY (culturaId) REFERENCES culturas(id) ON DELETE CASCADE
    )
  ''');
  
  // Criar índices para melhorar performance
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_adubo_coleta_talhaoId ON calibragem_adubo_coleta (talhaoId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_adubo_coleta_culturaId ON calibragem_adubo_coleta (culturaId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_adubo_coleta_criadoEm ON calibragem_adubo_coleta (criadoEm)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_adubo_coleta_sincronizado ON calibragem_adubo_coleta (sincronizado)');
} 