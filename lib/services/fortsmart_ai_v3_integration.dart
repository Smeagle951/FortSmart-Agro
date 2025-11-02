import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/organism_catalog_v3.dart';
import '../utils/logger.dart';

/// Serviço de integração IA FortSmart com dados v3.0
/// Usa os novos campos para cálculos inteligentes de risco
class FortSmartAIV3Integration {
  static const String _basePath = 'assets/data';
  
  /// Calcula risco climático baseado em condições_climaticas do organismo v3.0
  static double calcularRiscoClimatico({
    required OrganismCatalogV3 organismo,
    required double temperaturaAtual,
    required double umidadeAtual,
  }) {
    if (organismo.climaticConditions == null) {
      Logger.warning('⚠️ Organismo sem condições climáticas: ${organismo.name}');
      return 0.5; // Risco médio padrão
    }
    
    final condicoes = organismo.climaticConditions!;
    double risco = 0.0;
    
    // Verificar temperatura (peso 0.4)
    if (condicoes.minTemperature != null && condicoes.maxTemperature != null) {
      if (temperaturaAtual >= condicoes.minTemperature! && 
          temperaturaAtual <= condicoes.maxTemperature!) {
        risco += 0.4; // Temperatura ideal
      } else if (temperaturaAtual >= condicoes.minTemperature! - 3 && 
                 temperaturaAtual <= condicoes.maxTemperature! + 3) {
        risco += 0.2; // Próximo do ideal
      }
    }
    
    // Verificar umidade (peso 0.4)
    if (condicoes.minHumidity != null && condicoes.maxHumidity != null) {
      if (umidadeAtual >= condicoes.minHumidity! && 
          umidadeAtual <= condicoes.maxHumidity!) {
        risco += 0.4; // Umidade ideal
      } else if (umidadeAtual >= condicoes.minHumidity! - 10 && 
                 umidadeAtual <= condicoes.maxHumidity! + 10) {
        risco += 0.2; // Próximo do ideal
      }
    }
    
    // Sazonalidade (peso 0.2)
    if (organismo.seasonalTrends != null) {
      final mesAtual = DateTime.now().month;
      final mesesPico = organismo.seasonalTrends!.peakMonths;
      
      final mesesPicoNumeros = <int>[];
      for (var mes in mesesPico) {
        switch (mes.toLowerCase()) {
          case 'janeiro': mesesPicoNumeros.add(1); break;
          case 'fevereiro': mesesPicoNumeros.add(2); break;
          case 'março': mesesPicoNumeros.add(3); break;
          case 'abril': mesesPicoNumeros.add(4); break;
          case 'maio': mesesPicoNumeros.add(5); break;
          case 'junho': mesesPicoNumeros.add(6); break;
          case 'julho': mesesPicoNumeros.add(7); break;
          case 'agosto': mesesPicoNumeros.add(8); break;
          case 'setembro': mesesPicoNumeros.add(9); break;
          case 'outubro': mesesPicoNumeros.add(10); break;
          case 'novembro': mesesPicoNumeros.add(11); break;
          case 'dezembro': mesesPicoNumeros.add(12); break;
        }
      }
      
      if (mesesPicoNumeros.contains(mesAtual)) {
        risco += 0.2;
      }
    }
    
    return risco.clamp(0.0, 1.0);
  }
  
