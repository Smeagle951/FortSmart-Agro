import 'package:sqflite/sqflite.dart';

// Migração para criar tabelas de subáreas e experimentos seguindo o padrão FortFiled GPS

class CreateSubareasExperimentoTables {
  static const int version = 28; // Próxima versão do banco

  static Future<void> up(Database db) async {
    // Tabela de experimentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS experimentos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT,
        talhao_id TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL DEFAULT 'ativo',
        criado_em TEXT NOT NULL,
        atualizado_em TEXT,
        cultura TEXT,
        variedade TEXT,
        tipo_teste TEXT,
        produto_testado TEXT,
        observacoes TEXT
      )
    ''');

    // Tabela de subáreas - CORRIGIDA para incluir polygon_id
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subareas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        polygon_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        color TEXT,
        cultura TEXT,
        variedade TEXT,
        populacao INTEGER,
        data_inicio TEXT,
        observacoes TEXT,
        area REAL NOT NULL,
        perimeter REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (polygon_id) REFERENCES polygons (id) ON DELETE CASCADE,
        FOREIGN KEY (talhao_id) REFERENCES talhao_safra (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de polígonos de desenho (seguindo padrão FortFiled GPS)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS drawing_polygons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        is_closed INTEGER NOT NULL DEFAULT 0,
        area REAL,
        perimeter REAL
      )
    ''');

    // Tabela de vértices de desenho
    await db.execute('''
      CREATE TABLE IF NOT EXISTS drawing_vertices (
        id TEXT PRIMARY KEY,
        polygon_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL,
        source TEXT,
        FOREIGN KEY(polygon_id) REFERENCES drawing_polygons(id) ON DELETE CASCADE
      )
    ''');

    // Índices para performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subareas_talhao ON subareas(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subareas_polygon ON subareas(polygon_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subareas_cultura ON subareas(cultura)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subareas_variedade ON subareas(variedade)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_experimentos_talhao ON experimentos(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_experimentos_status ON experimentos(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_drawing_vertices_polygon ON drawing_vertices(polygon_id)');
    
    print('✅ Tabelas de subáreas e experimentos criadas com sucesso');
  }

  static Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS drawing_vertices');
    await db.execute('DROP TABLE IF EXISTS drawing_polygons');
    await db.execute('DROP TABLE IF EXISTS subareas');
    await db.execute('DROP TABLE IF EXISTS experimentos');
    print('✅ Tabelas de subáreas e experimentos removidas');
  }
}
