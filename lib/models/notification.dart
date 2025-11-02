/// Tipos de eventos de notificação
enum NotificationEventType {
  displayed,
  tapped,
  dismissed
}

/// Níveis de importância para notificações
enum NotificationImportance {
  low,
  normal,
  medium,
  high,
  critical
}

/// Ações para notificações
enum NotificationAction {
  tapped,
  dismissed,
  action
}

/// Modelo para representar um evento de notificação
class NotificationEvent {
  final int id;
  final String? payload;
  final String? actionId;
  final NotificationEventType type;
  final DateTime timestamp;
  
  NotificationEvent({
    required this.id,
    this.payload,
    this.actionId,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payload': payload,
      'actionId': actionId,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
