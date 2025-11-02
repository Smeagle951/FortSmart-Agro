import 'dart:math';
import '../models/planting_cv_model.dart';
import '../utils/logger.dart';
import '../database/repositories/planting_cv_repository.dart';

/// Serviço para cálculos de Coeficiente de Variação do Plantio (CV%)
class PlantingCVCalculationService {
  static const String _tag = 'PlantingCVCalculationService';
  final PlantingCVRepository _repository = PlantingCVRepository();

  /// Calcula o CV% baseado nas distâncias entre sementes
  /// 
  /// Parâmetros:
  /// - distanciasEntreSementes: Lista de distâncias em cm
  /// - comprimentoLinhaAmostrada: Comprimento da linha em metros
  /// - espacamentoEntreLinhas: Espaçamento entre linhas em metros
  /// - metaPopulacaoPorHectare: Meta desejada de população por hectare (opcional)
  /// - metaPlantasPorMetro: Meta desejada de plantas por metro (opcional)
  /// 
  /// Retorna: PlantingCVModel com todos os cálculos realizados
  PlantingCVModel calcularCV({
    required List<double> distanciasEntreSementes,
    required double comprimentoLinhaAmostrada,
    required double espacamentoEntreLinhas,
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
    required DateTime dataPlantio,
    String observacoes = '',
    double? metaPopulacaoPorHectare,
    double? metaPlantasPorMetro,
  }) {
    try {
      Logger.info('$_tag: Iniciando cálculo de CV%');
      Logger.info('$_tag: Distâncias: ${distanciasEntreSementes.length} medições');
      Logger.info('$_tag: Comprimento linha: ${comprimentoLinhaAmostrada}m');
      Logger.info('$_tag: Espaçamento entre linhas: ${espacamentoEntreLinhas}m');

      // Validar dados de entrada
      if (distanciasEntreSementes.isEmpty) {
        throw ArgumentError('Lista de distâncias não pode estar vazia');
      }
      if (comprimentoLinhaAmostrada <= 0) {
        throw ArgumentError('Comprimento da linha deve ser maior que zero');
      }
      if (espacamentoEntreLinhas <= 0) {
        throw ArgumentError('Espaçamento entre linhas deve ser maior que zero');
      }

      // 1. Converter distâncias acumuladas para espaçamentos individuais
      final espacamentosIndividuais = _converterDistanciasAcumuladasParaEspacamentos(distanciasEntreSementes);
      Logger.info('$_tag: Espaçamentos individuais calculados: ${espacamentosIndividuais.length} valores');
      
      // 2. Calcular média do espaçamento
      final mediaEspacamento = _calcularMedia(espacamentosIndividuais);
      Logger.info('$_tag: Média do espaçamento: ${mediaEspacamento.toStringAsFixed(2)} cm');

      // 3. Calcular desvio-padrão
      final desvioPadrao = _calcularDesvioPadrao(espacamentosIndividuais, mediaEspacamento);
      Logger.info('$_tag: Desvio-padrão: ${desvioPadrao.toStringAsFixed(2)} cm');

      // 4. Calcular CV%
      final coeficienteVariacao = (desvioPadrao / mediaEspacamento) * 100;
      Logger.info('$_tag: CV%: ${coeficienteVariacao.toStringAsFixed(2)}%');

      // 5. Calcular plantas por metro
      final plantasPorMetro = 100 / mediaEspacamento;
      Logger.info('$_tag: Plantas por metro: ${plantasPorMetro.toStringAsFixed(2)}');

      // 6. Calcular população estimada por hectare
      final populacaoEstimadaPorHectare = _calcularPopulacaoPorHectare(
        plantasPorMetro,
        espacamentoEntreLinhas,
      );
      Logger.info('$_tag: População estimada/ha: ${populacaoEstimadaPorHectare.toStringAsFixed(0)}');

      // 7. Classificar o CV%
      final classificacao = coeficienteVariacao.classificacao;
      Logger.info('$_tag: Classificação: ${classificacao.toString().split('.').last}');

      // 8. Calcular comparações com metas (se fornecidas)
      final comparacoes = _calcularComparacoesComMetas(
        populacaoEstimadaPorHectare,
        plantasPorMetro,
        metaPopulacaoPorHectare,
        metaPlantasPorMetro,
      );

      // 9. Criar modelo com os resultados
      final cvModel = PlantingCVModel(
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        dataPlantio: dataPlantio,
        comprimentoLinhaAmostrada: comprimentoLinhaAmostrada,
        espacamentoEntreLinhas: espacamentoEntreLinhas,
        distanciasEntreSementes: espacamentosIndividuais,
        mediaEspacamento: mediaEspacamento,
        desvioPadrao: desvioPadrao,
        coeficienteVariacao: coeficienteVariacao,
        plantasPorMetro: plantasPorMetro,
        populacaoEstimadaPorHectare: populacaoEstimadaPorHectare,
        classificacao: classificacao,
        observacoes: observacoes,
        metaPopulacaoPorHectare: metaPopulacaoPorHectare,
        metaPlantasPorMetro: metaPlantasPorMetro,
        diferencaPopulacaoPercentual: comparacoes['diferencaPopulacaoPercentual'],
        diferencaPlantasPorMetroPercentual: comparacoes['diferencaPlantasPorMetroPercentual'],
        statusComparacaoPopulacao: comparacoes['statusPopulacao'],
        statusComparacaoPlantasPorMetro: comparacoes['statusPlantasPorMetro'],
      );

      Logger.info('$_tag: ✅ Cálculo de CV% concluído com sucesso');
      return cvModel;

    } catch (e) {
      Logger.error('$_tag: ❌ Erro no cálculo de CV%: $e');
      rethrow;
    }
  }

