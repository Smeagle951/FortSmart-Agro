/// 🚨 Service: Sistema de Alertas Fenológicos
/// 
/// Serviço inteligente para geração automática de alertas
/// baseado em desvios e problemas identificados.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import '../models/phenological_record_model.dart';
import '../models/phenological_alert_model.dart';
import 'growth_analysis_service.dart';
import 'productivity_estimation_service.dart';

class PhenologicalAlertService {
  /// Analisar registro e gerar alertas
  static List<PhenologicalAlertModel> analisarEGerarAlertas({
    required PhenologicalRecordModel registro,
    required String cultura,
    List<PhenologicalRecordModel>? historico,
  }) {
    final alertas = <PhenologicalAlertModel>[];

    // 1. Verificar crescimento
    final alertaCrescimento = _verificarCrescimento(
      registro: registro,
      cultura: cultura,
    );
    if (alertaCrescimento != null) alertas.add(alertaCrescimento);

    // 2. Verificar estande
    final alertaEstande = _verificarEstande(registro);
    if (alertaEstande != null) alertas.add(alertaEstande);

    // 3. Verificar sanidade
    final alertaSanidade = _verificarSanidade(registro);
    if (alertaSanidade != null) alertas.add(alertaSanidade);

    // 4. Verificar desenvolvimento reprodutivo
    final alertaReprodutivo = _verificarDesenvolvimentoReprodutivo(
      registro: registro,
      cultura: cultura,
    );
    if (alertaReprodutivo != null) alertas.add(alertaReprodutivo);

    // 5. Verificar sintomas nutricionais
    if (registro.sintomasObservados != null && 
        registro.sintomasObservados!.isNotEmpty) {
      final alertaNutricional = _verificarSintomas(registro);
      if (alertaNutricional != null) alertas.add(alertaNutricional);
    }

    return alertas;
  }

  /// Verificar crescimento em relação ao padrão
  static PhenologicalAlertModel? _verificarCrescimento({
    required PhenologicalRecordModel registro,
    required String cultura,
  }) {
    if (registro.alturaCm == null) return null;

    final desvio = GrowthAnalysisService.calcularDesvioAltura(
      alturaReal: registro.alturaCm!,
      cultura: cultura,
      diasAposEmergencia: registro.diasAposEmergencia,
    );

    if (desvio == null) return null;

    // Gerar alerta se desvio significativo
    if (desvio < -10) {
      AlertSeverity severidade;
      if (desvio < -30) {
        severidade = AlertSeverity.critica;
      } else if (desvio < -20) {
        severidade = AlertSeverity.alta;
      } else {
        severidade = AlertSeverity.media;
      }

      return PhenologicalAlertModel.novo(
        registroId: registro.id,
        talhaoId: registro.talhaoId,
        culturaId: registro.culturaId,
        tipo: AlertType.crescimento,
        severidade: severidade,
        titulo: 'Crescimento Abaixo do Esperado',
        descricao: 'A altura das plantas está ${desvio.abs().toStringAsFixed(1)}% '
                   'abaixo do padrão esperado para ${registro.diasAposEmergencia} DAE.',
        valorMedido: registro.alturaCm,
        valorEsperado: GrowthAnalysisService.calcularAlturaEsperada(
          cultura: cultura,
          diasAposEmergencia: registro.diasAposEmergencia,
        ),
        desvioPercentual: desvio,
        recomendacoes: [
          'Verificar disponibilidade hídrica',
          'Avaliar nutrição (especialmente N e P)',
          'Investigar compactação do solo',
          'Verificar ataque de pragas de solo',
        ],
      );
    }

    return null;
  }

  /// Verificar problemas no estande
  static PhenologicalAlertModel? _verificarEstande(
    PhenologicalRecordModel registro,
  ) {
    if (registro.percentualFalhas == null) return null;

    if (registro.percentualFalhas! > 10) {
      AlertSeverity severidade;
      if (registro.percentualFalhas! > 20) {
        severidade = AlertSeverity.critica;
      } else if (registro.percentualFalhas! > 15) {
        severidade = AlertSeverity.alta;
      } else {
        severidade = AlertSeverity.media;
      }

      return PhenologicalAlertModel.novo(
        registroId: registro.id,
        talhaoId: registro.talhaoId,
        culturaId: registro.culturaId,
        tipo: AlertType.estande,
        severidade: severidade,
        titulo: 'Falhas no Estande',
        descricao: 'Detectadas ${registro.percentualFalhas!.toStringAsFixed(1)}% '
                   'de falhas no estande. Isso pode impactar significativamente '
                   'a produtividade final.',
        valorMedido: registro.percentualFalhas,
        valorEsperado: 5.0, // Esperado < 5%
        desvioPercentual: registro.percentualFalhas! - 5.0,
        recomendacoes: [
          'Investigar causas: qualidade da semente, profundidade de plantio',
          'Avaliar necessidade de replantio em áreas críticas',
          'Considerar ajuste de espaçamento para compensação',
          'Documentar para análise pós-colheita',
        ],
      );
    }

    return null;
  }

