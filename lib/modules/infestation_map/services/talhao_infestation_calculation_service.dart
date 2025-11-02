import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../models/monitoring_point.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';
import 'organism_catalog_integration_service.dart';
import 'hexbin_service.dart';

/// Resultado do cálculo de infestação por talhão
class TalhaoInfestationResult {
  final String talhaoId;
  final String organismoId;
  final double infestationPercentage; // 0-100% do talhão afetado
  final String severityLevel; // BAIXO, MODERADO, ALTO, CRÍTICO
  final String colorCode; // Código da cor para visualização
  final int totalPoints;
  final int affectedPoints;
  final double averageInfestationIndex;
  final Map<String, dynamic> metadata;

  TalhaoInfestationResult({
    required this.talhaoId,
    required this.organismoId,
    required this.infestationPercentage,
    required this.severityLevel,
    required this.colorCode,
    required this.totalPoints,
    required this.affectedPoints,
    required this.averageInfestationIndex,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'organismoId': organismoId,
      'infestationPercentage': infestationPercentage,
      'severityLevel': severityLevel,
      'colorCode': colorCode,
      'totalPoints': totalPoints,
      'affectedPoints': affectedPoints,
      'averageInfestationIndex': averageInfestationIndex,
      'metadata': metadata,
    };
  }
}

/// Serviço para cálculo de infestação por talhão usando novos dados do catálogo
class TalhaoInfestationCalculationService {
  final OrganismCatalogIntegrationService _organismService = OrganismCatalogIntegrationService();
  final HexbinService _hexbinService = HexbinService();

  /// Calcula infestação por talhão baseado em pontos de monitoramento
  Future<TalhaoInfestationResult> calculateTalhaoInfestation({
    required String talhaoId,
    required String organismoId,
    required List<MonitoringPoint> monitoringPoints,
    required List<LatLng> talhaoPolygon,
    required String cropId,
  }) async {
    try {
      Logger.info('🧮 Calculando infestação do talhão $talhaoId para organismo $organismoId');

      // 1. Filtrar pontos que contêm o organismo específico
      final relevantPoints = _filterPointsByOrganism(monitoringPoints, organismoId);
      
      if (relevantPoints.isEmpty) {
        Logger.warning('⚠️ Nenhum ponto relevante encontrado para organismo $organismoId');
        return _createEmptyResult(talhaoId, organismoId);
      }

      // 2. Obter dados do catálogo de organismos
      final organismData = await _organismService.getOrganismData(organismoId, cropId);
      if (organismData == null) {
        Logger.warning('⚠️ Dados do organismo $organismoId não encontrados no catálogo');
        return _createEmptyResult(talhaoId, organismoId);
      }

      // 3. Calcular estatísticas dos pontos
      final stats = _calculatePointStatistics(relevantPoints, organismoId);
      
      // 4. Calcular porcentagem do talhão afetado
      final infestationPercentage = await _calculateTalhaoInfestationPercentage(
        relevantPoints,
        talhaoPolygon,
        organismData,
      );

      // 5. Determinar nível de severidade usando novos dados do catálogo
      final severityLevel = await _determineSeverityLevel(
        infestationPercentage,
        organismData,
        stats.averageInfestationIndex,
      );

      // 6. Obter cor correspondente ao nível
      final colorCode = _getColorCodeForSeverity(severityLevel, organismData);

      // 7. Gerar metadados
      final metadata = _generateMetadata(relevantPoints, organismData, stats);

      final result = TalhaoInfestationResult(
        talhaoId: talhaoId,
        organismoId: organismoId,
        infestationPercentage: infestationPercentage,
        severityLevel: severityLevel,
        colorCode: colorCode,
        totalPoints: monitoringPoints.length,
        affectedPoints: relevantPoints.length,
        averageInfestationIndex: stats.averageInfestationIndex,
        metadata: metadata,
      );

      Logger.info('✅ Infestação calculada: ${infestationPercentage.toStringAsFixed(1)}% - $severityLevel');
      return result;

    } catch (e) {
      Logger.error('❌ Erro ao calcular infestação do talhão: $e');
      return _createEmptyResult(talhaoId, organismoId);
    }
  }

  /// Filtra pontos que contêm o organismo específico
  List<MonitoringPoint> _filterPointsByOrganism(
    List<MonitoringPoint> points,
    String organismoId,
  ) {
    return points.where((point) {
      return point.occurrences.any((occurrence) => 
        occurrence.name.toLowerCase().contains(organismoId.toLowerCase()) ||
        organismoId.toLowerCase().contains(occurrence.name.toLowerCase())
      );
    }).toList();
  }

