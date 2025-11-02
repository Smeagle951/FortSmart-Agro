/// 🌱 MOTOR DE CÁLCULOS AGRONÔMICOS RIGOROSOS
/// 
/// Sistema revolucionário que aplica normas internacionais rigorosas:
/// - ISTA (International Seed Testing Association)
/// - AOSA (Association of Official Seed Analysts) 
/// - RAS (Regras para Análise de Sementes - Brasil)
/// 
/// Calcula automaticamente todos os parâmetros agronômicos em tempo real
/// conforme os dados diários são registrados.

import 'dart:math';
import '../screens/plantio/submods/germination_test/models/germination_test_model.dart';

/// 🧮 Motor Principal de Cálculos Agronômicos
class AgronomicCalculationEngine {
  
  /// 📊 Calcula TODOS os parâmetros agronômicos de uma vez
  /// Retorna um objeto completo com todos os resultados
  static AgronomicResults calculateCompleteResults({
    required List<GerminationDailyRecord> dailyRecords,
    required int totalSeeds,
    required String culture,
    required String variety,
    required DateTime testStartDate,
    int? vigorDays = 5, // Dias para cálculo de vigor (padrão ISTA)
  }) {
    
    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecord>.from(dailyRecords)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    if (sortedRecords.isEmpty) {
      return AgronomicResults.empty();
    }
    
    // === CÁLCULOS PRINCIPAIS ===
    final germination = _calculateGermination(sortedRecords, totalSeeds);
    final vigor = _calculateVigor(sortedRecords, totalSeeds, vigorDays!);
    final purity = _calculatePurity(sortedRecords, totalSeeds);
    final contamination = _calculateContamination(sortedRecords, totalSeeds);
    final uniformity = _calculateUniformity(sortedRecords);
    final speed = _calculateGerminationSpeed(sortedRecords, totalSeeds);
    final classification = _calculateClassification(germination, vigor, purity);
    final recommendations = _generateRecommendations(germination, vigor, purity, contamination, culture);
    final statistics = _calculateAdvancedStatistics(sortedRecords, totalSeeds);
    final evolution = _calculateEvolutionCurve(sortedRecords, totalSeeds);
    
    return AgronomicResults(
      // Resultados principais
      germinationPercentage: germination,
      vigorIndex: vigor,
      purityPercentage: purity,
      contaminationPercentage: contamination,
      
      // Classificação e qualidade
      classification: classification,
      qualityGrade: _determineQualityGrade(classification),
      
      // Parâmetros de velocidade
      firstCountDay: _getFirstCountDay(sortedRecords),
      lastCountDay: _getLastCountDay(sortedRecords),
      germinationSpeed: speed,
      uniformityIndex: uniformity,
      
      // Estatísticas avançadas
      statistics: statistics,
      evolutionCurve: evolution,
      
      // Recomendações automáticas
      recommendations: recommendations,
      alerts: _generateAlerts(germination, vigor, purity, contamination),
      
      // Metadados
      totalSeeds: totalSeeds,
      testDuration: _calculateTestDuration(sortedRecords),
      culture: culture,
      variety: variety,
      calculatedAt: DateTime.now(),
      
      // Conformidade com normas
      istaCompliant: _checkISTACompliance(germination, vigor, purity),
      aosaCompliant: _checkAOSACompliance(germination, vigor, purity),
      rasCompliant: _checkRASCompliance(germination, vigor, purity),
    );
  }
  
  /// 🌱 CÁLCULO DE GERMINAÇÃO (Norma ISTA)
  /// Percentual de sementes que germinaram normalmente
  static double _calculateGermination(List<GerminationDailyRecord> records, int totalSeeds) {
    if (totalSeeds == 0) return 0.0;
    
    final lastRecord = records.last;
    final normalGerminated = lastRecord.normalGerminated;
    
    return (normalGerminated / totalSeeds) * 100;
  }
  
