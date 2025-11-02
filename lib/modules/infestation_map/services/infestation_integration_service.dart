import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../../../models/monitoring_point.dart';
import 'infestation_calculation_service.dart';
import 'talhao_integration_service.dart';
import 'hexbin_service.dart';

/// Serviço para integração entre monitoramento e infestação
class InfestationIntegrationService {
  static final InfestationIntegrationService _instance = 
      InfestationIntegrationService._internal();
  
  factory InfestationIntegrationService() => _instance;
  
  InfestationIntegrationService._internal();

  // Serviços privados
  final InfestationCalculationService _calculationService = InfestationCalculationService();
  final HexbinService _hexbinService = HexbinService();
  final TalhaoIntegrationService _talhaoService = TalhaoIntegrationService();

  /// Processa dados de monitoramento para gerar resumos de infestação
  Future<void> processMonitoringForInfestation({
    required String monitoringId,
    required String talhaoId,
    required List<Map<String, dynamic>> monitoringPoints,
    required DateTime monitoringDate,
    required Map<String, double> organismRiskWeights,
  }) async {
    try {
      if (monitoringPoints.isEmpty) return;

      // Agrupar pontos por organismo
      final pointsByOrganism = <String, List<Map<String, dynamic>>>{};
      
      for (final point in monitoringPoints) {
        final organismoId = point['organismo_id'] as String;
        pointsByOrganism.putIfAbsent(organismoId, () => []).add(point);
      }

      // Processar cada organismo
      for (final entry in pointsByOrganism.entries) {
        final organismoId = entry.key;
        final points = entry.value;
        final riskWeight = organismRiskWeights[organismoId] ?? 1.0;

        await _processOrganismInfestation(
          talhaoId: talhaoId,
          organismoId: organismoId,
          points: points,
          monitoringDate: monitoringDate,
          riskWeight: riskWeight,
        );
      }

      // Atualizar resumo geral do talhão
      await _updateTalhaoSummary(talhaoId);
      
    } catch (e) {
      // Em produção, usar sistema de logging apropriado
      print('Erro ao processar monitoramento para infestação: $e');
      rethrow;
    }
  }

  /// Processa infestação para um organismo específico
  Future<void> _processOrganismInfestation({
    required String talhaoId,
    required String organismoId,
    required List<Map<String, dynamic>> points,
    required DateTime monitoringDate,
    required double riskWeight,
  }) async {
    // Calcular score composto (simplificado)
    final compositeScore = _calculateSimpleScore(points, monitoringDate);

    // Determinar nível
    final level = await _calculationService.levelFromPct(compositeScore, organismoId: organismoId);
    
    // Calcular estatísticas
    final stats = _calculationService.calculateAggregateStats(_convertToMonitoringPoints(points));

    // Gerar dados de heatmap
    final heatmapData = await _hexbinService.generateHexbinData(
      _convertToMonitoringPoints(points),
      polygonBounds: _extractPolygonBounds(points),
      hexSize: 50.0, // 50 metros por hexágono
    );

    // Criar ou atualizar resumo
    final summary = InfestationSummary(
      id: const Uuid().v4(),
      talhaoId: talhaoId,
      organismoId: organismoId,
      periodoIni: monitoringDate.subtract(const Duration(days: 7)),
      periodoFim: monitoringDate,
      avgInfestation: compositeScore,
      infestationPercentage: compositeScore,
      level: level,
      lastUpdate: DateTime.now(),
      heatGeoJson: jsonEncode(heatmapData),
      totalPoints: stats['total_points'] as int,
      pointsWithOccurrence: stats['points_with_occurrence'] as int,
    );

    // Salvar resumo (implementar repositório)
    await _saveInfestationSummary(summary);

    // Verificar se deve gerar alerta
    if (_shouldGenerateAlert(
      level: level,
      percentage: compositeScore,
      organismRiskWeight: riskWeight,
    )) {
      await _createInfestationAlert(
        talhaoId: talhaoId,
        organismoId: organismoId,
        level: level,
        description: _generateAlertDescription(level, compositeScore, organismoId),
      );
    }
  }

  /// Extrai os limites do polígono dos pontos
  List<LatLng> _extractPolygonBounds(List<Map<String, dynamic>> points) {
    if (points.isEmpty) {
      return [];
    }
    
    return points.map((point) {
      final lat = (point['lat'] as num).toDouble();
      final lon = (point['lon'] as num).toDouble();
      return LatLng(lat, lon);
    }).toList();
  }

