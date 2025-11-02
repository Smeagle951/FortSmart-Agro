import 'package:fortsmart_agro/services/plantio_integration_service.dart';
import 'package:fortsmart_agro/database/repositories/estande_plantas_repository.dart';
import 'package:fortsmart_agro/database/repositories/planting_cv_repository.dart';
import 'package:fortsmart_agro/database/models/estande_plantas_model.dart';
import 'package:fortsmart_agro/models/planting_cv_model.dart';
import 'package:fortsmart_agro/screens/plantio/submods/phenological_evolution/providers/phenological_provider.dart';
import 'package:fortsmart_agro/screens/plantio/submods/phenological_evolution/models/phenological_record_model.dart';
import 'package:fortsmart_agro/utils/logger.dart';

/// 🎯 SERVIÇO CENTRAL DE DADOS COMPLETOS DE PLANTIO
/// 
/// Este é o "MOTOR CENTRAL" que integra TODOS os submódulos:
/// - Novo Plantio (cadastro base)
/// - Histórico de Plantio (registros históricos)
/// - Novo Estande de Plantas (população real + eficiência)
/// - Cálculo de CV% (uniformidade)
/// - Evolução Fenológica (desenvolvimento da cultura)
/// 
/// Autor: FortSmart Agro - Especialista Agronômico + Dev Senior
/// Data: Outubro 2025
class PlantioCompleteDataService {
  static final PlantioCompleteDataService _instance = PlantioCompleteDataService._internal();
  factory PlantioCompleteDataService() => _instance;
  PlantioCompleteDataService._internal();

  // Repositórios e serviços
  final PlantioIntegrationService _plantioIntegration = PlantioIntegrationService();
  final EstandePlantasRepository _estandeRepository = EstandePlantasRepository();
  final PlantingCVRepository _cvRepository = PlantingCVRepository();
  final PhenologicalProvider _phenologicalProvider = PhenologicalProvider();