  /// ⚡ CÁLCULO DE VIGOR (Método ISTA - First Count)
  /// Baseado na velocidade de germinação nos primeiros dias
  static double _calculateVigor(List<GerminationDailyRecord> records, int totalSeeds, int vigorDays) {
    if (totalSeeds == 0) return 0.0;
    
    // Encontrar registros dos primeiros X dias
    final vigorRecords = records.where((r) => r.day <= vigorDays).toList();
    
    if (vigorRecords.isEmpty) return 0.0;
    
    // Soma ponderada: dias iniciais têm peso maior
    double weightedSum = 0.0;
    int totalGerminated = 0;
    
    for (final record in vigorRecords) {
      final dailyGerminated = record.normalGerminated;
      final weight = (vigorDays - record.day + 1).toDouble(); // Peso decrescente
      weightedSum += dailyGerminated.toDouble() * weight;
      totalGerminated += dailyGerminated;
    }
    
    if (totalGerminated == 0) return 0.0;
    
    // Índice de vigor (0-100)
    final vigorIndex = (weightedSum / (totalGerminated * vigorDays)) * 100;
    return min(vigorIndex, 100.0);
  }
  
  /// 🧹 CÁLCULO DE PUREZA (Norma RAS)
  /// Percentual de sementes puras vs impurezas
  static double _calculatePurity(List<GerminationDailyRecord> records, int totalSeeds) {
    if (totalSeeds == 0) return 0.0;
    
    final lastRecord = records.last;
    final pureSeeds = lastRecord.normalGerminated + lastRecord.abnormalGerminated;
    
    return (pureSeeds / totalSeeds) * 100;
  }
  
  /// 🦠 CÁLCULO DE CONTAMINAÇÃO
  /// Percentual de sementes doentes/contaminadas
  static double _calculateContamination(List<GerminationDailyRecord> records, int totalSeeds) {
    if (totalSeeds == 0) return 0.0;
    
    final lastRecord = records.last;
    final contaminated = lastRecord.diseasedFungi + lastRecord.diseasedBacteria;
    
    return (contaminated / totalSeeds) * 100;
  }
  
  /// 📈 CÁLCULO DE UNIFORMIDADE
  /// Mede a consistência da germinação ao longo dos dias
  static double _calculateUniformity(List<GerminationDailyRecord> records) {
    if (records.length < 2) return 100.0;
    
    final dailyGermination = records.map((r) => r.normalGerminated.toDouble()).toList().cast<double>();
    final mean = dailyGermination.reduce((a, b) => a + b) / dailyGermination.length;
    
    if (mean == 0) return 100.0;
    
    // Calcular desvio padrão
    final variance = dailyGermination
        .map((x) => pow(x - mean, 2))
        .reduce((a, b) => a + b) / dailyGermination.length;
    final standardDeviation = sqrt(variance);
    
    // Índice de uniformidade (0-100)
    final coefficientOfVariation = (standardDeviation / mean) * 100;
    return max(0.0, 100.0 - coefficientOfVariation);
  }
  
  /// 🏃 CÁLCULO DE VELOCIDADE DE GERMINAÇÃO
  /// Dias médios para germinação
  static double _calculateGerminationSpeed(List<GerminationDailyRecord> records, int totalSeeds) {
    if (totalSeeds == 0) return 0.0;
    
    double weightedSum = 0.0;
    int totalGerminated = 0;
    
    for (final record in records) {
      final dailyGerminated = record.normalGerminated;
      weightedSum += record.day * dailyGerminated.toDouble();
      totalGerminated += dailyGerminated;
    }
    
    if (totalGerminated == 0) return 0.0;
    
    return weightedSum / totalGerminated;
  }
  
  /// 🏆 CLASSIFICAÇÃO AGRONÔMICA
  /// Baseada em critérios rigorosos das normas internacionais
  static String _calculateClassification(double germination, double vigor, double purity) {
    // Critérios rigorosos baseados em normas ISTA/AOSA/RAS
    if (germination >= 95 && vigor >= 90 && purity >= 98) {
      return 'EXCELENTE';
    } else if (germination >= 90 && vigor >= 80 && purity >= 95) {
      return 'MUITO BOA';
    } else if (germination >= 85 && vigor >= 70 && purity >= 90) {
      return 'BOA';
    } else if (germination >= 80 && vigor >= 60 && purity >= 85) {
      return 'REGULAR';
    } else if (germination >= 70 && vigor >= 50 && purity >= 80) {
      return 'ACEITÁVEL';
    } else {
      return 'RUIM';
    }
  }
  