  /// Verificar problemas de sanidade
  static PhenologicalAlertModel? _verificarSanidade(
    PhenologicalRecordModel registro,
  ) {
    // Verificar percentual de sanidade
    if (registro.percentualSanidade != null && 
        registro.percentualSanidade! < 80) {
      AlertSeverity severidade;
      if (registro.percentualSanidade! < 60) {
        severidade = AlertSeverity.critica;
      } else if (registro.percentualSanidade! < 70) {
        severidade = AlertSeverity.alta;
      } else {
        severidade = AlertSeverity.media;
      }

      return PhenologicalAlertModel.novo(
        registroId: registro.id,
        talhaoId: registro.talhaoId,
        culturaId: registro.culturaId,
        tipo: AlertType.sanidade,
        severidade: severidade,
        titulo: 'Problema Fitossanitário Detectado',
        descricao: 'Apenas ${registro.percentualSanidade!.toStringAsFixed(1)}% '
                   'das plantas estão sadias. '
                   '${registro.presencaPragas == true ? "Pragas detectadas. " : ""}'
                   '${registro.presencaDoencas == true ? "Doenças detectadas." : ""}',
        valorMedido: registro.percentualSanidade,
        valorEsperado: 90.0,
        desvioPercentual: registro.percentualSanidade! - 90.0,
        recomendacoes: [
          'Identificar pragas/doenças presentes',
          'Avaliar necessidade de aplicação de defensivos',
          'Verificar condições climáticas favoráveis a doenças',
          'Consultar agrônomo para recomendação específica',
        ],
      );
    }

    // Verificar presença de pragas/doenças
    if (registro.presencaPragas == true || registro.presencaDoencas == true) {
      return PhenologicalAlertModel.novo(
        registroId: registro.id,
        talhaoId: registro.talhaoId,
        culturaId: registro.culturaId,
        tipo: AlertType.sanidade,
        severidade: AlertSeverity.alta,
        titulo: registro.presencaPragas == true 
            ? 'Pragas Identificadas' 
            : 'Doenças Identificadas',
        descricao: registro.presencaPragas == true
            ? 'Presença de pragas detectada no talhão. Monitoramento necessário.'
            : 'Presença de doenças detectada no talhão. Intervenção pode ser necessária.',
        recomendacoes: [
          'Identificar espécie/patógeno',
          'Avaliar nível de dano econômico',
          'Definir estratégia de controle',
          'Monitorar evolução',
        ],
      );
    }

    return null;
  }

  /// Verificar desenvolvimento reprodutivo
  static PhenologicalAlertModel? _verificarDesenvolvimentoReprodutivo({
    required PhenologicalRecordModel registro,
    required String cultura,
  }) {
    // Verificar vagens/espigas por planta
    if (cultura.toLowerCase() == 'soja' || 
        cultura.toLowerCase() == 'feijao' || 
        cultura.toLowerCase() == 'feijão') {
      if (registro.vagensPlanta != null && registro.vagensPlanta! < 15) {
        final valoresMedios = ProductivityEstimationService.obterValoresMedios(cultura);
        final vagensEsperadas = valoresMedios['vagens'] as double?;

        if (vagensEsperadas != null) {
          final desvio = ((registro.vagensPlanta! - vagensEsperadas) / vagensEsperadas) * 100;

          if (desvio < -20) {
            return PhenologicalAlertModel.novo(
              registroId: registro.id,
              talhaoId: registro.talhaoId,
              culturaId: registro.culturaId,
              tipo: AlertType.reprodutivo,
              severidade: AlertSeverity.alta,
              titulo: 'Baixo Número de Vagens',
              descricao: 'Número de vagens por planta (${registro.vagensPlanta!.toStringAsFixed(1)}) '
                         'está ${desvio.abs().toStringAsFixed(1)}% abaixo do esperado.',
              valorMedido: registro.vagensPlanta,
              valorEsperado: vagensEsperadas,
              desvioPercentual: desvio,
              recomendacoes: [
                'Investigar se houve estresse durante floração',
                'Verificar polinização (presença de abelhas)',
                'Avaliar nutrição (B, Mo para leguminosas)',
                'Considerar aplicação de bioestimulantes',
              ],
            );
          }
        }
      }
    }

    return null;
  }

