/// 🎯 Modelo de Relatório de Infestação
/// Integração entre Mapa de Infestação e IA FortSmart

import 'package:flutter/material.dart';

/// Modelo de Relatório de Infestação
class InfestationReportModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String cultura;
  final String variedade;
  final DateTime dataColeta;
  final DateTime dataAnalise;
  final String status; // 'ativo', 'controlado', 'critico'
  final List<InfestationPoint> pontosInfestacao;
  final Map<String, dynamic> dadosAgronomicos;
  final Map<String, dynamic> analiseIA;
  final List<PrescriptionModel> prescricoes;
  final List<LearningFeedback> feedbacks;
  final String? observacoes;

  InfestationReportModel({
    required this.id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.cultura,
    required this.variedade,
    required this.dataColeta,
    required this.dataAnalise,
    required this.status,
    required this.pontosInfestacao,
    required this.dadosAgronomicos,
    required this.analiseIA,
    required this.prescricoes,
    required this.feedbacks,
    this.observacoes,
  });

  /// Calcula estatísticas do relatório
  Map<String, dynamic> get estatisticas {
    final totalPontos = pontosInfestacao.length;
    final pontosCriticos = pontosInfestacao.where((p) => p.nivel == 'critico').length;
    final pontosModerados = pontosInfestacao.where((p) => p.nivel == 'moderado').length;
    final pontosBaixos = pontosInfestacao.where((p) => p.nivel == 'baixo').length;
    
    final areaTotal = dadosAgronomicos['areaTotal'] as double? ?? 0.0;
    final areaAfetada = pontosInfestacao.fold<double>(0.0, (sum, p) => sum + p.areaAfetada);
    final percentualAfetado = areaTotal > 0 ? (areaAfetada / areaTotal) * 100 : 0.0;
    
    return {
      'totalPontos': totalPontos,
      'pontosCriticos': pontosCriticos,
      'pontosModerados': pontosModerados,
      'pontosBaixos': pontosBaixos,
      'areaTotal': areaTotal,
      'areaAfetada': areaAfetada,
      'percentualAfetado': percentualAfetado,
      'status': status,
      'diasDesdeColeta': DateTime.now().difference(dataColeta).inDays,
    };
  }

  /// Obtém cor baseada no status
  Color get corStatus {
    switch (status.toLowerCase()) {
      case 'critico': return Colors.red;
      case 'ativo': return Colors.orange;
      case 'controlado': return Colors.green;
      default: return Colors.grey;
    }
  }

  /// Verifica se relatório está ativo
  bool get isAtivo => status == 'ativo';

  /// Verifica se relatório está crítico
  bool get isCritico => status == 'critico';

  /// Obtém nível de risco geral
  String get nivelRisco {
    final stats = estatisticas;
    final percentualAfetado = stats['percentualAfetado'] as double;
    final pontosCriticos = stats['pontosCriticos'] as int;
    
    if (percentualAfetado >= 20 || pontosCriticos >= 3) return 'Alto';
    if (percentualAfetado >= 10 || pontosCriticos >= 1) return 'Médio';
    return 'Baixo';
  }
}

/// Modelo de Ponto de Infestação
class InfestationPoint {
  final String id;
  final double latitude;
  final double longitude;
  final String organismo;
  final String nivel; // 'baixo', 'moderado', 'critico'
  final double intensidade; // 0.0 a 1.0
  final double areaAfetada; // em hectares
  final String sintomas;
  final String observacoes;
  final DateTime dataDetectado;
  final List<String> fotos;
  final Map<String, dynamic> dadosTecnicos;

  InfestationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.organismo,
    required this.nivel,
    required this.intensidade,
    required this.areaAfetada,
    required this.sintomas,
    required this.observacoes,
    required this.dataDetectado,
    required this.fotos,
    required this.dadosTecnicos,
  });

  /// Obtém cor baseada no nível
  Color get corNivel {
    switch (nivel.toLowerCase()) {
      case 'critico': return Colors.red;
      case 'moderado': return Colors.orange;
      case 'baixo': return Colors.yellow;
      default: return Colors.grey;
    }
  }

  /// Obtém ícone baseado no organismo
  IconData get iconeOrganismo {
    if (organismo.toLowerCase().contains('lagarta')) return Icons.bug_report;
    if (organismo.toLowerCase().contains('fungo')) return Icons.healing;
    if (organismo.toLowerCase().contains('bacteria')) return Icons.science;
    if (organismo.toLowerCase().contains('virus')) return Icons.biotech;
    return Icons.pest_control;
  }

  /// Calcula dias desde detecção
  int get diasDesdeDetectado {
    return DateTime.now().difference(dataDetectado).inDays;
  }
}

