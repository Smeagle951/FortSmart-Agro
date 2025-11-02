import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/infestacao_model.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';

/// Serviço para geração de hexágonos inteligentes diferenciados por organismo
class IntelligentHexagonService {
  
  /// Gera hexágonos inteligentes baseados em organismos e severidade
  Future<List<IntelligentHexagon>> generateIntelligentHexagons({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
    required double hexagonSize, // Tamanho do hexágono em metros
  }) async {
    try {
      Logger.info('🔷 [HEXAGON] Gerando hexágonos inteligentes com ${occurrences.length} ocorrências');
      
      final hexagons = <IntelligentHexagon>[];
      
      // Agrupar ocorrências por organismo
      final organismGroups = _groupOccurrencesByOrganism(occurrences);
      
      for (final entry in organismGroups.entries) {
        final organismId = entry.key;
        final organismOccurrences = entry.value;
        
        // Calcular centro do hexágono baseado nas ocorrências
        final center = _calculateHexagonCenter(organismOccurrences, monitoringPoints);
        
        if (center != null) {
          // Calcular métricas do hexágono
          final metrics = _calculateHexagonMetrics(organismOccurrences);
          
          // Gerar vértices do hexágono
          final vertices = _generateHexagonVertices(center, hexagonSize);
          
          // Calcular cor baseada na severidade e organismo
          final color = _calculateOrganismColor(organismId, metrics.severity);
          
          // Calcular opacidade baseada na confiança
          final opacity = _calculateConfidenceOpacity(metrics.confidence);
          
          hexagons.add(IntelligentHexagon(
            center: center,
            vertices: vertices,
            organismId: organismId,
            organismName: organismOccurrences.first.subtipo,
            organismType: _getOrganismType(organismId),
            severity: metrics.severity,
            confidence: metrics.confidence,
            phase: metrics.dominantPhase,
            riskLevel: metrics.riskLevel,
            color: color,
            opacity: opacity,
            strokeColor: _calculateStrokeColor(metrics.riskLevel),
            strokeWidth: _calculateStrokeWidth(metrics.severity),
            totalOccurrences: organismOccurrences.length,
            averageIntensity: metrics.averageIntensity,
            temperature: metrics.temperature,
            humidity: metrics.humidity,
            aiDiagnosis: metrics.aiDiagnosis,
            timestamp: DateTime.now(),
          ));
        }
      }
      
      Logger.info('✅ [HEXAGON] ${hexagons.length} hexágonos inteligentes gerados');
      return hexagons;
      
    } catch (e) {
      Logger.error('❌ [HEXAGON] Erro ao gerar hexágonos inteligentes: $e');
      return [];
    }
  }
  
  /// Agrupa ocorrências por organismo
  Map<String, List<InfestacaoModel>> _groupOccurrencesByOrganism(List<InfestacaoModel> occurrences) {
    final grouped = <String, List<InfestacaoModel>>{};
    
    for (final occurrence in occurrences) {
      final organismId = occurrence.subtipo;
      grouped.putIfAbsent(organismId, () => []).add(occurrence);
    }
    
    return grouped;
  }
  
  /// Calcula centro do hexágono baseado nas ocorrências
  LatLng? _calculateHexagonCenter(
    List<InfestacaoModel> occurrences,
    List<MonitoringPoint> monitoringPoints,
  ) {
    if (occurrences.isEmpty) return null;
    
    double totalLat = 0.0;
    double totalLng = 0.0;
    int validPoints = 0;
    
    for (final occurrence in occurrences) {
      if (occurrence.latitude != 0 && occurrence.longitude != 0) {
        totalLat += occurrence.latitude;
        totalLng += occurrence.longitude;
        validPoints++;
      }
    }
    
    if (validPoints == 0) return null;
    
    return LatLng(totalLat / validPoints, totalLng / validPoints);
  }
  
