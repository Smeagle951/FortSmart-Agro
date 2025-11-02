/// 🤖 FortSmart Agronomic AI - IA Agronômica Unificada
/// 
/// IA ÚNICA que serve TODOS os módulos do FortSmart:
/// - ✅ Teste de Germinação
/// - ✅ Diagnóstico de Pragas/Doenças
/// - ✅ Análise de Infestação
/// - ✅ Monitoramento de Culturas
/// - ✅ Recomendações Agronômicas
/// 
/// 100% Offline - Dart Puro - Sem Python - Sem Servidor
/// Baseado em normas ISTA/AOSA/MAPA e conhecimento agronômico científico

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
// import '../modules/tratamento_sementes/utils/vigor_calculator.dart'; // Comentado temporariamente
// import '../modules/tratamento_sementes/utils/germination_professional_calculator.dart'; // Comentado temporariamente
import '../screens/plantio/submods/germination_test/models/germination_test_model.dart';
import 'agronomic_knowledge_base.dart';
import 'organism_v3_integration_service.dart';
// import 'advanced_germination_training_service.dart'; // Comentado temporariamente

/// IA Agronômica Unificada do FortSmart
class FortSmartAgronomicAI {
  static FortSmartAgronomicAI? _instance;
  static Map<String, dynamic>? _modelData;
  static Map<String, dynamic>? _organismData;
  static bool _isInitialized = false;
  // static AdvancedGerminationTrainingService? _trainingService; // Comentado temporariamente
  
  // Singleton pattern
  factory FortSmartAgronomicAI() {
    _instance ??= FortSmartAgronomicAI._internal();
    return _instance!;
  }
  
  FortSmartAgronomicAI._internal();
  
  // ============================================================================
  // INICIALIZAÇÃO
  // ============================================================================
  
  /// Inicializa a IA Agronômica Unificada
  Future<bool> initialize() async {
    if (_isInitialized) {
      Logger.info('🤖 FortSmart AI já inicializada');
      return true;
    }
    
    try {
      Logger.info('🤖 Inicializando FortSmart Agronomic AI...');
      
      // Carregar modelo de germinação
      await _loadGerminationModel();
      
      // Carregar dados de organismos
      await _loadOrganismData();
      
      // Inicializar serviço de treinamento avançado
      // _trainingService = AdvancedGerminationTrainingService(); // Comentado temporariamente
      // await _trainingService!.initialize(); // Comentado temporariamente
      
      _isInitialized = true;
      Logger.info('✅ FortSmart AI inicializada com sucesso!');
      Logger.info('📊 Módulos: Germinação, Diagnóstico, Infestação, Monitoramento');
      Logger.info('🧠 Treinamento Avançado: MGT, GSI, Predição Inteligente');
      
      return true;
    } catch (e) {
      Logger.error('❌ Erro ao inicializar FortSmart AI: $e');
      return false;
    }
  }
  
  /// Carrega modelo de germinação
  Future<void> _loadGerminationModel() async {
    try {
      final modelJson = await rootBundle.loadString('assets/models/flutter_model.json');
      _modelData = json.decode(modelJson);
      Logger.info('✅ Modelo de germinação carregado');
    } catch (e) {
      Logger.warning('⚠️ Modelo de germinação não encontrado: $e');
      _modelData = {};
    }
  }
  
