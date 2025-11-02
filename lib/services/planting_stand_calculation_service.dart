import '../models/planting_stand_model.dart';
import '../utils/logger.dart';

/// Serviço para cálculos de Estande de Plantas
class PlantingStandCalculationService {
  static const String _tag = 'PlantingStandCalculationService';

  /// Calcula o estande baseado na contagem de plantas
  /// 
  /// Parâmetros:
  /// - plantasContadas: Número de plantas contadas
  /// - comprimentoLinhaAvaliado: Comprimento da linha em metros
  /// - numeroLinhasAvaliadas: Número de linhas avaliadas
  /// - espacamentoEntreLinhas: Espaçamento entre linhas em metros
  /// - populacaoAlvo: População alvo por hectare (opcional)
  /// 
  /// Retorna: PlantingStandModel com todos os cálculos realizados
  PlantingStandModel calcularEstande({
    required int plantasContadas,
    required double comprimentoLinhaAvaliado,
    required int numeroLinhasAvaliadas,
    required double espacamentoEntreLinhas,
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
    required DateTime dataAvaliacao,
    double? percentualGerminacaoTeorica,
    double? populacaoAlvo,
    String observacoes = '',
  }) {
    try {
      Logger.info('$_tag: Iniciando cálculo de estande');
      Logger.info('$_tag: Plantas contadas: $plantasContadas');
      Logger.info('$_tag: Comprimento linha: ${comprimentoLinhaAvaliado}m');
      Logger.info('$_tag: Número de linhas: $numeroLinhasAvaliadas');
      Logger.info('$_tag: Espaçamento entre linhas: ${espacamentoEntreLinhas}m');

      // Validar dados de entrada
      if (plantasContadas < 0) {
        throw ArgumentError('Número de plantas não pode ser negativo');
      }
      if (comprimentoLinhaAvaliado <= 0) {
        throw ArgumentError('Comprimento da linha deve ser maior que zero');
      }
      if (numeroLinhasAvaliadas <= 0) {
        throw ArgumentError('Número de linhas deve ser maior que zero');
      }
      if (espacamentoEntreLinhas <= 0) {
        throw ArgumentError('Espaçamento entre linhas deve ser maior que zero');
      }

      // 1. Calcular plantas por metro
      final plantasPorMetro = _calcularPlantasPorMetro(
        plantasContadas,
        comprimentoLinhaAvaliado,
        numeroLinhasAvaliadas,
      );
      Logger.info('$_tag: Plantas por metro: ${plantasPorMetro.toStringAsFixed(2)}');

      // 2. Calcular população real por hectare
      final populacaoRealPorHectare = _calcularPopulacaoPorHectare(
        plantasPorMetro,
        espacamentoEntreLinhas,
      );
      Logger.info('$_tag: População real/ha: ${populacaoRealPorHectare.toStringAsFixed(0)}');

      // 3. Calcular percentual atingido em relação à população alvo
      double? percentualAtingidoPopulacaoAlvo;
      if (populacaoAlvo != null && populacaoAlvo > 0) {
        percentualAtingidoPopulacaoAlvo = (populacaoRealPorHectare / populacaoAlvo) * 100;
        Logger.info('$_tag: Percentual atingido: ${percentualAtingidoPopulacaoAlvo.toStringAsFixed(1)}%');
      }

      // 4. Calcular desvio entre plantio e emergência (se houver dados de plantio)
      double? desvioPlantioEmergencia;
      // TODO: Integrar com dados de plantio para calcular o desvio

      // 5. Criar modelo com os resultados
      final standModel = PlantingStandModel(
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        dataAvaliacao: dataAvaliacao,
        comprimentoLinhaAvaliado: comprimentoLinhaAvaliado,
        numeroLinhasAvaliadas: numeroLinhasAvaliadas,
        espacamentoEntreLinhas: espacamentoEntreLinhas,
        plantasContadas: plantasContadas,
        percentualGerminacaoTeorica: percentualGerminacaoTeorica,
        populacaoAlvo: populacaoAlvo,
        plantasPorMetro: plantasPorMetro,
        populacaoRealPorHectare: populacaoRealPorHectare,
        percentualAtingidoPopulacaoAlvo: percentualAtingidoPopulacaoAlvo,
        desvioPlantioEmergencia: desvioPlantioEmergencia,
        observacoes: observacoes,
      );

      Logger.info('$_tag: ✅ Cálculo de estande concluído com sucesso');
      return standModel;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro no cálculo de estande: $e');
      rethrow;
    }
  }

  /// Calcula plantas por metro
  double _calcularPlantasPorMetro(
    int plantasContadas,
    double comprimentoLinhaAvaliado,
    int numeroLinhasAvaliadas,
  ) {
    final comprimentoTotal = comprimentoLinhaAvaliado * numeroLinhasAvaliadas;
    return plantasContadas / comprimentoTotal;
  }

