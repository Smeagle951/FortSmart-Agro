/// 📈 Service: Análise de Crescimento
/// 
/// Serviço para análise de curvas de crescimento,
/// comparação com padrões e detecção de desvios.
/// 
/// Autor: FortSmart Agro
/// Data: Outubro 2025

import 'dart:math';
import '../models/phenological_record_model.dart';

class GrowthAnalysisService {
  /// Calcular taxa de crescimento (cm/dia)
  static double? calcularTaxaCrescimento(
    List<PhenologicalRecordModel> registros,
  ) {
    if (registros.length < 2) return null;
    
    // Filtrar registros com altura
    final registrosComAltura = registros
        .where((r) => r.alturaCm != null)
        .toList()
      ..sort((a, b) => a.dataRegistro.compareTo(b.dataRegistro));
    
    if (registrosComAltura.length < 2) return null;
    
    final primeiro = registrosComAltura.first;
    final ultimo = registrosComAltura.last;
    
    final diferencaAltura = ultimo.alturaCm! - primeiro.alturaCm!;
    final diferencaDias = ultimo.dataRegistro.difference(primeiro.dataRegistro).inDays;
    
    if (diferencaDias == 0) return null;
    
    return diferencaAltura / diferencaDias;
  }

  /// Calcular altura esperada para um DAE específico
  static double? calcularAlturaEsperada({
    required String cultura,
    required int diasAposEmergencia,
  }) {
    final padroes = _getPadroesCrescimento(cultura);
    if (padroes == null) return null;
    
    // Interpolação linear entre pontos de referência
    for (int i = 0; i < padroes.length - 1; i++) {
      final atual = padroes[i];
      final proximo = padroes[i + 1];
      
      if (diasAposEmergencia >= atual['dae'] && 
          diasAposEmergencia <= proximo['dae']) {
        final t = (diasAposEmergencia - atual['dae']) / 
                  (proximo['dae'] - atual['dae']);
        return atual['altura'] + t * (proximo['altura'] - atual['altura']);
      }
    }
    
    return null;
  }

  /// Calcular desvio percentual em relação ao padrão
  static double? calcularDesvioAltura({
    required double alturaReal,
    required String cultura,
    required int diasAposEmergencia,
  }) {
    final alturaEsperada = calcularAlturaEsperada(
      cultura: cultura,
      diasAposEmergencia: diasAposEmergencia,
    );
    
    if (alturaEsperada == null || alturaEsperada == 0) return null;
    
    return ((alturaReal - alturaEsperada) / alturaEsperada) * 100;
  }

