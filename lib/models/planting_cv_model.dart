import 'package:uuid/uuid.dart';

/// Modelo para dados de Coeficiente de Variação do Plantio (CV%)
/// Representa a qualidade da distribuição de sementes durante o plantio
class PlantingCVModel {
  final String id;
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;
  final DateTime dataPlantio;
  final double comprimentoLinhaAmostrada; // em metros
  final double espacamentoEntreLinhas; // em metros
  final List<double> distanciasEntreSementes; // em cm
  final double mediaEspacamento; // em cm
  final double desvioPadrao; // em cm
  final double coeficienteVariacao; // CV% em porcentagem
  final double plantasPorMetro;
  final double populacaoEstimadaPorHectare;
  final CVClassification classificacao;
  final String observacoes;
  
  // Campos para comparação com metas
  final double? metaPopulacaoPorHectare;
  final double? metaPlantasPorMetro;
  final double? diferencaPopulacaoPercentual;
  final double? diferencaPlantasPorMetroPercentual;
  final String statusComparacaoPopulacao;
  final String statusComparacaoPlantasPorMetro;
  
  // Campos adicionais do card de resultado
  final List<String> sugestoes;
  final String motivoResultado;
  final String detalhesCalculo;
  final Map<String, dynamic> metricasDetalhadas;
  
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int syncStatus;

