import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'sync_metadata.dart';
import 'sync_operation.dart';
import 'sync_module.dart';

/// Classe que representa um lote de sincronização
class SyncBatch {
  final String id;
  final SyncModule module;
  final List<SyncOperation> operations;
  final int pendingCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final SyncBatchStatus status;
  final Map<String, dynamic>? metadata;

  const SyncBatch({
    required this.id,
    required this.module,
    required this.operations,
    required this.pendingCount,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.status = SyncBatchStatus.pending,
    this.metadata,
  });

  /// Cria um novo lote de sincronização
  factory SyncBatch.create({
    required SyncModule module,
    required List<SyncOperation> operations,
    Map<String, dynamic>? metadata,
  }) {
    return SyncBatch(
      id: const Uuid().v4(),
      module: module,
      operations: operations,
      pendingCount: operations.length,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Marca o lote como iniciado
  SyncBatch markAsStarted() {
    return copyWith(
      startedAt: DateTime.now(),
      status: SyncBatchStatus.processing,
    );
  }

  /// Marca o lote como concluído
  SyncBatch markAsCompleted() {
    return copyWith(
      completedAt: DateTime.now(),
      status: SyncBatchStatus.completed,
    );
  }

  /// Marca o lote como falhou
  SyncBatch markAsFailed() {
    return copyWith(
      completedAt: DateTime.now(),
      status: SyncBatchStatus.failed,
    );
  }

  /// Marca o lote como cancelado
  SyncBatch markAsCancelled() {
    return copyWith(
      completedAt: DateTime.now(),
      status: SyncBatchStatus.cancelled,
    );
  }

  /// Cria uma cópia com alterações
  SyncBatch copyWith({
    String? id,
    SyncModule? module,
    List<SyncOperation>? operations,
    int? pendingCount,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncBatchStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return SyncBatch(
      id: id ?? this.id,
      module: module ?? this.module,
      operations: operations ?? this.operations,
      pendingCount: pendingCount ?? this.pendingCount,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Verifica se o lote está em processamento
  bool get isProcessing => status == SyncBatchStatus.processing;

  /// Verifica se o lote foi concluído
  bool get isCompleted => status == SyncBatchStatus.completed;

  /// Verifica se o lote falhou
  bool get isFailed => status == SyncBatchStatus.failed;

  /// Verifica se o lote foi cancelado
  bool get isCancelled => status == SyncBatchStatus.cancelled;

  /// Obtém a duração do processamento
  Duration? get processingDuration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  /// Obtém o progresso do lote (0.0 a 1.0)
  double get progress {
    if (operations.isEmpty) return 1.0;
    final completedOperations = operations.where((op) => op.isCompleted).length;
    return completedOperations / operations.length;
  }

  /// Obtém estatísticas do lote
  SyncBatchStats get stats {
    final completed = operations.where((op) => op.isCompleted).length;
    final failed = operations.where((op) => op.isFailed).length;
    final pending = operations.where((op) => op.isPending).length;

    return SyncBatchStats(
      total: operations.length,
      completed: completed,
      failed: failed,
      pending: pending,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.name,
      'operations': operations.map((op) => op.toMap()).toList(),
      'pendingCount': pendingCount,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  /// Cria a partir de Map
  factory SyncBatch.fromMap(Map<String, dynamic> map) {
    return SyncBatch(
      id: map['id'] ?? '',
      module: SyncModule.values.firstWhere(
        (e) => e.name == map['module'],
        orElse: () => SyncModule.talhoes,
      ),
      operations: (map['operations'] as List<dynamic>?)
          ?.map((op) => SyncOperation.fromMap(op))
          .toList() ?? [],
      pendingCount: map['pendingCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      status: SyncBatchStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncBatchStatus.pending,
      ),
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    );
  }

  @override
  String toString() {
    return 'SyncBatch(id: $id, module: $module, operations: ${operations.length}, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncBatch && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum que representa o status de um lote
enum SyncBatchStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled
}

/// Estatísticas de um lote de sincronização
class SyncBatchStats {
  final int total;
  final int completed;
  final int failed;
  final int pending;

  const SyncBatchStats({
    required this.total,
    required this.completed,
    required this.failed,
    required this.pending,
  });

  /// Taxa de sucesso (0.0 a 1.0)
  double get successRate {
    if (total == 0) return 0.0;
    return completed / total;
  }

  /// Taxa de falha (0.0 a 1.0)
  double get failureRate {
    if (total == 0) return 0.0;
    return failed / total;
  }

  @override
  String toString() {
    return 'SyncBatchStats(total: $total, completed: $completed, failed: $failed, pending: $pending, successRate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}
