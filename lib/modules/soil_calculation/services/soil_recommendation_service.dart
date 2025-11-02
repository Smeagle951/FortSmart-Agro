import 'package:flutter/material.dart';
import '../models/soil_diagnostic_model.dart';

/// Serviço para geração de recomendações agronômicas automáticas
class SoilRecommendationService {
  
  /// Gera recomendações baseadas no tipo de diagnóstico e severidade
  static List<String> gerarRecomendacoes({
    required String tipoDiagnostico,
    required String severidade,
    String? especieIdentificada,
    double? penetrometria,
  }) {
    switch (tipoDiagnostico) {
      case 'Compactação':
        return _recomendacoesCompactacao(severidade, penetrometria);
      
      case 'Nematoides':
        return _recomendacoesNematoides(severidade, especieIdentificada);
      
      case 'Cisto de Soja':
        return _recomendacoesCistoSoja(severidade);
      
      case 'Baixa Drenagem':
      case 'Encharcamento':
        return _recomendacoesDrenagem(severidade);
      
      case 'Baixa Matéria Orgânica':
        return _recomendacoesMateriaOrganica(severidade);
      
      case 'Crosta Superficial':
        return _recomendacoesCrostaSuperficial(severidade);
      
      case 'Baixa Atividade Biológica':
        return _recomendacoesAtividadeBiologica(severidade);
      
      default:
        return ['Consulte um agrônomo para análise detalhada.'];
    }
  }
  
  /// Recomendações para compactação do solo
  static List<String> _recomendacoesCompactacao(String severidade, double? penetrometria) {
    List<String> recomendacoes = [];
    
    if (penetrometria != null && penetrometria > 2.5) {
      recomendacoes.add(
        '🚜 **SUBSOLAGEM PRIORITÁRIA**: Realizar subsolagem na linha ou entrelinha com profundidade de 25-40 cm'
      );
      recomendacoes.add(
        '⚠️ Evitar tráfego de máquinas sob condições de alta umidade do solo'
      );
    }
    
    if (severidade == 'Alta' || severidade == 'Crítica') {
      recomendacoes.addAll([
        '🌱 Implementar sistema de plantio direto para reduzir compactação superficial',
        '🔧 Calibrar pressão dos pneus das máquinas agrícolas',
        '📊 Monitorar umidade do solo antes de operações de campo',
        '🌾 Estabelecer plantas de cobertura com sistema radicular agressivo (nabo forrageiro, crotalária)',
      ]);
    } else if (severidade == 'Moderado') {
      recomendacoes.addAll([
        '🌱 Manter cobertura vegetal permanente',
        '🔄 Rotação de culturas com espécies de raízes profundas',
        '📉 Reduzir intensidade de tráfego na área',
      ]);
    } else {
      recomendacoes.add(
        '✅ Solo em condição adequada. Manter práticas conservacionistas.'
      );
    }
    
    return recomendacoes;
  }
  
  /// Recomendações para nematoides
  static List<String> _recomendacoesNematoides(String severidade, String? especie) {
    List<String> recomendacoes = [];
    
    // Recomendações gerais
    recomendacoes.addAll([
      '🔬 **Identificação confirmada**: ${especie ?? "Realizar análise laboratorial para identificação precisa"}',
    ]);
    
    // Recomendações específicas por espécie
    if (especie?.contains('Pratylenchus') ?? false) {
      recomendacoes.addAll([
        '🌾 **Rotação de culturas**: Utilizar gramíneas (milheto, braquiária, sorgo)',
        '🦠 **Controle biológico**: Aplicar Bacillus subtilis ou Paecilomyces lilacinus',
        '🌱 **Plantas antagônicas**: Crotalária spectabilis ou mucuna preta',
      ]);
    } else if (especie?.contains('Meloidogyne') ?? false) {
      recomendacoes.addAll([
        '🌻 **Plantas antagonistas**: Crotalária spectabilis, milheto, sorgo',
        '♨️ **Solarização do solo**: Em áreas com alta infestação',
        '🧪 **Nematicidas biológicos**: Pochonia chlamydosporia',
      ]);
    } else if (especie?.contains('Heterodera') ?? false) {
      recomendacoes.addAll([
        '🚫 **Evitar cultivo de soja suscetível** por 2-3 anos',
        '🌽 **Rotação obrigatória**: Milho, sorgo, algodão ou pastagem',
        '🧬 **Cultivares resistentes**: Utilizar soja com gene de resistência',
      ]);
    }
    
    // Recomendações por severidade
    if (severidade == 'Alta' || severidade == 'Crítica') {
      recomendacoes.addAll([
        '⚠️ **ALERTA FITOSSANITÁRIO**: População acima do nível de dano econômico',
        '💰 Considerar uso de nematicidas químicos em casos críticos',
        '🗺️ Mapear área infestada e isolar para evitar disseminação',
      ]);
    }
    
    recomendacoes.add(
      '🧹 **Higienização**: Limpar máquinas e equipamentos para evitar disseminação'
    );
    
    return recomendacoes;
  }
  