  /// Calcula métricas do hexágono
  HexagonMetrics _calculateHexagonMetrics(List<InfestacaoModel> occurrences) {
    double totalSeverity = 0.0;
    double totalConfidence = 0.0;
    double totalIntensity = 0.0;
    double totalTemperature = 0.0;
    double totalHumidity = 0.0;
    
    final phases = <String, int>{};
    final aiDiagnoses = <Map<String, dynamic>>[];
    
    for (final occurrence in occurrences) {
      // Severidade baseada no percentual
      final severity = _calculateSeverityFromPercentual(occurrence.percentual.toDouble());
      totalSeverity += severity;
      
      // Confiança baseada na qualidade dos dados
      final confidence = _calculateConfidenceFromOccurrence(occurrence);
      totalConfidence += confidence;
      
      // Intensidade
      final intensity = occurrence.percentual / 100.0;
      totalIntensity += intensity;
      
      // Condições ambientais simuladas
      final temperature = _simulateTemperature(occurrence.dataHora);
      final humidity = _simulateHumidity(occurrence.dataHora);
      totalTemperature += temperature;
      totalHumidity += humidity;
      
      // Fase do organismo
      final phase = _extractPhaseFromOccurrence(occurrence);
      phases[phase] = (phases[phase] ?? 0) + 1;
      
      // Diagnóstico de IA
      final aiDiagnosis = _generateAIDiagnosis(occurrence);
      if (aiDiagnosis != null) {
        aiDiagnoses.add(aiDiagnosis);
      }
    }
    
    final count = occurrences.length;
    final dominantPhase = phases.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final riskLevel = _calculateRiskLevel(
      totalSeverity / count,
      totalConfidence / count,
    );
    
    return HexagonMetrics(
      severity: totalSeverity / count,
      confidence: totalConfidence / count,
      averageIntensity: totalIntensity / count,
      dominantPhase: dominantPhase,
      riskLevel: riskLevel,
      temperature: totalTemperature / count,
      humidity: totalHumidity / count,
      aiDiagnosis: aiDiagnoses.isNotEmpty ? aiDiagnoses.first : null,
    );
  }
  
  /// Gera vértices do hexágono
  List<LatLng> _generateHexagonVertices(LatLng center, double size) {
    final vertices = <LatLng>[];
    final radius = size / 2; // Raio em metros
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (pi / 180.0); // 60 graus por vértice
      final lat = center.latitude + (radius / 111000.0) * cos(angle);
      final lng = center.longitude + (radius / (111000.0 * cos(center.latitude * pi / 180.0))) * sin(angle);
      vertices.add(LatLng(lat, lng));
    }
    
    return vertices;
  }
  
  /// Calcula cor baseada no organismo e severidade
  Color _calculateOrganismColor(String organismId, double severity) {
    // Cores diferentes para cada tipo de organismo
    Color baseColor;
    
    if (organismId.contains('praga') || organismId.contains('lagarta')) {
      baseColor = Colors.orange;
    } else if (organismId.contains('doenca') || organismId.contains('fungo')) {
      baseColor = Colors.red;
    } else if (organismId.contains('daninha') || organismId.contains('erva')) {
      baseColor = Colors.green;
    } else {
      baseColor = Colors.blue;
    }
    
    // Ajustar intensidade baseada na severidade
    final intensity = (severity / 10.0).clamp(0.3, 1.0);
    
    return Color.fromRGBO(
      (baseColor.red * intensity).round(),
      (baseColor.green * intensity).round(),
      (baseColor.blue * intensity).round(),
      0.7,
    );
  }
  
  /// Calcula opacidade baseada na confiança
  double _calculateConfidenceOpacity(double confidence) {
    return (confidence / 100.0).clamp(0.3, 0.9);
  }
  
  /// Calcula cor da borda baseada no nível de risco
  Color _calculateStrokeColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'crítico':
        return Colors.red.shade800;
      case 'alto':
        return Colors.orange.shade800;
      case 'médio':
        return Colors.yellow.shade800;
      default:
        return Colors.green.shade800;
    }
  }
  
  /// Calcula largura da borda baseada na severidade
  double _calculateStrokeWidth(double severity) {
    if (severity >= 8) return 3.0;
    if (severity >= 6) return 2.5;
    if (severity >= 4) return 2.0;
    return 1.5;
  }
  
  // Métodos auxiliares
  
  double _calculateSeverityFromPercentual(double percentual) {
    if (percentual <= 10) return 2.0;
    if (percentual <= 30) return 5.0;
    if (percentual <= 60) return 7.0;
    return 9.0;
  }
  
  double _calculateConfidenceFromOccurrence(InfestacaoModel occurrence) {
    double confidence = 70.0; // Base
    
    if (occurrence.observacao?.isNotEmpty == true) confidence += 10;
    if (occurrence.latitude != 0 && occurrence.longitude != 0) confidence += 10;
    if (occurrence.subtipo.isNotEmpty) confidence += 10;
    
    return confidence.clamp(0.0, 100.0);
  }
  
  double _simulateTemperature(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 22.0; // Outono
    if (month >= 6 && month <= 8) return 18.0; // Inverno
    if (month >= 9 && month <= 11) return 25.0; // Primavera
    return 28.0; // Verão
  }
  
  double _simulateHumidity(DateTime date) {
    final month = date.month;
    if (month >= 6 && month <= 8) return 85.0; // Inverno
    if (month >= 12 && month <= 2) return 75.0; // Verão
    return 70.0; // Padrão
  }
  
  String _extractPhaseFromOccurrence(InfestacaoModel occurrence) {
    final observations = occurrence.observacao?.toLowerCase() ?? '';
    if (observations.contains('ovo')) return 'Ovo';
    if (observations.contains('larva')) return 'Larva Média';
    if (observations.contains('adulto')) return 'Adulto';
    return 'Larva Média';
  }
  
  String _getOrganismType(String organismId) {
    if (organismId.contains('praga')) return 'Praga';
    if (organismId.contains('doenca')) return 'Doença';
    if (organismId.contains('daninha')) return 'Planta Daninha';
    return 'Organismo';
  }
  
  String _calculateRiskLevel(double severity, double confidence) {
    if (severity >= 8 && confidence >= 80) return 'Crítico';
    if (severity >= 6 && confidence >= 70) return 'Alto';
    if (severity >= 4 && confidence >= 60) return 'Médio';
    return 'Baixo';
  }
  
  Map<String, dynamic>? _generateAIDiagnosis(InfestacaoModel occurrence) {
    if (occurrence.observacao?.isNotEmpty == true) {
      return {
        'organismName': occurrence.subtipo,
        'confidence': _calculateConfidenceFromOccurrence(occurrence) / 100.0,
        'severity': _calculateSeverityFromPercentual(occurrence.percentual.toDouble()),
        'phase': _extractPhaseFromOccurrence(occurrence),
        'riskLevel': _calculateRiskLevel(
          _calculateSeverityFromPercentual(occurrence.percentual.toDouble()),
          _calculateConfidenceFromOccurrence(occurrence),
        ),
      };
    }
    return null;
  }
}

