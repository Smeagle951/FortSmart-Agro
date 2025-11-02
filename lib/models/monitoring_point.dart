import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'occurrence.dart';
import '../utils/enums.dart';

/// Classe que representa um ponto de monitoramento
class MonitoringPoint {
  final String id;
  final String? monitoringId;
  final int plotId;
  final String plotName;
  final String? cropId;
  final String? cropName;
  final double latitude;
  final double longitude;
  final List<Occurrence> occurrences;
  final List<String> imagePaths;
  final String? audioPath;
  final String? observations;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSynced;
  final String? metadata;
  final int? plantasAvaliadas;
  final double? gpsAccuracy;
  final bool isManualEntry;

  // Getter para compatibilidade
  DateTime get date => createdAt;

  MonitoringPoint({
    String? id,
    this.monitoringId,
    required this.plotId,
    required this.plotName,
    this.cropId,
    this.cropName,
    required this.latitude,
    required this.longitude,
    List<Occurrence>? occurrences,
    List<String>? imagePaths,
    this.audioPath,
    this.observations,
    DateTime? createdAt,
    this.updatedAt,
    this.isSynced = false,
    this.metadata,
    this.plantasAvaliadas,
    this.gpsAccuracy,
    this.isManualEntry = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.occurrences = occurrences ?? [],
    this.imagePaths = imagePaths ?? [],
    this.createdAt = createdAt ?? DateTime.now();

  /// Getter para quantity (compatibilidade)
  int get quantity => plantasAvaliadas ?? 0;

  /// Getter para unidade (compatibilidade)
  String get unidade => 'plantas';

  /// Getter para accuracy (compatibilidade)
  double get accuracy => gpsAccuracy ?? 0.0;

  /// Getter para collectedAt (compatibilidade)
  DateTime get collectedAt => createdAt;

  /// Getter para observacoes (compatibilidade)
  String get observacoes => observations ?? '';

  /// Getter para collectorId (compatibilidade)
  String get collectorId => id;

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monitoringId': monitoringId,
      'plotId': plotId,
      'plotName': plotName,
      'cropId': cropId,
      'cropName': cropName,
      'latitude': latitude,
      'longitude': longitude,
      'audioPath': audioPath,
      'observations': observations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'metadata': metadata,
      'plantasAvaliadas': plantasAvaliadas,
      'gpsAccuracy': gpsAccuracy,
      'isManualEntry': isManualEntry ? 1 : 0,
      'sync_status': 0,
      'remote_id': null,
    };
  }

  /// Cria a partir de Map
  factory MonitoringPoint.fromMap(Map<String, dynamic> map) {
    return MonitoringPoint(
      id: map['id'],
      monitoringId: map['monitoringId'],
      plotId: map['plotId']?.toInt() ?? 0,
      plotName: map['plotName'] ?? '',
      cropId: map['cropId']?.toInt(),
      cropName: map['cropName'],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      occurrences: [], // Ocorrências serão carregadas separadamente
      imagePaths: _parseStringList(map['imagePaths']),
      audioPath: map['audioPath'],
      observations: map['observations'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      isSynced: map['isSynced'] == 1,
      metadata: map['metadata'],
      plantasAvaliadas: map['plantasAvaliadas']?.toInt(),
      gpsAccuracy: map['gpsAccuracy']?.toDouble(),
      isManualEntry: map['isManualEntry'] == 1,
    );
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

  /// Obtém a posição como LatLng
  LatLng get position => LatLng(latitude, longitude);

  /// Calcula a severidade média do ponto
  double get averageSeverity {
    if (occurrences.isEmpty) return 0.0;
    
    double totalSeverity = 0.0;
    for (var occurrence in occurrences) {
      totalSeverity += occurrence.infestationIndex;
    }
    
    return totalSeverity / occurrences.length;
  }

  /// Obtém o nível de alerta baseado na severidade média
  AlertLevel get alertLevel {
    final severity = averageSeverity;
    
    if (severity <= 25) return AlertLevel.low;
    if (severity <= 50) return AlertLevel.medium;
    if (severity <= 75) return AlertLevel.high;
    return AlertLevel.critical;
  }

  /// Verifica se o ponto tem GPS preciso
  bool get hasAccurateGPS {
    return gpsAccuracy == null || gpsAccuracy! <= 5.0;
  }

  /// Obtém estatísticas do ponto
  Map<String, dynamic> getStatistics() {
    final Map<String, int> organismCount = {};
    final Map<String, double> organismSeverity = {};
    
    for (var occurrence in occurrences) {
      final key = '${occurrence.type}_${occurrence.name}';
      organismCount[key] = (organismCount[key] ?? 0) + 1;
      organismSeverity[key] = (organismSeverity[key] ?? 0.0) + occurrence.infestationIndex;
    }
    
    // Calcula média de severidade por organismo
    organismSeverity.forEach((key, total) {
      organismSeverity[key] = total / organismCount[key]!;
    });
    
    return {
      'total_occurrences': occurrences.length,
      'organism_count': organismCount,
      'organism_severity': organismSeverity,
      'average_severity': averageSeverity,
      'alert_level': alertLevel.toString().split('.').last,
      'has_accurate_gps': hasAccurateGPS,
      'is_manual_entry': isManualEntry,
    };
  }

  /// Cria uma cópia com alterações
  MonitoringPoint copyWith({
    String? id,
    String? monitoringId,
    int? plotId,
    String? plotName,
    String? cropId,
    String? cropName,
    double? latitude,
    double? longitude,
    List<Occurrence>? occurrences,
    List<String>? imagePaths,
    String? audioPath,
    String? observations,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? metadata,
    int? plantasAvaliadas,
    double? gpsAccuracy,
    bool? isManualEntry,
  }) {
    return MonitoringPoint(
      id: id ?? this.id,
      monitoringId: monitoringId ?? this.monitoringId,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      occurrences: occurrences ?? this.occurrences,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPath: audioPath ?? this.audioPath,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      metadata: metadata ?? this.metadata,
      plantasAvaliadas: plantasAvaliadas ?? this.plantasAvaliadas,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      isManualEntry: isManualEntry ?? this.isManualEntry,
    );
  }

  @override
  String toString() {
    return 'MonitoringPoint(id: $id, lat: $latitude, lng: $longitude, occurrences: ${occurrences.length})';
  }
}

/// Enum para níveis de alerta
enum AlertLevel {
  low,
  medium,
  high,
  critical,
}

/// Extensão para facilitar o uso dos níveis de alerta
extension AlertLevelExtension on AlertLevel {
  String get displayName {
    switch (this) {
      case AlertLevel.low:
        return 'Baixo';
      case AlertLevel.medium:
        return 'Médio';
      case AlertLevel.high:
        return 'Alto';
      case AlertLevel.critical:
        return 'Crítico';
    }
  }

  String get color {
    switch (this) {
      case AlertLevel.low:
        return '#4CAF50'; // Verde
      case AlertLevel.medium:
        return '#FF9800'; // Laranja
      case AlertLevel.high:
        return '#F44336'; // Vermelho
      case AlertLevel.critical:
        return '#9C27B0'; // Roxo
    }
  }
}
