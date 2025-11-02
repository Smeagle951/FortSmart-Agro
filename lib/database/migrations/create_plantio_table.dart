import 'package:sqflite/sqflite.dart';

/// Migração para criar a tabela plantio
class CreatePlantioTable {
  static Future<void> createPlantioTable(Database db) async {
    print('🔄 Criando tabela plantio...');
    
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS plantio (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          cultura_id TEXT NOT NULL,
          safra_id TEXT,
          variedade_id TEXT,
          data_plantio TEXT NOT NULL,
          populacao INTEGER NOT NULL,
          espacamento REAL NOT NULL,
          profundidade REAL NOT NULL,
          maquinas_ids TEXT,
          calibragem_id TEXT,
          estande_id TEXT,
          observacoes TEXT,
          sincronizado INTEGER DEFAULT 0,
          criado_em TEXT NOT NULL,
          atualizado_em TEXT NOT NULL,
          trator_id TEXT,
          plantadeira_id TEXT,
          densidade_linear REAL,
          germinacao REAL,
          metodo_calibragem TEXT,
          fonte_sementes_id TEXT,
          resultados TEXT,
          peso_mil_sementes REAL,
          gramas_coletadas REAL,
          distancia_percorrida REAL,
          engrenagem_motora INTEGER,
          engrenagem_movida INTEGER,
          deleted_at TEXT
        )
      ''');
      
      // Criar índices
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_talhao_id ON plantio (talhao_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_cultura_id ON plantio (cultura_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_data_plantio ON plantio (data_plantio)');
      
      print('✅ Tabela plantio criada com sucesso!');
    } catch (e) {
      print('❌ Erro ao criar tabela plantio: $e');
      rethrow;
    }
  }
}

