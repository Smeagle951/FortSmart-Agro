/// 🎯 Service: Estimativa de Produtividade
/// 
/// Serviço para cálculo dinâmico de estimativa de
/// produtividade baseado em componentes de rendimento.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import '../models/phenological_record_model.dart';

class ProductivityEstimationService {
  /// Estimar produtividade (kg/ha) baseado nos componentes
  static double? estimarProdutividade({
    required String cultura,
    required double? estandePlantas,
    required double? componentePrincipal, // vagens/planta ou espigas/planta
    double? graosVagem,
    double? pesoMedioGrao,
  }) {
    if (estandePlantas == null || componentePrincipal == null) {
      return null;
    }

    switch (cultura.toLowerCase()) {
      case 'soja':
        return _estimarProdutividadeSoja(
          estandePlantas: estandePlantas,
          vagensPlanta: componentePrincipal,
          graosVagem: graosVagem ?? 2.5, // Média soja
          pesoMedioGrao: pesoMedioGrao ?? 0.15, // 150mg
        );
      
      case 'milho':
        return _estimarProdutividadeMilho(
          estandePlantas: estandePlantas,
          espigasPlanta: componentePrincipal,
          graosEspiga: graosVagem ?? 400.0, // Média milho
          pesoMedioGrao: pesoMedioGrao ?? 0.35, // 350mg
        );
      
      case 'feijao':
      case 'feijão':
        return _estimarProdutividadeFeijao(
          estandePlantas: estandePlantas,
          vagensPlanta: componentePrincipal,
          graosVagem: graosVagem ?? 5.0, // Média feijão
          pesoMedioGrao: pesoMedioGrao ?? 0.25, // 250mg
        );
      
      default:
        return null;
    }
  }

  /// Estimativa de produtividade para SOJA
  static double _estimarProdutividadeSoja({
    required double estandePlantas,
    required double vagensPlanta,
    required double graosVagem,
    required double pesoMedioGrao,
  }) {
    // Fórmula: Estande × Vagens/planta × Grãos/vagem × Peso grão (g) ÷ 1000
    final produtividadeKgHa = (
      estandePlantas *
      vagensPlanta *
      graosVagem *
      pesoMedioGrao
    ) / 1000;

    return produtividadeKgHa;
  }

  /// Estimativa de produtividade para MILHO
  static double _estimarProdutividadeMilho({
    required double estandePlantas,
    required double espigasPlanta,
    required double graosEspiga,
    required double pesoMedioGrao,
  }) {
    // Fórmula: Estande × Espigas/planta × Grãos/espiga × Peso grão (g) ÷ 1000
    final produtividadeKgHa = (
      estandePlantas *
      espigasPlanta *
      graosEspiga *
      pesoMedioGrao
    ) / 1000;

    return produtividadeKgHa;
  }

  /// Estimativa de produtividade para FEIJÃO
  static double _estimarProdutividadeFeijao({
    required double estandePlantas,
    required double vagensPlanta,
    required double graosVagem,
    required double pesoMedioGrao,
  }) {
    // Fórmula: Estande × Vagens/planta × Grãos/vagem × Peso grão (g) ÷ 1000
    final produtividadeKgHa = (
      estandePlantas *
      vagensPlanta *
      graosVagem *
      pesoMedioGrao
    ) / 1000;

    return produtividadeKgHa;
  }

  /// Calcular produtividade esperada (baseado em padrões)
  static double? calcularProdutividadeEsperada(String cultura) {
    switch (cultura.toLowerCase()) {
      case 'soja':
        return 3500.0; // kg/ha (média Brasil)
      case 'milho':
        return 6000.0; // kg/ha (média Brasil)
      case 'feijao':
      case 'feijão':
        return 1800.0; // kg/ha (média Brasil)
      case 'algodao':
      case 'algodão':
        return 4500.0; // kg/ha de pluma (média Brasil)
      case 'sorgo':
        return 3200.0; // kg/ha (média Brasil)
      case 'gergelim':
        return 1200.0; // kg/ha (média Brasil)
      case 'cana':
      case 'cana-de-açucar':
      case 'cana-de-acucar':
      case 'cana de açúcar':
      case 'cana de acucar':
        return 75000.0; // kg/ha (75 t/ha média Brasil)
      case 'tomate':
        return 60000.0; // kg/ha (60 t/ha média Brasil)
      case 'trigo':
        return 2800.0; // kg/ha (média Brasil)
      case 'aveia':
        return 2500.0; // kg/ha (média Brasil)
      case 'girassol':
        return 2000.0; // kg/ha (média Brasil)
      case 'arroz':
        return 6500.0; // kg/ha (média Brasil)
      default:
        return null;
    }
  }