  /// 🔍 BUSCA DADOS COMPLETOS DE UM PLANTIO ESPECÍFICO
  /// 
  /// Retorna um JSON unificado com TODOS os dados:
  /// - Informações básicas do plantio
  /// - População real do estande
  /// - CV% e classificação
  /// - Evolução fenológica
  /// - Histórico de registros
  Future<Map<String, dynamic>> buscarDadosCompletos({
    required String talhaoId,
    required String culturaId,
    String? plantioId,
  }) async {
    try {
      Logger.info('🔍 DADOS COMPLETOS: Buscando para talhão=$talhaoId, cultura=$culturaId');

      // 1️⃣ BUSCAR PLANTIO BASE
      final plantios = await _plantioIntegration.buscarPlantiosParaEvolucaoFenologica(
        talhaoId,
        culturaId,
      );

      if (plantios.isEmpty) {
        Logger.warning('⚠️ DADOS COMPLETOS: Nenhum plantio encontrado');
        return _retornarDadosVazios();
      }

      final plantio = plantios.first;
      Logger.info('✅ PLANTIO BASE: ${plantio.culturaId} - ${plantio.variedadeId}');
      Logger.info('   - ID: ${plantio.id}');
      Logger.info('   - Talhão ID plantio: "${plantio.talhaoId}"');
      Logger.info('   - Cultura ID plantio: "${plantio.culturaId}"');

      // 2️⃣ BUSCAR ESTANDE REAL (População Real + Eficiência)
      EstandePlantasModel? estande;
      try {
        Logger.info('🔍 BUSCANDO ESTANDE:');
        Logger.info('   - Parâmetro talhaoId: "$talhaoId"');
        Logger.info('   - Parâmetro culturaId: "$culturaId"');
        
        estande = await _estandeRepository.getLatestByTalhaoAndCultura(
          talhaoId,
          culturaId,
        );
        
        if (estande != null) {
          Logger.info('✅ ESTANDE REAL ENCONTRADO:');
          Logger.info('   - Talhão: ${estande.talhaoId}');
          Logger.info('   - Cultura: ${estande.culturaId}');
          Logger.info('   - População: ${estande.plantasPorHectare?.toStringAsFixed(0)} plantas/ha');
          Logger.info('   - Eficiência: ${estande.eficiencia?.toStringAsFixed(1)}%');
          Logger.info('   - Plantas/m: ${estande.plantasPorMetro?.toStringAsFixed(1)}');
          Logger.info('   - Data avaliação: ${estande.dataAvaliacao}');
        } else {
          Logger.warning('⚠️ NENHUM ESTANDE ENCONTRADO para talhão "$talhaoId" e cultura "$culturaId"');
          
          // Buscar todos os estandes do talhão para debug
          final estandesTalhao = await _estandeRepository.buscarPorTalhao(talhaoId);
          Logger.info('📋 DEBUG: Total de estandes no talhão "$talhaoId": ${estandesTalhao.length}');
          for (var e in estandesTalhao) {
            Logger.info('   - Cultura: "${e.culturaId}" (comparando com "$culturaId")');
          }
        }
      } catch (e) {
        Logger.error('❌ Erro ao buscar estande: $e');
      }

      // 3️⃣ BUSCAR CV% (Uniformidade)
      PlantingCVModel? cv;
      try {
        // Buscar por talhão e depois filtrar por cultura (ignorando prefixo "custom_")
        final cvList = await _cvRepository.buscarPorTalhao(talhaoId);
        final culturaSemPrefixo = culturaId.toLowerCase().replaceAll('custom_', '');
        
        final cvFiltrado = cvList.where((c) {
          final cvCulturaNorm = c.culturaId.toLowerCase().replaceAll('custom_', '');
          return cvCulturaNorm == culturaSemPrefixo;
        }).toList();
        
        if (cvFiltrado.isNotEmpty) {
          cv = cvFiltrado.first;
          Logger.info('✅ CV% ENCONTRADO: ${cv.coeficienteVariacao.toStringAsFixed(2)}% - ${cv.classificacao.name}');
          Logger.info('   - Cultura no banco: "${cv.culturaId}", buscando por: "$culturaId"');
        } else {
          Logger.warning('⚠️ Nenhum CV% encontrado para talhão $talhaoId e cultura $culturaId');
          Logger.info('   📋 DEBUG: Total de CV% no talhão: ${cvList.length}');
          for (var c in cvList) {
            Logger.info('      - CV% com cultura: "${c.culturaId}" (comparando com "$culturaId")');
          }
        }
      } catch (e) {
        Logger.error('❌ Erro ao buscar CV%: $e');
      }

      // 4️⃣ BUSCAR EVOLUÇÃO FENOLÓGICA (Desenvolvimento)
      List<PhenologicalRecordModel> registrosFenologicos = [];
      PhenologicalRecordModel? ultimoRegistro;
      try {
        await _phenologicalProvider.inicializar();
        await _phenologicalProvider.carregarRegistros(talhaoId, culturaId);
        
        registrosFenologicos = await _phenologicalProvider.obterRegistrosParaGraficos(
          talhaoId,
          culturaId,
        );
        
        ultimoRegistro = await _phenologicalProvider.buscarUltimoRegistro(
          talhaoId,
          culturaId,
        );
        
        if (registrosFenologicos.isNotEmpty) {
          Logger.info('✅ FENOLOGIA: ${registrosFenologicos.length} registros');
          if (ultimoRegistro != null) {
            Logger.info('   Último: ${ultimoRegistro.diasAposEmergencia} DAE - ${ultimoRegistro.alturaCm ?? 0} cm');
          }
        } else {
          Logger.warning('⚠️ Nenhum registro fenológico encontrado');
        }
      } catch (e) {
        Logger.error('❌ Erro ao buscar fenologia: $e');
      }

      // 5️⃣ MONTAR JSON COMPLETO UNIFICADO
      final dadosCompletos = _montarJsonCompleto(
        plantio: plantio,
        estande: estande,
        cv: cv,
        registrosFenologicos: registrosFenologicos,
        ultimoRegistro: ultimoRegistro,
      );

      Logger.info('✅ DADOS COMPLETOS: JSON unificado gerado com sucesso');
      return dadosCompletos;

    } catch (e, stackTrace) {
      Logger.error('❌ DADOS COMPLETOS: Erro ao buscar: $e');
      Logger.error('Stack trace: $stackTrace');
      return _retornarDadosVazios();
    }
  }

