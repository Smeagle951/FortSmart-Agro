import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import '../modules/infestation_map/repositories/infestation_repository.dart';
import '../modules/infestation_map/models/models.dart';
import '../modules/infestation_map/services/infestation_calculation_service.dart';
import 'infestation_priority_analysis_service.dart';

/// Serviço unificado para integração entre monitoramento e mapa de infestação
/// Corrige os problemas de incompatibilidade entre os módulos
class MonitoringInfestationIntegrationService {
  final AppDatabase _appDatabase = AppDatabase();
  final InfestationRepository _infestationRepository = InfestationRepository();
  final InfestationCalculationService _calculationService = InfestationCalculationService();
  final InfestationPriorityAnalysisService _priorityService = InfestationPriorityAnalysisService();

  /// Obtém todos os monitoramentos do banco de dados
  Future<List<Monitoring>> getAllMonitorings() async {
    try {
      final db = await _appDatabase.database;
      
      Logger.info('🔍 [INTEGRATION] Buscando sessões de monitoramento...');
      
      // ✅ BUSCAR NA TABELA CORRETA: monitoring_sessions
      final sessionsData = await db.query(
        'monitoring_sessions',
        where: 'status = ?',
        whereArgs: ['finalized'], // Apenas sessões finalizadas
        orderBy: 'created_at DESC',
      );
      
      Logger.info('📊 [INTEGRATION] ${sessionsData.length} sessões finalizadas encontradas');
      
      final monitorings = <Monitoring>[];
      
      for (final sessionData in sessionsData) {
        try {
          final sessionId = sessionData['id'] as String;
          
          // Buscar pontos da sessão
          final pointsData = await db.query(
            'monitoring_points',
            where: 'session_id = ?',
            whereArgs: [sessionId],
          );
          
          Logger.info('📍 [INTEGRATION] Sessão $sessionId: ${pointsData.length} pontos encontrados');
          
          final points = <MonitoringPoint>[];
          for (final pointData in pointsData) {
            try {
              final pointId = pointData['id'] as String;
              
              // ✅ BUSCAR NA TABELA CORRETA: monitoring_occurrences
              final occurrencesData = await db.query(
                'monitoring_occurrences',
                where: 'point_id = ?',
                whereArgs: [pointId],
              );
              
              Logger.info('🐛 [INTEGRATION] Ponto $pointId: ${occurrencesData.length} ocorrências encontradas');
              
              final occurrences = occurrencesData.map((occ) {
                // Mapear tipo de ocorrência
                final tipo = (occ['tipo'] as String?)?.toLowerCase() ?? 'pest';
                OccurrenceType occType = OccurrenceType.pest;
                if (tipo.contains('doen') || tipo == 'disease') {
                  occType = OccurrenceType.disease;
                } else if (tipo.contains('daninha') || tipo == 'weed') {
                  occType = OccurrenceType.weed;
                }
                
                return Occurrence(
                  id: occ['id'] as String,
                  type: occType,
                  name: occ['subtipo'] as String? ?? 'Não identificado',
                  infestationIndex: (occ['percentual'] as num?)?.toDouble() ?? 0.0,
                  affectedSections: [PlantSection.middle], // Seção padrão
                  organismName: occ['subtipo'] as String?,
                  notes: occ['observacao'] as String?, // ✅ CORRIGIDO: observacao (singular)
                );
              }).toList();
              
              if (pointData['latitude'] != null && pointData['longitude'] != null) {
                points.add(MonitoringPoint(
                  id: pointId,
                  plotId: int.tryParse(sessionData['talhao_id'] as String? ?? '0') ?? 0,
                  plotName: sessionData['talhao_nome'] as String? ?? 'Talhão',
                  latitude: pointData['latitude'] as double,
                  longitude: pointData['longitude'] as double,
                  occurrences: occurrences.cast<Occurrence>(),
                  observations: pointData['observacoes'] as String?,
                  createdAt: DateTime.tryParse(pointData['created_at'] as String? ?? '') ?? DateTime.now(),
                ));
              }
            } catch (e) {
              Logger.error('❌ [INTEGRATION] Erro ao processar ponto: $e');
              continue;
            }
          }
          
          if (points.isNotEmpty) {
            monitorings.add(Monitoring(
              id: sessionId,
              date: DateTime.tryParse(sessionData['started_at'] as String? ?? '') ?? DateTime.now(),
              plotId: int.tryParse(sessionData['talhao_id'] as String? ?? '0') ?? 0,
              plotName: sessionData['talhao_nome'] as String? ?? 'Talhão',
              cropId: sessionData['cultura_id'] as String? ?? '',
              cropName: sessionData['cultura_nome'] as String? ?? 'Cultura',
              route: [],
              points: points,
              createdAt: DateTime.tryParse(sessionData['created_at'] as String? ?? '') ?? DateTime.now(),
              technicianName: sessionData['tecnico_nome'] as String? ?? 'Técnico',
              observations: sessionData['observacoes'] as String?,
            ));
          }
        } catch (e) {
          Logger.error('❌ [INTEGRATION] Erro ao processar sessão: $e');
          continue;
        }
      }
      
      Logger.info('✅ [INTEGRATION] ${monitorings.length} monitoramentos carregados do banco');
      Logger.info('📊 [INTEGRATION] Total de pontos: ${monitorings.fold(0, (sum, m) => sum + m.points.length)}');
      Logger.info('🐛 [INTEGRATION] Total de ocorrências: ${monitorings.fold(0, (sum, m) => sum + m.points.fold(0, (pSum, p) => pSum + p.occurrences.length))}');
      
      return monitorings;
      
    } catch (e, stack) {
      Logger.error('❌ [INTEGRATION] Erro ao carregar monitoramentos: $e');
      Logger.error('❌ [INTEGRATION] Stack: $stack');
      return [];
    }
  }

