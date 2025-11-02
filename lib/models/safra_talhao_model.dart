import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

/// Modelo que representa a associação entre um talhão e uma safra
class SafraTalhaoModel {
  final String id;
  final String talhaoId;
  final String safraId;
  final String culturaId;
  final String culturaNome;
  final Color culturaCor;
  final double area; // Área em hectares
  final DateTime dataCadastro;
  final DateTime dataAtualizacao;
  final bool ativo;
  final Map<String, dynamic>? metadados; // Dados adicionais como produtividade, etc.
  final bool sincronizado;

  /// Construtor principal
  SafraTalhaoModel({
    required this.id,
    required this.talhaoId,
    required this.safraId,
    required this.culturaId,
    required this.culturaNome,
    required this.culturaCor,
    required this.area,
    required this.dataCadastro,
    required this.dataAtualizacao,
    this.ativo = true,
    this.metadados,
    this.sincronizado = false,
  });

  /// Factory constructor para criar uma nova associação safra-talhão
  factory SafraTalhaoModel.criar({
    required String talhaoId,
    required String safraId,
    required String culturaId,
    required String culturaNome,
    required Color culturaCor,
    required double area,
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    
    return SafraTalhaoModel(
      id: id,
      talhaoId: talhaoId,
      safraId: safraId,
      culturaId: culturaId,
      culturaNome: culturaNome,
      culturaCor: culturaCor,
      area: area,
      dataCadastro: now,
      dataAtualizacao: now,
      ativo: true,
      sincronizado: false,
    );
  }

  /// Converte o modelo para um mapa para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'safraId': safraId,
      'culturaId': culturaId,
      'culturaNome': culturaNome,
      'culturaCor': culturaCor.value,
      'area': area,
      'dataCadastro': dataCadastro.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'ativo': ativo,
      'metadados': metadados,
      'sincronizado': sincronizado,
    };
  }

  /// Cria uma instância a partir de um mapa
  factory SafraTalhaoModel.fromMap(Map<String, dynamic> map) {
    return SafraTalhaoModel(
      id: map['id'],
      talhaoId: map['talhaoId'],
      safraId: map['safraId'],
      culturaId: map['culturaId'],
      culturaNome: map['culturaNome'],
      culturaCor: Color(map['culturaCor']),
      area: map['area']?.toDouble() ?? 0.0,
      dataCadastro: DateTime.parse(map['dataCadastro']),
      dataAtualizacao: DateTime.parse(map['dataAtualizacao']),
      ativo: map['ativo'] ?? true,
      metadados: map['metadados'],
      sincronizado: map['sincronizado'] ?? false,
    );
  }

  /// Serializa para JSON
  String toJson() => json.encode(toMap());

  /// Cria uma instância a partir de JSON
  factory SafraTalhaoModel.fromJson(String source) =>
      SafraTalhaoModel.fromMap(json.decode(source));

  /// Cria uma cópia com alterações específicas
  SafraTalhaoModel copyWith({
    String? id,
    String? talhaoId,
    String? safraId,
    String? culturaId,
    String? culturaNome,
    Color? culturaCor,
    double? area,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
    bool? ativo,
    Map<String, dynamic>? metadados,
    bool? sincronizado,
  }) {
    return SafraTalhaoModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      safraId: safraId ?? this.safraId,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      culturaCor: culturaCor ?? this.culturaCor,
      area: area ?? this.area,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      ativo: ativo ?? this.ativo,
      metadados: metadados ?? this.metadados,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// Retorna uma string representando o período da safra (ex: "2023/2024")
  String get periodoSafra {
    // Implementação depende do formato de safraId ou outros dados
    // Por exemplo, se safraId for "2023-2024"
    return safraId.replaceAll('-', '/');
  }

  /// Calcula a produtividade estimada (se disponível nos metadados)
  double? get produtividadeEstimada {
    if (metadados != null && metadados!.containsKey('produtividadeEstimada')) {
      return metadados!['produtividadeEstimada'];
    }
    return null;
  }

  /// Calcula a produtividade real (se disponível nos metadados)
  double? get produtividadeReal {
    if (metadados != null && metadados!.containsKey('produtividadeReal')) {
      return metadados!['produtividadeReal'];
    }
    return null;
  }

  /// Verifica se a safra está ativa
  bool get isAtiva => ativo;

  /// Verifica se a safra está em andamento (baseado na data atual)
  bool get isEmAndamento {
    final now = DateTime.now();
    if (metadados != null && 
        metadados!.containsKey('dataInicio') && 
        metadados!.containsKey('dataFim')) {
      final dataInicio = DateTime.parse(metadados!['dataInicio']);
      final dataFim = DateTime.parse(metadados!['dataFim']);
      return now.isAfter(dataInicio) && now.isBefore(dataFim);
    }
    return false;
  }
}
