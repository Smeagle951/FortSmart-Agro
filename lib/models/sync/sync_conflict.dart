import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'sync_metadata.dart';

/// Enum que representa o tipo de conflito
enum ConflictType {
  versionMismatch,
  concurrentModification,
  deletionConflict,
  dataIntegrity,
  serverError,
  networkError
}

/// Enum que representa a estratégia de resolução
enum ConflictResolution {
  useLocal,
  useServer,
  merge,
  manual,
  skip
}

/// Classe que representa um conflito de sincronização
class SyncConflict {
  final String id;
  final String entityId;
  final String entityType;
  final ConflictType type;
  final String description;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final SyncMetadata localMetadata;
  final SyncMetadata serverMetadata;
  final DateTime detectedAt;
  final ConflictResolution? resolution;
  final Map<String, dynamic>? resolvedData;
  final String? resolutionNotes;

  const SyncConflict({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.type,
    required this.description,
    required this.localData,
    required this.serverData,
    required this.localMetadata,
    required this.serverMetadata,
    required this.detectedAt,
    this.resolution,
    this.resolvedData,
    this.resolutionNotes,
  });

  /// Cria um conflito de versão
  factory SyncConflict.versionMismatch({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required SyncMetadata localMetadata,
    required SyncMetadata serverMetadata,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: ConflictType.versionMismatch,
      description: 'Versão local (${localMetadata.version}) é diferente da versão do servidor (${serverMetadata.version})',
      localData: localData,
      serverData: serverData,
      localMetadata: localMetadata,
      serverMetadata: serverMetadata,
      detectedAt: DateTime.now(),
    );
  }

  /// Cria um conflito de modificação concorrente
  factory SyncConflict.concurrentModification({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required SyncMetadata localMetadata,
    required SyncMetadata serverMetadata,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: ConflictType.concurrentModification,
      description: 'Modificações concorrentes detectadas - dados foram alterados localmente e no servidor',
      localData: localData,
      serverData: serverData,
      localMetadata: localMetadata,
      serverMetadata: serverMetadata,
      detectedAt: DateTime.now(),
    );
  }

  /// Cria um conflito de deleção
  factory SyncConflict.deletionConflict({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required SyncMetadata localMetadata,
    required SyncMetadata serverMetadata,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: ConflictType.deletionConflict,
      description: 'Conflito de deleção - item foi deletado localmente mas modificado no servidor',
      localData: localData,
      serverData: serverData,
      localMetadata: localMetadata,
      serverMetadata: serverMetadata,
      detectedAt: DateTime.now(),
    );
  }

  /// Cria um conflito de integridade de dados
  factory SyncConflict.dataIntegrity({
    required String entityId,
    required String entityType,
    required String description,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required SyncMetadata localMetadata,
    required SyncMetadata serverMetadata,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: ConflictType.dataIntegrity,
      description: description,
      localData: localData,
      serverData: serverData,
      localMetadata: localMetadata,
      serverMetadata: serverMetadata,
      detectedAt: DateTime.now(),
    );
  }

  /// Cria um conflito de erro do servidor
  factory SyncConflict.serverError({
    required String entityId,
    required String entityType,
    required String description,
    required Map<String, dynamic> localData,
    required SyncMetadata localMetadata,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: ConflictType.serverError,
      description: description,
      localData: localData,
      serverData: {},
      localMetadata: localMetadata,
      serverMetadata: SyncMetadata.create(entityId: entityId, entityType: entityType),
      detectedAt: DateTime.now(),
    );
  }

  /// Cria um conflito de erro de rede
  factory SyncConflict.networkError({
    required String entityId,
    required String entityType,
    required String description,
    required Map<String, dynamic> localData,
    required SyncMetadata localMetadata,
  }) {
    return SyncConflict(
      id: const Uuid().v4(),
      entityId: entityId,
      entityType: entityType,
      type: ConflictType.networkError,
      description: description,
      localData: localData,
      serverData: {},
      localMetadata: localMetadata,
      serverMetadata: SyncMetadata.create(entityId: entityId, entityType: entityType),
      detectedAt: DateTime.now(),
    );
  }

