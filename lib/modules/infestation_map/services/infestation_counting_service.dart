import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../models/monitoring_point.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';
import 'organism_catalog_integration_service.dart';
import 'hexbin_service.dart';

/// Resultado da contagem de infestação por organismo
class InfestationCountResult {
  final String organismoId;
  final String organismoNome;
  final int totalCount; // Total de números contados (ex: 15 lagartas)
  final int totalPoints; // Total de pontos monitorados
  final int affectedPoints; // Pontos com infestação
  final double averagePerPoint; // Média por ponto
  final String severityLevel; // BAIXO, MÉDIO, CRÍTICO
  final String colorCode; // Cor para visualização
  final Map<String, dynamic> details; // Detalhes por ponto

  InfestationCountResult({
    required this.organismoId,
    required this.organismoNome,
    required this.totalCount,
    required this.totalPoints,
    required this.affectedPoints,
    required this.averagePerPoint,
    required this.severityLevel,
    required this.colorCode,
    this.details = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'organismoId': organismoId,
      'organismoNome': organismoNome,
      'totalCount': totalCount,
      'totalPoints': totalPoints,
      'affectedPoints': affectedPoints,
      'averagePerPoint': averagePerPoint,
      'severityLevel': severityLevel,
      'colorCode': colorCode,
      'details': details,
    };
  }
}

/// Resultado do cálculo de percentual médio do talhão
class TalhaoAverageResult {
  final String talhaoId;
  final double averagePercentage; // Percentual médio do talhão
  final String overallSeverity; // Severidade geral
  final String colorCode; // Cor geral
  final List<InfestationCountResult> organismResults; // Resultados por organismo
  final List<CriticalSequentialPoint> criticalSequentialPoints; // Pontos críticos sequenciais
  final Map<String, dynamic> metadata;

  TalhaoAverageResult({
    required this.talhaoId,
    required this.averagePercentage,
    required this.overallSeverity,
    required this.colorCode,
    required this.organismResults,
    required this.criticalSequentialPoints,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'averagePercentage': averagePercentage,
      'overallSeverity': overallSeverity,
      'colorCode': colorCode,
      'organismResults': organismResults.map((r) => r.toMap()).toList(),
      'criticalSequentialPoints': criticalSequentialPoints.map((p) => p.toMap()).toList(),
      'metadata': metadata,
    };
  }
}

/// Ponto crítico sequencial para heatmap térmico
class CriticalSequentialPoint {
  final String id;
  final LatLng position;
  final String organismoId;
  final int infestationCount;
  final String severityLevel;
  final String colorCode;
  final double thermalIntensity; // Intensidade térmica (0-1)
  final List<LatLng> nearbyPoints; // Pontos próximos críticos

  CriticalSequentialPoint({
    required this.id,
    required this.position,
    required this.organismoId,
    required this.infestationCount,
    required this.severityLevel,
    required this.colorCode,
    required this.thermalIntensity,
    this.nearbyPoints = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'position': {'lat': position.latitude, 'lng': position.longitude},
      'organismoId': organismoId,
      'infestationCount': infestationCount,
      'severityLevel': severityLevel,
      'colorCode': colorCode,
      'thermalIntensity': thermalIntensity,
      'nearbyPoints': nearbyPoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };
  }
}

/// Serviço para contagem de números de infestação e geração de heatmaps térmicos
class InfestationCountingService {
  final OrganismCatalogIntegrationService _organismService = OrganismCatalogIntegrationService();
  final HexbinService _hexbinService = HexbinService();

