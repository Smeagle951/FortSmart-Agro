import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../utils/logger.dart';
import '../utils/config.dart';
import '../database/app_database.dart';
import 'monitoring_analysis_service.dart';

/// Serviço de API para Monitoramento Avançado
/// Implementa todos os endpoints necessários conforme especificado no guia
class MonitoringApiService {
  static const String _tag = 'MonitoringApiService';
  final AppDatabase _database = AppDatabase();
  final MonitoringAnalysisService _analysisService = MonitoringAnalysisService();
  
  // Configurações da API
  final String _baseUrl = AppConfig.apiBaseUrl;
  final String _apiKey = AppConfig.apiToken;

  /// Cria uma nova sessão de monitoramento
  Future<Map<String, dynamic>> createSession({
    required String fazendaId,
    required String talhaoId,
    required String culturaId,
    required int amostragemPadraoPlantasPorPonto,
  }) async {
    try {
      Logger.info('$_tag: Criando sessão de monitoramento...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/monitoring/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'fazenda_id': fazendaId,
          'talhao_id': talhaoId,
          'cultura_id': culturaId,
          'amostragem_padrao_plantas_por_ponto': amostragemPadraoPlantasPorPonto,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Logger.info('$_tag: ✅ Sessão criada com sucesso: ${data['session_id']}');
        return data;
      } else {
        Logger.error('$_tag: ❌ Erro ao criar sessão: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao criar sessão: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na requisição: $e');
      rethrow;
    }
  }

  /// Adiciona um ponto à sessão de monitoramento
  Future<Map<String, dynamic>> addPoint({
    required String sessionId,
    required int numero,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    int? plantasAvaliadas,
    double? gpsAccuracy,
    bool manualEntry = false,
    List<String>? attachments,
    String? observacoes,
  }) async {
    try {
      Logger.info('$_tag: Adicionando ponto $numero à sessão $sessionId...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/monitoring/sessions/$sessionId/points'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'numero': numero,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': timestamp.toIso8601String(),
          'plantas_avaliadas': plantasAvaliadas,
          'gps_accuracy': gpsAccuracy,
          'manual_entry': manualEntry,
          'attachments': attachments,
          'observacoes': observacoes,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Logger.info('$_tag: ✅ Ponto adicionado com sucesso: ${data['point_id']}');
        return data;
      } else {
        Logger.error('$_tag: ❌ Erro ao adicionar ponto: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao adicionar ponto: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na requisição: $e');
      rethrow;
    }
  }

  /// Adiciona uma ocorrência a um ponto
  Future<Map<String, dynamic>> addOccurrence({
    required String pointId,
    required int organismId,
    required double valorBruto,
    String? observacao,
  }) async {
    try {
      Logger.info('$_tag: Adicionando ocorrência ao ponto $pointId...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/monitoring/points/$pointId/occurrences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'organism_id': organismId,
          'valor_bruto': valorBruto,
          'observacao': observacao,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Logger.info('$_tag: ✅ Ocorrência adicionada com sucesso: ${data['occurrence_id']}');
        return data;
      } else {
        Logger.error('$_tag: ❌ Erro ao adicionar ocorrência: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao adicionar ocorrência: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na requisição: $e');
      rethrow;
    }
  }

  /// Finaliza uma sessão de monitoramento (TRANSCIONAL)
  Future<AnalysisResult> finalizeSession(String sessionId) async {
    try {
      Logger.info('$_tag: Finalizando sessão $sessionId...');
      
      // 1. Obter dados completos da sessão do banco local
      final sessionData = await _getCompleteSessionData(sessionId);
      
      // 2. Enviar dados para o servidor
      final response = await http.post(
        Uri.parse('$_baseUrl/api/monitoring/sessions/$sessionId/finalize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(sessionData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('$_tag: ✅ Sessão finalizada com sucesso');
        
        // 3. Atualizar status local
        await _updateSessionStatus(sessionId, 'finalized');
        
        // 4. Retornar resultado da análise
        return AnalysisResult(
          sessionId: sessionId,
          talhaoId: sessionData['session']['talhao_id'],
          resumoPorOrganismo: _parseOrganismSummaries(data['resumo_por_organismo']),
          pontos: _parsePointAnalyses(data['pontos']),
          catalogVersion: data['catalog_version'] ?? '1.0.0',
          analyzedAt: DateTime.parse(data['analyzed_at']),
        );
      } else {
        Logger.error('$_tag: ❌ Erro ao finalizar sessão: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao finalizar sessão: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na requisição: $e');
      rethrow;
    }
  }

  /// Obtém o mapa de infestação de um talhão
  Future<Map<String, dynamic>> getInfestationMap({
    required String talhaoId,
    DateTime? date,
  }) async {
    try {
      Logger.info('$_tag: Obtendo mapa de infestação para talhão $talhaoId...');
      
      final queryParams = <String>[];
      if (date != null) {
        queryParams.add('date=${date.toIso8601String()}');
      }
      
      final url = queryParams.isEmpty
          ? '$_baseUrl/api/infestation/talhao/$talhaoId'
          : '$_baseUrl/api/infestation/talhao/$talhaoId?${queryParams.join('&')}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('$_tag: ✅ Mapa de infestação obtido com sucesso');
        return data;
      } else {
        Logger.error('$_tag: ❌ Erro ao obter mapa: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao obter mapa: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na requisição: $e');
      rethrow;
    }
  }

  /// Sincroniza o catálogo de organismos
  Future<bool> syncOrganismCatalog() async {
    try {
      Logger.info('$_tag: Sincronizando catálogo de organismos...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/catalog/organisms'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveOrganismCatalog(data['organisms']);
        Logger.info('$_tag: ✅ Catálogo sincronizado com sucesso');
        return true;
      } else {
        Logger.error('$_tag: ❌ Erro ao sincronizar catálogo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('$_tag: ❌ Erro na sincronização: $e');
      return false;
    }
  }

  /// Obtém dados completos da sessão do banco local
  Future<Map<String, dynamic>> _getCompleteSessionData(String sessionId) async {
    final db = await _database.database;
    
    // Obter dados da sessão
    final sessionResult = await db.query(
      'monitoring_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    
    if (sessionResult.isEmpty) {
      throw Exception('Sessão não encontrada: $sessionId');
    }
    
    final session = sessionResult.first;
    
    // Obter pontos da sessão
    final pointsResult = await db.query(
      'monitoring_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'numero ASC',
    );
    
    // Obter ocorrências de todos os pontos
    final pointIds = pointsResult.map((p) => p['id']).toList();
    final occurrencesResult = await db.query(
      'monitoring_occurrences',
      where: 'point_id IN (${List.filled(pointIds.length, '?').join(',')})',
      whereArgs: pointIds,
    );
    
    // Organizar ocorrências por ponto
    final occurrencesByPoint = <String, List<Map<String, dynamic>>>{};
    for (final occurrence in occurrencesResult) {
      final pointId = occurrence['point_id'] as String;
      occurrencesByPoint.putIfAbsent(pointId, () => []).add(occurrence);
    }
    
    // Montar estrutura de pontos com ocorrências
    final points = pointsResult.map((point) {
      final pointId = point['id'] as String;
      final occurrences = occurrencesByPoint[pointId] ?? [];
      
      return {
        'id': pointId,
        'numero': point['numero'],
        'latitude': point['latitude'],
        'longitude': point['longitude'],
        'timestamp': point['timestamp'],
        'plantas_avaliadas': point['plantas_avaliadas'],
        'gps_accuracy': point['gps_accuracy'],
        'manual_entry': point['manual_entry'] == 1,
        'attachments': point['attachments_json'] != null 
            ? jsonDecode(point['attachments_json'] as String) 
            : [],
        'observacoes': point['observacoes'],
        'occurrences': occurrences.map((occ) => {
          'organism_id': occ['organism_id'],
          'valor_bruto': occ['valor_bruto'],
          'observacao': occ['observacao'],
        }).toList(),
      };
    }).toList();
    
    return {
      'session': {
        'id': session['id'],
        'fazenda_id': session['fazenda_id'],
        'talhao_id': session['talhao_id'],
        'cultura_id': session['cultura_id'],
        'amostragem_padrao_plantas_por_ponto': session['amostragem_padrao_plantas_por_ponto'],
        'started_at': session['started_at'],
        'catalog_version': session['catalog_version'],
      },
      'points': points,
    };
  }

  /// Atualiza o status da sessão no banco local
  Future<void> _updateSessionStatus(String sessionId, String status) async {
    final db = await _database.database;
    await db.update(
      'monitoring_sessions',
      {
        'status': status,
        'finished_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Salva o catálogo de organismos no banco local
  Future<void> _saveOrganismCatalog(List<dynamic> organisms) async {
    final db = await _database.database;
    final batch = db.batch();
    
    for (final organism in organisms) {
      batch.insert(
        'catalog_organisms',
        organism,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  /// Converte dados de resumo de organismos
  List<OrganismSummary> _parseOrganismSummaries(List<dynamic> data) {
    return data.map((item) => OrganismSummary(
      organismId: item['organism_id'] as int,
      frequenciaPercent: (item['frequencia_percent'] as num?)?.toDouble() ?? 0.0,
      intensidadeMedia: (item['intensidade_media'] as num?)?.toDouble() ?? 0.0,
      indicePercent: (item['indice_percent'] as num?)?.toDouble() ?? 0.0,
      nivel: item['nivel'] as String? ?? 'baixo',
    )).toList();
  }

  /// Converte dados de análise de pontos
  List<PointAnalysis> _parsePointAnalyses(List<dynamic> data) {
    return data.map((item) => PointAnalysis(
      pointId: item['point_id'] as int,
      latitude: (item['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (item['longitude'] as num?)?.toDouble() ?? 0.0,
      organismos: (item['organismos'] as List<dynamic>).map((org) => 
        OrganismAnalysis(
          organismId: org['organism_id'] as int,
          valorNorm: (org['valor_norm'] as num?)?.toDouble() ?? 0.0,
          nivel: org['nivel'] as String? ?? 'baixo',
        )
      ).toList(),
    )).toList();
  }

  /// Verifica se o servidor está online
  Future<bool> isServerOnline() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/health'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.warning('$_tag: Servidor offline: $e');
      return false;
    }
  }

  /// Obtém estatísticas de sincronização
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/monitoring/sync/stats'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Falha ao obter estatísticas'};
      }
    } catch (e) {
      Logger.error('$_tag: Erro ao obter estatísticas: $e');
      return {'error': 'Erro de conexão'};
    }
  }
}