  /// Calcula o bounding box dos pontos
  Map<String, dynamic> _calculateBoundingBox(List<Map<String, dynamic>> points) {
    if (points.isEmpty) {
      return {
        'min_lat': 0.0,
        'max_lat': 0.0,
        'min_lon': 0.0,
        'max_lon': 0.0,
      };
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final point in points) {
      final lat = (point['lat'] as num).toDouble();
      final lon = (point['lon'] as num).toDouble();

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;
    }

    return {
      'min_lat': minLat,
      'max_lat': maxLat,
      'min_lon': minLon,
      'max_lon': maxLon,
    };
  }

  /// Gera descrição do alerta
  String _generateAlertDescription(
    String level,
    double percentage,
    String organismoId,
  ) {
    return 'Nível $level detectado para organismo $organismoId '
           '(${percentage.toStringAsFixed(1)}%)';
  }

  /// Calcula score simples baseado nos pontos
  double _calculateSimpleScore(List<Map<String, dynamic>> points, DateTime referenceDate) {
    if (points.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int validPoints = 0;
    
    for (final point in points) {
      final infestationValue = point['infestation_value'] as double? ?? 0.0;
      final accuracy = point['accuracy'] as double? ?? 10.0;
      final daysDiff = DateTime.now().difference(referenceDate).inDays;
      
      // Peso baseado na precisão GPS
      final accuracyWeight = (accuracy <= 5.0) ? 1.0 : (accuracy <= 10.0) ? 0.8 : 0.6;
      
      // Decay temporal
      final timeWeight = exp(-daysDiff / 14.0); // 14 dias de meia-vida
      
      totalScore += infestationValue * accuracyWeight * timeWeight;
      validPoints++;
    }
    
    return validPoints > 0 ? (totalScore / validPoints) : 0.0;
  }

  /// Converte pontos para MonitoringPoint
  List<MonitoringPoint> _convertToMonitoringPoints(List<Map<String, dynamic>> points) {
    return points.map((point) => MonitoringPoint(
      id: point['id'] as String? ?? const Uuid().v4(),
      monitoringId: point['monitoring_id'] as String? ?? '',
      plotId: 0, // Placeholder - deve ser fornecido pelo contexto
      plotName: 'Talhão', // Placeholder - deve ser fornecido pelo contexto
      latitude: point['lat'] as double? ?? 0.0,
      longitude: point['lon'] as double? ?? 0.0,
      gpsAccuracy: point['accuracy'] as double? ?? 10.0,
      observations: point['observations'] as String? ?? '',
      occurrences: [], // Placeholder
    )).toList();
  }

  /// Verifica se deve gerar alerta
  bool _shouldGenerateAlert({
    required String level,
    required double percentage,
    required double organismRiskWeight,
  }) {
    // Lógica simples: gerar alerta para níveis altos ou críticos
    return level == 'ALTO' || level == 'CRITICO' || percentage > 50.0;
  }

  /// Salva resumo de infestação
  Future<void> _saveInfestationSummary(InfestationSummary summary) async {
    try {
      final repository = InfestationRepository();
      await repository.saveInfestationSummary(summary);
    } catch (e) {
      print('Erro ao salvar resumo de infestação: $e');
      rethrow;
    }
  }

  /// Cria alerta de infestação
  Future<void> _createInfestationAlert({
    required String talhaoId,
    required String organismoId,
    required String level,
    required String description,
  }) async {
    final alert = InfestationAlert(
      id: const Uuid().v4(),
      talhaoId: talhaoId,
      organismoId: organismoId,
      level: level,
      riskLevel: level,
      priorityScore: 0.0,
      message: description,
      description: description,
      origin: 'auto',
      createdAt: DateTime.now(),
    );

    try {
      final repository = InfestationRepository();
      await repository.saveInfestationAlert(alert);
    } catch (e) {
      print('Erro ao criar alerta de infestação: $e');
      rethrow;
    }
  }

  /// Atualiza resumo geral do talhão
  Future<void> _updateTalhaoSummary(String talhaoId) async {
    // TODO: Implementar atualização do resumo do talhão
    // await _talhaoRepository.updateInfestationSummary(talhaoId);
    print('Atualizando resumo do talhão: $talhaoId');
  }

  /// Obtém estatísticas de infestação para um talhão
  Future<Map<String, dynamic>> getTalhaoInfestationStats(String talhaoId) async {
    try {
      final repository = InfestationRepository();
      return await repository.getTalhaoInfestationStats(talhaoId);
    } catch (e) {
      print('Erro ao obter estatísticas do talhão: $e');
      rethrow;
    }
  }

  /// Reconhece um alerta
  Future<void> acknowledgeAlert(String alertId, String userId) async {
    try {
      final repository = InfestationRepository();
      await repository.acknowledgeAlert(alertId, userId);
    } catch (e) {
      print('Erro ao reconhecer alerta: $e');
      rethrow;
    }
  }
}
