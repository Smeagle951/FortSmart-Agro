import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Classe que representa um estande de plantas
class EstandeModel {
  final String id;
  final String talhaoId;
  final DateTime data;
  final int populacao;
  final double percentualGerminacao;
  final String estadioFenologico;
  final int diasAposEmergencia; // DAE
  final String? observacoes;
  final DateTime createdAt;
  final DateTime updatedAt;

  EstandeModel({
    String? id,
    required this.talhaoId,
    required this.data,
    required this.populacao,
    required this.percentualGerminacao,
    required this.estadioFenologico,
    required this.diasAposEmergencia,
    this.observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'data': data.toIso8601String(),
      'populacao': populacao,
      'percentual_germinacao': percentualGerminacao,
      'estadio_fenologico': estadioFenologico,
      'dias_apos_emergencia': diasAposEmergencia,
      'observacoes': observacoes ?? '',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converte para JSON
  String toJson() => json.encode(toMap());

  /// Cria a partir de Map
  factory EstandeModel.fromMap(Map<String, dynamic> map) {
    return EstandeModel(
      id: map['id'],
      talhaoId: map['talhao_id'] ?? '',
      data: DateTime.tryParse(map['data'] ?? '') ?? DateTime.now(),
      populacao: map['populacao'] ?? 0,
      percentualGerminacao: (map['percentual_germinacao'] ?? 0.0).toDouble(),
      estadioFenologico: map['estadio_fenologico'] ?? '',
      diasAposEmergencia: map['dias_apos_emergencia'] ?? 0,
      observacoes: map['observacoes'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Cria a partir de JSON
  factory EstandeModel.fromJson(String source) => EstandeModel.fromMap(json.decode(source));

  /// Cria uma cópia com alterações
  EstandeModel copyWith({
    String? id,
    String? talhaoId,
    DateTime? data,
    int? populacao,
    double? percentualGerminacao,
    String? estadioFenologico,
    int? diasAposEmergencia,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EstandeModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      data: data ?? this.data,
      populacao: populacao ?? this.populacao,
      percentualGerminacao: percentualGerminacao ?? this.percentualGerminacao,
      estadioFenologico: estadioFenologico ?? this.estadioFenologico,
      diasAposEmergencia: diasAposEmergencia ?? this.diasAposEmergencia,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'EstandeModel(id: $id, talhaoId: $talhaoId, data: $data, populacao: $populacao, percentualGerminacao: $percentualGerminacao, estadioFenologico: $estadioFenologico, diasAposEmergencia: $diasAposEmergencia)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EstandeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