  /// Calcula estatísticas dos pontos de monitoramento
  PointStatistics _calculatePointStatistics(
    List<MonitoringPoint> points,
    String organismoId,
  ) {
    double totalInfestation = 0.0;
    int validPoints = 0;
    double maxInfestation = 0.0;
    double minInfestation = double.infinity;

    for (final point in points) {
      for (final occurrence in point.occurrences) {
        if (occurrence.name.toLowerCase().contains(organismoId.toLowerCase()) ||
            organismoId.toLowerCase().contains(occurrence.name.toLowerCase())) {
          totalInfestation += occurrence.infestationIndex;
          validPoints++;
          maxInfestation = max(maxInfestation, occurrence.infestationIndex);
          minInfestation = min(minInfestation, occurrence.infestationIndex);
        }
      }
    }

    return PointStatistics(
      totalPoints: points.length,
      validPoints: validPoints,
      averageInfestationIndex: validPoints > 0 ? totalInfestation / validPoints : 0.0,
      maxInfestationIndex: maxInfestation,
      minInfestationIndex: minInfestation == double.infinity ? 0.0 : minInfestation,
    );
  }

  /// Calcula porcentagem do talhão afetado
  Future<double> _calculateTalhaoInfestationPercentage(
    List<MonitoringPoint> points,
    List<LatLng> talhaoPolygon,
    Map<String, dynamic> organismData,
  ) async {
    try {
      // 1. Calcular área total do talhão
      final talhaoArea = _calculatePolygonArea(talhaoPolygon);
      
      // 2. Calcular área de influência dos pontos afetados
      final affectedArea = await _calculateAffectedArea(points, talhaoPolygon);
      
      // 3. Calcular porcentagem
      final percentage = talhaoArea > 0 ? (affectedArea / talhaoArea) * 100.0 : 0.0;
      
      // 4. Aplicar peso baseado na severidade média
      final averageSeverity = _calculateAverageSeverity(points);
      final weightedPercentage = percentage * (averageSeverity / 100.0);
      
      return weightedPercentage.clamp(0.0, 100.0);
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular porcentagem do talhão: $e');
      return 0.0;
    }
  }