  /// Calcular gap de produtividade
  static Map<String, dynamic>? calcularGapProdutividade({
    required String cultura,
    required double produtividadeEstimada,
  }) {
    final produtividadeEsperada = calcularProdutividadeEsperada(cultura);
    if (produtividadeEsperada == null) return null;

    final gap = produtividadeEstimada - produtividadeEsperada;
    final gapPercentual = (gap / produtividadeEsperada) * 100;

    String status;
    String recomendacao;

    if (gapPercentual >= 10) {
      status = 'Acima do esperado';
      recomendacao = 'Manter práticas atuais. Excelente manejo!';
    } else if (gapPercentual >= -10) {
      status = 'Dentro do esperado';
      recomendacao = 'Produtividade adequada. Considerar melhorias pontuais.';
    } else if (gapPercentual >= -25) {
      status = 'Abaixo do esperado';
      recomendacao = 'Revisar manejo: nutrição, sanidade e densidade de plantio.';
    } else {
      status = 'Crítico';
      recomendacao = 'Ação urgente necessária. Investigar causas de baixa produtividade.';
    }

    return {
      'produtividadeEstimada': produtividadeEstimada,
      'produtividadeEsperada': produtividadeEsperada,
      'gap': gap,
      'gapPercentual': gapPercentual,
      'status': status,
      'recomendacao': recomendacao,
    };
  }

  /// Estimar produtividade a partir do último registro
  static Map<String, dynamic>? estimarProdutividadeAtual({
    required String cultura,
    required PhenologicalRecordModel ultimoRegistro,
  }) {
    double? componentePrincipal;
    double? graosComponente;
    double? pesoGrao;

    // Determinar componente principal por cultura
    switch (cultura.toLowerCase()) {
      case 'soja':
      case 'feijao':
      case 'feijão':
        componentePrincipal = ultimoRegistro.vagensPlanta;
        graosComponente = ultimoRegistro.graosVagem;
        pesoGrao = cultura.toLowerCase() == 'soja' ? 0.15 : 0.25;
        break;
      
      case 'milho':
        componentePrincipal = ultimoRegistro.espigasPlanta;
        graosComponente = ultimoRegistro.graosVagem; // Reutilizando campo
        pesoGrao = 0.35;
        break;
    }

    final produtividade = estimarProdutividade(
      cultura: cultura,
      estandePlantas: ultimoRegistro.estandePlantas,
      componentePrincipal: componentePrincipal,
      graosVagem: graosComponente,
      pesoMedioGrao: pesoGrao,
    );

    if (produtividade == null) return null;

    // Calcular gap
    final analiseGap = calcularGapProdutividade(
      cultura: cultura,
      produtividadeEstimada: produtividade,
    );

    return {
      'produtividade': produtividade,
      'sacas60kg': produtividade / 60, // Conversão para sacas
      'estandeUtilizado': ultimoRegistro.estandePlantas,
      'componenteUtilizado': componentePrincipal,
      'dataEstimativa': ultimoRegistro.dataRegistro,
      'analiseGap': analiseGap,
    };
  }

  /// Simular impacto de mudanças nos componentes
  static Map<String, double> simularImpactos({
    required String cultura,
    required double estandeBase,
    required double componenteBase,
    double? graosVagem,
    double? pesoGrao,
  }) {
    final resultados = <String, double>{};

    // Produtividade base
    final prodBase = estimarProdutividade(
      cultura: cultura,
      estandePlantas: estandeBase,
      componentePrincipal: componenteBase,
      graosVagem: graosVagem,
      pesoMedioGrao: pesoGrao,
    );

    if (prodBase == null) return resultados;
    resultados['base'] = prodBase;

    // Simular aumento de 10% no estande
    final prodEstande10 = estimarProdutividade(
      cultura: cultura,
      estandePlantas: estandeBase * 1.1,
      componentePrincipal: componenteBase,
      graosVagem: graosVagem,
      pesoMedioGrao: pesoGrao,
    );
    if (prodEstande10 != null) {
      resultados['estande+10%'] = prodEstande10;
    }

    // Simular aumento de 10% em vagens/espigas
    final prodComponente10 = estimarProdutividade(
      cultura: cultura,
      estandePlantas: estandeBase,
      componentePrincipal: componenteBase * 1.1,
      graosVagem: graosVagem,
      pesoMedioGrao: pesoGrao,
    );
    if (prodComponente10 != null) {
      resultados['componente+10%'] = prodComponente10;
    }

    // Simular aumento de 10% no peso do grão
    if (pesoGrao != null) {
      final prodPeso10 = estimarProdutividade(
        cultura: cultura,
        estandePlantas: estandeBase,
        componentePrincipal: componenteBase,
        graosVagem: graosVagem,
        pesoMedioGrao: pesoGrao * 1.1,
      );
      if (prodPeso10 != null) {
        resultados['pesoGrao+10%'] = prodPeso10;
      }
    }

    return resultados;
  }

