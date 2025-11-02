import '../models/planting_cv_model.dart';
import '../utils/logger.dart';

/// Serviço para gerar o card de resultado do CV% com todas as informações
/// Baseado no card mostrado na imagem: CV%, classificação, comparação com metas, sugestões
class PlantingCVResultCardService {
  static const String _tag = 'PlantingCVResultCardService';

  /// Gera o card de resultado completo do CV%
  static PlantingCVModel gerarCardResultado({
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
    required DateTime dataPlantio,
    required double comprimentoLinhaAmostrada,
    required double espacamentoEntreLinhas,
    required List<double> distanciasEntreSementes,
    required double mediaEspacamento,
    required double desvioPadrao,
    required double coeficienteVariacao,
    required double plantasPorMetro,
    required double populacaoEstimadaPorHectare,
    double? metaPopulacaoPorHectare,
    double? metaPlantasPorMetro,
    String observacoes = '',
  }) {
    Logger.info('$_tag: Gerando card de resultado para talhão: $talhaoNome');

    // Calcular classificação
    final classificacao = coeficienteVariacao.classificacao;

    // Gerar sugestões baseadas no CV%
    final sugestoes = _gerarSugestoes(coeficienteVariacao, classificacao);

    // Gerar motivo do resultado
    final motivoResultado = _gerarMotivoResultado(coeficienteVariacao, classificacao);

    // Gerar detalhes do cálculo
    final detalhesCalculo = _gerarDetalhesCalculo(
      distanciasEntreSementes,
      mediaEspacamento,
      desvioPadrao,
      coeficienteVariacao,
    );

    // Calcular comparações com metas
    final comparacoes = _calcularComparacoesComMetas(
      populacaoEstimadaPorHectare,
      plantasPorMetro,
      metaPopulacaoPorHectare,
      metaPlantasPorMetro,
    );

    // Gerar métricas detalhadas
    final metricasDetalhadas = _gerarMetricasDetalhadas(
      distanciasEntreSementes,
      mediaEspacamento,
      desvioPadrao,
      coeficienteVariacao,
      plantasPorMetro,
      populacaoEstimadaPorHectare,
    );

    final cvModel = PlantingCVModel(
      talhaoId: talhaoId,
      talhaoNome: talhaoNome,
      culturaId: culturaId,
      culturaNome: culturaNome,
      dataPlantio: dataPlantio,
      comprimentoLinhaAmostrada: comprimentoLinhaAmostrada,
      espacamentoEntreLinhas: espacamentoEntreLinhas,
      distanciasEntreSementes: distanciasEntreSementes,
      mediaEspacamento: mediaEspacamento,
      desvioPadrao: desvioPadrao,
      coeficienteVariacao: coeficienteVariacao,
      plantasPorMetro: plantasPorMetro,
      populacaoEstimadaPorHectare: populacaoEstimadaPorHectare,
      classificacao: classificacao,
      observacoes: observacoes,
      metaPopulacaoPorHectare: metaPopulacaoPorHectare,
      metaPlantasPorMetro: metaPlantasPorMetro,
      diferencaPopulacaoPercentual: comparacoes['diferencaPopulacao'],
      diferencaPlantasPorMetroPercentual: comparacoes['diferencaPlantasPorMetro'],
      statusComparacaoPopulacao: comparacoes['statusPopulacao'],
      statusComparacaoPlantasPorMetro: comparacoes['statusPlantasPorMetro'],
      sugestoes: sugestoes,
      motivoResultado: motivoResultado,
      detalhesCalculo: detalhesCalculo,
      metricasDetalhadas: metricasDetalhadas,
    );

    Logger.info('$_tag: Card de resultado gerado com sucesso');
    Logger.info('  - CV%: ${coeficienteVariacao.toStringAsFixed(2)}%');
    Logger.info('  - Classificação: ${classificacao.toString().split('.').last}');
    Logger.info('  - Sugestões: ${sugestoes.length}');
    Logger.info('  - Status População: ${comparacoes['statusPopulacao']}');
    Logger.info('  - Status Plantas/m: ${comparacoes['statusPlantasPorMetro']}');

    return cvModel;
  }

  /// Gera sugestões baseadas no CV% e classificação
  static List<String> _gerarSugestoes(double cv, CVClassification classificacao) {
    final sugestoes = <String>[];

    switch (classificacao) {
      case CVClassification.excelente:
        sugestoes.addAll([
          'Manter configuração atual da plantadora',
          'Continuar monitoramento da qualidade',
          'Documentar boas práticas utilizadas',
        ]);
        break;
      case CVClassification.bom:
        sugestoes.addAll([
          'Ajustar finamente a regulagem da plantadora',
          'Verificar uniformidade do terreno',
          'Reduzir velocidade de plantio se necessário',
        ]);
        break;
      case CVClassification.moderado:
        sugestoes.addAll([
          'Ajustar finamente a regulagem da plantadora',
          'Verificar uniformidade do terreno',
          'Reduzir velocidade de plantio se necessário',
          'Verificar profundidade de plantio',
          'Limpar mecanismos de distribuição',
        ]);
        break;
      case CVClassification.ruim:
        sugestoes.addAll([
          'Verificar regulagem completa da plantadora',
          'Verificar qualidade das sementes',
          'Verificar profundidade de plantio',
          'Limpar mecanismos de distribuição',
          'Verificar velocidade de plantio',
          'Considerar calibração dos discos',
        ]);
        break;
    }

    return sugestoes;
  }