  /// Resolve o conflito
  SyncConflict resolve({
    required ConflictResolution resolution,
    Map<String, dynamic>? resolvedData,
    String? notes,
  }) {
    return copyWith(
      resolution: resolution,
      resolvedData: resolvedData,
      resolutionNotes: notes,
    );
  }

  /// Cria uma cópia com alterações
  SyncConflict copyWith({
    String? id,
    String? entityId,
    String? entityType,
    ConflictType? type,
    String? description,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? serverData,
    SyncMetadata? localMetadata,
    SyncMetadata? serverMetadata,
    DateTime? detectedAt,
    ConflictResolution? resolution,
    Map<String, dynamic>? resolvedData,
    String? resolutionNotes,
  }) {
    return SyncConflict(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      type: type ?? this.type,
      description: description ?? this.description,
      localData: localData ?? this.localData,
      serverData: serverData ?? this.serverData,
      localMetadata: localMetadata ?? this.localMetadata,
      serverMetadata: serverMetadata ?? this.serverMetadata,
      detectedAt: detectedAt ?? this.detectedAt,
      resolution: resolution ?? this.resolution,
      resolvedData: resolvedData ?? this.resolvedData,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  /// Verifica se o conflito foi resolvido
  bool get isResolved => resolution != null;

  /// Verifica se o conflito é crítico
  bool get isCritical => type == ConflictType.dataIntegrity || type == ConflictType.serverError;

  /// Obtém a prioridade do conflito (0 = mais alta, 5 = mais baixa)
  int get priority {
    switch (type) {
      case ConflictType.dataIntegrity:
        return 0;
      case ConflictType.serverError:
        return 1;
      case ConflictType.deletionConflict:
        return 2;
      case ConflictType.concurrentModification:
        return 3;
      case ConflictType.versionMismatch:
        return 4;
      case ConflictType.networkError:
        return 5;
    }
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'type': type.name,
      'description': description,
      'localData': jsonEncode(localData),
      'serverData': jsonEncode(serverData),
      'localMetadata': jsonEncode(localMetadata.toMap()),
      'serverMetadata': jsonEncode(serverMetadata.toMap()),
      'detectedAt': detectedAt.toIso8601String(),
      'resolution': resolution?.name,
      'resolvedData': resolvedData != null ? jsonEncode(resolvedData) : null,
      'resolutionNotes': resolutionNotes,
    };
  }

  /// Cria a partir de Map
  factory SyncConflict.fromMap(Map<String, dynamic> map) {
    return SyncConflict(
      id: map['id'] ?? '',
      entityId: map['entityId'] ?? '',
      entityType: map['entityType'] ?? '',
      type: ConflictType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ConflictType.versionMismatch,
      ),
      description: map['description'] ?? '',
      localData: jsonDecode(map['localData'] ?? '{}'),
      serverData: jsonDecode(map['serverData'] ?? '{}'),
      localMetadata: SyncMetadata.fromMap(jsonDecode(map['localMetadata'] ?? '{}')),
      serverMetadata: SyncMetadata.fromMap(jsonDecode(map['serverMetadata'] ?? '{}')),
      detectedAt: DateTime.parse(map['detectedAt'] ?? DateTime.now().toIso8601String()),
      resolution: map['resolution'] != null 
          ? ConflictResolution.values.firstWhere(
              (e) => e.name == map['resolution'],
              orElse: () => ConflictResolution.manual,
            )
          : null,
      resolvedData: map['resolvedData'] != null ? jsonDecode(map['resolvedData']) : null,
      resolutionNotes: map['resolutionNotes'],
    );
  }

  @override
  String toString() {
    return 'SyncConflict(id: $id, entityId: $entityId, type: $type, isResolved: $isResolved, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncConflict && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
