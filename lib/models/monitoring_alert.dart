import 'dart:convert';

/// Modelo para representar um alerta de monitoramento
class MonitoringAlert {
  final String id;
  final String title;
  final String message;
  final String type; // 'critical', 'warning', 'info'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String? fieldId;
  final String? cropId;
  final String? organismId;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  MonitoringAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    this.fieldId,
    this.cropId,
    this.organismId,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory MonitoringAlert.fromMap(Map<String, dynamic> map) {
    return MonitoringAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'info',
      severity: map['severity'] ?? 'low',
      fieldId: map['field_id'],
      cropId: map['crop_id'],
      organismId: map['organism_id'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'severity': severity,
      'field_id': fieldId,
      'crop_id': cropId,
      'organism_id': organismId,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory MonitoringAlert.fromJson(String source) => MonitoringAlert.fromMap(json.decode(source));

  /// Obtém a cor baseada na severidade
  String get color {
    switch (severity) {
      case 'critical':
        return '#9C27B0'; // Roxo
      case 'high':
        return '#F44336'; // Vermelho
      case 'medium':
        return '#FF9800'; // Laranja
      case 'low':
        return '#4CAF50'; // Verde
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Obtém o ícone baseado no tipo
  String get icon {
    switch (type) {
      case 'critical':
        return '🚨';
      case 'warning':
        return '⚠️';
      case 'info':
        return 'ℹ️';
      default:
        return '📢';
    }

  }

  /// Marca como lido
  MonitoringAlert markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  MonitoringAlert copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? severity,
    String? fieldId,
    String? cropId,
    String? organismId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return MonitoringAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      fieldId: fieldId ?? this.fieldId,
      cropId: cropId ?? this.cropId,
      organismId: organismId ?? this.organismId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  String toString() {
    return 'MonitoringAlert(id: $id, title: $title, message: $message, type: $type, severity: $severity, fieldId: $fieldId, cropId: $cropId, organismId: $organismId, data: $data, isRead: $isRead, createdAt: $createdAt, readAt: $readAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonitoringAlert &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.severity == severity &&
        other.fieldId == fieldId &&
        other.cropId == cropId &&
        other.organismId == organismId &&
        other.data == data &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        message.hashCode ^
        type.hashCode ^
        severity.hashCode ^
        fieldId.hashCode ^
        cropId.hashCode ^
        organismId.hashCode ^
        data.hashCode ^
        isRead.hashCode ^
        createdAt.hashCode ^
        readAt.hashCode;
  }
}