  /// Obter valores médios de componentes por cultura (referência)
  static Map<String, dynamic> obterValoresMedios(String cultura) {
    switch (cultura.toLowerCase()) {
      case 'soja':
        return {
          'estande': 280000.0, // plantas/ha
          'vagens': 40.0, // vagens/planta
          'graos': 2.5, // grãos/vagem
          'peso': 0.15, // g/grão (150mg)
        };
      
      case 'milho':
        return {
          'estande': 70000.0, // plantas/ha
          'espigas': 1.0, // espigas/planta
          'graos': 450.0, // grãos/espiga
          'peso': 0.35, // g/grão (350mg)
        };
      
      case 'feijao':
      case 'feijão':
        return {
          'estande': 220000.0, // plantas/ha
          'vagens': 12.0, // vagens/planta
          'graos': 5.0, // grãos/vagem
          'peso': 0.25, // g/grão (250mg)
        };
      
      case 'algodao':
      case 'algodão':
        return {
          'estande': 100000.0, // plantas/ha
          'capulhos': 35.0, // capulhos/planta
          'peso': 5.5, // g/capulho (pluma)
        };
      
      case 'sorgo':
        return {
          'estande': 160000.0, // plantas/ha
          'paniculas': 1.0, // panículas/planta
          'graos': 1800.0, // grãos/panícula
          'peso': 0.025, // g/grão (25mg)
        };
      
      case 'gergelim':
        return {
          'estande': 200000.0, // plantas/ha
          'capsulas': 80.0, // cápsulas/planta
          'graos': 70.0, // sementes/cápsula
          'peso': 0.003, // g/semente (3mg)
        };
      
      case 'cana':
      case 'cana-de-açucar':
      case 'cana-de-acucar':
      case 'cana de açúcar':
      case 'cana de acucar':
        return {
          'colmos': 12.0, // colmos/metro
          'peso': 1.2, // kg/colmo
        };
      
      case 'tomate':
        return {
          'estande': 25000.0, // plantas/ha
          'pencas': 8.0, // pencas/planta
          'frutos': 5.0, // frutos/penca
          'peso': 150.0, // g/fruto
        };
      
      case 'trigo':
        return {
          'estande': 400000.0, // plantas/ha (afilhos)
          'espigas': 1.0, // espiga/afilho
          'graos': 35.0, // grãos/espiga
          'peso': 0.040, // g/grão (40mg)
        };
      
      case 'aveia':
        return {
          'estande': 350000.0, // plantas/ha (afilhos)
          'paniculas': 1.0, // panícula/afilho
          'graos': 40.0, // grãos/panícula
          'peso': 0.035, // g/grão (35mg)
        };
      
      case 'girassol':
        return {
          'estande': 50000.0, // plantas/ha
          'capitulos': 1.0, // capítulo/planta
          'aquenios': 900.0, // aquênios/capítulo
          'peso': 0.055, // g/aquênio (55mg)
        };
      
      case 'arroz':
        return {
          'estande': 300000.0, // plantas/ha (perfilhos)
          'paniculas': 1.0, // panícula/perfilho
          'graos': 110.0, // grãos/panícula
          'peso': 0.025, // g/grão (25mg)
        };
      
      default:
        return {};
    }
  }

  /// Converter kg/ha para sacas de 60kg
  static double converterParaSacas(double kgHa) {
    return kgHa / 60.0;
  }

  /// Converter sacas para kg/ha
  static double converterParaKg(double sacas) {
    return sacas * 60.0;
  }
}