  /// Padrões de crescimento por cultura (dados de referência)
  static List<Map<String, dynamic>>? _getPadroesCrescimento(String cultura) {
    switch (cultura.toLowerCase()) {
      case 'soja':
        return [
          {'dae': 10, 'altura': 15.0},
          {'dae': 20, 'altura': 30.0},
          {'dae': 30, 'altura': 50.0},
          {'dae': 40, 'altura': 70.0},
          {'dae': 50, 'altura': 85.0},
          {'dae': 60, 'altura': 95.0},
          {'dae': 70, 'altura': 100.0},
        ];
      
      case 'milho':
        return [
          {'dae': 10, 'altura': 20.0},
          {'dae': 20, 'altura': 50.0},
          {'dae': 30, 'altura': 90.0},
          {'dae': 40, 'altura': 140.0},
          {'dae': 50, 'altura': 190.0},
          {'dae': 60, 'altura': 230.0},
          {'dae': 70, 'altura': 250.0},
        ];
      
      case 'feijao':
      case 'feijão':
        return [
          {'dae': 10, 'altura': 12.0},
          {'dae': 20, 'altura': 25.0},
          {'dae': 30, 'altura': 40.0},
          {'dae': 40, 'altura': 55.0},
          {'dae': 50, 'altura': 60.0},
          {'dae': 60, 'altura': 62.0},
        ];
      
      case 'algodao':
      case 'algodão':
        return [
          {'dae': 15, 'altura': 15.0},
          {'dae': 30, 'altura': 35.0},
          {'dae': 45, 'altura': 60.0},
          {'dae': 60, 'altura': 85.0},
          {'dae': 90, 'altura': 110.0},
          {'dae': 120, 'altura': 130.0},
        ];
      
      case 'sorgo':
        return [
          {'dae': 10, 'altura': 18.0},
          {'dae': 20, 'altura': 45.0},
          {'dae': 30, 'altura': 80.0},
          {'dae': 40, 'altura': 120.0},
          {'dae': 50, 'altura': 160.0},
          {'dae': 60, 'altura': 200.0},
          {'dae': 70, 'altura': 220.0},
        ];
      
      case 'gergelim':
        return [
          {'dae': 10, 'altura': 12.0},
          {'dae': 20, 'altura': 30.0},
          {'dae': 30, 'altura': 55.0},
          {'dae': 40, 'altura': 80.0},
          {'dae': 50, 'altura': 105.0},
          {'dae': 60, 'altura': 130.0},
          {'dae': 80, 'altura': 150.0},
        ];
      
      case 'cana':
      case 'cana-de-açucar':
      case 'cana-de-acucar':
      case 'cana de açúcar':
      case 'cana de acucar':
        return [
          {'dae': 30, 'altura': 30.0},
          {'dae': 60, 'altura': 60.0},
          {'dae': 90, 'altura': 100.0},
          {'dae': 120, 'altura': 150.0},
          {'dae': 180, 'altura': 220.0},
          {'dae': 240, 'altura': 280.0},
          {'dae': 300, 'altura': 320.0},
        ];
      
      case 'tomate':
        return [
          {'dae': 15, 'altura': 20.0},
          {'dae': 30, 'altura': 40.0},
          {'dae': 45, 'altura': 70.0},
          {'dae': 60, 'altura': 100.0},
          {'dae': 75, 'altura': 130.0},
          {'dae': 90, 'altura': 150.0},
        ];
      
      case 'trigo':
        return [
          {'dae': 15, 'altura': 12.0},
          {'dae': 30, 'altura': 25.0},
          {'dae': 45, 'altura': 45.0},
          {'dae': 60, 'altura': 65.0},
          {'dae': 75, 'altura': 85.0},
          {'dae': 90, 'altura': 95.0},
          {'dae': 110, 'altura': 100.0},
        ];
      
      case 'aveia':
        return [
          {'dae': 15, 'altura': 15.0},
          {'dae': 30, 'altura': 30.0},
          {'dae': 45, 'altura': 50.0},
          {'dae': 60, 'altura': 70.0},
          {'dae': 80, 'altura': 90.0},
          {'dae': 100, 'altura': 105.0},
          {'dae': 120, 'altura': 110.0},
        ];
      
      case 'girassol':
        return [
          {'dae': 10, 'altura': 15.0},
          {'dae': 20, 'altura': 35.0},
          {'dae': 30, 'altura': 60.0},
          {'dae': 40, 'altura': 90.0},
          {'dae': 50, 'altura': 120.0},
          {'dae': 60, 'altura': 150.0},
          {'dae': 80, 'altura': 180.0},
          {'dae': 100, 'altura': 190.0},
        ];
      
      case 'arroz':
        return [
          {'dae': 15, 'altura': 20.0},
          {'dae': 30, 'altura': 40.0},
          {'dae': 45, 'altura': 60.0},
          {'dae': 60, 'altura': 75.0},
          {'dae': 80, 'altura': 90.0},
          {'dae': 100, 'altura': 100.0},
          {'dae': 120, 'altura': 105.0},
        ];
      
      default:
        return null;
    }
  }

