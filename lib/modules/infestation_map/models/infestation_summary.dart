/// Modelo para representar o resumo de infestação por talhão/organismo
class InfestationSummary {
  final String id;
  final String talhaoId;
  final String organismoId;
  final String talhaoName;
  final String organismName;
  final DateTime periodoIni;
  final DateTime periodoFim;
  final double avgInfestation;
  final double infestationPercentage;
  final String level;
  final DateTime lastUpdate;
  final DateTime? lastMonitoringDate;
  final String? trend;
  final String? severity;
  final String? heatGeoJson;
  final int totalPoints;
  final int pointsWithOccurrence;

  const InfestationSummary({
    required this.id,
    required this.talhaoId,
    required this.organismoId,
    this.talhaoName = '',
    this.organismName = '',
    required this.periodoIni,
    required this.periodoFim,
    required this.avgInfestation,
    required this.infestationPercentage,
    required this.level,
    required this.lastUpdate,
    this.lastMonitoringDate,
    this.trend,
    this.severity,
    this.heatGeoJson,
    this.totalPoints = 0,
    this.pointsWithOccurrence = 0,
  });

  /// Cria uma instância a partir de um Map (ex: resultado do banco)
  factory InfestationSummary.fromMap(Map<String, dynamic> map) {
    return InfestationSummary(
      id: map['id'] as String,
      talhaoId: map['talhao_id'] as String,
      organismoId: map['organismo_id'] as String,
      talhaoName: map['talhao_name'] as String? ?? '',
      organismName: map['organism_name'] as String? ?? '',
      periodoIni: DateTime.parse(map['periodo_ini'] as String),
      periodoFim: DateTime.parse(map['periodo_fim'] as String),
      avgInfestation: (map['avg_infestation'] as num).toDouble(),
      infestationPercentage: (map['infestation_percentage'] as num?)?.toDouble() ?? 0.0,
      level: map['level'] as String,
      lastUpdate: DateTime.parse(map['last_update'] as String),
      lastMonitoringDate: map['last_monitoring_date'] != null 
          ? DateTime.parse(map['last_monitoring_date'] as String) 
          : null,
      trend: map['trend'] as String?,
      severity: map['severity'] as String?,
      heatGeoJson: map['heat_geojson'] as String?,
      totalPoints: map['total_points'] as int? ?? 0,
      pointsWithOccurrence: map['points_with_occurrence'] as int? ?? 0,
    );
  }

  /// Converte para Map (ex: para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'organismo_id': organismoId,
      'talhao_name': talhaoName,
      'organism_name': organismName,
      'periodo_ini': periodoIni.toIso8601String(),
      'periodo_fim': periodoFim.toIso8601String(),
      'avg_infestation': avgInfestation,
      'infestation_percentage': infestationPercentage,
      'level': level,
      'last_update': lastUpdate.toIso8601String(),
      'last_monitoring_date': lastMonitoringDate?.toIso8601String(),
      'trend': trend,
      'severity': severity,
      'heat_geojson': heatGeoJson,
      'total_points': totalPoints,
      'points_with_occurrence': pointsWithOccurrence,
    };
  }

  /// Cria uma cópia com campos atualizados
  InfestationSummary copyWith({
    String? id,
    String? talhaoId,
    String? organismoId,
    String? talhaoName,
    String? organismName,
    DateTime? periodoIni,
    DateTime? periodoFim,
    double? avgInfestation,
    double? infestationPercentage,
    String? level,
    DateTime? lastUpdate,
    DateTime? lastMonitoringDate,
    String? trend,
    String? severity,
    String? heatGeoJson,
    int? totalPoints,
    int? pointsWithOccurrence,
  }) {
    return InfestationSummary(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      organismoId: organismoId ?? this.organismoId,
      talhaoName: talhaoName ?? this.talhaoName,
      organismName: organismName ?? this.organismName,
      periodoIni: periodoIni ?? this.periodoIni,
      periodoFim: periodoFim ?? this.periodoFim,
      avgInfestation: avgInfestation ?? this.avgInfestation,
      infestationPercentage: infestationPercentage ?? this.infestationPercentage,
      level: level ?? this.level,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastMonitoringDate: lastMonitoringDate ?? this.lastMonitoringDate,
      trend: trend ?? this.trend,
      severity: severity ?? this.severity,
      heatGeoJson: heatGeoJson ?? this.heatGeoJson,
      totalPoints: totalPoints ?? this.totalPoints,
      pointsWithOccurrence: pointsWithOccurrence ?? this.pointsWithOccurrence,
    );
  }

  @override
  String toString() {
    return 'InfestationSummary(id: $id, talhaoId: $talhaoId, organismoId: $organismoId, '
           'avgInfestation: $avgInfestation, infestationPercentage: $infestationPercentage, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfestationSummary && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