  /// 🔍 BUSCA DADOS COMPLETOS DE TODOS OS PLANTIOS
  /// Para uso no Relatório Agronômico
  Future<List<Map<String, dynamic>>> buscarTodosDadosCompletos({
    String? safraId,
    String? culturaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Logger.info('🔍 TODOS DADOS COMPLETOS: Buscando todos os plantios...');

      // 1. Buscar todos os plantios integrados
      final todosPlantios = await _plantioIntegration.buscarPlantiosIntegrados();
      Logger.info('📊 Total de plantios encontrados: ${todosPlantios.length}');

      // 2. Para cada plantio, buscar dados completos
      final dadosCompletos = <Map<String, dynamic>>[];

      for (final plantio in todosPlantios) {
        try {
          final dados = await buscarDadosCompletos(
            talhaoId: plantio.talhaoId,
            culturaId: plantio.culturaId,
            plantioId: plantio.id,
          );

          // Aplicar filtros se necessário
          bool incluir = true;

          if (culturaId != null && !plantio.culturaId.toLowerCase().contains(culturaId.toLowerCase())) {
            incluir = false;
          }

          if (dataInicio != null && plantio.dataPlantio.isBefore(dataInicio)) {
            incluir = false;
          }

          if (dataFim != null && plantio.dataPlantio.isAfter(dataFim)) {
            incluir = false;
          }

          if (incluir) {
            dadosCompletos.add(dados);
          }
        } catch (e) {
          Logger.error('❌ Erro ao buscar dados completos do plantio ${plantio.id}: $e');
        }
      }

      Logger.info('✅ TODOS DADOS COMPLETOS: ${dadosCompletos.length} plantios processados');
      return dadosCompletos;

    } catch (e, stackTrace) {
      Logger.error('❌ TODOS DADOS COMPLETOS: Erro: $e');
      Logger.error('Stack trace: $stackTrace');
      return [];
    }
  }

