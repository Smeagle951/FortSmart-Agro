import 'package:flutter/material.dart';
import 'drawing_polygon_model.dart';
import 'subarea_experimento_model.dart';

class Experimento {
  final String id;
  final String nome;
  final String? descricao;
  final String talhaoId;
  final String talhaoNome;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String status; // 'ativo', 'concluido', 'cancelado'
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final List<Subarea> subareas;
  final DrawingPolygon? talhaoPolygon;
  
  // Campos adicionais para informações detalhadas
  final String? cultura;
  final String? variedade;
  final String? tipoTeste; // 'fertilizante', 'fungicida', 'populacao', 'variedade', 'outros'
  final String? produtoTestado;
  final String? observacoes;

  Experimento({
    required this.id,
    required this.nome,
    this.descricao,
    required this.talhaoId,
    required this.talhaoNome,
    required this.dataInicio,
    this.dataFim,
    required this.status,
    required this.criadoEm,
    this.atualizadoEm,
    this.subareas = const [],
    this.talhaoPolygon,
    this.cultura,
    this.variedade,
    this.tipoTeste,
    this.produtoTestado,
    this.observacoes,
  });

  // Calcular dias restantes
  int? get diasRestantes {
    if (dataFim == null) return null;
    final now = DateTime.now();
    final difference = dataFim!.difference(now);
    return difference.inDays;
  }

  // Calcular total de área das subáreas
  double get areaTotalSubareas {
    return subareas.fold(0.0, (sum, subarea) => sum + subarea.areaHa);
  }

  // Verificar se está ativo
  bool get isAtivo => status == 'ativo';

  // Verificar se está concluído
  bool get isConcluido => status == 'concluido';

  // Verificar se está cancelado
  bool get isCancelado => status == 'cancelado';

  // Criar experimento a partir de Map do banco
  factory Experimento.fromMap(Map<String, dynamic> map, {
    List<Subarea> subareas = const [],
    DrawingPolygon? talhaoPolygon,
  }) {
    return Experimento(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      descricao: map['descricao']?.toString(),
      talhaoId: map['talhao_id']?.toString() ?? '',
      talhaoNome: map['talhao_nome']?.toString() ?? '',
      dataInicio: map['data_inicio'] is DateTime 
          ? map['data_inicio'] as DateTime
          : DateTime.parse(map['data_inicio']?.toString() ?? DateTime.now().toIso8601String()),
      dataFim: map['data_fim'] != null 
          ? (map['data_fim'] is DateTime 
              ? map['data_fim'] as DateTime
              : DateTime.parse(map['data_fim'].toString()))
          : null,
      status: map['status']?.toString() ?? 'ativo',
      criadoEm: map['criado_em'] is DateTime 
          ? map['criado_em'] as DateTime
          : DateTime.parse(map['criado_em']?.toString() ?? DateTime.now().toIso8601String()),
      atualizadoEm: map['atualizado_em'] != null 
          ? (map['atualizado_em'] is DateTime 
              ? map['atualizado_em'] as DateTime
              : DateTime.parse(map['atualizado_em'].toString()))
          : null,
      subareas: subareas,
      talhaoPolygon: talhaoPolygon,
      cultura: map['cultura']?.toString(),
      variedade: map['variedade']?.toString(),
      tipoTeste: map['tipo_teste']?.toString(),
      produtoTestado: map['produto_testado']?.toString(),
      observacoes: map['observacoes']?.toString(),
    );
  }

  // Converter para Map para o banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'status': status,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      'cultura': cultura,
      'variedade': variedade,
      'tipo_teste': tipoTeste,
      'produto_testado': produtoTestado,
      'observacoes': observacoes,
    };
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'talhaoId': talhaoId,
      'talhaoNome': talhaoNome,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
      'status': status,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
      'subareas': subareas.map((s) => s.toJson()).toList(),
      'talhaoPolygon': talhaoPolygon?.toJson(),
      'cultura': cultura,
      'variedade': variedade,
      'tipoTeste': tipoTeste,
      'produtoTestado': produtoTestado,
      'observacoes': observacoes,
    };
  }

  // Criar a partir de JSON
  factory Experimento.fromJson(Map<String, dynamic> json) {
    return Experimento(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      talhaoId: json['talhaoId'] ?? '',
      talhaoNome: json['talhaoNome'] ?? '',
      dataInicio: DateTime.parse(json['dataInicio'] ?? DateTime.now().toIso8601String()),
      dataFim: json['dataFim'] != null ? DateTime.parse(json['dataFim']) : null,
      status: json['status'] ?? 'ativo',
      criadoEm: DateTime.parse(json['criadoEm'] ?? DateTime.now().toIso8601String()),
      atualizadoEm: json['atualizadoEm'] != null ? DateTime.parse(json['atualizadoEm']) : null,
      subareas: (json['subareas'] as List<dynamic>?)
          ?.map((s) => Subarea.fromJson(s))
          .toList() ?? [],
      talhaoPolygon: json['talhaoPolygon'] != null 
          ? DrawingPolygon.fromJson(json['talhaoPolygon'])
          : null,
      cultura: json['cultura'],
      variedade: json['variedade'],
      tipoTeste: json['tipoTeste'],
      produtoTestado: json['produtoTestado'],
      observacoes: json['observacoes'],
    );
  }

  // Copiar com alterações
  Experimento copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? talhaoId,
    String? talhaoNome,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    List<Subarea>? subareas,
    DrawingPolygon? talhaoPolygon,
    String? cultura,
    String? variedade,
    String? tipoTeste,
    String? produtoTestado,
    String? observacoes,
  }) {
    return Experimento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      subareas: subareas ?? this.subareas,
      talhaoPolygon: talhaoPolygon ?? this.talhaoPolygon,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      tipoTeste: tipoTeste ?? this.tipoTeste,
      produtoTestado: produtoTestado ?? this.produtoTestado,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}
