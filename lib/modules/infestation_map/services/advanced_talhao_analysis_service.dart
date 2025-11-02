import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../models/monitoring_point.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';
import 'organism_catalog_integration_service.dart';
import 'hexbin_service.dart';

/// Resultado da análise avançada do talhão
class AdvancedTalhaoAnalysisResult {
  final String talhaoId;
  final double globalInfestationIndex; // Índice global do talhão (0-100)
  final String globalSeverity; // BAIXO, MÉDIO, CRÍTICO
  final String globalColorCode; // Cor para visualização
  final List<OrganismAnalysisResult> organismResults; // Análise por organismo
  final List<ThermalCluster> thermalClusters; // Clusters térmicos
  final TemporalEvolution temporalEvolution; // Evolução temporal
  final Map<String, dynamic> metadata;

  AdvancedTalhaoAnalysisResult({
    required this.talhaoId,
    required this.globalInfestationIndex,
    required this.globalSeverity,
    required this.globalColorCode,
    required this.organismResults,
    required this.thermalClusters,
    required this.temporalEvolution,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'globalInfestationIndex': globalInfestationIndex,
      'globalSeverity': globalSeverity,
      'globalColorCode': globalColorCode,
      'organismResults': organismResults.map((r) => r.toMap()).toList(),
      'thermalClusters': thermalClusters.map((c) => c.toMap()).toList(),
      'temporalEvolution': temporalEvolution.toMap(),
      'metadata': metadata,
    };
  }
}

/// Resultado da análise por organismo
class OrganismAnalysisResult {
  final String organismoId;
  final String organismoNome;
  final int totalInfestationCount; // Total de infestações (ex: 8 lagartas)
  final int totalPoints; // Total de pontos
  final int affectedPoints; // Pontos com infestação
  final double averagePerPoint; // Média por ponto
  final String severityLevel; // BAIXO, MÉDIO, CRÍTICO
  final String colorCode; // Cor específica
  final double catalogThreshold; // Limiar do catálogo
  final bool exceedsThreshold; // Se excede o limiar crítico
  final Map<String, dynamic> pointDetails; // Detalhes por ponto

  OrganismAnalysisResult({
    required this.organismoId,
    required this.organismoNome,
    required this.totalInfestationCount,
    required this.totalPoints,
    required this.affectedPoints,
    required this.averagePerPoint,
    required this.severityLevel,
    required this.colorCode,
    required this.catalogThreshold,
    required this.exceedsThreshold,
    this.pointDetails = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'organismoId': organismoId,
      'organismoNome': organismoNome,
      'totalInfestationCount': totalInfestationCount,
      'totalPoints': totalPoints,
      'affectedPoints': affectedPoints,
      'averagePerPoint': averagePerPoint,
      'severityLevel': severityLevel,
      'colorCode': colorCode,
      'catalogThreshold': catalogThreshold,
      'exceedsThreshold': exceedsThreshold,
      'pointDetails': pointDetails,
    };
  }
}

/// Cluster térmico para heatmap inteligente
class ThermalCluster {
  final String id;
  final LatLng center;
  final List<LatLng> points; // Pontos que formam o cluster
  final String severityLevel; // Severidade do cluster
  final String colorCode; // Cor do cluster
  final double thermalIntensity; // Intensidade térmica (0-1)
  final double radius; // Raio de influência em metros
  final List<String> organismIds; // Organismos presentes no cluster
  final int totalInfestationCount; // Total de infestações no cluster
  final bool isCritical; // Se é um cluster crítico
  final Map<String, dynamic> metadata;

  ThermalCluster({
    required this.id,
    required this.center,
    required this.points,
    required this.severityLevel,
    required this.colorCode,
    required this.thermalIntensity,
    required this.radius,
    required this.organismIds,
    required this.totalInfestationCount,
    required this.isCritical,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'severityLevel': severityLevel,
      'colorCode': colorCode,
      'thermalIntensity': thermalIntensity,
      'radius': radius,
      'organismIds': organismIds,
      'totalInfestationCount': totalInfestationCount,
      'isCritical': isCritical,
      'metadata': metadata,
    };
  }
}

/// Evolução temporal da infestação
class TemporalEvolution {
  final List<TemporalDataPoint> dataPoints; // Pontos temporais
  final String trend; // CRESCENTE, DECRESCENTE, ESTÁVEL
  final double trendPercentage; // Percentual de mudança
  final String recommendation; // Recomendação baseada na tendência

