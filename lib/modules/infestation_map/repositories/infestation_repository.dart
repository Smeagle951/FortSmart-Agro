import 'package:sqflite/sqflite.dart';
import '../../../database/app_database.dart';
import '../../../models/monitoring.dart';
import '../../../models/monitoring_point.dart';
import '../../../models/occurrence.dart';
import '../../../utils/enums.dart';
import '../../../utils/logger.dart';
import '../models/models.dart';

/// Repositório para dados de infestação que se conecta com o módulo de monitoramento
/// Obtém dados reais dos monitoramentos existentes e os processa para infestação
class InfestationRepository {
  final AppDatabase _appDatabase = AppDatabase();
  
  // Tabelas do módulo de infestação
  final String _infestationSummariesTable = 'infestation_summaries';
  final String _infestationAlertsTable = 'infestation_alerts';
  final String _infestationTimelapseTable = 'infestation_timelapse';
  
  /// Getter para acesso ao database
  Future<Database> get database async => await _appDatabase.database;
  
  /// Inicializa as tabelas de infestação
  Future<void> initialize() async {
    try {
      Logger.info('🔍 Inicializando tabelas de infestação...');
      
      final db = await _appDatabase.database;
      
      // Tabela de resumos de infestação
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_infestationSummariesTable (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          periodo_ini TEXT NOT NULL,
          periodo_fim TEXT NOT NULL,
          avg_infestation REAL NOT NULL,
          level TEXT NOT NULL,
          last_update TEXT NOT NULL,
          heat_geojson TEXT,
          total_points INTEGER DEFAULT 0,
          points_with_occurrence INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(talhao_id, organismo_id, periodo_fim)
        )
      ''');
      
      // Tabela de alertas de infestação
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_infestationAlertsTable (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          level TEXT NOT NULL,
          description TEXT NOT NULL,
          origin TEXT DEFAULT 'auto',
          created_at TEXT NOT NULL,
          acknowledged_at TEXT,
          acknowledged_by TEXT,
          is_active INTEGER DEFAULT 1
        )
      ''');
      
      // Tabela de timelapse para dados históricos
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_infestationTimelapseTable (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          data_coleta TEXT NOT NULL,
          periodo_ini TEXT NOT NULL,
          periodo_fim TEXT NOT NULL,
          infestacao_percent REAL NOT NULL,
          nivel TEXT NOT NULL,
          total_pontos INTEGER DEFAULT 0,
          pontos_com_ocorrencia INTEGER DEFAULT 0,
          trend TEXT,
          severity TEXT,
          heat_geojson TEXT,
          metadata TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Índices para performance
      await db.execute('CREATE INDEX IF NOT EXISTS idx_talhao_organismo ON $_infestationTimelapseTable (talhao_id, organismo_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_data_coleta ON $_infestationTimelapseTable (data_coleta)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_nivel ON $_infestationTimelapseTable (nivel)');
      
      Logger.info('✅ Tabelas de infestação inicializadas (incluindo timelapse)');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar tabelas de infestação: $e');
      rethrow;
    }
  }

  /// Obtém dados de infestação para um talhão específico
  /// Conecta com o módulo de monitoramento para obter dados reais
  Future<List<InfestationSummary>> getInfestationSummariesByTalhao(
    String talhaoId, {
    DateTime? dataInicio,
    DateTime? dataFim,
    String? organismoId,
  }) async {
    try {
      Logger.info('🔍 Obtendo dados de infestação para talhão: $talhaoId');
      
      // 1. Buscar monitoramentos do talhão no módulo de monitoramento
      final monitorings = await _getMonitoringsByTalhao(talhaoId, dataInicio, dataFim);
      
      if (monitorings.isEmpty) {
        Logger.info('ℹ️ Nenhum monitoramento encontrado para talhão: $talhaoId');
        return [];
      }
      
      // 2. Processar dados de monitoramento para infestação
      final summaries = await _processMonitoringsForInfestation(
        monitorings,
        talhaoId,
        organismoId,
      );
      
      Logger.info('✅ Dados de infestação obtidos: ${summaries.length} resumos');
      return summaries;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter dados de infestação: $e');
      return [];
    }
  }