  /// Processa um monitoramento salvo para gerar dados de infestação
  /// Este é o método principal que deve ser chamado após salvar um monitoramento
  Future<bool> processMonitoringForInfestation(Monitoring monitoring) async {
    try {
      Logger.info('🔄 [INTEGRAÇÃO] Processando monitoramento ${monitoring.id} para mapa de infestação...');
      
      // 1. Validar dados do monitoramento
      if (!_validateMonitoringData(monitoring)) {
        Logger.warning('⚠️ [INTEGRAÇÃO] Dados do monitoramento inválidos: ${monitoring.id}');
        return false;
      }
      
      // 2. Usar sistema de priorização para analisar infestações
      final priorityResults = await _priorityService.analyzeMonitoring(monitoring);
      
      if (priorityResults.isEmpty) {
        Logger.warning('⚠️ [INTEGRAÇÃO] Nenhuma infestação identificada no monitoramento: ${monitoring.id}');
          return false;
      }
      
      // 3. Processar resultados priorizados
      final processedPoints = _processPriorityResults(priorityResults, monitoring);
      if (processedPoints.isEmpty) {
        Logger.warning('⚠️ [INTEGRAÇÃO] Nenhum ponto válido processado: ${monitoring.id}');
          return false;
        }
      
      // 3. Agrupar por organismo
      final pointsByOrganism = _groupPointsByOrganism(processedPoints);
      
      // 4. Processar cada organismo
      for (final entry in pointsByOrganism.entries) {
        final organismId = entry.key;
        final points = entry.value;
        
        await _processOrganismInfestation(
          talhaoId: monitoring.plotId.toString(),
          organismoId: organismId,
          points: points,
          monitoringDate: monitoring.date,
        );
      }
      
      // 5. Atualizar resumo geral do talhão
      await _updateTalhaoSummary(monitoring.plotId.toString());
      
      Logger.info('✅ [INTEGRAÇÃO] Monitoramento processado com sucesso: ${monitoring.id}');
      return true;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao processar monitoramento: $e');
      return false;
    }
  }
  