  /// Converte posições das sementes para espaçamentos individuais
  /// Exemplo: [1, 8, 15, 23] -> [7, 7, 8] (diferenças entre posições consecutivas)
  /// As posições são medidas em cm desde o início da linha de plantio
  List<double> _converterDistanciasAcumuladasParaEspacamentos(List<double> posicoesSementes) {
    if (posicoesSementes.length < 2) return [];
    
    final espacamentos = <double>[];
    
    // Calcular espaçamentos entre sementes consecutivas
    for (int i = 1; i < posicoesSementes.length; i++) {
      final espacamento = posicoesSementes[i] - posicoesSementes[i - 1];
      espacamentos.add(espacamento);
    }
    
    return espacamentos;
  }

  /// Calcula a média de uma lista de valores
  double _calcularMedia(List<double> valores) {
    if (valores.isEmpty) return 0.0;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  /// Calcula o desvio-padrão de uma lista de valores
  double _calcularDesvioPadrao(List<double> valores, double media) {
    if (valores.length <= 1) return 0.0;
    
    final somaQuadrados = valores
        .map((valor) => pow(valor - media, 2))
        .reduce((a, b) => a + b);
    
    final variancia = somaQuadrados / (valores.length - 1);
    return sqrt(variancia);
  }

  /// Calcula a população estimada por hectare
  double _calcularPopulacaoPorHectare(double plantasPorMetro, double espacamentoEntreLinhas) {
    // Área de 1 hectare = 10.000 m²
    // Comprimento de linha por hectare = 10.000 / espacamentoEntreLinhas
    final comprimentoLinhaPorHectare = 10000 / espacamentoEntreLinhas;
    return plantasPorMetro * comprimentoLinhaPorHectare;
  }

  /// Calcula as comparações com as metas fornecidas
  Map<String, dynamic> _calcularComparacoesComMetas(
    double populacaoAtual,
    double plantasPorMetroAtual,
    double? metaPopulacao,
    double? metaPlantasPorMetro,
  ) {
    final resultado = <String, dynamic>{};
    
    // Comparação de população
    if (metaPopulacao != null && metaPopulacao > 0) {
      final diferencaPopulacao = ((populacaoAtual - metaPopulacao) / metaPopulacao) * 100;
      final statusPopulacao = _determinarStatusComparacao(diferencaPopulacao);
      
      resultado['diferencaPopulacaoPercentual'] = diferencaPopulacao;
      resultado['statusPopulacao'] = statusPopulacao;
      
      Logger.info('$_tag: Comparação população - Meta: ${metaPopulacao.toStringAsFixed(0)}, Atual: ${populacaoAtual.toStringAsFixed(0)}, Diferença: ${diferencaPopulacao.toStringAsFixed(2)}%');
    } else {
      resultado['diferencaPopulacaoPercentual'] = null;
      resultado['statusPopulacao'] = '';
    }
    
    // Comparação de plantas por metro
    if (metaPlantasPorMetro != null && metaPlantasPorMetro > 0) {
      final diferencaPlantasPorMetro = ((plantasPorMetroAtual - metaPlantasPorMetro) / metaPlantasPorMetro) * 100;
      final statusPlantasPorMetro = _determinarStatusComparacao(diferencaPlantasPorMetro);
      
      resultado['diferencaPlantasPorMetroPercentual'] = diferencaPlantasPorMetro;
      resultado['statusPlantasPorMetro'] = statusPlantasPorMetro;
      
      Logger.info('$_tag: Comparação plantas/m - Meta: ${metaPlantasPorMetro.toStringAsFixed(2)}, Atual: ${plantasPorMetroAtual.toStringAsFixed(2)}, Diferença: ${diferencaPlantasPorMetro.toStringAsFixed(2)}%');
    } else {
      resultado['diferencaPlantasPorMetroPercentual'] = null;
      resultado['statusPlantasPorMetro'] = '';
    }
    
    return resultado;
  }

  /// Determina o status da comparação baseado na diferença percentual
  String _determinarStatusComparacao(double diferencaPercentual) {
    final diferencaAbsoluta = diferencaPercentual.abs();
    
    if (diferencaAbsoluta <= 5.0) {
      return 'Dentro da meta';
    } else if (diferencaAbsoluta <= 15.0) {
      return 'Próximo da meta';
    } else {
      return 'Fora da meta';
    }
  }

  /// Valida se as distâncias estão dentro de parâmetros aceitáveis
  bool validarDistancias(List<double> distancias) {
    if (distancias.isEmpty) return false;
    
    // Verificar se todas as distâncias são positivas
    if (distancias.any((d) => d <= 0)) return false;
    
    // Verificar se não há valores extremos (muito pequenos ou muito grandes)
    final media = _calcularMedia(distancias);
    final desvio = _calcularDesvioPadrao(distancias, media);
    
    // Valores muito distantes da média (mais de 3 desvios-padrão) são suspeitos
    final limiteInferior = media - (3 * desvio);
    final limiteSuperior = media + (3 * desvio);
    
    return !distancias.any((d) => d < limiteInferior || d > limiteSuperior);
  }

  /// Retorna sugestões de melhoria baseadas no CV%
  List<String> obterSugestoesMelhoria(double cvPercentual) {
    final sugestoes = <String>[];

    if (cvPercentual > 30.0) {
      sugestoes.addAll([
        'URGENTE: Verificar regulagem da plantadeira',
        'Calibrar dosadores de sementes',
        'Verificar velocidade de plantio (máximo 6 km/h)',
        'Limpar e lubrificar mecanismos de distribuição',
        'Verificar pressão dos pneus da plantadeira',
        'Considerar troca de discos de plantio',
        'Verificar qualidade das sementes',
      ]);
    } else if (cvPercentual > 20.0) {
      sugestoes.addAll([
        'Ajustar finamente a regulagem da plantadeira',
        'Verificar uniformidade do terreno',
        'Reduzir velocidade de plantio se necessário',
        'Verificar profundidade de plantio',
        'Limpar mecanismos de distribuição',
      ]);
    } else if (cvPercentual > 10.0) {
      sugestoes.addAll([
        'Verificar regulagem fina da plantadeira',
        'Monitorar velocidade de plantio',
        'Verificar condições do solo',
        'Manter manutenção preventiva',
      ]);
    } else {
      sugestoes.addAll([
        'Excelente qualidade de plantio!',
        'Manter as condições atuais',
        'Continuar monitorando a qualidade',
        'Documentar as boas práticas utilizadas',
      ]);
    }

    return sugestoes;
  }

  /// Retorna informações sobre o CV% ideal para diferentes culturas
  Map<String, dynamic> obterInfoCVIdeal(String culturaNome) {
    final cvIdeal = <String, Map<String, dynamic>>{
      'Soja': {
        'cvIdeal': 15.0,
        'cvAceitavel': 25.0,
        'populacaoIdeal': 300000,
        'observacoes': 'Soja é sensível à irregularidade de plantio',
      },
      'Milho': {
        'cvIdeal': 12.0,
        'cvAceitavel': 20.0,
        'populacaoIdeal': 60000,
        'observacoes': 'Milho requer alta precisão no espaçamento',
      },
      'Algodão': {
        'cvIdeal': 18.0,
        'cvAceitavel': 30.0,
        'populacaoIdeal': 100000,
        'observacoes': 'Algodão tem maior tolerância à irregularidade',
      },
      'Feijão': {
        'cvIdeal': 20.0,
        'cvAceitavel': 35.0,
        'populacaoIdeal': 250000,
        'observacoes': 'Feijão pode compensar irregularidades',
      },
    };

    return cvIdeal[culturaNome] ?? {
      'cvIdeal': 15.0,
      'cvAceitavel': 25.0,
      'populacaoIdeal': 200000,
      'observacoes': 'Valores padrão para a cultura',
    };
  }

  /// Salva o resultado do cálculo de CV% no banco de dados
  Future<String> salvarCV(PlantingCVModel cvModel) async {
    try {
      Logger.info('$_tag: Salvando CV% no banco de dados...');
      final id = await _repository.salvar(cvModel);
      Logger.info('$_tag: ✅ CV% salvo com sucesso: $id');
      return id;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao salvar CV%: $e');
      rethrow;
    }
  }

  /// Busca todos os registros de CV%
  Future<List<PlantingCVModel>> buscarTodosCV() async {
    try {
      Logger.info('$_tag: Buscando todos os CV%...');
      final cvs = await _repository.buscarTodos();
      Logger.info('$_tag: ✅ ${cvs.length} registros de CV% encontrados');
      return cvs;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar CV%: $e');
      return [];
    }
  }

  /// Busca CV% por talhão
  Future<List<PlantingCVModel>> buscarCVPorTalhao(String talhaoId) async {
    try {
      Logger.info('$_tag: Buscando CV% para talhão: $talhaoId');
      final cvs = await _repository.buscarPorTalhao(talhaoId);
      Logger.info('$_tag: ✅ ${cvs.length} registros de CV% encontrados para o talhão');
      return cvs;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar CV% por talhão: $e');
      return [];
    }
  }

  /// Busca o CV% mais recente de um talhão
  Future<PlantingCVModel?> buscarCVMaisRecentePorTalhao(String talhaoId) async {
    try {
      Logger.info('$_tag: Buscando CV% mais recente para talhão: $talhaoId');
      final cv = await _repository.buscarMaisRecentePorTalhao(talhaoId);
      if (cv != null) {
        Logger.info('$_tag: ✅ CV% mais recente encontrado: ${cv.id}');
      } else {
        Logger.info('$_tag: ⚠️ Nenhum CV% encontrado para o talhão');
      }
      return cv;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao buscar CV% mais recente: $e');
      return null;
    }
  }

  /// Calcula e salva o CV% em uma única operação
  Future<PlantingCVModel> calcularESalvarCV({
    required List<double> distanciasEntreSementes,
    required double comprimentoLinhaAmostrada,
    required double espacamentoEntreLinhas,
    required String talhaoId,
    required String talhaoNome,
    required String culturaId,
    required String culturaNome,
    required DateTime dataPlantio,
    String observacoes = '',
    double? metaPopulacaoPorHectare,
    double? metaPlantasPorMetro,
  }) async {
    try {
      Logger.info('$_tag: Iniciando cálculo e salvamento de CV%...');
      
      // Calcular CV%
      final cvModel = calcularCV(
        distanciasEntreSementes: distanciasEntreSementes,
        comprimentoLinhaAmostrada: comprimentoLinhaAmostrada,
        espacamentoEntreLinhas: espacamentoEntreLinhas,
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        culturaId: culturaId,
        culturaNome: culturaNome,
        dataPlantio: dataPlantio,
        observacoes: observacoes,
        metaPopulacaoPorHectare: metaPopulacaoPorHectare,
        metaPlantasPorMetro: metaPlantasPorMetro,
      );
      
      // Salvar no banco
      await salvarCV(cvModel);
      
      Logger.info('$_tag: ✅ Cálculo e salvamento concluídos com sucesso');
      return cvModel;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no cálculo e salvamento: $e');
      rethrow;
    }
  }

  /// Obtém estatísticas dos CV% salvos
  Future<Map<String, dynamic>> obterEstatisticasCV() async {
    try {
      Logger.info('$_tag: Obtendo estatísticas de CV%...');
      final estatisticas = await _repository.obterEstatisticas();
      Logger.info('$_tag: ✅ Estatísticas obtidas: ${estatisticas['total']} registros');
      return estatisticas;
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'excelente': 0,
        'bom': 0,
        'moderado': 0,
        'ruim': 0,
        'percentual_excelente': 0.0,
        'percentual_bom': 0.0,
        'percentual_moderado': 0.0,
        'percentual_ruim': 0.0,
      };
    }
  }
}
