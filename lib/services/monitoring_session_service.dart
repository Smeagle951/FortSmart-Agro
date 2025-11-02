import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../models/organism_catalog.dart';
import '../models/monitoring.dart';
import '../repositories/organism_catalog_repository.dart';
import '../repositories/infestation_rules_repository.dart';
import '../services/intelligent_infestation_service.dart';
import '../services/cultura_service.dart';
import '../modules/infestation_map/services/infestacao_integration_service.dart';
import '../database/repositories/estande_plantas_repository.dart';
import '../database/models/estande_plantas_model.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';

/// Serviço completo de sessão de monitoramento
/// Implementa o fluxo completo conforme especificação do documento
/// Utiliza dados reais do catálogo de organismos e culturas da fazenda
class MonitoringSessionService {
  final AppDatabase _database = AppDatabase();
  final OrganismCatalogRepository _organismCatalogRepository = OrganismCatalogRepository();
  // Removido: InfestationRulesRepository - funcionalidade integrada ao OrganismCatalogRepository
  final IntelligentInfestationService _intelligentInfestationService = IntelligentInfestationService();
  final CulturaService _culturaService = CulturaService();
  final EstandePlantasRepository _estandeRepository = EstandePlantasRepository();
  final InfestacaoIntegrationService _infestationIntegration = InfestacaoIntegrationService();
  
  static const String _tag = 'MonitoringSessionService';

