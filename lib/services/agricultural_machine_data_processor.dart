import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../services/geojson_reader_service.dart';
import '../utils/logger.dart';

/// Dados de trabalho de máquina processados
class MachineWorkData {
  final String id;
  final String machineName;
  final String applicationType;
  final DateTime workDate;
  final List<WorkPoint> points;
  final double totalArea;
  final double totalVolume;
  final double averageRate;
  final double averageSpeed;
  final Map<String, dynamic> statistics;
  final List<ValueRange> valueRanges;

  MachineWorkData({
    required this.id,
    required this.machineName,
    required this.applicationType,
    required this.workDate,
    required this.points,
    required this.totalArea,
    required this.totalVolume,
    required this.averageRate,
    required this.averageSpeed,
    required this.statistics,
    required this.valueRanges,
  });
}

/// Ponto de trabalho da máquina
class WorkPoint {
  final double latitude;
  final double longitude;
  final double applicationRate; // kg/ha ou L/ha
  final double speed; // km/h
  final double volume; // volume aplicado
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  WorkPoint({
    required this.latitude,
    required this.longitude,
    required this.applicationRate,
    required this.speed,
    required this.volume,
    required this.timestamp,
    this.additionalData = const {},
  });
}

/// Faixa de valores para legenda
class ValueRange {
  final double minValue;
  final double maxValue;
  final Color color;
  final double area; // área em hectares
  final double percentage; // percentual da área total
  final int pointCount; // número de pontos nesta faixa

  ValueRange({
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.area,
    required this.percentage,
    required this.pointCount,
  });
}

/// Cores para faixas de valores (usando Flutter Color)
class ThermalColors {
  static const Color red = Color(0xFFFF0000);
  static const Color orange = Color(0xFFFFA500);
  static const Color yellow = Color(0xFFFFFF00);
  static const Color lightGreen = Color(0xFF90EE90);
  static const Color green = Color(0xFF00FF00);
  static const Color blue = Color(0xFF0000FF);
}

/// Processador de dados de máquinas agrícolas
class AgriculturalMachineDataProcessor {
  
  /// Processa dados GeoJSON de máquina agrícola
  static Future<MachineWorkData> processMachineData(GeoJSONData geoJSONData) async {
    try {
      Logger.info('🔄 [MACHINE_PROCESSOR] Iniciando processamento de dados de máquina');
      
      // Extrair pontos de trabalho
      final workPoints = _extractWorkPoints(geoJSONData);
      Logger.info('📊 [MACHINE_PROCESSOR] ${workPoints.length} pontos de trabalho extraídos');
      
      // Calcular estatísticas
      final statistics = _calculateStatistics(workPoints);
      Logger.info('📈 [MACHINE_PROCESSOR] Estatísticas calculadas');
      
      // Calcular área total
      final totalArea = _calculateTotalArea(workPoints);
      Logger.info('📐 [MACHINE_PROCESSOR] Área total: ${totalArea.toStringAsFixed(2)} ha');
      
      // Calcular volume total
      final totalVolume = _calculateTotalVolume(workPoints);
      Logger.info('💧 [MACHINE_PROCESSOR] Volume total: ${totalVolume.toStringAsFixed(2)} L');
      
      // Calcular taxa média
      final averageRate = _calculateAverageRate(workPoints);
      Logger.info('⚖️ [MACHINE_PROCESSOR] Taxa média: ${averageRate.toStringAsFixed(2)} kg/ha');
      
      // Calcular velocidade média
      final averageSpeed = _calculateAverageSpeed(workPoints);
      Logger.info('🚜 [MACHINE_PROCESSOR] Velocidade média: ${averageSpeed.toStringAsFixed(2)} km/h');
      
      // Criar faixas de valores
      final valueRanges = _createValueRanges(workPoints, totalArea);
      Logger.info('🎨 [MACHINE_PROCESSOR] ${valueRanges.length} faixas de valores criadas');
      
      // Extrair metadados
      final metadata = _extractMetadata(geoJSONData);
      
      final machineData = MachineWorkData(
        id: metadata['id'] ?? 'machine_${DateTime.now().millisecondsSinceEpoch}',
        machineName: metadata['machineName'] ?? 'Máquina Desconhecida',
        applicationType: metadata['applicationType'] ?? 'Aplicação',
        workDate: metadata['workDate'] ?? DateTime.now(),
        points: workPoints,
        totalArea: totalArea,
        totalVolume: totalVolume,
        averageRate: averageRate,
        averageSpeed: averageSpeed,
        statistics: statistics,
        valueRanges: valueRanges,
      );
      
      Logger.info('✅ [MACHINE_PROCESSOR] Processamento concluído com sucesso');
      return machineData;
      
    } catch (e) {
      Logger.error('❌ [MACHINE_PROCESSOR] Erro no processamento: $e');
      rethrow;
    }
  }
  
