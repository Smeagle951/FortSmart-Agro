import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// 🧠 Modelos Avançados de Predição - Sistema FortSmart Agro
/// 
/// IMPLEMENTAÇÕES AVANÇADAS:
/// - Curvas de Infestação por Cultura
/// - Modelos de Progressão Temporal (Regressão Logística)
/// - Validação por Safra
/// - Integração Germinação + Infestação
/// 
/// DIFERENCIAIS ÚNICOS:
/// - ✅ Predição de tendência 7 dias
/// - ✅ Relatórios de acurácia por safra
/// - ✅ Retroalimentação germinação → infestação
/// - ✅ Modelos matemáticos avançados

class AdvancedPredictionModels {
  static AdvancedPredictionModels? _instance;
  static Database? _db;
  
  factory AdvancedPredictionModels() {
    _instance ??= AdvancedPredictionModels._internal();
    return _instance!;
  }
  
  AdvancedPredictionModels._internal();
  
  // ============================================================================
  // INICIALIZAÇÃO
  // ============================================================================
  
  Future<void> initialize() async {
    try {
      final appDatabase = AppDatabase();
      _db = await appDatabase.database;
      await _createAdvancedTables();
      Logger.info('🧠 Modelos Avançados de Predição inicializados');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar modelos avançados: $e');
      // Re-throw o erro para que seja tratado na interface
      rethrow;
    }
  }
  