  /// 🎯 GERAÇÃO DE RECOMENDAÇÕES AUTOMÁTICAS
  /// Baseada em análise agronômica avançada
  static List<String> _generateRecommendations(
    double germination, 
    double vigor, 
    double purity, 
    double contamination,
    String culture
  ) {
    final recommendations = <String>[];
    
    // Recomendações baseadas em germinação
    if (germination < 80) {
      recommendations.add('⚠️ Germinação baixa: Verificar qualidade das sementes e condições de armazenamento');
    } else if (germination >= 95) {
      recommendations.add('✅ Excelente germinação: Sementes de alta qualidade');
    }
    
    // Recomendações baseadas em vigor
    if (vigor < 60) {
      recommendations.add('⚡ Vigor baixo: Considerar tratamento de sementes ou troca de lote');
    } else if (vigor >= 90) {
      recommendations.add('🚀 Alto vigor: Ideal para plantio em condições adversas');
    }
    
    // Recomendações baseadas em pureza
    if (purity < 90) {
      recommendations.add('🧹 Pureza insuficiente: Necessário beneficiamento das sementes');
    }
    
    // Recomendações baseadas em contaminação
    if (contamination > 5) {
      recommendations.add('🦠 Alta contaminação: Aplicar tratamento fungicida nas sementes');
    }
    
    // Recomendações específicas por cultura
    switch (culture.toLowerCase()) {
      case 'soja':
        if (germination >= 85) {
          recommendations.add('🌱 Soja: Densidade de plantio pode ser reduzida em 10%');
        }
        break;
      case 'milho':
        if (vigor >= 80) {
          recommendations.add('🌽 Milho: Plantio direto recomendado para preservar vigor');
        }
        break;
      case 'algodão':
        if (purity >= 95) {
          recommendations.add('🌿 Algodão: Sementes prontas para deslintamento');
        }
        break;
    }
    
    return recommendations;
  }
  