  /// Obtém alertas ativos de infestação
  Future<List<InfestationAlert>> getActiveInfestationAlerts({
    String? talhaoId,
    String? organismoId,
    List<String>? levels,
  }) async {
    try {
      final db = await _appDatabase.database;
      
      // ✅ Garantir que a tabela existe
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_infestationAlertsTable (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          level TEXT NOT NULL,
          description TEXT NOT NULL,
          origin TEXT DEFAULT 'auto',
          created_at TEXT NOT NULL,
          acknowledged_at TEXT,
          acknowledged_by TEXT,
          is_active INTEGER DEFAULT 1
        )
      ''');
      
      String whereClause = 'is_active = 1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      if (levels != null && levels.isNotEmpty) {
        final placeholders = levels.map((_) => '?').join(',');
        whereClause += ' AND level IN ($placeholders)';
        whereArgs.addAll(levels);
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        _infestationAlertsTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      
      Logger.info('📊 [REPO] ${maps.length} alertas encontrados (talhão: $talhaoId)');
      return maps.map((map) => InfestationAlert.fromMap(map)).toList();
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao obter alertas de infestação: $e');
      Logger.error('❌ Stack: $stack');
      return [];
    }
  }

  /// Salva um resumo de infestação
  Future<void> saveInfestationSummary(InfestationSummary summary) async {
    try {
      final db = await _appDatabase.database;
      
      // ✅ Garantir que a tabela existe
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_infestationSummariesTable (
          id TEXT PRIMARY KEY,
          talhao_id TEXT NOT NULL,
          organismo_id TEXT NOT NULL,
          periodo_ini TEXT NOT NULL,
          periodo_fim TEXT NOT NULL,
          avg_infestation REAL NOT NULL,
          level TEXT NOT NULL,
          last_update TEXT NOT NULL,
          heat_geojson TEXT,
          total_points INTEGER DEFAULT 0,
          points_with_occurrence INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(talhao_id, organismo_id, periodo_fim)
        )
      ''');
      
      await db.insert(
        _infestationSummariesTable,
        summary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Resumo de infestação salvo: ${summary.id}');
    } catch (e, stack) {
      Logger.error('❌ Erro ao salvar resumo de infestação: $e');
      Logger.error('❌ Stack: $stack');
      rethrow;
    }
  }

