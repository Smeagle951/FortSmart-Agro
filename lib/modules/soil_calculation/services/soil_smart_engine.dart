import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/soil_compaction_point_model.dart';
import '../models/soil_diagnostic_model.dart';
import '../models/soil_laboratory_sample_model.dart';

/// SoilSmart Engine - Núcleo inteligente de diagnóstico, previsão e recomendação agronômica
class SoilSmartEngine {
  
  /// Análise cruzada completa: compactação + química + física
  static Map<String, dynamic> analiseCruzadaCompleta({
    required SoilCompactionPointModel ponto,
    SoilLaboratorySampleModel? amostraQuimica,
    List<SoilDiagnosticModel>? diagnosticos,
  }) {
    final Map<String, dynamic> resultado = {
      'ponto_id': ponto.id,
      'ponto_codigo': ponto.pointCode,
      'data_analise': DateTime.now().toIso8601String(),
      'diagnosticos_principais': <String>[],
      'diagnosticos_secundarios': <String>[],
      'causas_identificadas': <String>[],
      'recomendacoes_prioritarias': <String>[],
      'recomendacoes_secundarias': <String>[],
      'nivel_criticidade': 'Baixo',
      'score_risco': 0.0,
      'proximos_passos': <String>[],
    };

    // 1. Análise de compactação
    _analisarCompactacao(ponto, resultado);
    
    // 2. Análise química (se disponível)
    if (amostraQuimica != null) {
      _analisarQuimica(amostraQuimica, resultado);
    }
    
    // 3. Análise cruzada compactação + química
    if (amostraQuimica != null) {
      _analiseCruzadaCompactacaoQuimica(ponto, amostraQuimica, resultado);
    }
    
    // 4. Análise de diagnósticos existentes
    if (diagnosticos != null && diagnosticos.isNotEmpty) {
      _analisarDiagnosticos(diagnosticos, resultado);
    }
    
    // 5. Cálculo do score de risco
    _calcularScoreRisco(resultado);
    
    // 6. Geração de recomendações inteligentes
    _gerarRecomendacoesInteligentes(resultado);
    
    return resultado;
  }

  /// Análise específica de compactação
  static void _analisarCompactacao(SoilCompactionPointModel ponto, Map<String, dynamic> resultado) {
    if (ponto.penetrometria == null) return;
    
    final penetrometria = ponto.penetrometria!;
    final List<String> diagnosticos = resultado['diagnosticos_principais'] as List<String>;
    final List<String> causas = resultado['causas_identificadas'] as List<String>;
    
    if (penetrometria > 2.5) {
      diagnosticos.add('Compactação Crítica');
      causas.add('Tráfego de máquinas sob alta umidade');
      causas.add('Preparo inadequado do solo');
      resultado['nivel_criticidade'] = 'Crítico';
    } else if (penetrometria > 2.0) {
      diagnosticos.add('Compactação Alta');
      causas.add('Pressão excessiva de pneus');
      resultado['nivel_criticidade'] = 'Alto';
    } else if (penetrometria > 1.5) {
      diagnosticos.add('Compactação Moderada');
      resultado['nivel_criticidade'] = 'Moderado';
    }
    
    // Análise por textura
    if (ponto.textura == 'Argiloso' && penetrometria > 2.0) {
      diagnosticos.add('Compactação em Solo Argiloso');
      causas.add('Solo argiloso suscetível à compactação');
    }
  }