  /// Verificar sintomas visuais
  static PhenologicalAlertModel? _verificarSintomas(
    PhenologicalRecordModel registro,
  ) {
    final sintomas = registro.sintomasObservados!.toLowerCase();
    
    // Identificar possíveis deficiências
    if (sintomas.contains('amarelamento') || sintomas.contains('clorose')) {
      return PhenologicalAlertModel.novo(
        registroId: registro.id,
        talhaoId: registro.talhaoId,
        culturaId: registro.culturaId,
        tipo: AlertType.nutricional,
        severidade: AlertSeverity.media,
        titulo: 'Possível Deficiência Nutricional',
        descricao: 'Sintomas de amarelamento/clorose detectados. '
                   'Pode indicar deficiência de Nitrogênio, Ferro ou Magnésio.',
        recomendacoes: [
          'Realizar análise foliar',
          'Verificar pH do solo',
          'Avaliar adubação realizada',
          'Considerar aplicação foliar emergencial',
        ],
      );
    }

    if (sintomas.contains('necrose') || sintomas.contains('queima')) {
      return PhenologicalAlertModel.novo(
        registroId: registro.id,
        talhaoId: registro.talhaoId,
        culturaId: registro.culturaId,
        tipo: AlertType.nutricional,
        severidade: AlertSeverity.alta,
        titulo: 'Sintomas de Necrose Detectados',
        descricao: 'Sintomas de necrose/queima nas folhas. '
                   'Pode indicar deficiência de Potássio, fitotoxidez ou doença.',
        recomendacoes: [
          'Identificar padrão de sintomas (folhas velhas ou novas)',
          'Verificar aplicações recentes de defensivos',
          'Avaliar possível deficiência de K',
          'Descartar doenças foliares',
        ],
      );
    }

    return null;
  }

  /// Priorizar alertas por severidade
  static List<PhenologicalAlertModel> priorizarAlertas(
    List<PhenologicalAlertModel> alertas,
  ) {
    final ordenados = List<PhenologicalAlertModel>.from(alertas);
    
    ordenados.sort((a, b) {
      // Ordenar por severidade (crítica > alta > média > baixa)
      final severidadeA = _getSeveridadeValue(a.severidade);
      final severidadeB = _getSeveridadeValue(b.severidade);
      
      if (severidadeA != severidadeB) {
        return severidadeB.compareTo(severidadeA);
      }
      
      // Se mesma severidade, ordenar por data (mais recente primeiro)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return ordenados;
  }

  static int _getSeveridadeValue(AlertSeverity severidade) {
    switch (severidade) {
      case AlertSeverity.critica:
        return 4;
      case AlertSeverity.alta:
        return 3;
      case AlertSeverity.media:
        return 2;
      case AlertSeverity.baixa:
        return 1;
    }
  }

  /// Agrupar alertas por tipo
  static Map<AlertType, List<PhenologicalAlertModel>> agruparPorTipo(
    List<PhenologicalAlertModel> alertas,
  ) {
    final agrupados = <AlertType, List<PhenologicalAlertModel>>{};
    
    for (final alerta in alertas) {
      if (!agrupados.containsKey(alerta.tipo)) {
        agrupados[alerta.tipo] = [];
      }
      agrupados[alerta.tipo]!.add(alerta);
    }
    
    return agrupados;
  }

  /// Resumo de alertas
  static Map<String, dynamic> gerarResumo(
    List<PhenologicalAlertModel> alertas,
  ) {
    final ativos = alertas.where((a) => a.status == AlertStatus.ativo).toList();
    
    return {
      'total': alertas.length,
      'ativos': ativos.length,
      'criticos': ativos.where((a) => a.severidade == AlertSeverity.critica).length,
      'altos': ativos.where((a) => a.severidade == AlertSeverity.alta).length,
      'medios': ativos.where((a) => a.severidade == AlertSeverity.media).length,
      'baixos': ativos.where((a) => a.severidade == AlertSeverity.baixa).length,
      'porTipo': agruparPorTipo(ativos).map(
        (key, value) => MapEntry(key.toString(), value.length),
      ),
    };
  }
}

