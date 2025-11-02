import 'dart:math';

/// Resultado completo de calibração de fertilizantes
/// Implementa as regras práticas de campo com cálculos precisos
class CalibrationResult {
  final double areaHa; // Área amostrada em hectares
  final double totalKg; // Peso total coletado em kg
  final double rateKgHa; // Taxa real aplicada em kg/ha
  final List<double> trayRates; // Taxas por bandeja em kg/ha
  final double mean; // Média das taxas por bandeja
  final double std; // Desvio padrão das taxas por bandeja
  final double cvPercent; // Coeficiente de variação em %
  final double errorPercent; // Erro vs taxa desejada (se fornecida)
  final double adjustPercent; // Percentual de ajuste sugerido
  final double adjustmentFactor; // Fator de ajuste
  final List<double> weightsGrams; // Pesos originais em gramas
  final double distanceM; // Distância percorrida em metros
  final double widthM; // Largura de aplicação em metros
  final int numberOfTrays; // Número de bandejas
  
  CalibrationResult({
    required this.areaHa,
    required this.totalKg,
    required this.rateKgHa,
    required this.trayRates,
    required this.mean,
    required this.std,
    required this.cvPercent,
    required this.errorPercent,
    required this.adjustPercent,
    required this.adjustmentFactor,
    required this.weightsGrams,
    required this.distanceM,
    required this.widthM,
    required this.numberOfTrays,
  });
  
  /// Status da qualidade baseado no CV%
  String get qualityStatus {
    if (cvPercent < 10) return 'Excelente';
    if (cvPercent <= 15) return 'Aceitável';
    return 'Ruim';
  }
  
  /// Cor do status baseado no CV%
  String get qualityColor {
    if (cvPercent < 10) return 'green';
    if (cvPercent <= 15) return 'orange';
    return 'red';
  }
  
  /// Descrição do status
  String get qualityDescription {
    if (cvPercent < 10) return 'Distribuição uniforme e excelente';
    if (cvPercent <= 15) return 'Distribuição aceitável, pode melhorar';
    return 'Distribuição irregular, recalibrar necessário';
  }
  
  /// Recomendação de ajuste
  String get adjustmentRecommendation {
    if (adjustPercent.abs() < 5) {
      return 'Calibração adequada, sem ajuste necessário';
    } else if (adjustPercent > 0) {
      return 'Aumentar dosador em ${adjustPercent.abs().toStringAsFixed(1)}%';
    } else {
      return 'Reduzir dosador em ${adjustPercent.abs().toStringAsFixed(1)}%';
    }
  }
  
  /// Taxa em sacas/ha (considerando 50kg por saca)
  double get rateSacasHa => rateKgHa / 50.0;
  
  /// Área por bandeja em hectares
  double get areaPerTray => areaHa / numberOfTrays;
}

/// Classe para cálculos de calibração seguindo regras práticas de campo
class CalibrationCalculator {
  /// Calcula calibração completa seguindo o exemplo fornecido
  /// 
  /// Parâmetros:
  /// - weightsGrams: Lista de pesos coletados em gramas
  /// - distanceM: Distância percorrida em metros (D)
  /// - widthM: Largura de aplicação em metros (F)
  /// - desiredKgHa: Taxa desejada em kg/ha (opcional)
  /// 
  /// Retorna: CalibrationResult com todos os cálculos
  static CalibrationResult calculateCalibration({
    required List<double> weightsGrams, // x_i em gramas
    required double distanceM, // D
    required double widthM, // F (largura total)
    double? desiredKgHa, // T_d opcional
  }) {
    final n = weightsGrams.length;
    if (n == 0) throw ArgumentError('É necessário ao menos 1 bandeja');
    if (distanceM <= 0) throw ArgumentError('Distância deve ser maior que zero');
    if (widthM <= 0) throw ArgumentError('Largura deve ser maior que zero');
    
    // 1. Área amostrada: A = (D × F) / 10.000
    final areaHa = (distanceM * widthM) / 10000.0;
    
    // 2. Peso total em kg
    final totalKg = weightsGrams.reduce((a, b) => a + b) / 1000.0;
    
    // 3. Taxa real: T_r = Peso Total / Área
    final rateKgHa = totalKg / areaHa;
    
    // 4. Área por bandeja
    final areaPerTray = areaHa / n;
    
    // 5. Taxas por bandeja: T_i = (peso_i em kg) / (área por bandeja)
    final trayRates = weightsGrams.map((g) {
      final kg = g / 1000.0;
      return kg / areaPerTray;
    }).toList();
    
    // 6. Média das taxas por bandeja
    final mean = trayRates.reduce((a, b) => a + b) / n;
    
    // 7. Desvio padrão das taxas por bandeja
    final sumSq = trayRates.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b);
    final std = n > 1 ? sqrt(sumSq / (n - 1)) : 0.0;
    