  TemporalEvolution({
    required this.dataPoints,
    required this.trend,
    required this.trendPercentage,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'dataPoints': dataPoints.map((d) => d.toMap()).toList(),
      'trend': trend,
      'trendPercentage': trendPercentage,
      'recommendation': recommendation,
    };
  }
}

/// Ponto de dados temporal
class TemporalDataPoint {
  final DateTime date;
  final double infestationIndex;
  final String severityLevel;

  TemporalDataPoint({
    required this.date,
    required this.infestationIndex,
    required this.severityLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'infestationIndex': infestationIndex,
      'severityLevel': severityLevel,
    };
  }
}

/// Serviço de análise avançada do talhão
class AdvancedTalhaoAnalysisService {
  final OrganismCatalogIntegrationService _organismService = OrganismCatalogIntegrationService();
  final HexbinService _hexbinService = HexbinService();

  /// Analisa talhão com as 4 melhorias implementadas
  Future<AdvancedTalhaoAnalysisResult> analyzeTalhao({
    required String talhaoId,
    required List<MonitoringPoint> monitoringPoints,
    required String cropId,
    List<TemporalDataPoint>? historicalData,
  }) async {
    try {
      Logger.info('🔬 Iniciando análise avançada do talhão $talhaoId');

      // 1. MELHORIA 1: Agregação de todos os pontos do talhão
      final organismResults = await _analyzeOrganismsByTalhao(
        monitoringPoints,
        cropId,
      );

      // 2. MELHORIA 2: Integração com catálogo de organismos
      final catalogIntegratedResults = await _integrateWithCatalog(
        organismResults,
        cropId,
      );

      // 3. MELHORIA 3: Heatmap térmico inteligente
      final thermalClusters = await _generateIntelligentHeatmap(
        monitoringPoints,
        catalogIntegratedResults,
      );

      // 4. MELHORIA 4: Índice global do talhão
      final globalIndex = _calculateGlobalTalhaoIndex(catalogIntegratedResults);
      final globalSeverity = _determineGlobalSeverity(globalIndex, catalogIntegratedResults);
      final globalColorCode = _getColorCodeForSeverity(globalSeverity);

      // 5. Evolução temporal
      final temporalEvolution = _analyzeTemporalEvolution(
        globalIndex,
        historicalData,
      );

      // 6. Metadados
      final metadata = _generateAdvancedMetadata(
        monitoringPoints,
        catalogIntegratedResults,
        thermalClusters,
      );

      final result = AdvancedTalhaoAnalysisResult(
        talhaoId: talhaoId,
        globalInfestationIndex: globalIndex,
        globalSeverity: globalSeverity,
        globalColorCode: globalColorCode,
        organismResults: catalogIntegratedResults,
        thermalClusters: thermalClusters,
        temporalEvolution: temporalEvolution,
        metadata: metadata,
      );

      Logger.info('✅ Análise avançada concluída: ${globalIndex.toStringAsFixed(1)}% - $globalSeverity');
      return result;

    } catch (e) {
      Logger.error('❌ Erro na análise avançada: $e');
      return _createEmptyResult(talhaoId);
    }
  }

  /// MELHORIA 1: Analisa organismos agregando todos os pontos do talhão
  Future<List<OrganismAnalysisResult>> _analyzeOrganismsByTalhao(
    List<MonitoringPoint> points,
    String cropId,
  ) async {
    final organismGroups = _groupPointsByOrganism(points);
    final results = <OrganismAnalysisResult>[];

    for (final entry in organismGroups.entries) {
      final organismId = entry.key;
      final organismPoints = entry.value;

      // Somar número de infestações por organismo
      int totalCount = 0;
      int affectedPoints = 0;
      final pointDetails = <String, Map<String, dynamic>>{};

      for (final point in organismPoints) {
        for (final occurrence in point.occurrences) {
          if (occurrence.name == organismId) {
            final count = _extractInfestationCount(occurrence.name, occurrence.infestationIndex);
            totalCount += count;
            affectedPoints++;

            pointDetails[point.id] = {
              'count': count,
              'infestationIndex': occurrence.infestationIndex,
              'position': {'lat': point.latitude, 'lng': point.longitude},
            };
          }
        }
      }

      final averagePerPoint = affectedPoints > 0 ? totalCount / affectedPoints : 0.0;

      results.add(OrganismAnalysisResult(
        organismoId: organismId,
        organismoNome: organismId, // Será atualizado com dados do catálogo
        totalInfestationCount: totalCount,
        totalPoints: points.length,
        affectedPoints: affectedPoints,
        averagePerPoint: averagePerPoint,
        severityLevel: 'BAIXO', // Será calculado com catálogo
        colorCode: '#4CAF50',
        catalogThreshold: 0.0, // Será obtido do catálogo
        exceedsThreshold: false, // Será calculado com catálogo
        pointDetails: pointDetails,
      ));
    }

    return results;
  }

