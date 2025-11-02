import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Metadados de sincronização para um item
class SyncMetadata {
  final String id;
  final String entityId;
  final String entityType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final String? serverId;
  final int version;
  final bool isDeleted;
  final bool isDirty;
  final Map<String, dynamic>? metadata;

  const SyncMetadata({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.serverId,
    this.version = 1,
    this.isDeleted = false,
    this.isDirty = false,
    this.metadata,
  });

  /// Cria metadados para uma nova entidade
  factory SyncMetadata.create({
    required String entityId,
    required String entityType,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return SyncMetadata(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      createdAt: now,
      updatedAt: now,
      version: 1,
      isDirty: true,
      metadata: metadata,
    );
  }

  /// Cria metadados a partir de dados do servidor
  factory SyncMetadata.fromServer({
    required String entityId,
    required String entityType,
    required String serverId,
    required DateTime serverUpdatedAt,
    required int serverVersion,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return SyncMetadata(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      createdAt: now,
      updatedAt: now,
      syncedAt: now,
      serverId: serverId,
      version: serverVersion,
      isDirty: false,
      metadata: metadata,
    );
  }

  /// Marca como sincronizado
  SyncMetadata markAsSynced({
    required String serverId,
    required int serverVersion,
  }) {
    return copyWith(
      syncedAt: DateTime.now(),
      serverId: serverId,
      version: serverVersion,
      isDirty: false,
    );
  }

  /// Marca como modificado
  SyncMetadata markAsDirty() {
    return copyWith(
      updatedAt: DateTime.now(),
      version: version + 1,
      isDirty: true,
    );
  }

  /// Marca como deletado
  SyncMetadata markAsDeleted() {
    return copyWith(
      updatedAt: DateTime.now(),
      version: version + 1,
      isDeleted: true,
      isDirty: true,
    );
  }

  /// Cria uma cópia com alterações
  SyncMetadata copyWith({
    String? id,
    String? entityId,
    String? entityType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    String? serverId,
    int? version,
    bool? isDeleted,
    bool? isDirty,
    Map<String, dynamic>? metadata,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      serverId: serverId ?? this.serverId,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'serverId': serverId,
      'version': version,
      'isDeleted': isDeleted ? 1 : 0,
      'isDirty': isDirty ? 1 : 0,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  /// Cria a partir de Map
  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      id: map['id'] ?? '',
      entityId: map['entityId'] ?? '',
      entityType: map['entityType'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      syncedAt: map['syncedAt'] != null ? DateTime.parse(map['syncedAt']) : null,
      serverId: map['serverId'],
      version: map['version'] ?? 1,
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      isDirty: (map['isDirty'] ?? 0) == 1,
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    );
  }

  /// Verifica se precisa ser sincronizado
  bool get needsSync => isDirty || syncedAt == null;

  /// Verifica se está em conflito com dados do servidor
  bool isInConflictWith(SyncMetadata serverMetadata) {
    if (serverId != serverMetadata.serverId) return false;
    if (version >= serverMetadata.version) return false;
    return updatedAt.isAfter(serverMetadata.updatedAt);
  }

  @override
  String toString() {
    return 'SyncMetadata(id: $id, entityId: $entityId, entityType: $entityType, version: $version, isDirty: $isDirty, needsSync: $needsSync)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncMetadata && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