    // 8. Coeficiente de variação: CV% = (std / mean) × 100
    final cvPercent = mean != 0 ? (std / mean) * 100.0 : 0.0;
    
    // 9. Erro percentual vs taxa desejada
    double errorPercent = 0.0;
    double adjustPercent = 0.0;
    double adjustmentFactor = 1.0;
    
    if (desiredKgHa != null && desiredKgHa > 0) {
      errorPercent = ((rateKgHa - desiredKgHa) / desiredKgHa) * 100.0;
      adjustmentFactor = desiredKgHa / rateKgHa;
      adjustPercent = (adjustmentFactor - 1.0) * 100.0; // positivo = aumentar, negativo = reduzir
    }
    
    return CalibrationResult(
      areaHa: areaHa,
      totalKg: totalKg,
      rateKgHa: rateKgHa,
      trayRates: trayRates,
      mean: mean,
      std: std,
      cvPercent: cvPercent,
      errorPercent: errorPercent,
      adjustPercent: adjustPercent,
      adjustmentFactor: adjustmentFactor,
      weightsGrams: weightsGrams,
      distanceM: distanceM,
      widthM: widthM,
      numberOfTrays: n,
    );
  }
  
  /// Valida se os dados de entrada são adequados
  static String? validateInput({
    required List<double> weights,
    required double distance,
    required double width,
  }) {
    if (weights.isEmpty) {
      return 'É necessário pelo menos 1 bandeja';
    }
    
    if (weights.length < 6) {
      return 'Recomenda-se usar pelo menos 6 bandejas para melhor estatística';
    }
    
    if (distance <= 0) {
      return 'Distância deve ser maior que zero';
    }
    
    if (width <= 0) {
      return 'Largura deve ser maior que zero';
    }
    
    if (weights.any((w) => w <= 0)) {
      return 'Todos os pesos devem ser maiores que zero';
    }
    
    return null; // Válido
  }
  
  /// Gera recomendações baseadas no resultado
  static List<String> generateRecommendations(CalibrationResult result) {
    final recommendations = <String>[];
    
    // Recomendação baseada no CV%
    if (result.cvPercent > 15) {
      recommendations.add('CV% alto (${result.cvPercent.toStringAsFixed(1)}%) - Verificar distribuidor');
      recommendations.add('Verificar se as bandejas estão uniformemente distribuídas');
      recommendations.add('Considerar limpeza ou manutenção do equipamento');
    } else if (result.cvPercent > 10) {
      recommendations.add('CV% moderado (${result.cvPercent.toStringAsFixed(1)}%) - Monitorar distribuição');
    } else {
      recommendations.add('CV% excelente (${result.cvPercent.toStringAsFixed(1)}%) - Distribuição uniforme');
    }
    
    // Recomendação baseada no ajuste
    if (result.adjustPercent.abs() > 10) {
      recommendations.add(result.adjustmentRecommendation);
    }
    
    // Recomendação baseada no número de bandejas
    if (result.numberOfTrays < 6) {
      recommendations.add('Considerar usar mais bandejas (6-8) para melhor precisão');
    }
    
    return recommendations;
  }
}
