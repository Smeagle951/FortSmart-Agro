import 'package:sqflite/sqflite.dart';

class CreateListaPlantioCompleteSystem {
  static const int version = 22; // Nova versão do banco

  static Future<void> up(Database db) async {
    print('🔄 Criando sistema completo de Lista de Plantio...');
    
    // Habilitar foreign keys
    await db.execute('PRAGMA foreign_keys = ON;');

    // 1. Tabelas base (se não existirem)
    await _createBaseTables(db);
    
    // 2. Tabelas de estoque específicas
    await _createEstoqueTables(db);
    
    // 3. Tabela de plantio atualizada
    await _createPlantioTable(db);
    
    // 4. Tabela de apontamento de estoque
    await _createApontamentoEstoqueTable(db);
    
    // 5. Tabela de estande/avaliação
    await _createEstandeAvaliacaoTable(db);
    
    // 6. Índices otimizados
    await _createIndexes(db);
    
    // 7. Views de cálculo
    await _createViews(db);
    
    print('✅ Sistema de Lista de Plantio criado com sucesso!');
  }

  static Future<void> _createBaseTables(Database db) async {
    // Usar tabela talhao_safra existente (não criar nova tabela talhao)
    // A tabela talhao_safra já existe no sistema principal
    
    // Subárea (se não existir)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subarea (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        area_ha REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (talhao_id) REFERENCES talhao_safra(id)
      )
    ''');
  }

  static Future<void> _createEstoqueTables(Database db) async {
    // Produto de estoque
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estoque_produto (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        cultura TEXT NOT NULL,
        variedade TEXT,
        unidade TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // Lote de estoque
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estoque_lote (
        id TEXT PRIMARY KEY,
        produto_id TEXT NOT NULL,
        lote TEXT,
        qntd_total REAL NOT NULL,
        qntd_disponivel REAL NOT NULL,
        custo_unitario REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (produto_id) REFERENCES estoque_produto(id)
      )
    ''');
  }

  static Future<void> _createPlantioTable(Database db) async {
    // Verificar se a tabela plantio existe e tem a estrutura correta
    final tableInfo = await db.rawQuery("PRAGMA table_info(plantio)");
    final hasNewColumns = tableInfo.any((col) => 
      col['name'] == 'subarea_id' || 
      col['name'] == 'variedade' || 
      col['name'] == 'espacamento_cm' || 
      col['name'] == 'populacao_por_m'
    );

    if (!hasNewColumns) {
      // Backup da tabela antiga se existir
      try {
        await db.execute('ALTER TABLE plantio RENAME TO plantio_old');
      } catch (e) {
        // Tabela não existe, continuar
      }

      // Criar nova tabela com estrutura completa
      await db.execute('''
        CREATE TABLE plantio (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          subarea_id TEXT,
          cultura TEXT NOT NULL,
          variedade TEXT NOT NULL,
          data_plantio TEXT NOT NULL,
          espacamento_cm REAL NOT NULL,
          populacao_por_m REAL NOT NULL,
          observacao TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          deleted_at TEXT,
          FOREIGN KEY (talhao_id) REFERENCES talhao_safra(id),
          FOREIGN KEY (subarea_id) REFERENCES subarea(id)
        )
      ''');

      // Migrar dados antigos se existirem
      try {
        await db.execute('''
          INSERT INTO plantio (
            id, talhao_id, cultura, data_plantio, espacamento_cm, 
            populacao_por_m, observacao, created_at, updated_at, deleted_at
          )
          SELECT 
            id, talhao_id, cultura, data_plantio, 45.0, 12.0, 
            observacoes, created_at, updated_at, NULL
          FROM plantio_old
        ''');
        await db.execute('DROP TABLE plantio_old');
      } catch (e) {
        // Sem dados para migrar
      }
    }
  }

  static Future<void> _createApontamentoEstoqueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS apontamento_estoque (
        id TEXT PRIMARY KEY,
        plantio_id TEXT NOT NULL,
        lote_id TEXT NOT NULL,
        quantidade REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (plantio_id) REFERENCES plantio(id),
        FOREIGN KEY (lote_id) REFERENCES estoque_lote(id)
      )
    ''');
  }

  static Future<void> _createEstandeAvaliacaoTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estande_avaliacao (
        id TEXT PRIMARY KEY,
        plantio_id TEXT NOT NULL,
        data_avaliacao TEXT NOT NULL,
        comprimento_amostrado_m REAL NOT NULL,
        linhas_amostradas INTEGER NOT NULL,
        plantas_contadas INTEGER NOT NULL,
        dae INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (plantio_id) REFERENCES plantio(id)
      )
    ''');
  }

  static Future<void> _createIndexes(Database db) async {
    // Índices para plantio
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_talhao ON plantio(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_subarea ON plantio(subarea_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plantio_data ON plantio(data_plantio)');
    
    // Índices para apontamento
    await db.execute('CREATE INDEX IF NOT EXISTS idx_apontamento_plantio ON apontamento_estoque(plantio_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_apontamento_lote ON apontamento_estoque(lote_id)');
    
    // Índices para estande
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_plantio ON estande_avaliacao(plantio_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estande_data ON estande_avaliacao(data_avaliacao)');
    
    // Índices para estoque
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estoque_produto_tipo ON estoque_produto(tipo)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estoque_produto_cultura ON estoque_produto(cultura)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_estoque_lote_produto ON estoque_lote(produto_id)');
  }

  static Future<void> _createViews(Database db) async {
    // Área considerada (subárea se existir, senão área do talhão)
    await db.execute('''
      CREATE VIEW IF NOT EXISTS vw_area_plantio AS
      SELECT p.id AS plantio_id,
             COALESCE(sa.area_ha, t.area) AS area_ha
      FROM plantio p
      JOIN talhao_safra t ON t.id = p.talhao_id
      LEFT JOIN subarea sa ON sa.id = p.subarea_id
      WHERE p.deleted_at IS NULL
    ''');

    // População por hectare: pop_m * (100 / espaçamento_cm)
    await db.execute('''
      CREATE VIEW IF NOT EXISTS vw_populacao_ha AS
      SELECT id AS plantio_id,
             populacao_por_m * (100.0 / NULLIF(espacamento_cm,0)) AS populacao_ha
      FROM plantio
      WHERE deleted_at IS NULL
    ''');

    // Custo por hectare real (somando saídas x custo_unitário / área)
    await db.execute('''
      CREATE VIEW IF NOT EXISTS vw_custo_ha AS
      WITH saida AS (
        SELECT a.plantio_id,
               SUM(a.quantidade * l.custo_unitario) AS custo_total
        FROM apontamento_estoque a
        JOIN estoque_lote l ON l.id = a.lote_id
        WHERE a.deleted_at IS NULL AND l.deleted_at IS NULL
        GROUP BY a.plantio_id
      )
      SELECT p.id AS plantio_id,
             CASE WHEN ap.area_ha IS NOT NULL AND ap.area_ha > 0
                  THEN COALESCE(s.custo_total,0) / ap.area_ha
                  ELSE NULL END AS custo_ha
      FROM plantio p
      LEFT JOIN saida s ON s.plantio_id = p.id
      LEFT JOIN vw_area_plantio ap ON ap.plantio_id = p.id
      WHERE p.deleted_at IS NULL
    ''');

    // DAE mais recente (por plantio)
    await db.execute('''
      CREATE VIEW IF NOT EXISTS vw_dae AS
      SELECT ea.plantio_id,
             (SELECT dae FROM estande_avaliacao ea2
               WHERE ea2.plantio_id = ea.plantio_id AND ea2.deleted_at IS NULL
               ORDER BY date(ea2.data_avaliacao) DESC LIMIT 1) AS dae
      FROM estande_avaliacao ea
      GROUP BY ea.plantio_id
    ''');

    // Lista consolidada para UI (join pronta)
    await db.execute('''
      CREATE VIEW IF NOT EXISTS vw_lista_plantio AS
      SELECT
        p.id,
        p.variedade,
        p.cultura,
        p.talhao_id,
        COALESCE(sa.nome, t.nome) AS talhao_nome,
        p.subarea_id,
        sa.nome AS subarea_nome,
        p.data_plantio,
        p.populacao_por_m,
        vph.populacao_ha,
        p.espacamento_cm,
        ch.custo_ha,
        vd.dae
      FROM plantio p
      JOIN talhao_safra t ON t.id = p.talhao_id
      LEFT JOIN subarea sa ON sa.id = p.subarea_id
      LEFT JOIN vw_populacao_ha vph ON vph.plantio_id = p.id
      LEFT JOIN vw_custo_ha ch ON ch.plantio_id = p.id
      LEFT JOIN vw_dae vd ON vd.plantio_id = p.id
      WHERE p.deleted_at IS NULL
    ''');
  }

  static Future<void> down(Database db) async {
    print('🔄 Revertendo sistema de Lista de Plantio...');
    
    // Remover views
    await db.execute('DROP VIEW IF EXISTS vw_lista_plantio');
    await db.execute('DROP VIEW IF EXISTS vw_dae');
    await db.execute('DROP VIEW IF EXISTS vw_custo_ha');
    await db.execute('DROP VIEW IF EXISTS vw_populacao_ha');
    await db.execute('DROP VIEW IF EXISTS vw_area_plantio');
    
    // Remover tabelas
    await db.execute('DROP TABLE IF EXISTS estande_avaliacao');
    await db.execute('DROP TABLE IF EXISTS apontamento_estoque');
    await db.execute('DROP TABLE IF EXISTS estoque_lote');
    await db.execute('DROP TABLE IF EXISTS estoque_produto');
    
    print('✅ Sistema de Lista de Plantio removido');
  }
}
