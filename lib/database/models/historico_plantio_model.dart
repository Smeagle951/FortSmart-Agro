import 'package:flutter/foundation.dart';

class HistoricoPlantioModel {
  final int? id;
  final String? calculoId;
  final String talhaoId;
  final String? talhaoNome;
  final String? safraId;
  final String culturaId;
  final String tipo; // 'calculo_sementes', 'calibragem_adubo', etc.
  final DateTime data;
  final String resumo; // JSON/texto dos principais resultados
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HistoricoPlantioModel({
    this.id,
    this.calculoId,
    required this.talhaoId,
    this.talhaoNome,
    this.safraId,
    required this.culturaId,
    required this.tipo,
    required this.data,
    required this.resumo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'calculo_id': calculoId,
    'talhao_id': talhaoId,
    'talhao_nome': talhaoNome,
    'safra_id': safraId,
    'cultura_id': culturaId,
    'tipo': tipo,
    'data': data.toIso8601String(),
    'resumo': resumo,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory HistoricoPlantioModel.fromMap(Map<String, dynamic> map) => HistoricoPlantioModel(
    id: map['id'],
    calculoId: map['calculo_id'],
    talhaoId: map['talhao_id'],
    talhaoNome: map['talhao_nome'],
    safraId: map['safra_id'],
    culturaId: map['cultura_id'],
    tipo: map['tipo'],
    data: DateTime.parse(map['data']),
    resumo: map['resumo'],
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
  );
}
