/// Schema do banco de dados para sistema de feedback e aprendizado contínuo
/// Armazena feedback dos usuários sobre diagnósticos e infestações
class FeedbackDatabaseSchema {
  
  /// Tabela principal de feedback de diagnósticos
  static const String createDiagnosisFeedbackTable = '''
    CREATE TABLE IF NOT EXISTS diagnosis_feedback (
      id TEXT PRIMARY KEY,
      farm_id TEXT NOT NULL,
      diagnosis_id TEXT,
      monitoring_id TEXT,
      alert_id TEXT,
      crop_name TEXT NOT NULL,
      image_path TEXT,
      
      -- Predição/Diagnóstico do Sistema
      system_predicted_organism TEXT NOT NULL,
      system_predicted_severity REAL NOT NULL,
      system_severity_level TEXT NOT NULL,
      system_confidence REAL,
      system_symptoms TEXT NOT NULL,
      
      -- Feedback do Usuário
      user_confirmed INTEGER NOT NULL DEFAULT 0,
      user_corrected_organism TEXT,
      user_corrected_severity REAL,
      user_corrected_severity_level TEXT,
      user_corrected_symptoms TEXT,
      user_notes TEXT,
      user_correction_reason TEXT,
      
      -- Metadados
      diagnosis_date TEXT NOT NULL,
      feedback_date TEXT NOT NULL,
      technician_name TEXT NOT NULL,
      environmental_data TEXT,
      latitude REAL,
      longitude REAL,
      
      -- Resultado Real (Follow-up)
      real_outcome TEXT,
      outcome_date TEXT,
      treatment_efficacy REAL,
      treatment_applied TEXT,
      outcome_notes TEXT,
      
      -- Sincronização
      synced_to_cloud INTEGER DEFAULT 0,
      synced_at TEXT,
      
      -- Auditoria
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      
      FOREIGN KEY (farm_id) REFERENCES fazendas(id) ON DELETE CASCADE
    );
  ''';

  /// Índices para otimizar consultas
  static const List<String> createIndexes = [
    // Índice por fazenda
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_farm 
    ON diagnosis_feedback(farm_id);
    ''',
    
    // Índice por cultura
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_crop 
    ON diagnosis_feedback(crop_name);
    ''',
    
    // Índice por data de feedback
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_date 
    ON diagnosis_feedback(feedback_date);
    ''',
    
    // Índice por confirmação (para estatísticas rápidas)
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_confirmed 
    ON diagnosis_feedback(user_confirmed);
    ''',
    
    // Índice por sincronização
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_sync 
    ON diagnosis_feedback(synced_to_cloud);
    ''',
    
    // Índice composto: fazenda + cultura + data
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_farm_crop_date 
    ON diagnosis_feedback(farm_id, crop_name, feedback_date);
    ''',
    
    // Índice para follow-ups pendentes
    '''
    CREATE INDEX IF NOT EXISTS idx_feedback_outcome 
    ON diagnosis_feedback(real_outcome);
    ''',
  ];

  /// Tabela de estatísticas agregadas (cache para performance)
  static const String createFeedbackStatsTable = '''
    CREATE TABLE IF NOT EXISTS feedback_stats (
      id TEXT PRIMARY KEY,
      farm_id TEXT NOT NULL,
      crop_name TEXT NOT NULL,
      period_start TEXT NOT NULL,
      period_end TEXT NOT NULL,
      
      -- Estatísticas
      total_diagnoses INTEGER DEFAULT 0,
      total_confirmed INTEGER DEFAULT 0,
      total_corrected INTEGER DEFAULT 0,
      accuracy_rate REAL DEFAULT 0.0,
      avg_confidence REAL DEFAULT 0.0,
      
      -- Por nível de severidade
      low_accuracy REAL DEFAULT 0.0,
      moderate_accuracy REAL DEFAULT 0.0,
      high_accuracy REAL DEFAULT 0.0,
      critical_accuracy REAL DEFAULT 0.0,
      
      -- Auditoria
      calculated_at TEXT NOT NULL,
      
      FOREIGN KEY (farm_id) REFERENCES fazendas(id) ON DELETE CASCADE,
      
      UNIQUE(farm_id, crop_name, period_start, period_end)
    );
  ''';

  /// Índices para tabela de estatísticas
  static const List<String> createStatsIndexes = [
    '''
    CREATE INDEX IF NOT EXISTS idx_stats_farm 
    ON feedback_stats(farm_id);
    ''',
    
    '''
    CREATE INDEX IF NOT EXISTS idx_stats_crop 
    ON feedback_stats(crop_name);
    ''',
    
    '''
    CREATE INDEX IF NOT EXISTS idx_stats_period 
    ON feedback_stats(period_start, period_end);
    ''',
  ];