  /// Conta números de infestação por organismo e calcula percentual médio do talhão
  Future<TalhaoAverageResult> countInfestationAndCalculateAverage({
    required String talhaoId,
    required List<MonitoringPoint> monitoringPoints,
    required String cropId,
  }) async {
    try {
      Logger.info('🔢 Contando infestação para talhão $talhaoId com ${monitoringPoints.length} pontos');

      // 1. Agrupar pontos por organismo
      final organismGroups = _groupPointsByOrganism(monitoringPoints);
      
      // 2. Contar números para cada organismo
      final organismResults = <InfestationCountResult>[];
      for (final entry in organismGroups.entries) {
        final organismId = entry.key;
        final points = entry.value;
        
        final countResult = await _countOrganismInfestation(
          organismId: organismId,
          points: points,
          cropId: cropId,
        );
        
        organismResults.add(countResult);
      }

      // 3. Calcular percentual médio do talhão
      final averagePercentage = _calculateTalhaoAveragePercentage(organismResults);
      
      // 4. Determinar severidade geral
      final overallSeverity = _determineOverallSeverity(averagePercentage, organismResults);
      
      // 5. Obter cor geral
      final colorCode = _getColorCodeForSeverity(overallSeverity);
      
      // 6. Identificar pontos críticos sequenciais
      final criticalSequentialPoints = _identifyCriticalSequentialPoints(
        monitoringPoints,
        organismResults,
      );

      // 7. Gerar metadados
      final metadata = _generateMetadata(monitoringPoints, organismResults);

      final result = TalhaoAverageResult(
        talhaoId: talhaoId,
        averagePercentage: averagePercentage,
        overallSeverity: overallSeverity,
        colorCode: colorCode,
        organismResults: organismResults,
        criticalSequentialPoints: criticalSequentialPoints,
        metadata: metadata,
      );

      Logger.info('✅ Talhão $talhaoId: ${averagePercentage.toStringAsFixed(1)}% - $overallSeverity');
      return result;

    } catch (e) {
      Logger.error('❌ Erro ao contar infestação: $e');
      return _createEmptyResult(talhaoId);
    }
  }

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