/// Métricas do hexágono
class HexagonMetrics {
  final double severity;
  final double confidence;
  final double averageIntensity;
  final String dominantPhase;
  final String riskLevel;
  final double temperature;
  final double humidity;
  final Map<String, dynamic>? aiDiagnosis;
  
  HexagonMetrics({
    required this.severity,
    required this.confidence,
    required this.averageIntensity,
    required this.dominantPhase,
    required this.riskLevel,
    required this.temperature,
    required this.humidity,
    this.aiDiagnosis,
  });
}

/// Hexágono inteligente com dados enriquecidos
class IntelligentHexagon {
  final LatLng center;
  final List<LatLng> vertices;
  final String organismId;
  final String organismName;
  final String organismType;
  final double severity;
  final double confidence;
  final String phase;
  final String riskLevel;
  final Color color;
  final double opacity;
  final Color strokeColor;
  final double strokeWidth;
  final int totalOccurrences;
  final double averageIntensity;
  final double temperature;
  final double humidity;
  final Map<String, dynamic>? aiDiagnosis;
  final DateTime timestamp;
  
  IntelligentHexagon({
    required this.center,
    required this.vertices,
    required this.organismId,
    required this.organismName,
    required this.organismType,
    required this.severity,
    required this.confidence,
    required this.phase,
    required this.riskLevel,
    required this.color,
    required this.opacity,
    required this.strokeColor,
    required this.strokeWidth,
    required this.totalOccurrences,
    required this.averageIntensity,
    required this.temperature,
    required this.humidity,
    this.aiDiagnosis,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'vertices': vertices.map((v) => {'lat': v.latitude, 'lng': v.longitude}).toList(),
      'organismId': organismId,
      'organismName': organismName,
      'organismType': organismType,
      'severity': severity,
      'confidence': confidence,
      'phase': phase,
      'riskLevel': riskLevel,
      'color': color.value,
      'opacity': opacity,
      'strokeColor': strokeColor.value,
      'strokeWidth': strokeWidth,
      'totalOccurrences': totalOccurrences,
      'averageIntensity': averageIntensity,
      'temperature': temperature,
      'humidity': humidity,
      'aiDiagnosis': aiDiagnosis,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