  /// MELHORIA 2: Integra com catálogo de organismos
  Future<List<OrganismAnalysisResult>> _integrateWithCatalog(
    List<OrganismAnalysisResult> organismResults,
    String cropId,
  ) async {
    final integratedResults = <OrganismAnalysisResult>[];

    for (final result in organismResults) {
      try {
        // Obter dados do catálogo
        final catalogData = await _organismService.getOrganismData(result.organismoId, cropId);
        
        if (catalogData != null) {
          // Usar limiares específicos do catálogo
          final threshold = _extractCatalogThreshold(catalogData);
          final severityLevel = _determineSeverityFromCatalog(
            result.averagePerPoint,
            catalogData,
          );
          final colorCode = _getColorCodeFromCatalog(severityLevel, catalogData);
          final exceedsThreshold = result.averagePerPoint > threshold;

          integratedResults.add(OrganismAnalysisResult(
            organismoId: result.organismoId,
            organismoNome: catalogData['nome'] ?? result.organismoId,
            totalInfestationCount: result.totalInfestationCount,
            totalPoints: result.totalPoints,
            affectedPoints: result.affectedPoints,
            averagePerPoint: result.averagePerPoint,
            severityLevel: severityLevel,
            colorCode: colorCode,
            catalogThreshold: threshold,
            exceedsThreshold: exceedsThreshold,
            pointDetails: result.pointDetails,
          ));

          Logger.info('📊 ${result.organismoId}: ${result.averagePerPoint.toStringAsFixed(1)} vs limiar ${threshold.toStringAsFixed(1)} - $severityLevel');
        } else {
          // Usar limiares padrão se catálogo não encontrado
          integratedResults.add(result);
        }
      } catch (e) {
        Logger.warning('⚠️ Erro ao integrar com catálogo para ${result.organismoId}: $e');
        integratedResults.add(result);
      }
    }

    return integratedResults;
  }

