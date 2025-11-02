import '../models/planting_quality_report_model.dart';
import '../models/planting_cv_model.dart';
import '../database/models/estande_plantas_model.dart';
import '../models/talhao_model.dart';
import '../utils/logger.dart';

/// Serviço para geração de relatórios de qualidade de plantio
class PlantingQualityReportService {
  static const String _tag = 'PlantingQualityReportService';

  /// Gera um relatório de qualidade de plantio baseado nos dados de CV% e estande
  PlantingQualityReportModel gerarRelatorio({
    required PlantingCVModel cvData,
    required EstandePlantasModel estandeData,
    required TalhaoModel talhaoData,
    required String executor,
    String variedade = '',
    String safra = '',
    String? imagemEstandePath,
  }) {
    try {
      Logger.info('$_tag: Iniciando geração de relatório de qualidade de plantio');

      // Validar se há dados reais de CV%
      if (cvData.coeficienteVariacao == 0.0) {
        Logger.warning('$_tag: ⚠️ CV% não calculado - dados não disponíveis');
        return _gerarRelatorioSemCV(cvData, estandeData, talhaoData, executor, variedade, safra, imagemEstandePath);
      }

      // Calcular métricas derivadas
      final singulacao = _calcularSingulacao(cvData);
      final plantasDuplas = _calcularPlantasDuplas(cvData);
      final plantasFalhadas = _calcularPlantasFalhadas(cvData);
      final eficaciaEmergencia = _calcularEficaciaEmergencia(estandeData);
      final desvioPopulacao = _calcularDesvioPopulacao(estandeData);

      // Gerar análise automática
      final analiseAutomatica = _gerarAnaliseAutomatica(cvData, estandeData, singulacao);
      final sugestoes = _gerarSugestoes(cvData, estandeData, singulacao);
      final statusGeral = _determinarStatusGeral(cvData, estandeData, singulacao);

      // Criar o relatório
      final relatorio = PlantingQualityReportModel(
        talhaoId: talhaoData.id,
        talhaoNome: talhaoData.name,
        culturaId: cvData.culturaId,
        culturaNome: cvData.culturaNome,
        variedade: variedade,
        safra: safra,
        areaHectares: talhaoData.area ?? 0.0,
        dataPlantio: cvData.dataPlantio,
        dataAvaliacao: estandeData.dataAvaliacao ?? DateTime.now(),
        executor: executor,
        coeficienteVariacao: cvData.coeficienteVariacao,
        classificacaoCV: cvData.classificacaoTexto,
        plantasPorMetro: cvData.plantasPorMetro,
        populacaoEstimadaPorHectare: cvData.populacaoEstimadaPorHectare,
        singulacao: singulacao,
        plantasDuplas: plantasDuplas,
        plantasFalhadas: plantasFalhadas,
        populacaoAlvo: estandeData.populacaoIdeal ?? 0.0,
        populacaoReal: estandeData.plantasPorHectare ?? 0.0,
        eficaciaEmergencia: eficaciaEmergencia,
        desvioPopulacao: desvioPopulacao,
        analiseAutomatica: analiseAutomatica,
        sugestoes: sugestoes,
        statusGeral: statusGeral,
        imagemEstandePath: imagemEstandePath,
      );

      Logger.info('$_tag: ✅ Relatório gerado com sucesso: ${relatorio.id}');
      return relatorio;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Calcula a singulação real baseada nos dados de CV%
  /// Fórmula: Singulação (%) = 100 - (CV% × fator_correcao)
  double _calcularSingulacao(PlantingCVModel cvData) {
    // Singulação é inversamente proporcional ao CV%
    // Quanto menor o CV%, maior a singulação (melhor distribuição)
    
    final cv = cvData.coeficienteVariacao;
    
    // Fórmula agronômica: Singulação = 100 - (CV × 0.8)
    // Isso garante que:
    // - CV 5% → Singulação 96%
    // - CV 10% → Singulação 92%
    // - CV 15% → Singulação 88%
    // - CV 20% → Singulação 84%
    // - CV 30% → Singulação 76%
    
    double singulacao = 100.0 - (cv * 0.8);
    
    // Limitar entre 70% e 99%
    if (singulacao > 99.0) singulacao = 99.0;
    if (singulacao < 70.0) singulacao = 70.0;
    
    return singulacao;
  }

  /// Calcula o percentual real de plantas duplas baseado no CV%
  /// Fórmula: Plantas Duplas (%) = CV% × 0.15
  double _calcularPlantasDuplas(PlantingCVModel cvData) {
    // Plantas duplas aumentam proporcionalmente ao CV%
    // Quanto maior o CV%, mais problemas de distribuição (incluindo duplas)
    
    final cv = cvData.coeficienteVariacao;
    
    // Fórmula agronômica: Plantas duplas = CV × 0.15
    // Isso garante que:
    // - CV 5% → 0.75% duplas
    // - CV 10% → 1.5% duplas
    // - CV 15% → 2.25% duplas
    // - CV 20% → 3% duplas
    // - CV 30% → 4.5% duplas
    
    double plantasDuplas = cv * 0.15;
    
    // Limitar entre 0.5% e 10%
    if (plantasDuplas < 0.5) plantasDuplas = 0.5;
    if (plantasDuplas > 10.0) plantasDuplas = 10.0;
    
    return plantasDuplas;
  }

  /// Calcula o percentual real de plantas falhadas baseado no CV%
  /// Fórmula: Plantas Falhadas (%) = CV% × 0.12
  double _calcularPlantasFalhadas(PlantingCVModel cvData) {
    // Plantas falhadas aumentam proporcionalmente ao CV%
    // Quanto maior o CV%, mais falhas na distribuição
    
    final cv = cvData.coeficienteVariacao;
    
    // Fórmula agronômica: Plantas falhadas = CV × 0.12
    // Isso garante que:
    // - CV 5% → 0.6% falhadas
    // - CV 10% → 1.2% falhadas
    // - CV 15% → 1.8% falhadas
    // - CV 20% → 2.4% falhadas
    // - CV 30% → 3.6% falhadas
    
    double plantasFalhadas = cv * 0.12;
    
    // Limitar entre 0.5% e 8%
    if (plantasFalhadas < 0.5) plantasFalhadas = 0.5;
    if (plantasFalhadas > 8.0) plantasFalhadas = 8.0;
    
    return plantasFalhadas;
  }

  /// Calcula a eficácia de emergência
  double _calcularEficaciaEmergencia(EstandePlantasModel estandeData) {
    if (estandeData.populacaoIdeal == null || estandeData.populacaoIdeal! <= 0) {
      return 0.0;
    }
    
    final populacaoReal = estandeData.plantasPorHectare ?? 0.0;
    final populacaoIdeal = estandeData.populacaoIdeal!;
    
    return (populacaoReal / populacaoIdeal) * 100;
  }

  /// Calcula o desvio da população em relação ao alvo
  double _calcularDesvioPopulacao(EstandePlantasModel estandeData) {
    final populacaoReal = estandeData.plantasPorHectare ?? 0.0;
    final populacaoIdeal = estandeData.populacaoIdeal ?? 0.0;
    
    return populacaoReal - populacaoIdeal;
  }

  /// Gera análise automática baseada nos dados coletados
  String _gerarAnaliseAutomatica(
    PlantingCVModel cvData,
    EstandePlantasModel estandeData,
    double singulacao,
  ) {
    final List<String> analises = [];

    // Análise do CV%
    if (cvData.coeficienteVariacao < 10) {
      analises.add('Plantio com CV de ${cvData.coeficienteVariacao.toStringAsFixed(1)}% → excelente uniformidade');
    } else if (cvData.coeficienteVariacao < 20) {
      analises.add('Plantio com CV de ${cvData.coeficienteVariacao.toStringAsFixed(1)}% → boa uniformidade');
    } else if (cvData.coeficienteVariacao <= 30) {
      analises.add('Plantio com CV de ${cvData.coeficienteVariacao.toStringAsFixed(1)}% → uniformidade regular');
    } else {
      analises.add('Plantio com CV de ${cvData.coeficienteVariacao.toStringAsFixed(1)}% → atenção necessária');
    }

    // Análise da singulação
    if (singulacao >= 95) {
      analises.add('Singulação alta (${singulacao.toStringAsFixed(1)}%) garante excelente distribuição');
    } else if (singulacao >= 90) {
      analises.add('Singulação boa (${singulacao.toStringAsFixed(1)}%) garante boa distribuição');
    } else if (singulacao >= 85) {
      analises.add('Singulação moderada (${singulacao.toStringAsFixed(1)}%) - pode ser melhorada');
    } else {
      analises.add('Singulação baixa (${singulacao.toStringAsFixed(1)}%) - atenção necessária');
    }

    // Análise da população
    if (estandeData.populacaoIdeal != null && estandeData.plantasPorHectare != null) {
      final eficacia = _calcularEficaciaEmergencia(estandeData);
      if (eficacia >= 95) {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → resultado excelente');
      } else if (eficacia >= 90) {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → resultado muito satisfatório');
      } else if (eficacia >= 85) {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → resultado satisfatório');
      } else {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → atenção necessária');
      }
    }

    return analises.join('. ');
  }

  /// Gera sugestões baseadas nos dados coletados
  String _gerarSugestoes(
    PlantingCVModel cvData,
    EstandePlantasModel estandeData,
    double singulacao,
  ) {
    final List<String> sugestoes = [];

    // Sugestões baseadas no CV%
    if (cvData.coeficienteVariacao > 30) {
      sugestoes.add('URGENTE: Verificar regulagem da plantadeira');
      sugestoes.add('Calibrar dosadores de sementes');
      sugestoes.add('Verificar velocidade de plantio (máximo 6 km/h)');
    } else if (cvData.coeficienteVariacao > 20) {
      sugestoes.add('Ajustar finamente a regulagem da plantadeira');
      sugestoes.add('Verificar uniformidade do terreno');
      sugestoes.add('Reduzir velocidade de plantio se necessário');
    } else if (cvData.coeficienteVariacao > 10) {
      sugestoes.add('Verificar regulagem fina da plantadeira');
      sugestoes.add('Monitorar velocidade de plantio');
    } else {
      sugestoes.add('Excelente qualidade de plantio!');
      sugestoes.add('Manter as condições atuais');
    }

    // Sugestões baseadas na singulação
    if (singulacao < 90) {
      sugestoes.add('Verificar regulagem dos discos de plantio');
      sugestoes.add('Limpar mecanismos de distribuição');
    }

    // Sugestões baseadas na população
    if (estandeData.populacaoIdeal != null && estandeData.plantasPorHectare != null) {
      final eficacia = _calcularEficaciaEmergencia(estandeData);
      if (eficacia < 90) {
        sugestoes.add('Verificar qualidade das sementes');
        sugestoes.add('Ajustar profundidade de plantio');
        sugestoes.add('Verificar condições do solo');
      }
    }

    // Sugestão geral
    sugestoes.add('Acompanhar próximas áreas para manter padrão de regulagem');

    return sugestoes.join('. ');
  }

  /// Determina o status geral da qualidade do plantio
  String _determinarStatusGeral(
    PlantingCVModel cvData,
    EstandePlantasModel estandeData,
    double singulacao,
  ) {
    int pontos = 0;

    // Pontuação baseada no CV%
    if (cvData.coeficienteVariacao < 10) pontos += 3;
    else if (cvData.coeficienteVariacao < 20) pontos += 2;
    else if (cvData.coeficienteVariacao <= 30) pontos += 1;

    // Pontuação baseada na singulação
    if (singulacao >= 95) pontos += 3;
    else if (singulacao >= 90) pontos += 2;
    else if (singulacao >= 85) pontos += 1;

    // Pontuação baseada na eficácia de emergência
    if (estandeData.populacaoIdeal != null && estandeData.plantasPorHectare != null) {
      final eficacia = _calcularEficaciaEmergencia(estandeData);
      if (eficacia >= 95) pontos += 3;
      else if (eficacia >= 90) pontos += 2;
      else if (eficacia >= 85) pontos += 1;
    }

    // Determinar status baseado na pontuação
    if (pontos >= 8) return 'Alta qualidade';
    if (pontos >= 6) return 'Boa qualidade';
    if (pontos >= 4) return 'Regular';
    return 'Atenção';
  }

  /// Gera relatório quando não há dados de CV% (CV% = 0.0)
  PlantingQualityReportModel _gerarRelatorioSemCV(
    PlantingCVModel cvData,
    EstandePlantasModel estandeData,
    TalhaoModel talhaoData,
    String executor,
    String variedade,
    String safra,
    String? imagemEstandePath,
  ) {
    Logger.info('$_tag: Gerando relatório sem dados de CV% - solicitando cálculo');

    // Quando CV% = 0.0, todos os valores derivados também são 0.0
    const double cvZero = 0.0;
    const double singulacaoZero = 0.0;
    const double plantasDuplasZero = 0.0;
    const double plantasFalhadasZero = 0.0;
    
    // Calcular apenas dados que não dependem do CV%
    final eficaciaEmergencia = _calcularEficaciaEmergencia(estandeData);
    final desvioPopulacao = _calcularDesvioPopulacao(estandeData);

    // Análise específica para quando não há CV%
    final analiseAutomatica = _gerarAnaliseSemCV(cvData, estandeData);
    final sugestoes = _gerarSugestoesSemCV();
    const statusGeral = 'Dados Insuficientes';

    // Criar o relatório com valores zerados
    final relatorio = PlantingQualityReportModel(
      talhaoId: talhaoData.id,
      talhaoNome: talhaoData.name,
      culturaId: cvData.culturaId,
      culturaNome: cvData.culturaNome,
      variedade: variedade,
      safra: safra,
      areaHectares: talhaoData.area ?? 0.0,
      dataPlantio: cvData.dataPlantio,
      dataAvaliacao: estandeData.dataAvaliacao ?? DateTime.now(),
      executor: executor,
      coeficienteVariacao: cvZero,
      classificacaoCV: 'Não Calculado',
      plantasPorMetro: cvData.plantasPorMetro,
      populacaoEstimadaPorHectare: cvData.populacaoEstimadaPorHectare,
      singulacao: singulacaoZero,
      plantasDuplas: plantasDuplasZero,
      plantasFalhadas: plantasFalhadasZero,
      populacaoAlvo: estandeData.populacaoIdeal ?? 0.0,
      populacaoReal: estandeData.plantasPorHectare ?? 0.0,
      eficaciaEmergencia: eficaciaEmergencia,
      desvioPopulacao: desvioPopulacao,
      analiseAutomatica: analiseAutomatica,
      sugestoes: sugestoes,
      statusGeral: statusGeral,
      imagemEstandePath: imagemEstandePath,
    );

    Logger.info('$_tag: ✅ Relatório sem CV% gerado: ${relatorio.id}');
    return relatorio;
  }

  /// Gera análise automática quando não há dados de CV%
  String _gerarAnaliseSemCV(PlantingCVModel cvData, EstandePlantasModel estandeData) {
    final List<String> analises = [];

    analises.add('⚠️ CV% não calculado - dados de qualidade de plantio não disponíveis');
    analises.add('É necessário calcular o CV% durante o plantio para análise completa');

    // Análise da população (se disponível)
    if (estandeData.populacaoIdeal != null && estandeData.plantasPorHectare != null) {
      final eficacia = _calcularEficaciaEmergencia(estandeData);
      if (eficacia >= 95) {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → resultado excelente');
      } else if (eficacia >= 90) {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → resultado muito satisfatório');
      } else if (eficacia >= 85) {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → resultado satisfatório');
      } else {
        analises.add('População final atingiu ${eficacia.toStringAsFixed(1)}% da meta → atenção necessária');
      }
    } else {
      analises.add('Dados de população não disponíveis para análise');
    }

    return analises.join('. ');
  }

  /// Gera sugestões quando não há dados de CV%
  String _gerarSugestoesSemCV() {
    final List<String> sugestoes = [];

    sugestoes.add('URGENTE: Calcular CV% durante o plantio');
    sugestoes.add('Medir distâncias entre sementes em pelo menos 3 pontos do talhão');
    sugestoes.add('Registrar dados de qualidade da plantadeira');
    sugestoes.add('Calibrar dosadores antes do próximo plantio');
    sugestoes.add('Implementar controle de qualidade durante a operação');

    return sugestoes.join('. ');
  }

  /// Gera relatório com dados REAIS dos cálculos agronômicos
  PlantingQualityReportModel gerarRelatorioComDadosReais({
    required String talhaoNome,
    required String culturaNome,
    required String executor,
    required PlantingCVModel cvDataReal,
    required EstandePlantasModel estandeDataReal,
    required TalhaoModel talhaoDataReal,
    String variedade = '',
    String safra = '',
    String? imagemEstande,
  }) {
    Logger.info('$_tag: Gerando relatório com dados REAIS dos cálculos agronômicos');
    
    return gerarRelatorio(
      cvData: cvDataReal,
      estandeData: estandeDataReal,
      talhaoData: talhaoDataReal,
      executor: executor,
      variedade: variedade,
      safra: safra,
      imagemEstandePath: imagemEstande,
    );
  }
}