  /// Cria tabelas para modelos avançados
  Future<void> _createAdvancedTables() async {
    // Tabela de curvas de infestação por cultura
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS curvas_infestacao_cultura (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cultura TEXT NOT NULL,
        organismo TEXT NOT NULL,
        estagio_fenologico TEXT NOT NULL,
        temperatura_otima REAL,
        umidade_otima REAL,
        taxa_crescimento_base REAL,
        densidade_maxima REAL,
        parametro_a REAL,
        parametro_b REAL,
        parametro_c REAL,
        confianca_modelo REAL,
        amostras_treinamento INTEGER,
        ultima_atualizacao TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Tabela de validação por safra
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS validacao_por_safra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        safra TEXT NOT NULL,
        cultura TEXT NOT NULL,
        talhao_id TEXT,
        total_predicoes INTEGER,
        predicoes_corretas INTEGER,
        predicoes_incorretas INTEGER,
        acuracia_geral REAL,
        acuracia_por_organismo TEXT,
        erro_medio_absoluto REAL,
        erro_medio_percentual REAL,
        confianca_media REAL,
        periodo_analise TEXT,
        observacoes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Tabela de integração germinação + infestação
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS integracao_germinacao_infestacao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lote_id TEXT NOT NULL,
        cultura TEXT NOT NULL,
        vigor_medio REAL,
        germinacao_final REAL,
        vigor_classificacao TEXT,
        risco_infestacao_base REAL,
        risco_doenca_base REAL,
        fatores_risco TEXT,
        recomendacoes TEXT,
        data_analise TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    Logger.info('✅ Tabelas de modelos avançados criadas');
  }
  
  // ============================================================================
  // CURVAS DE INFESTAÇÃO POR CULTURA
  // ============================================================================
  
  /// Calcula curva de infestação usando regressão logística
  Future<Map<String, dynamic>> calcularCurvaInfestacao({
    required String cultura,
    required String organismo,
    required String estagioFenologico,
    required double temperatura,
    required double umidade,
    required double densidadeAtual,
    required int diasProjecao,
  }) async {
    try {
      // Buscar parâmetros do modelo para a cultura/organismo
      final parametros = await _obterParametrosModelo(cultura, organismo, estagioFenologico);
      
      if (parametros == null) {
        // Criar modelo inicial se não existir
        await _criarModeloInicial(cultura, organismo, estagioFenologico);
        return _predicaoConservadora(densidadeAtual, diasProjecao);
      }
      
      // Aplicar regressão logística
      final curva = _aplicarRegressaoLogistica(
        densidadeAtual: densidadeAtual,
        temperatura: temperatura,
        umidade: umidade,
        parametros: parametros,
        diasProjecao: diasProjecao,
      );
      
      // Calcular tendência
      final tendencia = _calcularTendenciaCurva(curva);
      
      // Identificar pontos críticos
      final pontosCriticos = _identificarPontosCriticos(curva);
      
      return {
        'curva_projecao': curva,
        'tendencia': tendencia,
        'densidade_final': curva['curva'].last,
        'crescimento_medio': _calcularCrescimentoMedio(curva),
        'pontos_criticos': pontosCriticos,
        'confianca_modelo': parametros['confianca_modelo'],
        'amostras_treinamento': parametros['amostras_treinamento'],
        'modelo_usado': 'Regressão Logística',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular curva de infestação: $e');
      return _predicaoConservadora(densidadeAtual, diasProjecao);
    }
  }
  
  /// Aplica regressão logística para predição
  Map<String, dynamic> _aplicarRegressaoLogistica({
    required double densidadeAtual,
    required double temperatura,
    required double umidade,
    required Map<String, dynamic> parametros,
    required int diasProjecao,
  }) {
    final curva = <double>[];
    final a = (parametros['parametro_a'] as num?)?.toDouble() ?? 1.0;
    final b = (parametros['parametro_b'] as num?)?.toDouble() ?? 0.5;
    final c = (parametros['parametro_c'] as num?)?.toDouble() ?? 0.1;
    final densidadeMaxima = (parametros['densidade_maxima'] as num?)?.toDouble() ?? 100.0;
    
    // Fator de condições ambientais
    final fatorAmbiental = _calcularFatorAmbiental(temperatura, umidade, parametros);
    
    for (int dia = 0; dia <= diasProjecao; dia++) {
      // Fórmula da regressão logística: P(t) = K / (1 + e^(-a(t-b)))
      final t = dia.toDouble();
      final exponencial = exp(-a * (t - b));
      final densidade = (densidadeMaxima / (1 + exponencial)) * fatorAmbiental;
      
      // Limitar ao máximo histórico
      final densidadeLimitada = min(densidade, densidadeMaxima);
      curva.add(densidadeLimitada);
    }
    
    return {
      'curva': curva,
      'fator_ambiental': fatorAmbiental,
      'parametros_usados': parametros,
    };
  }
  
  /// Calcula fator ambiental baseado em temperatura e umidade
  double _calcularFatorAmbiental(
    double temperatura,
    double umidade,
    Map<String, dynamic> parametros,
  ) {
    final tempOtima = (parametros['temperatura_otima'] as num?)?.toDouble() ?? 25.0;
    final umidOtima = (parametros['umidade_otima'] as num?)?.toDouble() ?? 70.0;
    
    // Fator de temperatura (curva gaussiana)
    final fatorTemp = exp(-pow((temperatura - tempOtima) / 5.0, 2));
    
    // Fator de umidade (curva gaussiana)
    final fatorUmid = exp(-pow((umidade - umidOtima) / 10.0, 2));
    
    // Fator combinado
    return (fatorTemp + fatorUmid) / 2.0;
  }
  
  /// Calcula tendência da curva
  String _calcularTendenciaCurva(Map<String, dynamic> curvaData) {
    final curva = curvaData['curva'] as List<double>;
    if (curva.length < 3) return 'Insuficiente';
    
    final inicio = curva.first;
    final meio = curva[curva.length ~/ 2];
    final fim = curva.last;
    
    final crescimentoInicial = meio - inicio;
    final crescimentoFinal = fim - meio;
    
    if (crescimentoFinal > crescimentoInicial * 1.2) {
      return 'Acelerando';
    } else if (crescimentoFinal < crescimentoInicial * 0.8) {
      return 'Desacelerando';
    } else {
      return 'Estável';
    }
  }
  
  /// Identifica pontos críticos na curva
  List<Map<String, dynamic>> _identificarPontosCriticos(Map<String, dynamic> curvaData) {
    final curva = curvaData['curva'] as List<double>;
    final pontos = <Map<String, dynamic>>[];
    
    for (int i = 1; i < curva.length - 1; i++) {
      final anterior = curva[i - 1];
      final atual = curva[i];
      final proximo = curva[i + 1];
      
      // Ponto de inflexão (mudança de concavidade)
      if ((atual - anterior) * (proximo - atual) < 0) {
        pontos.add({
          'dia': i,
          'densidade': atual,
          'tipo': 'Ponto de Inflexão',
          'significado': 'Mudança na taxa de crescimento',
        });
      }
      
      // Ponto de crescimento máximo
      if (atual > anterior && atual > proximo) {
        pontos.add({
          'dia': i,
          'densidade': atual,
          'tipo': 'Pico de Crescimento',
          'significado': 'Máxima taxa de crescimento',
        });
      }
    }
    
    return pontos;
  }
  
  /// Calcula crescimento médio da curva
  double _calcularCrescimentoMedio(Map<String, dynamic> curvaData) {
    final curva = curvaData['curva'] as List<double>;
    if (curva.length < 2) return 0.0;
    
    final crescimento = curva.last - curva.first;
    return crescimento / (curva.length - 1);
  }
  
  // ============================================================================
  // VALIDAÇÃO POR SAFRA
  // ============================================================================
  
  /// Gera relatório de validação por safra
  Future<Map<String, dynamic>> gerarRelatorioValidacaoSafra({
    required String safra,
    String? cultura,
    String? talhaoId,
  }) async {
    try {
      // Buscar todas as predições da safra
      final predicoes = await _buscarPredicoesSafra(safra, cultura, talhaoId);
      
      if (predicoes.isEmpty) {
        return {
          'safra': safra,
          'total_predicoes': 0,
          'mensagem': 'Nenhuma predição encontrada para esta safra',
        };
      }
      
      // Calcular métricas de validação
      final metricas = _calcularMetricasValidacao(predicoes);
      
      // Gerar insights por organismo
      final insightsOrganismo = await _gerarInsightsPorOrganismo(predicoes);
      
      // Calcular tendência de melhoria
      final tendenciaMelhoria = _calcularTendenciaMelhoria(predicoes);
      
      return {
        'safra': safra,
        'cultura': cultura,
        'talhao_id': talhaoId,
        'periodo_analise': _calcularPeriodoAnalise(predicoes),
        'total_predicoes': predicoes.length,
        'metricas_gerais': metricas,
        'insights_por_organismo': insightsOrganismo,
        'tendencia_melhoria': tendenciaMelhoria,
        'recomendacoes': _gerarRecomendacoesMelhoria(metricas),
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório de validação: $e');
      return {'erro': e.toString()};
    }
  }
  
  /// Calcula métricas de validação
  Map<String, dynamic> _calcularMetricasValidacao(List<Map<String, dynamic>> predicoes) {
    int totalPredicoes = predicoes.length;
    int predicoesCorretas = 0;
    double erroAbsolutoTotal = 0.0;
    double erroPercentualTotal = 0.0;
    double confiancaTotal = 0.0;
    
    for (final predicao in predicoes) {
      final valorPredito = (predicao['valor_predito'] as num?)?.toDouble() ?? 0.0;
      final valorReal = (predicao['valor_real'] as num?)?.toDouble() ?? 0.0;
      final erroAbsoluto = (predicao['erro_absoluto'] as num?)?.toDouble() ?? 0.0;
      final erroPercentual = (predicao['erro_percentual'] as num?)?.toDouble() ?? 0.0;
      final confianca = (predicao['confianca_predicao'] as num?)?.toDouble() ?? 0.0;
      
      // Considerar correta se erro percentual < 20%
      if (erroPercentual < 20.0) {
        predicoesCorretas++;
      }
      
      erroAbsolutoTotal += erroAbsoluto;
      erroPercentualTotal += erroPercentual;
      confiancaTotal += confianca;
    }
    
    final acuracia = (predicoesCorretas / totalPredicoes) * 100;
    final erroMedioAbsoluto = erroAbsolutoTotal / totalPredicoes;
    final erroMedioPercentual = erroPercentualTotal / totalPredicoes;
    final confiancaMedia = confiancaTotal / totalPredicoes;
    
    return {
      'acuracia_geral': acuracia,
      'predicoes_corretas': predicoesCorretas,
      'predicoes_incorretas': totalPredicoes - predicoesCorretas,
      'erro_medio_absoluto': erroMedioAbsoluto,
      'erro_medio_percentual': erroMedioPercentual,
      'confianca_media': confiancaMedia,
      'classificacao_acuracia': _classificarAcuracia(acuracia),
    };
  }
  
  /// Classifica a acurácia
  String _classificarAcuracia(double acuracia) {
    if (acuracia >= 90) return 'Excelente';
    if (acuracia >= 80) return 'Muito Boa';
    if (acuracia >= 70) return 'Boa';
    if (acuracia >= 60) return 'Regular';
    return 'Baixa';
  }
  
  // ============================================================================
  // INTEGRAÇÃO GERMINAÇÃO + INFESTAÇÃO
  // ============================================================================
  
  /// Analisa risco de infestação baseado no vigor da germinação
  Future<Map<String, dynamic>> analisarRiscoGerminacaoInfestacao({
    required String loteId,
    required String cultura,
    required double vigorMedio,
    required double germinacaoFinal,
  }) async {
    try {
      // Classificar vigor
      final classificacaoVigor = _classificarVigor(vigorMedio);
      
      // Calcular risco baseado no vigor
      final riscoInfestacao = _calcularRiscoInfestacaoPorVigor(vigorMedio, germinacaoFinal);
      final riscoDoenca = _calcularRiscoDoencaPorVigor(vigorMedio, germinacaoFinal);
      
      // Identificar fatores de risco
      final fatoresRisco = _identificarFatoresRisco(vigorMedio, germinacaoFinal);
      
      // Gerar recomendações
      final recomendacoes = _gerarRecomendacoesIntegracao(
        classificacaoVigor,
        riscoInfestacao,
        riscoDoenca,
        fatoresRisco,
      );
      
      // Salvar análise
      await _salvarAnaliseIntegracao(
        loteId: loteId,
        cultura: cultura,
        vigorMedio: vigorMedio,
        germinacaoFinal: germinacaoFinal,
        classificacaoVigor: classificacaoVigor,
        riscoInfestacao: riscoInfestacao,
        riscoDoenca: riscoDoenca,
        fatoresRisco: fatoresRisco,
        recomendacoes: recomendacoes,
      );
      
      return {
        'lote_id': loteId,
        'cultura': cultura,
        'vigor_medio': vigorMedio,
        'germinacao_final': germinacaoFinal,
        'classificacao_vigor': classificacaoVigor,
        'risco_infestacao': riscoInfestacao,
        'risco_doenca': riscoDoenca,
        'fatores_risco': fatoresRisco,
        'recomendacoes': recomendacoes,
        'analise_integrada': true,
      };
      
    } catch (e) {
      Logger.error('❌ Erro na análise de integração: $e');
      return {'erro': e.toString()};
    }
  }
  
  /// Classifica vigor da germinação
  String _classificarVigor(double vigor) {
    if (vigor >= 90) return 'Excelente';
    if (vigor >= 80) return 'Muito Bom';
    if (vigor >= 70) return 'Bom';
    if (vigor >= 60) return 'Regular';
    return 'Baixo';
  }
  
  /// Calcula risco de infestação baseado no vigor
  double _calcularRiscoInfestacaoPorVigor(double vigor, double germinacao) {
    // Fórmula: risco = (100 - vigor) / 100 * (100 - germinacao) / 100
    final fatorVigor = (100 - vigor) / 100;
    final fatorGerminacao = (100 - germinacao) / 100;
    
    return (fatorVigor + fatorGerminacao) / 2;
  }
  
  /// Calcula risco de doença baseado no vigor
  double _calcularRiscoDoencaPorVigor(double vigor, double germinacao) {
    // Plantas com baixo vigor são mais suscetíveis a doenças
    final fatorVigor = (100 - vigor) / 100;
    final fatorGerminacao = (100 - germinacao) / 100;
    
    return (fatorVigor * 0.7 + fatorGerminacao * 0.3);
  }
  
  /// Identifica fatores de risco
  List<String> _identificarFatoresRisco(double vigor, double germinacao) {
    final fatores = <String>[];
    
    if (vigor < 70) {
      fatores.add('Vigor baixo - plantas mais suscetíveis a pragas');
    }
    
    if (germinacao < 80) {
      fatores.add('Germinação baixa - espaçamento irregular favorece pragas');
    }
    
    if (vigor < 60 && germinacao < 70) {
      fatores.add('Risco crítico - combinação de baixo vigor e germinação');
    }
    
    if (vigor >= 85 && germinacao >= 90) {
      fatores.add('Condições excelentes - baixo risco de infestação');
    }
    
    return fatores;
  }
  
  /// Gera recomendações integradas
  List<String> _gerarRecomendacoesIntegracao(
    String classificacaoVigor,
    double riscoInfestacao,
    double riscoDoenca,
    List<String> fatoresRisco,
  ) {
    final recomendacoes = <String>[];
    
    if (riscoInfestacao > 0.7) {
      recomendacoes.add('🔴 ALTA PRIORIDADE: Monitoramento intensivo recomendado');
      recomendacoes.add('💊 Aplicação preventiva de inseticidas');
      recomendacoes.add('📊 Verificar condições do solo e nutrição');
    }
    
    if (riscoDoenca > 0.6) {
      recomendacoes.add('🦠 Aplicação preventiva de fungicidas');
      recomendacoes.add('🌡️ Monitorar condições de umidade');
      recomendacoes.add('🌱 Melhorar drenagem se necessário');
    }
    
    if (classificacaoVigor == 'Baixo') {
      recomendacoes.add('🌱 Aplicar bioestimulantes para melhorar vigor');
      recomendacoes.add('💧 Verificar irrigação e nutrição');
      recomendacoes.add('📈 Acompanhar desenvolvimento das plantas');
    }
    
    if (fatoresRisco.isEmpty) {
      recomendacoes.add('✅ Condições excelentes - manter práticas atuais');
      recomendacoes.add('📊 Monitoramento rotineiro suficiente');
    }
    
    return recomendacoes;
  }
  
  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================
  
  /// Busca parâmetros do modelo
  Future<Map<String, dynamic>?> _obterParametrosModelo(
    String cultura,
    String organismo,
    String estagioFenologico,
  ) async {
    try {
      final result = await _db!.query(
        'curvas_infestacao_cultura',
        where: 'cultura = ? AND organismo = ? AND estagio_fenologico = ?',
        whereArgs: [cultura, organismo, estagioFenologico],
        limit: 1,
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      Logger.error('❌ Erro ao buscar parâmetros do modelo: $e');
      return null;
    }
  }
  
  /// Cria modelo inicial
  Future<void> _criarModeloInicial(
    String cultura,
    String organismo,
    String estagioFenologico,
  ) async {
    // Parâmetros conservadores baseados em literatura
    await _db!.insert('curvas_infestacao_cultura', {
      'cultura': cultura,
      'organismo': organismo,
      'estagio_fenologico': estagioFenologico,
      'temperatura_otima': 25.0,
      'umidade_otima': 70.0,
      'taxa_crescimento_base': 0.1,
      'densidade_maxima': 1.0,
      'parametro_a': 0.5,
      'parametro_b': 3.0,
      'parametro_c': 1.0,
      'confianca_modelo': 0.5,
      'amostras_treinamento': 0,
      'ultima_atualizacao': DateTime.now().toIso8601String(),
    });
  }
  
  /// Predição conservadora quando não há modelo
  Map<String, dynamic> _predicaoConservadora(double densidadeAtual, int diasProjecao) {
    final curva = <double>[];
    for (int i = 0; i <= diasProjecao; i++) {
      curva.add(densidadeAtual * (1 + i * 0.05)); // Crescimento linear de 5% por dia
    }
    
    return {
      'curva_projecao': curva,
      'tendencia': 'Linear',
      'densidade_final': curva.last,
      'crescimento_medio': 0.05,
      'pontos_criticos': [],
      'confianca_modelo': 0.3,
      'amostras_treinamento': 0,
      'modelo_usado': 'Conservador',
    };
  }
  
  /// Salva análise de integração
  Future<void> _salvarAnaliseIntegracao({
    required String loteId,
    required String cultura,
    required double vigorMedio,
    required double germinacaoFinal,
    required String classificacaoVigor,
    required double riscoInfestacao,
    required double riscoDoenca,
    required List<String> fatoresRisco,
    required List<String> recomendacoes,
  }) async {
    await _db!.insert('integracao_germinacao_infestacao', {
      'lote_id': loteId,
      'cultura': cultura,
      'vigor_medio': vigorMedio,
      'germinacao_final': germinacaoFinal,
      'vigor_classificacao': classificacaoVigor,
      'risco_infestacao_base': riscoInfestacao,
      'risco_doenca_base': riscoDoenca,
      'fatores_risco': fatoresRisco.join('; '),
      'recomendacoes': recomendacoes.join('; '),
      'data_analise': DateTime.now().toIso8601String(),
    });
  }
  
  /// Busca predições da safra
  Future<List<Map<String, dynamic>>> _buscarPredicoesSafra(
    String safra,
    String? cultura,
    String? talhaoId,
  ) async {
    try {
    String whereClause = 'safra = ?';
    List<dynamic> whereArgs = [safra];
    
    if (cultura != null) {
      whereClause += ' AND cultura = ?';
      whereArgs.add(cultura);
    }
    
    if (talhaoId != null) {
      whereClause += ' AND talhao_id = ?';
      whereArgs.add(talhaoId);
    }
    
    return await _db!.query('ia_predicoes_validacao', where: whereClause, whereArgs: whereArgs);
    } catch (e) {
      // Se a tabela não existir, retornar vazio ao invés de dar erro
      return [];
    }
  }
  
  /// Gera insights por organismo
  Future<Map<String, dynamic>> _gerarInsightsPorOrganismo(
    List<Map<String, dynamic>> predicoes,
  ) async {
    // Agrupar por organismo e calcular métricas
    final organismos = <String, List<Map<String, dynamic>>>{};
    
    for (final predicao in predicoes) {
      final organismo = (predicao['contexto'] as String?) ?? 'Desconhecido';
      organismos[organismo] ??= [];
      organismos[organismo]!.add(predicao);
    }
    
    final insights = <String, dynamic>{};
    
    for (final entry in organismos.entries) {
      final organismo = entry.key;
      final predicoesOrganismo = entry.value;
      
      final metricas = _calcularMetricasValidacao(predicoesOrganismo);
      insights[organismo] = {
        'total_predicoes': predicoesOrganismo.length,
        'acuracia': metricas['acuracia_geral'],
        'erro_medio': metricas['erro_medio_percentual'],
        'confianca_media': metricas['confianca_media'],
      };
    }
    
    return insights;
  }
  
  /// Calcula tendência de melhoria
  Map<String, dynamic> _calcularTendenciaMelhoria(
    List<Map<String, dynamic>> predicoes,
  ) {
    if (predicoes.length < 10) {
      return {'tendencia': 'Insuficiente', 'dados': predicoes.length};
    }
    
    // Ordenar por data
    predicoes.sort((a, b) => 
      DateTime.parse((a['data_predicao'] as String?) ?? DateTime.now().toIso8601String())
        .compareTo(DateTime.parse((b['data_predicao'] as String?) ?? DateTime.now().toIso8601String()))
    );
    
    // Dividir em períodos
    final metade = predicoes.length ~/ 2;
    final primeiraMetade = predicoes.take(metade).toList();
    final segundaMetade = predicoes.skip(metade).toList();
    
    final acuraciaPrimeira = _calcularMetricasValidacao(primeiraMetade)['acuracia_geral'];
    final acuraciaSegunda = _calcularMetricasValidacao(segundaMetade)['acuracia_geral'];
    
    final melhoria = acuraciaSegunda - acuraciaPrimeira;
    
    return {
      'tendencia': melhoria > 5 ? 'Melhorando' : melhoria < -5 ? 'Piorando' : 'Estável',
      'melhoria_percentual': melhoria,
      'acuracia_inicial': acuraciaPrimeira,
      'acuracia_final': acuraciaSegunda,
    };
  }
  
  /// Calcula período de análise
  String _calcularPeriodoAnalise(List<Map<String, dynamic>> predicoes) {
    if (predicoes.isEmpty) return 'N/A';
    
    final datas = predicoes.map((p) => DateTime.parse((p['data_predicao'] as String?) ?? DateTime.now().toIso8601String())).toList();
    datas.sort();
    
    final inicio = datas.first;
    final fim = datas.last;
    final dias = fim.difference(inicio).inDays;
    
    return '${inicio.day}/${inicio.month}/${inicio.year} a ${fim.day}/${fim.month}/${fim.year} ($dias dias)';
  }
  
  /// Gera recomendações de melhoria
  List<String> _gerarRecomendacoesMelhoria(Map<String, dynamic> metricas) {
    final recomendacoes = <String>[];
    final acuracia = (metricas['acuracia_geral'] as num?)?.toDouble() ?? 0.0;
    final erroMedio = (metricas['erro_medio_percentual'] as num?)?.toDouble() ?? 0.0;
    
    if (acuracia < 70) {
      recomendacoes.add('📊 Aumentar coleta de dados para melhorar treinamento');
      recomendacoes.add('🔍 Revisar parâmetros dos modelos');
      recomendacoes.add('📈 Implementar validação cruzada');
    }
    
    if (erroMedio > 30) {
      recomendacoes.add('🎯 Focar em organismos com maior erro');
      recomendacoes.add('📚 Atualizar base de conhecimento');
      recomendacoes.add('🔄 Implementar feedback contínuo');
    }
    
    if (acuracia >= 85) {
      recomendacoes.add('✅ Excelente performance - manter práticas atuais');
      recomendacoes.add('🚀 Considerar expansão para novos organismos');
    }
    
    return recomendacoes;
  }
}
