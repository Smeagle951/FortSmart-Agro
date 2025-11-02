import 'package:sqflite/sqflite.dart';

/// Migração para criar as tabelas do módulo de Tratamento de Sementes
class CreateTratamentoSementesTables {
  static const String _tableDoses = 'doses_ts';
  static const String _tableProdutos = 'produtos_ts';
  static const String _tableInoculantes = 'inoculantes_ts';
  static const String _tableAgua = 'agua_ts';
  static const String _tableCustos = 'custos_doses_ts';
  static const String _tableDetalhes = 'detalhes_produtos_doses_ts';

  /// Executa a migração criando todas as tabelas necessárias
  static Future<void> execute(Database db) async {
    await _createDosesTable(db);
    await _createProdutosTable(db);
    await _createInoculantesTable(db);
    await _createAguaTable(db);
    await _createCustosTable(db);
    await _createDetalhesTable(db);
    await _createIndexes(db);
  }

  /// Cria a tabela de doses de tratamento de sementes
  static Future<void> _createDosesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableDoses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_cultura TEXT NOT NULL,
        nome TEXT NOT NULL,
        descricao TEXT,
        versao INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(nome_cultura, nome, versao)
      )
    ''');
  }

  /// Cria a tabela de produtos de tratamento de sementes
  static Future<void> _createProdutosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableProdutos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dose_id INTEGER NOT NULL,
        nome_produto TEXT NOT NULL,
        tipo_calculo TEXT NOT NULL DEFAULT 'milKg',
        valor REAL NOT NULL,
        unidade TEXT NOT NULL,
        valor_unitario REAL,
        observacao TEXT,
        ordem INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (dose_id) REFERENCES $_tableDoses (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Cria a tabela de inoculantes de tratamento de sementes
  static Future<void> _createInoculantesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableInoculantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dose_id INTEGER NOT NULL,
        nome_inoculante TEXT NOT NULL,
        tipo_dose TEXT NOT NULL DEFAULT 'por1000kg',
        base_kg REAL,
        valor_dose REAL NOT NULL,
        unidade TEXT NOT NULL DEFAULT 'dose(s)',
        valor_unitario REAL,
        observacao TEXT,
        ordem INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (dose_id) REFERENCES $_tableDoses (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Cria a tabela de água/calda de tratamento de sementes
  static Future<void> _createAguaTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableAgua (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dose_id INTEGER NOT NULL,
        tipo_calculo TEXT NOT NULL DEFAULT 'milKg',
        valor REAL NOT NULL,
        unidade TEXT NOT NULL DEFAULT 'L',
        observacao TEXT,
        ordem INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (dose_id) REFERENCES $_tableDoses (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Cria a tabela de custos de doses
  static Future<void> _createCustosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableCustos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_dose TEXT NOT NULL,
        nome_cultura TEXT NOT NULL,
        sementes_kg REAL NOT NULL,
        hectares REAL,
        custo_total_produtos REAL NOT NULL DEFAULT 0,
        custo_total_inoculantes REAL NOT NULL DEFAULT 0,
        custo_total_agua REAL NOT NULL DEFAULT 0,
        custo_total_geral REAL NOT NULL DEFAULT 0,
        data_criacao INTEGER NOT NULL,
        observacoes TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');
  }

  /// Cria a tabela de detalhes dos produtos das doses
  static Future<void> _createDetalhesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableDetalhes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        custo_dose_id INTEGER NOT NULL,
        tipo_produto TEXT NOT NULL,
        nome_produto TEXT NOT NULL,
        unidade TEXT NOT NULL,
        quantidade REAL NOT NULL,
        valor_unitario REAL NOT NULL,
        custo_total REAL NOT NULL,
        observacoes TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (custo_dose_id) REFERENCES $_tableCustos (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Cria os índices para melhorar a performance
  static Future<void> _createIndexes(Database db) async {
    // Índices para doses
    await db.execute('CREATE INDEX IF NOT EXISTS idx_doses_ts_cultura ON $_tableDoses (nome_cultura)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_doses_ts_nome ON $_tableDoses (nome)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_doses_ts_created ON $_tableDoses (created_at)');

    // Índices para produtos
    await db.execute('CREATE INDEX IF NOT EXISTS idx_produtos_ts_dose_id ON $_tableProdutos (dose_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_produtos_ts_tipo_calculo ON $_tableProdutos (tipo_calculo)');

    // Índices para inoculantes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inoculantes_ts_dose_id ON $_tableInoculantes (dose_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inoculantes_ts_tipo_dose ON $_tableInoculantes (tipo_dose)');

    // Índices para água
    await db.execute('CREATE INDEX IF NOT EXISTS idx_agua_ts_dose_id ON $_tableAgua (dose_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_agua_ts_tipo_calculo ON $_tableAgua (tipo_calculo)');

    // Índices para custos
    await db.execute('CREATE INDEX IF NOT EXISTS idx_custos_ts_cultura ON $_tableCustos (nome_cultura)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_custos_ts_data ON $_tableCustos (data_criacao)');

    // Índices para detalhes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_detalhes_ts_custo_dose_id ON $_tableDetalhes (custo_dose_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_detalhes_ts_tipo_produto ON $_tableDetalhes (tipo_produto)');
  }

  /// Verifica se as tabelas existem
  static Future<bool> tablesExist(Database db) async {
    final tables = [_tableDoses, _tableProdutos, _tableInoculantes, _tableAgua, _tableCustos, _tableDetalhes];
    
    for (final table in tables) {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      
      if (result.isEmpty) {
        return false;
      }
    }
    
    return true;
  }

  /// Remove todas as tabelas (para testes ou reset)
  static Future<void> dropTables(Database db) async {
    final tables = [_tableDetalhes, _tableCustos, _tableAgua, _tableInoculantes, _tableProdutos, _tableDoses];
    
    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }
}
