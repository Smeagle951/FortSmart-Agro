import 'package:uuid/uuid.dart';

/// Modelo para representar uma entrada na timeline de infestação
class InfestationTimelineModel {
  final String id;
  final String talhaoId;
  final String organismoId;
  final DateTime dataOcorrencia;
  final int quantidade;
  final String nivel;
  final double percentual;
  final double latitude;
  final double longitude;
  final String? usuarioId;
  final String? observacao;
  final String? fotoPaths;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? serverId;
  final String? lastSyncError;
  final int attemptsSync;

  InfestationTimelineModel({
    String? id,
    required this.talhaoId,
    required this.organismoId,
    required this.dataOcorrencia,
    required this.quantidade,
    required this.nivel,
    required this.percentual,
    required this.latitude,
    required this.longitude,
    this.usuarioId,
    this.observacao,
    this.fotoPaths,
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.serverId,
    this.lastSyncError,
    this.attemptsSync = 0,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'organismo_id': organismoId,
      'data_ocorrencia': dataOcorrencia.toIso8601String(),
      'quantidade': quantidade,
      'nivel': nivel,
      'percentual': percentual,
      'latitude': latitude,
      'longitude': longitude,
      'usuario_id': usuarioId,
      'observacao': observacao,
      'foto_paths': fotoPaths,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'server_id': serverId,
      'last_sync_error': lastSyncError,
      'attempts_sync': attemptsSync,
    };
  }

  /// Cria a partir de Map
  factory InfestationTimelineModel.fromMap(Map<String, dynamic> map) {
    return InfestationTimelineModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      organismoId: map['organismo_id'],
      dataOcorrencia: DateTime.parse(map['data_ocorrencia']),
      quantidade: map['quantidade'],
      nivel: map['nivel'],
      percentual: map['percentual']?.toDouble() ?? 0.0,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      usuarioId: map['usuario_id'],
      observacao: map['observacao'],
      fotoPaths: map['foto_paths'],
      syncStatus: map['sync_status'] ?? 'pending',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      serverId: map['server_id'],
      lastSyncError: map['last_sync_error'],
      attemptsSync: map['attempts_sync'] ?? 0,
    );
  }

  /// Cria a partir de InfestacaoModel
  factory InfestationTimelineModel.fromInfestacaoModel(
    Map<String, dynamic> infestacaoData,
    String organismoId,
  ) {
    return InfestationTimelineModel(
      talhaoId: infestacaoData['talhao_id'].toString(),
      organismoId: organismoId,
      dataOcorrencia: DateTime.parse(infestacaoData['data_hora']),
      quantidade: infestacaoData['percentual'],
      nivel: infestacaoData['nivel'],
      percentual: infestacaoData['percentual']?.toDouble() ?? 0.0,
      latitude: infestacaoData['latitude']?.toDouble() ?? 0.0,
      longitude: infestacaoData['longitude']?.toDouble() ?? 0.0,
      usuarioId: infestacaoData['usuario_id'],
      observacao: infestacaoData['observacao'],
      fotoPaths: infestacaoData['foto_paths'],
    );
  }

  /// Converte para JSON de sincronização
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'organismo_id': organismoId,
      'data_ocorrencia': dataOcorrencia.toIso8601String(),
      'quantidade': quantidade,
      'nivel': nivel,
      'percentual': percentual,
      'latitude': latitude,
      'longitude': longitude,
      'usuario_id': usuarioId,
      'observacao': observacao,
      'foto_paths': fotoPaths,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma cópia com alterações
  InfestationTimelineModel copyWith({
    String? id,
    String? talhaoId,
    String? organismoId,
    DateTime? dataOcorrencia,
    int? quantidade,
    String? nivel,
    double? percentual,
    double? latitude,
    double? longitude,
    String? usuarioId,
    String? observacao,
    String? fotoPaths,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverId,
    String? lastSyncError,
    int? attemptsSync,
  }) {
    return InfestationTimelineModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      organismoId: organismoId ?? this.organismoId,
      dataOcorrencia: dataOcorrencia ?? this.dataOcorrencia,
      quantidade: quantidade ?? this.quantidade,
      nivel: nivel ?? this.nivel,
      percentual: percentual ?? this.percentual,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      usuarioId: usuarioId ?? this.usuarioId,
      observacao: observacao ?? this.observacao,
      fotoPaths: fotoPaths ?? this.fotoPaths,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      attemptsSync: attemptsSync ?? this.attemptsSync,
    );
  }

  /// Retorna a cor correspondente ao nível
  String get nivelColor {
    switch (nivel.toUpperCase()) {
      case 'BAIXO':
        return '#4CAF50'; // Verde
      case 'MODERADO':
        return '#FF9800'; // Laranja
      case 'ALTO':
        return '#F44336'; // Vermelho
      case 'CRÍTICO':
        return '#9C27B0'; // Roxo
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Retorna o ícone correspondente ao nível
  String get nivelIcon {
    switch (nivel.toUpperCase()) {
      case 'BAIXO':
        return '🟢';
      case 'MODERADO':
        return '🟡';
      case 'ALTO':
        return '🟠';
      case 'CRÍTICO':
        return '🔴';
      default:
        return '⚪';
    }
  }

  @override
  String toString() {
    return 'InfestationTimelineModel(id: $id, talhao: $talhaoId, organismo: $organismoId, nivel: $nivel, data: $dataOcorrencia)';
  }
}
