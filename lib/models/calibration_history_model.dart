import 'package:flutter/material.dart';

class CalibrationHistoryModel {
  final int? id;
  final String talhaoId;
  final String talhaoName;
  final String culturaId;
  final String culturaName;
  final String? discoNome;
  final int? furosDisco;
  final int? engrenagemMotora;
  final int? engrenagemMovida;
  final double? voltasDisco;
  final double? distanciaPercorrida;
  final int? linhasColetadas;
  final double? espacamentoCm;
  final int? metaSementesHectare;
  final double? relacaoTransmissao;
  final int? sementesTotais;
  final double? sementesPorMetro;
  final int? sementesPorHectare;
  final double? diferencaMetaPercentual;
  final String statusCalibracao;
  final String? observacoes;
  final DateTime dataCalibracao;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalibrationHistoryModel({
    this.id,
    required this.talhaoId,
    required this.talhaoName,
    required this.culturaId,
    required this.culturaName,
    this.discoNome,
    this.furosDisco,
    this.engrenagemMotora,
    this.engrenagemMovida,
    this.voltasDisco,
    this.distanciaPercorrida,
    this.linhasColetadas,
    this.espacamentoCm,
    this.metaSementesHectare,
    this.relacaoTransmissao,
    this.sementesTotais,
    this.sementesPorMetro,
    this.sementesPorHectare,
    this.diferencaMetaPercentual,
    this.statusCalibracao = 'normal',
    this.observacoes,
    required this.dataCalibracao,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converte para Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_name': talhaoName,
      'cultura_id': culturaId,
      'cultura_name': culturaName,
      'disco_nome': discoNome,
      'furos_disco': furosDisco,
      'engrenagem_motora': engrenagemMotora,
      'engrenagem_movida': engrenagemMovida,
      'voltas_disco': voltasDisco,
      'distancia_percorrida': distanciaPercorrida,
      'linhas_coletadas': linhasColetadas,
      'espacamento_cm': espacamentoCm,
      'meta_sementes_hectare': metaSementesHectare,
      'relacao_transmissao': relacaoTransmissao,
      'sementes_totais': sementesTotais,
      'sementes_por_metro': sementesPorMetro,
      'sementes_por_hectare': sementesPorHectare,
      'diferenca_meta_percentual': diferencaMetaPercentual,
      'status_calibracao': statusCalibracao,
      'observacoes': observacoes,
      'data_calibracao': dataCalibracao.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria instância a partir de Map
  factory CalibrationHistoryModel.fromJson(Map<String, dynamic> map) {
    return CalibrationHistoryModel(
      id: map['id'],
      talhaoId: map['talhao_id'] ?? '',
      talhaoName: map['talhao_name'] ?? '',
      culturaId: map['cultura_id'] ?? '',
      culturaName: map['cultura_name'] ?? '',
      discoNome: map['disco_nome'],
      furosDisco: map['furos_disco'],
      engrenagemMotora: map['engrenagem_motora'],
      engrenagemMovida: map['engrenagem_movida'],
      voltasDisco: map['voltas_disco']?.toDouble(),
      distanciaPercorrida: map['distancia_percorrida']?.toDouble(),
      linhasColetadas: map['linhas_coletadas'],
      espacamentoCm: map['espacamento_cm']?.toDouble(),
      metaSementesHectare: map['meta_sementes_hectare'],
      relacaoTransmissao: map['relacao_transmissao']?.toDouble(),
      sementesTotais: map['sementes_totais'],
      sementesPorMetro: map['sementes_por_metro']?.toDouble(),
      sementesPorHectare: map['sementes_por_hectare'],
      diferencaMetaPercentual: map['diferenca_meta_percentual']?.toDouble(),
      statusCalibracao: map['status_calibracao'] ?? 'normal',
      observacoes: map['observacoes'],
      dataCalibracao: DateTime.parse(map['data_calibracao'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Cria cópia com campos atualizados
  CalibrationHistoryModel copyWith({
    int? id,
    String? talhaoId,
    String? talhaoName,
    String? culturaId,
    String? culturaName,
    String? discoNome,
    int? furosDisco,
    int? engrenagemMotora,
    int? engrenagemMovida,
    double? voltasDisco,
    double? distanciaPercorrida,
    int? linhasColetadas,
    double? espacamentoCm,
    int? metaSementesHectare,
    double? relacaoTransmissao,
    int? sementesTotais,
    double? sementesPorMetro,
    int? sementesPorHectare,
    double? diferencaMetaPercentual,
    String? statusCalibracao,
    String? observacoes,
    DateTime? dataCalibracao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalibrationHistoryModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoName: talhaoName ?? this.talhaoName,
      culturaId: culturaId ?? this.culturaId,
      culturaName: culturaName ?? this.culturaName,
      discoNome: discoNome ?? this.discoNome,
      furosDisco: furosDisco ?? this.furosDisco,
      engrenagemMotora: engrenagemMotora ?? this.engrenagemMotora,
      engrenagemMovida: engrenagemMovida ?? this.engrenagemMovida,
      voltasDisco: voltasDisco ?? this.voltasDisco,
      distanciaPercorrida: distanciaPercorrida ?? this.distanciaPercorrida,
      linhasColetadas: linhasColetadas ?? this.linhasColetadas,
      espacamentoCm: espacamentoCm ?? this.espacamentoCm,
      metaSementesHectare: metaSementesHectare ?? this.metaSementesHectare,
      relacaoTransmissao: relacaoTransmissao ?? this.relacaoTransmissao,
      sementesTotais: sementesTotais ?? this.sementesTotais,
      sementesPorMetro: sementesPorMetro ?? this.sementesPorMetro,
      sementesPorHectare: sementesPorHectare ?? this.sementesPorHectare,
      diferencaMetaPercentual: diferencaMetaPercentual ?? this.diferencaMetaPercentual,
      statusCalibracao: statusCalibracao ?? this.statusCalibracao,
      observacoes: observacoes ?? this.observacoes,
      dataCalibracao: dataCalibracao ?? this.dataCalibracao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Determina o status da calibração baseado na diferença da meta
  static String determinarStatusCalibracao(double diferencaMeta) {
    if (diferencaMeta.abs() <= 5.0) {
      return 'dentro_esperado';
    } else if (diferencaMeta.abs() <= 15.0) {
      return 'normal';
    } else {
      return 'fora_esperado';
    }
  }

  /// Retorna a cor do status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'dentro_esperado':
        return const Color(0xFF4CAF50); // Verde
      case 'normal':
        return const Color(0xFFFF9800); // Laranja
      case 'fora_esperado':
        return const Color(0xFFF44336); // Vermelho
      default:
        return const Color(0xFF9E9E9E); // Cinza
    }
  }

  /// Retorna o texto do status
  static String getStatusText(String status) {
    switch (status) {
      case 'dentro_esperado':
        return 'Dentro do Esperado';
      case 'normal':
        return 'Normal';
      case 'fora_esperado':
        return 'Fora do Esperado';
      default:
        return 'Desconhecido';
    }
  }

  /// Retorna o ícone do status
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'dentro_esperado':
        return Icons.check_circle;
      case 'normal':
        return Icons.info;
      case 'fora_esperado':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }
}