  /// Conta infestação para um organismo específico
  Future<InfestationCountResult> _countOrganismInfestation({
    required String organismId,
    required List<MonitoringPoint> points,
    required String cropId,
  }) async {
    try {
      // 1. Obter dados do catálogo
      final organismData = await _organismService.getOrganismData(organismId, cropId);
      
      // 2. Contar números de infestação
      int totalCount = 0;
      int affectedPoints = 0;
      final pointDetails = <String, Map<String, dynamic>>{};
      
      for (final point in points) {
        for (final occurrence in point.occurrences) {
          if (occurrence.name == organismId) {
            // Extrair número da infestação (ex: "3 lagartas" -> 3)
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

      // 3. Calcular média por ponto
      final averagePerPoint = affectedPoints > 0 ? totalCount / affectedPoints : 0.0;
      
      // 4. Determinar nível de severidade
      final severityLevel = await _determineOrganismSeverity(
        totalCount,
        averagePerPoint,
        organismData,
      );
      
      // 5. Obter cor
      final colorCode = _getColorCodeForSeverity(severityLevel);

      return InfestationCountResult(
        organismoId: organismId,
        organismoNome: organismData?['nome'] ?? organismId,
        totalCount: totalCount,
        totalPoints: points.length,
        affectedPoints: affectedPoints,
        averagePerPoint: averagePerPoint,
        severityLevel: severityLevel,
        colorCode: colorCode,
        details: pointDetails,
      );

    } catch (e) {
      Logger.error('❌ Erro ao contar organismo $organismId: $e');
      return _createEmptyOrganismResult(organismId);
    }
  }

  /// Extrai número da infestação do nome e índice
  int _extractInfestationCount(String organismName, double infestationIndex) {
    try {
      // Se o índice já representa um número (ex: 3.0), usar diretamente
      if (infestationIndex > 0 && infestationIndex < 1000) {
        return infestationIndex.round();
      }
      
      // Tentar extrair número do nome (ex: "3 lagartas", "5 percevejos")
      final regex = RegExp(r'(\d+)');
      final match = regex.firstMatch(organismName);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
      
      // Fallback: usar índice como número
      return infestationIndex.round().clamp(1, 100);
      
    } catch (e) {
      Logger.error('❌ Erro ao extrair contagem: $e');
      return 1;
    }
  }

  /// Determina severidade do organismo baseado na contagem
  Future<String> _determineOrganismSeverity(
    int totalCount,
    double averagePerPoint,
    Map<String, dynamic>? organismData,
  ) async {
    try {
      // Usar limiares do catálogo se disponível
      if (organismData != null && organismData.containsKey('limiares_especificos')) {
        final limiares = organismData['limiares_especificos'] as Map<String, dynamic>;
        
        // Verificar limiares por fase fenológica
        for (final entry in limiares.entries) {
          final fase = entry.key;
          final limite = entry.value as String;
          
          // Extrair número do limite (ex: "2 lagartas por metro quadrado" -> 2)
          final limiteNumero = _extractNumberFromString(limite);
          
          if (totalCount <= limiteNumero) {
            return 'BAIXO';
          }
        }
      }
      
      // Limiares padrão baseados na contagem
      if (totalCount <= 5) return 'BAIXO';
      if (totalCount <= 15) return 'MÉDIO';
      if (totalCount <= 30) return 'ALTO';
      return 'CRÍTICO';
      
    } catch (e) {
      Logger.error('❌ Erro ao determinar severidade: $e');
      return 'DESCONHECIDO';
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

  /// Calcula percentual médio do talhão
  double _calculateTalhaoAveragePercentage(List<InfestationCountResult> organismResults) {
    if (organismResults.isEmpty) return 0.0;
    
    double totalPercentage = 0.0;
    int validResults = 0;
    
    for (final result in organismResults) {
      // Converter severidade para percentual
      double percentage = 0.0;
      switch (result.severityLevel) {
        case 'BAIXO': percentage = 25.0; break;
        case 'MÉDIO': percentage = 50.0; break;
        case 'ALTO': percentage = 75.0; break;
        case 'CRÍTICO': percentage = 100.0; break;
        default: percentage = 0.0;
      }
      
      // Ponderar pelo número de pontos afetados
      final weight = result.affectedPoints / result.totalPoints;
      totalPercentage += percentage * weight;
      validResults++;
    }
    
    return validResults > 0 ? totalPercentage / validResults : 0.0;
  }

  /// Determina severidade geral do talhão
  String _determineOverallSeverity(
    double averagePercentage,
    List<InfestationCountResult> organismResults,
  ) {
    // Verificar se há organismos críticos
    final hasCritical = organismResults.any((r) => r.severityLevel == 'CRÍTICO');
    if (hasCritical) return 'CRÍTICO';
    
    // Usar percentual médio
    if (averagePercentage <= 25.0) return 'BAIXO';
    if (averagePercentage <= 50.0) return 'MÉDIO';
    if (averagePercentage <= 75.0) return 'ALTO';
    return 'CRÍTICO';
  }

  /// Identifica pontos críticos sequenciais para heatmap térmico
  List<CriticalSequentialPoint> _identifyCriticalSequentialPoints(
    List<MonitoringPoint> points,
    List<InfestationCountResult> organismResults,
  ) {
    final criticalPoints = <CriticalSequentialPoint>[];
    
    // Encontrar organismos críticos
    final criticalOrganisms = organismResults
        .where((r) => r.severityLevel == 'CRÍTICO' || r.severityLevel == 'ALTO')
        .toList();
    
    for (final organism in criticalOrganisms) {
      // Encontrar pontos com alta infestação para este organismo
      final organismPoints = points.where((point) {
        return point.occurrences.any((occurrence) => 
          occurrence.name == organism.organismoId && 
          occurrence.infestationIndex > 50.0
        );
      }).toList();
      
      // Agrupar pontos próximos (sequenciais)
      final sequentialGroups = _groupNearbyPoints(organismPoints, 100.0); // 100 metros
      
      for (final group in sequentialGroups) {
        if (group.length >= 2) { // Pelo menos 2 pontos próximos
          final centerPoint = _calculateGroupCenter(group);
          final totalCount = group.fold<int>(0, (sum, point) {
            return sum + point.occurrences
                .where((o) => o.name == organism.organismoId)
                .fold<int>(0, (s, o) => s + _extractInfestationCount(o.name, o.infestationIndex));
          });
          
          final thermalIntensity = _calculateThermalIntensity(group, totalCount);
          
          criticalPoints.add(CriticalSequentialPoint(
            id: 'critical_${organism.organismoId}_${DateTime.now().millisecondsSinceEpoch}',
            position: centerPoint,
            organismoId: organism.organismoId,
            infestationCount: totalCount,
            severityLevel: organism.severityLevel,
            colorCode: organism.colorCode,
            thermalIntensity: thermalIntensity,
            nearbyPoints: group.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          ));
        }
      }
    }
    
    return criticalPoints;
  }

  /// Agrupa pontos próximos
  List<List<MonitoringPoint>> _groupNearbyPoints(
    List<MonitoringPoint> points,
    double maxDistance,
  ) {
    final groups = <List<MonitoringPoint>>[];
    final used = <int>{};
    
    for (int i = 0; i < points.length; i++) {
      if (used.contains(i)) continue;
      
      final group = <MonitoringPoint>[points[i]];
      used.add(i);
      
      for (int j = i + 1; j < points.length; j++) {
        if (used.contains(j)) continue;
        
        final distance = _calculateDistance(
          points[i].latitude, points[i].longitude,
          points[j].latitude, points[j].longitude,
        );
        
        if (distance <= maxDistance) {
          group.add(points[j]);
          used.add(j);
        }
      }
      
      groups.add(group);
    }
    
    return groups;
  }

  /// Calcula centro de um grupo de pontos
  LatLng _calculateGroupCenter(List<MonitoringPoint> points) {
    double totalLat = 0.0;
    double totalLng = 0.0;
    
    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    
    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  /// Calcula intensidade térmica
  double _calculateThermalIntensity(List<MonitoringPoint> points, int totalCount) {
    // Baseado no número de pontos e contagem total
    final pointDensity = points.length / 10.0; // Normalizar
    final countDensity = totalCount / 100.0; // Normalizar
    
    return (pointDensity + countDensity).clamp(0.0, 1.0);
  }

  /// Calcula distância entre duas coordenadas
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000.0; // metros
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
               sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
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

  /// Gera metadados
  Map<String, dynamic> _generateMetadata(
    List<MonitoringPoint> points,
    List<InfestationCountResult> organismResults,
  ) {
    return {
      'calculation_date': DateTime.now().toIso8601String(),
      'total_points': points.length,
      'total_organisms': organismResults.length,
      'critical_organisms': organismResults.where((r) => r.severityLevel == 'CRÍTICO').length,
      'high_organisms': organismResults.where((r) => r.severityLevel == 'ALTO').length,
      'total_infestation_count': organismResults.fold<int>(0, (sum, r) => sum + r.totalCount),
    };
  }

  /// Cria resultado vazio
  TalhaoAverageResult _createEmptyResult(String talhaoId) {
    return TalhaoAverageResult(
      talhaoId: talhaoId,
      averagePercentage: 0.0,
      overallSeverity: 'BAIXO',
      colorCode: '#4CAF50',
      organismResults: [],
      criticalSequentialPoints: [],
      metadata: {
        'calculation_date': DateTime.now().toIso8601String(),
        'status': 'no_data',
      },
    );
  }

  /// Cria resultado vazio para organismo
  InfestationCountResult _createEmptyOrganismResult(String organismId) {
    return InfestationCountResult(
      organismoId: organismId,
      organismoNome: organismId,
      totalCount: 0,
      totalPoints: 0,
      affectedPoints: 0,
      averagePerPoint: 0.0,
      severityLevel: 'BAIXO',
      colorCode: '#4CAF50',
    );
  }
}