  /// Tabela de organismos mais comuns por fazenda (para aprendizado local)
  static const String createFarmOrganismPatternsTable = '''
    CREATE TABLE IF NOT EXISTS farm_organism_patterns (
      id TEXT PRIMARY KEY,
      farm_id TEXT NOT NULL,
      crop_name TEXT NOT NULL,
      organism_name TEXT NOT NULL,
      
      -- Estatísticas de ocorrência
      occurrence_count INTEGER DEFAULT 0,
      last_occurrence_date TEXT,
      avg_severity REAL DEFAULT 0.0,
      
      -- Padrões de sintomas
      common_symptoms TEXT,
      
      -- Condições ambientais típicas
      typical_conditions TEXT,
      
      -- Eficácia de tratamentos
      successful_treatments TEXT,
      avg_treatment_efficacy REAL,
      
      -- Auditoria
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      
      FOREIGN KEY (farm_id) REFERENCES fazendas(id) ON DELETE CASCADE,
      
      UNIQUE(farm_id, crop_name, organism_name)
    );
  ''';

  /// Índices para padrões de organismos
  static const List<String> createPatternsIndexes = [
    '''
    CREATE INDEX IF NOT EXISTS idx_patterns_farm 
    ON farm_organism_patterns(farm_id);
    ''',
    
    '''
    CREATE INDEX IF NOT EXISTS idx_patterns_crop 
    ON farm_organism_patterns(crop_name);
    ''',
    
    '''
    CREATE INDEX IF NOT EXISTS idx_patterns_organism 
    ON farm_organism_patterns(organism_name);
    ''',
    
    '''
    CREATE INDEX IF NOT EXISTS idx_patterns_occurrence 
    ON farm_organism_patterns(occurrence_count DESC);
    ''',
  ];

  /// Lista de todos os SQLs para criar tabelas
  static List<String> get allCreateTableStatements => [
    createDiagnosisFeedbackTable,
    createFeedbackStatsTable,
    createFarmOrganismPatternsTable,
  ];

  /// Lista de todos os índices
  static List<String> get allIndexStatements => [
    ...createIndexes,
    ...createStatsIndexes,
    ...createPatternsIndexes,
  ];

  /// Executa todas as migrações necessárias
  static List<String> getAllStatements() {
    return [
      ...allCreateTableStatements,
      ...allIndexStatements,
    ];
  }

  /// SQL para limpar dados antigos (manutenção)
  static String getCleanupOldFeedbackSQL(int daysToKeep) {
    return '''
      DELETE FROM diagnosis_feedback 
      WHERE synced_to_cloud = 1 
        AND datetime(feedback_date) < datetime('now', '-$daysToKeep days');
    ''';
  }

  /// SQL para estatísticas rápidas
  static const String getQuickStatsSQL = '''
    SELECT 
      crop_name,
      COUNT(*) as total,
      SUM(CASE WHEN user_confirmed = 1 THEN 1 ELSE 0 END) as confirmed,
      SUM(CASE WHEN user_confirmed = 0 THEN 1 ELSE 0 END) as corrected,
      AVG(CASE WHEN system_confidence IS NOT NULL THEN system_confidence ELSE 0 END) as avg_confidence,
      CAST(SUM(CASE WHEN user_confirmed = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100 as accuracy_rate
    FROM diagnosis_feedback
    WHERE farm_id = ?
    GROUP BY crop_name
    ORDER BY total DESC;
  ''';

  /// SQL para feedback pendente de sincronização
  static const String getPendingSyncSQL = '''
    SELECT * FROM diagnosis_feedback 
    WHERE synced_to_cloud = 0 
    ORDER BY feedback_date ASC 
    LIMIT ?;
  ''';

  /// SQL para follow-ups pendentes
  static const String getPendingFollowUpsSQL = '''
    SELECT * FROM diagnosis_feedback 
    WHERE real_outcome IS NULL 
      AND datetime(feedback_date) < datetime('now', '-7 days')
    ORDER BY feedback_date ASC;
  ''';

  /// SQL para atualizar estatísticas agregadas
  static String getUpdateStatsSQL(String farmId, String cropName, String periodStart, String periodEnd) {
    return '''
      INSERT OR REPLACE INTO feedback_stats (
        id, farm_id, crop_name, period_start, period_end,
        total_diagnoses, total_confirmed, total_corrected, accuracy_rate, avg_confidence,
        calculated_at
      )
      SELECT 
        '${farmId}_${cropName}_$periodStart' as id,
        farm_id,
        crop_name,
        '$periodStart' as period_start,
        '$periodEnd' as period_end,
        COUNT(*) as total_diagnoses,
        SUM(CASE WHEN user_confirmed = 1 THEN 1 ELSE 0 END) as total_confirmed,
        SUM(CASE WHEN user_confirmed = 0 THEN 1 ELSE 0 END) as total_corrected,
        CAST(SUM(CASE WHEN user_confirmed = 1 THEN 1 ELSE 0 END) AS REAL) / COUNT(*) * 100 as accuracy_rate,
        AVG(CASE WHEN system_confidence IS NOT NULL THEN system_confidence ELSE 0 END) as avg_confidence,
        datetime('now') as calculated_at
      FROM diagnosis_feedback
      WHERE farm_id = '$farmId'
        AND crop_name = '$cropName'
        AND datetime(feedback_date) BETWEEN '$periodStart' AND '$periodEnd'
      GROUP BY farm_id, crop_name;
    ''';
  }
}

