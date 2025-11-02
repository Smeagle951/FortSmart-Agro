/// 🚨 Model: Alerta Fenológico
/// 
/// Este modelo representa um alerta gerado automaticamente
/// pelo sistema de análise fenológica quando detecta
/// desvios ou problemas no desenvolvimento da cultura.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'package:flutter/material.dart';

class PhenologicalAlertModel {
  /// ID único do alerta
  final String id;
  
  /// ID do registro que gerou o alerta
  final String registroId;
  
  /// ID do talhão
  final String talhaoId;
  
  /// ID da cultura
  final String culturaId;
  
  /// Tipo de alerta
  final AlertType tipo;
  
  /// Severidade do alerta
  final AlertSeverity severidade;
  
  /// Título do alerta
  final String titulo;
  
  /// Descrição detalhada
  final String descricao;
  
  /// Valor medido
  final double? valorMedido;
  
  /// Valor esperado
  final double? valorEsperado;
  
  /// Desvio percentual
  final double? desvioPercentual;
  
  /// Recomendações de ação
  final List<String> recomendacoes;
  
  /// Status do alerta
  final AlertStatus status;
  
  /// Data de criação
  final DateTime createdAt;
  
  /// Data de resolução
  final DateTime? resolvidoEm;
  
  /// Observações de resolução
  final String? observacoesResolucao;

  PhenologicalAlertModel({
    required this.id,
    required this.registroId,
    required this.talhaoId,
    required this.culturaId,
    required this.tipo,
    required this.severidade,
    required this.titulo,
    required this.descricao,
    this.valorMedido,
    this.valorEsperado,
    this.desvioPercentual,
    this.recomendacoes = const [],
    this.status = AlertStatus.ativo,
    required this.createdAt,
    this.resolvidoEm,
    this.observacoesResolucao,
  });

  /// Factory: Criar novo alerta
  factory PhenologicalAlertModel.novo({
    required String registroId,
    required String talhaoId,
    required String culturaId,
    required AlertType tipo,
    required AlertSeverity severidade,
    required String titulo,
    required String descricao,
    double? valorMedido,
    double? valorEsperado,
    double? desvioPercentual,
    List<String>? recomendacoes,
  }) {
    final now = DateTime.now();
    return PhenologicalAlertModel(
      id: '${talhaoId}_${now.millisecondsSinceEpoch}',
      registroId: registroId,
      talhaoId: talhaoId,
      culturaId: culturaId,
      tipo: tipo,
      severidade: severidade,
      titulo: titulo,
      descricao: descricao,
      valorMedido: valorMedido,
      valorEsperado: valorEsperado,
      desvioPercentual: desvioPercentual,
      recomendacoes: recomendacoes ?? [],
      status: AlertStatus.ativo,
      createdAt: now,
    );
  }

