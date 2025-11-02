import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/talhao_model.dart';
import '../../models/cultura_model.dart';
import '../../models/monitoring.dart';
import '../../models/monitoring_point.dart';
import 'monitoring_constants.dart';

/// Funções auxiliares para o módulo de monitoramento
class MonitoringHelpers {
  
  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    final lat1Rad = point1.latitude * (pi / 180);
    final lat2Rad = point2.latitude * (pi / 180);
    final deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final deltaLonRad = (point2.longitude - point1.longitude) * (pi / 180);
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calcula a área de um polígono em hectares
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() / 2.0;
    
    // Converter para hectares (aproximadamente)
    // Esta é uma aproximação simples, para maior precisão use bibliotecas especializadas
    return area * 111320 * 111320 / 10000; // 1 grau ≈ 111.32 km
  }
  
  /// Formata área para exibição
  static String formatArea(double areaInHectares) {
    if (areaInHectares < 1) {
      return '${(areaInHectares * 10000).toStringAsFixed(0)} m²';
    } else if (areaInHectares < 100) {
      return '${areaInHectares.toStringAsFixed(2)} ha';
    } else {
      return '${areaInHectares.toStringAsFixed(1)} ha';
    }
  }
  
  /// Formata coordenadas para exibição
  static String formatCoordinates(LatLng coordinates) {
    final lat = coordinates.latitude.toStringAsFixed(6);
    final lng = coordinates.longitude.toStringAsFixed(6);
    return '$lat, $lng';
  }
  
  /// Formata data para exibição
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  /// Formata data e hora para exibição
  static String formatDateTime(DateTime dateTime) {
    final date = formatDate(dateTime);
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
  
  /// Obtém cor baseada na severidade
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'baixa':
        return Colors.green;
      case 'média':
        return Colors.yellow;
      case 'alta':
        return Colors.orange;
      case 'crítica':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  /// Obtém cor baseada no tipo de cultura
  static Color getCulturaColor(String? culturaName) {
    if (culturaName == null) return Colors.grey;
    
    final name = culturaName.toLowerCase();
    if (name.contains('soja')) return Colors.green;
    if (name.contains('milho')) return Colors.yellow;
    if (name.contains('algodão') || name.contains('algodao')) return Colors.orange;
    if (name.contains('café') || name.contains('cafe')) return Colors.brown;
    if (name.contains('cana')) return Colors.lightGreen;
    
    return Colors.grey;
  }
  
  /// Obtém ícone baseado no tipo de cultura
  static IconData getCulturaIcon(String? culturaName) {
    if (culturaName == null) return Icons.agriculture;
    
    final name = culturaName.toLowerCase();
    if (name.contains('soja')) return Icons.grass;
    if (name.contains('milho')) return Icons.eco;
    if (name.contains('algodão') || name.contains('algodao')) return Icons.local_florist;
    if (name.contains('café') || name.contains('cafe')) return Icons.local_cafe;
    if (name.contains('cana')) return Icons.forest;
    
    return Icons.agriculture;
  }
  
  /// Calcula estatísticas de monitoramento
  static Map<String, dynamic> calculateMonitoringStats(List<Monitoring> monitorings) {
    if (monitorings.isEmpty) {
      return {
        'total': 0,
        'completos': 0,
        'pendentes': 0,
        'sincronizados': 0,
        'areaTotal': 0.0,
        'tempoMedio': 0.0,
      };
    }
    
    int total = monitorings.length;
    int completos = monitorings.where((m) => m.isCompleted).length;
    int pendentes = total - completos;
    int sincronizados = monitorings.where((m) => m.isSynced).length;
    
    double areaTotal = 0.0;
    double tempoTotal = 0.0;
    int monitoringsComTempo = 0;
    
    for (final monitoring in monitorings) {
      if (monitoring.points.isNotEmpty) {
        // Calcular área aproximada baseada nos pontos
        final points = monitoring.points
            .where((p) => p.latitude != null && p.longitude != null)
            .map((p) => LatLng(p.latitude!, p.longitude!))
            .toList();
        
        if (points.length >= 3) {
          areaTotal += calculatePolygonArea(points);
        }
      }
      
      // Calcular tempo médio (se disponível)
      if (monitoring.date != null) {
        final now = DateTime.now();
        final duration = now.difference(monitoring.date!);
        tempoTotal += duration.inMinutes;
        monitoringsComTempo++;
      }
    }
    
    double tempoMedio = monitoringsComTempo > 0 ? tempoTotal / monitoringsComTempo : 0.0;
    
    return {
      'total': total,
      'completos': completos,
      'pendentes': pendentes,
      'sincronizados': sincronizados,
      'areaTotal': areaTotal,
      'tempoMedio': tempoMedio,
      'percentualCompletos': total > 0 ? (completos / total) * 100 : 0.0,
      'percentualSincronizados': total > 0 ? (sincronizados / total) * 100 : 0.0,
    };
  }
  
  /// Filtra monitoramentos por critérios
  static List<Monitoring> filterMonitorings(
    List<Monitoring> monitorings, {
    String? culturaId,
    String? talhaoId,
    DateTime? startDate,
    DateTime? endDate,
    String? severity,
    bool? isCompleted,
    bool? isSynced,
  }) {
    return monitorings.where((monitoring) {
      // Filtro por cultura
      if (culturaId != null && monitoring.cropId != culturaId) {
        return false;
      }
      
      // Filtro por talhão
      if (talhaoId != null && monitoring.plotId != talhaoId) {
        return false;
      }
      
      // Filtro por data
      if (startDate != null && monitoring.date != null) {
        if (monitoring.date!.isBefore(startDate)) {
          return false;
        }
      }
      
      if (endDate != null && monitoring.date != null) {
        if (monitoring.date!.isAfter(endDate)) {
          return false;
        }
      }
      
      // Filtro por severidade
      if (severity != null && monitoring.severity != severity) {
        return false;
      }
      
      // Filtro por status de conclusão
      if (isCompleted != null && monitoring.isCompleted != isCompleted) {
        return false;
      }
      
      // Filtro por status de sincronização
      if (isSynced != null && monitoring.isSynced != isSynced) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  /// Ordena monitoramentos por critério
  static List<Monitoring> sortMonitorings(
    List<Monitoring> monitorings, {
    String sortBy = 'date',
    bool ascending = false,
  }) {
    final sorted = List<Monitoring>.from(monitorings);
    
    switch (sortBy.toLowerCase()) {
      case 'date':
        sorted.sort((a, b) {
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return ascending ? a.date!.compareTo(b.date!) : b.date!.compareTo(a.date!);
        });
        break;
        
      case 'severity':
        sorted.sort((a, b) {
          final severityOrder = {'baixa': 1, 'média': 2, 'alta': 3, 'crítica': 4};
          final aOrder = severityOrder[a.severity?.toLowerCase()] ?? 0;
          final bOrder = severityOrder[b.severity?.toLowerCase()] ?? 0;
          return ascending ? aOrder.compareTo(bOrder) : bOrder.compareTo(aOrder);
        });
        break;
        
      case 'area':
        sorted.sort((a, b) {
          final aArea = _calculateMonitoringArea(a);
          final bArea = _calculateMonitoringArea(b);
          return ascending ? aArea.compareTo(bArea) : bArea.compareTo(aArea);
        });
        break;
        
      case 'status':
        sorted.sort((a, b) {
          if (a.isCompleted == b.isCompleted) return 0;
          return ascending ? (a.isCompleted ? 1 : -1) : (a.isCompleted ? -1 : 1);
        });
        break;
    }
    
    return sorted;
  }
  
  /// Calcula área aproximada de um monitoramento
  static double _calculateMonitoringArea(Monitoring monitoring) {
    if (monitoring.points.isEmpty) return 0.0;
    
    final points = monitoring.points
        .where((p) => p.latitude != null && p.longitude != null)
        .map((p) => LatLng(p.latitude!, p.longitude!))
        .toList();
    
    if (points.length < 3) return 0.0;
    
    return calculatePolygonArea(points);
  }
  
  /// Valida coordenadas
  static bool isValidCoordinates(LatLng coordinates) {
    return coordinates.latitude >= -90 &&
           coordinates.latitude <= 90 &&
           coordinates.longitude >= -180 &&
           coordinates.longitude <= 180;
  }
  
  /// Converte string para coordenadas
  static LatLng? parseCoordinates(String coordinates) {
    try {
      final parts = coordinates.split(',');
      if (parts.length != 2) return null;
      
      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());
      
      final latLng = LatLng(lat, lng);
      return isValidCoordinates(latLng) ? latLng : null;
    } catch (e) {
      return null;
    }
  }
  
  /// Gera ID único para monitoramento
  static String generateMonitoringId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (1000 + (timestamp % 9000)).toString();
    return 'mon_${timestamp}_$random';
  }
  
  /// Formata duração para exibição
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}min';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  /// Calcula tempo decorrido desde uma data
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dia${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Agora mesmo';
    }
  }
}

// Constantes matemáticas
const double pi = 3.14159265359;