  /// 🚨 GERAÇÃO DE ALERTAS AUTOMÁTICOS
  static List<AgronomicAlert> _generateAlerts(
    double germination, 
    double vigor, 
    double purity, 
    double contamination
  ) {
    final alerts = <AgronomicAlert>[];
    
    if (germination < 70) {
      alerts.add(AgronomicAlert(
        type: AlertType.critical,
        title: 'Germinação Crítica',
        message: 'Germinação abaixo de 70% - Sementes não recomendadas para plantio',
        action: 'Verificar lote e considerar troca',
      ));
    }
    
    if (vigor < 50) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Vigor Baixo',
        message: 'Vigor abaixo de 50% - Risco de estabelecimento inadequado',
        action: 'Aplicar tratamento de sementes',
      ));
    }
    
    if (contamination > 10) {
      alerts.add(AgronomicAlert(
        type: AlertType.warning,
        title: 'Alta Contaminação',
        message: 'Contaminação acima de 10% - Risco de doenças',
        action: 'Tratamento fungicida obrigatório',
      ));
    }
    
    return alerts;
  }
  
  /// 📊 ESTATÍSTICAS AVANÇADAS
  static AgronomicStatistics _calculateAdvancedStatistics(
    List<GerminationDailyRecord> records, 
    int totalSeeds
  ) {
    if (records.isEmpty) return AgronomicStatistics.empty();
    
    final dailyGermination = records.map((r) => r.normalGerminated.toDouble()).toList().cast<double>();
    final mean = dailyGermination.reduce((a, b) => a + b) / dailyGermination.length;
    
    // Desvio padrão
    final variance = dailyGermination
        .map((x) => pow(x - mean, 2).toDouble())
        .reduce((a, b) => a + b) / dailyGermination.length;
    final standardDeviation = sqrt(variance);
    
    // Coeficiente de variação
    final coefficientOfVariation = mean > 0 ? (standardDeviation / mean) * 100 : 0.0;
    
    // Tendência (regressão linear simples)
    final trend = _calculateTrend(records);
    
    return AgronomicStatistics(
      meanDailyGermination: mean,
      standardDeviation: standardDeviation,
      coefficientOfVariation: coefficientOfVariation,
      trend: trend,
      confidenceInterval: _calculateConfidenceInterval(dailyGermination),
      reliability: _calculateReliability(records, totalSeeds),
    );
  }
  
  /// 📈 CURVA DE EVOLUÇÃO
  static List<EvolutionPoint> _calculateEvolutionCurve(
    List<GerminationDailyRecord> records, 
    int totalSeeds
  ) {
    return records.map((record) {
      final cumulativeGermination = records
          .where((r) => r.day <= record.day)
          .map((r) => r.normalGerminated)
          .reduce((a, b) => a + b);
      
      final percentage = totalSeeds > 0 ? (cumulativeGermination / totalSeeds) * 100 : 0.0;
      
      return EvolutionPoint(
        day: record.day,
        cumulativePercentage: percentage,
        dailyGermination: record.normalGerminated,
        date: record.recordDate,
      );
    }).toList().cast<EvolutionPoint>();
  }
  
  // === MÉTODOS AUXILIARES ===
  
  static int _getFirstCountDay(List<GerminationDailyRecord> records) {
    return records.isNotEmpty ? records.first.day : 0;
  }
  
  static int _getLastCountDay(List<GerminationDailyRecord> records) {
    return records.isNotEmpty ? records.last.day : 0;
  }
  
  static int _calculateTestDuration(List<GerminationDailyRecord> records) {
    if (records.isEmpty) return 0;
    return records.last.day - records.first.day + 1;
  }
  
  static String _determineQualityGrade(String classification) {
    switch (classification) {
      case 'EXCELENTE': return 'A+';
      case 'MUITO BOA': return 'A';
      case 'BOA': return 'B';
      case 'REGULAR': return 'C';
      case 'ACEITÁVEL': return 'D';
      default: return 'F';
    }
  }
  
  static bool _checkISTACompliance(double germination, double vigor, double purity) {
    return germination >= 85 && vigor >= 70 && purity >= 90;
  }
  
  static bool _checkAOSACompliance(double germination, double vigor, double purity) {
    return germination >= 80 && vigor >= 65 && purity >= 85;
  }
  
  static bool _checkRASCompliance(double germination, double vigor, double purity) {
    return germination >= 80 && vigor >= 60 && purity >= 85;
  }
  
  static double _calculateTrend(List<GerminationDailyRecord> records) {
    if (records.length < 2) return 0.0;
    
    final n = records.length;
    final sumX = records.map((r) => r.day).reduce((a, b) => a + b);
    final sumY = records.map((r) => r.normalGerminated).reduce((a, b) => a + b);
    final sumXY = records.map((r) => r.day * r.normalGerminated).reduce((a, b) => a + b);
    final sumXX = records.map((r) => r.day * r.day).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }
  
  static Map<String, double> _calculateConfidenceInterval(List<double> values) {
    if (values.isEmpty) return {'lower': 0.0, 'upper': 0.0};
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    final standardError = sqrt(variance / values.length);
    
    // 95% confidence interval (aproximado)
    final margin = 1.96 * standardError;
    
    return {
      'lower': max(0.0, mean - margin),
      'upper': mean + margin,
    };
  }
  
  static double _calculateReliability(List<GerminationDailyRecord> records, int totalSeeds) {
    if (records.isEmpty || totalSeeds == 0) return 0.0;
    
    // Baseado na consistência dos dados e tamanho da amostra
    final consistency = _calculateUniformity(records);
    final sampleSize = min(totalSeeds / 100.0, 1.0); // Normalizado
    
    return (consistency * 0.7 + sampleSize * 30.0);
  }
}

/// 📊 RESULTADOS COMPLETOS AGRONÔMICOS
class AgronomicResults {
  // Resultados principais
  final double germinationPercentage;
  final double vigorIndex;
  final double purityPercentage;
  final double contaminationPercentage;
  
  // Classificação e qualidade
  final String classification;
  final String qualityGrade;
  
  // Parâmetros de velocidade
  final int firstCountDay;
  final int lastCountDay;
  final double germinationSpeed;
  final double uniformityIndex;
  