  /// Extrai pontos de trabalho do GeoJSON
  static List<WorkPoint> _extractWorkPoints(GeoJSONData geoJSONData) {
    final points = <WorkPoint>[];
    
    for (final feature in geoJSONData.features) {
      if (feature.geometry == null) continue;
      
      final geometry = feature.geometry!;
      final properties = feature.properties;
      
      switch (geometry['type']) {
        case 'Point':
          final coordinates = geometry['coordinates'] as List;
          if (coordinates.length >= 2) {
            final point = WorkPoint(
              latitude: coordinates[1].toDouble(),
              longitude: coordinates[0].toDouble(),
              applicationRate: _parseDouble(properties['rate']) ?? 
                             _parseDouble(properties['dose']) ?? 
                             _parseDouble(properties['RATE']) ?? 
                             _parseDouble(properties['DOSE']) ?? 0.0,
              speed: _parseDouble(properties['speed']) ?? 
                     _parseDouble(properties['velocidade']) ?? 
                     _parseDouble(properties['SPEED']) ?? 
                     _parseDouble(properties['VELOCIDADE']) ?? 0.0,
              volume: _parseDouble(properties['volume']) ?? 
                      _parseDouble(properties['VOLUME']) ?? 0.0,
              timestamp: _parseDateTime(properties['timestamp']) ?? 
                        _parseDateTime(properties['data']) ?? 
                        _parseDateTime(properties['DATE']) ?? 
                        DateTime.now(),
              additionalData: properties,
            );
            points.add(point);
          }
          break;
          
        case 'LineString':
          final coordinates = geometry['coordinates'] as List;
          for (int i = 0; i < coordinates.length; i++) {
            final coord = coordinates[i] as List;
            if (coord.length >= 2) {
              final point = WorkPoint(
                latitude: coord[1].toDouble(),
                longitude: coord[0].toDouble(),
                applicationRate: _parseDouble(properties['rate']) ?? 
                               _parseDouble(properties['dose']) ?? 0.0,
                speed: _parseDouble(properties['speed']) ?? 
                       _parseDouble(properties['velocidade']) ?? 0.0,
                volume: _parseDouble(properties['volume']) ?? 0.0,
                timestamp: _parseDateTime(properties['timestamp']) ?? 
                          DateTime.now().add(Duration(seconds: i)),
                additionalData: properties,
              );
              points.add(point);
            }
          }
          break;
          
        case 'Polygon':
          final coordinates = geometry['coordinates'] as List;
          if (coordinates.isNotEmpty) {
            final ring = coordinates[0] as List;
            for (int i = 0; i < ring.length; i++) {
              final coord = ring[i] as List;
              if (coord.length >= 2) {
                final point = WorkPoint(
                  latitude: coord[1].toDouble(),
                  longitude: coord[0].toDouble(),
                  applicationRate: _parseDouble(properties['rate']) ?? 
                                 _parseDouble(properties['dose']) ?? 0.0,
                  speed: _parseDouble(properties['speed']) ?? 
                         _parseDouble(properties['velocidade']) ?? 0.0,
                  volume: _parseDouble(properties['volume']) ?? 0.0,
                  timestamp: _parseDateTime(properties['timestamp']) ?? 
                            DateTime.now().add(Duration(seconds: i)),
                  additionalData: properties,
                );
                points.add(point);
              }
            }
          }
          break;
      }
    }
    
    return points;
  }
  
