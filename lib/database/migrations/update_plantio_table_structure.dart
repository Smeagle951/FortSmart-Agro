import 'package:sqflite/sqflite.dart';

/// Migração para atualizar a estrutura da tabela plantio
/// Alinha com o PlantioModel usado pela Evolução Fenológica
class UpdatePlantioTableStructure {
  static Future<void> updatePlantioTable(Database db) async {
    print('🔄 Atualizando estrutura da tabela plantio...');
    
    try {
      // Verificar se a tabela existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plantio'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ Tabela plantio não existe, criando nova...');
        await _createNewTable(db);
      } else {
        print('📋 Tabela plantio existe, atualizando estrutura...');
        await _updateExistingTable(db);
      }
      
      print('✅ Estrutura da tabela plantio atualizada!');
    } catch (e) {
      print('❌ Erro ao atualizar tabela plantio: $e');
      rethrow;
    }
  }
  
  static Future<void> _createNewTable(Database db) async {
    await db.execute('''
      CREATE TABLE plantio (
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
    await db.execute('CREATE INDEX idx_plantio_talhao_id ON plantio (talhao_id)');
    await db.execute('CREATE INDEX idx_plantio_cultura_id ON plantio (cultura_id)');
    await db.execute('CREATE INDEX idx_plantio_data_plantio ON plantio (data_plantio)');
  }
  
  static Future<void> _updateExistingTable(Database db) async {
    // Renomear tabela antiga
    await db.execute('ALTER TABLE plantio RENAME TO plantio_old');
    
    // Criar nova tabela com estrutura correta
    await _createNewTable(db);
    
    // Migrar dados existentes (se houver)
    try {
      await db.execute('''
        INSERT INTO plantio (
          id, talhao_id, cultura_id, variedade_id, data_plantio,
          populacao, espacamento, profundidade, observacoes,
          criado_em, atualizado_em
        )
        SELECT 
          COALESCE(id, ''), 
          COALESCE(talhao_id, ''),
          COALESCE(cultura, cultura_id, ''),
          COALESCE(variedade, variedade_id),
          COALESCE(data_plantio, datetime('now')),
          COALESCE(CAST(populacao_por_m AS INTEGER), CAST(espacamento_cm / espacamento AS INTEGER), 0),
          COALESCE(espacamento, espacamento_cm, 0.0),
          5.0,
          COALESCE(observacao, observacoes),
          COALESCE(created_at, criado_em, datetime('now')),
          COALESCE(updated_at, atualizado_em, datetime('now'))
        FROM plantio_old
        WHERE id IS NOT NULL AND talhao_id IS NOT NULL
      ''');
      
      print('✅ Dados migrados da tabela antiga');
    } catch (e) {
      print('⚠️ Erro ao migrar dados (tabela pode estar vazia): $e');
    }
    
    // Remover tabela antiga
    await db.execute('DROP TABLE IF EXISTS plantio_old');
  }
}