  /// MELHORIA 3: Gera heatmap térmico inteligente
  Future<List<ThermalCluster>> _generateIntelligentHeatmap(
    List<MonitoringPoint> points,
    List<OrganismAnalysisResult> organismResults,
  ) async {
    final clusters = <ThermalCluster>[];

    // Identificar pontos críticos
    final criticalPoints = <MonitoringPoint>[];
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        final organismResult = organismResults.firstWhere(
          (r) => r.organismoId == occurrence.name,
          orElse: () => OrganismAnalysisResult(
            organismoId: occurrence.name,
            organismoNome: occurrence.name,
            totalInfestationCount: 0,
            totalPoints: 0,
            affectedPoints: 0,
            averagePerPoint: 0.0,
            severityLevel: 'BAIXO',
            colorCode: '#4CAF50',
            catalogThreshold: 0.0,
            exceedsThreshold: false,
          ),
        );

        if (organismResult.severityLevel == 'CRÍTICO' || 
            organismResult.severityLevel == 'ALTO') {
          criticalPoints.add(point);
        }
      }
    }

    // Agrupar pontos críticos em clusters
    final pointClusters = _clusterCriticalPoints(criticalPoints, 150.0); // 150 metros

    for (int i = 0; i < pointClusters.length; i++) {
      final clusterPoints = pointClusters[i];
      if (clusterPoints.length >= 2) { // Pelo menos 2 pontos para formar cluster
        final center = _calculateClusterCenter(clusterPoints);
        final severityLevel = _determineClusterSeverity(clusterPoints, organismResults);
        final thermalIntensity = _calculateThermalIntensity(clusterPoints, organismResults);
        final organismIds = _getOrganismsInCluster(clusterPoints);
        final totalCount = _calculateTotalInfestationInCluster(clusterPoints, organismResults);

        clusters.add(ThermalCluster(
          id: 'thermal_cluster_${i}_${DateTime.now().millisecondsSinceEpoch}',
          center: center,
          points: clusterPoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          severityLevel: severityLevel,
          colorCode: _getColorCodeForSeverity(severityLevel),
          thermalIntensity: thermalIntensity,
          radius: _calculateClusterRadius(clusterPoints),
          organismIds: organismIds,
          totalInfestationCount: totalCount,
          isCritical: severityLevel == 'CRÍTICO',
          metadata: {
            'cluster_size': clusterPoints.length,
            'generated_at': DateTime.now().toIso8601String(),
          },
        ));
      }
    }

    Logger.info('🔥 ${clusters.length} clusters térmicos gerados');
    return clusters;
  }

  /// MELHORIA 4: Calcula índice global do talhão
  double _calculateGlobalTalhaoIndex(List<OrganismAnalysisResult> organismResults) {
    if (organismResults.isEmpty) return 0.0;

    // Evitar distorção por apenas 1 ponto crítico
    // Usar média ponderada por número de pontos afetados
    double totalWeightedIndex = 0.0;
    double totalWeight = 0.0;

    for (final result in organismResults) {
      // Peso baseado no número de pontos afetados
      final weight = result.affectedPoints / result.totalPoints;
      
      // Converter severidade para índice numérico
      double severityIndex = 0.0;
      switch (result.severityLevel) {
        case 'BAIXO': severityIndex = 25.0; break;
        case 'MÉDIO': severityIndex = 50.0; break;
        case 'ALTO': severityIndex = 75.0; break;
        case 'CRÍTICO': severityIndex = 100.0; break;
      }

      totalWeightedIndex += severityIndex * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalWeightedIndex / totalWeight : 0.0;
  }

  /// Determina severidade global do talhão
  String _determineGlobalSeverity(
    double globalIndex,
    List<OrganismAnalysisResult> organismResults,
  ) {
    // Verificar se há organismos críticos
    final hasCritical = organismResults.any((r) => r.severityLevel == 'CRÍTICO');
    if (hasCritical) return 'CRÍTICO';

    // Usar índice global
    if (globalIndex <= 25.0) return 'BAIXO';
    if (globalIndex <= 50.0) return 'MÉDIO';
    if (globalIndex <= 75.0) return 'ALTO';
    return 'CRÍTICO';
  }

  /// Analisa evolução temporal
  TemporalEvolution _analyzeTemporalEvolution(
    double currentIndex,
    List<TemporalDataPoint>? historicalData,
  ) {
    if (historicalData == null || historicalData.length < 2) {
      return TemporalEvolution(
        dataPoints: [
          TemporalDataPoint(
            date: DateTime.now(),
            infestationIndex: currentIndex,
            severityLevel: _determineGlobalSeverity(currentIndex, []),
          ),
        ],
        trend: 'ESTÁVEL',
        trendPercentage: 0.0,
        recommendation: 'Monitoramento contínuo recomendado',
      );
    }

    // Calcular tendência
    final recent = historicalData.take(3).toList();
    final older = historicalData.skip(historicalData.length - 3).take(3).toList();

    final recentAvg = recent.fold(0.0, (sum, p) => sum + p.infestationIndex) / recent.length;
    final olderAvg = older.fold(0.0, (sum, p) => sum + p.infestationIndex) / older.length;

    final trendPercentage = olderAvg > 0 ? ((recentAvg - olderAvg) / olderAvg) * 100 : 0.0;
    
    String trend = 'ESTÁVEL';
    String recommendation = 'Monitoramento contínuo recomendado';

    if (trendPercentage > 10) {
      trend = 'CRESCENTE';
      recommendation = 'Ação imediata recomendada - infestação em crescimento';
    } else if (trendPercentage < -10) {
      trend = 'DECRESCENTE';
      recommendation = 'Controle eficaz - manter monitoramento';
    }

    return TemporalEvolution(
      dataPoints: historicalData,
      trend: trend,
      trendPercentage: trendPercentage,
      recommendation: recommendation,
    );
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Agrupa pontos por organismo
  Map<String, List<MonitoringPoint>> _groupPointsByOrganism(List<MonitoringPoint> points) {
    final groups = <String, List<MonitoringPoint>>{};
    
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        final organismId = occurrence.name;
        groups.putIfAbsent(organismId, () => []).add(point);
      }
    }
    
    return groups;
  }

  /// Extrai número da infestação
  int _extractInfestationCount(String organismName, double infestationIndex) {
    try {
      if (infestationIndex > 0 && infestationIndex < 1000) {
        return infestationIndex.round();
      }
      
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(organismName);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
      
      return infestationIndex.round().clamp(1, 100);
    } catch (e) {
      return 1;
    }
  }

  /// Extrai limiar do catálogo
  double _extractCatalogThreshold(Map<String, dynamic> catalogData) {
    try {
      // Tentar extrair de limiares específicos
      if (catalogData.containsKey('limiares_especificos')) {
        final limiares = catalogData['limiares_especificos'] as Map<String, dynamic>;
        for (final entry in limiares.entries) {
          final limite = entry.value as String;
          final numero = _extractNumberFromString(limite);
          if (numero > 0) return numero.toDouble();
        }
      }

      // Tentar extrair de severidade
      if (catalogData.containsKey('severidade')) {
        final severidade = catalogData['severidade'] as Map<String, dynamic>;
        if (severidade.containsKey('alto')) {
          final alto = severidade['alto'] as Map<String, dynamic>;
          final descricao = alto['descricao'] as String? ?? '';
          final numero = _extractNumberFromString(descricao);
          if (numero > 0) return numero.toDouble();
        }
      }

      return 5.0; // Limiar padrão
    } catch (e) {
      return 5.0;
    }
  }

  /// Extrai número de uma string
  int _extractNumberFromString(String text) {
    try {
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(text);
      return match != null ? int.parse(match.group(1)!) : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Determina severidade usando catálogo
  String _determineSeverityFromCatalog(
    double averagePerPoint,
    Map<String, dynamic> catalogData,
  ) {
    try {
      final threshold = _extractCatalogThreshold(catalogData);
      
      if (averagePerPoint <= threshold * 0.5) return 'BAIXO';
      if (averagePerPoint <= threshold) return 'MÉDIO';
      if (averagePerPoint <= threshold * 1.5) return 'ALTO';
      return 'CRÍTICO';
    } catch (e) {
      return 'BAIXO';
    }
  }

  /// Obtém cor do catálogo
  String _getColorCodeFromCatalog(String severityLevel, Map<String, dynamic> catalogData) {
    try {
      if (catalogData.containsKey('severidade')) {
        final severidade = catalogData['severidade'] as Map<String, dynamic>;
        
        switch (severityLevel) {
          case 'BAIXO':
            if (severidade.containsKey('baixo')) {
              final baixo = severidade['baixo'] as Map<String, dynamic>;
              return baixo['cor_alerta'] as String? ?? '#4CAF50';
            }
            break;
          case 'MÉDIO':
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
        }
      }
      
      return _getColorCodeForSeverity(severityLevel);
    } catch (e) {
      return _getColorCodeForSeverity(severityLevel);
    }
  }

  /// Obtém código de cor para severidade
  String _getColorCodeForSeverity(String severity) {
    switch (severity) {
      case 'BAIXO': return '#4CAF50'; // Verde
      case 'MÉDIO': return '#FF9800'; // Laranja
      case 'ALTO': return '#F44336'; // Vermelho
      case 'CRÍTICO': return '#D32F2F'; // Vermelho escuro
      default: return '#9E9E9E'; // Cinza
    }
  }

  /// Agrupa pontos críticos em clusters
  List<List<MonitoringPoint>> _clusterCriticalPoints(
    List<MonitoringPoint> points,
    double maxDistance,
  ) {
    final clusters = <List<MonitoringPoint>>[];
    final used = <int>{};

    for (int i = 0; i < points.length; i++) {
      if (used.contains(i)) continue;

      final cluster = <MonitoringPoint>[points[i]];
      used.add(i);

      for (int j = i + 1; j < points.length; j++) {
        if (used.contains(j)) continue;

        final distance = _calculateDistance(
          points[i].latitude, points[i].longitude,
          points[j].latitude, points[j].longitude,
        );

        if (distance <= maxDistance) {
          cluster.add(points[j]);
          used.add(j);
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  /// Calcula centro do cluster
  LatLng _calculateClusterCenter(List<MonitoringPoint> points) {
    double totalLat = 0.0;
    double totalLng = 0.0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  /// Determina severidade do cluster
  String _determineClusterSeverity(
    List<MonitoringPoint> points,
    List<OrganismAnalysisResult> organismResults,
  ) {
    int criticalCount = 0;
    int highCount = 0;

    for (final point in points) {
      for (final occurrence in point.occurrences) {
        final organismResult = organismResults.firstWhere(
          (r) => r.organismoId == occurrence.name,
          orElse: () => OrganismAnalysisResult(
            organismoId: occurrence.name,
            organismoNome: occurrence.name,
            totalInfestationCount: 0,
            totalPoints: 0,
            affectedPoints: 0,
            averagePerPoint: 0.0,
            severityLevel: 'BAIXO',
            colorCode: '#4CAF50',
            catalogThreshold: 0.0,
            exceedsThreshold: false,
          ),
        );

        if (organismResult.severityLevel == 'CRÍTICO') criticalCount++;
        if (organismResult.severityLevel == 'ALTO') highCount++;
      }
    }

    if (criticalCount > 0) return 'CRÍTICO';
    if (highCount > 0) return 'ALTO';
    return 'MÉDIO';
  }

  /// Calcula intensidade térmica
  double _calculateThermalIntensity(
    List<MonitoringPoint> points,
    List<OrganismAnalysisResult> organismResults,
  ) {
    double totalIntensity = 0.0;
    int count = 0;

    for (final point in points) {
      for (final occurrence in point.occurrences) {
        final organismResult = organismResults.firstWhere(
          (r) => r.organismoId == occurrence.name,
          orElse: () => OrganismAnalysisResult(
            organismoId: occurrence.name,
            organismoNome: occurrence.name,
            totalInfestationCount: 0,
            totalPoints: 0,
            affectedPoints: 0,
            averagePerPoint: 0.0,
            severityLevel: 'BAIXO',
            colorCode: '#4CAF50',
            catalogThreshold: 0.0,
            exceedsThreshold: false,
          ),
        );

        double intensity = 0.0;
        switch (organismResult.severityLevel) {
          case 'BAIXO': intensity = 0.25; break;
          case 'MÉDIO': intensity = 0.5; break;
          case 'ALTO': intensity = 0.75; break;
          case 'CRÍTICO': intensity = 1.0; break;
        }

        totalIntensity += intensity;
        count++;
      }
    }

    return count > 0 ? totalIntensity / count : 0.0;
  }

  /// Obtém organismos no cluster
  List<String> _getOrganismsInCluster(List<MonitoringPoint> points) {
    final organisms = <String>{};
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        organisms.add(occurrence.name);
      }
    }
    return organisms.toList();
  }

  /// Calcula total de infestação no cluster
  int _calculateTotalInfestationInCluster(
    List<MonitoringPoint> points,
    List<OrganismAnalysisResult> organismResults,
  ) {
    int total = 0;
    for (final point in points) {
      for (final occurrence in point.occurrences) {
        total += _extractInfestationCount(occurrence.name, occurrence.infestationIndex);
      }
    }
    return total;
  }

  /// Calcula raio do cluster
  double _calculateClusterRadius(List<MonitoringPoint> points) {
    if (points.length <= 1) return 50.0;

    final center = _calculateClusterCenter(points);
    double maxDistance = 0.0;

    for (final point in points) {
      final distance = _calculateDistance(
        center.latitude, center.longitude,
        point.latitude, point.longitude,
      );
      maxDistance = max(maxDistance, distance);
    }

    return maxDistance;
  }

  /// Calcula distância entre coordenadas
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
               sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Gera metadados avançados
  Map<String, dynamic> _generateAdvancedMetadata(
    List<MonitoringPoint> points,
    List<OrganismAnalysisResult> organismResults,
    List<ThermalCluster> thermalClusters,
  ) {
    return {
      'analysis_date': DateTime.now().toIso8601String(),
      'total_points': points.length,
      'total_organisms': organismResults.length,
      'critical_organisms': organismResults.where((r) => r.severityLevel == 'CRÍTICO').length,
      'thermal_clusters': thermalClusters.length,
      'critical_clusters': thermalClusters.where((c) => c.isCritical).length,
      'total_infestation_count': organismResults.fold<int>(0, (sum, r) => sum + r.totalInfestationCount),
      'analysis_version': '2.0',
    };
  }

  /// Cria resultado vazio
  AdvancedTalhaoAnalysisResult _createEmptyResult(String talhaoId) {
    return AdvancedTalhaoAnalysisResult(
      talhaoId: talhaoId,
      globalInfestationIndex: 0.0,
      globalSeverity: 'BAIXO',
      globalColorCode: '#4CAF50',
      organismResults: [],
      thermalClusters: [],
      temporalEvolution: TemporalEvolution(
        dataPoints: [],
        trend: 'ESTÁVEL',
        trendPercentage: 0.0,
        recommendation: 'Dados insuficientes para análise',
      ),
      metadata: {
        'analysis_date': DateTime.now().toIso8601String(),
        'status': 'no_data',
      },
    );
  }
}
