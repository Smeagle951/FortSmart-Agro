import 'package:uuid/uuid.dart';

/// Modelo para dados de Estande de Plantas (emergência)
/// Representa a contagem real de plantas que emergiram após o plantio
class PlantingStandModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;
  final DateTime dataAvaliacao;
  final double comprimentoLinhaAvaliado; // em metros
  final int numeroLinhasAvaliadas;
  final double espacamentoEntreLinhas; // em metros
  final int plantasContadas;
  final double? percentualGerminacaoTeorica; // opcional
  final double? populacaoAlvo; // opcional
  final double plantasPorMetro;
  final double populacaoRealPorHectare;
  final double? percentualAtingidoPopulacaoAlvo; // em relação à população alvo
  final double? desvioPlantioEmergencia; // diferença entre previsto e realizado
  final String observacoes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PlantingStandModel({
    String? id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
    required this.dataAvaliacao,
    required this.comprimentoLinhaAvaliado,
    required this.numeroLinhasAvaliadas,
    required this.espacamentoEntreLinhas,
    required this.plantasContadas,
    this.percentualGerminacaoTeorica,
    this.populacaoAlvo,
    required this.plantasPorMetro,
    required this.populacaoRealPorHectare,
    this.percentualAtingidoPopulacaoAlvo,
    this.desvioPlantioEmergencia,
    this.observacoes = '',
    DateTime? createdAt,
    this.updatedAt,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.createdAt = createdAt ?? DateTime.now();

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'talhao_nome': talhaoNome,
      'cultura_id': culturaId,
      'cultura_nome': culturaNome,
      'data_avaliacao': dataAvaliacao.toIso8601String(),
      'comprimento_linha_avaliado': comprimentoLinhaAvaliado,
      'numero_linhas_avaliadas': numeroLinhasAvaliadas,
      'espacamento_entre_linhas': espacamentoEntreLinhas,
      'plantas_contadas': plantasContadas,
      'percentual_germinacao_teorica': percentualGerminacaoTeorica,
      'populacao_alvo': populacaoAlvo,
      'plantas_por_metro': plantasPorMetro,
      'populacao_real_hectare': populacaoRealPorHectare,
      'percentual_atingido_populacao_alvo': percentualAtingidoPopulacaoAlvo,
      'desvio_plantio_emergencia': desvioPlantioEmergencia,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Cria a partir de Map
  factory PlantingStandModel.fromMap(Map<String, dynamic> map) {
    return PlantingStandModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      culturaId: map['cultura_id'] ?? '',
      culturaNome: map['cultura_nome'] ?? '',
      dataAvaliacao: DateTime.parse(map['data_avaliacao'] ?? DateTime.now().toIso8601String()),
      comprimentoLinhaAvaliado: (map['comprimento_linha_avaliado'] ?? 0.0).toDouble(),
      numeroLinhasAvaliadas: map['numero_linhas_avaliadas'] ?? 0,
      espacamentoEntreLinhas: (map['espacamento_entre_linhas'] ?? 0.0).toDouble(),
      plantasContadas: map['plantas_contadas'] ?? 0,
      percentualGerminacaoTeorica: map['percentual_germinacao_teorica']?.toDouble(),
      populacaoAlvo: map['populacao_alvo']?.toDouble(),
      plantasPorMetro: (map['plantas_por_metro'] ?? 0.0).toDouble(),
      populacaoRealPorHectare: (map['populacao_real_hectare'] ?? 0.0).toDouble(),
      percentualAtingidoPopulacaoAlvo: map['percentual_atingido_populacao_alvo']?.toDouble(),
      desvioPlantioEmergencia: map['desvio_plantio_emergencia']?.toDouble(),
      observacoes: map['observacoes'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  /// Cria uma cópia com novos valores
  PlantingStandModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    DateTime? dataAvaliacao,
    double? comprimentoLinhaAvaliado,
    int? numeroLinhasAvaliadas,
    double? espacamentoEntreLinhas,
    int? plantasContadas,
    double? percentualGerminacaoTeorica,
    double? populacaoAlvo,
    double? plantasPorMetro,
    double? populacaoRealPorHectare,
    double? percentualAtingidoPopulacaoAlvo,
    double? desvioPlantioEmergencia,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantingStandModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      comprimentoLinhaAvaliado: comprimentoLinhaAvaliado ?? this.comprimentoLinhaAvaliado,
      numeroLinhasAvaliadas: numeroLinhasAvaliadas ?? this.numeroLinhasAvaliadas,
      espacamentoEntreLinhas: espacamentoEntreLinhas ?? this.espacamentoEntreLinhas,
      plantasContadas: plantasContadas ?? this.plantasContadas,
      percentualGerminacaoTeorica: percentualGerminacaoTeorica ?? this.percentualGerminacaoTeorica,
      populacaoAlvo: populacaoAlvo ?? this.populacaoAlvo,
      plantasPorMetro: plantasPorMetro ?? this.plantasPorMetro,
      populacaoRealPorHectare: populacaoRealPorHectare ?? this.populacaoRealPorHectare,
      percentualAtingidoPopulacaoAlvo: percentualAtingidoPopulacaoAlvo ?? this.percentualAtingidoPopulacaoAlvo,
      desvioPlantioEmergencia: desvioPlantioEmergencia ?? this.desvioPlantioEmergencia,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Retorna a classificação do estande baseada na porcentagem atingida
  StandClassification get classificacao {
    if (percentualAtingidoPopulacaoAlvo == null) {
      return StandClassification.naoAvaliado;
    }
    
    final percentual = percentualAtingidoPopulacaoAlvo!;
    if (percentual >= 90.0) {
      return StandClassification.excelente;
    } else if (percentual >= 75.0) {
      return StandClassification.bom;
    } else if (percentual >= 60.0) {
      return StandClassification.regular;
    } else {
      return StandClassification.ruim;
    }
  }

  /// Retorna a cor do indicador visual baseada na classificação
  String get corIndicador {
    switch (classificacao) {
      case StandClassification.excelente:
        return '#4CAF50'; // Verde
      case StandClassification.bom:
        return '#8BC34A'; // Verde claro
      case StandClassification.regular:
        return '#FFC107'; // Amarelo
      case StandClassification.ruim:
        return '#F44336'; // Vermelho
      case StandClassification.naoAvaliado:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Retorna o texto da classificação em português
  String get classificacaoTexto {
    switch (classificacao) {
      case StandClassification.excelente:
        return 'Excelente';
      case StandClassification.bom:
        return 'Bom';
      case StandClassification.regular:
        return 'Regular';
      case StandClassification.ruim:
        return 'Ruim';
      case StandClassification.naoAvaliado:
        return 'Não Avaliado';
    }
  }

  /// Retorna a descrição da classificação
  String get classificacaoDescricao {
    switch (classificacao) {
      case StandClassification.excelente:
        return 'Estande excelente - população ideal atingida';
      case StandClassification.bom:
        return 'Estande bom - população adequada';
      case StandClassification.regular:
        return 'Estande regular - população abaixo do ideal';
      case StandClassification.ruim:
        return 'Estande ruim - população muito baixa';
      case StandClassification.naoAvaliado:
        return 'Estande não avaliado em relação à população alvo';
    }
  }

  /// Getters para compatibilidade com código existente
  double get actualPopulationPerHectare => populacaoRealPorHectare;
  double? get percentageAchievedTarget => percentualAtingidoPopulacaoAlvo;
}

/// Enum para classificação do estande
enum StandClassification {
  excelente, // >= 90%
  bom,       // 75% - 89%
  regular,   // 60% - 74%
  ruim,      // < 60%
  naoAvaliado, // Sem população alvo definida
}
