import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../../models/infestation_point.dart';
import '../../../models/organism_catalog.dart';
import 'infestation_level.dart';
import 'thermal_heatmap_result.dart';

/// Resultado do cálculo matemático de infestação
class InfestationCalculationResult {
  final String classification; // BAIXO, MODERADO, ALTO, CRÍTICO
  final double infestationIndex; // Índice de infestação (0-100)
  final double averageCount; // Média de contagem
  final double totalCount; // Total de contagem
  final int pointCount; // Número de pontos
  final List<HeatmapData> heatmapData; // Dados para o heatmap
  final List<InfestationPoint> criticalPoints; // Pontos críticos
  final Map<String, dynamic> metadata; // Metadados adicionais

  InfestationCalculationResult({
    required this.classification,
    required this.infestationIndex,
    required this.averageCount,
    required this.totalCount,
    required this.pointCount,
    required this.heatmapData,
    required this.criticalPoints,
    required this.metadata,
  });

  /// Converte para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'classification': classification,
      'infestation_index': infestationIndex,
      'average_count': averageCount,
      'total_count': totalCount,
      'point_count': pointCount,
      'heatmap_data': heatmapData.map((h) => h.toMap()).toList(),
      'critical_points': criticalPoints.map((p) => p.toMap()).toList(),
      'metadata': metadata,
    };
  }
}

/// Dados para geração do heatmap
class HeatmapData {
  final double latitude;
  final double longitude;
  final double intensity; // Intensidade (0-1)
  final String level; // BAIXO, MODERADO, ALTO, CRÍTICO
  final double radius; // Raio de influência em metros

  HeatmapData({
    required this.latitude,
    required this.longitude,
    required this.intensity,
    required this.level,
    required this.radius,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'intensity': intensity,
      'level': level,
      'radius': radius,
    };
  }
}

/// Calculador matemático de infestação que combina:
/// 1. Cálculo por ponto georreferenciado → gera heatmap
/// 2. Cálculo consolidado por talhão → classificação geral
class MathematicalInfestationCalculator {
  final List<InfestationPoint> points;
  final OrganismCatalog organism;
  final String phenologicalPhase; // vegetativo, floracao, enchimento
  final double? talhaoArea; // Área do talhão em hectares
  final int? totalPlants; // Total de plantas no talhão

  MathematicalInfestationCalculator({
    required this.points,
    required this.organism,
    required this.phenologicalPhase,
    this.talhaoArea,
    this.totalPlants,
  });

  /// Executa o cálculo completo
  InfestationCalculationResult calculate() {
    if (points.isEmpty) {
      return _emptyResult();
    }

    // 1. Obter thresholds do organismo para a fase fenológica
    final thresholds = _getThresholdsForPhase();
    
    // 2. Calcular infestação por ponto
    final pointCalculations = _calculatePointInfestations(thresholds);
    
    // 3. Gerar heatmap
    final heatmapData = _generateHeatmap(pointCalculations);
    
    // 4. Calcular infestação consolidada do talhão
    final consolidatedResult = _calculateConsolidatedInfestation(pointCalculations, thresholds);
    
    // 5. Identificar pontos críticos
    final criticalPoints = _identifyCriticalPoints(pointCalculations);
    
    // 6. Compilar resultado final
    return InfestationCalculationResult(
      classification: consolidatedResult['classification'] as String,
      infestationIndex: consolidatedResult['infestation_index'] as double,
      averageCount: consolidatedResult['average_count'] as double,
      totalCount: consolidatedResult['total_count'] as double,
      pointCount: points.length,
      heatmapData: heatmapData,
      criticalPoints: criticalPoints,
      metadata: {
        'organism_name': organism.name,
        'phenological_phase': phenologicalPhase,
        'thresholds_used': thresholds,
        'calculation_timestamp': DateTime.now().toIso8601String(),
        'talhao_area': talhaoArea,
        'total_plants': totalPlants,
      },
    );
  }

  /// Obtém os thresholds do organismo para a fase fenológica atual
  Map<String, dynamic> _getThresholdsForPhase() {
    try {
      // Usar thresholds padrão do organismo
      return {
        'low': organism.lowLimit,
        'medium': organism.mediumLimit,
        'high': organism.highLimit,
        'unit': organism.unit,
      };
      
    } catch (e) {
      debugPrint('❌ Erro ao obter thresholds: $e');
      return _getDefaultThresholds();
    }
  }