  /// Salva um alerta de infestação
  Future<void> saveInfestationAlert(InfestationAlert alert) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert(
        _infestationAlertsTable,
        alert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      Logger.info('✅ Alerta de infestação salvo: ${alert.id}');
    } catch (e) {
      Logger.error('❌ Erro ao salvar alerta de infestação: $e');
      rethrow;
    }
  }

  /// Reconhece um alerta de infestação
  Future<void> acknowledgeAlert(String alertId, String userId) async {
    try {
      final db = await _appDatabase.database;
      
      await db.update(
        _infestationAlertsTable,
        {
          'acknowledged_at': DateTime.now().toIso8601String(),
          'acknowledged_by': userId,
        },
        where: 'id = ?',
        whereArgs: [alertId],
      );
      
      Logger.info('✅ Alerta reconhecido: $alertId por usuário: $userId');
    } catch (e) {
      Logger.error('❌ Erro ao reconhecer alerta: $e');
      rethrow;
    }
  }

  /// Obtém pontos de monitoramento por ID de monitoramento
  Future<List<MonitoringPoint>> obterPontos(String monitoringId) async {
    try {
      Logger.info('🔍 Obtendo pontos para monitoramento: $monitoringId');
      
      // Buscar monitoramento no módulo de monitoramento
      final monitoring = await _getMonitoringById(monitoringId);
      if (monitoring == null) {
        Logger.warning('⚠️ Monitoramento não encontrado: $monitoringId');
        return [];
      }
      
      Logger.info('✅ Pontos obtidos: ${monitoring.points.length}');
      return monitoring.points;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter pontos: $e');
      return [];
    }
  }

  /// Upsert de resumo de infestação
  Future<void> upsertSummary({
    required String talhaoId,
    required String organismoId,
    required DateTime periodoIni,
    required DateTime periodoFim,
    required double avgPct,
    required String level,
    String? heatGeoJson,
  }) async {
    try {
      Logger.info('💾 Upsert de resumo: Talhão: $talhaoId | Organismo: $organismoId');
      
      final db = await _appDatabase.database;
      
      // Verificar se já existe
      final existing = await db.query(
        _infestationSummariesTable,
        where: 'talhao_id = ? AND organismo_id = ? AND periodo_fim = ?',
        whereArgs: [talhaoId, organismoId, periodoFim.toIso8601String()],
      );
      
      final summaryData = {
        'id': existing.isNotEmpty ? existing.first['id'] : '${talhaoId}_${organismoId}_${DateTime.now().millisecondsSinceEpoch}',
        'talhao_id': talhaoId,
        'organismo_id': organismoId,
        'periodo_ini': periodoIni.toIso8601String(),
        'periodo_fim': periodoFim.toIso8601String(),
        'avg_infestation': avgPct,
        'level': level,
        'last_update': DateTime.now().toIso8601String(),
        'heat_geojson': heatGeoJson,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (existing.isNotEmpty) {
        // Update
        await db.update(
          _infestationSummariesTable,
          summaryData,
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
        Logger.info('✅ Resumo atualizado: ${existing.first['id']}');
      } else {
        // Insert
        summaryData['created_at'] = DateTime.now().toIso8601String();
        await db.insert(
          _infestationSummariesTable,
          summaryData,
        );
        Logger.info('✅ Resumo criado: ${summaryData['id']}');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao fazer upsert de resumo: $e');
      rethrow;
    }
  }

  /// Cria um alerta de infestação
  Future<void> createAlert({
    required String talhaoId,
    required String organismoId,
    required String level,
    String? description,
    String? monitoringId,
  }) async {
    try {
      Logger.info('🚨 Criando alerta: Talhão: $talhaoId | Organismo: $organismoId | Nível: $level');
      
      final db = await _appDatabase.database;
      
      final alertData = {
        'id': 'ALERT_${talhaoId}_${organismoId}_${DateTime.now().millisecondsSinceEpoch}',
        'talhao_id': talhaoId,
        'organismo_id': organismoId,
        'level': level,
        'description': description ?? 'Nível $level detectado para organismo $organismoId',
        'origin': 'auto',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      };
      
      await db.insert(
        _infestationAlertsTable,
        alertData,
      );
      
      Logger.info('✅ Alerta criado: ${alertData['id']}');
      
    } catch (e) {
      Logger.error('❌ Erro ao criar alerta: $e');
      rethrow;
    }
  }

  /// Stream de alertas em tempo real
  Stream<InfestationAlert> streamAlertas() async* {
    try {
      final db = await _appDatabase.database;
      
      // Buscar alertas ativos
      final List<Map<String, dynamic>> maps = await db.query(
        _infestationAlertsTable,
        where: 'is_active = 1',
        orderBy: 'created_at DESC',
      );
      
      for (final map in maps) {
        yield InfestationAlert.fromMap(map);
      }
      
      // TODO: Implementar stream em tempo real com notificações
      // Por enquanto, retorna alertas existentes
      
    } catch (e) {
      Logger.error('❌ Erro no stream de alertas: $e');
    }
  }

  /// Obtém estatísticas de infestação por talhão
  Future<Map<String, dynamic>> getInfestationStatsByTalhao(String talhaoId) async {
    try {
      Logger.info('📊 Obtendo estatísticas de infestação para talhão: $talhaoId');
      
      final db = await _appDatabase.database;
      
      // Buscar resumos do talhão
      final summaries = await db.query(
        _infestationSummariesTable,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'last_update DESC',
      );
      
      if (summaries.isEmpty) {
        return {
          'total_organismos': 0,
          'nivel_geral': 'BAIXO',
          'ultima_atualizacao': null,
          'alertas_ativos': 0,
        };
      }
      
      // Calcular estatísticas
      int totalOrganismos = summaries.length;
      int alertasAtivos = 0;
      DateTime? ultimaAtualizacao;
      
      // Contar alertas ativos
      final alertas = await db.query(
        _infestationAlertsTable,
        where: 'talhao_id = ? AND is_active = 1',
        whereArgs: [talhaoId],
      );
      alertasAtivos = alertas.length;
      
      // Determinar nível geral
      String nivelGeral = 'BAIXO';
      for (final summary in summaries) {
        final level = summary['level'] as String;
        if (level == 'CRITICO') {
          nivelGeral = 'CRITICO';
          break;
        } else if (level == 'ALTO' && nivelGeral != 'CRITICO') {
          nivelGeral = 'ALTO';
        } else if (level == 'MODERADO' && nivelGeral == 'BAIXO') {
          nivelGeral = 'MODERADO';
        }
      }
      
      // Última atualização
      if (summaries.isNotEmpty) {
        ultimaAtualizacao = DateTime.tryParse(summaries.first['last_update'] as String);
      }
      
      final stats = {
        'total_organismos': totalOrganismos,
        'nivel_geral': nivelGeral,
        'ultima_atualizacao': ultimaAtualizacao?.toIso8601String(),
        'alertas_ativos': alertasAtivos,
        'resumos': summaries,
      };
      
      Logger.info('✅ Estatísticas obtidas para talhão: $talhaoId');
      return stats;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de infestação: $e');
      return {};
    }
  }

  /// Obtém estatísticas de infestação para um talhão
  Future<Map<String, dynamic>> getTalhaoInfestationStats(String talhaoId) async {
    try {
      final db = await _appDatabase.database;
      
      // Buscar resumos do talhão
      final summaries = await db.query(
        _infestationSummariesTable,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'last_update DESC',
      );
      
      if (summaries.isEmpty) {
        return {
          'total_organisms': 0,
          'critical_levels': 0,
          'high_levels': 0,
          'moderate_levels': 0,
          'low_levels': 0,
          'last_update': DateTime.now().toIso8601String(),
        };
      }
      
      // Calcular estatísticas
      int criticalLevels = 0;
      int highLevels = 0;
      int moderateLevels = 0;
      int lowLevels = 0;
      
      for (final summary in summaries) {
        final level = summary['level'] as String;
        switch (level) {
          case 'CRITICO':
            criticalLevels++;
            break;
          case 'ALTO':
            highLevels++;
            break;
          case 'MODERADO':
            moderateLevels++;
            break;
          case 'BAIXO':
            lowLevels++;
            break;
        }
      }
      
      final totalOrganisms = summaries.map((s) => s['organismo_id'] as String).toSet().length;
      final lastUpdate = summaries.first['last_update'] as String;
      
      return {
        'total_organisms': totalOrganisms,
        'critical_levels': criticalLevels,
        'high_levels': highLevels,
        'moderate_levels': moderateLevels,
        'low_levels': lowLevels,
        'last_update': lastUpdate,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de infestação: $e');
      return {};
    }
  }

  // ===== MÉTODOS PRIVADOS PARA CONEXÃO COM MONITORAMENTO =====

  /// Obtém monitoramento por ID
  Future<Monitoring?> _getMonitoringById(String monitoringId) async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'monitorings',
        where: 'id = ?',
        whereArgs: [monitoringId],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      final monitoring = Monitoring.fromMap(maps.first);
      final points = await _getPointsBySessionId(monitoring.id);
      return monitoring.copyWith(points: points);
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar monitoramento por ID: $e');
      return null;
    }
  }

  /// Obtém monitoramentos de um talhão do módulo de monitoramento
  Future<List<Monitoring>> _getMonitoringsByTalhao(
    String talhaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  ) async {
    try {
      final db = await _appDatabase.database;
      
      // ✅ CORRIGIDO: Buscar na tabela monitoring_sessions com coluna talhao_id
      String whereClause = 'talhao_id = ? AND status = ?';
      List<dynamic> whereArgs = [talhaoId, 'finalized'];
      
      if (dataInicio != null) {
        whereClause += ' AND started_at >= ?';
        whereArgs.add(dataInicio.toIso8601String());
      }
      
      if (dataFim != null) {
        whereClause += ' AND started_at <= ?';
        whereArgs.add(dataFim.toIso8601String());
      }
      
      final List<Map<String, dynamic>> sessionsData = await db.query(
        'monitoring_sessions',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'started_at DESC',
      );
      
      Logger.info('📊 [REPO] ${sessionsData.length} sessões encontradas para talhão $talhaoId');
      
      List<Monitoring> monitorings = [];
      for (var sessionData in sessionsData) {
        try {
          final sessionId = sessionData['id'] as String;
          
          // Buscar pontos da sessão
          final points = await _getPointsBySessionId(sessionId);
          
          monitorings.add(Monitoring(
            id: sessionId,
            date: DateTime.tryParse(sessionData['started_at'] as String? ?? '') ?? DateTime.now(),
            plotId: int.tryParse(talhaoId) ?? talhaoId.hashCode.abs(),
            plotName: sessionData['talhao_nome'] as String? ?? 'Talhão',
            cropId: sessionData['cultura_id'] as String? ?? '',
            cropName: sessionData['cultura_nome'] as String? ?? 'Cultura',
            route: [],
            points: points,
            createdAt: DateTime.tryParse(sessionData['created_at'] as String? ?? '') ?? DateTime.now(),
            technicianName: sessionData['tecnico_nome'] as String? ?? 'Técnico',
            observations: sessionData['observacoes'] as String?,
          ));
        } catch (e) {
          Logger.error('❌ [REPO] Erro ao processar sessão: $e');
          continue;
        }
      }
      
      Logger.info('✅ [REPO] ${monitorings.length} monitoramentos processados');
      return monitorings;
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao obter monitoramentos do talhão: $e');
      Logger.error('❌ Stack: $stack');
      return [];
    }
  }

  /// Obtém pontos de monitoramento por ID de sessão (CORRIGIDO)
  Future<List<MonitoringPoint>> _getPointsBySessionId(String sessionId) async {
    try {
      final db = await _appDatabase.database;
      
      // ✅ CORRIGIDO: Buscar com session_id
      final List<Map<String, dynamic>> pointsData = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'numero ASC',
      );
      
      Logger.info('📍 [REPO] ${pointsData.length} pontos encontrados para sessão $sessionId');
      
      List<MonitoringPoint> points = [];
      for (var pointData in pointsData) {
        try {
          final pointId = pointData['id'] as String;
          
          // Buscar ocorrências do ponto
          final occurrences = await _getOccurrencesByPointId(pointId);
          
          points.add(MonitoringPoint(
            id: pointId,
            plotId: 0, // Será preenchido pela sessão
            plotName: '', // Será preenchido pela sessão
            latitude: pointData['latitude'] as double? ?? 0.0,
            longitude: pointData['longitude'] as double? ?? 0.0,
            occurrences: occurrences,
            observations: pointData['observacoes'] as String?,
            createdAt: DateTime.tryParse(pointData['created_at'] as String? ?? '') ?? DateTime.now(),
          ));
        } catch (e) {
          Logger.error('❌ [REPO] Erro ao processar ponto: $e');
          continue;
        }
      }
      
      Logger.info('✅ [REPO] ${points.length} pontos processados');
      return points;
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao obter pontos de monitoramento: $e');
      Logger.error('❌ Stack: $stack');
      return [];
    }
  }

  /// Obtém ocorrências por ponto (CORRIGIDO)
  Future<List<Occurrence>> _getOccurrencesByPointId(String pointId) async {
    try {
      final db = await _appDatabase.database;
      
      // ✅ CORRIGIDO: Buscar na tabela monitoring_occurrences
      final List<Map<String, dynamic>> occurrencesData = await db.query(
        'monitoring_occurrences',
        where: 'point_id = ?',
        whereArgs: [pointId],
        orderBy: 'created_at ASC',
      );
      
      Logger.info('🐛 [REPO] ${occurrencesData.length} ocorrências encontradas para ponto $pointId');
      
      List<Occurrence> occurrences = [];
      for (var occ in occurrencesData) {
        try {
          // Mapear tipo de ocorrência
          final tipo = (occ['tipo'] as String?)?.toLowerCase() ?? 'pest';
          OccurrenceType occType = OccurrenceType.pest;
          if (tipo.contains('doen') || tipo == 'disease') {
            occType = OccurrenceType.disease;
          } else if (tipo.contains('daninha') || tipo == 'weed') {
            occType = OccurrenceType.weed;
          }
          
          occurrences.add(Occurrence(
            id: occ['id'] as String,
            type: occType,
            name: occ['subtipo'] as String? ?? 'Não identificado',
            infestationIndex: (occ['percentual'] as num?)?.toDouble() ?? 0.0,
            affectedSections: [PlantSection.middle],
            organismName: occ['subtipo'] as String?,
            notes: occ['observacoes'] as String?,
          ));
        } catch (e) {
          Logger.error('❌ [REPO] Erro ao processar ocorrência: $e');
          continue;
        }
      }
      
      Logger.info('✅ [REPO] ${occurrences.length} ocorrências processadas');
      return occurrences;
      
    } catch (e, stack) {
      Logger.error('❌ Erro ao obter ocorrências: $e');
      Logger.error('❌ Stack: $stack');
      return [];
    }
  }

  /// Processa dados de monitoramento para gerar resumos de infestação
  Future<List<InfestationSummary>> _processMonitoringsForInfestation(
    List<Monitoring> monitorings,
    String talhaoId,
    String? organismoId,
  ) async {
    try {
      final summaries = <InfestationSummary>[];
      
      // Agrupar pontos por organismo
      final pointsByOrganism = <String, List<MonitoringPoint>>{};
      
      for (final monitoring in monitorings) {
        for (final point in monitoring.points) {
          for (final occurrence in point.occurrences) {
            // Filtrar por organismo específico se fornecido
            if (organismoId != null && occurrence.name != organismoId) {
              continue;
            }
            
            final organismKey = occurrence.name;
            pointsByOrganism.putIfAbsent(organismKey, () => []).add(point);
          }
        }
      }
      
      // Processar cada organismo
      for (final entry in pointsByOrganism.entries) {
        final organismoId = entry.key;
        final points = entry.value;
        
        if (points.isEmpty) continue;
        
        // Calcular estatísticas usando o serviço de cálculo
        final stats = _calculateInfestationStats(points, organismoId);
        
        // Determinar nível de infestação
        final level = await _determineInfestationLevel(stats['avg_infestation'] as double, organismoId);
        
        // Criar resumo
        final summary = InfestationSummary(
          id: '${talhaoId}_${organismoId}_${DateTime.now().millisecondsSinceEpoch}',
          talhaoId: talhaoId,
          organismoId: organismoId,
          periodoIni: monitorings.last.date,
          periodoFim: monitorings.first.date,
          avgInfestation: stats['avg_infestation'] as double,
          infestationPercentage: stats['avg_infestation'] as double,
          level: level, // level já é String
          lastUpdate: DateTime.now(),
          totalPoints: stats['total_points'] as int,
          pointsWithOccurrence: stats['points_with_occurrence'] as int,
        );
        
        summaries.add(summary);
      }
      
      return summaries;
      
    } catch (e) {
      Logger.error('❌ Erro ao processar monitoramentos para infestação: $e');
      return [];
    }
  }

  /// Determina o nível de infestação baseado no percentual
  Future<String> _determineInfestationLevel(double pct, String organismoId) async {
    try {
      // TODO: Implementar busca de thresholds do catálogo de organismos
      // Por enquanto, usar thresholds padrão
      const lowLimit = 25.0;
      const mediumLimit = 50.0;
      const highLimit = 75.0;

      if (pct <= lowLimit) return 'BAIXO';
      if (pct <= mediumLimit) return 'MODERADO';
      if (pct <= highLimit) return 'ALTO';
      return 'CRITICO';
      
    } catch (e) {
      Logger.error('❌ Erro ao determinar nível de infestação: $e');
      return 'DESCONHECIDO';
    }
  }

  /// Calcula estatísticas de infestação para um conjunto de pontos
  Map<String, dynamic> _calculateInfestationStats(
    List<MonitoringPoint> points,
    String organismoId,
  ) {
    try {
      if (points.isEmpty) {
        return {
          'total_points': 0,
          'points_with_occurrence': 0,
          'avg_infestation': 0.0,
        };
      }
      
      int totalPoints = points.length;
      int pointsWithOccurrence = 0;
      double totalInfestation = 0.0;
      
      for (final point in points) {
        // Buscar ocorrência do organismo específico neste ponto
        final occurrence = point.occurrences.firstWhere(
          (o) => o.name == organismoId,
          orElse: () => Occurrence(
            type: OccurrenceType.values.first, // Usar primeiro tipo disponível
            name: organismoId,
            infestationIndex: 0.0,
            affectedSections: [],
          ),
        );
        
        if (occurrence.infestationIndex > 0) {
          pointsWithOccurrence++;
        }
        
        totalInfestation += occurrence.infestationIndex;
      }
      
      final avgInfestation = totalPoints > 0 ? totalInfestation / totalPoints : 0.0;
      
      return {
        'total_points': totalPoints,
        'points_with_occurrence': pointsWithOccurrence,
        'avg_infestation': avgInfestation,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas de infestação: $e');
      return {
        'total_points': 0,
        'points_with_occurrence': 0,
        'avg_infestation': 0.0,
      };
    }
  }

  /// Obtém todos os resumos de infestação
  Future<List<InfestationSummary>> getAllInfestationSummaries() async {
    try {
      final db = await _appDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _infestationSummariesTable,
        orderBy: 'last_update DESC',
      );
      
      return maps.map((map) => InfestationSummary.fromMap(map)).toList();
      
    } catch (e) {
      Logger.error('❌ Erro ao obter todos os resumos de infestação: $e');
      return [];
    }
  }

  /// Obtém dados históricos para timelapse
  Future<List<Map<String, dynamic>>> getTimelapseData({
    String? talhaoId,
    String? organismoId,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? limit,
  }) async {
    try {
      final db = await _appDatabase.database;
      
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      if (dataInicio != null) {
        whereClause += ' AND data_coleta >= ?';
        whereArgs.add(dataInicio.toIso8601String());
      }
      
      if (dataFim != null) {
        whereClause += ' AND data_coleta <= ?';
        whereArgs.add(dataFim.toIso8601String());
      }
      
      String limitClause = '';
      if (limit != null) {
        limitClause = ' LIMIT $limit';
      }
      
      final results = await db.query(
        _infestationTimelapseTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_coleta ASC',
      );
      
      Logger.info('📊 ${results.length} registros históricos obtidos para timelapse');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter dados de timelapse: $e');
      return [];
    }
  }

  /// Obtém tendências temporais de infestação
  Future<List<Map<String, dynamic>>> getInfestationTrends({
    String? talhaoId,
    String? organismoId,
    int days = 30,
  }) async {
    try {
      final db = await _appDatabase.database;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      
      String whereClause = 'data_coleta >= ?';
      List<dynamic> whereArgs = [cutoffDate];
      
      if (talhaoId != null) {
        whereClause += ' AND talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (organismoId != null) {
        whereClause += ' AND organismo_id = ?';
        whereArgs.add(organismoId);
      }
      
      final results = await db.query(
        _infestationTimelapseTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'data_coleta ASC',
      );
      
      Logger.info('📈 ${results.length} registros de tendência obtidos');
      return results;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter tendências: $e');
      return [];
    }
  }
}