  /// Gera alerta climático automático
  static Map<String, dynamic> gerarAlertaClimatico({
    required OrganismCatalogV3 organismo,
    required double temperaturaAtual,
    required double umidadeAtual,
    required String cultura,
  }) {
    final risco = calcularRiscoClimatico(
      organismo: organismo,
      temperaturaAtual: temperaturaAtual,
      umidadeAtual: umidadeAtual,
    );
    
    String nivel = 'Baixo';
    String cor = '#4CAF50';
    
    if (risco >= 0.7) {
      nivel = 'Alto';
      cor = '#F44336';
    } else if (risco >= 0.4) {
      nivel = 'Médio';
      cor = '#FF9800';
    }
    
    return {
      'organismo': organismo.name,
      'risco': risco,
      'nivel': nivel,
      'cor': cor,
      'temperatura_atual': temperaturaAtual,
      'umidade_atual': umidadeAtual,
      'recomendacao': _gerarRecomendacaoClimatica(risco, organismo),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Calcula ROI de controle baseado em economia_agronomica
  static Map<String, dynamic> calcularROIControle({
    required OrganismCatalogV3 organismo,
    required double areaHa,
  }) {
    if (organismo.agronomicEconomics == null) {
      return {
        'roi': 2.0, // ROI padrão
        'custo_controle': areaHa * 60.0,
        'custo_nao_controle': areaHa * 180.0,
        'economia': areaHa * 120.0,
      };
    }
    
    final economiaData = organismo.agronomicEconomics!;
    final custoControle = (economiaData.costControlPerHa ?? 60.0) * areaHa;
    final custoNaoControle = (economiaData.costNoControlPerHa ?? 180.0) * areaHa;
    final economiaTotal = custoNaoControle - custoControle;
    final roi = economiaTotal / custoControle;
    
    return {
      'roi': roi,
      'custo_controle': custoControle,
      'custo_nao_controle': custoNaoControle,
      'economia': economiaTotal,
      'momento_otimo': economiaData.optimalApplicationTime ?? 'Início da infestação',
    };
  }
  
  /// Usa features_ia para buscar organismos similares
  static List<String> buscarOrganismosSimilares({
    required OrganismCatalogV3 organismo,
    required List<OrganismCatalogV3> todosOrganismos,
  }) {
    if (organismo.iaFeatures == null) return [];
    
    final keywords = organismo.iaFeatures!.behavioralKeywords;
    final similares = <String>[];
    
    for (var org in todosOrganismos) {
      if (org.id == organismo.id) continue;
      
      if (org.iaFeatures != null) {
        final keywordsOutro = org.iaFeatures!.behavioralKeywords;
        
        // Contar keywords em comum
        int comum = 0;
        for (var keyword in keywords) {
          if (keywordsOutro.contains(keyword)) {
            comum++;
          }
        }
        
        // Se tiver pelo menos 2 keywords em comum, é similar
        if (comum >= 2) {
          similares.add(org.name);
        }
      }
    }
    
    return similares;
  }
  
  /// Analisa risco de resistência baseado em rotacao_resistencia
  static Map<String, dynamic> analisarRiscoResistencia({
    required OrganismCatalogV3 organismo,
    required List<String> produtosUsados, // Lista de produtos IRAC usados recentemente
  }) {
    if (organismo.resistanceRotation == null) {
      return {
        'risco': 0.0,
        'recomendacao': 'Sem dados de resistência disponíveis',
      };
    }
    
    final rotacao = organismo.resistanceRotation!;
    final gruposProblema = <String>[];
    
    for (var produto in produtosUsados) {
      // Extrair grupo IRAC do nome do produto (exemplo simplificado)
      for (var grupoIrac in rotacao.iracGroups) {
        if (produto.toLowerCase().contains('irac $grupoIrac') ||
            produto.toLowerCase().contains('grupo $grupoIrac')) {
          gruposProblema.add(grupoIrac);
        }
      }
    }
    
    double risco = gruposProblema.length * 0.3;
    
    return {
      'risco': risco.clamp(0.0, 1.0),
      'grupos_usados': gruposProblema,
      'estrategias': rotacao.strategies,
      'intervalo_minimo': rotacao.minimumIntervalDays ?? 14,
      'recomendacao': gruposProblema.isEmpty
        ? 'Nenhum risco detectado'
        : '⚠️ Evitar produtos dos grupos: ${gruposProblema.join(", ")}',
    };
  }
  
  /// Gera recomendação climática
  static String _gerarRecomendacaoClimatica(
    double risco,
    OrganismCatalogV3 organismo,
  ) {
    if (risco >= 0.7) {
      return '⚠️ ALTO RISCO: Condições climáticas favoráveis detectadas. '
             'Intensificar monitoramento e preparar controle preventivo.';
    } else if (risco >= 0.4) {
      return '⚠️ RISCO MODERADO: Condições parcialmente favoráveis. '
             'Manter monitoramento regular.';
    } else {
      return '✅ RISCO BAIXO: Condições climáticas não favoráveis no momento. '
             'Manter monitoramento de rotina.';
    }
  }
  
  /// Carrega organismo v3.0 do JSON
  static Future<OrganismCatalogV3?> carregarOrganismoV3({
    required String cultura,
    required String organismoId,
  }) async {
    try {
      final culturaMap = {
        'soja': 'soja',
        'milho': 'milho',
        'algodao': 'algodao',
        'feijao': 'feijao',
        'trigo': 'trigo',
        'arroz': 'arroz',
        'aveia': 'aveia',
        'girassol': 'girassol',
        'sorgo': 'sorgo',
        'cana_acucar': 'cana_acucar',
        'gergelim': 'gergelim',
        'tomate': 'tomate',
        'batata': 'batata',
      };
      
      final culturaNormalizada = culturaMap[cultura.toLowerCase()] ?? cultura.toLowerCase();
      final filePath = '$_basePath/organismos_$culturaNormalizada.json';
      
      Logger.info('📂 Carregando organismo v3.0: $filePath');
      
      final jsonString = await rootBundle.loadString(filePath);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final organismos = data['organismos'] as List<dynamic>? ?? [];
      
      // Buscar organismo por ID
      final orgJson = organismos.firstWhere(
        (org) => org['id'] == organismoId,
        orElse: () => null,
      );
      
      if (orgJson == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismoId');
        return null;
      }
      
      return OrganismCatalogV3.fromJson(
        orgJson as Map<String, dynamic>,
        cropId: culturaNormalizada,
        cropName: data['cultura']?.toString() ?? cultura,
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao carregar organismo v3.0: $e');
      return null;
    }
  }
}

