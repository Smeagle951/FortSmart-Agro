import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/infestacao_model.dart';
import '../models/monitoring_point.dart';
import '../utils/logger.dart';

/// Serviço para geração de heatmaps inteligentes com dados enriquecidos
class IntelligentHeatmapService {
  
  /// Gera pontos de heatmap baseados em dados enriquecidos do card inteligente
  Future<List<IntelligentHeatmapPoint>> generateIntelligentHeatmap({
    required List<InfestacaoModel> occurrences,
    required List<MonitoringPoint> monitoringPoints,
  }) async {
    try {
      Logger.info('🔥 [HEATMAP] Gerando heatmap inteligente com ${occurrences.length} ocorrências');
      
      final heatmapPoints = <IntelligentHeatmapPoint>[];
      
      // Agrupar ocorrências por ponto de monitoramento
      final groupedOccurrences = _groupOccurrencesByPoint(occurrences, monitoringPoints);
      
      for (final entry in groupedOccurrences.entries) {
        final pointId = entry.key;
        final pointOccurrences = entry.value;
        final monitoringPoint = monitoringPoints.firstWhere(
          (p) => p.id == pointId,
          orElse: () => monitoringPoints.first,
        );
        
        // Calcular intensidade baseada em severidade + fase + condições ambientais
        final intensity = _calculateIntelligentIntensity(pointOccurrences);
        
        // Calcular cor baseada na severidade
        final color = _calculateSeverityColor(intensity);
        
        // Calcular raio baseado na confiança dos dados
        final radius = _calculateConfidenceRadius(pointOccurrences);
        
        heatmapPoints.add(IntelligentHeatmapPoint(
          lat: monitoringPoint.latitude,
          lng: monitoringPoint.longitude,
          intensity: intensity,
          color: color,
          radius: radius,
          organismId: pointOccurrences.first.subtipo,
          organismName: pointOccurrences.first.subtipo,
          phase: _extractPhaseFromOccurrence(pointOccurrences.first),
          severity: _extractSeverityFromOccurrence(pointOccurrences.first),
          confidence: _extractConfidenceFromOccurrence(pointOccurrences.first),
          temperature: _extractTemperatureFromOccurrence(pointOccurrences.first),
          humidity: _extractHumidityFromOccurrence(pointOccurrences.first),
          riskLevel: _calculateRiskLevel(intensity, pointOccurrences.first),
          aiDiagnosis: _extractAIDiagnosisFromOccurrence(pointOccurrences.first),
          timestamp: pointOccurrences.first.dataHora,
        ));
      }
      
      Logger.info('✅ [HEATMAP] ${heatmapPoints.length} pontos de heatmap inteligente gerados');
      return heatmapPoints;
      
    } catch (e) {
      Logger.error('❌ [HEATMAP] Erro ao gerar heatmap inteligente: $e');
      return [];
    }
  }
  
  /// Agrupa ocorrências por ponto de monitoramento
  Map<String, List<InfestacaoModel>> _groupOccurrencesByPoint(
    List<InfestacaoModel> occurrences,
    List<MonitoringPoint> monitoringPoints,
  ) {
    final grouped = <String, List<InfestacaoModel>>{};
    
    for (final occurrence in occurrences) {
      // Encontrar o ponto de monitoramento mais próximo
      final nearestPoint = _findNearestMonitoringPoint(
        occurrence.latitude,
        occurrence.longitude,
        monitoringPoints,
      );
      
      if (nearestPoint != null) {
        grouped.putIfAbsent(nearestPoint.id, () => []).add(occurrence);
      }
    }
    
    return grouped;
  }
  