  /// Cria uma nova sessão de monitoramento
  Future<String> createSession({
    required String fazendaId,
    required String talhaoId,
    required String culturaId,
    required String culturaNome,
    int amostragemPadraoPlantasPorPonto = 10,
    String? deviceId,
  }) async {
    try {
      final sessionId = const Uuid().v4();
      final now = DateTime.now();
      
      // Criar sessão no banco de dados
      final db = await _database.database;
      
      await db.insert('monitoring_sessions', {
        'id': sessionId,
        'fazenda_id': fazendaId,
        'talhao_id': talhaoId,
        'cultura_id': culturaId,
        'cultura_nome': culturaNome,
        'amostragem_padrao_plantas_por_ponto': amostragemPadraoPlantasPorPonto,
        'started_at': now.toIso8601String(),
        'status': 'draft',
        'device_id': deviceId,
        'catalog_version': await _getCurrentCatalogVersion(),
        'sync_state': 'synced', // Local, não precisa sincronizar
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      Logger.info('$_tag: ✅ Sessão criada: $sessionId');
      return sessionId;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao criar sessão: $e');
      rethrow;
    }
  }

  /// Adiciona um ponto de monitoramento à sessão
  Future<String> addPoint({
    required String sessionId,
    required int numero,
    required double latitude,
    required double longitude,
    int? plantasAvaliadas,
    double? gpsAccuracy,
    bool manualEntry = false,
    String? observacoes,
    List<String>? attachments,
  }) async {
    try {
      final pointId = const Uuid().v4();
      final now = DateTime.now();
      
      final db = await _database.database;
      
      await db.insert('monitoring_points', {
        'id': pointId,
        'session_id': sessionId,
        'numero': numero,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': now.toIso8601String(),
        'plantas_avaliadas': plantasAvaliadas,
        'gps_accuracy': gpsAccuracy,
        'manual_entry': manualEntry ? 1 : 0,
        'attachments_json': attachments != null ? jsonEncode(attachments) : null,
        'observacoes': observacoes,
        'sync_state': 'synced',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      Logger.info('$_tag: ✅ Ponto adicionado: $pointId (número $numero)');
      return pointId;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao adicionar ponto: $e');
      rethrow;
    }
  }

  /// Adiciona uma ocorrência a um ponto
  /// Utiliza organismId como String para compatibilidade com o catálogo
  Future<String> addOccurrence({
    required String pointId,
    required String organismId,
    required double valorBruto,
    String? observacao,
  }) async {
    try {
      final occurrenceId = const Uuid().v4();
      final now = DateTime.now();
      
      final db = await _database.database;
      
      await db.insert('monitoring_occurrences', {
        'id': occurrenceId,
        'point_id': pointId,
        'organism_id': organismId,
        'valor_bruto': valorBruto,
        'observacao': observacao,
        'sync_state': 'synced',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      Logger.info('$_tag: ✅ Ocorrência adicionada: $occurrenceId');
      return occurrenceId;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao adicionar ocorrência: $e');
      rethrow;
    }
  }

  /// Finaliza uma sessão de monitoramento e executa análise
  Future<Map<String, dynamic>> finalizeSession(String sessionId) async {
    try {
      Logger.info('$_tag: 🔄 Finalizando sessão: $sessionId');
      
      // 1. Atualizar status da sessão
      await _updateSessionStatus(sessionId, 'finalized');
      
      // 2. Carregar dados completos da sessão
      final sessionData = await _loadSessionData(sessionId);
      
      // 3. Executar análise inteligente
      final analysisResult = await _executeAnalysis(sessionData);
      
      // 4. Salvar resultado no mapa de infestação
      await _saveInfestationMap(sessionId, analysisResult);
      
      // 5. Retornar resultado consolidado
      return {
        'session_id': sessionId,
        'talhao_id': sessionData['session']['talhao_id'],
        'cultura_id': sessionData['session']['cultura_id'],
        'cultura_nome': sessionData['session']['cultura_nome'],
        'resumo_por_organismo': analysisResult['resumo_por_organismo'],
        'pontos': analysisResult['pontos'],
        'analise_finalizada_em': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao finalizar sessão: $e');
      rethrow;
    }
  }

  /// Obtém dados de infestação para um talhão
  Future<Map<String, dynamic>?> getInfestationData(String talhaoId) async {
    try {
      final db = await _database.database;
      
      // Buscar sessões finalizadas do talhão
      final sessions = await db.query(
        'monitoring_sessions',
        where: 'talhao_id = ? AND status = ?',
        whereArgs: [talhaoId, 'finalized'],
        orderBy: 'started_at DESC',
      );
      
      if (sessions.isEmpty) {
        return null;
      }
      
      // Buscar dados do mapa de infestação
      final infestationData = await db.query(
        'infestation_map',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'aggregated_at DESC',
      );
      
      // Processar dados para visualização
      final Map<String, dynamic> result = {
        'talhao_id': talhaoId,
        'sessoes': sessions.length,
        'ultima_analise': sessions.first['started_at'],
        'organismos': {},
        'pontos': [],
      };
      
      // Agrupar dados por organismo
      for (final data in infestationData) {
        final organismId = data['organism_id'].toString();
        if (!result['organismos'].containsKey(organismId)) {
          result['organismos'][organismId] = {
            'frequencia_percent': 0.0,
            'intensidade_media': 0.0,
            'indice_percent': 0.0,
            'nivel': 'baixo',
            'total_pontos': 0,
          };
        }
        
        final organism = result['organismos'][organismId];
        organism['frequencia_percent'] = data['frequencia_percent'] ?? 0.0;
        organism['intensidade_media'] = data['intensidade_media'] ?? 0.0;
        organism['indice_percent'] = data['indice_percent'] ?? 0.0;
        organism['nivel'] = data['nivel'] ?? 'baixo';
        organism['total_pontos'] = data['total_pontos'] ?? 0;
      }
      
      // Buscar pontos para visualização no mapa
      final points = await db.query(
        'monitoring_points',
        where: 'session_id IN (${sessions.map((s) => "'${s['id']}'").join(',')})',
        orderBy: 'numero ASC',
      );
      
      result['pontos'] = points.map((point) => {
        'point_id': point['id'],
        'numero': point['numero'],
        'latitude': point['latitude'],
        'longitude': point['longitude'],
        'plantas_avaliadas': point['plantas_avaliadas'],
        'manual_entry': point['manual_entry'] == 1,
        'gps_accuracy': point['gps_accuracy'],
      }).toList();
      
      return result;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter dados de infestação: $e');
      return null;
    }
  }

  /// Obtém sessões de monitoramento
  Future<List<Map<String, dynamic>>> getSessions({
    String? talhaoId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _database.database;
      
      // ✅ Por padrão, buscar sessões finalizadas OU ativas (que podem ter sido concluídas)
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];
      
      if (talhaoId != null) {
        whereClause += ' AND ms.talhao_id = ?';
        whereArgs.add(talhaoId);
      }
      
      if (status != null) {
        whereClause += ' AND ms.status = ?';
        whereArgs.add(status);
      } else {
        // ✅ Se não especificou status, buscar TODOS os status (draft, finalized, cancelled)
        whereClause += ' AND ms.status IN (?, ?, ?)';
        whereArgs.addAll(['draft', 'finalized', 'cancelled']);
      }
      
      if (startDate != null) {
        whereClause += ' AND (ms.started_at >= ? OR ms.data_inicio >= ?)';
        final dateStr = startDate.toIso8601String();
        whereArgs.add(dateStr);
        whereArgs.add(dateStr);
      }
      
      if (endDate != null) {
        whereClause += ' AND (ms.started_at <= ? OR ms.data_inicio <= ?)';
        final dateStr = endDate.toIso8601String();
        whereArgs.add(dateStr);
        whereArgs.add(dateStr);
      }
      
      // ✅ BUSCAR DIRETAMENTE DA TABELA monitoring_sessions (sem JOIN problemático)
      Logger.info('$_tag: 🔍 Buscando sessões diretamente da tabela...');
      
      final sessions = await db.query(
        'monitoring_sessions',
        where: whereClause.replaceAll('ms.', ''),
        whereArgs: whereArgs,
        orderBy: 'started_at DESC',
      );
      
      Logger.info('$_tag: 📊 Total de sessões encontradas: ${sessions.length}');
      
      if (sessions.isEmpty) {
        Logger.warning('$_tag: ⚠️ Nenhuma sessão encontrada!');
        return [];
      }
      
      // ✅ CALCULAR ESTATÍSTICAS: pontos_registrados e total_ocorrencias
      final sessionsWithStats = await Future.wait(sessions.map((s) async {
        final sessionId = s['id'] as String;
        
        // Contar pontos da sessão
        final pointsResult = await db.rawQuery(
          'SELECT COUNT(*) as total FROM monitoring_points WHERE session_id = ?',
          [sessionId],
        );
        final pontosRegistrados = (pointsResult.first['total'] as num?)?.toInt() ?? 0;
        
        // Contar ocorrências da sessão (via pontos ou diretamente)
        final occurrencesResult = await db.rawQuery(
          '''
          SELECT COUNT(*) as total 
          FROM monitoring_occurrences 
          WHERE session_id = ? OR point_id IN (
            SELECT id FROM monitoring_points WHERE session_id = ?
          )
          ''',
          [sessionId, sessionId],
        );
        final totalOcorrencias = (occurrencesResult.first['total'] as num?)?.toInt() ?? 0;
        
        // Calcular duração (verificar finished_at ou data_fim)
        int duracaoMinutos = 0;
        final finishedAtField = s['finished_at'] ?? s['data_fim'];
        final startedAtField = s['started_at'] ?? s['data_inicio'];
        
        if (finishedAtField != null && startedAtField != null) {
          try {
            final started = DateTime.parse(startedAtField as String);
            final finished = DateTime.parse(finishedAtField as String);
            final diffInSeconds = finished.difference(started).inSeconds;
            
            // ✅ ARREDONDAR: Se teve atividade, mostrar pelo menos 1 minuto
            if (diffInSeconds > 0) {
              duracaoMinutos = (diffInSeconds / 60).ceil(); // Arredondar para cima
            } else {
              duracaoMinutos = 0;
            }
            
            Logger.info('$_tag: ⏱️ Sessão ${s['id']}: ${duracaoMinutos}min (${diffInSeconds}s) - ${started.toIso8601String()} → ${finished.toIso8601String()}');
          } catch (e) {
            Logger.warning('$_tag: ⚠️ Erro ao calcular duração da sessão ${s['id']}: $e');
            duracaoMinutos = 0;
          }
        } else {
          Logger.warning('$_tag: ⚠️ Sessão ${s['id']} não tem timestamps de início/fim: finished_at=${finishedAtField}, started_at=${startedAtField}');
        }
        
        return {
          ...s,
          'talhao_nome': s['talhao_nome'] ?? s['talhao_id'] ?? 'Talhão',
          'cultura_nome': s['cultura_nome'] ?? s['cultura_id'] ?? 'Cultura',
          'pontos_registrados': pontosRegistrados, // ✅ NOVO
          'total_ocorrencias': totalOcorrencias, // ✅ NOVO
          'duracao_minutos': duracaoMinutos, // ✅ NOVO
        };
      }));
      
      Logger.info('$_tag: ✅ ${sessionsWithStats.length} sessões carregadas com estatísticas!');
      if (sessionsWithStats.isNotEmpty) {
        final first = sessionsWithStats.first;
        Logger.info('$_tag: ✅ Primeira sessão: ${first['talhao_nome']} - ${first['cultura_nome']} (${first['status']}) - ${first['pontos_registrados']} pontos, ${first['total_ocorrencias']} ocorrências');
      }
      
      return sessionsWithStats;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter sessões: $e');
      return [];
    }
  }

  /// Obtém pontos de uma sessão
  Future<List<Map<String, dynamic>>> getSessionPoints(String sessionId) async {
    try {
      final db = await _database.database;
      
      final points = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'numero ASC',
      );
      
      // Carregar ocorrências para cada ponto
      for (final point in points) {
        final occurrences = await db.query(
          'monitoring_occurrences',
          where: 'point_id = ?',
          whereArgs: [point['id']],
        );
        point['occurrences'] = occurrences;
      }
      
      return points;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter pontos da sessão: $e');
      return [];
    }
  }

  // Métodos privados auxiliares

  /// Atualiza o status de uma sessão
  Future<void> _updateSessionStatus(String sessionId, String status) async {
    final db = await _database.database;
    await db.update(
      'monitoring_sessions',
      {
        'status': status,
        'finished_at': status == 'finalized' ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Carrega dados completos de uma sessão
  Future<Map<String, dynamic>> _loadSessionData(String sessionId) async {
    final db = await _database.database;
    
    // Carregar sessão
    final sessions = await db.query(
      'monitoring_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    if (sessions.isEmpty) {
      throw Exception('Sessão não encontrada: $sessionId');
    }
    
    final session = sessions.first;
    
    // Carregar pontos
    final points = await db.query(
      'monitoring_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'numero ASC',
    );
    
    // Carregar ocorrências para cada ponto
    for (final point in points) {
      final occurrences = await db.query(
        'monitoring_occurrences',
        where: 'point_id = ?',
        whereArgs: [point['id']],
      );
      point['occurrences'] = occurrences;
    }
    
    return {
      'session': session,
      'points': points,
    };
  }

  /// Executa análise inteligente dos dados
  Future<Map<String, dynamic>> _executeAnalysis(Map<String, dynamic> sessionData) async {
    try {
      // Inicializar repositórios
      await _organismCatalogRepository.initialize();
      
      final session = sessionData['session'];
      final points = sessionData['points'] as List;
      
      // Converter para modelos
      final monitoringPoints = await Future.wait(points.map((point) async {
        final occurrences = await Future.wait((point['occurrences'] as List).map((occ) async {
          final organism = await getOrganismById(occ['organism_id']);
          return Occurrence(
            id: occ['id'],
            type: await _getOccurrenceTypeFromOrganismId(occ['organism_id']),
            name: organism?.name ?? 'Organismo ${occ['organism_id']}',
            infestationIndex: occ['valor_bruto'].toDouble(),
            affectedSections: [PlantSection.leaf], // Padrão
            notes: occ['observacao'],
            monitoringPointId: point['id'],
            createdAt: DateTime.parse(occ['created_at']),
            updatedAt: DateTime.parse(occ['updated_at']),
          );
        }));
        
        return MonitoringPoint(
          id: point['id'],
          monitoringId: session['id'],
          plotId: int.tryParse(session['talhao_id']) ?? 0,
          plotName: session['talhao_id'],
          cropId: session['cultura_id'].toString(),
          cropName: session['cultura_nome'],
          latitude: point['latitude'],
          longitude: point['longitude'],
          occurrences: occurrences,
          observations: point['observacoes'],
          createdAt: DateTime.parse(point['created_at']),
          updatedAt: DateTime.parse(point['updated_at']),
        );
      }));
      
      // Executar análise usando o serviço inteligente
      final result = await _intelligentInfestationService.calculateInfestation(
        monitoringId: session['id'],
        plotId: session['talhao_id'],
        plotName: session['talhao_id'],
        cropName: session['cultura_nome'],
        date: DateTime.parse(session['started_at']),
        points: monitoringPoints,
        farmId: session['fazenda_id'],
      );
      
      // Converter resultado para formato esperado
      return {
        'resumo_por_organismo': result.results.map((r) => {
          'organism_id': r.organism.id,
          'organism_name': r.organism.name,
          'frequencia_percent': r.frequency,
          'intensidade_media': r.averageQuantity,
          'indice_percent': r.infestationPercentage,
          'nivel': r.alertLevel,
          'total_pontos': r.totalPoints,
          'pontos_com_ocorrencia': r.pointsWithOccurrence,
        }).toList(),
        'pontos': monitoringPoints.map((point) => {
          'point_id': point.id,
          'numero': point.id, // Usar ID como número
          'latitude': point.latitude,
          'longitude': point.longitude,
          'organismos': point.occurrences.map((occ) => {
            'organism_id': occ.id,
            'valor_norm': occ.infestationIndex,
            'nivel': _calculateLevel(occ.infestationIndex),
          }).toList(),
        }).toList(),
      };
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na análise: $e');
      rethrow;
    }
  }

  /// Salva resultado no mapa de infestação e processa para geração de heatmap
  Future<void> _saveInfestationMap(String sessionId, Map<String, dynamic> analysisResult) async {
    try {
      final db = await _database.database;
      final now = DateTime.now();
      
      // Limpar dados anteriores da sessão
      await db.delete(
        'infestation_map',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      // Salvar novos dados básicos
      for (final organismo in analysisResult['resumo_por_organismo']) {
        await db.insert('infestation_map', {
          'session_id': sessionId,
          'talhao_id': analysisResult['talhao_id'] ?? '1',
          'organism_id': organismo['organism_id'],
          'infestacao_percent': organismo['indice_percent'],
          'nivel': organismo['nivel'],
          'frequencia_percent': organismo['frequencia_percent'],
          'intensidade_media': organismo['intensidade_media'],
          'indice_percent': organismo['indice_percent'],
          'total_pontos': organismo['total_pontos'],
          'pontos_com_ocorrencia': organismo['pontos_com_ocorrencia'],
          'catalog_version': await _getCurrentCatalogVersion(),
          'aggregated_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
        });
      }
      
      // 🔥 NOVO: Processar dados com IA FortSmart para gerar heatmap
      try {
        Logger.info('$_tag: 🤖 Iniciando processamento com IA FortSmart...');
        
        // Buscar dados completos da sessão para processamento
        final sessionData = await _loadSessionData(sessionId);
        final monitoring = _convertSessionDataToMonitoring(sessionData);
        
        // Processar com motor de cálculos avançados
        await _infestationIntegration.processMonitoringForInfestation(monitoring);
        
        Logger.info('$_tag: ✅ Processamento IA FortSmart concluído - heatmap gerado');
        
      } catch (e) {
        Logger.warning('$_tag: ⚠️ Erro no processamento IA FortSmart: $e');
        // Continuar mesmo se o processamento avançado falhar
      }
      
      Logger.info('$_tag: ✅ Mapa de infestação salvo para sessão: $sessionId');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao salvar mapa de infestação: $e');
      rethrow;
    }
  }

  /// Converte dados da sessão para objeto Monitoring
  Monitoring _convertSessionDataToMonitoring(Map<String, dynamic> sessionData) {
    try {
      final session = sessionData['session'] as Map<String, dynamic>;
      final points = sessionData['pontos'] as List<dynamic>;
      
      // Converter pontos para MonitoringPoint
      final monitoringPoints = points.map((pointData) {
        final point = pointData as Map<String, dynamic>;
        final occurrences = (point['ocorrencias'] as List<dynamic>).map((occ) {
          final occurrence = occ as Map<String, dynamic>;
          return Occurrence(
            id: occurrence['id'] as String? ?? '',
            type: OccurrenceType.pest, // Usar enum correto
            name: occurrence['name'] as String? ?? '',
            infestationIndex: (occurrence['severity'] as num?)?.toDouble() ?? 0.0,
            affectedSections: [PlantSection.leaf], // Usar enum correto
            notes: occurrence['notes'] as String? ?? '',
          );
        }).toList();
        
        return MonitoringPoint(
          id: point['id'] as String? ?? '',
          plotId: int.tryParse(session['talhao_id']?.toString() ?? '1') ?? 1,
          plotName: session['talhao_nome'] as String? ?? 'Talhão',
          latitude: (point['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (point['longitude'] as num?)?.toDouble() ?? 0.0,
          occurrences: occurrences,
          observations: point['notes'] as String? ?? '',
          createdAt: DateTime.parse(point['created_at'] as String? ?? DateTime.now().toIso8601String()),
        );
      }).toList();
      
      return Monitoring(
        id: session['id'] as String? ?? '',
        plotId: int.tryParse(session['talhao_id']?.toString() ?? '1') ?? 1,
        plotName: session['talhao_nome'] as String? ?? 'Talhão',
        cropId: session['cultura_id']?.toString() ?? '1',
        cropName: session['cultura_nome'] as String? ?? 'Cultura',
        date: DateTime.parse(session['started_at'] as String? ?? DateTime.now().toIso8601String()),
        route: [], // Rota não é necessária para processamento
        points: monitoringPoints,
        isCompleted: true,
        isSynced: false,
      );
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao converter dados da sessão: $e');
      rethrow;
    }
  }

  /// Obtém versão atual do catálogo
  Future<String> _getCurrentCatalogVersion() async {
    try {
      final db = await _database.database;
      final result = await db.rawQuery(
        'SELECT MAX(updated_at) as version FROM organism_catalog'
      );
      
      if (result.isNotEmpty && result.first['version'] != null) {
        return result.first['version'] as String;
      }
      
      return DateTime.now().toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  /// Obtém organismos disponíveis para uma cultura específica
  Future<List<OrganismCatalog>> getOrganismsForCrop(String cropId) async {
    try {
      await _organismCatalogRepository.initialize();
      return await _organismCatalogRepository.getByCrop(cropId);
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter organismos para cultura $cropId: $e');
      return [];
    }
  }

  /// Obtém organismos por tipo para uma cultura específica
  Future<List<OrganismCatalog>> getOrganismsByType(String cropId, OccurrenceType type) async {
    try {
      await _organismCatalogRepository.initialize();
      return await _organismCatalogRepository.getByCropAndType(cropId, type);
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter organismos por tipo: $e');
      return [];
    }
  }

  /// Obtém culturas disponíveis na fazenda
  Future<List<dynamic>> getAvailableCrops() async {
    try {
      return await _culturaService.loadCulturas();
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter culturas: $e');
      return [];
    }
  }

  /// Busca organismo no catálogo por ID
  Future<OrganismCatalog?> getOrganismById(String organismId) async {
    try {
      await _organismCatalogRepository.initialize();
      return await _organismCatalogRepository.getById(organismId);
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar organismo $organismId: $e');
      return null;
    }
  }

  /// Converte organism ID para tipo de ocorrência
  /// Busca no catálogo real de organismos
  Future<OccurrenceType> _getOccurrenceTypeFromOrganismId(String organismId) async {
    try {
      final organism = await getOrganismById(organismId);
      if (organism != null) {
        return organism.type;
      }
      // Fallback se não encontrar no catálogo
      return OccurrenceType.pest;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter tipo de organismo $organismId: $e');
      return OccurrenceType.pest;
    }
  }

  /// Calcula nível baseado no valor
  String _calculateLevel(double value) {
    if (value >= 80) return 'critico';
    if (value >= 60) return 'alto';
    if (value >= 30) return 'medio';
    return 'baixo';
  }

  /// Obtém dados de estande de plantas para um talhão e cultura
  Future<Map<String, dynamic>?> getEstandeData(String talhaoId, String culturaId) async {
    try {
      Logger.info('$_tag: Obtendo dados de estande para talhão $talhaoId e cultura $culturaId');
      
      // Buscar dados mais recentes de estande
      final estandeData = await _estandeRepository.getLatestByTalhaoAndCultura(
        talhaoId, 
        culturaId,
      );
      
      if (estandeData != null) {
        final diasAposEmergencia = estandeData.diasAposEmergencia ?? 0;
        
        return {
          'plantasPorHectare': estandeData.plantasPorHectare ?? 0.0,
          'eficiencia': estandeData.eficiencia ?? 0.0,
          'diasAposEmergencia': diasAposEmergencia,
          'estadoFenologico': _determinarEstadoFenologico(diasAposEmergencia, culturaId),
          'cv': _calcularCV(estandeData),
          'dataAvaliacao': estandeData.dataAvaliacao?.toIso8601String(),
        };
      }
      
      Logger.info('$_tag: Nenhum dado de estande encontrado');
      return null;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao obter dados de estande: $e');
      return null;
    }
  }

  /// Determina estado fenológico baseado em DAE e cultura
  String _determinarEstadoFenologico(int diasAposEmergencia, String culturaId) {
    // Estados fenológicos básicos por cultura
    final estadosPorCultura = {
      'soja': {
        'V1': [0, 10],
        'V2': [11, 15],
        'V3': [16, 20],
        'V4': [21, 25],
        'V5': [26, 30],
        'R1': [31, 35],
        'R2': [36, 45],
      },
      'milho': {
        'V1': [0, 7],
        'V2': [8, 12],
        'V3': [13, 17],
        'V4': [18, 22],
        'V5': [23, 27],
        'V6': [28, 32],
        'R1': [33, 40],
      },
      'algodao': {
        'V1': [0, 8],
        'V2': [9, 15],
        'V3': [16, 22],
        'V4': [23, 30],
        'V5': [31, 40],
        'R1': [41, 50],
      },
    };
    
    final estados = estadosPorCultura[culturaId.toLowerCase()] ?? estadosPorCultura['soja']!;
    
    for (final entry in estados.entries) {
      final range = entry.value;
      if (diasAposEmergencia >= range[0] && diasAposEmergencia <= range[1]) {
        return entry.key;
      }
    }
    
    return 'V1'; // Estado padrão
  }

  /// Calcula CV% baseado nos dados de estande
  double _calcularCV(EstandePlantasModel estande) {
    if (estande.plantasPorHectare == null || estande.populacaoIdeal == null) {
      return 0.0;
    }
    
    final media = estande.plantasPorHectare!;
    final ideal = estande.populacaoIdeal!;
    final diferenca = (media - ideal).abs();
    
    return (diferenca / ideal) * 100;
  }

  /// Duplica uma sessão de monitoramento
  Future<String> duplicateSession(String sessionId) async {
    try {
      final db = await _database.database;
      
      // Buscar sessão original
      final originalSession = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      if (originalSession.isEmpty) {
        throw Exception('Sessão não encontrada');
      }
      
      final original = originalSession.first;
      final newSessionId = const Uuid().v4();
      final now = DateTime.now();
      
      // Criar nova sessão duplicada
      await db.insert('monitoring_sessions', {
        'id': newSessionId,
        'fazenda_id': original['fazenda_id'],
        'talhao_id': original['talhao_id'],
        'cultura_id': original['cultura_id'],
        'cultura_nome': original['cultura_nome'],
        'amostragem_padrao_plantas_por_ponto': original['amostragem_padrao_plantas_por_ponto'],
        'started_at': now.toIso8601String(),
        'status': 'draft',
        'device_id': original['device_id'],
        'catalog_version': original['catalog_version'],
        'sync_state': 'synced',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      
      Logger.info('$_tag: ✅ Sessão duplicada: $newSessionId');
      return newSessionId;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao duplicar sessão: $e');
      rethrow;
    }
  }

  /// Exporta dados da sessão para compartilhamento
  Future<Map<String, dynamic>> exportSessionData(String sessionId) async {
    try {
      final db = await _database.database;
      
      // Buscar sessão
      final session = await db.query(
        'monitoring_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      
      if (session.isEmpty) {
        throw Exception('Sessão não encontrada');
      }
      
      // Buscar pontos da sessão
      final points = await db.query(
        'monitoring_points',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'numero ASC',
      );
      
      // Buscar ocorrências de cada ponto
      final exportData = <String, dynamic>{
        'session': session.first,
        'points': [],
      };
      
      for (final point in points) {
        final pointId = point['id'] as String;
        
        // Buscar ocorrências do ponto
        final occurrences = await db.query(
          'monitoring_occurrences',
          where: 'point_id = ?',
          whereArgs: [pointId],
        );
        
        exportData['points'].add({
          'point': point,
          'occurrences': occurrences,
        });
      }
      
      Logger.info('$_tag: ✅ Dados exportados: ${points.length} pontos');
      return exportData;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao exportar dados: $e');
      rethrow;
    }
  }
}
