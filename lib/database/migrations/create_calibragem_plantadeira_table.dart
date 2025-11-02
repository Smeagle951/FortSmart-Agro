import 'package:sqflite/sqflite.dart';

/// Cria a tabela de calibragem de plantadeira no banco de dados
Future<void> createCalibragemPlantadeiraTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS calibragem_plantadeira (
      id TEXT PRIMARY KEY,
      talhaoId TEXT NOT NULL,
      culturaId TEXT NOT NULL,
      discoNome TEXT NOT NULL,
      furosDisco INTEGER NOT NULL,
      engrenagemMotora INTEGER NOT NULL,
      engrenagemMovida INTEGER NOT NULL,
      voltasRoda REAL NOT NULL,
      distancia REAL NOT NULL,
      linhas INTEGER NOT NULL,
      espacamento REAL NOT NULL,
      metaSementesHa REAL NOT NULL,
      relacaoTransmissao REAL,
      voltasDisco REAL,
      sementesTotais REAL,
      sementesPorMetro REAL,
      sementesPorHectare REAL,
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
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_plantadeira_talhaoId ON calibragem_plantadeira (talhaoId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_plantadeira_culturaId ON calibragem_plantadeira (culturaId)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_plantadeira_criadoEm ON calibragem_plantadeira (criadoEm)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_calibragem_plantadeira_sincronizado ON calibragem_plantadeira (sincronizado)');
} 