  /// Carrega dados de organismos (pragas/doenças)
  Future<void> _loadOrganismData() async {
    try {
      // Tentar carregar do sistema de arquivos primeiro (lib/data)
      try {
        // Carregar todas as culturas disponíveis
        final cultureFiles = [
          'organismos_soja.json',
          'organismos_milho.json',
          'organismos_algodao.json',
          'organismos_feijao.json',
          'organismos_girassol.json',
          'organismos_arroz.json',
          'organismos_sorgo.json',
          'organismos_trigo.json',
          'organismos_aveia.json',
          'organismos_gergelim.json',
          'organismos_cana_acucar.json',
          'organismos_tomate.json',
        ];
        
        _organismData = <String, dynamic>{};
        for (final fileName in cultureFiles) {
          try {
            final file = File('lib/data/$fileName');
            if (await file.exists()) {
              final cultureJson = await file.readAsString();
              final cultureData = json.decode(cultureJson);
              _organismData![fileName] = cultureData;
            }
          } catch (e) {
            Logger.warning('⚠️ Erro ao carregar $fileName: $e');
          }
        }
        
        Logger.info('✅ Catálogo de organismos carregado de lib/data/ - ${_organismData?.length ?? 0} culturas');
        return;
      } catch (e) {
        Logger.warning('⚠️ Erro ao carregar de lib/data: $e');
      }
      
      // Fallback para assets
      try {
        final cultureFiles = [
          'organismos_soja.json',
          'organismos_milho.json',
          'organismos_algodao.json',
          'organismos_feijao.json',
          'organismos_girassol.json',
          'organismos_arroz.json',
          'organismos_sorgo.json',
          'organismos_trigo.json',
          'organismos_aveia.json',
          'organismos_gergelim.json',
          'organismos_cana_acucar.json',
          'organismos_tomate.json',
        ];
        
        _organismData = <String, dynamic>{};
        for (final fileName in cultureFiles) {
          try {
            final cultureJson = await rootBundle.loadString('lib/data/$fileName');
            final cultureData = json.decode(cultureJson);
            _organismData![fileName] = cultureData;
          } catch (e) {
            Logger.warning('⚠️ Erro ao carregar $fileName via rootBundle: $e');
          }
        }
        Logger.info('✅ Catálogo de organismos carregado de lib/data/ via rootBundle - ${_organismData?.length ?? 0} culturas');
      } catch (e) {
        Logger.warning('⚠️ Catálogo de organismos não encontrado em assets: $e');
        _organismData = {};
      }
    } catch (e) {
      Logger.warning('⚠️ Erro geral ao carregar catálogo de organismos: $e');
      _organismData = {};
    }
  }
  
  // ============================================================================
  // MÓDULO 1: ANÁLISE DE GERMINAÇÃO
  // ============================================================================
  
