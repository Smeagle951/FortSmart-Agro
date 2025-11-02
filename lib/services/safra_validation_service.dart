import 'package:intl/intl.dart';
import '../services/plantio_integration_service.dart';
import '../services/plantio_complete_data_service.dart';
import '../database/repositories/historico_plantio_repository.dart';
import '../services/talhao_service.dart';

/// Serviço de validação por safra
/// Integra dados de plantio para gerar relatórios completos por safra
class SafraValidationService {
  static final SafraValidationService _instance = SafraValidationService._internal();
  factory SafraValidationService() => _instance;
  SafraValidationService._internal();

  final PlantioIntegrationService _plantioService = PlantioIntegrationService();
  final PlantioCompleteDataService _completeDataService = PlantioCompleteDataService();
  final HistoricoPlantioRepository _historicoRepository = HistoricoPlantioRepository();
  final TalhaoService _talhaoService = TalhaoService();

  /// Gera relatório de validação por safra
  /// NOVO: Usando PlantioCompleteDataService para dados unificados
  Future<Map<String, dynamic>> gerarRelatorioValidacaoSafra({
    String? safraId,
    String? culturaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      print('🔄 VALIDAÇÃO SAFRA: Gerando relatório COMPLETO...');
      
      // 🎯 USAR O SERVIÇO COMPLETO - PEGA TUDO DE UMA VEZ!
      final estatisticasCompletas = await _completeDataService.gerarEstatisticasAgregadas(
        safraId: safraId,
        culturaId: culturaId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      
      print('📊 VALIDAÇÃO SAFRA: Estatísticas completas geradas');
      print('   Total Plantios: ${estatisticasCompletas['total_plantios']}');
      print('   Com Estande: ${estatisticasCompletas['cobertura_dados']['com_estande']}');
      print('   Com CV%: ${estatisticasCompletas['cobertura_dados']['com_cv']}');
      print('   Com Fenologia: ${estatisticasCompletas['cobertura_dados']['com_fenologia']}');
      print('   Score Qualidade: ${estatisticasCompletas['qualidade_geral']['score']}');
      
      // Montar relatório no formato esperado pelo dashboard
      return {
        'metadata': {
          'gerado_em': DateTime.now().toIso8601String(),
          'periodo': {
            'inicio': dataInicio?.toIso8601String(),
            'fim': dataFim?.toIso8601String(),
          },
          'filtros': {
            'safra_id': safraId,
            'cultura_id': culturaId,
          },
          'total_plantios': estatisticasCompletas['total_plantios'],
        },
        'estatisticas_gerais': {
          'total_plantios': estatisticasCompletas['total_plantios'],
          'culturas': estatisticasCompletas['culturas'],
          'talhoes': estatisticasCompletas['talhoes'],
          'variedades': estatisticasCompletas['variedades'],
          'medias': estatisticasCompletas['medias'],
          'cobertura_dados': estatisticasCompletas['cobertura_dados'],
        },
        'analise_talhoes': _gerarAnaliseTalhoes(estatisticasCompletas['plantios_detalhados']),
        'qualidade_dados': estatisticasCompletas['qualidade_geral'],
        'recomendacoes': _gerarRecomendacoes(
          {
            'total_plantios': estatisticasCompletas['total_plantios'],
            'culturas': estatisticasCompletas['culturas'],
            'talhoes': estatisticasCompletas['talhoes'],
          },
          _gerarAnaliseTalhoes(estatisticasCompletas['plantios_detalhados']),
          estatisticasCompletas['qualidade_geral'],
        ),
        'dados_detalhados': estatisticasCompletas['plantios_detalhados'],
      };
      
    } catch (e, stackTrace) {
      print('❌ VALIDAÇÃO SAFRA: Erro ao gerar relatório: $e');
      print('Stack trace: $stackTrace');
      return {
        'erro': e.toString(),
        'metadata': {
          'gerado_em': DateTime.now().toIso8601String(),
          'total_plantios': 0,
        },
        'estatisticas_gerais': {
          'total_plantios': 0,
          'culturas': {},
          'talhoes': {},
        },
        'qualidade_dados': {
          'score': 0,
          'nivel': 'ERRO',
        },
      };
    }
  }

  /// Gera análise por talhão a partir dos dados detalhados
  Map<String, dynamic> _gerarAnaliseTalhoes(List<Map<String, dynamic>> plantiosDetalhados) {
    final analisePorTalhao = <String, dynamic>{};
    
    for (final plantio in plantiosDetalhados) {
      final talhaoNome = plantio['talhao_nome'] as String;
      
      if (!analisePorTalhao.containsKey(talhaoNome)) {
        analisePorTalhao[talhaoNome] = {
          'total_plantios': 0,
          'culturas': <String, int>{},
        };
      }
      
      analisePorTalhao[talhaoNome]['total_plantios']++;
      
      final cultura = plantio['cultura_id'] as String;
      final culturas = analisePorTalhao[talhaoNome]['culturas'] as Map<String, int>;
      culturas[cultura] = (culturas[cultura] ?? 0) + 1;
    }
    
    return analisePorTalhao;
  }
  
  /// Gera estatísticas gerais dos plantios
  Future<Map<String, dynamic>> _gerarEstatisticasPlantio(List<PlantioIntegrado> plantios) async {
    print('📊 ESTATÍSTICAS: Gerando estatísticas para ${plantios.length} plantios');
    
    if (plantios.isEmpty) {
      print('⚠️ ESTATÍSTICAS: Nenhum plantio para processar - retornando dados vazios');
      return {
        'total_plantios': 0,
        'culturas': {},
        'variedades': {},
        'talhoes': {},
        'fontes_dados': {},
      };
    }
    
    // Contadores
    final culturas = <String, int>{};
    final variedades = <String, int>{};
    final talhoes = <String, int>{};
    final fontesDados = <String, int>{};
    
    double populacaoTotal = 0;
    double espacamentoMedio = 0;
    double profundidadeMedio = 0;
    
    for (final plantio in plantios) {
      // Culturas
      culturas[plantio.culturaId] = (culturas[plantio.culturaId] ?? 0) + 1;
      
      // Variedades
      final variedade = plantio.variedadeId ?? 'Não definida';
      variedades[variedade] = (variedades[variedade] ?? 0) + 1;
      
      // Talhões
      talhoes[plantio.talhaoNome] = (talhoes[plantio.talhaoNome] ?? 0) + 1;
      
      // Fontes de dados
      fontesDados[plantio.fonte] = (fontesDados[plantio.fonte] ?? 0) + 1;
      
      // Médias
      populacaoTotal += plantio.populacao;
      espacamentoMedio += plantio.espacamento;
      profundidadeMedio += plantio.profundidade;
    }
    
    return {
      'total_plantios': plantios.length,
      'periodo_analise': {
        'data_mais_antiga': plantios.map((p) => p.dataPlantio).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
        'data_mais_recente': plantios.map((p) => p.dataPlantio).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
      },
      'culturas': culturas,
      'variedades': variedades,
      'talhoes': talhoes,
      'fontes_dados': fontesDados,
      'medias': {
        'populacao_media': populacaoTotal / plantios.length,
        'espacamento_medio': espacamentoMedio / plantios.length,
        'profundidade_media': profundidadeMedio / plantios.length,
      },
    };
  }
  
  /// Análise detalhada por talhão
  Future<Map<String, dynamic>> _analisarPorTalhao(List<PlantioIntegrado> plantios) async {
    final analise = <String, Map<String, dynamic>>{};
    
    // Agrupar por talhão
    final plantiosPorTalhao = <String, List<PlantioIntegrado>>{};
    for (final plantio in plantios) {
      final talhaoNome = plantio.talhaoNome;
      plantiosPorTalhao[talhaoNome] = (plantiosPorTalhao[talhaoNome] ?? [])..add(plantio);
    }
    
    // Analisar cada talhão
    for (final entry in plantiosPorTalhao.entries) {
      final talhaoNome = entry.key;
      final plantiosTalhao = entry.value;
      
      final culturas = <String, int>{};
      final variedades = <String, int>{};
      final fontes = <String, int>{};
      
      double populacaoTotal = 0;
      double espacamentoTotal = 0;
      
      for (final plantio in plantiosTalhao) {
        culturas[plantio.culturaId] = (culturas[plantio.culturaId] ?? 0) + 1;
        variedades[plantio.variedadeId ?? 'Não definida'] = (variedades[plantio.variedadeId ?? 'Não definida'] ?? 0) + 1;
        fontes[plantio.fonte] = (fontes[plantio.fonte] ?? 0) + 1;
        
        populacaoTotal += plantio.populacao;
        espacamentoTotal += plantio.espacamento;
      }
      
      analise[talhaoNome] = {
        'total_plantios': plantiosTalhao.length,
        'culturas': culturas,
        'variedades': variedades,
        'fontes_dados': fontes,
        'populacao_media': populacaoTotal / plantiosTalhao.length,
        'espacamento_medio': espacamentoTotal / plantiosTalhao.length,
        'periodo': {
          'primeiro_plantio': plantiosTalhao.map((p) => p.dataPlantio).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
          'ultimo_plantio': plantiosTalhao.map((p) => p.dataPlantio).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
        },
      };
    }
    
    return analise;
  }
  
  /// Análise de tendência temporal
  Map<String, dynamic> _analisarTendenciaTemporal(List<PlantioIntegrado> plantios) {
    if (plantios.isEmpty) return {};
    
    // Ordenar por data
    plantios.sort((a, b) => a.dataPlantio.compareTo(b.dataPlantio));
    
    // Agrupar por mês
    final plantiosPorMes = <String, List<PlantioIntegrado>>{};
    final dateFormat = DateFormat('yyyy-MM');
    
    for (final plantio in plantios) {
      final mesAno = dateFormat.format(plantio.dataPlantio);
      plantiosPorMes[mesAno] = (plantiosPorMes[mesAno] ?? [])..add(plantio);
    }
    
    // Calcular tendências
    final tendencias = <String, dynamic>{};
    for (final entry in plantiosPorMes.entries) {
      final mes = entry.key;
      final plantiosMes = entry.value;
      
      tendencias[mes] = {
        'total_plantios': plantiosMes.length,
        'culturas_distintas': plantiosMes.map((p) => p.culturaId).toSet().length,
        'talhoes_distintos': plantiosMes.map((p) => p.talhaoNome).toSet().length,
        'populacao_media': plantiosMes.map((p) => p.populacao).reduce((a, b) => a + b) / plantiosMes.length,
      };
    }
    
    return {
      'plantios_por_mes': tendencias,
      'periodo_total': {
        'meses_com_plantio': plantiosPorMes.length,
        'media_plantios_por_mes': plantios.length / plantiosPorMes.length,
      },
    };
  }
  
  /// Avalia qualidade dos dados
  Map<String, dynamic> _avaliarQualidadeDados(List<PlantioIntegrado> plantios) {
    if (plantios.isEmpty) return {'score': 0, 'nivel': 'BAIXO'};
    
    int pontuacao = 0;
    int maxPontuacao = 0;
    
    // Critérios de qualidade
    for (final plantio in plantios) {
      // 1. Dados básicos completos (20 pontos)
      maxPontuacao += 20;
      if (plantio.culturaId.isNotEmpty) pontuacao += 5;
      if (plantio.variedadeId != null && plantio.variedadeId!.isNotEmpty) pontuacao += 5;
      if (plantio.populacao > 0) pontuacao += 5;
      if (plantio.espacamento > 0) pontuacao += 5;
      
      // 2. Nome do talhão disponível (10 pontos)
      maxPontuacao += 10;
      if (plantio.talhaoNome.isNotEmpty && !plantio.talhaoNome.startsWith('Talhão ')) {
        pontuacao += 10;
      }
      
      // 3. Observações disponíveis (10 pontos)
      maxPontuacao += 10;
      if (plantio.observacoes != null && plantio.observacoes!.isNotEmpty) {
        pontuacao += 10;
      }
      
      // 4. Histórico disponível (10 pontos)
      maxPontuacao += 10;
      if (plantio.historicos.isNotEmpty) {
        pontuacao += 10;
      }
    }
    
    final scorePercentual = maxPontuacao > 0 ? (pontuacao / maxPontuacao * 100).round() : 0;
    
    String nivel;
    if (scorePercentual >= 90) nivel = 'EXCELENTE';
    else if (scorePercentual >= 80) nivel = 'MUITO BOM';
    else if (scorePercentual >= 70) nivel = 'BOM';
    else if (scorePercentual >= 60) nivel = 'REGULAR';
    else nivel = 'BAIXO';
    
    return {
      'score': scorePercentual,
      'nivel': nivel,
      'detalhes': {
        'pontuacao_obtida': pontuacao,
        'pontuacao_maxima': maxPontuacao,
        'plantios_com_variedade': plantios.where((p) => p.variedadeId != null && p.variedadeId!.isNotEmpty).length,
        'plantios_com_observacoes': plantios.where((p) => p.observacoes != null && p.observacoes!.isNotEmpty).length,
        'plantios_com_historico': plantios.where((p) => p.historicos.isNotEmpty).length,
      },
    };
  }
  
  /// Gera recomendações baseadas na análise
  List<Map<String, dynamic>> _gerarRecomendacoes(
    Map<String, dynamic> estatisticas,
    Map<String, dynamic> analiseTalhoes,
    Map<String, dynamic> qualidadeDados,
  ) {
    final recomendacoes = <Map<String, dynamic>>[];
    
    // Recomendações baseadas na qualidade dos dados
    final scoreQualidade = qualidadeDados['score'] as int;
    if (scoreQualidade < 70) {
      recomendacoes.add({
        'tipo': 'qualidade_dados',
        'prioridade': 'alta',
        'titulo': 'Melhorar Qualidade dos Dados',
        'descricao': 'A qualidade dos dados está abaixo do ideal ($scoreQualidade%). Recomenda-se preencher mais informações nos plantios.',
        'acoes': [
          'Incluir variedades específicas nos plantios',
          'Adicionar observações detalhadas',
          'Verificar dados de população e espaçamento',
        ],
      });
    }
    
    // Recomendações baseadas na diversidade de culturas
    final culturas = estatisticas['culturas'] as Map<String, int>;
    if (culturas.length == 1) {
      recomendacoes.add({
        'tipo': 'diversificacao',
        'prioridade': 'media',
        'titulo': 'Considerar Diversificação',
        'descricao': 'Apenas uma cultura foi identificada. A diversificação pode reduzir riscos.',
        'acoes': [
          'Avaliar viabilidade de outras culturas',
          'Considerar rotação de culturas',
          'Analisar mercado para outras opções',
        ],
      });
    }
    
    // Recomendações baseadas na análise temporal
    final totalPlantios = estatisticas['total_plantios'] as int;
    if (totalPlantios < 5) {
      recomendacoes.add({
        'tipo': 'dados_insuficientes',
        'prioridade': 'baixa',
        'titulo': 'Aumentar Base de Dados',
        'descricao': 'Poucos plantios registrados ($totalPlantios). Mais dados permitirão análises mais precisas.',
        'acoes': [
          'Registrar todos os plantios realizados',
          'Incluir plantios históricos se possível',
          'Manter registro contínuo das atividades',
        ],
      });
    }
    
    return recomendacoes;
  }
}
