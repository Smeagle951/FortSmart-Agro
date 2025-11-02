import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../../../models/infestacao_model.dart';
import '../../../utils/logger.dart';
import '../models/models.dart';

/// Repositório unificado para dados de monitoramento e infestação
/// Evita redundância usando views e joins para manter rastreabilidade
class UnifiedMonitoringRepository {
  static final UnifiedMonitoringRepository _instance = 
      UnifiedMonitoringRepository._internal();
  
  factory UnifiedMonitoringRepository() => _instance;
  
  UnifiedMonitoringRepository._internal();
  
  Database? _database;
  
  /// Inicializa o repositório unificado
  Future<void> initialize() async {
    try {
      _database = await AppDatabase().database;
      await _createUnifiedViews();
      Logger.info('✅ [UNIFIED] Repositório unificado inicializado');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao inicializar: $e');
      rethrow;
    }
  }
  
  /// Cria views unificadas para evitar redundância
  Future<void> _createUnifiedViews() async {
    try {
      // Verificar se a tabela monitoring_history existe antes de criar a view
      final tableExists = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='monitoring_history'"
      );
      
      if (tableExists.isEmpty) {
        Logger.warning('⚠️ Tabela monitoring_history não existe. Criando tabela...');
        await _createMonitoringHistoryTable();
      }
      
      // View unificada de monitoramento com dados de infestação
      await _database!.execute('''
        CREATE VIEW IF NOT EXISTS unified_monitoring_view AS
        SELECT 
          m.id,
          m.talhao_id,
          m.ponto_id,
          m.cultura_id,
          m.cultura_nome,
          m.talhao_nome,
          m.latitude,
          m.longitude,
          m.tipo_ocorrencia,
          m.subtipo_ocorrencia,
          m.nivel_ocorrencia,
          m.percentual_ocorrencia,
          m.observacao,
          m.foto_paths,
          m.data_hora_ocorrencia,
          m.data_hora_monitoramento,
          m.sincronizado,
          m.created_at,
          m.updated_at,
          -- Campos calculados para infestação
          CASE 
            WHEN m.percentual_ocorrencia >= 75 THEN 'CRÍTICO'
            WHEN m.percentual_ocorrencia >= 50 THEN 'ALTO'
            WHEN m.percentual_ocorrencia >= 25 THEN 'MODERADO'
            ELSE 'BAIXO'
          END as nivel_infestacao,
          -- Status de integração
          CASE 
            WHEN i.id IS NOT NULL THEN 1
            ELSE 0
          END as integrado_mapa_infestacao,
          i.id as infestation_map_id
        FROM monitoring_history m
        LEFT JOIN infestation_map i ON m.id = i.monitoring_history_id
      ''');
      
      // View de resumos de infestação por talhão
      await _database!.execute('''
        CREATE VIEW IF NOT EXISTS infestation_summaries_view AS
        SELECT 
          talhao_id,
          tipo_ocorrencia as organismo_id,
          MIN(data_hora_ocorrencia) as periodo_ini,
          MAX(data_hora_ocorrencia) as periodo_fim,
          AVG(percentual_ocorrencia) as avg_infestation,
          COUNT(*) as total_points,
          COUNT(CASE WHEN percentual_ocorrencia > 0 THEN 1 END) as points_with_occurrence,
          MAX(data_hora_monitoramento) as last_update,
          -- Nível predominante
          CASE 
            WHEN AVG(percentual_ocorrencia) >= 75 THEN 'CRÍTICO'
            WHEN AVG(percentual_ocorrencia) >= 50 THEN 'ALTO'
            WHEN AVG(percentual_ocorrencia) >= 25 THEN 'MODERADO'
            ELSE 'BAIXO'
          END as level
        FROM monitoring_history
        WHERE data_hora_ocorrencia >= datetime('now', '-30 days')
        GROUP BY talhao_id, tipo_ocorrencia
      ''');
      
      // View de alertas ativos
      await _database!.execute('''
        CREATE VIEW IF NOT EXISTS active_alerts_view AS
        SELECT 
          'alert_' || talhao_id || '_' || tipo_ocorrencia as id,
          talhao_id,
          tipo_ocorrencia as organismo_id,
          level,
          CASE 
            WHEN level = 'CRÍTICO' THEN 'crítico'
            WHEN level = 'ALTO' THEN 'alto'
            ELSE 'médio'
          END as risk_level,
          CASE 
            WHEN level = 'CRÍTICO' THEN 10.0
            WHEN level = 'ALTO' THEN 7.0
            WHEN level = 'MODERADO' THEN 5.0
            ELSE 3.0
          END as priority_score,
          'Infestação ' || LOWER(level) || ' detectada em ' || talhao_nome as message,
          'Média de infestação: ' || ROUND(avg_infestation, 1) || '%' as description,
          'auto' as origin,
          last_update as created_at,
          'ativo' as status
        FROM infestation_summaries_view
        WHERE level IN ('CRÍTICO', 'ALTO')
      ''');
      
      Logger.info('✅ [UNIFIED] Views unificadas criadas');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao criar views: $e');
      rethrow;
    }
  }
  
  /// Cria a tabela monitoring_history se não existir
  Future<void> _createMonitoringHistoryTable() async {
    try {
      await _database!.execute('''
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
      
      // Criar índices
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_talhao ON monitoring_history(talhao_id)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_ponto ON monitoring_history(ponto_id)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_cultura ON monitoring_history(cultura_id)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_data ON monitoring_history(data_hora_monitoramento)');
      await _database!.execute('CREATE INDEX IF NOT EXISTS idx_history_sync ON monitoring_history(sincronizado)');
      
      Logger.info('✅ [UNIFIED] Tabela monitoring_history criada com sucesso');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao criar tabela monitoring_history: $e');
    }
  }
  
  /// Salva ocorrência de monitoramento (método unificado)
  Future<String> saveMonitoringOccurrence({
    required InfestacaoModel occurrence,
    required int culturaId,
    String? culturaNome,
    String? talhaoNome,
    bool autoIntegrate = true,
  }) async {
    try {
      if (_database == null) await initialize();
      
      final occurrenceId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Inserir na tabela principal (monitoring_history)
      await _database!.insert(
        'monitoring_history',
        {
          'id': occurrenceId,
          'talhao_id': occurrence.talhaoId,
          'ponto_id': occurrence.pontoId,
          'cultura_id': culturaId,
          'cultura_nome': culturaNome ?? 'Cultura',
          'talhao_nome': talhaoNome ?? 'Talhão',
          'latitude': occurrence.latitude ?? 0.0,
          'longitude': occurrence.longitude ?? 0.0,
          'tipo_ocorrencia': occurrence.tipo,
          'subtipo_ocorrencia': occurrence.subtipo,
          'nivel_ocorrencia': occurrence.nivel,
          'percentual_ocorrencia': occurrence.percentual,
          'observacao': occurrence.observacao,
          'foto_paths': occurrence.fotoPaths,
          'data_hora_ocorrencia': occurrence.dataHora.toIso8601String(),
          'data_hora_monitoramento': DateTime.now().toIso8601String(),
          'sincronizado': 0, // Pendente de sincronização
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Integração automática com mapa de infestação
      if (autoIntegrate) {
        await _integrateWithInfestationMap(occurrenceId, occurrence);
      }
      
      Logger.info('✅ [UNIFIED] Ocorrência salva: $occurrenceId');
      return occurrenceId;
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao salvar ocorrência: $e');
      rethrow;
    }
  }
  
  /// Integração automática com mapa de infestação
  Future<void> _integrateWithInfestationMap(String occurrenceId, InfestacaoModel occurrence) async {
    try {
      // Inserir na tabela de infestação (referência para o mapa)
      await _database!.insert(
        'infestation_map',
        {
          'id': 'inf_' + occurrenceId,
          'monitoring_history_id': occurrenceId, // Referência para o histórico
          'talhao_id': occurrence.talhaoId,
          'ponto_id': occurrence.pontoId,
          'latitude': occurrence.latitude ?? 0.0,
          'longitude': occurrence.longitude ?? 0.0,
          'tipo_ocorrencia': occurrence.tipo,
          'subtipo_ocorrencia': occurrence.subtipo,
          'nivel_ocorrencia': occurrence.nivel,
          'percentual_ocorrencia': occurrence.percentual,
          'observacao': occurrence.observacao,
          'foto_paths': occurrence.fotoPaths,
          'data_hora_ocorrencia': occurrence.dataHora.toIso8601String(),
          'data_hora_monitoramento': DateTime.now().toIso8601String(),
          'sincronizado': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ [UNIFIED] Integração com mapa de infestação concluída');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro na integração: $e');
    }
  }
  
  /// Obtém dados unificados de monitoramento
  Future<List<Map<String, dynamic>>> getUnifiedMonitoringData({
    int? talhaoId,
    String? organismoId,
    DateTime? startDate,
    DateTime? endDate,
    bool onlyWithInfestation = false,
  }) async {
    try {
      if (_database == null) await initialize();
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND tipo_ocorrencia = ?';
        whereArgs.add(organismoId);
      }
      
      if (startDate != null) {
        whereClause += ' AND data_hora_ocorrencia >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      
      if (endDate != null) {
        whereClause += ' AND data_hora_ocorrencia <= ?';
        whereArgs.add(endDate.toIso8601String());
      }
      
      if (onlyWithInfestation) {
        whereClause += ' AND percentual_ocorrencia > 0';
      }
      
      final results = await _database!.rawQuery('''
        SELECT * FROM unified_monitoring_view
        WHERE $whereClause
        ORDER BY data_hora_ocorrencia DESC
      ''', whereArgs);
      
      Logger.info('✅ [UNIFIED] ${results.length} registros unificados obtidos');
      return results;
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao obter dados unificados: $e');
      return [];
    }
  }
  
  /// Obtém resumos de infestação por talhão
  Future<List<InfestationSummary>> getInfestationSummaries({
    int? talhaoId,
    String? organismoId,
  }) async {
    try {
      if (_database == null) await initialize();
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId.toString());
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      final results = await _database!.rawQuery('''
        SELECT 
          talhao_id || '_' || organismo_id as id,
          talhao_id,
          organismo_id,
          periodo_ini,
          periodo_fim,
          avg_infestation,
          avg_infestation as infestation_percentage,
          level,
          last_update,
          total_points,
          points_with_occurrence
        FROM infestation_summaries_view
        WHERE $whereClause
        ORDER BY avg_infestation DESC
      ''', whereArgs);
      
      return results.map((row) => InfestationSummary.fromMap(row)).toList();
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao obter resumos: $e');
      return [];
    }
  }
  
  /// Obtém alertas ativos
  Future<List<InfestationAlert>> getActiveAlerts({
    int? talhaoId,
    String? organismoId,
  }) async {
    try {
      if (_database == null) await initialize();
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId.toString());
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      final results = await _database!.rawQuery('''
        SELECT * FROM active_alerts_view
        WHERE $whereClause
        ORDER BY priority_score DESC, created_at DESC
      ''', whereArgs);
      
      return results.map((row) => InfestationAlert.fromMap(row)).toList();
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao obter alertas: $e');
      return [];
    }
  }
  
  /// Obtém estatísticas rápidas para dashboard
  Future<Map<String, dynamic>> getDashboardStats({
    int? talhaoId,
  }) async {
    try {
      if (_database == null) await initialize();
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId.toString());
      }
      
      final result = await _database!.rawQuery('''
        SELECT 
          COUNT(*) as total_occurrences,
          COUNT(CASE WHEN percentual_ocorrencia > 0 THEN 1 END) as occurrences_with_infestation,
          AVG(percentual_ocorrencia) as avg_infestation,
          COUNT(CASE WHEN nivel_infestacao = 'CRÍTICO' THEN 1 END) as critical_alerts,
          COUNT(CASE WHEN nivel_infestacao = 'ALTO' THEN 1 END) as high_alerts,
          COUNT(CASE WHEN nivel_infestacao = 'MODERADO' THEN 1 END) as moderate_alerts,
          COUNT(CASE WHEN nivel_infestacao = 'BAIXO' THEN 1 END) as low_alerts,
          COUNT(CASE WHEN integrado_mapa_infestacao = 1 THEN 1 END) as integrated_occurrences,
          COUNT(CASE WHEN sincronizado = 0 THEN 1 END) as pending_sync
        FROM unified_monitoring_view
        WHERE $whereClause
        AND data_hora_ocorrencia >= datetime('now', '-30 days')
      ''', whereArgs);
      
      return result.isNotEmpty ? result.first : {};
      
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao obter estatísticas: $e');
      return {};
    }
  }
  
  /// Marca dados como sincronizados
  Future<void> markAsSynced(List<String> occurrenceIds) async {
    try {
      if (_database == null) await initialize();
      
      for (final id in occurrenceIds) {
        await _database!.update(
          'monitoring_history',
          {'sincronizado': 1, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
        
        await _database!.update(
          'infestation_map',
          {'sincronizado': 1, 'updated_at': DateTime.now().toIso8601String()},
          where: 'monitoring_history_id = ?',
          whereArgs: [id],
        );
      }
      
      Logger.info('✅ [UNIFIED] ${occurrenceIds.length} registros marcados como sincronizados');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro ao marcar como sincronizado: $e');
    }
  }
  
  /// Limpa dados antigos (manutenção)
  Future<void> cleanupOldData({int daysToKeep = 365}) async {
    try {
      if (_database == null) await initialize();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      // Limpar dados antigos do histórico
      await _database!.delete(
        'monitoring_history',
        where: 'data_hora_ocorrencia < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      // Limpar dados antigos do mapa de infestação
      await _database!.delete(
        'infestation_map',
        where: 'data_hora_ocorrencia < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      Logger.info('✅ [UNIFIED] Limpeza de dados antigos concluída');
    } catch (e) {
      Logger.error('❌ [UNIFIED] Erro na limpeza: $e');
    }
  }
}
