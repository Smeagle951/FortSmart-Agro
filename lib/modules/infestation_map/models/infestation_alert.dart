import 'alert_status.dart';

/// Modelo para representar alertas de infestação
class InfestationAlert {
  final String id;
  final String talhaoId;
  final String organismoId;
  final String level;
  final String riskLevel;
  final double priorityScore;
  final String message;
  final String description;
  final String origin;
  final DateTime createdAt;
  final AlertStatus status;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String notes;
  final Map<String, dynamic> metadata;

  const InfestationAlert({
    required this.id,
    required this.talhaoId,
    required this.organismoId,
    required this.level,
    required this.riskLevel,
    required this.priorityScore,
    required this.message,
    required this.description,
    this.origin = 'auto',
    required this.createdAt,
    this.status = AlertStatus.active,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolvedBy,
    this.notes = '',
    this.metadata = const {},
  });

  /// Cria uma instância a partir de um Map (ex: resultado do banco)
  factory InfestationAlert.fromMap(Map<String, dynamic> map) {
    return InfestationAlert(
      id: map['id'] as String,
      talhaoId: map['talhao_id'] as String,
      organismoId: map['organismo_id'] as String,
      level: map['level'] as String,
      riskLevel: map['risk_level'] as String? ?? 'médio',
      priorityScore: (map['priority_score'] as num?)?.toDouble() ?? 0.0,
      message: map['message'] as String? ?? '',
      description: map['description'] as String,
      origin: map['origin'] as String? ?? 'auto',
      createdAt: DateTime.parse(map['created_at'] as String),
      status: AlertStatus.fromString(map['status'] as String? ?? 'ativo'),
      acknowledgedAt: map['acknowledged_at'] != null 
          ? DateTime.parse(map['acknowledged_at'] as String) 
          : null,
      acknowledgedBy: map['acknowledged_by'] as String?,
      resolvedAt: map['resolved_at'] != null 
          ? DateTime.parse(map['resolved_at'] as String) 
          : null,
      resolvedBy: map['resolved_by'] as String?,
      notes: map['notes'] as String? ?? '',
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converte para Map (ex: para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'organismo_id': organismoId,
      'level': level,
      'risk_level': riskLevel,
      'priority_score': priorityScore,
      'message': message,
      'description': description,
      'origin': origin,
      'created_at': createdAt.toIso8601String(),
      'status': status.toString(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Cria uma cópia com campos atualizados
  InfestationAlert copyWith({
    String? id,
    String? talhaoId,
    String? organismoId,
    String? level,
    String? riskLevel,
    double? priorityScore,
    String? message,
    String? description,
    String? origin,
    DateTime? createdAt,
    AlertStatus? status,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return InfestationAlert(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      organismoId: organismoId ?? this.organismoId,
      level: level ?? this.level,
      riskLevel: riskLevel ?? this.riskLevel,
      priorityScore: priorityScore ?? this.priorityScore,
      message: message ?? this.message,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Cria uma instância vazia para uso em comparações
  factory InfestationAlert.empty() {
    return InfestationAlert(
      id: '',
      talhaoId: '',
      organismoId: '',
      level: '',
      riskLevel: '',
      priorityScore: 0.0,
      message: '',
      description: '',
      createdAt: DateTime.now(),
    );
  }

  /// Verifica se o alerta foi reconhecido
  bool get isAcknowledged => acknowledgedAt != null;

  /// Verifica se o alerta é crítico
  bool get isCritical => level == 'CRITICO';

  /// Verifica se o alerta é de alto risco
  bool get isHighRisk => level == 'ALTO' || level == 'CRITICO';

  @override
  String toString() {
    return 'InfestationAlert(id: $id, talhaoId: $talhaoId, level: $level, '
           'riskLevel: $riskLevel, status: $status, isAcknowledged: $isAcknowledged)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfestationAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