  /// Gera motivo do resultado baseado no CV%
  static String _gerarMotivoResultado(double cv, CVClassification classificacao) {
    switch (classificacao) {
      case CVClassification.excelente:
        return 'Distribuição muito uniforme das sementes - excelente qualidade de plantio';
      case CVClassification.bom:
        return 'Distribuição boa das sementes - qualidade satisfatória com pequenos ajustes possíveis';
      case CVClassification.moderado:
        return 'Distribuição moderada das sementes - pode ser melhorada com ajustes na regulagem';
      case CVClassification.ruim:
        return 'Distribuição irregular das sementes - atenção necessária na regulagem da plantadora';
    }
  }

  /// Gera detalhes do cálculo
  static String _gerarDetalhesCalculo(
    List<double> distancias,
    double media,
    double desvioPadrao,
    double cv,
  ) {
    return '''
Cálculo do CV%:
- Número de medições: ${distancias.length}
- Média do espaçamento: ${media.toStringAsFixed(2)} cm
- Desvio padrão: ${desvioPadrao.toStringAsFixed(2)} cm
- Coeficiente de variação: ${cv.toStringAsFixed(2)}%
- Fórmula: CV% = (Desvio Padrão / Média) × 100
''';
  }

  /// Calcula comparações com metas
  static Map<String, dynamic> _calcularComparacoesComMetas(
    double populacaoAtual,
    double plantasPorMetroAtual,
    double? metaPopulacao,
    double? metaPlantasPorMetro,
  ) {
    final resultado = <String, dynamic>{};

    // Comparação de população
    if (metaPopulacao != null && metaPopulacao > 0) {
      final diferenca = ((populacaoAtual - metaPopulacao) / metaPopulacao * 100);
      resultado['diferencaPopulacao'] = diferenca;
      
      if (diferenca.abs() <= 5) {
        resultado['statusPopulacao'] = 'Dentro da meta';
      } else if (diferenca.abs() <= 15) {
        resultado['statusPopulacao'] = 'Próximo da meta';
      } else {
        resultado['statusPopulacao'] = 'Fora da meta';
      }
    } else {
      resultado['diferencaPopulacao'] = null;
      resultado['statusPopulacao'] = 'Meta não definida';
    }

    // Comparação de plantas por metro
    if (metaPlantasPorMetro != null && metaPlantasPorMetro > 0) {
      final diferenca = ((plantasPorMetroAtual - metaPlantasPorMetro) / metaPlantasPorMetro * 100);
      resultado['diferencaPlantasPorMetro'] = diferenca;
      
      if (diferenca.abs() <= 5) {
        resultado['statusPlantasPorMetro'] = 'Dentro da meta';
      } else if (diferenca.abs() <= 15) {
        resultado['statusPlantasPorMetro'] = 'Próximo da meta';
      } else {
        resultado['statusPlantasPorMetro'] = 'Fora da meta';
      }
    } else {
      resultado['diferencaPlantasPorMetro'] = null;
      resultado['statusPlantasPorMetro'] = 'Meta não definida';
    }

    return resultado;
  }

  /// Gera métricas detalhadas
  static Map<String, dynamic> _gerarMetricasDetalhadas(
    List<double> distancias,
    double media,
    double desvioPadrao,
    double cv,
    double plantasPorMetro,
    double populacaoHectare,
  ) {
    return {
      'numeroMedicoes': distancias.length,
      'mediaEspacamento': media,
      'desvioPadrao': desvioPadrao,
      'coeficienteVariacao': cv,
      'plantasPorMetro': plantasPorMetro,
      'populacaoHectare': populacaoHectare,
      'espacamentoMinimo': distancias.isNotEmpty ? distancias.reduce((a, b) => a < b ? a : b) : 0.0,
      'espacamentoMaximo': distancias.isNotEmpty ? distancias.reduce((a, b) => a > b ? a : b) : 0.0,
      'amplitude': distancias.isNotEmpty ? distancias.reduce((a, b) => a > b ? a : b) - distancias.reduce((a, b) => a < b ? a : b) : 0.0,
      'dataCalculo': DateTime.now().toIso8601String(),
    };
  }
}