  /// Valida dados do monitoramento
  bool _validateMonitoringData(Monitoring monitoring) {
    try {
      // Verificar se tem ID válido
      if (monitoring.id.isEmpty) {
        Logger.warning('⚠️ [INTEGRAÇÃO] ID do monitoramento vazio');
        return false;
      }
      
      // Verificar se tem pontos
      if (monitoring.points.isEmpty) {
        Logger.warning('⚠️ [INTEGRAÇÃO] Nenhum ponto no monitoramento');
        return false;
      }
      
      // Verificar se tem pelo menos um ponto com ocorrência
      bool hasOccurrences = false;
      for (final point in monitoring.points) {
        if (point.occurrences.isNotEmpty) {
          hasOccurrences = true;
          break;
        }
      }
      
      if (!hasOccurrences) {
        Logger.warning('⚠️ [INTEGRAÇÃO] Nenhuma ocorrência encontrada nos pontos');
        return false;
      }
      
      return true;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro na validação: $e');
      return false;
    }
  }
  
  /// Processa resultados priorizados para o formato do mapa de infestação
  List<Map<String, dynamic>> _processPriorityResults(
    List<InfestationPriorityResult> priorityResults,
    Monitoring monitoring,
  ) {
    final processedPoints = <Map<String, dynamic>>[];
    
    for (final result in priorityResults) {
      // Encontrar o ponto original para obter coordenadas
      MonitoringPoint? originalPoint;
      for (final point in monitoring.points) {
        for (final occurrence in point.occurrences) {
          if (occurrence.name == result.organismId) {
            originalPoint = point;
            break;
          }
        }
        if (originalPoint != null) break;
      }
      
      final processedPoint = {
        'id': '${monitoring.id}_${result.organismId}',
        'monitoring_id': monitoring.id,
        'talhao_id': monitoring.plotId.toString(),
        'latitude': originalPoint?.latitude ?? 0.0,
        'longitude': originalPoint?.longitude ?? 0.0,
        'accuracy': originalPoint?.gpsAccuracy ?? 5.0,
        'organismo_id': result.organismId,
        'organismo_tipo': result.organismType.toString().split('.').last,
        'infestation_value': result.infestationIndex,
        'affected_sections': '',
        'notes': result.recommendations.join('; '),
        'collected_at': result.detectedAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'severity_level': result.severityLevel,
        'priority_score': result.priorityScore,
        'risk_category': result.riskCategory,
        'urgency_level': result.urgencyLevel,
      };
      
      processedPoints.add(processedPoint);
    }
    
    Logger.info('📊 [INTEGRAÇÃO] ${processedPoints.length} pontos priorizados processados');
    return processedPoints;
  }

  /// Processa pontos do monitoramento (método legado)
  List<Map<String, dynamic>> _processMonitoringPoints(Monitoring monitoring) {
    final processedPoints = <Map<String, dynamic>>[];
    
    for (final point in monitoring.points) {
      for (final occurrence in point.occurrences) {
        // Criar ponto processado com dados corretos
        final processedPoint = {
          'id': point.id,
          'monitoring_id': monitoring.id,
          'talhao_id': monitoring.plotId.toString(),
          'latitude': point.latitude,
          'longitude': point.longitude,
          'accuracy': point.gpsAccuracy ?? 10.0,
          'organismo_id': occurrence.name, // Nome do organismo
          'organismo_tipo': occurrence.type.toString().split('.').last,
          'infestation_value': occurrence.infestationIndex,
          'affected_sections': occurrence.affectedSections.join(','),
          'notes': occurrence.notes ?? '',
          'collected_at': point.createdAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };
        
        processedPoints.add(processedPoint);
      }
    }
    
    Logger.info('📊 [INTEGRAÇÃO] ${processedPoints.length} pontos processados');
    return processedPoints;
  }