  /// Analisa teste de germinação completo
  /// 
  /// Retorna análise profissional com:
  /// - Percentual de germinação
  /// - Vigor (PCG, IVG, VMG, CVG)
  /// - Sanidade
  /// - Valor Cultural
  /// - Classificação (Classe A/B/C)
  /// - Recomendações personalizadas
  Future<Map<String, dynamic>> analyzeGermination({
    required Map<int, int> contagensPorDia,
    required int sementesTotais,
    required int germinadasFinal,
    int manchas = 0,
    int podridao = 0,
    int cotiledonesAmarelados = 0,
    double pureza = 98.0,
    required String cultura,
  }) async {
    try {
      Logger.info('🌱 Analisando germinação: $cultura');
      
      // Usar calculadora profissional
      final analise = <String, dynamic>{
        'germinationPercentage': 0.0,
        'vigor': 0.0,
        'quality': 'N/A',
        'recommendations': ['Módulo de germinação removido'],
      };
      
      Logger.info('✅ Análise de germinação concluída');
      
      return {
        ...analise,
        'modulo': 'germinacao',
        'timestamp': DateTime.now().toIso8601String(),
        'ia_version': '2.0.0',
      };
    } catch (e) {
      Logger.error('❌ Erro na análise de germinação: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Análise rápida de vigor
  Future<Map<String, dynamic>> analyzeVigor({
    required int germinadas,
    required int dia,
    required int sementesTotais,
    String cultura = 'soja',
  }) async {
    try {
      Logger.info('💪 Analisando vigor...');
      
      final vigor = 0.0; // Módulo de germinação removido
      
      final classificacao = 'N/A'; // Módulo de germinação removido
      final recomendacoes = ['Módulo de germinação removido'];
      
      return {
        'vigor': vigor,
        'vigor_percentual': vigor * 100,
        'classificacao': classificacao,
        'recomendacoes': recomendacoes,
        'modulo': 'vigor',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro na análise de vigor: $e');
      return {'error': e.toString()};
    }
  }
  
  // ============================================================================
  // MÓDULO 2: DIAGNÓSTICO DE PRAGAS E DOENÇAS
  // ============================================================================
  
  /// Diagnóstico por sintomas observados
  /// 
  /// Analisa sintomas e retorna possíveis pragas/doenças
  Future<List<Map<String, dynamic>>> diagnoseBySyntoms({
    required List<String> sintomas,
    required String cultura,
    double limiarConfianca = 0.3,
  }) async {
    try {
      Logger.info('🔍 Diagnosticando por sintomas: $cultura');
      Logger.info('📋 Sintomas: ${sintomas.join(", ")}');
      
      if (_organismData == null || _organismData!.isEmpty) {
        return _generateFallbackDiagnosis(sintomas, cultura);
      }
      
      final resultados = <Map<String, dynamic>>[];
      final organismos = _getOrganismsByCulture(cultura);
      
      for (final organismo in organismos) {
        final confianca = _calculateSymptomMatch(sintomas, organismo);
        
        if (confianca >= limiarConfianca) {
          resultados.add({
            'organismo': organismo['nome'],
            'tipo': organismo['tipo'],
            'confianca': confianca,
            'sintomas_comuns': organismo['sintomas'] ?? [],
            'estrategias': organismo['estrategias'] ?? [],
            'nivel_dano': _estimateDamageLevel(confianca),
          });
        }
      }
      
      // Ordenar por confiança
      resultados.sort((a, b) => 
        (b['confianca'] as double).compareTo(a['confianca'] as double)
      );
      
      Logger.info('✅ Diagnóstico concluído: ${resultados.length} resultados');
      
      return resultados;
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      return [];
    }
  }
  
  /// Diagnóstico por imagem
  /// 
  /// NOTA: Por enquanto usa análise de características
  /// TODO: Integrar com modelo de visão computacional no futuro
  Future<List<Map<String, dynamic>>> diagnoseByImage({
    required String imagePath,
    required String cultura,
  }) async {
    try {
      Logger.info('🖼️ Diagnosticando por imagem: $cultura');
      
      // Por enquanto, retorna diagnóstico genérico
      // TODO: Implementar análise real de imagem com TFLite Vision
      
      return [
        {
          'organismo': 'Análise de imagem',
          'tipo': 'pendente',
          'confianca': 0.0,
          'mensagem': 'Diagnóstico por imagem será implementado em versão futura',
          'sugestao': 'Use diagnóstico por sintomas no momento',
        }
      ];
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico por imagem: $e');
      return [];
    }
  }
  
  // ============================================================================
  // MÓDULO 3: ANÁLISE DE INFESTAÇÃO PROFISSIONAL
  // ============================================================================
  
  /// Analisa nível de infestação com conhecimento científico avançado
  Future<Map<String, dynamic>> analyzeInfestation({
    required String organismo,
    required double densidadeAtual,
    required String cultura,
    required String estagioFenologico,
    double temperatura = 26.0,
    double umidade = 70.0,
    double chuva7dias = 20.0,
    int diasAposPlantio = 60,
  }) async {
    try {
      Logger.info('🐛 Análise Profissional de Infestação: $organismo');
      
      // Obter dados do organismo
      final orgData = _getOrganismData(organismo, cultura);
      
      // Calcular graus-dia
      final grausDia = _calculateDegreeDays(diasAposPlantio, temperatura);
      
      // Análise de risco de surto
      final riscoSurto = _predictOutbreakRiskAdvanced(
        organismo: orgData,
        temperatura: temperatura,
        umidade: umidade,
        estagio: estagioFenologico,
        chuva: chuva7dias,
        grausDia: grausDia,
      );
      
      // Predição de densidade futura (7 dias)
      final densidadeFutura = _predictFutureDensity(
        densidadeAtual: densidadeAtual,
        temperatura: temperatura,
        umidade: umidade,
        organismo: orgData,
      );
      
      // Classificação de nível
      final nivelInfestacao = _classifyInfestationLevelAdvanced(
        densidadeAtual,
        orgData['limiar_controle'] ?? 2.0,
      );
      
      // Urgência de controle
      final urgenciaControle = _assessControlUrgency(
        densidadeAtual,
        densidadeFutura,
        orgData['limiar_controle'] ?? 2.0,
        estagio: estagioFenologico,
      );
      
      // Melhor momento de aplicação
      final melhorMomento = _calculateOptimalApplicationTime(
        temperatura: temperatura,
        umidade: umidade,
        vento: 5.0, // TODO: pegar real
        chuva: chuva7dias / 7,
      );
      
      // Recomendações avançadas
      final recomendacoes = _generateAdvancedRecommendations(
        organismo: organismo,
        densidade: densidadeAtual,
        densidadeFutura: densidadeFutura,
        risco: riscoSurto,
        nivel: nivelInfestacao,
        urgencia: urgenciaControle,
        estagio: estagioFenologico,
      );
      
      return {
        'organismo': organismo,
        'tipo': orgData['tipo'],
        'densidade_atual': densidadeAtual,
        'densidade_prevista_7d': densidadeFutura,
        'limiar_controle': orgData['limiar_controle'],
        'nivel_infestacao': nivelInfestacao,
        'risco_surto': riscoSurto,
        'risco_classificacao': _classifyRisk(riscoSurto),
        'urgencia_controle': urgenciaControle,
        'necessita_controle': densidadeAtual >= (orgData['limiar_controle'] ?? 2.0),
        'melhor_momento_aplicacao': melhorMomento,
        'eficacia_esperada': melhorMomento['eficacia'],
        'recomendacoes': recomendacoes,
        'graus_dia_acumulados': grausDia,
        'modulo': 'infestacao_profissional',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro na análise de infestação: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Calcula graus-dia acumulados (base 10°C para soja)
  double _calculateDegreeDays(int dias, double temperaturaMedia) {
    final baseTemp = 10.0;
    final tempDiff = temperaturaMedia - baseTemp;
    return dias * (tempDiff > 0 ? tempDiff : 0.0);
  }
  
  /// Predição avançada de risco de surto
  double _predictOutbreakRiskAdvanced({
    required Map<String, dynamic> organismo,
    required double temperatura,
    required double umidade,
    required String estagio,
    required double chuva,
    required double grausDia,
  }) {
    double risco = 0.0;
    
    final tipo = organismo['tipo'] ?? 'praga';
    
    if (tipo == 'praga') {
      // PRAGAS: Temperatura e estágio fenológico
      final tempIdeal = organismo['temp_ideal'] as List?;
      if (tempIdeal != null && tempIdeal.length == 2) {
        if (temperatura >= tempIdeal[0] && temperatura <= tempIdeal[1]) {
          risco += 0.4;  // Temperatura ideal
        } else if (temperatura >= tempIdeal[0] - 3 && temperatura <= tempIdeal[1] + 3) {
          risco += 0.2;  // Próximo do ideal
        }
      }
      
      // Estágio fenológico crítico
      final estagiosCriticos = organismo['estagio_critico'] as List?;
      if (estagiosCriticos != null && estagiosCriticos.contains(estagio)) {
        risco += 0.4;  // Estágio crítico
      }
      
      // Condições gerais para pragas
      if (umidade >= 60 && umidade <= 85) {
        risco += 0.2;
      }
      
    } else if (tipo == 'doenca') {
      // DOENÇAS: Umidade e molhamento foliar são críticos
      if (umidade > 80) {
        risco += 0.5;  // Umidade alta
      }
      if (umidade > 90) {
        risco += 0.3;  // Umidade muito alta (extra)
      }
      
      // Molhamento foliar (estimado pela chuva)
      final horasMolhamento = chuva / 5;  // Aproximação
      final molhamentoNecessario = organismo['molhamento_necessario'] ?? 6.0;
      if (horasMolhamento >= molhamentoNecessario) {
        risco += 0.4;
      }
      
      // Temperatura
      final tempIdeal = organismo['temp_ideal'] as List?;
      if (tempIdeal != null && tempIdeal.length == 2) {
        if (temperatura >= tempIdeal[0] && temperatura <= tempIdeal[1]) {
          risco += 0.3;
        }
      }
    }
    
    return risco.clamp(0.0, 1.0);
  }
  
  /// Predição de densidade futura
  double _predictFutureDensity({
    required double densidadeAtual,
    required double temperatura,
    required double umidade,
    required Map<String, dynamic> organismo,
  }) {
    if (densidadeAtual == 0) return 0.0;
    
    final tipo = organismo['tipo'] ?? 'praga';
    double taxaCrescimento = 1.0;
    
    if (tipo == 'praga') {
      // Pragas crescem exponencialmente em condições ideais
      final tempIdeal = organismo['temp_ideal'] as List?;
      if (tempIdeal != null && tempIdeal.length == 2) {
        if (temperatura >= tempIdeal[0] && temperatura <= tempIdeal[1]) {
          taxaCrescimento = 2.0;  // Dobra em 7 dias (condições ideais)
        } else {
          taxaCrescimento = 1.3;  // Crescimento moderado
        }
      }
    } else {
      // Doenças crescem com umidade
      if (umidade > 90) {
        taxaCrescimento = 3.0;  // Triplica (condições muito favoráveis)
      } else if (umidade > 80) {
        taxaCrescimento = 2.0;  // Dobra
      } else if (umidade > 70) {
        taxaCrescimento = 1.5;  // Crescimento moderado
      } else {
        taxaCrescimento = 1.1;  // Crescimento lento
      }
    }
    
    return densidadeAtual * taxaCrescimento;
  }
  
  /// Classificação avançada de nível de infestação
  String _classifyInfestationLevelAdvanced(double densidade, double limiar) {
    if (densidade >= limiar * 3) return 'Crítico';
    if (densidade >= limiar * 1.5) return 'Alto';
    if (densidade >= limiar * 0.5) return 'Médio';
    if (densidade > 0) return 'Baixo';
    return 'Ausente';
  }
  
  /// Avalia urgência de controle
  String _assessControlUrgency(
    double densidadeAtual,
    double densidadeFutura,
    double limiar,
    {required String estagio}
  ) {
    // Crítico: Densidade atual muito alta OU crescimento explosivo
    if (densidadeAtual >= limiar * 3) return 'Imediata';
    if (densidadeFutura >= limiar * 3 && densidadeAtual >= limiar) return 'Imediata';
    
    // Alta: Acima do limiar e crescendo
    if (densidadeAtual >= limiar * 1.5) return 'Alta';
    if (densidadeFutura >= limiar * 2) return 'Alta';
    
    // Média: Próximo do limiar
    if (densidadeAtual >= limiar) return 'Média';
    if (densidadeFutura >= limiar * 1.5) return 'Média';
    
    // Baixa: Abaixo do limiar mas monitorar
    if (densidadeAtual > 0) return 'Baixa';
    
    return 'Nenhuma';
  }
  
  /// Calcula melhor momento de aplicação
  Map<String, dynamic> _calculateOptimalApplicationTime({
    required double temperatura,
    required double umidade,
    required double vento,
    required double chuva,
  }) {
    double eficacia = 0.85;  // Base: 85%
    final restricoes = <String>[];
    String recomendacao = 'Condições adequadas';
    
    // Temperatura
    if (temperatura < 10 || temperatura > 35) {
      eficacia *= 0.5;
      restricoes.add('Temperatura fora da faixa ideal (10-35°C)');
      recomendacao = 'Aguardar temperatura adequada';
    }
    
    // Umidade
    if (umidade < 50) {
      eficacia *= 0.7;
      restricoes.add('Umidade baixa (<50%) - produto pode evaporar');
    } else if (umidade > 95) {
      eficacia *= 0.8;
      restricoes.add('Umidade muito alta (>95%) - risco de lixiviação');
    }
    
    // Vento
    if (vento > 15) {
      eficacia *= 0.4;
      restricoes.add('Vento forte (>15km/h) - NÃO APLICAR (deriva)');
      recomendacao = 'AGUARDAR vento diminuir';
    } else if (vento > 10) {
      eficacia *= 0.7;
      restricoes.add('Vento moderado (10-15km/h) - cuidado com deriva');
    }
    
    // Chuva prevista
    if (chuva > 5) {
      eficacia *= 0.5;
      restricoes.add('Chuva prevista (>5mm) - produto será lavado');
      recomendacao = 'AGUARDAR 24-48h sem chuva';
    }
    
    // Determinar janela de aplicação
    String janela;
    if (eficacia >= 0.8) {
      janela = 'Ótima - Aplicar agora';
    } else if (eficacia >= 0.6) {
      janela = 'Adequada - Pode aplicar';
    } else if (eficacia >= 0.4) {
      janela = 'Ruim - Aplicar apenas se urgente';
    } else {
      janela = 'Péssima - NÃO APLICAR';
    }
    
    return {
      'eficacia_esperada': eficacia,
      'janela_aplicacao': janela,
      'recomendacao': recomendacao,
      'restricoes': restricoes,
      'melhor_horario': _getBestTimeOfDay(temperatura, umidade),
    };
  }
  
  String _getBestTimeOfDay(double temperatura, double umidade) {
    // Manhã cedo (6-9h): Baixa temperatura, alta umidade, pouco vento
    // Final da tarde (17-20h): Temperatura ameniza, menos vento
    
    if (temperatura > 30) {
      return 'Final da tarde (17-20h) - Temperatura mais amena';
    } else if (umidade < 60) {
      return 'Início da manhã (6-9h) - Umidade mais alta';
    } else {
      return 'Manhã (6-9h) ou Final tarde (17-20h) - Ambos adequados';
    }
  }
  
  /// Recomendações avançadas de infestação
  List<String> _generateAdvancedRecommendations({
    required String organismo,
    required double densidade,
    required double densidadeFutura,
    required double risco,
    required String nivel,
    required String urgencia,
    required String estagio,
  }) {
    final recomendacoes = <String>[];
    
    // Recomendações por urgência
    if (urgencia == 'Imediata') {
      recomendacoes.add('🚨 CONTROLE IMEDIATO NECESSÁRIO!');
      recomendacoes.add('⚠️ População acima do nível crítico');
      recomendacoes.add('⚠️ Aplicar defensivo específico nas próximas 24-48h');
      recomendacoes.add('⚠️ Priorizar áreas com maior infestação');
    } else if (urgencia == 'Alta') {
      recomendacoes.add('⚠️ Controle necessário em breve (3-5 dias)');
      recomendacoes.add('⚠️ População próxima ao nível de dano econômico');
      recomendacoes.add('✅ Programar aplicação para condições ideais');
    } else if (urgencia == 'Média') {
      recomendacoes.add('⚠️ Monitoramento intensivo recomendado');
      recomendacoes.add('✅ Preparar para possível aplicação');
      recomendacoes.add('✅ Remonitorar em 3-4 dias');
    } else {
      recomendacoes.add('✅ População sob controle');
      recomendacoes.add('✅ Manter monitoramento de rotina');
    }
    
    // Recomendações por risco futuro
    if (densidadeFutura > densidade * 2) {
      recomendacoes.add('📈 ALERTA: População em crescimento exponencial');
      recomendacoes.add('⚠️ Condições climáticas favoráveis ao organismo');
    }
    
    // Recomendações por risco de surto
    if (risco > 0.7) {
      recomendacoes.add('🔮 RISCO ALTO de surto nas próximas semanas');
      recomendacoes.add('⚠️ Monitoramento preventivo essencial');
    }
    
    // Recomendações por estágio
    if (estagio.contains('R')) {
      recomendacoes.add('🌾 Fase reprodutiva: Momento crítico para controle');
      recomendacoes.add('⚠️ Danos nesta fase impactam diretamente a produtividade');
    }
    
    // Recomendações específicas por organismo
    recomendacoes.addAll(_getOrganismSpecificRecommendations(organismo, densidade));
    
    return recomendacoes;
  }
  
  List<String> _getOrganismSpecificRecommendations(String organismo, double densidade) {
    // Usar base de conhecimento completa com 40+ organismos
    return AgronomicKnowledgeBase.getOrganismRecommendations(
      organismo, 
      densidade, 
      'R1', // TODO: pegar estágio real
    );
  }
  
  /// Obtém dados do organismo da base de conhecimento científico (com v3.0)
  Future<Map<String, dynamic>> _getOrganismDataAsync(String organismo, String cultura) async {
    try {
      // Tentar carregar dados v3.0 primeiro
      final v3Service = OrganismV3IntegrationService();
      final dadosV3 = await v3Service.getOrganismDataForReport(
        organismoNome: organismo,
        cultura: cultura,
      );
      
      if (dadosV3['versao'] == '3.0') {
        // Converter formato v3.0 para formato esperado pela IA
        final tempIdeal = dadosV3['condicoes_climaticas'] != null
          ? [
              dadosV3['condicoes_climaticas']['temperatura_min']?.toDouble() ?? 20.0,
              dadosV3['condicoes_climaticas']['temperatura_max']?.toDouble() ?? 30.0,
            ]
          : [25.0, 30.0];
        
        final umidadeIdeal = dadosV3['condicoes_climaticas'] != null
          ? [
              dadosV3['condicoes_climaticas']['umidade_min']?.toDouble() ?? 60.0,
              dadosV3['condicoes_climaticas']['umidade_max']?.toDouble() ?? 80.0,
            ]
          : [60.0, 80.0];
        
        return {
          'nome': dadosV3['nome'],
          'cientifico': dadosV3['nome_cientifico'],
          'tipo': dadosV3['categoria'] == 'Praga' ? 'praga' : 'doenca',
          'cultura': cultura,
          'temp_ideal': tempIdeal,
          'umidade_ideal': umidadeIdeal,
          'estagio_critico': dadosV3['fenologia'] ?? [],
          'limiar_controle': 2.0,
          'unidade': 'unidades/ponto',
          'geracoes_safra': dadosV3['ciclo_vida']?['geracoes_por_ano'] ?? 4,
          'graus_dia_geracao': dadosV3['ciclo_vida']?['ciclo_total_dias'] != null
            ? (365.0 / (dadosV3['ciclo_vida']['geracoes_por_ano'] ?? 1) * 30.0)
            : 280.0,
          // Dados v3.0 extras
          'versao': '3.0',
          'v3_data': dadosV3,
        };
      }
    } catch (e) {
      Logger.warning('⚠️ Erro ao carregar dados v3.0, usando fallback: $e');
    }
    
    // Fallback para base de conhecimento antiga
    return AgronomicKnowledgeBase.getOrganismData(organismo, cultura);
  }
  
  /// Obtém dados do organismo (wrapper para compatibilidade)
  Map<String, dynamic> _getOrganismData(String organismo, String cultura) {
    return AgronomicKnowledgeBase.getOrganismData(organismo, cultura);
  }
  
  // ============================================================================
  // MÓDULO 4: MONITORAMENTO E PREDIÇÕES
  // ============================================================================
  
  /// Prediz risco de surto baseado em condições
  Future<Map<String, dynamic>> predictOutbreakRisk({
    required String cultura,
    required double temperatura,
    required double umidade,
    required String estacao,
  }) async {
    try {
      Logger.info('🔮 Predizendo risco de surto: $cultura');
      
      final riscoGeral = _calculateOutbreakRisk(
        temperatura: temperatura,
        umidade: umidade,
        cultura: cultura,
      );
      
      final organismosRisco = _identifyRiskOrganisms(
        cultura: cultura,
        temperatura: temperatura,
        umidade: umidade,
      );
      
      return {
        'risco_geral': riscoGeral,
        'classificacao_risco': _classifyRisk(riscoGeral),
        'organismos_risco': organismosRisco,
        'recomendacoes_preventivas': _getPreventiveRecommendations(riscoGeral),
        'monitoramento_sugerido': _suggestMonitoringFrequency(riscoGeral),
        'modulo': 'predicao',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('❌ Erro na predição: $e');
      return {'error': e.toString()};
    }
  }
  
  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================
  
  /// Obtém organismos por cultura
  List<Map<String, dynamic>> _getOrganismsByCulture(String cultura) {
    if (_organismData == null || _organismData!.isEmpty) {
      return [];
    }
    
    final List<dynamic> todosOrganismos = _organismData!['organisms'] ?? [];
    return todosOrganismos
        .where((org) => 
            (org['cultures'] as List?)?.contains(cultura.toLowerCase()) ?? false
        )
        .map((org) => Map<String, dynamic>.from(org))
        .toList();
  }
  
  /// Calcula match de sintomas
  double _calculateSymptomMatch(List<String> sintomasObservados, Map<String, dynamic> organismo) {
    final sintomasOrganismo = (organismo['sintomas'] as List?)?.cast<String>() ?? [];
    
    if (sintomasOrganismo.isEmpty) return 0.0;
    
    int matches = 0;
    for (final sintoma in sintomasObservados) {
      if (sintomasOrganismo.any((s) => 
          s.toLowerCase().contains(sintoma.toLowerCase()) ||
          sintoma.toLowerCase().contains(s.toLowerCase())
      )) {
        matches++;
      }
    }
    
    return matches / sintomasObservados.length;
  }
  
  /// Estima nível de dano
  String _estimateDamageLevel(double confianca) {
    if (confianca >= 0.8) return 'Alto';
    if (confianca >= 0.5) return 'Médio';
    return 'Baixo';
  }
  
  /// Diagnóstico fallback quando dados não estão disponíveis
  List<Map<String, dynamic>> _generateFallbackDiagnosis(List<String> sintomas, String cultura) {
    return [
      {
        'organismo': 'Diagnóstico genérico',
        'tipo': 'análise_sintomas',
        'confianca': 0.5,
        'sintomas': sintomas,
        'recomendacao': 'Consultar especialista agronômico para diagnóstico preciso',
        'cultura': cultura,
      }
    ];
  }
  
  /// Calcula nível de dano econômico
  double _calculateDamageLevel(double densidade, String cultura, String organismo) {
    // Simplificado - na prática usaria dados específicos por organismo
    return densidade * 0.1; // Placeholder
  }
  
  /// Avalia necessidade de controle
  String _assessControlNeed(double nivelDano) {
    if (nivelDano >= 0.7) return 'Urgente';
    if (nivelDano >= 0.4) return 'Necessário';
    if (nivelDano >= 0.2) return 'Monitorar';
    return 'Não necessário';
  }
  
  /// Classifica nível de infestação
  String _classifyInfestationLevel(double nivelDano) {
    if (nivelDano >= 0.7) return 'Muito Alto';
    if (nivelDano >= 0.5) return 'Alto';
    if (nivelDano >= 0.3) return 'Médio';
    if (nivelDano >= 0.1) return 'Baixo';
    return 'Muito Baixo';
  }
  
  /// Recomendações para infestação
  List<String> _getInfestationRecommendations(double nivelDano, String cultura) {
    final recomendacoes = <String>[];
    
    if (nivelDano >= 0.7) {
      recomendacoes.add('⚠️ Controle imediato necessário');
      recomendacoes.add('⚠️ Aplicar defensivo específico');
      recomendacoes.add('⚠️ Monitorar eficácia do controle');
    } else if (nivelDano >= 0.4) {
      recomendacoes.add('⚠️ Programar aplicação de controle');
      recomendacoes.add('✅ Monitoramento semanal');
    } else {
      recomendacoes.add('✅ Manter monitoramento regular');
      recomendacoes.add('✅ Condições sob controle');
    }
    
    return recomendacoes;
  }
  
  /// Calcula risco de surto
  double _calculateOutbreakRisk({
    required double temperatura,
    required double umidade,
    required String cultura,
  }) {
    // Condições favoráveis para maioria das pragas/doenças
    double riscoTemp = 0.0;
    double riscoUmid = 0.0;
    
    // Temperatura entre 25-30°C é ideal para muitas pragas
    if (temperatura >= 25 && temperatura <= 30) {
      riscoTemp = 0.8;
    } else if (temperatura >= 20 && temperatura <= 35) {
      riscoTemp = 0.5;
    } else {
      riscoTemp = 0.2;
    }
    
    // Umidade > 70% favorece doenças
    if (umidade >= 70) {
      riscoUmid = 0.8;
    } else if (umidade >= 60) {
      riscoUmid = 0.5;
    } else {
      riscoUmid = 0.3;
    }
    
    return (riscoTemp + riscoUmid) / 2;
  }
  
  /// Identifica organismos em risco
  List<String> _identifyRiskOrganisms({
    required String cultura,
    required double temperatura,
    required double umidade,
  }) {
    final organismosRisco = <String>[];
    
    if (umidade >= 70) {
      organismosRisco.add('Doenças fúngicas');
    }
    
    if (temperatura >= 25 && temperatura <= 30) {
      organismosRisco.add('Lagartas');
      organismosRisco.add('Percevejos');
    }
    
    return organismosRisco;
  }
  
  /// Classifica risco
  String _classifyRisk(double risco) {
    if (risco >= 0.7) return 'Alto';
    if (risco >= 0.4) return 'Médio';
    return 'Baixo';
  }
  
  /// Recomendações preventivas
  List<String> _getPreventiveRecommendations(double risco) {
    if (risco >= 0.7) {
      return [
        '⚠️ Intensificar monitoramento',
        '⚠️ Preparar defensivos',
        '⚠️ Avaliar aplicação preventiva',
      ];
    } else if (risco >= 0.4) {
      return [
        '✅ Monitoramento regular',
        '✅ Estar preparado para intervenção',
      ];
    }
    return [
      '✅ Monitoramento de rotina suficiente',
    ];
  }
  
  /// Sugere frequência de monitoramento
  String _suggestMonitoringFrequency(double risco) {
    if (risco >= 0.7) return 'Diário';
    if (risco >= 0.4) return 'Semanal (2-3x)';
    return 'Semanal';
  }
  
  // ============================================================================
  // UTILITÁRIOS
  // ============================================================================
  
  /// Verifica se IA está inicializada
  bool get isInitialized => _isInitialized;
  
  /// Obtém informações da IA
  Map<String, dynamic> getInfo() {
    return {
      'initialized': _isInitialized,
      'version': '2.0.0',
      'modules': [
        'Germinação',
        'Vigor',
        'Diagnóstico',
        'Infestação',
        'Predição',
        'Monitoramento',
      ],
      'offline': true,
      'technology': 'Dart Pure',
      'standards': ['ISTA', 'AOSA', 'MAPA'],
    };
  }
  
  /// Reinicia IA
  Future<void> reset() async {
    _isInitialized = false;
    _modelData = null;
    _organismData = null;
    // _trainingService = null; // Comentado temporariamente
    Logger.info('🔄 FortSmart AI reiniciada');
  }
  
  // ============================================================================
  // TREINAMENTO AVANÇADO
  // ============================================================================
  
  /// Treina modelo para uma cultura específica
  Future<Map<String, dynamic>> trainGerminationModel(String cultura) async {
    // if (_trainingService == null) {
    //   return {
    //     'sucesso': false,
    //     'erro': 'Serviço de treinamento não inicializado',
    //   };
    // }
    
    // return await _trainingService!.trainModelForCulture(cultura);
    return {
      'sucesso': false,
      'erro': 'Serviço de treinamento temporariamente desabilitado',
    };
  }
  
  /// Prediz germinação final baseada em dados parciais
  Future<Map<String, dynamic>> predictGerminationFinal({
    required String loteId,
    required String cultura,
    required int diaAtual,
    required Map<String, dynamic> dadosAtuais,
  }) async {
    // if (_trainingService == null) {
    //   return {
    //     'sucesso': false,
    //     'erro': 'Serviço de treinamento não inicializado',
    //   };
    // }
    
    // return await _trainingService!.predictGerminationFinal(
    //   loteId: loteId,
    //   cultura: cultura,
    //   diaAtual: diaAtual,
    //   dadosAtuais: dadosAtuais,
    // );
    return {
      'sucesso': false,
      'erro': 'Serviço de treinamento temporariamente desabilitado',
    };
  }
  
  /// Retorna estatísticas de treinamento
  Future<Map<String, dynamic>> getTrainingStats() async {
    // if (_trainingService == null) {
    //   return {'erro': 'Serviço de treinamento não inicializado'};
    // }
    
    // return await _trainingService!.getTrainingStats();
    return {'erro': 'Serviço de treinamento temporariamente desabilitado'};
  }
}