  /// Análise química do solo
  static void _analisarQuimica(SoilLaboratorySampleModel amostra, Map<String, dynamic> resultado) {
    final List<String> diagnosticos = resultado['diagnosticos_principais'] as List<String>;
    final List<String> causas = resultado['causas_identificadas'] as List<String>;
    
    // pH
    if (amostra.ph != null) {
      if (amostra.ph! < 5.0) {
        diagnosticos.add('Acidez Extrema');
        causas.add('Deficiência de calcário');
      } else if (amostra.ph! < 5.5) {
        diagnosticos.add('Acidez Moderada');
        causas.add('Necessidade de calagem');
      } else if (amostra.ph! > 7.5) {
        diagnosticos.add('Alcalinidade');
        causas.add('Excesso de calcário ou sódio');
      }
    }
    
    // Matéria Orgânica
    if (amostra.materiaOrganica != null) {
      if (amostra.materiaOrganica! < 1.0) {
        diagnosticos.add('Muito Baixa Matéria Orgânica');
        causas.add('Falta de cobertura vegetal');
        causas.add('Revolvimento excessivo');
      } else if (amostra.materiaOrganica! < 2.0) {
        diagnosticos.add('Baixa Matéria Orgânica');
        causas.add('Manejo inadequado da palhada');
      }
    }
    
    // CTC
    if (amostra.ctc != null) {
      if (amostra.ctc! < 3.0) {
        diagnosticos.add('CTC Muito Baixa');
        causas.add('Solo arenoso ou baixa matéria orgânica');
      } else if (amostra.ctc! < 5.0) {
        diagnosticos.add('CTC Baixa');
        causas.add('Necessidade de melhorar estrutura');
      }
    }
    
    // Fósforo
    if (amostra.fosforo != null && amostra.fosforo! < 10.0) {
      diagnosticos.add('Deficiência de Fósforo');
      causas.add('Fosfato indisponível por fixação');
    }
    
    // Potássio
    if (amostra.potassio != null && amostra.potassio! < 80.0) {
      diagnosticos.add('Deficiência de Potássio');
      causas.add('Baixa fertilização potássica');
    }
  }

  /// Análise cruzada: compactação + química
  static void _analiseCruzadaCompactacaoQuimica(
    SoilCompactionPointModel ponto,
    SoilLaboratorySampleModel amostra,
    Map<String, dynamic> resultado,
  ) {
    final List<String> diagnosticos = resultado['diagnosticos_principais'] as List<String>;
    final List<String> causas = resultado['causas_identificadas'] as List<String>;
    
    // Compactação + pH baixo + Ca baixo = Compactação Química
    if (ponto.penetrometria != null && ponto.penetrometria! > 2.0 &&
        amostra.ph != null && amostra.ph! < 5.5 &&
        amostra.calcio != null && amostra.calcio! < 2.0) {
      diagnosticos.add('Compactação Química');
      causas.add('Deficiência de cálcio e pH baixo');
      resultado['nivel_criticidade'] = 'Crítico';
    }
    
    // Compactação + Baixa MO = Compactação Física
    if (ponto.penetrometria != null && ponto.penetrometria! > 2.0 &&
        amostra.materiaOrganica != null && amostra.materiaOrganica! < 2.0) {
      diagnosticos.add('Compactação Física');
      causas.add('Baixa matéria orgânica e tráfego excessivo');
    }
    
    // Solo argiloso + pH baixo + compactação = Problema Estrutural
    if (ponto.textura == 'Argiloso' &&
        ponto.penetrometria != null && ponto.penetrometria! > 2.0 &&
        amostra.ph != null && amostra.ph! < 5.5) {
      diagnosticos.add('Problema Estrutural Complexo');
      causas.add('Solo argiloso ácido e compactado');
    }
    
    // CTC baixa + compactação = Solo Degradado
    if (ponto.penetrometria != null && ponto.penetrometria! > 2.0 &&
        amostra.ctc != null && amostra.ctc! < 3.0) {
      diagnosticos.add('Solo Degradado');
      causas.add('Baixa capacidade de troca e compactação');
    }
  }

  /// Análise de diagnósticos existentes
  static void _analisarDiagnosticos(List<SoilDiagnosticModel> diagnosticos, Map<String, dynamic> resultado) {
    final List<String> diagnosticosSecundarios = resultado['diagnosticos_secundarios'] as List<String>;
    
    for (var diagnostico in diagnosticos) {
      if (diagnostico.severidade == 'Alta' || diagnostico.severidade == 'Crítica') {
        diagnosticosSecundarios.add('${diagnostico.tipoDiagnostico} (${diagnostico.severidade})');
      }
    }
  }

  /// Cálculo do score de risco (0-100)
  static void _calcularScoreRisco(Map<String, dynamic> resultado) {
    double score = 0.0;
    
    // Compactação
    final diagnosticos = resultado['diagnosticos_principais'] as List<String>;
    if (diagnosticos.contains('Compactação Crítica')) score += 40;
    else if (diagnosticos.contains('Compactação Alta')) score += 25;
    else if (diagnosticos.contains('Compactação Moderada')) score += 15;
    
    // Problemas químicos
    if (diagnosticos.contains('Acidez Extrema')) score += 30;
    else if (diagnosticos.contains('Acidez Moderada')) score += 15;
    
    if (diagnosticos.contains('Muito Baixa Matéria Orgânica')) score += 25;
    else if (diagnosticos.contains('Baixa Matéria Orgânica')) score += 10;
    
    if (diagnosticos.contains('CTC Muito Baixa')) score += 20;
    else if (diagnosticos.contains('CTC Baixa')) score += 10;
    
    // Problemas complexos
    if (diagnosticos.contains('Compactação Química')) score += 35;
    if (diagnosticos.contains('Problema Estrutural Complexo')) score += 30;
    if (diagnosticos.contains('Solo Degradado')) score += 25;
    
    resultado['score_risco'] = min(score, 100.0);
    
    // Atualiza criticidade baseada no score
    if (score >= 70) resultado['nivel_criticidade'] = 'Crítico';
    else if (score >= 50) resultado['nivel_criticidade'] = 'Alto';
    else if (score >= 30) resultado['nivel_criticidade'] = 'Moderado';
    else resultado['nivel_criticidade'] = 'Baixo';
  }