  /// Calcular crescimento médio diário (cm/dia)
  /// Fórmula: (Altura_atual - Altura_anterior) / Dias
  static double? calcularCrescimentoMedioDiario(
    List<PhenologicalRecordModel> registros,
  ) {
    if (registros.length < 2) return null;
    
    // Filtrar registros com altura e ordenar por data
    final registrosComAltura = registros
        .where((r) => r.alturaCm != null)
        .toList()
      ..sort((a, b) => a.dataRegistro.compareTo(b.dataRegistro));
    
    if (registrosComAltura.length < 2) return null;
    
    final primeiro = registrosComAltura.first;
    final ultimo = registrosComAltura.last;
    
    final diferencaAltura = ultimo.alturaCm! - primeiro.alturaCm!;
    final diferencaDias = ultimo.dataRegistro.difference(primeiro.dataRegistro).inDays;
    
    if (diferencaDias == 0) return null;
    
    return diferencaAltura / diferencaDias;
  }

  /// Calcular espaçamento médio entre nós (cm)
  /// Fórmula: Altura / Nº de nós
  /// Interpretação: Índice de estiolamento (quanto maior, mais estiolada)
  static double? calcularEspacamentoEntreNos({
    required double? alturaCm,
    required int? numeroNos,
  }) {
    if (alturaCm == null || numeroNos == null || numeroNos == 0) {
      return null;
    }
    
    return alturaCm / numeroNos;
  }

  /// Calcular relação vagens/nó (eficiência reprodutiva)
  /// Fórmula: Nº de vagens / Nº de nós
  /// Interpretação: Eficiência reprodutiva (quanto maior, melhor)
  static double? calcularRelacaoVagensNo({
    required double? vagensPlanta,
    required int? numeroNos,
  }) {
    if (vagensPlanta == null || numeroNos == null || numeroNos == 0) {
      return null;
    }
    
    return vagensPlanta / numeroNos;
  }

  /// Calcular desvio fenológico (%)
  /// Fórmula: (Valor observado / Valor esperado) × 100
  /// Interpretação: Grau de atraso ou avanço
  static double? calcularDesvioFenologico({
    required double? valorObservado,
    required double? valorEsperado,
  }) {
    if (valorObservado == null || valorEsperado == null || valorEsperado == 0) {
      return null;
    }
    
    return ((valorObservado - valorEsperado) / valorEsperado) * 100;
  }

  /// Analisar eficiência reprodutiva (algodão)
  /// Baseado na relação ramos reprodutivos / ramos vegetativos
  static String analisarEficienciaReprodutiva({
    required int? ramosVegetativos,
    required int? ramosReprodutivos,
  }) {
    if (ramosVegetativos == null || ramosReprodutivos == null) {
      return 'Dados insuficientes';
    }
    
    if (ramosVegetativos == 0) {
      return '⚠️ Planta sem desenvolvimento vegetativo adequado';
    }
    
    final relacao = ramosReprodutivos / ramosVegetativos;
    
    if (relacao > 2.0) {
      return '✅ Excelente eficiência reprodutiva (${relacao.toStringAsFixed(2)}:1)';
    } else if (relacao > 1.5) {
      return '✅ Boa eficiência reprodutiva (${relacao.toStringAsFixed(2)}:1)';
    } else if (relacao > 1.0) {
      return '⚠️ Eficiência reprodutiva moderada (${relacao.toStringAsFixed(2)}:1)';
    } else {
      return '🚨 Baixa eficiência reprodutiva (${relacao.toStringAsFixed(2)}:1)';
    }
  }

