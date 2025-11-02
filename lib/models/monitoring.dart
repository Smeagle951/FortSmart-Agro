import 'dart:convert';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'monitoring_point.dart';
import 'occurrence.dart';
import '../utils/enums.dart';

/// Classe que representa um monitoramento completo
class Monitoring {
  String id;
  final DateTime date;
  final int plotId;
  final String plotName;
  final String cropId;
  final String cropName;
  final String? cropType;
  final List<Map<String, dynamic>> route;
  final List<MonitoringPoint> points;
  final bool isCompleted;
  final bool isSynced;
  final int severity;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? metadata;
  
  // Campos adicionais para relatórios
  final String? technicianName;
  final String? technicianIdentification;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>>? pests;
  final List<Map<String, dynamic>>? diseases;
  final List<Map<String, dynamic>>? weeds;
  final List<String>? images;
  final String? observations;
  final String? recommendations;
  
  // Propriedades de compatibilidade
  String get status => isCompleted ? 'Concluído' : 'Ativo';
  bool get hasCriticalOccurrences => points?.any((p) => p.occurrences?.any((o) => o.intensity > 7) ?? false) ?? false;
  
  // Getters adicionais para compatibilidade
  String get farmId => plotId.toString();
  String? get cropVariety => null; // Variedade não implementada ainda
  Map<String, dynamic>? get weatherData => {
    'temperatura': 25.0,
    'umidade': 60.0,
    'pressao': 1013.25,
  };

  Monitoring({
    String? id,
    required this.date,
    required this.plotId,
    required this.plotName,
    required this.cropId,
    required this.cropName,
    this.cropType,
    required this.route,
    List<MonitoringPoint>? points,
    this.isCompleted = false,
    this.isSynced = false,
    this.severity = 0,
    DateTime? createdAt,
    this.updatedAt,
    this.metadata,
    this.technicianName,
    this.technicianIdentification,
    this.latitude,
    this.longitude,
    this.pests,
    this.diseases,
    this.weeds,
    this.images,
    this.observations,
    this.recommendations,
  })  : id = id ?? const Uuid().v4(),
        points = points ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plot_id': plotId.toString(),
      'plotName': plotName,
      'crop_id': cropId.toString(),
      'cropName': cropName,
      'cropType': cropType,
      'date': date.toIso8601String(),
      'route': jsonEncode(route),
      'isCompleted': isCompleted ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'severity': severity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'technicianName': technicianName,
      'technicianIdentification': technicianIdentification,
      'latitude': latitude,
      'longitude': longitude,
      'pests': pests != null ? jsonEncode(pests) : null,
      'diseases': diseases != null ? jsonEncode(diseases) : null,
      'weeds': weeds != null ? jsonEncode(weeds) : null,
      'images': images != null ? jsonEncode(images) : null,
      'observations': observations,
      'recommendations': recommendations,
      'sync_status': 0,
      'remote_id': null,
    };
  }

  /// Cria a partir de Map
  factory Monitoring.fromMap(Map<String, dynamic> map) {
    return Monitoring(
      id: map['id'],
      plotId: int.tryParse(map['plot_id'] ?? '0') ?? 0,
      plotName: map['plotName'] ?? '',
      cropId: map['crop_id']?.toString() ?? '0',
      cropName: map['cropName'] ?? '',
      cropType: map['cropType'],
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      route: _parseRoute(map['route']),
      points: [], // Pontos serão carregados separadamente
      isCompleted: map['isCompleted'] == 1,
      isSynced: map['isSynced'] == 1,
      severity: map['severity']?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      metadata: map['metadata'],
      technicianName: map['technicianName'],
      technicianIdentification: map['technicianIdentification'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      pests: _parseJsonList(map['pests']),
      diseases: _parseJsonList(map['diseases']),
      weeds: _parseJsonList(map['weeds']),
      images: _parseStringList(map['images']),
      observations: map['observations'],
      recommendations: map['recommendations'],
    );
  }

  /// Parse da rota
  static List<Map<String, dynamic>> _parseRoute(dynamic route) {
    if (route == null) return [];
    if (route is String) {
      try {
        final List<dynamic> parsed = jsonDecode(route);
        return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        return [];
      }
    }
    if (route is List) {
      return route.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Parse de lista JSON
  static List<Map<String, dynamic>> _parseJsonList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try {
        final List<dynamic> parsed = jsonDecode(data);
        return parsed.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        return [];
      }
    }
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Parse de lista de strings
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try {
        final List<dynamic> parsed = jsonDecode(data);
        return parsed.map((e) => e.toString()).toList();
      } catch (e) {
        return [];
      }
    }
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Calcula a severidade média baseada nos pontos
  double calculateAverageSeverity() {
    if (points.isEmpty) return 0.0;
    
    double totalSeverity = 0.0;
    int validPoints = 0;
    
    for (var point in points) {
      if (point.occurrences.isNotEmpty) {
        double pointSeverity = 0.0;
        for (var occurrence in point.occurrences) {
          pointSeverity += occurrence.infestationIndex;
        }
        totalSeverity += pointSeverity / point.occurrences.length;
        validPoints++;
      }
    }
    
    return validPoints > 0 ? totalSeverity / validPoints : 0.0;
  }

  /// Obtém estatísticas do monitoramento
  Map<String, dynamic> getStatistics() {
    final Map<String, int> organismCount = {};
    final Map<String, double> organismSeverity = {};
    
    for (var point in points) {
      for (var occurrence in point.occurrences) {
        final key = '${occurrence.type}_${occurrence.name}';
        organismCount[key] = (organismCount[key] ?? 0) + 1;
        organismSeverity[key] = (organismSeverity[key] ?? 0.0) + occurrence.infestationIndex;
      }
    }
    
    // Calcula média de severidade por organismo
    organismSeverity.forEach((key, total) {
      organismSeverity[key] = total / organismCount[key]!;
    });
    
    return {
      'total_points': points.length,
      'total_occurrences': points.fold(0, (sum, point) => sum + point.occurrences.length),
      'organism_count': organismCount,
      'organism_severity': organismSeverity,
      'average_severity': calculateAverageSeverity(),
    };
  }

  /// Cria uma cópia com alterações
  Monitoring copyWith({
    String? id,
    DateTime? date,
    int? plotId,
    String? plotName,
    String? cropId,
    String? cropName,
    String? cropType,
    List<Map<String, dynamic>>? route,
    List<MonitoringPoint>? points,
    bool? isCompleted,
    bool? isSynced,
    int? severity,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? metadata,
    String? technicianName,
    String? technicianIdentification,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>>? pests,
    List<Map<String, dynamic>>? diseases,
    List<Map<String, dynamic>>? weeds,
    List<String>? images,
    String? observations,
    String? recommendations,
  }) {
    return Monitoring(
      id: id ?? this.id,
      date: date ?? this.date,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      cropType: cropType ?? this.cropType,
      route: route ?? this.route,
      points: points ?? this.points,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      technicianName: technicianName ?? this.technicianName,
      technicianIdentification: technicianIdentification ?? this.technicianIdentification,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pests: pests ?? this.pests,
      diseases: diseases ?? this.diseases,
      weeds: weeds ?? this.weeds,
      images: images ?? this.images,
      observations: observations ?? this.observations,
      recommendations: recommendations ?? this.recommendations,
    );
  }

  @override
  String toString() {
    return 'Monitoring(id: $id, plot: $plotName, crop: $cropName, date: $date, points: ${points.length})';
  }
}