  /// Geração de recomendações inteligentes
  static void _gerarRecomendacoesInteligentes(Map<String, dynamic> resultado) {
    final List<String> prioritarias = resultado['recomendacoes_prioritarias'] as List<String>;
    final List<String> secundarias = resultado['recomendacoes_secundarias'] as List<String>;
    final List<String> proximosPassos = resultado['proximos_passos'] as List<String>;
    final List<String> diagnosticos = resultado['diagnosticos_principais'] as List<String>;
    final String criticidade = resultado['nivel_criticidade'] as String;
    
    // Recomendações por criticidade
    if (criticidade == 'Crítico') {
      prioritarias.add('🚨 INTERVENÇÃO URGENTE: Subsolagem profunda (40-50 cm)');
      prioritarias.add('🧪 Análise completa do solo (química + física)');
      prioritarias.add('📋 Plano de recuperação estruturado');
    } else if (criticidade == 'Alto') {
      prioritarias.add('⚠️ Subsolagem recomendada (25-40 cm)');
      prioritarias.add('🌱 Implementar plantas de cobertura');
      prioritarias.add('📊 Monitoramento mensal');
    }
    
    // Recomendações específicas por diagnóstico
    if (diagnosticos.contains('Compactação Química')) {
      prioritarias.add('💊 Calagem urgente (2-3 t/ha)');
      prioritarias.add('🔬 Análise de saturação por bases');
      secundarias.add('🌾 Gesso agrícola para subsuperfície');
    }
    
    if (diagnosticos.contains('Compactação Física')) {
      prioritarias.add('🌿 Adubação verde intensiva');
      prioritarias.add('♻️ Compostagem (5-10 t/ha)');
      secundarias.add('🚜 Reduzir tráfego de máquinas');
    }
    
    if (diagnosticos.contains('Problema Estrutural Complexo')) {
      prioritarias.add('🏗️ Recuperação estrutural em etapas');
      prioritarias.add('📅 Rotação com gramíneas por 2 anos');
      secundarias.add('💧 Sistema de drenagem');
    }
    
    if (diagnosticos.contains('Solo Degradado')) {
      prioritarias.add('🔄 Reconstrução do perfil do solo');
      prioritarias.add('🌱 Plantio direto com alta palhada');
      secundarias.add('📈 Monitoramento de CTC');
    }
    
    // Próximos passos
    proximosPassos.add('📸 Documentar área com fotos');
    proximosPassos.add('📝 Registrar observações detalhadas');
    proximosPassos.add('🗓️ Agendar próxima avaliação em 30 dias');
    
    if (criticidade == 'Crítico' || criticidade == 'Alto') {
      proximosPassos.add('👨‍🌾 Consultar agrônomo especialista');
      proximosPassos.add('💰 Orçar custos de recuperação');
    }
  }

