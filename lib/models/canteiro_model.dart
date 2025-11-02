/// 🎯 Modelo de Canteiro para Relatórios Agronômicos
/// Integração entre Teste de Germinação e Dashboard

import 'package:flutter/material.dart';

/// Modelo de Canteiro
class CanteiroModel {
  final String id;
  final String nome;
  final String loteId;
  final String cultura;
  final String variedade;
  final DateTime dataCriacao;
  final DateTime? dataConclusao;
  final String status; // 'ativo', 'concluido', 'pausado'
  final List<CanteiroPosition> posicoes;
  final Map<String, dynamic> dadosAgronomicos;
  final String? observacoes;

  CanteiroModel({
    required this.id,
    required this.nome,
    required this.loteId,
    required this.cultura,
    required this.variedade,
    required this.dataCriacao,
    this.dataConclusao,
    required this.status,
    required this.posicoes,
    required this.dadosAgronomicos,
    this.observacoes,
  });

  /// Calcula estatísticas do canteiro
  Map<String, dynamic> get estatisticas {
    final totalPosicoes = posicoes.length;
    final posicoesPreenchidas = posicoes.where((p) => !p.isEmpty).length;
    final mediaGerminacao = posicoesPreenchidas > 0 
        ? posicoes.where((p) => !p.isEmpty).map((p) => p.percentual).reduce((a, b) => a + b) / posicoesPreenchidas
        : 0.0;
    
    return {
      'totalPosicoes': totalPosicoes,
      'posicoesPreenchidas': posicoesPreenchidas,
      'posicoesVazias': totalPosicoes - posicoesPreenchidas,
      'mediaGerminacao': mediaGerminacao,
      'status': status,
      'diasAtivo': DateTime.now().difference(dataCriacao).inDays,
    };
  }

  /// Obtém cor do canteiro baseada no lote
  Color get cor {
    final hash = loteId.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.amber,
    ];
    return colors[hash.abs() % colors.length];
  }

  /// Verifica se canteiro está ativo
  bool get isAtivo => status == 'ativo';

  /// Verifica se canteiro está concluído
  bool get isConcluido => status == 'concluido';

  /// Obtém percentual de preenchimento
  double get percentualPreenchimento {
    return (posicoes.where((p) => !p.isEmpty).length / posicoes.length) * 100;
  }

  /// Cria uma cópia do modelo com campos alterados
  CanteiroModel copyWith({
    String? id,
    String? nome,
    String? loteId,
    String? cultura,
    String? variedade,
    DateTime? dataCriacao,
    DateTime? dataConclusao,
    String? status,
    List<CanteiroPosition>? posicoes,
    Map<String, dynamic>? dadosAgronomicos,
    String? observacoes,
  }) {
    return CanteiroModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      loteId: loteId ?? this.loteId,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      status: status ?? this.status,
      posicoes: posicoes ?? this.posicoes,
      dadosAgronomicos: dadosAgronomicos ?? this.dadosAgronomicos,
      observacoes: observacoes ?? this.observacoes,
    );
  }
}

/// Modelo de Posição no Canteiro
class CanteiroPosition {
  final String posicao; // A1, B2, C3, D4
  final String? loteId;
  final String? subteste; // A, B, C, D
  final int? subtestId; // ID do subteste específico
  final int cor;
  final int germinadas;
  final int total;
  final double percentual;
  final String? cultura;
  final DateTime? dataInicio;
  final DateTime? ultimaAtualizacao;
  final Map<String, dynamic> dadosDiarios;
  final String? observacoes;
  final dynamic test; // Referência ao teste principal

  CanteiroPosition({
    required this.posicao,
    this.loteId,
    this.subteste,
    this.subtestId,
    required this.cor,
    required this.germinadas,
    required this.total,
    required this.percentual,
    this.cultura,
    this.dataInicio,
    this.ultimaAtualizacao,
    required this.dadosDiarios,
    this.observacoes,
    this.test,
  });

  /// Verifica se posição está vazia
  bool get isEmpty => loteId == null;

  /// Obtém cor baseada na germinação
  Color get corGerminacao {
    if (percentual >= 90) return Colors.green;
    if (percentual >= 80) return Colors.lightGreen;
    if (percentual >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Obtém descrição da qualidade
  String get qualidadeDescricao {
    if (percentual >= 90) return 'Excelente';
    if (percentual >= 80) return 'Boa';
    if (percentual >= 70) return 'Regular';
    return 'Ruim';
  }

  /// Calcula dias desde início
  int get diasDesdeInicio {
    if (dataInicio == null) return 0;
    return DateTime.now().difference(dataInicio!).inDays;
  }
}

/// Modelo de Dados Diários
class DadosDiariosCanteiro {
  final String canteiroId;
  final String posicao;
  final DateTime data;
  final int germinadas;
  final int naoGerminadas;
  final int manchas;
  final int podridao;
  final int cotiledonesAmarelados;
  final double umidadeSubstrato;
  final double temperatura;
  final String? observacoes;
  final Map<String, dynamic> dadosExtras;

  DadosDiariosCanteiro({
    required this.canteiroId,
    required this.posicao,
    required this.data,
    required this.germinadas,
    required this.naoGerminadas,
    required this.manchas,
    required this.podridao,
    required this.cotiledonesAmarelados,
    required this.umidadeSubstrato,
    required this.temperatura,
    this.observacoes,
    required this.dadosExtras,
  });

  /// Calcula percentual de germinação
  double get percentualGerminacao {
    final total = germinadas + naoGerminadas;
    return total > 0 ? (germinadas / total) * 100 : 0.0;
  }

  /// Calcula índice de sanidade
  double get indiceSanidade {
    final total = germinadas + naoGerminadas;
    if (total == 0) return 100.0;
    
    final problemas = manchas + podridao + cotiledonesAmarelados;
    return ((total - problemas) / total) * 100;
  }
}
