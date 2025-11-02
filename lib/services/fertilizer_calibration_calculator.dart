import 'dart:math';

/// Resultado da calibração de fertilizantes
class ResultadoCalibracao {
  final double taxaRealKgHa;
  final double erroPercent;
  final double mediaG;
  final double desvioG;
  final double cvPercent;
  final double? faixaEfetivaM;

  ResultadoCalibracao({
    required this.taxaRealKgHa,
    required this.erroPercent,
    required this.mediaG,
    required this.desvioG,
    required this.cvPercent,
    this.faixaEfetivaM,
  });
}

/// Calculadora de calibração de fertilizantes
/// Implementa o método correto baseado no Guia Técnico FortSmart
class CalibracaoFertilizantesCalculator {
  
  /// Calcula a calibração usando o método correto
  static ResultadoCalibracao calcular({
    // Entradas de cálculo (OBRIGATÓRIAS)
    required List<double> massasBandejaG, // g - Massa coletada por bandeja
    required double distanciaPercorridaM, // m - Distância percorrida durante coleta
    required double larguraBandejaM,      // m - Largura de cada bandeja (ex.: 0.20)
    required double taxaDesejadaKgHa,     // kg/ha - Taxa desejada

    // Diagnóstico (não entram na taxa)
    double? faixaEsperadaM,
    double? paletaPmm,
    double? paletaGmm,
    int? rpm,
    double? densidade_gL,
    double? velocidadeKmh,
  }) {
    // ======= Validações obrigatórias
    if (distanciaPercorridaM <= 0) {
      throw ArgumentError('Distância percorrida deve ser > 0 m.');
    }
    if (larguraBandejaM <= 0) {
      throw ArgumentError('Largura da bandeja deve ser > 0 m.');
    }
    if (massasBandejaG.isEmpty) {
      throw ArgumentError('Informe as massas das bandejas (g).');
    }
    if (taxaDesejadaKgHa <= 0) {
      throw ArgumentError('Taxa desejada deve ser > 0 kg/ha.');
    }

    // ======= Estatística básica (desvio amostral n-1)
    final n = massasBandejaG.length;
    final soma = massasBandejaG.fold<double>(0, (a, b) => a + b);
    final media = soma / n;

    // Calcular desvio padrão amostral (n-1)
    double varianciaAmostral = 0;
    if (n > 1) {
      final sq = massasBandejaG
          .map((v) => (v - media) * (v - media))
          .fold<double>(0, (a, b) => a + b);
      varianciaAmostral = sq / (n - 1);
    }
    final desvio = varianciaAmostral > 0 ? sqrt(varianciaAmostral) : 0.0;
    final cv = media > 0 ? (desvio / media) * 100.0 : 0.0;

    // ======= Taxa real (kg/ha) - FÓRMULA CORRETA
    // Área amostrada = (N * larguraBandejaM) * distanciaPercorridaM
    // Conversão g → kg/ha (fator 10)
    final taxaRealKgHa =
        (soma * 10.0) / (n * larguraBandejaM * distanciaPercorridaM);

    // ======= Erro percentual
    final erroPercent = ((taxaRealKgHa - taxaDesejadaKgHa) / taxaDesejadaKgHa) * 100.0;

    // ======= Faixa efetiva para exibição (opcional)
    final faixaEfetivaM = faixaEsperadaM; // exibir se houver

    return ResultadoCalibracao(
      taxaRealKgHa: taxaRealKgHa.isFinite ? taxaRealKgHa : 0,
      erroPercent: erroPercent.isFinite ? erroPercent : 0,
      mediaG: media.isFinite ? media : 0,
      desvioG: desvio.isFinite ? desvio : 0,
      cvPercent: cv.isFinite ? cv : 0,
      faixaEfetivaM: faixaEfetivaM,
    );
  }

  /// Valida se os dados de entrada são consistentes
  static List<String> validarDados({
    required List<double> massasBandejaG,
    required double distanciaPercorridaM,
    required double larguraBandejaM,
    required double taxaDesejadaKgHa,
  }) {
    final erros = <String>[];

    // Validações básicas
    if (distanciaPercorridaM <= 0) {
      erros.add('Distância percorrida deve ser maior que zero');
    }
    if (larguraBandejaM <= 0) {
      erros.add('Largura da bandeja deve ser maior que zero');
    }
    if (massasBandejaG.isEmpty) {
      erros.add('Informe as massas das bandejas');
    }
    if (taxaDesejadaKgHa <= 0) {
      erros.add('Taxa desejada deve ser maior que zero');
    }

    // Validações de consistência
    if (massasBandejaG.isNotEmpty && distanciaPercorridaM > 0) {
      final soma = massasBandejaG.fold<double>(0, (a, b) => a + b);
      
      if (soma < 1.0 && distanciaPercorridaM > 50.0) {
        erros.add('Massa total muito baixa para o percurso. Considere reduzir a distância para 10-20m');
      }
      
      if (soma > 1000.0 && distanciaPercorridaM < 10.0) {
        erros.add('Massa total muito alta para o percurso. Verifique as unidades (gramas)');
      }
    }

    return erros;
  }

  /// Classifica o CV baseado em critérios agronômicos
  static String classificarCV(double cvPercent) {
    if (cvPercent < 10.0) {
      return 'Excelente';
    } else if (cvPercent < 20.0) {
      return 'Moderado';
    } else {
      return 'Ruim';
    }
  }

  /// Classifica o erro percentual
  static String classificarErro(double erroPercent) {
    final erroAbs = erroPercent.abs();
    if (erroAbs <= 5.0) {
      return 'OK';
    } else if (erroAbs <= 10.0) {
      return 'Alerta';
    } else {
      return 'Recalibrar';
    }
  }

  /// Calcula a faixa efetiva estimada (opcional)
  static double? estimarFaixaEfetiva({
    double? paletaPmm,
    double? paletaGmm,
    double? densidade_gL,
    double? rpm,
  }) {
    // Implementação empírica baseada em dados de campo
    // Esta é uma estimativa aproximada
    if (paletaPmm != null && paletaGmm != null && densidade_gL != null) {
      // Fórmula empírica para estimar faixa efetiva
      final faixaEstimada = (paletaPmm + paletaGmm) / 2000.0; // Converter mm para m
      return faixaEstimada;
    }
    return null;
  }
}

/// Utilitário matemático
class Math {
  static double sqrt(double v) => v <= 0 ? 0 : v.toDouble().sqrt();
}

extension _Sqrt on double {
  double sqrt() => (this).toDouble() >= 0 ? _sqrtNewton(this) : double.nan;
  static double _sqrtNewton(double x) {
    if (x == 0) return 0;
    double r = x, last;
    do {
      last = r;
      r = 0.5 * (r + x / r);
    } while ((r - last).abs() > 1e-12);
    return r;
  }
}