  /// Converter para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registroId': registroId,
      'talhaoId': talhaoId,
      'culturaId': culturaId,
      'tipo': tipo.toString(),
      'severidade': severidade.toString(),
      'titulo': titulo,
      'descricao': descricao,
      'valorMedido': valorMedido,
      'valorEsperado': valorEsperado,
      'desvioPercentual': desvioPercentual,
      'recomendacoes': recomendacoes.join('|'),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'resolvidoEm': resolvidoEm?.toIso8601String(),
      'observacoesResolucao': observacoesResolucao,
    };
  }

  /// Criar a partir de Map
  factory PhenologicalAlertModel.fromMap(Map<String, dynamic> map) {
    return PhenologicalAlertModel(
      id: map['id'] as String,
      registroId: map['registroId'] as String,
      talhaoId: map['talhaoId'] as String,
      culturaId: map['culturaId'] as String,
      tipo: _parseAlertType(map['tipo'] as String),
      severidade: _parseAlertSeverity(map['severidade'] as String),
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String,
      valorMedido: map['valorMedido'] as double?,
      valorEsperado: map['valorEsperado'] as double?,
      desvioPercentual: map['desvioPercentual'] as double?,
      recomendacoes: (map['recomendacoes'] as String?)?.split('|').where((s) => s.isNotEmpty).toList() ?? [],
      status: _parseAlertStatus(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      resolvidoEm: map['resolvidoEm'] != null ? DateTime.parse(map['resolvidoEm'] as String) : null,
      observacoesResolucao: map['observacoesResolucao'] as String?,
    );
  }

  static AlertType _parseAlertType(String type) {
    if (type.contains('crescimento')) return AlertType.crescimento;
    if (type.contains('estande')) return AlertType.estande;
    if (type.contains('sanidade')) return AlertType.sanidade;
    if (type.contains('nutricional')) return AlertType.nutricional;
    if (type.contains('reprodutivo')) return AlertType.reprodutivo;
    return AlertType.crescimento;
  }

  static AlertSeverity _parseAlertSeverity(String severity) {
    if (severity.contains('critica')) return AlertSeverity.critica;
    if (severity.contains('alta')) return AlertSeverity.alta;
    if (severity.contains('media')) return AlertSeverity.media;
    if (severity.contains('baixa')) return AlertSeverity.baixa;
    return AlertSeverity.media;
  }

  static AlertStatus _parseAlertStatus(String status) {
    if (status.contains('resolvido')) return AlertStatus.resolvido;
    if (status.contains('ignorado')) return AlertStatus.ignorado;
    return AlertStatus.ativo;
  }

  /// Copiar com modificações
  PhenologicalAlertModel copyWith({
    String? id,
    String? registroId,
    String? talhaoId,
    String? culturaId,
    AlertType? tipo,
    AlertSeverity? severidade,
    String? titulo,
    String? descricao,
    double? valorMedido,
    double? valorEsperado,
    double? desvioPercentual,
    List<String>? recomendacoes,
    AlertStatus? status,
    DateTime? createdAt,
    DateTime? resolvidoEm,
    String? observacoesResolucao,
  }) {
    return PhenologicalAlertModel(
      id: id ?? this.id,
      registroId: registroId ?? this.registroId,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      tipo: tipo ?? this.tipo,
      severidade: severidade ?? this.severidade,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      valorMedido: valorMedido ?? this.valorMedido,
      valorEsperado: valorEsperado ?? this.valorEsperado,
      desvioPercentual: desvioPercentual ?? this.desvioPercentual,
      recomendacoes: recomendacoes ?? this.recomendacoes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvidoEm: resolvidoEm ?? this.resolvidoEm,
      observacoesResolucao: observacoesResolucao ?? this.observacoesResolucao,
    );
  }

  /// Obter cor baseada na severidade
  Color get cor {
    switch (severidade) {
      case AlertSeverity.critica:
        return Colors.red;
      case AlertSeverity.alta:
        return Colors.deepOrange;
      case AlertSeverity.media:
        return Colors.orange;
      case AlertSeverity.baixa:
        return Colors.amber;
    }
  }

  /// Obter ícone baseado no tipo
  IconData get icone {
    switch (tipo) {
      case AlertType.crescimento:
        return Icons.trending_down;
      case AlertType.estande:
        return Icons.people_outline;
      case AlertType.sanidade:
        return Icons.healing;
      case AlertType.nutricional:
        return Icons.science;
      case AlertType.reprodutivo:
        return Icons.local_florist;
    }
  }

  @override
  String toString() => 'PhenologicalAlertModel($titulo - $severidade)';
}

/// Enum: Tipo de Alerta
enum AlertType {
  crescimento,    // Crescimento abaixo do esperado
  estande,        // Problemas no estande
  sanidade,       // Problemas fitossanitários
  nutricional,    // Deficiências nutricionais
  reprodutivo,    // Problemas na fase reprodutiva
}

/// Enum: Severidade do Alerta
enum AlertSeverity {
  baixa,    // Desvio < 10%
  media,    // Desvio 10-20%
  alta,     // Desvio 20-30%
  critica,  // Desvio > 30%
}

/// Enum: Status do Alerta
enum AlertStatus {
  ativo,      // Alerta ativo, requer atenção
  resolvido,  // Problema foi resolvido
  ignorado,   // Alerta foi ignorado pelo usuário
}

/// Extension: Helpers para AlertType
extension AlertTypeExtension on AlertType {
  String get nome {
    switch (this) {
      case AlertType.crescimento:
        return 'Crescimento';
      case AlertType.estande:
        return 'Estande';
      case AlertType.sanidade:
        return 'Sanidade';
      case AlertType.nutricional:
        return 'Nutricional';
      case AlertType.reprodutivo:
        return 'Reprodutivo';
    }
  }

  String get descricao {
    switch (this) {
      case AlertType.crescimento:
        return 'Alerta relacionado ao crescimento vegetativo';
      case AlertType.estande:
        return 'Alerta relacionado à população de plantas';
      case AlertType.sanidade:
        return 'Alerta relacionado a doenças ou pragas';
      case AlertType.nutricional:
        return 'Alerta relacionado à nutrição das plantas';
      case AlertType.reprodutivo:
        return 'Alerta relacionado ao desenvolvimento reprodutivo';
    }
  }
}

/// Extension: Helpers para AlertSeverity
extension AlertSeverityExtension on AlertSeverity {
  String get nome {
    switch (this) {
      case AlertSeverity.baixa:
        return 'Baixa';
      case AlertSeverity.media:
        return 'Média';
      case AlertSeverity.alta:
        return 'Alta';
      case AlertSeverity.critica:
        return 'Crítica';
    }
  }

  Color get cor {
    switch (this) {
      case AlertSeverity.baixa:
        return Colors.amber;
      case AlertSeverity.media:
        return Colors.orange;
      case AlertSeverity.alta:
        return Colors.deepOrange;
      case AlertSeverity.critica:
        return Colors.red;
    }
  }
}

