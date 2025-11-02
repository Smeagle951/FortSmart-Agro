import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';

/// Esquema completo de banco de dados para Monitoramento Avançado
/// Implementa todas as tabelas necessárias conforme especificado no guia
class MonitoringDatabaseSchema {
  static const String _tag = 'MonitoringDatabaseSchema';

  /// Cria todas as tabelas do sistema de monitoramento
  static Future<void> createAllTables(Database db) async {
    Logger.info('$_tag: Criando tabelas do sistema de monitoramento...');
    
    try {
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
      
      // 8. Prescrições de Monitoramento
      await _createMonitoringPrescriptionsTable(db);
      
      Logger.info('$_tag: ✅ Todas as tabelas criadas com sucesso');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao criar tabelas: $e');
      rethrow;
    }
  }

  /// Tabela: Catálogo de Organismos
  /// Fonte de verdade para unidades, limiares e versões
  static Future<void> _createCatalogOrganismsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS organism_catalog (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        nome_cientifico TEXT,
        tipo TEXT NOT NULL CHECK (tipo IN ('pest', 'disease', 'weed', 'deficiency', 'other')),
        cultura_id TEXT NOT NULL,
        cultura_nome TEXT NOT NULL,
        unidade TEXT NOT NULL,
        base_denominador INTEGER DEFAULT 1,
        limiar_baixo REAL DEFAULT 0,
        limiar_medio REAL DEFAULT 0,
        limiar_alto REAL DEFAULT 0,
        limiar_critico REAL DEFAULT 0,
        descricao TEXT,
        imagem_url TEXT,
        ativo INTEGER DEFAULT 1,
        version TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(nome, cultura_id, version)
      )
    ''');
    
    // Índices para performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_cultura ON organism_catalog(cultura_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_tipo ON organism_catalog(tipo)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_catalog_version ON organism_catalog(version)');
  }

  /// Tabela: Sessões de Monitoramento
  /// Controla o ciclo de vida de uma sessão de monitoramento
  static Future<void> _createMonitoringSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_sessions (
        id TEXT PRIMARY KEY,
        fazenda_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        cultura_id TEXT NOT NULL,
        amostragem_padrao_plantas_por_ponto INTEGER DEFAULT 10,
        started_at DATETIME NOT NULL,
        finished_at DATETIME,
        status TEXT NOT NULL CHECK (status IN ('draft', 'finalized', 'cancelled')) DEFAULT 'draft',
        device_id TEXT,
        catalog_version TEXT,
        sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'pending',
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
  /// Cada ponto coletado durante a sessão
  static Future<void> _createMonitoringPointsTable(Database db) async {
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
        sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'pending',
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
  /// Organismos encontrados em cada ponto
  static Future<void> _createMonitoringOccurrencesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_occurrences (
        id TEXT PRIMARY KEY,
        point_id TEXT NOT NULL,
        organism_id INTEGER NOT NULL,
        valor_bruto REAL NOT NULL,
        observacao TEXT,
        sync_state TEXT NOT NULL CHECK (sync_state IN ('pending', 'syncing', 'synced', 'error')) DEFAULT 'pending',
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
  /// Resultado da análise determinística
  static Future<void> _createInfestationMapTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS infestation_map (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        talhao_id TEXT NOT NULL,
        organism_id INTEGER NOT NULL,
        infestacao_percent REAL NOT NULL,
        nivel TEXT NOT NULL CHECK (nivel IN ('baixo', 'medio', 'alto', 'critico')),
        frequencia_percent REAL,
        intensidade_media REAL,
        indice_percent REAL,
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
  /// Auditoria de operações de sync
  static Future<void> _createSyncHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL CHECK (operation IN ('create', 'update', 'delete')),
        status TEXT NOT NULL CHECK (status IN ('success', 'error', 'retry')),
        error_message TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        synced_at DATETIME
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_entity ON sync_history(entity_type, entity_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_history(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_created ON sync_history(created_at)');
  }

  /// Tabela: Notificações de Monitoramento
  /// Sistema de alertas automáticos
  static Future<void> _createMonitoringNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        data TEXT,
        timestamp TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        session_id TEXT,
        organism_id TEXT,
        field_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_type ON monitoring_notifications(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_priority ON monitoring_notifications(priority)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON monitoring_notifications(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_read ON monitoring_notifications(is_read)');
  }

  /// Tabela: Prescrições de Monitoramento
  /// Recomendações baseadas em dados de monitoramento
  static Future<void> _createMonitoringPrescriptionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_prescriptions (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        field_id TEXT NOT NULL,
        crop_id TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        recommendations TEXT,
        organism_ids TEXT,
        monitoring_data TEXT,
        created_at TEXT NOT NULL,
        applied_at TEXT,
        applied_by TEXT,
        results TEXT
      )
    ''');
    
    // Índices
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_session ON monitoring_prescriptions(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_field ON monitoring_prescriptions(field_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_type ON monitoring_prescriptions(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_status ON monitoring_prescriptions(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prescriptions_created ON monitoring_prescriptions(created_at)');
  }

  /// Insere dados iniciais do catálogo de organismos
  static Future<void> insertInitialCatalogData(Database db) async {
    Logger.info('$_tag: Inserindo dados iniciais do catálogo...');
    
    try {
      // Verificar se já existem dados
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM organism_catalog')
      );
      
      if (count! > 0) {
        Logger.info('$_tag: Catálogo já possui dados, pulando inserção inicial');
        return;
      }

      // Dados de exemplo para Soja
      await db.insert('organism_catalog', {
        'nome': 'Lagarta-do-cartucho',
        'nome_cientifico': 'Spodoptera frugiperda',
        'tipo': 'pest',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'unidade': 'individuos/10_plantas',
        'base_denominador': 10,
        'limiar_baixo': 2,
        'limiar_medio': 5,
        'limiar_alto': 10,
        'limiar_critico': 20,
        'descricao': 'Lagarta que ataca o cartucho da planta',
        'ativo': 1,
        'version': '1.0.0',
      });

      await db.insert('organism_catalog', {
        'nome': 'Ferrugem Asiática',
        'nome_cientifico': 'Phakopsora pachyrhizi',
        'tipo': 'disease',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'unidade': 'percent_folha',
        'base_denominador': 1,
        'limiar_baixo': 5,
        'limiar_medio': 15,
        'limiar_alto': 30,
        'limiar_critico': 50,
        'descricao': 'Doença fúngica que afeta as folhas',
        'ativo': 1,
        'version': '1.0.0',
      });

      await db.insert('organism_catalog', {
        'nome': 'Buva',
        'nome_cientifico': 'Conyza bonariensis',
        'tipo': 'weed',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'unidade': 'plantas/m2',
        'base_denominador': 1,
        'limiar_baixo': 2,
        'limiar_medio': 5,
        'limiar_alto': 10,
        'limiar_critico': 20,
        'descricao': 'Planta daninha resistente a herbicidas',
        'ativo': 1,
        'version': '1.0.0',
      });

      Logger.info('$_tag: ✅ Dados iniciais do catálogo inseridos com sucesso');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao inserir dados iniciais: $e');
    }
  }

  /// Atualiza a versão do banco de dados
  static Future<void> updateDatabaseVersion(Database db, int newVersion) async {
    await db.execute('PRAGMA user_version = $newVersion');
    Logger.info('$_tag: Versão do banco atualizada para $newVersion');
  }

  /// Verifica a integridade do banco de dados
  static Future<bool> checkDatabaseIntegrity(Database db) async {
    try {
      final result = await db.rawQuery('PRAGMA integrity_check');
      final integrityOk = result.isEmpty || result.first['integrity_check'] == 'ok';
      
      if (integrityOk) {
        Logger.info('$_tag: ✅ Integridade do banco verificada com sucesso');
      } else {
        Logger.error('$_tag: ❌ Problemas de integridade detectados: $result');
      }
      
      return integrityOk;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar integridade: $e');
      return false;
    }
  }
}