  /// Calcula área de um polígono usando fórmula de Shoelace
  double _calculatePolygonArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      final j = (i + 1) % polygon.length;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para metros quadrados (aproximado)
    const double earthRadius = 6371000.0;
    return area * earthRadius * earthRadius;
  }

  /// Calcula área afetada pelos pontos de monitoramento
  Future<double> _calculateAffectedArea(
    List<MonitoringPoint> points,
    List<LatLng> talhaoPolygon,
  ) async {
    if (points.isEmpty) return 0.0;
    
    // Usar hexágonos para calcular área afetada
    final hexbinData = _hexbinService.generateHexbinData(
      points,
      polygonBounds: talhaoPolygon,
      hexSize: 50.0,
    );
    
    // Calcular área total dos hexágonos com infestação
    double totalAffectedArea = 0.0;
    final hexbinList = await hexbinData;
    for (final hexbin in hexbinList) {
      if (hexbin.infestationValue > 0) {
        // Área aproximada de um hexágono
        final hexArea = _calculateHexagonArea(hexbin.vertices);
        totalAffectedArea += hexArea;
      }
    }
    
    return totalAffectedArea;
  }

  /// Calcula área de um hexágono
  double _calculateHexagonArea(List<LatLng> vertices) {
    if (vertices.length != 6) return 0.0;
    
    // Usar fórmula de Shoelace para hexágono
    double area = 0.0;
    for (int i = 0; i < 6; i++) {
      final j = (i + 1) % 6;
      area += vertices[i].longitude * vertices[j].latitude;
      area -= vertices[j].longitude * vertices[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para metros quadrados
    const double earthRadius = 6371000.0;
    return area * earthRadius * earthRadius;
  }

  /// Calcula severidade média dos pontos
  double _calculateAverageSeverity(List<MonitoringPoint> points) {
    if (points.isEmpty) return 0.0;
    
    double totalSeverity = 0.0;
    int count = 0;
    
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        totalSeverity += occurrence.infestationIndex;
        count++;
      }
    }
    
    return count > 0 ? totalSeverity / count : 0.0;
  }

  /// Determina nível de severidade usando novos dados do catálogo
  Future<String> _determineSeverityLevel(
    double infestationPercentage,
    Map<String, dynamic> organismData,
    double averageInfestationIndex,
  ) async {
    try {
      // Usar dados de severidade do catálogo se disponível
      if (organismData.containsKey('severidade')) {
        final severidade = organismData['severidade'] as Map<String, dynamic>;
        
        // Verificar limiares específicos
        if (severidade.containsKey('baixo')) {
          final baixo = severidade['baixo'] as Map<String, dynamic>;
          if (infestationPercentage <= 5.0 && averageInfestationIndex <= 25.0) {
            return 'BAIXO';
          }
        }
        
        if (severidade.containsKey('medio')) {
          final medio = severidade['medio'] as Map<String, dynamic>;
          if (infestationPercentage <= 20.0 && averageInfestationIndex <= 50.0) {
            return 'MODERADO';
          }
        }
        
        if (severidade.containsKey('alto')) {
          final alto = severidade['alto'] as Map<String, dynamic>;
          if (infestationPercentage <= 50.0 && averageInfestationIndex <= 75.0) {
            return 'ALTO';
          }
        }
        
        return 'CRÍTICO';
      }
      
      // Fallback para limiares padrão
      if (infestationPercentage <= 5.0) return 'BAIXO';
      if (infestationPercentage <= 20.0) return 'MODERADO';
      if (infestationPercentage <= 50.0) return 'ALTO';
      return 'CRÍTICO';
      
    } catch (e) {
      Logger.error('❌ Erro ao determinar nível de severidade: $e');
      return 'DESCONHECIDO';
    }
  }

  /// Obtém código de cor baseado no nível de severidade
  String _getColorCodeForSeverity(
    String severityLevel,
    Map<String, dynamic> organismData,
  ) {
    try {
      // Usar cores do catálogo se disponível
      if (organismData.containsKey('severidade')) {
        final severidade = organismData['severidade'] as Map<String, dynamic>;
        
        switch (severityLevel) {
          case 'BAIXO':
            if (severidade.containsKey('baixo')) {
              final baixo = severidade['baixo'] as Map<String, dynamic>;
              return baixo['cor_alerta'] as String? ?? '#4CAF50';
            }
            break;
          case 'MODERADO':
            if (severidade.containsKey('medio')) {
              final medio = severidade['medio'] as Map<String, dynamic>;
              return medio['cor_alerta'] as String? ?? '#FF9800';
            }
            break;
          case 'ALTO':
            if (severidade.containsKey('alto')) {
              final alto = severidade['alto'] as Map<String, dynamic>;
              return alto['cor_alerta'] as String? ?? '#F44336';
            }
            break;
          case 'CRÍTICO':
            return '#D32F2F'; // Vermelho escuro para crítico
        }
      }
      
      // Cores padrão
      switch (severityLevel) {
        case 'BAIXO': return '#4CAF50'; // Verde
        case 'MODERADO': return '#FF9800'; // Laranja
        case 'ALTO': return '#F44336'; // Vermelho
        case 'CRÍTICO': return '#D32F2F'; // Vermelho escuro
        default: return '#9E9E9E'; // Cinza
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao obter cor: $e');
      return '#9E9E9E';
    }
  }

  /// Gera metadados do cálculo
  Map<String, dynamic> _generateMetadata(
    List<MonitoringPoint> points,
    Map<String, dynamic> organismData,
    PointStatistics stats,
  ) {
    return {
      'calculation_date': DateTime.now().toIso8601String(),
      'organism_data_version': organismData['versao'] ?? '1.0',
      'points_analyzed': points.length,
      'statistics': {
        'average_infestation': stats.averageInfestationIndex,
        'max_infestation': stats.maxInfestationIndex,
        'min_infestation': stats.minInfestationIndex,
        'valid_points': stats.validPoints,
      },
      'organism_info': {
        'name': organismData['nome'] ?? 'Desconhecido',
        'scientific_name': organismData['nome_cientifico'] ?? '',
        'category': organismData['categoria'] ?? 'Desconhecido',
      },
    };
  }

  /// Cria resultado vazio
  TalhaoInfestationResult _createEmptyResult(String talhaoId, String organismoId) {
    return TalhaoInfestationResult(
      talhaoId: talhaoId,
      organismoId: organismoId,
      infestationPercentage: 0.0,
      severityLevel: 'BAIXO',
      colorCode: '#4CAF50',
      totalPoints: 0,
      affectedPoints: 0,
      averageInfestationIndex: 0.0,
      metadata: {
        'calculation_date': DateTime.now().toIso8601String(),
        'status': 'no_data',
      },
    );
  }
}

/// Estatísticas dos pontos de monitoramento
class PointStatistics {
  final int totalPoints;
  final int validPoints;
  final double averageInfestationIndex;
  final double maxInfestationIndex;
  final double minInfestationIndex;

  PointStatistics({
    required this.totalPoints,
    required this.validPoints,
    required this.averageInfestationIndex,
    required this.maxInfestationIndex,
    required this.minInfestationIndex,
  });
}