  /// Analisar índice de estiolamento
  /// Baseado no espaçamento entre nós
  static String analisarEstiolamento({
    required double? espacamentoEntreNosCm,
    required String cultura,
  }) {
    if (espacamentoEntreNosCm == null) {
      return 'Dados insuficientes';
    }
    
    // Valores de referência por cultura
    final Map<String, double> limiteNormal = {
      'soja': 6.0,
      'feijao': 5.5,
      'feijão': 5.5,
      'milho': 15.0,
      'sorgo': 12.0,
      'trigo': 8.0,
      'algodao': 8.0,
      'algodão': 8.0,
    };
    
    final limite = limiteNormal[cultura.toLowerCase()] ?? 8.0;
    
    if (espacamentoEntreNosCm < limite * 0.8) {
      return '✅ Crescimento compacto (${espacamentoEntreNosCm.toStringAsFixed(1)} cm/nó)';
    } else if (espacamentoEntreNosCm < limite * 1.2) {
      return '✅ Crescimento normal (${espacamentoEntreNosCm.toStringAsFixed(1)} cm/nó)';
    } else if (espacamentoEntreNosCm < limite * 1.5) {
      return '⚠️ Início de estiolamento (${espacamentoEntreNosCm.toStringAsFixed(1)} cm/nó)';
    } else {
      return '🚨 Estiolamento crítico (${espacamentoEntreNosCm.toStringAsFixed(1)} cm/nó) - verificar sombreamento, déficit hídrico ou deficiência nutricional';
    }
  }

  /// Analisar tendência de crescimento
  static String analisarTendencia(List<PhenologicalRecordModel> registros) {
    if (registros.length < 3) {
      return 'Dados insuficientes para análise de tendência';
    }
    
    // Ordenar por data
    final ordenados = List<PhenologicalRecordModel>.from(registros)
      ..sort((a, b) => a.dataRegistro.compareTo(b.dataRegistro));
    
    // Filtrar registros com altura
    final comAltura = ordenados.where((r) => r.alturaCm != null).toList();
    
    if (comAltura.length < 3) {
      return 'Dados insuficientes para análise de tendência';
    }
    
    // Calcular incrementos
    final incrementos = <double>[];
    for (int i = 1; i < comAltura.length; i++) {
      final incremento = comAltura[i].alturaCm! - comAltura[i - 1].alturaCm!;
      incrementos.add(incremento);
    }
    
    // Média dos incrementos
    final mediaIncremento = incrementos.reduce((a, b) => a + b) / incrementos.length;
    
    // Análise
    if (mediaIncremento > 5) {
      return '📈 Crescimento acelerado (${mediaIncremento.toStringAsFixed(1)} cm entre registros)';
    } else if (mediaIncremento > 2) {
      return '✅ Crescimento normal (${mediaIncremento.toStringAsFixed(1)} cm entre registros)';
    } else if (mediaIncremento > 0) {
      return '⚠️ Crescimento lento (${mediaIncremento.toStringAsFixed(1)} cm entre registros)';
    } else {
      return '🚨 Crescimento estagnado ou negativo';
    }
  }

  /// Prever altura futura (regressão linear simples)
  static double? preverAltura({
    required List<PhenologicalRecordModel> registros,
    required int daeAlvo,
  }) {
    final comAltura = registros
        .where((r) => r.alturaCm != null)
        .toList();
    
    if (comAltura.length < 2) return null;
    
    // Preparar dados para regressão
    final x = comAltura.map((r) => r.diasAposEmergencia.toDouble()).toList();
    final y = comAltura.map((r) => r.alturaCm!).toList();
    
    // Calcular regressão linear: y = a + bx
    final n = x.length;
    final somaX = x.reduce((a, b) => a + b);
    final somaY = y.reduce((a, b) => a + b);
    final somaXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final somaX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    
    final b = (n * somaXY - somaX * somaY) / (n * somaX2 - somaX * somaX);
    final a = (somaY - b * somaX) / n;
    
    // Prever altura para DAE alvo
    return a + b * daeAlvo;
  }

  /// Calcular coeficiente de variação (CV%) da altura
  static double? calcularCVAltura(List<PhenologicalRecordModel> registros) {
    final alturas = registros
        .where((r) => r.alturaCm != null)
        .map((r) => r.alturaCm!)
        .toList();
    
    if (alturas.length < 2) return null;
    
    final media = alturas.reduce((a, b) => a + b) / alturas.length;
    final variancia = alturas
        .map((v) => pow(v - media, 2))
        .reduce((a, b) => a + b) / alturas.length;
    final desvio = sqrt(variancia);
    
    return (desvio / media) * 100;
  }