  /// Predição de problemas futuros
  static Map<String, dynamic> predizerProblemasFuturos({
    required List<SoilCompactionPointModel> pontos,
    List<SoilLaboratorySampleModel>? amostras,
  }) {
    final Map<String, dynamic> predicao = {
      'risco_geral': 'Baixo',
      'probabilidade_problemas': <String, double>{},
      'areas_criticas': <String>[],
      'recomendacoes_preventivas': <String>[],
    };

    if (pontos.isEmpty) return predicao;

    // Análise de tendência de compactação
    final pontosComMedicao = pontos.where((p) => p.penetrometria != null).toList();
    if (pontosComMedicao.length >= 3) {
      final media = pontosComMedicao.fold(0.0, (sum, p) => sum + p.penetrometria!) / pontosComMedicao.length;
      
      if (media > 2.5) {
        predicao['risco_geral'] = 'Crítico';
        predicao['probabilidade_problemas']['compactacao_aumento'] = 0.9;
      } else if (media > 2.0) {
        predicao['risco_geral'] = 'Alto';
        predicao['probabilidade_problemas']['compactacao_aumento'] = 0.7;
      } else if (media > 1.5) {
        predicao['risco_geral'] = 'Moderado';
        predicao['probabilidade_problemas']['compactacao_aumento'] = 0.5;
      }
    }

    // Análise de amostras químicas
    if (amostras != null && amostras.isNotEmpty) {
      final amostraMedia = amostras.first; // Simplificado
      
      if (amostraMedia.ph != null && amostraMedia.ph! < 5.5) {
        predicao['probabilidade_problemas']['acidificacao'] = 0.8;
      }
      
      if (amostraMedia.materiaOrganica != null && amostraMedia.materiaOrganica! < 2.0) {
        predicao['probabilidade_problemas']['degradacao_estrutural'] = 0.6;
      }
    }

    // Recomendações preventivas
    if (predicao['risco_geral'] == 'Crítico') {
      predicao['recomendacoes_preventivas'].addAll([
        '🚨 Intervenção imediata obrigatória',
        '📊 Monitoramento semanal',
        '👨‍🌾 Consultoria especializada',
      ]);
    } else if (predicao['risco_geral'] == 'Alto') {
      predicao['recomendacoes_preventivas'].addAll([
        '⚠️ Ação preventiva recomendada',
        '📈 Monitoramento mensal',
        '🌱 Práticas conservacionistas',
      ]);
    }

    return predicao;
  }

  /// Geração de relatório inteligente
  static Map<String, dynamic> gerarRelatorioInteligente({
    required List<SoilCompactionPointModel> pontos,
    List<SoilLaboratorySampleModel>? amostras,
    List<SoilDiagnosticModel>? diagnosticos,
  }) {
    final Map<String, dynamic> relatorio = {
      'resumo_executivo': <String, dynamic>{},
      'analises_detalhadas': <Map<String, dynamic>>[],
      'recomendacoes_consolidadas': <String>[],
      'cronograma_acoes': <Map<String, dynamic>>[],
      'indicadores_monitoramento': <String, dynamic>{},
    };

    // Análise de cada ponto
    for (var ponto in pontos) {
      final amostraPonto = amostras?.where((a) => a.pointId == ponto.id).firstOrNull;
      final diagnosticosPonto = diagnosticos?.where((d) => d.pointId == ponto.id).toList();
      
      final analise = analiseCruzadaCompleta(
        ponto: ponto,
        amostraQuimica: amostraPonto,
        diagnosticos: diagnosticosPonto,
      );
      
      relatorio['analises_detalhadas'].add(analise);
    }

    // Consolidação de recomendações
    final todasRecomendacoes = <String>[];
    for (var analise in relatorio['analises_detalhadas']) {
      todasRecomendacoes.addAll(analise['recomendacoes_prioritarias'] as List<String>);
    }
    
    relatorio['recomendacoes_consolidadas'] = todasRecomendacoes.toSet().toList();

    // Cronograma de ações
    relatorio['cronograma_acoes'] = _gerarCronogramaAcoes(relatorio['analises_detalhadas']);

    return relatorio;
  }

  /// Geração de cronograma de ações
  static List<Map<String, dynamic>> _gerarCronogramaAcoes(List<dynamic> analises) {
    final cronograma = <Map<String, dynamic>>[];
    
    // Ações imediatas (0-7 dias)
    cronograma.add({
      'periodo': 'Imediato (0-7 dias)',
      'acoes': [
        'Documentar área com fotos',
        'Registrar observações detalhadas',
        'Identificar pontos críticos no mapa',
      ],
    });
    
    // Ações de curto prazo (1-4 semanas)
    cronograma.add({
      'periodo': 'Curto Prazo (1-4 semanas)',
      'acoes': [
        'Realizar subsolagem em áreas críticas',
        'Aplicar calagem se necessário',
        'Implementar plantas de cobertura',
      ],
    });
    
    // Ações de médio prazo (1-6 meses)
    cronograma.add({
      'periodo': 'Médio Prazo (1-6 meses)',
      'acoes': [
        'Monitorar evolução da compactação',
        'Ajustar práticas de manejo',
        'Avaliar eficácia das intervenções',
      ],
    });
    
    return cronograma;
  }
}
