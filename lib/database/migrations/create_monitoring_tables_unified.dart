import 'package:sqflite/sqflite.dart';

/// Migração unificada para criar todas as tabelas de monitoramento
/// Resolve conflitos entre diferentes estruturas de tabelas
class CreateMonitoringTablesUnified {
  static Future<void> up(Database db) async {
    print('🔄 Criando tabelas de monitoramento unificadas...');
    
    // 1. Tabela de Sessões de Monitoramento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_sessions (
        id TEXT PRIMARY KEY,
        fazenda_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        total_pontos INTEGER NOT NULL DEFAULT 0,
        total_ocorrencias INTEGER NOT NULL DEFAULT 0,
        data_inicio TEXT NOT NULL,
        data_fim TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        tecnico_nome TEXT,
        observacoes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // 2. Tabela de Pontos de Monitoramento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_points (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        numero INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        ordem INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        observacoes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES monitoring_sessions (id) ON DELETE CASCADE
      )
    ''');
    
    // 3. Tabela de Ocorrências de Monitoramento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_occurrences (
        id TEXT PRIMARY KEY,
        point_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        tipo TEXT NOT NULL,
        subtipo TEXT NOT NULL,
        nivel TEXT NOT NULL,
        percentual INTEGER NOT NULL DEFAULT 0,
        quantidade INTEGER NOT NULL DEFAULT 0,
        terco_planta TEXT,
        observacao TEXT,
        foto_paths TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        data_hora TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (point_id) REFERENCES monitoring_points (id) ON DELETE CASCADE,
        FOREIGN KEY (session_id) REFERENCES monitoring_sessions (id) ON DELETE CASCADE
      )
    ''');
    
    // 4. Tabela de Histórico de Monitoramento (compatível com MonitoringHistoryService)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_history (
        id TEXT PRIMARY KEY,
        monitoring_id TEXT NOT NULL,
        plot_id TEXT NOT NULL,
        plot_name TEXT NOT NULL,
        crop_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        date TEXT NOT NULL,
        points_data TEXT NOT NULL,
        occurrences_data TEXT,
        severity REAL DEFAULT 0,
        technician_name TEXT,
        observations TEXT,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
      )
    ''');
    
    // 5. Tabela de Mapa de Infestação
    await db.execute('''
      CREATE TABLE IF NOT EXISTS infestation_map (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        ponto_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tipo TEXT NOT NULL,
        subtipo TEXT NOT NULL,
        nivel TEXT NOT NULL,
        percentual INTEGER NOT NULL DEFAULT 0,
        observacao TEXT,
        foto_paths TEXT,
        data_hora TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        cultura_id TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        severity_level TEXT NOT NULL DEFAULT 'low',
        status TEXT NOT NULL DEFAULT 'active',
        source TEXT NOT NULL DEFAULT 'monitoring_module',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // 6. Tabela de Histórico de Monitoramento (estrutura alternativa)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_history_alt (
        id TEXT PRIMARY KEY,
        talhao_id TEXT NOT NULL,
        ponto_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tipo TEXT NOT NULL,
        subtipo TEXT NOT NULL,
        nivel TEXT NOT NULL,
        percentual INTEGER NOT NULL DEFAULT 0,
        observacao TEXT,
        foto_paths TEXT,
        data_hora TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Criar índices para melhor performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_sessions_talhao ON monitoring_sessions(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_sessions_cultura ON monitoring_sessions(cultura_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_sessions_data ON monitoring_sessions(data_inicio)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_points_session ON monitoring_points(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_occurrences_point ON monitoring_occurrences(point_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_occurrences_session ON monitoring_occurrences(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_occurrences_talhao ON monitoring_occurrences(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_history_plot ON monitoring_history(plot_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_history_date ON monitoring_history(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_map_talhao ON infestation_map(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_map_tipo ON infestation_map(tipo)');
    
    print('✅ Tabelas de monitoramento unificadas criadas com sucesso');
  }
  
  static Future<void> down(Database db) async {
    print('🔄 Removendo tabelas de monitoramento unificadas...');
    
    await db.execute('DROP TABLE IF EXISTS monitoring_occurrences');
    await db.execute('DROP TABLE IF EXISTS monitoring_points');
    await db.execute('DROP TABLE IF EXISTS monitoring_sessions');
    await db.execute('DROP TABLE IF EXISTS monitoring_history');
    await db.execute('DROP TABLE IF EXISTS infestation_map');
    await db.execute('DROP TABLE IF EXISTS monitoring_history_alt');
    
    print('✅ Tabelas de monitoramento unificadas removidas');
  }
}