/// Modelo de Prescrição Agronômica
class PrescriptionModel {
  final String id;
  final String tipo; // 'preventivo', 'curativo', 'emergencial'
  final String categoria; // 'quimico', 'biologico', 'cultural'
  final String produto;
  final String dosagem;
  final String aplicacao;
  final String frequencia;
  final String observacoes;
  final String prioridade; // 'alta', 'media', 'baixa'
  final DateTime dataPrescricao;
  final String status; // 'pendente', 'aplicada', 'cancelada'
  final Map<String, dynamic> dadosTecnicos;

  PrescriptionModel({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.produto,
    required this.dosagem,
    required this.aplicacao,
    required this.frequencia,
    required this.observacoes,
    required this.prioridade,
    required this.dataPrescricao,
    required this.status,
    required this.dadosTecnicos,
  });

  /// Obtém cor baseada na prioridade
  Color get corPrioridade {
    switch (prioridade.toLowerCase()) {
      case 'alta': return Colors.red;
      case 'media': return Colors.orange;
      case 'baixa': return Colors.green;
      default: return Colors.grey;
    }
  }

  /// Obtém ícone baseado na categoria
  IconData get iconeCategoria {
    switch (categoria.toLowerCase()) {
      case 'quimico': return Icons.science;
      case 'biologico': return Icons.eco;
      case 'cultural': return Icons.agriculture;
      default: return Icons.info;
    }
  }
}

/// Modelo de Feedback de Aprendizado
class LearningFeedback {
  final String id;
  final String relatorioId;
  final String prescricaoId;
  final String tipo; // 'aceita', 'rejeita', 'modifica'
  final String metodoUtilizado;
  final String resultado;
  final String observacoes;
  final DateTime dataFeedback;
  final String usuarioId;
  final Map<String, dynamic> dadosExtras;

  LearningFeedback({
    required this.id,
    required this.relatorioId,
    required this.prescricaoId,
    required this.tipo,
    required this.metodoUtilizado,
    required this.resultado,
    required this.observacoes,
    required this.dataFeedback,
    required this.usuarioId,
    required this.dadosExtras,
  });

  /// Verifica se feedback é positivo
  bool get isPositivo => tipo == 'aceita' || resultado.toLowerCase().contains('sucesso');

  /// Obtém cor baseada no tipo
  Color get corTipo {
    switch (tipo.toLowerCase()) {
      case 'aceita': return Colors.green;
      case 'rejeita': return Colors.red;
      case 'modifica': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

/// Modelo de Análise da IA
class InfestationAIAnalysis {
  final String versaoIA;
  final DateTime dataAnalise;
  final String nivelRisco;
  final double scoreConfianca;
  final List<String> organismosDetectados;
  final List<String> sintomasIdentificados;
  final Map<String, dynamic> condicoesFavoraveis;
  final List<String> recomendacoes;
  final List<String> alertas;
  final Map<String, dynamic> dadosTecnicos;

  InfestationAIAnalysis({
    required this.versaoIA,
    required this.dataAnalise,
    required this.nivelRisco,
    required this.scoreConfianca,
    required this.organismosDetectados,
    required this.sintomasIdentificados,
    required this.condicoesFavoraveis,
    required this.recomendacoes,
    required this.alertas,
    required this.dadosTecnicos,
  });

  /// Obtém cor baseada no nível de risco
  Color get corRisco {
    switch (nivelRisco.toLowerCase()) {
      case 'alto': return Colors.red;
      case 'medio': return Colors.orange;
      case 'baixo': return Colors.green;
      default: return Colors.grey;
    }
  }

  /// Verifica se análise é confiável
  bool get isConfiavel => scoreConfianca >= 0.8;
}
