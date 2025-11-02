import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Enum que representa o status de uma operação
enum SyncOperationStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled
}

/// Classe que representa uma operação de sincronização
class SyncOperation {
  final String id;
  final String entityId;
  final String entityType;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final SyncOperationStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int retryCount;
  final int maxRetries;

  const SyncOperation({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.type,
    required this.data,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  /// Cria uma nova operação
  factory SyncOperation.create({
    required String entityId,
    required String entityType,
    required SyncOperationType type,
    required Map<String, dynamic> data,
  }) {
    return SyncOperation(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: type,
      data: data,
      status: SyncOperationStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// Marca a operação como iniciada
  SyncOperation markAsStarted() {
    return copyWith(
      startedAt: DateTime.now(),
      status: SyncOperationStatus.processing,
    );
  }

  /// Marca a operação como concluída
  SyncOperation markAsCompleted() {
    return copyWith(
      completedAt: DateTime.now(),
      status: SyncOperationStatus.completed,
    );
  }

  /// Marca a operação como falhou
  SyncOperation markAsFailed(String errorMessage) {
    return copyWith(
      completedAt: DateTime.now(),
      status: SyncOperationStatus.failed,
      errorMessage: errorMessage,
      retryCount: retryCount + 1,
    );
  }

  /// Marca a operação como cancelada
  SyncOperation markAsCancelled() {
    return copyWith(
      completedAt: DateTime.now(),
      status: SyncOperationStatus.cancelled,
    );
  }

  /// Cria uma cópia com alterações
  SyncOperation copyWith({
    String? id,
    String? entityId,
    String? entityType,
    SyncOperationType? type,
    Map<String, dynamic>? data,
    SyncOperationStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      type: type ?? this.type,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  /// Verifica se a operação está pendente
  bool get isPending => status == SyncOperationStatus.pending;

  /// Verifica se a operação está em processamento
  bool get isProcessing => status == SyncOperationStatus.processing;

  /// Verifica se a operação foi concluída
  bool get isCompleted => status == SyncOperationStatus.completed;

  /// Verifica se a operação falhou
  bool get isFailed => status == SyncOperationStatus.failed;

  /// Verifica se a operação foi cancelada
  bool get isCancelled => status == SyncOperationStatus.cancelled;

  /// Verifica se pode tentar novamente
  bool get canRetry => isFailed && retryCount < maxRetries;

  /// Obtém a duração da operação
  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'type': type.name,
      'data': jsonEncode(data),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
    };
  }

  /// Cria a partir de Map
  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] ?? '',
      entityId: map['entityId'] ?? '',
      entityType: map['entityType'] ?? '',
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SyncOperationType.create,
      ),
      data: jsonDecode(map['data'] ?? '{}'),
      status: SyncOperationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncOperationStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      errorMessage: map['errorMessage'],
      retryCount: map['retryCount'] ?? 0,
      maxRetries: map['maxRetries'] ?? 3,
    );
  }

  @override
  String toString() {
    return 'SyncOperation(id: $id, entityId: $entityId, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncOperation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum que representa o tipo de operação
enum SyncOperationType {
  create,
  update,
  delete,
  upsert
}