  PlantingCVModel({
    String? id,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
    required this.dataPlantio,
    required this.comprimentoLinhaAmostrada,
    required this.espacamentoEntreLinhas,
    required this.distanciasEntreSementes,
    required this.mediaEspacamento,
    required this.desvioPadrao,
    required this.coeficienteVariacao,
    required this.plantasPorMetro,
    required this.populacaoEstimadaPorHectare,
    required this.classificacao,
    this.observacoes = '',
    this.metaPopulacaoPorHectare,
    this.metaPlantasPorMetro,
    this.diferencaPopulacaoPercentual,
    this.diferencaPlantasPorMetroPercentual,
    this.statusComparacaoPopulacao = '',
    this.statusComparacaoPlantasPorMetro = '',
    this.sugestoes = const [],
    this.motivoResultado = '',
    this.detalhesCalculo = '',
    this.metricasDetalhadas = const {},
    DateTime? createdAt,
    this.updatedAt,
    this.syncStatus = 0,
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
      'data_plantio': dataPlantio.toIso8601String(),
      'comprimento_linha_amostrada': comprimentoLinhaAmostrada,
      'espacamento_entre_linhas': espacamentoEntreLinhas,
      'distancias_entre_sementes': distanciasEntreSementes.join(','),
      'media_espacamento': mediaEspacamento,
      'desvio_padrao': desvioPadrao,
      'coeficiente_variacao': coeficienteVariacao,
      'plantas_por_metro': plantasPorMetro,
      'populacao_estimada_hectare': populacaoEstimadaPorHectare,
      'classificacao': classificacao.toString().split('.').last,
      'observacoes': observacoes,
      'meta_populacao_hectare': metaPopulacaoPorHectare,
      'meta_plantas_metro': metaPlantasPorMetro,
      'diferenca_populacao_percentual': diferencaPopulacaoPercentual,
      'diferenca_plantas_metro_percentual': diferencaPlantasPorMetroPercentual,
      'status_comparacao_populacao': statusComparacaoPopulacao,
      'status_comparacao_plantas_metro': statusComparacaoPlantasPorMetro,
      'sugestoes': sugestoes.join('|'),
      'motivo_resultado': motivoResultado,
      'detalhes_calculo': detalhesCalculo,
      'metricas_detalhadas': metricasDetalhadas.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  /// Cria a partir de Map
  factory PlantingCVModel.fromMap(Map<String, dynamic> map) {
    return PlantingCVModel(
      id: map['id'] ?? '',
      talhaoId: map['talhao_id'] ?? '',
      talhaoNome: map['talhao_nome'] ?? '',
      culturaId: map['cultura_id'] ?? '',
      culturaNome: map['cultura_nome'] ?? '',
      dataPlantio: DateTime.parse(map['data_plantio'] ?? DateTime.now().toIso8601String()),
      comprimentoLinhaAmostrada: (map['comprimento_linha_amostrada'] ?? 0.0).toDouble(),
      espacamentoEntreLinhas: (map['espacamento_entre_linhas'] ?? 0.0).toDouble(),
      distanciasEntreSementes: (map['distancias_entre_sementes'] ?? '')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList(),
      mediaEspacamento: (map['media_espacamento'] ?? 0.0).toDouble(),
      desvioPadrao: (map['desvio_padrao'] ?? 0.0).toDouble(),
      coeficienteVariacao: (map['coeficiente_variacao'] ?? 0.0).toDouble(),
      plantasPorMetro: (map['plantas_por_metro'] ?? 0.0).toDouble(),
      populacaoEstimadaPorHectare: (map['populacao_estimada_hectare'] ?? 0.0).toDouble(),
      classificacao: CVClassification.values.firstWhere(
        (e) => e.toString().split('.').last == map['classificacao'],
        orElse: () => CVClassification.ruim,
      ),
      observacoes: map['observacoes'] ?? '',
      metaPopulacaoPorHectare: map['meta_populacao_hectare']?.toDouble(),
      metaPlantasPorMetro: map['meta_plantas_metro']?.toDouble(),
      diferencaPopulacaoPercentual: map['diferenca_populacao_percentual']?.toDouble(),
      diferencaPlantasPorMetroPercentual: map['diferenca_plantas_metro_percentual']?.toDouble(),
      statusComparacaoPopulacao: map['status_comparacao_populacao'] ?? '',
      statusComparacaoPlantasPorMetro: map['status_comparacao_plantas_metro'] ?? '',
      sugestoes: (map['sugestoes'] ?? '').toString().split('|').where((e) => e.isNotEmpty).toList(),
      motivoResultado: map['motivo_resultado'] ?? '',
      detalhesCalculo: map['detalhes_calculo'] ?? '',
      metricasDetalhadas: _parseMetricasDetalhadas(map['metricas_detalhadas']),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      syncStatus: map['sync_status'] ?? 0,
    );
  }

  /// Cria uma cópia com novos valores
  PlantingCVModel copyWith({
    String? id,
    String? talhaoId,
    String? talhaoNome,
    String? culturaId,
    String? culturaNome,
    DateTime? dataPlantio,
    double? comprimentoLinhaAmostrada,
    double? espacamentoEntreLinhas,
    List<double>? distanciasEntreSementes,
    double? mediaEspacamento,
    double? desvioPadrao,
    double? coeficienteVariacao,
    double? plantasPorMetro,
    double? populacaoEstimadaPorHectare,
    CVClassification? classificacao,
    String? observacoes,
    double? metaPopulacaoPorHectare,
    double? metaPlantasPorMetro,
    double? diferencaPopulacaoPercentual,
    double? diferencaPlantasPorMetroPercentual,
    String? statusComparacaoPopulacao,
    String? statusComparacaoPlantasPorMetro,
    List<String>? sugestoes,
    String? motivoResultado,
    String? detalhesCalculo,
    Map<String, dynamic>? metricasDetalhadas,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return PlantingCVModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      culturaId: culturaId ?? this.culturaId,
      culturaNome: culturaNome ?? this.culturaNome,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      comprimentoLinhaAmostrada: comprimentoLinhaAmostrada ?? this.comprimentoLinhaAmostrada,
      espacamentoEntreLinhas: espacamentoEntreLinhas ?? this.espacamentoEntreLinhas,
      distanciasEntreSementes: distanciasEntreSementes ?? this.distanciasEntreSementes,
      mediaEspacamento: mediaEspacamento ?? this.mediaEspacamento,
      desvioPadrao: desvioPadrao ?? this.desvioPadrao,
      coeficienteVariacao: coeficienteVariacao ?? this.coeficienteVariacao,
      plantasPorMetro: plantasPorMetro ?? this.plantasPorMetro,
      populacaoEstimadaPorHectare: populacaoEstimadaPorHectare ?? this.populacaoEstimadaPorHectare,
      classificacao: classificacao ?? this.classificacao,
      observacoes: observacoes ?? this.observacoes,
      metaPopulacaoPorHectare: metaPopulacaoPorHectare ?? this.metaPopulacaoPorHectare,
      metaPlantasPorMetro: metaPlantasPorMetro ?? this.metaPlantasPorMetro,
      diferencaPopulacaoPercentual: diferencaPopulacaoPercentual ?? this.diferencaPopulacaoPercentual,
      diferencaPlantasPorMetroPercentual: diferencaPlantasPorMetroPercentual ?? this.diferencaPlantasPorMetroPercentual,
      statusComparacaoPopulacao: statusComparacaoPopulacao ?? this.statusComparacaoPopulacao,
      statusComparacaoPlantasPorMetro: statusComparacaoPlantasPorMetro ?? this.statusComparacaoPlantasPorMetro,
      sugestoes: sugestoes ?? this.sugestoes,
      motivoResultado: motivoResultado ?? this.motivoResultado,
      detalhesCalculo: detalhesCalculo ?? this.detalhesCalculo,
      metricasDetalhadas: metricasDetalhadas ?? this.metricasDetalhadas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  /// Retorna a cor do indicador visual baseada na classificação
  String get corIndicador {
    switch (classificacao) {
      case CVClassification.excelente:
        return '#4CAF50'; // Verde
      case CVClassification.bom:
        return '#8BC34A'; // Verde claro
      case CVClassification.moderado:
        return '#FFC107'; // Amarelo
      case CVClassification.ruim:
        return '#F44336'; // Vermelho
    }
  }

  /// Retorna o texto da classificação em português
  String get classificacaoTexto {
    switch (classificacao) {
      case CVClassification.excelente:
        return 'Excelente';
      case CVClassification.bom:
        return 'Bom';
      case CVClassification.moderado:
        return 'Moderado';
      case CVClassification.ruim:
        return 'Ruim';
    }
  }

  /// Retorna a descrição da classificação
  String get classificacaoDescricao {
    switch (classificacao) {
      case CVClassification.excelente:
        return 'Distribuição muito uniforme das sementes - excelente qualidade';
      case CVClassification.bom:
        return 'Distribuição boa das sementes - qualidade satisfatória';
      case CVClassification.moderado:
        return 'Distribuição moderada das sementes - pode ser melhorada';
      case CVClassification.ruim:
        return 'Distribuição irregular das sementes - atenção necessária';
    }
  }

  /// Getter para compatibilidade com código existente
  double get cvPercentage => coeficienteVariacao;

  /// Verifica se há metas definidas para comparação
  bool get temMetasDefinidas => 
      metaPopulacaoPorHectare != null || metaPlantasPorMetro != null;

  /// Retorna o status da comparação de população
  String get statusPopulacaoTexto {
    if (metaPopulacaoPorHectare == null) return 'Meta não definida';
    return statusComparacaoPopulacao;
  }

  /// Retorna o status da comparação de plantas por metro
  String get statusPlantasPorMetroTexto {
    if (metaPlantasPorMetro == null) return 'Meta não definida';
    return statusComparacaoPlantasPorMetro;
  }

  /// Método auxiliar para parsear métricas detalhadas
  static Map<String, dynamic> _parseMetricasDetalhadas(dynamic value) {
    if (value == null) return {};
    
    try {
      if (value is Map<String, dynamic>) {
        return value;
      } else if (value is String) {
        // Tentar fazer parse de JSON string
        final entries = value.split(',').map((e) {
          final parts = e.split(':');
          if (parts.length == 2) {
            return MapEntry(parts[0].trim(), parts[1].trim());
          }
          return MapEntry(e, '');
        });
        return Map<String, dynamic>.fromEntries(entries);
      }
    } catch (e) {
      // Em caso de erro, retornar mapa vazio
    }
    
    return {};
  }

  /// Retorna a cor do indicador de comparação de população
  String get corComparacaoPopulacao {
    if (metaPopulacaoPorHectare == null) return '#9E9E9E'; // Cinza
    switch (statusComparacaoPopulacao) {
      case 'Dentro da meta':
        return '#4CAF50'; // Verde
      case 'Próximo da meta':
        return '#FFC107'; // Amarelo
      case 'Fora da meta':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }

  /// Retorna a cor do indicador de comparação de plantas por metro
  String get corComparacaoPlantasPorMetro {
    if (metaPlantasPorMetro == null) return '#9E9E9E'; // Cinza
    switch (statusComparacaoPlantasPorMetro) {
      case 'Dentro da meta':
        return '#4CAF50'; // Verde
      case 'Próximo da meta':
        return '#FFC107'; // Amarelo
      case 'Fora da meta':
        return '#F44336'; // Vermelho
      default:
        return '#9E9E9E'; // Cinza
    }
  }
}

/// Enum para classificação do CV%
enum CVClassification {
  excelente, // < 10%
  bom,       // 10% - 20%
  moderado,  // 20% - 30%
  ruim,      // > 30%
}

/// Extensão para facilitar a classificação do CV%
extension CVClassificationExtension on double {
  CVClassification get classificacao {
    if (this < 10.0) {
      return CVClassification.excelente;
    } else if (this < 20.0) {
      return CVClassification.bom;
    } else if (this <= 30.0) {
      return CVClassification.moderado;
    } else {
      return CVClassification.ruim;
    }
  }
}