  /// Parseia um threshold textual em valores numéricos
  Map<String, dynamic> _parseThreshold(String threshold) {
    final lowerThreshold = threshold.toLowerCase();
    
    // Padrões comuns de thresholds
    if (lowerThreshold.contains('percevejos por metro')) {
      final value = _extractNumber(threshold);
      return {
        'baixo': 0,
        'medio': (value * 0.5).round(),
        'alto': value,
        'critico': (value * 1.5).round(),
        'unit': 'percevejos/m',
        'type': 'count_per_meter',
      };
    }
    
    if (lowerThreshold.contains('lagartas por metro')) {
      final value = _extractNumber(threshold);
      return {
        'baixo': 0,
        'medio': (value * 0.5).round(),
        'alto': value,
        'critico': (value * 1.5).round(),
        'unit': 'lagartas/m',
        'type': 'count_per_meter',
      };
    }
    
    if (lowerThreshold.contains('% de desfolha')) {
      final value = _extractNumber(threshold);
      return {
        'baixo': 0,
        'medio': (value * 0.5).round(),
        'alto': value,
        'critico': (value * 1.5).round(),
        'unit': '%',
        'type': 'percentage',
      };
    }
    
    if (lowerThreshold.contains('% das plantas')) {
      final value = _extractNumber(threshold);
      return {
        'baixo': 0,
        'medio': (value * 0.5).round(),
        'alto': value,
        'critico': (value * 1.5).round(),
        'unit': '%',
        'type': 'percentage',
      };
    }
    
    // Threshold padrão se não conseguir parsear
    return _getDefaultThresholds();
  }

