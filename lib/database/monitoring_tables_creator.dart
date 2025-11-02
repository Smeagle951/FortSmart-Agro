import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';
import '../repositories/organism_catalog_repository.dart';
import 'app_database.dart';

/// Criador de tabelas para o sistema de monitoramento
/// Implementa todas as tabelas conforme especificação do documento
class MonitoringTablesCreator {
  final AppDatabase _database = AppDatabase();
  static const String _tag = 'MonitoringTablesCreator';

  /// Cria todas as tabelas necessárias para o sistema de monitoramento
  Future<void> createAllTables() async {
    try {
      Logger.info('$_tag: 🏗️ Criando tabelas do sistema de monitoramento...');
      
      final db = await _database.database;
      
      // 1. Catálogo de Organismos (fonte de verdade)
      await _createCatalogOrganismsTable(db);
      
      // 2. Sessões de Monitoramento
      await _createMonitoringSessionsTable(db);
      
      // 3. Pontos de Monitoramento
      await _createMonitoringPointsTable(db);
      
      // 4. Ocorrências de Monitoramento
      await _createMonitoringOccurrencesTable(db);
      
      // 5. Mapa de Infestação (resultado da análise)
      await _createInfestationMapTable(db);
      
      // 6. Histórico de Sincronização
      await _createSyncHistoryTable(db);
      
      // 7. Notificações de Monitoramento
      await _createMonitoringNotificationsTable(db);
      
      // 8. Histórico de Monitoramento
      await _createMonitoringHistoryTable(db);
      
      Logger.info('$_tag: ✅ Todas as tabelas criadas com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  /// Tabela: Catálogo de Organismos
  Future<void> _createCatalogOrganismsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS organism_catalog (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientific_name TEXT,
        type TEXT NOT NULL,
        crop_id TEXT NOT NULL,
        crop_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        low_limit INTEGER NOT NULL,
        medium_limit INTEGER NOT NULL,
        high_limit INTEGER NOT NULL,
        description TEXT,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_tipo ON organism_catalog(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_cultura ON organism_catalog(crop_id)');
  }

  /// Tabela: Sessões de Monitoramento
  Future<void> _createMonitoringSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_sessions (
        id TEXT PRIMARY KEY,
        fazenda_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        amostragem_padrao_plantas_por_ponto INTEGER DEFAULT 10,
        started_at DATETIME NOT NULL,
        finished_at DATETIME,
        status TEXT NOT NULL CHECK (status IN ('draft', 'finalized', 'cancelled')) DEFAULT 'draft',
        device_id TEXT,
        catalog_version TEXT,
        sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'synced',
        sync_error TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_talhao ON monitoring_sessions(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_status ON monitoring_sessions(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_sync ON monitoring_sessions(sync_state)');
  }

  /// Tabela: Pontos de Monitoramento
  Future<void> _createMonitoringPointsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_points (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        numero INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp DATETIME NOT NULL,
        plantas_avaliadas INTEGER,
        gps_accuracy REAL,
        manual_entry INTEGER DEFAULT 0,
        attachments_json TEXT,
        observacoes TEXT,
        sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'synced',
        sync_error TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(session_id) REFERENCES monitoring_sessions(id) ON DELETE CASCADE,
        UNIQUE(session_id, numero)
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_points_session ON monitoring_points(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_points_sync ON monitoring_points(sync_state)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_points_coords ON monitoring_points(latitude, longitude)');
  }

  /// Tabela: Ocorrências de Monitoramento
  Future<void> _createMonitoringOccurrencesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_occurrences (
        id TEXT PRIMARY KEY,
        point_id TEXT NOT NULL,
        organism_id TEXT NOT NULL,
        valor_bruto REAL NOT NULL,
        observacao TEXT,
        sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'synced',
        sync_error TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(point_id) REFERENCES monitoring_points(id) ON DELETE CASCADE,
        FOREIGN KEY(organism_id) REFERENCES organism_catalog(id),
        UNIQUE(point_id, organism_id)
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_occurrences_point ON monitoring_occurrences(point_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_occurrences_organism ON monitoring_occurrences(organism_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_occurrences_sync ON monitoring_occurrences(sync_state)');
  }

  /// Tabela: Mapa de Infestação
  Future<void> _createInfestationMapTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS infestation_map (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        organism_id TEXT NOT NULL,
        infestacao_percent REAL NOT NULL,
        nivel TEXT NOT NULL CHECK (nivel IN ('baixo', 'medio', 'alto', 'critico')),
        frequencia_percent REAL,
        intensidade_media REAL,
        indice_percent REAL,
        total_pontos INTEGER,
        pontos_com_ocorrencia INTEGER,
        catalog_version TEXT NOT NULL,
        aggregated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(session_id) REFERENCES monitoring_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(organism_id) REFERENCES organism_catalog(id)
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_session ON infestation_map(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_talhao ON infestation_map(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_organism ON infestation_map(organism_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_infestation_nivel ON infestation_map(nivel)');
  }

  /// Tabela: Histórico de Sincronização
  Future<void> _createSyncHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
        status TEXT NOT NULL CHECK (status IN ('pending', 'success', 'error')),
        error_message TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        synced_at DATETIME
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_table ON sync_history(table_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_history(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_created ON sync_history(created_at)');
  }

  /// Tabela: Notificações de Monitoramento
  Future<void> _createMonitoringNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        organism_id TEXT NOT NULL,
        nivel TEXT NOT NULL CHECK (nivel IN ('baixo', 'medio', 'alto', 'critico')),
        mensagem TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(session_id) REFERENCES monitoring_sessions(id) ON DELETE CASCADE,
        FOREIGN KEY(organism_id) REFERENCES organism_catalog(id)
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_session ON monitoring_notifications(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_talhao ON monitoring_notifications(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_read ON monitoring_notifications(is_read)');
  }

  /// Tabela: Histórico de Monitoramento
  Future<void> _createMonitoringHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_history (
        id TEXT PRIMARY KEY,
        talhao_id INTEGER NOT NULL,
        ponto_id INTEGER NOT NULL,
        cultura_id INTEGER NOT NULL,
        cultura_nome TEXT NOT NULL,
        talhao_nome TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tipo_ocorrencia TEXT NOT NULL,
        subtipo_ocorrencia TEXT NOT NULL,
        nivel_ocorrencia TEXT NOT NULL,
        percentual_ocorrencia INTEGER NOT NULL,
        observacao TEXT,
        foto_paths TEXT,
        data_hora_ocorrencia DATETIME NOT NULL,
        data_hora_monitoramento DATETIME NOT NULL,
        sincronizado INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_talhao ON monitoring_history(talhao_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_ponto ON monitoring_history(ponto_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_cultura ON monitoring_history(cultura_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_data ON monitoring_history(data_hora_monitoramento)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_history_sync ON monitoring_history(sincronizado)');
  }

  /// Verifica se todas as tabelas existem
  Future<bool> checkTablesExist() async {
    try {
      final db = await _database.database;
      
      final tables = [
        'organism_catalog',
        'monitoring_sessions',
        'monitoring_points',
        'monitoring_occurrences',
        'infestation_map',
        'sync_history',
        'monitoring_notifications',
        'monitoring_history',
      ];
      
      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table]
        );
        
        if (result.isEmpty) {
          Logger.warning('$_tag: ⚠️ Tabela não encontrada: $table');
          return false;
        }
      }
      
      Logger.info('$_tag: ✅ Todas as tabelas existem');
      return true;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar tabelas: $e');
      return false;
    }
  }

  /// Inicializa o catálogo de organismos com dados reais
  Future<void> initializeOrganismCatalog() async {
    try {
      Logger.info('$_tag: 🔄 Inicializando catálogo de organismos...');
      
      // Importar o repositório de catálogo de organismos
      final organismCatalogRepository = OrganismCatalogRepository();
      
      // Inicializar a tabela
      await organismCatalogRepository.initialize();
      
      // Inserir dados padrão do catálogo (se não existirem)
      await organismCatalogRepository.insertDefaultData();
      
      Logger.info('$_tag: ✅ Catálogo de organismos inicializado');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao inicializar catálogo de organismos: $e');
    }
  }

  /// Limpa todas as tabelas (apenas para desenvolvimento)
  Future<void> clearAllTables() async {
    try {
      final db = await _database.database;
      
      final tables = [
        'monitoring_notifications',
        'infestation_map',
        'monitoring_occurrences',
        'monitoring_points',
        'monitoring_sessions',
        'sync_history',
      ];
      
      for (final table in tables) {
        await db.delete(table);
      }
      
      Logger.info('$_tag: ✅ Todas as tabelas limpas');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao limpar tabelas: $e');
    }
  }
}