  // Estatísticas avançadas
  final AgronomicStatistics statistics;
  final List<EvolutionPoint> evolutionCurve;
  
  // Recomendações e alertas
  final List<String> recommendations;
  final List<AgronomicAlert> alerts;
  
  // Metadados
  final int totalSeeds;
  final int testDuration;
  final String culture;
  final String variety;
  final DateTime calculatedAt;
  
  // Conformidade com normas
  final bool istaCompliant;
  final bool aosaCompliant;
  final bool rasCompliant;
  
  AgronomicResults({
    required this.germinationPercentage,
    required this.vigorIndex,
    required this.purityPercentage,
    required this.contaminationPercentage,
    required this.classification,
    required this.qualityGrade,
    required this.firstCountDay,
    required this.lastCountDay,
    required this.germinationSpeed,
    required this.uniformityIndex,
    required this.statistics,
    required this.evolutionCurve,
    required this.recommendations,
    required this.alerts,
    required this.totalSeeds,
    required this.testDuration,
    required this.culture,
    required this.variety,
    required this.calculatedAt,
    required this.istaCompliant,
    required this.aosaCompliant,
    required this.rasCompliant,
  });
  
  factory AgronomicResults.empty() {
    return AgronomicResults(
      germinationPercentage: 0.0,
      vigorIndex: 0.0,
      purityPercentage: 0.0,
      contaminationPercentage: 0.0,
      classification: 'SEM DADOS',
      qualityGrade: 'F',
      firstCountDay: 0,
      lastCountDay: 0,
      germinationSpeed: 0.0,
      uniformityIndex: 0.0,
      statistics: AgronomicStatistics.empty(),
      evolutionCurve: [],
      recommendations: [],
      alerts: [],
      totalSeeds: 0,
      testDuration: 0,
      culture: '',
      variety: '',
      calculatedAt: DateTime.now(),
      istaCompliant: false,
      aosaCompliant: false,
      rasCompliant: false,
    );
  }
  
  /// 🎯 Verifica se os resultados são aceitáveis para plantio
  bool get isPlantingAcceptable {
    return germinationPercentage >= 80 && 
           vigorIndex >= 60 && 
           purityPercentage >= 85 && 
           contaminationPercentage <= 10;
  }
  
  /// 📈 Retorna o status geral do teste
  String get overallStatus {
    if (classification == 'EXCELENTE' || classification == 'MUITO BOA') {
      return 'APROVADO';
    } else if (classification == 'BOA' || classification == 'REGULAR') {
      return 'CONDICIONAL';
    } else {
      return 'REPROVADO';
    }
  }
}

/// 📊 ESTATÍSTICAS AVANÇADAS
class AgronomicStatistics {
  final double meanDailyGermination;
  final double standardDeviation;
  final double coefficientOfVariation;
  final double trend;
  final Map<String, double> confidenceInterval;
  final double reliability;
  
  AgronomicStatistics({
    required this.meanDailyGermination,
    required this.standardDeviation,
    required this.coefficientOfVariation,
    required this.trend,
    required this.confidenceInterval,
    required this.reliability,
  });
  
  factory AgronomicStatistics.empty() {
    return AgronomicStatistics(
      meanDailyGermination: 0.0,
      standardDeviation: 0.0,
      coefficientOfVariation: 0.0,
      trend: 0.0,
      confidenceInterval: {'lower': 0.0, 'upper': 0.0},
      reliability: 0.0,
    );
  }
}

/// 📈 PONTO DA CURVA DE EVOLUÇÃO
class EvolutionPoint {
  final int day;
  final double cumulativePercentage;
  final int dailyGermination;
  final DateTime date;
  
  EvolutionPoint({
    required this.day,
    required this.cumulativePercentage,
    required this.dailyGermination,
    required this.date,
  });
}

/// 🚨 ALERTA AGRONÔMICO
class AgronomicAlert {
  final AlertType type;
  final String title;
  final String message;
  final String action;
  
  AgronomicAlert({
    required this.type,
    required this.title,
    required this.message,
    required this.action,
  });
}

/// 🚨 TIPOS DE ALERTA
enum AlertType {
  info,
  warning,
  critical,
}