  /// Calcula estatísticas dos pontos
  static Map<String, dynamic> _calculateStatistics(List<WorkPoint> points) {
    if (points.isEmpty) return {};
    
    final rates = points.map((p) => p.applicationRate).toList();
    final speeds = points.map((p) => p.speed).toList();
    final volumes = points.map((p) => p.volume).toList();
    
    rates.sort();
    speeds.sort();
    volumes.sort();
    
    return {
      'totalPoints': points.length,
      'rateStats': {
        'min': rates.first,
        'max': rates.last,
        'mean': rates.reduce((a, b) => a + b) / rates.length,
        'median': _calculateMedian(rates),
        'stdDev': _calculateStandardDeviation(rates),
      },
      'speedStats': {
        'min': speeds.first,
        'max': speeds.last,
        'mean': speeds.reduce((a, b) => a + b) / speeds.length,
        'median': _calculateMedian(speeds),
        'stdDev': _calculateStandardDeviation(speeds),
      },
      'volumeStats': {
        'min': volumes.first,
        'max': volumes.last,
        'mean': volumes.reduce((a, b) => a + b) / volumes.length,
        'median': _calculateMedian(volumes),
        'stdDev': _calculateStandardDeviation(volumes),
      },
    };
  }
  
  /// Calcula área total baseada nos pontos
  static double _calculateTotalArea(List<WorkPoint> points) {
    if (points.length < 3) return 0.0;
    
    // Usar algoritmo de Shoelace para calcular área do polígono
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    // Converter para hectares (aproximação)
    return (area.abs() / 2.0) * 111000 * 111000 / 10000; // m² para ha
  }
  
  /// Calcula volume total aplicado
  static double _calculateTotalVolume(List<WorkPoint> points) {
    return points.fold(0.0, (sum, point) => sum + point.volume);
  }
  
  /// Calcula taxa média de aplicação
  static double _calculateAverageRate(List<WorkPoint> points) {
    if (points.isEmpty) return 0.0;
    return points.fold(0.0, (sum, point) => sum + point.applicationRate) / points.length;
  }
  
  /// Calcula velocidade média
  static double _calculateAverageSpeed(List<WorkPoint> points) {
    if (points.isEmpty) return 0.0;
    return points.fold(0.0, (sum, point) => sum + point.speed) / points.length;
  }
  
  /// Cria faixas de valores para legenda
  static List<ValueRange> _createValueRanges(List<WorkPoint> points, double totalArea) {
    if (points.isEmpty) return [];
    
    final rates = points.map((p) => p.applicationRate).toList();
    rates.sort();
    
    // Criar 5 faixas de valores
    final numRanges = 5;
    final minRate = rates.first;
    final maxRate = rates.last;
    final rangeSize = (maxRate - minRate) / numRanges;
    
    final ranges = <ValueRange>[];
    final colors = [
      ThermalColors.red,
      ThermalColors.orange,
      ThermalColors.yellow,
      ThermalColors.lightGreen,
      ThermalColors.green,
    ];
    
    for (int i = 0; i < numRanges; i++) {
      final rangeMin = minRate + (i * rangeSize);
      final rangeMax = i == numRanges - 1 ? maxRate : minRate + ((i + 1) * rangeSize);
      
      // Contar pontos nesta faixa
      final pointsInRange = points.where((p) => 
        p.applicationRate >= rangeMin && p.applicationRate < rangeMax
      ).length;
      
      // Calcular área aproximada desta faixa
      final rangeArea = (pointsInRange / points.length) * totalArea;
      final rangePercentage = (rangeArea / totalArea) * 100;
      
      ranges.add(ValueRange(
        minValue: rangeMin,
        maxValue: rangeMax,
        color: colors[i],
        area: rangeArea,
        percentage: rangePercentage,
        pointCount: pointsInRange,
      ));
    }
    
    return ranges;
  }
  
  /// Extrai metadados do GeoJSON
  static Map<String, dynamic> _extractMetadata(GeoJSONData geoJSONData) {
    final metadata = <String, dynamic>{};
    
    if (geoJSONData.features.isNotEmpty) {
      final firstFeature = geoJSONData.features.first;
      final properties = firstFeature.properties;
      
      metadata['id'] = firstFeature.id;
      metadata['machineName'] = properties['machine'] ?? 
                               properties['maquina'] ?? 
                               properties['MACHINE'] ?? 
                               'Máquina Desconhecida';
      metadata['applicationType'] = properties['application'] ?? 
                                   properties['aplicacao'] ?? 
                                   properties['APPLICATION'] ?? 
                                   'Aplicação';
      metadata['workDate'] = _parseDateTime(properties['date']) ?? 
                            _parseDateTime(properties['data']) ?? 
                            _parseDateTime(properties['DATE']) ?? 
                            DateTime.now();
    }
    
    return metadata;
  }
  
  /// Converte valor para double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Converte valor para DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  /// Calcula mediana
  static double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
  }
  
  /// Calcula desvio padrão
  static double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
}
