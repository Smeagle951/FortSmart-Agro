import 'package:flutter/material.dart';

enum PlotStatusLevel { ok, warning, critical }

class PlotStatus {
  final String id;
  final String name;
  final String cropType;
  final double area;
  final String coordinates; // GeoJSON format
  final int criticalCount;
  final int warningCount;
  final int okCount;
  final String? status;
  final String? plotId; // ID do talhão relacionado
  final String? color; // Cor personalizada para o talhão
  
  PlotStatus({
    required this.id,
    required this.name,
    required this.cropType,
    required this.area,
    required this.coordinates,
    required this.criticalCount,
    required this.warningCount,
    required this.okCount,
    this.status,
    this.plotId,
    this.color,
  });
  
  PlotStatusLevel get statusLevel {
    if (criticalCount > 0) {
      return PlotStatusLevel.critical;
    } else if (warningCount > 0) {
      return PlotStatusLevel.warning;
    } else {
      return PlotStatusLevel.ok;
    }
  }
  
  Color get statusColor {
    switch (statusLevel) {
      case PlotStatusLevel.critical:
        return Colors.red;
      case PlotStatusLevel.warning:
        return Colors.orange;
      case PlotStatusLevel.ok:
        return Colors.green;
    }
  }
  
  String get statusText {
    switch (statusLevel) {
      case PlotStatusLevel.critical:
        return 'Crítico';
      case PlotStatusLevel.warning:
        return 'Atenção';
      case PlotStatusLevel.ok:
        return 'OK';
    }
  }
  
  static PlotStatus fromMap(Map<String, dynamic> map) {
    return PlotStatus(
      id: map['id'],
      name: map['name'],
      cropType: map['crop_type'],
      area: map['area'],
      coordinates: map['coordinates'],
      criticalCount: map['critical_count'] ?? 0,
      warningCount: map['warning_count'] ?? 0,
      okCount: map['ok_count'] ?? 0,
    );
  }
}
