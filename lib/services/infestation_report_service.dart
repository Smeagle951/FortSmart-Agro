/// 🎯 Serviço de Relatórios de Infestação
/// Integração entre Mapa de Infestação e IA FortSmart com Aprendizado Contínuo

import '../models/infestation_report_model.dart';
import '../services/fortsmart_agronomic_ai.dart';
import '../services/ia_aprendizado_continuo.dart';
import '../services/organism_v3_integration_service.dart';
import '../utils/logger.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/services.dart';

class InfestationReportService {
  static const String _tag = 'InfestationReportService';
  final FortSmartAgronomicAI _ai = FortSmartAgronomicAI();
  final IAAprendizadoContinuo _learningService = IAAprendizadoContinuo();
  final AppDatabase _appDatabase = AppDatabase();
  final OrganismV3IntegrationService _v3Service = OrganismV3IntegrationService();

  /// Gera relatório completo de infestação baseado em dados reais
  Future<InfestationReportModel> gerarRelatorioCompleto({
    required String talhaoId,
    required String talhaoNome,
    required String cultura,
    required String variedade,
    required List<Map<String, dynamic>> pontosInfestacao,
    required Map<String, dynamic> dadosAgronomicos,
  }) async {
    try {
      Logger.info('$_tag: Gerando relatório completo para talhão $talhaoId');
      
      // Inicializar serviços
      await _ai.initialize();
      await _learningService.initialize();
      
      // ✅ Converter pontos de infestação (com tratamento de null)
      final pontos = pontosInfestacao.map((p) => InfestationPoint(
        id: p['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        latitude: (p['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (p['longitude'] as num?)?.toDouble() ?? 0.0,
        organismo: p['organismo'] as String? ?? p['subtipo'] as String? ?? 'Organismo não identificado',
        nivel: p['nivel'] as String? ?? 'Baixo',
        intensidade: (p['intensidade'] as num?)?.toDouble() ?? (p['percentual'] as num?)?.toDouble() ?? 0.0,
        areaAfetada: (p['areaAfetada'] as num?)?.toDouble() ?? 0.0,
        sintomas: p['sintomas'] as String? ?? '',
        observacoes: p['observacoes'] as String? ?? p['observacao'] as String? ?? '',
        dataDetectado: p['dataDetectado'] != null ? DateTime.parse(p['dataDetectado'] as String) : (p['data_hora'] != null ? DateTime.parse(p['data_hora'] as String) : DateTime.now()),
        fotos: List<String>.from(p['fotos'] ?? p['foto_paths']?.toString().split(';') ?? []),
        dadosTecnicos: Map<String, dynamic>.from(p['dadosTecnicos'] ?? {}),
      )).toList();
      
      // Análise da IA FortSmart com dados reais dos JSONs
      final analiseIA = await _gerarAnaliseIAComDadosReais(pontos, cultura, dadosAgronomicos);
      
      // Gerar prescrições baseadas na análise e JSONs
      final prescricoes = await _gerarPrescricoesComDadosReais(pontos, analiseIA, cultura);
      
      // Buscar feedbacks de aprendizado
      final feedbacks = await _buscarFeedbacks(talhaoId);
      
      // Criar relatório
      final relatorio = InfestationReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: talhaoId,
        talhaoNome: talhaoNome,
        cultura: cultura,
        variedade: variedade,
        dataColeta: DateTime.now(),
        dataAnalise: DateTime.now(),
        status: _determinarStatus(pontos),
        pontosInfestacao: pontos,
        dadosAgronomicos: dadosAgronomicos,
        analiseIA: analiseIA,
        prescricoes: prescricoes,
        feedbacks: feedbacks,
        observacoes: _gerarObservacoes(pontos, analiseIA),
      );
      
      // Salvar relatório no banco
      await _salvarRelatorio(relatorio);
      
      Logger.info('$_tag: Relatório gerado com sucesso - ${pontos.length} pontos analisados');
      return relatorio;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar relatório: $e');
      rethrow;
    }
  }