  /// Recomendações para cisto de soja
  static List<String> _recomendacoesCistoSoja(String severidade) {
    return [
      '🚫 **Evitar cultivo de soja suscetível** na área por 2-3 safras',
      '🌽 **Rotação obrigatória**: Milho, sorgo, algodão, pastagem ou adubos verdes',
      '🧬 **Cultivares resistentes**: Utilizar soja com gene de resistência ao cisto (SCN)',
      '🌱 **Plantas armadilhas**: Crotalária spectabilis (reduz população)',
      '🗺️ **Mapeamento**: Delimitar área infestada e monitorar expansão',
      '🧹 **Higienização rigorosa**: Limpar máquinas antes de entrar em áreas sadias',
      '📊 **Análise nematológica**: Repetir análise após rotação para avaliar eficácia',
      if (severidade == 'Crítica')
        '⚠️ **População crítica**: Considerar deixar área em pousio por uma safra',
    ];
  }
  
  /// Recomendações para problemas de drenagem
  static List<String> _recomendacoesDrenagem(String severidade) {
    return [
      '💧 **Sistema de drenagem**: Implementar drenos subsuperficiais ou superficiais',
      '🏗️ **Terraços**: Construir ou reformar sistema de terraços',
      '🌾 **Canteiros**: Em áreas críticas, considerar cultivo em canteiros elevados',
      '🌱 **Plantas tolerantes**: Selecionar cultivares adaptadas a solos úmidos',
      '🔧 **Subsolagem**: Romper camadas compactadas que impedem drenagem',
      '📐 **Nivelamento**: Corrigir depressões que acumulam água',
      '🌿 **Cobertura vegetal**: Manter palhada para melhorar infiltração',
      if (severidade == 'Crítica')
        '⚠️ Considerar mudança de uso da área (pastagem, silvicultura)',
    ];
  }
  
  /// Recomendações para baixa matéria orgânica
  static List<String> _recomendacoesMateriaOrganica(String severidade) {
    return [
      '🌾 **Adubação verde**: Plantar crotalária, mucuna, feijão-de-porco',
      '♻️ **Compostagem**: Aplicar composto orgânico (2-5 t/ha)',
      '🌿 **Sistema de plantio direto**: Manter palhada sobre o solo',
      '🐄 **Esterco animal**: Incorporar esterco curtido quando disponível',
      '🔄 **Rotação de culturas**: Incluir gramíneas para maior aporte de carbono',
      '🚜 **Evitar revolvimento excessivo**: Reduzir oxidação da matéria orgânica',
      '🍂 **Resíduos culturais**: Manter restos de cultura sobre o solo',
      '🦠 **Inoculantes**: Aplicar fungos micorrízicos e bactérias fixadoras',
    ];
  }
  
  /// Recomendações para crosta superficial
  static List<String> _recomendacoesCrostaSuperficial(String severidade) {
    return [
      '🌱 **Plantas de cobertura**: Estabelecer cobertura vegetal permanente',
      '🌾 **Sistema radicular**: Utilizar espécies com raízes agressivas (nabo, aveia)',
      '🚜 **Reduzir preparo do solo**: Evitar pulverização excessiva',
      '♻️ **Matéria orgânica**: Aumentar teor de MO para melhorar agregação',
      '💧 **Manejo de irrigação**: Evitar irrigação com alta vazão que causa selamento',
      '🔧 **Gradagem leve**: Em casos severos, romper crosta antes do plantio',
      '🌿 **Palhada**: Manter cobertura morta para proteger superfície',
    ];
  }
  
  /// Recomendações para baixa atividade biológica
  static List<String> _recomendacoesAtividadeBiologica(String severidade) {
    return [
      '♻️ **Compostagem**: Aplicar composto para introduzir microrganismos',
      '🦠 **Inoculantes microbianos**: Bacillus, Trichoderma, micorrizas',
      '🌾 **Diversificação**: Rotação de culturas para estimular biodiversidade',
      '🚫 **Reduzir agroquímicos**: Minimizar uso de fungicidas e herbicidas',
      '🌿 **Cobertura permanente**: Manter solo sempre coberto',
      '💧 **Manejo da umidade**: Evitar extremos de seca ou encharcamento',
      '🍂 **Resíduos orgânicos**: Deixar restos culturais na superfície',
      '🌱 **Adubos verdes**: Plantar leguminosas para fixação de nitrogênio',
      '🐛 **Fauna do solo**: Preservar minhocas e outros organismos benéficos',
    ];
  }
  
  /// Retorna a cor correspondente ao nível de compactação
  static Color getCorPorNivel(String nivel) {
    switch (nivel) {
      case 'Solto':
        return const Color(0xFF4CAF50); // Verde
      case 'Moderado':
        return const Color(0xFFFFEB3B); // Amarelo
      case 'Alto':
        return const Color(0xFFFF9800); // Laranja
      case 'Crítico':
        return const Color(0xFFF44336); // Vermelho
      default:
        return const Color(0xFF9E9E9E); // Cinza
    }
  }
  
  /// Retorna o ícone correspondente ao tipo de diagnóstico
  static IconData getIconePorTipo(String tipo) {
    switch (tipo) {
      case 'Compactação':
        return Icons.compress;
      case 'Nematoides':
        return Icons.bug_report;
      case 'Cisto de Soja':
        return Icons.bubble_chart;
      case 'Baixa Drenagem':
      case 'Encharcamento':
        return Icons.water_damage;
      case 'Baixa Matéria Orgânica':
        return Icons.compost;
      case 'Crosta Superficial':
        return Icons.layers;
      case 'Baixa Atividade Biológica':
        return Icons.eco;
      default:
        return Icons.warning;
    }
  }
}