  /// Calcula a população por hectare
  double _calcularPopulacaoPorHectare(double plantasPorMetro, double espacamentoEntreLinhas) {
    // Área de 1 hectare = 10.000 m²
    // Comprimento de linha por hectare = 10.000 / espacamentoEntreLinhas
    final comprimentoLinhaPorHectare = 10000 / espacamentoEntreLinhas;
    return plantasPorMetro * comprimentoLinhaPorHectare;
  }

  /// Retorna sugestões de melhoria baseadas no estande
  List<String> obterSugestoesMelhoria(PlantingStandModel estande) {
    final sugestoes = <String>[];

    if (estande.percentualAtingidoPopulacaoAlvo != null) {
      final percentual = estande.percentualAtingidoPopulacaoAlvo!;
      
      if (percentual < 60.0) {
        sugestoes.addAll([
          'Verificar qualidade das sementes',
          'Avaliar condições de solo e fertilidade',
          'Verificar profundidade de plantio',
          'Considerar replantio se necessário',
          'Avaliar condições climáticas durante a germinação',
          'Verificar presença de pragas ou doenças',
        ]);
      } else if (percentual < 75.0) {
        sugestoes.addAll([
          'Avaliar necessidade de adubação de cobertura',
          'Verificar condições de umidade do solo',
          'Monitorar desenvolvimento das plantas',
          'Considerar ajustes na próxima safra',
        ]);
      } else if (percentual < 90.0) {
        sugestoes.addAll([
          'Estande adequado, continuar monitoramento',
          'Avaliar necessidade de adubação suplementar',
          'Documentar as condições que levaram ao resultado',
        ]);
      } else {
        sugestoes.addAll([
          'Estande excelente - manter práticas atuais',
          'Documentar as boas práticas utilizadas',
          'Continuar monitoramento do desenvolvimento',
        ]);
      }
    } else {
      sugestoes.addAll([
        'Definir população alvo para melhor avaliação',
        'Continuar monitoramento do desenvolvimento',
        'Documentar condições de plantio e germinação',
      ]);
    }

    return sugestoes;
  }

  /// Retorna informações sobre população ideal para diferentes culturas
  Map<String, dynamic> obterInfoPopulacaoIdeal(String culturaNome) {
    final populacaoIdeal = <String, Map<String, dynamic>>{
      'Soja': {
        'populacaoIdeal': 300000,
        'populacaoMinima': 200000,
        'populacaoMaxima': 400000,
        'observacoes': 'Soja tem boa capacidade de compensação',
      },
      'Milho': {
        'populacaoIdeal': 60000,
        'populacaoMinima': 50000,
        'populacaoMaxima': 70000,
        'observacoes': 'Milho é sensível à população',
      },
      'Algodão': {
        'populacaoIdeal': 100000,
        'populacaoMinima': 80000,
        'populacaoMaxima': 120000,
        'observacoes': 'Algodão tem boa adaptabilidade',
      },
      'Feijão': {
        'populacaoIdeal': 250000,
        'populacaoMinima': 200000,
        'populacaoMaxima': 300000,
        'observacoes': 'Feijão pode compensar falhas',
      },
    };

    return populacaoIdeal[culturaNome] ?? {
      'populacaoIdeal': 200000,
      'populacaoMinima': 150000,
      'populacaoMaxima': 250000,
      'observacoes': 'Valores padrão para a cultura',
    };
  }

  /// Calcula o percentual de germinação baseado no estande
  double? calcularPercentualGerminacao({
    required PlantingStandModel estande,
    required double populacaoPlantada, // Plantas plantadas por hectare
  }) {
    if (populacaoPlantada <= 0) return null;
    
    return (estande.populacaoRealPorHectare / populacaoPlantada) * 100;
  }

  /// Analisa a qualidade do estande
  StandQualityAnalysis analisarQualidadeEstande(PlantingStandModel estande) {
    if (estande.percentualAtingidoPopulacaoAlvo == null) {
      return StandQualityAnalysis.dadosIncompletos;
    }

    final percentual = estande.percentualAtingidoPopulacaoAlvo!;
    
    if (percentual >= 90.0) {
      return StandQualityAnalysis.excelente;
    } else if (percentual >= 75.0) {
      return StandQualityAnalysis.bom;
    } else if (percentual >= 60.0) {
      return StandQualityAnalysis.regular;
    } else {
      return StandQualityAnalysis.ruim;
    }
  }
}

/// Enum para análise de qualidade do estande
enum StandQualityAnalysis {
  excelente,
  bom,
  regular,
  ruim,
  dadosIncompletos,
}