  /// 📦 MONTA JSON COMPLETO UNIFICADO
  Map<String, dynamic> _montarJsonCompleto({
    required PlantioIntegrado plantio,
    EstandePlantasModel? estande,
    PlantingCVModel? cv,
    List<PhenologicalRecordModel>? registrosFenologicos,
    PhenologicalRecordModel? ultimoRegistro,
  }) {
    // Calcular métricas derivadas
    final diasPlantio = DateTime.now().difference(plantio.dataPlantio).inDays;
    
    // População: usar real se disponível, senão planejada
    final populacaoReal = estande?.plantasPorHectare;
    final populacaoPlanejada = plantio.populacao;
    final populacaoFinal = populacaoReal ?? populacaoPlanejada;
    
    // Calcular eficiência se houver estande
    double? eficienciaReal;
    if (estande?.eficiencia != null) {
      eficienciaReal = estande!.eficiencia;
    } else if (populacaoReal != null && populacaoPlanejada > 0) {
      eficienciaReal = (populacaoReal / populacaoPlanejada) * 100;
    }

    // Classificação de CV%
    String? classificacaoCV;
    if (cv != null) {
      classificacaoCV = cv.classificacao.name;
    }

    // Status fenológico
    String? estagioFenologico;
    double? alturaAtual;
    int? dae;
    if (ultimoRegistro != null) {
      dae = ultimoRegistro.diasAposEmergencia;
      alturaAtual = ultimoRegistro.alturaCm;
      estagioFenologico = ultimoRegistro.estagioFenologico;
    }

    return {
      // 📋 IDENTIFICAÇÃO
      'id': plantio.id,
      'talhao_id': plantio.talhaoId,
      'talhao_nome': plantio.talhaoNome,
      'cultura_id': plantio.culturaId,
      'variedade_id': plantio.variedadeId,
      'fonte_dados': plantio.fonte,
      
      // 📅 DATAS E PRAZOS
      'data_plantio': plantio.dataPlantio.toIso8601String(),
      'dias_apos_plantio': diasPlantio,
      'criado_em': plantio.dataPlantio.toIso8601String(), // Usar data de plantio como referência
      
      // 🌱 DADOS DO PLANTIO BASE
      'plantio': {
        'espacamento_cm': plantio.espacamento,
        'profundidade_cm': plantio.profundidade,
        'populacao_planejada': populacaoPlanejada,
        'observacoes': plantio.observacoes,
        'foto_observacao': _obterPrimeiraFoto(plantio),
      },
      
      // 📊 ESTANDE REAL (População Real + Eficiência)
      'estande': estande != null ? {
        'tem_dados': true,
        'populacao_real': populacaoReal?.toInt(),
        'plantas_por_metro': estande.plantasPorMetro,
        'plantas_contadas': estande.plantasContadas,
        'metros_avaliados': estande.metrosLinearesMedidos,
        'populacao_ideal': estande.populacaoIdeal,
        'eficiencia_percentual': estande.eficiencia,
        'data_avaliacao': estande.dataAvaliacao?.toIso8601String(),
        'dias_apos_emergencia': estande.diasAposEmergencia,
      } : {
        'tem_dados': false,
        'populacao_real': null,
      },
      
      // 📐 CV% (Uniformidade)
      'cv_uniformidade': cv != null ? {
        'tem_dados': true,
        'coeficiente_variacao': cv.coeficienteVariacao,
        'classificacao': classificacaoCV,
        'desvio_padrao': cv.desvioPadrao,
        'media_espacamento': cv.mediaEspacamento,
        'espacamentos': cv.distanciasEntreSementes,
        'data_calculo': cv.dataPlantio.toIso8601String(),
      } : {
        'tem_dados': false,
        'coeficiente_variacao': null,
      },
      
      // 🌾 EVOLUÇÃO FENOLÓGICA (Desenvolvimento)
      'evolucao_fenologica': {
        'tem_dados': registrosFenologicos != null && registrosFenologicos.isNotEmpty,
        'total_registros': registrosFenologicos?.length ?? 0,
        'ultimo_registro': ultimoRegistro != null ? {
          'dias_apos_emergencia': dae,
          'altura_cm': alturaAtual,
          'estagio_fenologico': estagioFenologico,
          'numero_nos': ultimoRegistro.numeroNos,
          'numero_folhas': ultimoRegistro.numeroFolhas,
          'vagens_planta': ultimoRegistro.vagensPlanta,
          'graos_vagem': ultimoRegistro.graosVagem,
          'ramos_vegetativos': ultimoRegistro.numeroRamosVegetativos,
          'ramos_reprodutivos': ultimoRegistro.numeroRamosReprodutivos,
          'data_registro': ultimoRegistro.dataRegistro.toIso8601String(),
        } : null,
        'historico_resumido': registrosFenologicos?.map((r) => {
          'dae': r.diasAposEmergencia,
          'altura': r.alturaCm,
          'estagio': r.estagioFenologico,
        }).toList() ?? [],
      },
      
      // 📈 MÉTRICAS CALCULADAS E INSIGHTS
      'metricas_calculadas': {
        'populacao_final': populacaoFinal,
        'populacao_tipo': populacaoReal != null ? 'REAL_ESTANDE' : 'PLANEJADA',
        'eficiencia_plantio': eficienciaReal,
        'tem_estande': estande != null,
        'tem_cv': cv != null,
        'tem_fenologia': registrosFenologicos != null && registrosFenologicos.isNotEmpty,
        'completude_dados': _calcularCompletudePercentual(
          temEstande: estande != null,
          temCV: cv != null,
          temFenologia: registrosFenologicos != null && registrosFenologicos.isNotEmpty,
        ),
      },
      
      // 🎯 QUALIDADE E STATUS
      'status_qualidade': _avaliarQualidadeDados(
        plantio: plantio,
        estande: estande,
        cv: cv,
        fenologia: registrosFenologicos,
      ),
      
      // 📊 HISTÓRICOS RELACIONADOS
      'historicos_count': plantio.historicos.length,
    };
  }