  /// Gera análise da IA FortSmart
  Future<Map<String, dynamic>> _gerarAnaliseIA(
    List<InfestationPoint> pontos,
    String cultura,
    Map<String, dynamic> dadosAgronomicos,
  ) async {
    try {
      // Preparar dados para IA
      final dadosParaIA = {
        'cultura': cultura,
        'pontos': pontos.map((p) => {
          'organismo': p.organismo,
          'nivel': p.nivel,
          'intensidade': p.intensidade,
          'sintomas': p.sintomas,
          'areaAfetada': p.areaAfetada,
          'diasDesdeDetectado': p.diasDesdeDetectado,
        }).toList(),
        'dadosAgronomicos': dadosAgronomicos,
        'condicoesAmbientais': await _obterCondicoesAmbientais(),
      };
      
      // Análise com IA FortSmart
      final analise = await _ai.analyzeInfestation(
        organismo: pontos.isNotEmpty ? pontos.first.organismo : 'Desconhecido',
        densidadeAtual: pontos.isNotEmpty ? pontos.first.intensidade : 0.0,
        cultura: cultura,
        estagioFenologico: 'R1',
        temperatura: dadosAgronomicos['temperatura'] ?? 25.0,
        umidade: dadosAgronomicos['umidade'] ?? 70.0,
      );
      
      // Análise de aprendizado contínuo
      final aprendizado = await _learningService.predizerComAprendizado(
        talhaoId: 'talhao_001',
        cultura: cultura,
        organismo: pontos.isNotEmpty ? pontos.first.organismo : 'Desconhecido',
        densidadeAtual: pontos.isNotEmpty ? pontos.first.intensidade : 0.0,
        estagioFenologico: 'R1',
        temperatura: dadosAgronomicos['temperatura'] ?? 25.0,
        umidade: dadosAgronomicos['umidade'] ?? 70.0,
      );
      
      // Combinar análises
      return {
        'versaoIA': 'FortSmart v2.0',
        'dataAnalise': DateTime.now().toIso8601String(),
        'nivelRisco': _calcularNivelRisco(pontos),
        'scoreConfianca': (analise['scoreConfianca'] as num?)?.toDouble() ?? 0.8,
        'organismosDetectados': pontos.map((p) => p.organismo).toSet().toList(),
        'sintomasIdentificados': pontos.map((p) => p.sintomas).toSet().toList(),
        'condicoesFavoraveis': analise['condicoesFavoraveis'] ?? {},
        'recomendacoes': analise['recomendacoes'] ?? [],
        'alertas': analise['alertas'] ?? [],
        'aprendizadoContinuo': aprendizado,
        'dadosTecnicos': {
          'totalPontos': pontos.length,
          'areaTotalAfetada': pontos.fold<double>(0.0, (sum, p) => sum + p.areaAfetada),
          'intensidadeMedia': pontos.fold<double>(0.0, (sum, p) => sum + p.intensidade) / pontos.length,
        },
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro na análise da IA: $e');
      return _gerarAnaliseFallback(pontos);
    }
  }

  /// Gera prescrições baseadas na análise
  Future<List<PrescriptionModel>> _gerarPrescricoes(
    List<InfestationPoint> pontos,
    Map<String, dynamic> analiseIA,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    try {
      // Agrupar organismos por tipo
      final organismosPorTipo = <String, List<InfestationPoint>>{};
      for (final ponto in pontos) {
        final tipo = _classificarOrganismo(ponto.organismo);
        organismosPorTipo[tipo] ??= [];
        organismosPorTipo[tipo]!.add(ponto);
      }
      
      // Gerar prescrições específicas para cada tipo de organismo
      for (final entry in organismosPorTipo.entries) {
        final tipo = entry.key;
        final pontosTipo = entry.value;
        
        // Buscar dados do catálogo de organismos
        final dadosCatalogo = await _learningService.obterRecomendacoesCatalogo(
          cultura,
          pontosTipo.first.organismo,
        );
        
        if (dadosCatalogo.isNotEmpty) {
          // Gerar prescrições específicas baseadas no tipo de organismo
          final prescricoesEspecificas = await _gerarPrescricoesEspecificas(
            tipo,
            pontosTipo,
            dadosCatalogo,
            cultura,
          );
          prescricoes.addAll(prescricoesEspecificas);
        }
      }
      
      // Prescrição emergencial se necessário
      final pontosCriticos = pontos.where((p) => p.nivel == 'critico').length;
      if (pontosCriticos > 0) {
        prescricoes.addAll(await _gerarPrescricoesEmergenciais(cultura));
      }
      
      Logger.info('$_tag: Geradas ${prescricoes.length} prescrições específicas');
      return prescricoes;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar prescrições: $e');
      return [];
    }
  }

  /// Gera prescrições específicas baseadas no tipo de organismo
  Future<List<PrescriptionModel>> _gerarPrescricoesEspecificas(
    String tipo,
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCatalogo,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    switch (tipo.toLowerCase()) {
      case 'fungo':
        prescricoes.addAll(await _gerarPrescricoesFungicidas(pontos, dadosCatalogo, cultura));
        break;
      case 'inseto':
        prescricoes.addAll(await _gerarPrescricoesInseticidas(pontos, dadosCatalogo, cultura));
        break;
      case 'bacteria':
        prescricoes.addAll(await _gerarPrescricoesBactericidas(pontos, dadosCatalogo, cultura));
        break;
      case 'virus':
        prescricoes.addAll(await _gerarPrescricoesViricidas(pontos, dadosCatalogo, cultura));
        break;
      default:
        prescricoes.addAll(await _gerarPrescricoesGenericas(pontos, dadosCatalogo, cultura));
    }
    
    return prescricoes;
  }

  /// Gera prescrições fungicidas específicas
  Future<List<PrescriptionModel>> _gerarPrescricoesFungicidas(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCatalogo,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    // Fungicidas específicos baseados no organismo
    final fungicidas = _obterFungicidasEspecificos(pontos.first.organismo, cultura);
    
    for (final fungicida in fungicidas) {
      prescricoes.add(PrescriptionModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_fungicida_${fungicida['nome']}',
        tipo: 'preventivo',
        categoria: 'quimico',
        produto: fungicida['nome'] as String,
        dosagem: fungicida['dosagem'] as String,
        aplicacao: fungicida['aplicacao'] as String,
        frequencia: fungicida['frequencia'] as String,
        observacoes: fungicida['observacoes'] as String,
        prioridade: _determinarPrioridade(pontos),
        dataPrescricao: DateTime.now(),
        status: 'pendente',
        dadosTecnicos: fungicida,
      ));
    }
    
    return prescricoes;
  }

  /// Gera prescrições inseticidas específicas
  Future<List<PrescriptionModel>> _gerarPrescricoesInseticidas(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCatalogo,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    // Inseticidas específicos baseados no organismo
    final inseticidas = _obterInseticidasEspecificos(pontos.first.organismo, cultura);
    
    for (final inseticida in inseticidas) {
      prescricoes.add(PrescriptionModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_inseticida_${inseticida['nome']}',
        tipo: 'preventivo',
        categoria: 'quimico',
        produto: inseticida['nome'] as String,
        dosagem: inseticida['dosagem'] as String,
        aplicacao: inseticida['aplicacao'] as String,
        frequencia: inseticida['frequencia'] as String,
        observacoes: inseticida['observacoes'] as String,
        prioridade: _determinarPrioridade(pontos),
        dataPrescricao: DateTime.now(),
        status: 'pendente',
        dadosTecnicos: inseticida,
      ));
    }
    