  /// Extrai número de uma string
  double _extractNumber(String text) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(text);
    return match != null ? double.parse(match.group(1)!) : 1.0;
  }

  /// Thresholds padrão quando não há dados específicos
  Map<String, dynamic> _getDefaultThresholds() {
    return {
      'baixo': 0,
      'medio': 1,
      'alto': 2,
      'critico': 3,
      'unit': 'unidades',
      'type': 'count',
    };
  }

  /// Calcula infestação para cada ponto
  List<Map<String, dynamic>> _calculatePointInfestations(Map<String, dynamic> thresholds) {
    return points.map((point) {
      final infestationRatio = _calculatePointInfestationRatio(point, thresholds);
      final level = _classifyInfestationLevel(infestationRatio, thresholds);
      
      return {
        'point': point,
        'infestation_ratio': infestationRatio,
        'level': level,
        'weight': point.accuracyWeight * point.timeWeight,
      };
    }).toList();
  }

  /// Calcula a razão de infestação para um ponto específico
  double _calculatePointInfestationRatio(InfestationPoint point, Map<String, dynamic> thresholds) {
    final thresholdValue = thresholds['alto'] as int;
    if (thresholdValue <= 0) return 0.0;
    
    // Converter contagem para a unidade do threshold
    final normalizedCount = _normalizeCount(point, thresholds);
    
    // Calcular razão: I_ponto = N_observado / N_limiar
    return (normalizedCount / thresholdValue).clamp(0.0, 10.0); // Limitar a 10x o threshold
  }

  /// Normaliza a contagem do ponto para a unidade do threshold
  double _normalizeCount(InfestationPoint point, Map<String, dynamic> thresholds) {
    final thresholdUnit = thresholds['unit'] as String;
    final thresholdType = thresholds['type'] as String;
    
    switch (thresholdType) {
      case 'count_per_meter':
        // Se o threshold é por metro, assumir que o ponto representa 1 metro
        return point.count.toDouble();
        
      case 'percentage':
        // Se o threshold é percentual, converter contagem para percentual
        if (totalPlants != null && totalPlants! > 0) {
          return (point.count / totalPlants!) * 100;
        }
        return point.count.toDouble();
        
      case 'count':
      default:
        // Contagem simples
        return point.count.toDouble();
    }
  }

  /// Classifica o nível de infestação baseado na razão
  String _classifyInfestationLevel(double ratio, Map<String, dynamic> thresholds) {
    final baixo = thresholds['baixo'] as int;
    final medio = thresholds['medio'] as int;
    final alto = thresholds['alto'] as int;
    final critico = thresholds['critico'] as int;
    
    if (ratio <= (baixo / alto)) return 'BAIXO';
    if (ratio <= (medio / alto)) return 'MODERADO';
    if (ratio <= (alto / alto)) return 'ALTO';
    return 'CRÍTICO';
  }

  /// Gera dados do heatmap
  List<HeatmapData> _generateHeatmap(List<Map<String, dynamic>> pointCalculations) {
    final List<HeatmapData> heatmapData = [];
    
    for (final calculation in pointCalculations) {
      final point = calculation['point'] as InfestationPoint;
      final ratio = calculation['infestation_ratio'] as double;
      final level = calculation['level'] as String;
      
      // Calcular intensidade baseada na razão de infestação
      final intensity = math.min(ratio, 1.0);
      
      // Calcular raio de influência baseado na intensidade
      final radius = _calculateInfluenceRadius(intensity, point.accuracy);
      
      heatmapData.add(HeatmapData(
        latitude: point.latitude,
        longitude: point.longitude,
        intensity: intensity,
        level: level,
        radius: radius,
      ));
    }
    
    return heatmapData;
  }

  /// Calcula o raio de influência para o heatmap
  double _calculateInfluenceRadius(double intensity, double? accuracy) {
    // Raio base de 50 metros
    double baseRadius = 50.0;
    
    // Ajustar baseado na intensidade
    baseRadius *= (0.5 + intensity * 0.5);
    
    // Ajustar baseado na precisão GPS
    if (accuracy != null) {
      baseRadius = math.max(baseRadius, accuracy * 2);
    }
    
    return baseRadius.clamp(25.0, 200.0);
  }

  /// Calcula infestação consolidada do talhão
  Map<String, dynamic> _calculateConsolidatedInfestation(
    List<Map<String, dynamic>> pointCalculations,
    Map<String, dynamic> thresholds,
  ) {
    if (pointCalculations.isEmpty) {
      return {
        'classification': 'BAIXO',
        'infestation_index': 0.0,
        'average_count': 0.0,
        'total_count': 0.0,
      };
    }

    // Calcular média ponderada
    double totalWeightedRatio = 0.0;
    double totalWeight = 0.0;
    double totalCount = 0.0;
    
    for (final calculation in pointCalculations) {
      final ratio = calculation['infestation_ratio'] as double;
      final weight = calculation['weight'] as double;
      final point = calculation['point'] as InfestationPoint;
      
      totalWeightedRatio += ratio * weight;
      totalWeight += weight;
      totalCount += point.count.toDouble();
    }
    
    final averageRatio = totalWeight > 0 ? totalWeightedRatio / totalWeight : 0.0;
    final averageCount = totalCount / pointCalculations.length;
    
    // Classificar infestação consolidada
    final classification = _classifyInfestationLevel(averageRatio, thresholds);
    
    // Converter para índice de 0-100
    final infestationIndex = (averageRatio * 100).clamp(0.0, 100.0);
    
    return {
      'classification': classification,
      'infestation_index': infestationIndex,
      'average_count': averageCount,
      'total_count': totalCount,
    };
  }

  /// Identifica pontos críticos (ALTO ou CRÍTICO)
  List<InfestationPoint> _identifyCriticalPoints(List<Map<String, dynamic>> pointCalculations) {
    return pointCalculations
        .where((calculation) {
          final level = calculation['level'] as String;
          return level == 'ALTO' || level == 'CRÍTICO';
        })
        .map((calculation) => calculation['point'] as InfestationPoint)
        .toList();
  }

  /// Resultado vazio quando não há pontos
  InfestationCalculationResult _emptyResult() {
    return InfestationCalculationResult(
      classification: 'BAIXO',
      infestationIndex: 0.0,
      averageCount: 0.0,
      totalCount: 0.0,
      pointCount: 0,
      heatmapData: [],
      criticalPoints: [],
      metadata: {
        'organism_name': organism.name,
        'phenological_phase': phenologicalPhase,
        'calculation_timestamp': DateTime.now().toIso8601String(),
        'error': 'No points provided',
      },
    );
  }
}