  /// Encontra o ponto de monitoramento mais próximo
  MonitoringPoint? _findNearestMonitoringPoint(
    double lat,
    double lng,
    List<MonitoringPoint> points,
  ) {
    if (points.isEmpty) return null;
    
    double minDistance = double.infinity;
    MonitoringPoint? nearestPoint;
    
    for (final point in points) {
      final distance = _calculateDistance(lat, lng, point.latitude, point.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }
    
    // Só retorna se estiver dentro de um raio razoável (ex: 100m)
    return minDistance < 0.1 ? nearestPoint : null;
  }
  
  /// Calcula distância entre dois pontos
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  /// Calcula intensidade inteligente baseada em severidade + fase + condições
  double _calculateIntelligentIntensity(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return 0.0;
    
    double totalIntensity = 0.0;
    int validOccurrences = 0;
    
    for (final occurrence in occurrences) {
      // Base: severidade (0-10) do card inteligente
      final severity = _extractSeverityFromOccurrence(occurrence);
      final severityWeight = severity / 10.0;
      
      // Peso da fase do organismo
      final phase = _extractPhaseFromOccurrence(occurrence);
      final phaseWeight = _getPhaseWeight(phase);
      
      // Peso das condições ambientais
      final temperature = _extractTemperatureFromOccurrence(occurrence);
      final humidity = _extractHumidityFromOccurrence(occurrence);
      final environmentalWeight = _calculateEnvironmentalWeight(temperature, humidity);
      
      // Peso da confiança da IA
      final confidence = _extractConfidenceFromOccurrence(occurrence);
      final confidenceWeight = confidence / 100.0;
      
      // Cálculo final da intensidade
      final intensity = (severityWeight * 0.4) + 
                      (phaseWeight * 0.3) + 
                      (environmentalWeight * 0.2) + 
                      (confidenceWeight * 0.1);
      
      totalIntensity += intensity;
      validOccurrences++;
    }
    
    return validOccurrences > 0 ? totalIntensity / validOccurrences : 0.0;
  }
  
  /// Obtém peso da fase do organismo
  double _getPhaseWeight(String phase) {
    switch (phase.toLowerCase()) {
      case 'ovo':
        return 0.2; // Baixo impacto
      case 'larva pequena':
        return 0.4; // Impacto médio
      case 'larva média':
        return 0.7; // Alto impacto
      case 'adulto':
        return 1.0; // Máximo impacto
      default:
        return 0.5; // Impacto médio padrão
    }
  }
  
  /// Calcula peso das condições ambientais
  double _calculateEnvironmentalWeight(double temperature, double humidity) {
    // Condições favoráveis para desenvolvimento de pragas/doenças
    double weight = 0.5; // Base
    
    // Temperatura ideal: 20-30°C
    if (temperature >= 20 && temperature <= 30) {
      weight += 0.3;
    } else if (temperature < 15 || temperature > 35) {
      weight -= 0.2;
    }
    
    // Umidade ideal: 60-80%
    if (humidity >= 60 && humidity <= 80) {
      weight += 0.2;
    } else if (humidity < 40 || humidity > 90) {
      weight -= 0.1;
    }
    
    return weight.clamp(0.0, 1.0);
  }
  
  /// Calcula cor baseada na severidade
  Color _calculateSeverityColor(double intensity) {
    if (intensity <= 0.2) return Colors.green;
    if (intensity <= 0.4) return Colors.lightGreen;
    if (intensity <= 0.6) return Colors.yellow;
    if (intensity <= 0.8) return Colors.orange;
    return Colors.red;
  }
  
  /// Calcula raio baseado na confiança dos dados
  double _calculateConfidenceRadius(List<InfestacaoModel> occurrences) {
    if (occurrences.isEmpty) return 20.0;
    
    double totalConfidence = 0.0;
    for (final occurrence in occurrences) {
      totalConfidence += _extractConfidenceFromOccurrence(occurrence);
    }
    
    final averageConfidence = totalConfidence / occurrences.length;
    
    // Raio baseado na confiança (20-60 metros)
    return 20.0 + (averageConfidence / 100.0) * 40.0;
  }
  
  /// Calcula nível de risco
  String _calculateRiskLevel(double intensity, InfestacaoModel occurrence) {
    if (intensity >= 0.8) return 'Crítico';
    if (intensity >= 0.6) return 'Alto';
    if (intensity >= 0.4) return 'Médio';
    return 'Baixo';
  }
  
  // Métodos de extração de dados enriquecidos
  
  String _extractPhaseFromOccurrence(InfestacaoModel occurrence) {
    // Tentar extrair da observação ou usar padrão
    final observations = occurrence.observacao?.toLowerCase() ?? '';
    if (observations.contains('ovo')) return 'Ovo';
    if (observations.contains('larva')) return 'Larva Média';
    if (observations.contains('adulto')) return 'Adulto';
    return 'Larva Média'; // Padrão
  }
  
  int _extractSeverityFromOccurrence(InfestacaoModel occurrence) {
    // Usar percentual como proxy para severidade (0-10)
    final percentual = occurrence.percentual;
    if (percentual <= 10) return 2;
    if (percentual <= 30) return 5;
    if (percentual <= 60) return 7;
    return 9;
  }
  
  double _extractConfidenceFromOccurrence(InfestacaoModel occurrence) {
    // Simular confiança baseada na qualidade dos dados
    double confidence = 70.0; // Base
    
    if (occurrence.observacao?.isNotEmpty == true) confidence += 10;
    if (occurrence.latitude != 0 && occurrence.longitude != 0) confidence += 10;
    if (occurrence.subtipo.isNotEmpty) confidence += 10;
    
    return confidence.clamp(0.0, 100.0);
  }
  
  double _extractTemperatureFromOccurrence(InfestacaoModel occurrence) {
    // Simular temperatura baseada na data (estação do ano)
    final month = occurrence.dataHora.month;
    if (month >= 3 && month <= 5) return 22.0; // Outono
    if (month >= 6 && month <= 8) return 18.0; // Inverno
    if (month >= 9 && month <= 11) return 25.0; // Primavera
    return 28.0; // Verão
  }
  
  double _extractHumidityFromOccurrence(InfestacaoModel occurrence) {
    // Simular umidade baseada na data
    final month = occurrence.dataHora.month;
    if (month >= 6 && month <= 8) return 85.0; // Inverno (mais úmido)
    if (month >= 12 && month <= 2) return 75.0; // Verão (menos úmido)
    return 70.0; // Padrão
  }
  
  Map<String, dynamic>? _extractAIDiagnosisFromOccurrence(InfestacaoModel occurrence) {
    // Simular diagnóstico de IA baseado nos dados
    if (occurrence.observacao?.isNotEmpty == true) {
      return {
        'organismName': occurrence.subtipo,
        'confidence': _extractConfidenceFromOccurrence(occurrence) / 100.0,
        'severity': _extractSeverityFromOccurrence(occurrence),
        'phase': _extractPhaseFromOccurrence(occurrence),
      };
    }
    return null;
  }
}

/// Ponto de heatmap inteligente com dados enriquecidos
class IntelligentHeatmapPoint {
  final double lat;
  final double lng;
  final double intensity;
  final Color color;
  final double radius;
  final String organismId;
  final String organismName;
  final String phase;
  final int severity;
  final double confidence;
  final double temperature;
  final double humidity;
  final String riskLevel;
  final Map<String, dynamic>? aiDiagnosis;
  final DateTime timestamp;
  
  // Getters para compatibilidade
  double get latitude => lat;
  double get longitude => lng;
  
  IntelligentHeatmapPoint({
    required this.lat,
    required this.lng,
    required this.intensity,
    required this.color,
    required this.radius,
    required this.organismId,
    required this.organismName,
    required this.phase,
    required this.severity,
    required this.confidence,
    required this.temperature,
    required this.humidity,
    required this.riskLevel,
    this.aiDiagnosis,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'intensity': intensity,
      'color': color.value,
      'radius': radius,
      'organismId': organismId,
      'organismName': organismName,
      'phase': phase,
      'severity': severity,
      'confidence': confidence,
      'temperature': temperature,
      'humidity': humidity,
      'riskLevel': riskLevel,
      'aiDiagnosis': aiDiagnosis,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