  /// Detectar outliers (valores anormais)
  static List<String> detectarOutliers(List<PhenologicalRecordModel> registros) {
    final outliers = <String>[];
    
    if (registros.length < 3) return outliers;
    
    final alturas = registros
        .where((r) => r.alturaCm != null)
        .map((r) => r.alturaCm!)
        .toList();
    
    if (alturas.length < 3) return outliers;
    
    // Calcular média e desvio padrão
    final media = alturas.reduce((a, b) => a + b) / alturas.length;
    final variancia = alturas
        .map((v) => pow(v - media, 2))
        .reduce((a, b) => a + b) / alturas.length;
    final desvio = sqrt(variancia);
    
    // Detectar outliers (> 2 desvios padrão)
    for (final registro in registros) {
      if (registro.alturaCm != null) {
        final z = (registro.alturaCm! - media) / desvio;
        if (z.abs() > 2) {
          outliers.add(
            '${registro.dataRegistro.day}/${registro.dataRegistro.month}: '
            '${registro.alturaCm!.toStringAsFixed(1)} cm (${z > 0 ? '+' : ''}${z.toStringAsFixed(1)}σ)'
          );
        }
      }
    }
    
    return outliers;
  }

  /// Análise de sanidade ao longo do tempo
  static Map<String, dynamic> analisarSanidade(
    List<PhenologicalRecordModel> registros,
  ) {
    final comSanidade = registros
        .where((r) => r.percentualSanidade != null)
        .toList()
      ..sort((a, b) => a.dataRegistro.compareTo(b.dataRegistro));
    
    if (comSanidade.isEmpty) {
      return {
        'status': 'Sem dados de sanidade',
        'tendencia': null,
        'mediaAtual': null,
      };
    }
    
    // Média dos últimos 3 registros
    final ultimos = comSanidade.length >= 3 
        ? comSanidade.sublist(comSanidade.length - 3)
        : comSanidade;
    
    final mediaAtual = ultimos
        .map((r) => r.percentualSanidade!)
        .reduce((a, b) => a + b) / ultimos.length;
    
    // Tendência
    String tendencia;
    if (comSanidade.length >= 2) {
      final penultimo = comSanidade[comSanidade.length - 2].percentualSanidade!;
      final ultimo = comSanidade.last.percentualSanidade!;
      
      if (ultimo > penultimo + 5) {
        tendencia = 'Melhora';
      } else if (ultimo < penultimo - 5) {
        tendencia = 'Piora';
      } else {
        tendencia = 'Estável';
      }
    } else {
      tendencia = 'Indeterminada';
    }
    
    // Status
    String status;
    if (mediaAtual >= 90) {
      status = 'Excelente';
    } else if (mediaAtual >= 80) {
      status = 'Bom';
    } else if (mediaAtual >= 70) {
      status = 'Regular';
    } else {
      status = 'Crítico';
    }
    
    return {
      'status': status,
      'tendencia': tendencia,
      'mediaAtual': mediaAtual,
      'registros': comSanidade.length,
    };
  }

  /// Calcular incremento médio de vagens por período
  static double? calcularIncrementoVagens(
    List<PhenologicalRecordModel> registros,
  ) {
    final comVagens = registros
        .where((r) => r.vagensPlanta != null && r.vagensPlanta! > 0)
        .toList()
      ..sort((a, b) => a.dataRegistro.compareTo(b.dataRegistro));
    
    if (comVagens.length < 2) return null;
    
    final primeiro = comVagens.first;
    final ultimo = comVagens.last;
    
    final diferencaVagens = ultimo.vagensPlanta! - primeiro.vagensPlanta!;
    final diferencaDias = ultimo.dataRegistro.difference(primeiro.dataRegistro).inDays;
    
    if (diferencaDias == 0) return null;
    
    return diferencaVagens / diferencaDias;
  }
}