    return prescricoes;
  }

  /// Gera prescrições bactericidas específicas
  Future<List<PrescriptionModel>> _gerarPrescricoesBactericidas(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCatalogo,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    // Bactericidas específicos baseados no organismo
    final bactericidas = _obterBactericidasEspecificos(pontos.first.organismo, cultura);
    
    for (final bactericida in bactericidas) {
      prescricoes.add(PrescriptionModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_bactericida_${bactericida['nome']}',
        tipo: 'preventivo',
        categoria: 'quimico',
        produto: bactericida['nome'] as String,
        dosagem: bactericida['dosagem'] as String,
        aplicacao: bactericida['aplicacao'] as String,
        frequencia: bactericida['frequencia'] as String,
        observacoes: bactericida['observacoes'] as String,
        prioridade: _determinarPrioridade(pontos),
        dataPrescricao: DateTime.now(),
        status: 'pendente',
        dadosTecnicos: bactericida,
      ));
    }
    
    return prescricoes;
  }

  /// Gera prescrições viricidas específicas
  Future<List<PrescriptionModel>> _gerarPrescricoesViricidas(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCatalogo,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    // Viricidas específicos baseados no organismo
    final viricidas = _obterViricidasEspecificos(pontos.first.organismo, cultura);
    
    for (final viricida in viricidas) {
      prescricoes.add(PrescriptionModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_viricida_${viricida['nome']}',
        tipo: 'preventivo',
        categoria: 'quimico',
        produto: viricida['nome'] as String,
        dosagem: viricida['dosagem'] as String,
        aplicacao: viricida['aplicacao'] as String,
        frequencia: viricida['frequencia'] as String,
        observacoes: viricida['observacoes'] as String,
        prioridade: _determinarPrioridade(pontos),
        dataPrescricao: DateTime.now(),
        status: 'pendente',
        dadosTecnicos: viricida,
      ));
    }
    
    return prescricoes;
  }

  /// Gera prescrições genéricas
  Future<List<PrescriptionModel>> _gerarPrescricoesGenericas(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCatalogo,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    // Prescrições genéricas baseadas no catálogo
    if (dadosCatalogo['manejo_quimico'] != null) {
      prescricoes.add(PrescriptionModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_generico_quimico',
        tipo: 'preventivo',
        categoria: 'quimico',
        produto: dadosCatalogo['manejo_quimico']?['produto'] ?? 'Produto recomendado',
        dosagem: dadosCatalogo['manejo_quimico']?['dosagem'] ?? 'Dosagem conforme bula',
        aplicacao: dadosCatalogo['manejo_quimico']?['aplicacao'] ?? 'Aplicação foliar',
        frequencia: dadosCatalogo['manejo_quimico']?['frequencia'] ?? 'Conforme necessidade',
        observacoes: dadosCatalogo['observacoes'] ?? 'Seguir recomendações do catálogo',
        prioridade: _determinarPrioridade(pontos),
        dataPrescricao: DateTime.now(),
        status: 'pendente',
        dadosTecnicos: dadosCatalogo,
      ));
    }
    
    return prescricoes;
  }

  /// Gera prescrições emergenciais
  Future<List<PrescriptionModel>> _gerarPrescricoesEmergenciais(String cultura) async {
    final prescricoes = <PrescriptionModel>[];
    
    // Fungicida emergencial
    prescricoes.add(PrescriptionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_emergencial_fungicida',
      tipo: 'emergencial',
      categoria: 'quimico',
      produto: 'Azoxistrobina + Ciproconazol',
      dosagem: '0.5 L/ha',
      aplicacao: 'Aplicação foliar imediata',
      frequencia: 'Aplicação única',
      observacoes: 'Ação emergencial para controle imediato de fungos',
      prioridade: 'alta',
      dataPrescricao: DateTime.now(),
      status: 'pendente',
      dadosTecnicos: {'emergencial': true, 'tipo': 'fungicida'},
    ));
    
    // Inseticida emergencial
    prescricoes.add(PrescriptionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_emergencial_inseticida',
      tipo: 'emergencial',
      categoria: 'quimico',
      produto: 'Lambda-cialotrina + Tiametoxam',
      dosagem: '0.3 L/ha',
      aplicacao: 'Aplicação foliar imediata',
      frequencia: 'Aplicação única',
      observacoes: 'Ação emergencial para controle imediato de insetos',
      prioridade: 'alta',
      dataPrescricao: DateTime.now(),
      status: 'pendente',
      dadosTecnicos: {'emergencial': true, 'tipo': 'inseticida'},
    ));
    
    return prescricoes;
  }

  /// Busca feedbacks de aprendizado
  Future<List<LearningFeedback>> _buscarFeedbacks(String talhaoId) async {
    try {
      final db = await _appDatabase.database;
      final feedbacksData = await db.query(
        'infestation_learning_feedback',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_feedback DESC',
      );
      
      return feedbacksData.map((f) => LearningFeedback(
        id: f['id'] as String,
        relatorioId: f['relatorio_id'] as String,
        prescricaoId: f['prescricao_id'] as String,
        tipo: f['tipo'] as String,
        metodoUtilizado: f['metodo_utilizado'] as String,
        resultado: f['resultado'] as String,
        observacoes: f['observacoes'] as String,
        dataFeedback: DateTime.parse(f['data_feedback'] as String),
        usuarioId: f['usuario_id'] as String,
        dadosExtras: Map<String, dynamic>.from(
          jsonDecode(f['dados_extras'] as String? ?? '{}')
        ),
      )).toList();
      
    } catch (e) {
      Logger.error('$_tag: Erro ao buscar feedbacks: $e');
      return [];
    }
  }

  /// Salva feedback de aprendizado
  Future<void> salvarFeedback({
    required String relatorioId,
    required String prescricaoId,
    required String tipo,
    required String metodoUtilizado,
    required String resultado,
    required String observacoes,
    required String usuarioId,
    Map<String, dynamic>? dadosExtras,
  }) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert('infestation_learning_feedback', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'relatorio_id': relatorioId,
        'prescricao_id': prescricaoId,
        'tipo': tipo,
        'metodo_utilizado': metodoUtilizado,
        'resultado': resultado,
        'observacoes': observacoes,
        'data_feedback': DateTime.now().toIso8601String(),
        'usuario_id': usuarioId,
        'dados_extras': jsonEncode(dadosExtras ?? {}),
      });
      
      // Atualizar aprendizado da IA
      await _learningService.atualizarAprendizado(
        talhaoId: 'talhao_001',
        dadosReais: {},
        predicoesAnteriores: {},
      );
      
      Logger.info('$_tag: Feedback salvo com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao salvar feedback: $e');
    }
  }

  /// Obtém condições ambientais atuais
  Future<Map<String, dynamic>> _obterCondicoesAmbientais() async {
    // Simular dados ambientais (em produção, viria de sensores)
    return {
      'temperatura': 28.5,
      'umidade': 75.0,
      'precipitacao': 15.0,
      'vento': 12.0,
      'pressao': 1013.25,
    };
  }

  /// Calcula nível de risco
  String _calcularNivelRisco(List<InfestationPoint> pontos) {
    final pontosCriticos = pontos.where((p) => p.nivel == 'critico').length;
    final areaTotalAfetada = pontos.fold<double>(0.0, (sum, p) => sum + p.areaAfetada);
    
    if (pontosCriticos >= 3 || areaTotalAfetada >= 5.0) return 'Alto';
    if (pontosCriticos >= 1 || areaTotalAfetada >= 2.0) return 'Médio';
    return 'Baixo';
  }

  /// Determina status do relatório
  String _determinarStatus(List<InfestationPoint> pontos) {
    final pontosCriticos = pontos.where((p) => p.nivel == 'critico').length;
    if (pontosCriticos > 0) return 'critico';
    if (pontos.isNotEmpty) return 'ativo';
    return 'controlado';
  }

  /// Classifica organismo por tipo
  String _classificarOrganismo(String organismo) {
    if (organismo.toLowerCase().contains('lagarta')) return 'inseto';
    if (organismo.toLowerCase().contains('fungo')) return 'fungo';
    if (organismo.toLowerCase().contains('bacteria')) return 'bacteria';
    if (organismo.toLowerCase().contains('virus')) return 'virus';
    return 'outros';
  }

  /// Determina prioridade baseada nos pontos
  String _determinarPrioridade(List<InfestationPoint> pontos) {
    final pontosCriticos = pontos.where((p) => p.nivel == 'critico').length;
    if (pontosCriticos > 0) return 'alta';
    if (pontos.length > 2) return 'media';
    return 'baixa';
  }

  /// Gera observações baseadas na análise
  String _gerarObservacoes(List<InfestationPoint> pontos, Map<String, dynamic> analiseIA) {
    final organismos = pontos.map((p) => p.organismo).toSet().join(', ');
    final nivelRisco = analiseIA['nivelRisco'] as String? ?? 'Baixo';
    
    return 'Relatório gerado automaticamente pela IA FortSmart. '
           'Organismos detectados: $organismos. '
           'Nível de risco: $nivelRisco. '
           'Recomendações baseadas no catálogo de organismos e aprendizado contínuo.';
  }

  /// Gera análise fallback
  Map<String, dynamic> _gerarAnaliseFallback(List<InfestationPoint> pontos) {
    return {
      'versaoIA': 'FortSmart v2.0 (Fallback)',
      'dataAnalise': DateTime.now().toIso8601String(),
      'nivelRisco': _calcularNivelRisco(pontos),
      'scoreConfianca': 0.6,
      'organismosDetectados': pontos.map((p) => p.organismo).toSet().toList(),
      'sintomasIdentificados': pontos.map((p) => p.sintomas).toSet().toList(),
      'condicoesFavoraveis': {},
      'recomendacoes': ['Análise básica - IA indisponível'],
      'alertas': ['Sistema em modo básico'],
      'dadosTecnicos': {
        'totalPontos': pontos.length,
        'areaTotalAfetada': pontos.fold<double>(0.0, (sum, p) => sum + p.areaAfetada),
      },
    };
  }

  /// Salva relatório no banco
  Future<void> _salvarRelatorio(InfestationReportModel relatorio) async {
    try {
      final db = await _appDatabase.database;
      
      await db.insert('infestation_reports', {
        'id': relatorio.id,
        'talhao_id': relatorio.talhaoId,
        'talhao_nome': relatorio.talhaoNome,
        'cultura': relatorio.cultura,
        'variedade': relatorio.variedade,
        'data_coleta': relatorio.dataColeta.toIso8601String(),
        'data_analise': relatorio.dataAnalise.toIso8601String(),
        'status': relatorio.status,
        'dados_agronomicos': jsonEncode(relatorio.dadosAgronomicos),
        'analise_ia': jsonEncode(relatorio.analiseIA),
        'observacoes': relatorio.observacoes,
      });
      
      Logger.info('$_tag: Relatório salvo no banco de dados');
      
    } catch (e) {
      Logger.error('$_tag: Erro ao salvar relatório: $e');
    }
  }

  /// Obtém fungicidas específicos baseados no organismo e cultura
  List<Map<String, dynamic>> _obterFungicidasEspecificos(String organismo, String cultura) {
    final fungicidas = <Map<String, dynamic>>[];
    
    // Fungicidas para Ferrugem Asiática (Soja)
    if (organismo.toLowerCase().contains('ferrugem') && cultura.toLowerCase() == 'soja') {
      fungicidas.addAll([
        {
          'nome': 'Azoxistrobina + Ciproconazol',
          'dosagem': '0.5 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '7-10 dias',
          'observacoes': 'Eficaz contra ferrugem asiática da soja',
          'classe': 'Triazol + Estrobilurina',
        },
        {
          'nome': 'Tebuconazol + Trifloxistrobina',
          'dosagem': '0.4 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '10-14 dias',
          'observacoes': 'Controle preventivo e curativo',
          'classe': 'Triazol + Estrobilurina',
        },
        {
          'nome': 'Protioconazol + Trifloxistrobina',
          'dosagem': '0.3 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '7-10 dias',
          'observacoes': 'Alta eficácia contra ferrugem',
          'classe': 'Triazol + Estrobilurina',
        },
      ]);
    }
    
    // Fungicidas para Antracnose (Soja)
    if (organismo.toLowerCase().contains('antracnose') && cultura.toLowerCase() == 'soja') {
      fungicidas.addAll([
        {
          'nome': 'Carbendazim + Tiofanato-metílico',
          'dosagem': '1.0 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '10-14 dias',
          'observacoes': 'Controle de antracnose em soja',
          'classe': 'Benzimidazol',
        },
        {
          'nome': 'Tebuconazol',
          'dosagem': '0.5 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '14 dias',
          'observacoes': 'Fungicida sistêmico para antracnose',
          'classe': 'Triazol',
        },
      ]);
    }
    
    // Fungicidas para Milho
    if (cultura.toLowerCase() == 'milho') {
      fungicidas.addAll([
        {
          'nome': 'Azoxistrobina + Ciproconazol',
          'dosagem': '0.5 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '10-14 dias',
          'observacoes': 'Controle de doenças foliares do milho',
          'classe': 'Triazol + Estrobilurina',
        },
        {
          'nome': 'Tebuconazol + Trifloxistrobina',
          'dosagem': '0.4 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '14 dias',
          'observacoes': 'Proteção contra ferrugem e manchas',
          'classe': 'Triazol + Estrobilurina',
        },
      ]);
    }
    
    return fungicidas;
  }

  /// Obtém inseticidas específicos baseados no organismo e cultura
  List<Map<String, dynamic>> _obterInseticidasEspecificos(String organismo, String cultura) {
    final inseticidas = <Map<String, dynamic>>[];
    
    // Inseticidas para Lagarta-do-cartucho (Milho)
    if (organismo.toLowerCase().contains('lagarta') && cultura.toLowerCase() == 'milho') {
      inseticidas.addAll([
        {
          'nome': 'Lambda-cialotrina + Tiametoxam',
          'dosagem': '0.3 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '7-10 dias',
          'observacoes': 'Controle eficaz de lagarta-do-cartucho',
          'classe': 'Piretróide + Neonicotinoide',
        },
        {
          'nome': 'Clorantraniliprole + Lambda-cialotrina',
          'dosagem': '0.2 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '10-14 dias',
          'observacoes': 'Controle sistêmico e de contato',
          'classe': 'Diamida + Piretróide',
        },
        {
          'nome': 'Espinetoram',
          'dosagem': '0.1 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '7 dias',
          'observacoes': 'Controle biológico de lagartas',
          'classe': 'Espinosina',
        },
      ]);
    }
    
    // Inseticidas para Soja
    if (cultura.toLowerCase() == 'soja') {
      inseticidas.addAll([
        {
          'nome': 'Lambda-cialotrina + Tiametoxam',
          'dosagem': '0.3 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '7-10 dias',
          'observacoes': 'Controle de pragas da soja',
          'classe': 'Piretróide + Neonicotinoide',
        },
        {
          'nome': 'Clorantraniliprole + Lambda-cialotrina',
          'dosagem': '0.2 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '10-14 dias',
          'observacoes': 'Controle sistêmico de pragas',
          'classe': 'Diamida + Piretróide',
        },
      ]);
    }
    
    return inseticidas;
  }

  /// Obtém bactericidas específicos baseados no organismo e cultura
  List<Map<String, dynamic>> _obterBactericidasEspecificos(String organismo, String cultura) {
    final bactericidas = <Map<String, dynamic>>[];
    
    // Bactericidas para Soja
    if (cultura.toLowerCase() == 'soja') {
      bactericidas.addAll([
        {
          'nome': 'Cobre + Mancozebe',
          'dosagem': '2.0 kg/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '10-14 dias',
          'observacoes': 'Controle de doenças bacterianas',
          'classe': 'Cobre + Ditiocarbamato',
        },
        {
          'nome': 'Oxicloreto de Cobre',
          'dosagem': '1.5 kg/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '14 dias',
          'observacoes': 'Proteção contra bactérias',
          'classe': 'Cobre',
        },
      ]);
    }
    
    return bactericidas;
  }

  /// Obtém viricidas específicos baseados no organismo e cultura
  List<Map<String, dynamic>> _obterViricidasEspecificos(String organismo, String cultura) {
    final viricidas = <Map<String, dynamic>>[];
    
    // Viricidas para Soja
    if (cultura.toLowerCase() == 'soja') {
      viricidas.addAll([
        {
          'nome': 'Imidacloprido + Tiametoxam',
          'dosagem': '0.2 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '14 dias',
          'observacoes': 'Controle de vetores de vírus',
          'classe': 'Neonicotinoide',
        },
        {
          'nome': 'Lambda-cialotrina',
          'dosagem': '0.1 L/ha',
          'aplicacao': 'Aplicação foliar',
          'frequencia': '7-10 dias',
          'observacoes': 'Controle de insetos vetores',
          'classe': 'Piretróide',
        },
      ]);
    }
    
    return viricidas;
  }

  /// Realiza análise da IA com dados reais dos JSONs
  Future<Map<String, dynamic>> _gerarAnaliseIAComDadosReais(
    List<InfestationPoint> pontos,
    String cultura,
    Map<String, dynamic> dadosAgronomicos,
  ) async {
    try {
      Logger.info('$_tag: Iniciando análise com dados reais dos JSONs para cultura: $cultura');
      
      // Carregar dados do JSON da cultura
      final dadosCultura = await _carregarDadosCulturaJSON(cultura);
      
      // Análise baseada em coordenadas reais
      final analiseCoordenadas = await _analisarPorCoordenadas(pontos, dadosCultura);
      
      // Análise baseada em organismos dos JSONs
      final analiseOrganismos = await _analisarOrganismosJSON(pontos, dadosCultura);
      
      // Combinar análises
      return {
        'versaoIA': 'Sistema FortSmart Agro v3.0',
        'dataAnalise': DateTime.now().toIso8601String(),
        'nivelRisco': _calcularNivelRiscoComDadosReais(pontos, analiseCoordenadas),
        'scoreConfianca': _calcularScoreConfianca(analiseCoordenadas, analiseOrganismos),
        'organismosDetectados': pontos.map((p) => p.organismo).toSet().toList(),
        'sintomasIdentificados': pontos.map((p) => p.sintomas).toSet().toList(),
        'condicoesFavoraveis': analiseCoordenadas['condicoesFavoraveis'] ?? {},
        'recomendacoes': analiseOrganismos['recomendacoes'] ?? [],
        'alertas': _gerarAlertasInteligentes(pontos, analiseCoordenadas),
        'dadosCoordenadas': analiseCoordenadas,
        'dadosOrganismos': analiseOrganismos,
        'dadosTecnicos': {
          'totalPontos': pontos.length,
          'areaTotalAfetada': pontos.fold<double>(0.0, (sum, p) => sum + p.areaAfetada),
          'intensidadeMedia': pontos.fold<double>(0.0, (sum, p) => sum + p.intensidade) / pontos.length,
          'coordenadasAnalisadas': pontos.map((p) => '${p.latitude},${p.longitude}').toList(),
        },
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro na análise com dados reais: $e');
      return _gerarAnaliseFallback(pontos);
    }
  }

  /// Carrega dados do JSON da cultura
  Future<Map<String, dynamic>> _carregarDadosCulturaJSON(String cultura) async {
    try {
      final nomeArquivo = 'organismos_${cultura.toLowerCase()}.json';
      final caminhoArquivo = 'lib/data/$nomeArquivo';
      
      // Tentar carregar do sistema de arquivos primeiro
      try {
        final file = File(caminhoArquivo);
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final dados = jsonDecode(jsonString) as Map<String, dynamic>;
          
          Logger.info('$_tag: Dados da cultura $cultura carregados de $caminhoArquivo: ${dados['organismos']?.length ?? 0} organismos');
          return dados;
        }
      } catch (e) {
        Logger.warning('$_tag: Erro ao carregar de $caminhoArquivo: $e');
      }
      
      // Fallback para assets se não encontrar em lib/data
      try {
        final jsonString = await rootBundle.loadString('assets/data/$nomeArquivo');
        final dados = jsonDecode(jsonString) as Map<String, dynamic>;
        
        Logger.info('$_tag: Dados da cultura $cultura carregados de assets/data/$nomeArquivo: ${dados['organismos']?.length ?? 0} organismos');
        return dados;
      } catch (e) {
        Logger.warning('$_tag: Erro ao carregar de assets/data/$nomeArquivo: $e');
      }
      
      // Se não encontrar em nenhum lugar, retornar dados vazios
      Logger.warning('$_tag: Arquivo $nomeArquivo não encontrado em lib/data nem assets/data');
      return {};
      
    } catch (e) {
      Logger.error('$_tag: Erro ao carregar JSON da cultura $cultura: $e');
      return {};
    }
  }

  /// Analisa pontos por coordenadas
  Future<Map<String, dynamic>> _analisarPorCoordenadas(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCultura,
  ) async {
    final analise = <String, dynamic>{};
    
    // Agrupar por proximidade geográfica
    final grupos = _agruparPorProximidade(pontos);
    
    for (final grupo in grupos) {
      final centro = _calcularCentroGeografico(grupo);
      final intensidadeMedia = grupo.fold<double>(0.0, (sum, p) => sum + p.intensidade) / grupo.length;
      
      analise['grupos'] ??= [];
      analise['grupos'].add({
        'centro': centro,
        'pontos': grupo.length,
        'intensidadeMedia': intensidadeMedia,
        'organismos': grupo.map((p) => p.organismo).toSet().toList(),
      });
    }
    
    return analise;
  }

  /// Analisa organismos baseado nos JSONs (v3.0)
  Future<Map<String, dynamic>> _analisarOrganismosJSON(
    List<InfestationPoint> pontos,
    Map<String, dynamic> dadosCultura,
  ) async {
    final analise = <String, dynamic>{};
    final organismos = dadosCultura['organismos'] as List<dynamic>? ?? [];
    
    // Tentar usar v3.0 primeiro
    final cultura = dadosCultura['cultura']?.toString() ?? '';
    
    for (final ponto in pontos) {
      // Buscar dados v3.0
      final dadosV3 = await _v3Service.getOrganismDataForReport(
        organismoNome: ponto.organismo,
        cultura: cultura,
        temperatura: dadosCultura['temperatura'] as double?,
        umidade: dadosCultura['umidade'] as double?,
      );
      
      // Se encontrou v3.0, usar dados enriquecidos
      if (dadosV3['versao'] == '3.0') {
        analise['organismos'] ??= [];
        analise['organismos'].add({
          'nome': dadosV3['nome'],
          'nome_cientifico': dadosV3['nome_cientifico'],
          'categoria': dadosV3['categoria'],
          'sintomas': dadosV3['sintomas'],
          'dano_economico': dadosV3['dano_economico'],
          'manejo_quimico': dadosV3['manejo_quimico'],
          'manejo_biologico': dadosV3['manejo_biologico'],
          'manejo_cultural': dadosV3['manejo_cultural'],
          'nivel_acao': dadosV3['nivel_acao'],
          'coordenada': '${ponto.latitude},${ponto.longitude}',
          'intensidade': ponto.intensidade,
          
          // Dados v3.0 enriquecidos
          'risco_climatico': dadosV3['risco_climatico'],
          'condicoes_climaticas': dadosV3['condicoes_climaticas'],
          'ciclo_vida': dadosV3['ciclo_vida'],
          'economia_agronomica': dadosV3['economia_agronomica'],
          'rotacao_resistencia': dadosV3['rotacao_resistencia'],
          'fontes_referencia': dadosV3['fontes_referencia'],
        });
      } else {
        // Fallback para dados v2.0
        final organismoData = organismos.firstWhere(
          (org) => org['nome'] == ponto.organismo,
          orElse: () => null,
        );
        
        if (organismoData != null) {
          analise['organismos'] ??= [];
          analise['organismos'].add({
            'nome': ponto.organismo,
            'categoria': organismoData['categoria'],
            'sintomas': organismoData['sintomas'],
            'dano_economico': organismoData['dano_economico'],
            'manejo_quimico': organismoData['manejo_quimico'],
            'manejo_biologico': organismoData['manejo_biologico'],
            'manejo_cultural': organismoData['manejo_cultural'],
            'nivel_acao': organismoData['nivel_acao'],
            'fases': organismoData['fases'],
            'coordenada': '${ponto.latitude},${ponto.longitude}',
            'intensidade': ponto.intensidade,
          });
        }
      }
    }
    
    return analise;
  }

  /// Gera prescrições com dados reais dos JSONs
  Future<List<PrescriptionModel>> _gerarPrescricoesComDadosReais(
    List<InfestationPoint> pontos,
    Map<String, dynamic> analiseIA,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    
    try {
      // Carregar dados da cultura
      final dadosCultura = await _carregarDadosCulturaJSON(cultura);
      
      // Gerar prescrições baseadas nos organismos dos JSONs
      for (final ponto in pontos) {
        final prescricoesOrganismo = await _gerarPrescricoesPorOrganismo(
          ponto,
          dadosCultura,
          cultura,
        );
        prescricoes.addAll(prescricoesOrganismo);
      }
      
      Logger.info('$_tag: Geradas ${prescricoes.length} prescrições com dados reais');
      return prescricoes;
      
    } catch (e) {
      Logger.error('$_tag: Erro ao gerar prescrições com dados reais: $e');
      return [];
    }
  }

  /// Gera prescrições por organismo baseado nos JSONs
  Future<List<PrescriptionModel>> _gerarPrescricoesPorOrganismo(
    InfestationPoint ponto,
    Map<String, dynamic> dadosCultura,
    String cultura,
  ) async {
    final prescricoes = <PrescriptionModel>[];
    final organismos = dadosCultura['organismos'] as List<dynamic>? ?? [];
    
    final organismoData = organismos.firstWhere(
      (org) => org['nome'] == ponto.organismo,
      orElse: () => null,
    );
    
    if (organismoData != null) {
      // Prescrição química
      final manejoQuimico = organismoData['manejo_quimico'] as List<dynamic>? ?? [];
      for (final produto in manejoQuimico) {
        prescricoes.add(PrescriptionModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${produto}',
          tipo: 'preventivo',
          categoria: 'quimico',
          produto: produto.toString(),
          dosagem: _obterDosagemPorProduto(produto.toString(), cultura),
          aplicacao: 'Aplicação foliar',
          frequencia: _obterFrequenciaPorOrganismo(organismoData),
          observacoes: 'Baseado em dados do catálogo de organismos',
          prioridade: _determinarPrioridade([ponto]),
          dataPrescricao: DateTime.now(),
          status: 'pendente',
          dadosTecnicos: {
            'organismo': ponto.organismo,
            'coordenada': '${ponto.latitude},${ponto.longitude}',
            'fonte': 'JSON_${cultura}',
            'nivel_acao': organismoData['nivel_acao'],
          },
        ));
      }
      
      // Prescrição biológica
      final manejoBiologico = organismoData['manejo_biologico'] as List<dynamic>? ?? [];
      for (final produto in manejoBiologico) {
        prescricoes.add(PrescriptionModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_bio_${produto}',
          tipo: 'preventivo',
          categoria: 'biologico',
          produto: produto.toString(),
          dosagem: 'Conforme recomendação do fabricante',
          aplicacao: 'Aplicação direcionada',
          frequencia: 'Conforme ciclo do organismo',
          observacoes: 'Controle biológico sustentável',
          prioridade: 'media',
          dataPrescricao: DateTime.now(),
          status: 'pendente',
          dadosTecnicos: {
            'organismo': ponto.organismo,
            'coordenada': '${ponto.latitude},${ponto.longitude}',
            'fonte': 'JSON_${cultura}',
            'tipo': 'biologico',
          },
        ));
      }
    }
    
    return prescricoes;
  }

  /// Agrupa pontos por proximidade geográfica
  List<List<InfestationPoint>> _agruparPorProximidade(List<InfestationPoint> pontos) {
    final grupos = <List<InfestationPoint>>[];
    final processados = <String>{};
    
    for (final ponto in pontos) {
      if (processados.contains('${ponto.latitude},${ponto.longitude}')) continue;
      
      final grupo = [ponto];
      processados.add('${ponto.latitude},${ponto.longitude}');
      
      // Encontrar pontos próximos (dentro de 100m)
      for (final outroPonto in pontos) {
        if (outroPonto == ponto) continue;
        if (processados.contains('${outroPonto.latitude},${outroPonto.longitude}')) continue;
        
        final distancia = _calcularDistancia(
          ponto.latitude, ponto.longitude,
          outroPonto.latitude, outroPonto.longitude,
        );
        
        if (distancia < 0.001) { // ~100m
          grupo.add(outroPonto);
          processados.add('${outroPonto.latitude},${outroPonto.longitude}');
        }
      }
      
      grupos.add(grupo);
    }
    
    return grupos;
  }

  /// Calcula centro geográfico de um grupo
  Map<String, double> _calcularCentroGeografico(List<InfestationPoint> pontos) {
    final latMedia = pontos.fold<double>(0.0, (sum, p) => sum + p.latitude) / pontos.length;
    final lngMedia = pontos.fold<double>(0.0, (sum, p) => sum + p.longitude) / pontos.length;
    
    return {
      'latitude': latMedia,
      'longitude': lngMedia,
    };
  }

  /// Calcula distância entre dois pontos
  double _calcularDistancia(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // metros
    final dLat = (lat2 - lat1) * (3.14159265359 / 180);
    final dLng = (lng2 - lng1) * (3.14159265359 / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (3.14159265359 / 180)) * cos(lat2 * (3.14159265359 / 180)) *   
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  /// Obtém dosagem por produto
  String _obterDosagemPorProduto(String produto, String cultura) {
    final dosagens = {
      'Fipronil': '0.5 L/ha',
      'Clorantraniliprole': '0.2 L/ha',
      'Tiametoxam': '0.3 L/ha',
      'Lambda-cialotrina': '0.1 L/ha',
      'Azoxistrobina': '0.5 L/ha',
      'Ciproconazol': '0.3 L/ha',
    };
    
    return dosagens[produto] ?? 'Conforme bula do produto';
  }

  /// Obtém frequência por organismo
  String _obterFrequenciaPorOrganismo(Map<String, dynamic> organismoData) {
    final nivelAcao = organismoData['nivel_acao'] as String? ?? '';
    if (nivelAcao.contains('larvas')) return '7-10 dias';
    if (nivelAcao.contains('adultos')) return '10-14 dias';
    return '14 dias';
  }

  /// Calcula nível de risco com dados reais
  String _calcularNivelRiscoComDadosReais(List<InfestationPoint> pontos, Map<String, dynamic> analiseCoordenadas) {
    final pontosCriticos = pontos.where((p) => p.nivel == 'critico').length;
    final areaTotalAfetada = pontos.fold<double>(0.0, (sum, p) => sum + p.areaAfetada);
    final grupos = analiseCoordenadas['grupos'] as List<dynamic>? ?? [];
    
    if (pontosCriticos >= 3 || areaTotalAfetada >= 5.0 || grupos.length >= 3) return 'Alto';
    if (pontosCriticos >= 1 || areaTotalAfetada >= 2.0 || grupos.length >= 2) return 'Médio';
    return 'Baixo';
  }

  /// Calcula score de confiança
  double _calcularScoreConfianca(Map<String, dynamic> analiseCoordenadas, Map<String, dynamic> analiseOrganismos) {
    double score = 0.5; // Base
    
    // Pontos por coordenadas
    final grupos = analiseCoordenadas['grupos'] as List<dynamic>? ?? [];
    score += grupos.length * 0.1;
    
    // Organismos identificados
    final organismos = analiseOrganismos['organismos'] as List<dynamic>? ?? [];
    score += organismos.length * 0.05;
    
    return (score > 1.0 ? 1.0 : score);
  }

  /// Gera alertas inteligentes
  List<String> _gerarAlertasInteligentes(List<InfestationPoint> pontos, Map<String, dynamic> analiseCoordenadas) {
    final alertas = <String>[];
    
    final grupos = analiseCoordenadas['grupos'] as List<dynamic>? ?? [];
    if (grupos.length >= 3) {
      alertas.add('Múltiplos focos de infestação detectados');
    }
    
    final pontosCriticos = pontos.where((p) => p.nivel == 'critico').length;
    if (pontosCriticos > 0) {
      alertas.add('Pontos críticos requerem ação imediata');
    }
    
    return alertas;
  }
}