  /// Agrupa pontos por organismo
  Map<String, List<Map<String, dynamic>>> _groupPointsByOrganism(List<Map<String, dynamic>> points) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final point in points) {
      final organismId = point['organismo_id'] as String;
      grouped.putIfAbsent(organismId, () => []).add(point);
    }
    
    Logger.info('🔍 [INTEGRAÇÃO] Organismos encontrados: ${grouped.keys.join(', ')}');
    return grouped;
  }

  /// Processa infestação para um organismo específico
  Future<void> _processOrganismInfestation({
    required String talhaoId,
    required String organismoId,
    required List<Map<String, dynamic>> points,
    required DateTime monitoringDate,
  }) async {
    try {
      Logger.info('🧮 [INTEGRAÇÃO] Calculando infestação para organismo: $organismoId (${points.length} pontos)');
      
      // 1. Calcular estatísticas básicas
      final stats = _calculateBasicStats(points);
      
      // 2. Determinar nível de infestação
      final level = await _determineInfestationLevel(stats['avg_infestation'] as double, organismoId);
      
      // 3. Criar resumo de infestação
      final summary = InfestationSummary(
        id: '${talhaoId}_${organismoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        organismoId: organismoId,
        talhaoName: 'Talhão $talhaoId',
        organismName: organismoId,
        periodoIni: monitoringDate.subtract(const Duration(days: 1)),
        periodoFim: monitoringDate,
        avgInfestation: stats['avg_infestation'] as double,
        infestationPercentage: stats['avg_infestation'] as double,
        level: level,
        lastUpdate: DateTime.now(),
        lastMonitoringDate: monitoringDate,
        totalPoints: stats['total_points'] as int,
        pointsWithOccurrence: stats['points_with_occurrence'] as int,
      );
      
      // 4. Salvar resumo no banco
      await _infestationRepository.saveInfestationSummary(summary);
      
      // 5. Verificar se deve gerar alerta
      if (_shouldGenerateAlert(level, stats['avg_infestation'] as double)) {
        await _createInfestationAlert(
          talhaoId: talhaoId,
          organismoId: organismoId,
          level: level,
          description: 'Nível $level detectado para $organismoId (${stats['avg_infestation']}%)',
        );
      }
      
      Logger.info('✅ [INTEGRAÇÃO] Organismo processado: $organismoId | Nível: $level | Infestação: ${stats['avg_infestation']}%');
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao processar organismo $organismoId: $e');
    }
  }

  /// Calcula estatísticas básicas dos pontos
  Map<String, dynamic> _calculateBasicStats(List<Map<String, dynamic>> points) {
    try {
      if (points.isEmpty) {
      return {
          'total_points': 0,
          'points_with_occurrence': 0,
          'avg_infestation': 0.0,
          'max_infestation': 0.0,
          'min_infestation': 0.0,
        };
      }
      
      int totalPoints = points.length;
      int pointsWithOccurrence = 0;
      double totalInfestation = 0.0;
      double maxInfestation = 0.0;
      double minInfestation = 100.0;
      
      for (final point in points) {
        final infestationValue = point['infestation_value'] as double;
        
        if (infestationValue > 0) {
          pointsWithOccurrence++;
        }
        
        totalInfestation += infestationValue;
        
        if (infestationValue > maxInfestation) {
          maxInfestation = infestationValue;
        }
        
        if (infestationValue < minInfestation) {
          minInfestation = infestationValue;
        }
      }
      
      final avgInfestation = totalPoints > 0 ? totalInfestation / totalPoints : 0.0;
      
      return {
        'total_points': totalPoints,
        'points_with_occurrence': pointsWithOccurrence,
        'avg_infestation': avgInfestation,
        'max_infestation': maxInfestation,
        'min_infestation': minInfestation,
      };
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao calcular estatísticas: $e');
      return {
        'total_points': 0,
        'points_with_occurrence': 0,
        'avg_infestation': 0.0,
        'max_infestation': 0.0,
        'min_infestation': 0.0,
      };
    }
  }

  /// Determina o nível de infestação
  Future<String> _determineInfestationLevel(double pct, String organismoId) async {
    try {
      // Usar o serviço de cálculo para determinar o nível
      final level = await _calculationService.levelFromPct(pct, organismoId: organismoId);
      return level;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao determinar nível: $e');
      
      // Fallback: usar thresholds padrão
      if (pct <= 25.0) return 'BAIXO';
      if (pct <= 50.0) return 'MODERADO';
      if (pct <= 75.0) return 'ALTO';
      return 'CRITICO';
    }
  }

  /// Verifica se deve gerar alerta
  bool _shouldGenerateAlert(String level, double pct) {
    // Gerar alerta para níveis altos ou críticos
    return level == 'ALTO' || level == 'CRITICO' || pct > 50.0;
  }

  /// Cria alerta de infestação
  Future<void> _createInfestationAlert({
    required String talhaoId,
    required String organismoId,
    required String level,
    required String description,
  }) async {
    try {
      final alert = InfestationAlert(
        id: 'ALERT_${talhaoId}_${organismoId}_${DateTime.now().millisecondsSinceEpoch}',
        talhaoId: talhaoId,
        organismoId: organismoId,
        level: level,
        riskLevel: level,
        priorityScore: _calculatePriorityScore(level),
        message: 'Alerta de Infestação $level',
        description: description,
        createdAt: DateTime.now(),
      );
      
      await _infestationRepository.saveInfestationAlert(alert);
      Logger.info('🚨 [INTEGRAÇÃO] Alerta criado: $level para $organismoId');
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao criar alerta: $e');
    }
  }

  /// Calcula score de prioridade do alerta
  double _calculatePriorityScore(String level) {
    switch (level) {
      case 'CRITICO':
        return 100.0;
      case 'ALTO':
        return 75.0;
      case 'MODERADO':
        return 50.0;
      case 'BAIXO':
        return 25.0;
      default:
        return 0.0;
    }
  }

  /// Atualiza resumo geral do talhão
  Future<void> _updateTalhaoSummary(String talhaoId) async {
    try {
      Logger.info('📊 [INTEGRAÇÃO] Atualizando resumo do talhão: $talhaoId');
      
      // Buscar estatísticas do talhão
      final stats = await _infestationRepository.getTalhaoInfestationStats(talhaoId);
      
      Logger.info('✅ [INTEGRAÇÃO] Resumo do talhão atualizado: $talhaoId');
      Logger.info('   📈 Organismos: ${stats['total_organisms']}');
      Logger.info('   🚨 Alertas: ${stats['alertas_ativos']}');
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao atualizar resumo do talhão: $e');
    }
  }

  /// Obtém dados de infestação para um talhão
  Future<List<InfestationSummary>> getInfestationDataForTalhao(String talhaoId) async {
    try {
      Logger.info('🔍 [INTEGRAÇÃO] Obtendo dados de infestação para talhão: $talhaoId');
      
      final summaries = await _infestationRepository.getInfestationSummariesByTalhao(talhaoId);
      
      Logger.info('✅ [INTEGRAÇÃO] ${summaries.length} resumos encontrados para talhão: $talhaoId');
      return summaries;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao obter dados de infestação: $e');
      return [];
    }
  }

  /// Obtém alertas ativos
  Future<List<InfestationAlert>> getActiveAlerts({String? talhaoId}) async {
    try {
      final alerts = await _infestationRepository.getActiveInfestationAlerts(
        talhaoId: talhaoId,
      );
      
      Logger.info('🚨 [INTEGRAÇÃO] ${alerts.length} alertas ativos encontrados');
      return alerts;
      
    } catch (e) {
      Logger.error('❌ [INTEGRAÇÃO] Erro ao obter alertas: $e');
      return [];
    }
  }
}