  /// 📊 GERA ESTATÍSTICAS AGREGADAS PARA O RELATÓRIO AGRONÔMICO
  /// 
  /// Processa TODOS os plantios e gera estatísticas consolidadas
  Future<Map<String, dynamic>> gerarEstatisticasAgregadas({
    String? safraId,
    String? culturaId,
    String? talhaoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      Logger.info('📊 ESTATÍSTICAS AGREGADAS: Gerando relatório completo...');

      // Buscar todos os dados completos
      final todosDados = await buscarTodosDadosCompletos(
        safraId: safraId,
        culturaId: culturaId,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      if (todosDados.isEmpty) {
        Logger.warning('⚠️ ESTATÍSTICAS: Nenhum dado encontrado');
        return _retornarEstatisticasVazias();
      }

      // Filtrar por talhão se especificado
      List<Map<String, dynamic>> dadosFiltrados = todosDados;
      if (talhaoId != null && talhaoId.isNotEmpty) {
        dadosFiltrados = todosDados.where((dados) {
          final talhaoNome = (dados['talhao_nome'] as String).toLowerCase();
          final talhaoIdLower = talhaoId.toLowerCase();
          return talhaoNome.contains(talhaoIdLower);
        }).toList();
        
        Logger.info('🔍 Filtro de talhão aplicado: ${dadosFiltrados.length}/${todosDados.length} plantios');
      }

      if (dadosFiltrados.isEmpty) {
        Logger.warning('⚠️ ESTATÍSTICAS: Nenhum plantio após filtros');
        return _retornarEstatisticasVazias();
      }

      Logger.info('📊 Processando ${dadosFiltrados.length} plantios...');

      // CONTADORES E ACUMULADORES
      final culturas = <String, int>{};
      final talhoes = <String, int>{};
      final variedades = <String, int>{};
      int plantiosComEstande = 0;
      int plantiosComCV = 0;
      int plantiosComFenologia = 0;
      
      double populacaoTotalReal = 0;
      double populacaoTotalPlanejada = 0;
      double eficienciaTotal = 0;
      double cvTotal = 0;
      int countEficiencia = 0;
      int countCV = 0;

      // PROCESSAR CADA PLANTIO
      for (final dados in dadosFiltrados) {
        // Contadores básicos
        final cultura = dados['cultura_id'] as String;
        final talhao = dados['talhao_nome'] as String;
        final variedade = dados['variedade_id'] as String? ?? 'Não definida';
        
        culturas[cultura] = (culturas[cultura] ?? 0) + 1;
        talhoes[talhao] = (talhoes[talhao] ?? 0) + 1;
        variedades[variedade] = (variedades[variedade] ?? 0) + 1;

        // Dados de estande
        final estande = dados['estande'] as Map<String, dynamic>;
        if (estande['tem_dados'] == true) {
          plantiosComEstande++;
          final popReal = estande['populacao_real'] as int?;
          if (popReal != null) {
            populacaoTotalReal += popReal;
          }
          
          final efic = (estande['eficiencia_percentual'] as num?)?.toDouble();
          if (efic != null) {
            eficienciaTotal += efic;
            countEficiencia++;
          }
        }

        // Dados de CV%
        final cvData = dados['cv_uniformidade'] as Map<String, dynamic>;
        if (cvData['tem_dados'] == true) {
          plantiosComCV++;
          final cvValor = (cvData['coeficiente_variacao'] as num?)?.toDouble();
          if (cvValor != null) {
            cvTotal += cvValor;
            countCV++;
          }
        }

        // Dados fenológicos
        final fenologia = dados['evolucao_fenologica'] as Map<String, dynamic>;
        if (fenologia['tem_dados'] == true) {
          plantiosComFenologia++;
        }

        // População planejada
        final plantioBase = dados['plantio'] as Map<String, dynamic>;
        populacaoTotalPlanejada += (plantioBase['populacao_planejada'] as num?)?.toDouble() ?? 0;
      }

      // CALCULAR MÉDIAS
      final totalPlantios = todosDados.length;
      final populacaoMediaReal = plantiosComEstande > 0 ? populacaoTotalReal / plantiosComEstande : 0;
      final populacaoMediaPlanejada = populacaoTotalPlanejada / totalPlantios;
      final eficienciaMedia = countEficiencia > 0 ? eficienciaTotal / countEficiencia : 0;
      final cvMedio = countCV > 0 ? cvTotal / countCV : 0;

      // MONTAR ESTATÍSTICAS AGREGADAS
      return {
        'total_plantios': totalPlantios,
        'culturas': culturas,
        'talhoes': talhoes,
        'variedades': variedades,
        
        'cobertura_dados': {
          'com_estande': plantiosComEstande,
          'com_cv': plantiosComCV,
          'com_fenologia': plantiosComFenologia,
          'percentual_estande': (plantiosComEstande / totalPlantios * 100),
          'percentual_cv': (plantiosComCV / totalPlantios * 100),
          'percentual_fenologia': (plantiosComFenologia / totalPlantios * 100),
        },
        
        'medias': {
          'populacao_planejada': populacaoMediaPlanejada.toInt(),
          'populacao_real': populacaoMediaReal.toInt(),
          'eficiencia_media': eficienciaMedia,
          'cv_medio': cvMedio,
        },
        
        'qualidade_geral': _avaliarQualidadeGeral(
          totalPlantios: totalPlantios,
          comEstande: plantiosComEstande,
          comCV: plantiosComCV,
          comFenologia: plantiosComFenologia,
          eficienciaMedia: eficienciaMedia.toDouble(),
          cvMedio: cvMedio.toDouble(),
        ),
        
        'plantios_detalhados': todosDados,
      };

    } catch (e, stackTrace) {
      Logger.error('❌ ESTATÍSTICAS AGREGADAS: Erro: $e');
      Logger.error('Stack trace: $stackTrace');
      return _retornarEstatisticasVazias();
    }
  }

  /// 📊 CALCULA PERCENTUAL DE COMPLETUDE DOS DADOS
  int _calcularCompletudePercentual({
    required bool temEstande,
    required bool temCV,
    required bool temFenologia,
  }) {
    int pontos = 0;
    if (temEstande) pontos += 40; // Estande é o mais importante
    if (temCV) pontos += 30; // CV% é muito importante
    if (temFenologia) pontos += 30; // Fenologia também importante
    return pontos;
  }

  /// 🎯 AVALIA QUALIDADE DOS DADOS DE UM PLANTIO
  Map<String, dynamic> _avaliarQualidadeDados({
    required PlantioIntegrado plantio,
    EstandePlantasModel? estande,
    PlantingCVModel? cv,
    List<PhenologicalRecordModel>? fenologia,
  }) {
    final completude = _calcularCompletudePercentual(
      temEstande: estande != null,
      temCV: cv != null,
      temFenologia: fenologia != null && fenologia.isNotEmpty,
    );

    String nivel;
    String recomendacao;
    
    if (completude >= 80) {
      nivel = 'EXCELENTE';
      recomendacao = 'Dados completos! Continue monitorando regularmente.';
    } else if (completude >= 50) {
      nivel = 'BOM';
      recomendacao = 'Bom conjunto de dados. Considere adicionar mais avaliações.';
    } else if (completude >= 30) {
      nivel = 'REGULAR';
      recomendacao = 'Dados parciais. Recomenda-se calcular estande e CV%.';
    } else {
      nivel = 'BAIXO';
      recomendacao = 'Poucos dados disponíveis. Realize avaliações de campo.';
    }

    return {
      'score': completude,
      'nivel': nivel,
      'recomendacao': recomendacao,
      'detalhes': {
        'tem_estande': estande != null,
        'tem_cv': cv != null,
        'tem_fenologia': fenologia != null && fenologia.isNotEmpty,
      },
    };
  }

  /// 🎯 AVALIA QUALIDADE GERAL DO CONJUNTO DE DADOS
  Map<String, dynamic> _avaliarQualidadeGeral({
    required int totalPlantios,
    required int comEstande,
    required int comCV,
    required int comFenologia,
    required double eficienciaMedia,
    required double cvMedio,
  }) {
    // Calcular score de qualidade (0-100)
    int score = 0;
    
    // 1. Cobertura de estande (30 pontos)
    if (totalPlantios > 0) {
      score += ((comEstande / totalPlantios) * 30).toInt();
    }
    
    // 2. Cobertura de CV% (25 pontos)
    if (totalPlantios > 0) {
      score += ((comCV / totalPlantios) * 25).toInt();
    }
    
    // 3. Cobertura fenológica (20 pontos)
    if (totalPlantios > 0) {
      score += ((comFenologia / totalPlantios) * 20).toInt();
    }
    
    // 4. Qualidade da eficiência (15 pontos)
    if (eficienciaMedia >= 90) score += 15;
    else if (eficienciaMedia >= 75) score += 10;
    else if (eficienciaMedia >= 60) score += 5;
    
    // 5. Qualidade do CV% (10 pontos)
    if (cvMedio <= 15) score += 10; // Excelente
    else if (cvMedio <= 25) score += 7; // Bom
    else if (cvMedio <= 35) score += 4; // Moderado

    String nivel;
    String recomendacoes;
    
    if (score >= 85) {
      nivel = 'EXCELENTE';
      recomendacoes = 'Parabéns! Excelente qualidade e completude dos dados. Continue o monitoramento regular.';
    } else if (score >= 70) {
      nivel = 'BOM';
      recomendacoes = 'Boa qualidade de dados. Para melhorar: calcule CV% e estande em todos os plantios.';
    } else if (score >= 50) {
      nivel = 'REGULAR';
      recomendacoes = 'Dados parciais. Recomendações: realizar mais avaliações de campo (estande e CV%).';
    } else {
      nivel = 'BAIXO';
      recomendacoes = 'Atenção! Poucos dados disponíveis. É essencial realizar: 1) Cálculo de estande, 2) Avaliação de CV%, 3) Registros fenológicos.';
    }

    return {
      'score': score,
      'nivel': nivel,
      'recomendacoes': recomendacoes,
      'detalhamento': {
        'cobertura_estande_percentual': totalPlantios > 0 ? (comEstande / totalPlantios * 100) : 0,
        'cobertura_cv_percentual': totalPlantios > 0 ? (comCV / totalPlantios * 100) : 0,
        'cobertura_fenologia_percentual': totalPlantios > 0 ? (comFenologia / totalPlantios * 100) : 0,
        'eficiencia_media': eficienciaMedia,
        'cv_medio': cvMedio,
      },
    };
  }

  /// 📭 RETORNA DADOS VAZIOS QUANDO NÃO HÁ PLANTIO
  Map<String, dynamic> _retornarDadosVazios() {
    return {
      'id': null,
      'talhao_id': null,
      'cultura_id': null,
      'plantio': {},
      'estande': {'tem_dados': false},
      'cv_uniformidade': {'tem_dados': false},
      'evolucao_fenologica': {'tem_dados': false, 'total_registros': 0},
      'metricas_calculadas': {
        'populacao_final': 0,
        'populacao_tipo': 'NENHUMA',
        'tem_estande': false,
        'tem_cv': false,
        'tem_fenologia': false,
        'completude_dados': 0,
      },
      'status_qualidade': {
        'score': 0,
        'nivel': 'SEM_DADOS',
        'recomendacao': 'Nenhum plantio encontrado. Crie um plantio primeiro.',
      },
    };
  }

  /// 📭 RETORNA ESTATÍSTICAS VAZIAS
  Map<String, dynamic> _retornarEstatisticasVazias() {
    return {
      'total_plantios': 0,
      'culturas': {},
      'talhoes': {},
      'variedades': {},
      'cobertura_dados': {
        'com_estande': 0,
        'com_cv': 0,
        'com_fenologia': 0,
        'percentual_estande': 0.0,
        'percentual_cv': 0.0,
        'percentual_fenologia': 0.0,
      },
      'medias': {
        'populacao_planejada': 0,
        'populacao_real': 0,
        'eficiencia_media': 0.0,
        'cv_medio': 0.0,
      },
      'qualidade_geral': {
        'score': 0,
        'nivel': 'SEM_DADOS',
        'recomendacoes': 'Nenhum dado disponível.',
      },
      'plantios_detalhados': [],
    };
  }

  /// Obter primeira foto do plantio (se disponível)
  String? _obterPrimeiraFoto(PlantioIntegrado plantio) {
    // Por enquanto, retornar null pois o PlantioIntegrado não tem campo de fotos
    // TODO: Adicionar busca de fotos do banco de dados se necessário
    return null;
  }
}

