/// 🌱 Serviço de Cálculos Agronômicos - Teste de Germinação
/// 
/// Implementa cálculos seguindo metodologias agronômicas (ABNT NBR 9787)
/// e protocolos de pesquisa para testes de germinação

import '../models/germination_test_model.dart';

class GerminationCalculationService {
  
  /// Calcula percentual de germinação final (ABNT NBR 9787)
  /// Germinação = (Sementes germinadas normais / Total de sementes) × 100
  static double calculateGerminationPercentage(
    int normalGerminated,
    int totalSeeds,
  ) {
    if (totalSeeds <= 0) return 0.0;
    return (normalGerminated / totalSeeds) * 100;
  }

  /// Calcula percentual de germinação acumulada
  /// Considera todos os registros diários acumulados
  static double calculateAccumulatedGermination(
    List<GerminationDailyRecord> records,
    int totalSeeds,
  ) {
    if (totalSeeds <= 0 || records.isEmpty) return 0.0;
    
    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecord>.from(records)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    // Calcular total acumulado de germinação normal
    int totalNormalGerminated = 0;
    for (final record in sortedRecords) {
      totalNormalGerminated += record.normalGerminated;
    }
    
    return (totalNormalGerminated / totalSeeds) * 100;
  }

  /// Calcula vigor (germinação até o 5º ou 7º dia)
  /// Vigor = (Germinadas até dia X / Total de sementes) × 100
  static double calculateVigor(
    List<GerminationDailyRecord> records,
    int totalSeeds, {
    int vigorDays = 5,
  }) {
    if (totalSeeds <= 0 || records.isEmpty) return 0.0;
    
    // Filtrar registros até o limite de dias
    final vigorRecords = records.where((r) => r.day <= vigorDays).toList();
    if (vigorRecords.isEmpty) return 0.0;
    
    // Ordenar por dia
    vigorRecords.sort((a, b) => a.day.compareTo(b.day));
    
    // Calcular total acumulado de germinação até o limite
    int totalVigor = 0;
    for (final record in vigorRecords) {
      totalVigor += record.normalGerminated + record.abnormalGerminated;
    }
    
    return (totalVigor / totalSeeds) * 100;
  }

  /// Calcula percentual de contaminação
  /// Contaminação = (Fungos + Bactérias / Total de sementes) × 100
  static double calculateContaminationPercentage(
    List<GerminationDailyRecord> records,
    int totalSeeds,
  ) {
    if (totalSeeds <= 0 || records.isEmpty) return 0.0;
    
    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecord>.from(records)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    // Calcular total acumulado de contaminação
    int totalContamination = 0;
    for (final record in sortedRecords) {
      totalContamination += record.diseasedFungi + record.diseasedBacteria;
    }
    
    return (totalContamination / totalSeeds) * 100;
  }

  /// Calcula percentual de pureza
  /// Pureza = ((Total - Outras sementes - Matéria inerte) / Total) × 100
  static double calculatePurityPercentage(
    List<GerminationDailyRecord> records,
    int totalSeeds,
  ) {
    if (totalSeeds <= 0 || records.isEmpty) return 0.0;
    
    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecord>.from(records)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    // Calcular total acumulado de impurezas
    int totalImpurities = 0;
    for (final record in sortedRecords) {
      totalImpurities += record.otherSeeds + record.inertMatter;
    }
    
    final pureSeeds = totalSeeds - totalImpurities;
    return (pureSeeds / totalSeeds) * 100;
  }

  /// Calcula tempo médio de germinação
  /// Tempo médio = Σ(Dia × Germinadas no dia) / Total germinadas
  static double calculateAverageGerminationTime(
    List<GerminationDailyRecord> records,
  ) {
    if (records.isEmpty) return 0.0;
    
    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecord>.from(records)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    int totalGerminated = 0;
    int weightedSum = 0;
    
    for (final record in sortedRecords) {
      final dailyGerminated = record.normalGerminated + record.abnormalGerminated;
      totalGerminated += dailyGerminated;
      weightedSum += record.day * dailyGerminated;
    }
    
    if (totalGerminated == 0) return 0.0;
    return weightedSum / totalGerminated;
  }

  /// Calcula dia do primeiro registro
  static int? calculateFirstCountDay(List<GerminationDailyRecord> records) {
    if (records.isEmpty) return null;
    
    final sortedRecords = List<GerminationDailyRecord>.from(records)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    return sortedRecords.first.day;
  }

  /// Calcula dia em que atingiu 50% de germinação
  static int? calculateDay50PercentGermination(
    List<GerminationDailyRecord> records,
    int totalSeeds,
  ) {
    if (totalSeeds <= 0 || records.isEmpty) return null;
    
    // Ordenar registros por dia
    final sortedRecords = List<GerminationDailyRecord>.from(records)
      ..sort((a, b) => a.day.compareTo(b.day));
    
    int accumulatedGerminated = 0;
    final target50Percent = (totalSeeds * 0.5).round();
    
    for (final record in sortedRecords) {
      accumulatedGerminated += record.normalGerminated;
      if (accumulatedGerminated >= target50Percent) {
        return record.day;
      }
    }
    
    return null;
  }

  /// Classifica resultado baseado em critérios agronômicos
  static String classifyResult(
    double germinationPercentage,
    double vigor,
    double contaminationPercentage,
  ) {
    // Critérios de classificação baseados em ABNT NBR 9787
    if (germinationPercentage >= 90 && vigor >= 80 && contaminationPercentage <= 5) {
      return 'Excelente';
    } else if (germinationPercentage >= 80 && vigor >= 70 && contaminationPercentage <= 10) {
      return 'Boa';
    } else if (germinationPercentage >= 70 && vigor >= 60 && contaminationPercentage <= 15) {
      return 'Regular';
    } else {
      return 'Baixa';
    }
  }

  /// Calcula valor cultural (Germinação × Vigor / 100)
  static double calculateCulturalValue(
    double germinationPercentage,
    double vigor,
  ) {
    return (germinationPercentage * vigor) / 100;
  }

  /// Calcula resultados consolidados para teste com subtestes
  static GerminationTestResults calculateConsolidatedResults(
    int testId,
    List<GerminationSubtestResults> subtestResults,
  ) {
    if (subtestResults.isEmpty) {
      return GerminationTestResults(
        testId: testId,
        finalGerminationPercentage: 0.0,
        averageGerminationTime: 0.0,
        diseasedPercentage: 0.0,
        purityPercentage: 0.0,
        classification: 'Baixa',
        subtestResults: subtestResults,
        calculatedAt: DateTime.now(),
      );
    }

    // Calcular médias dos subtestes
    final avgGermination = subtestResults
        .map((s) => s.germinationPercentage)
        .reduce((a, b) => a + b) / subtestResults.length;

    final avgDiseased = subtestResults
        .map((s) => s.diseasedPercentage)
        .reduce((a, b) => a + b) / subtestResults.length;

    final avgPurity = subtestResults
        .map((s) => s.purityPercentage)
        .reduce((a, b) => a + b) / subtestResults.length;

    final avgTime = subtestResults
        .map((s) => s.dailyRecords.isNotEmpty 
            ? calculateAverageGerminationTime(s.dailyRecords.map((r) => 
                GerminationDailyRecord(
                  germinationTestId: testId,
                  day: r.day,
                  recordDate: r.recordDate,
                  normalGerminated: r.normalGerminated,
                  abnormalGerminated: r.abnormalGerminated,
                  diseasedFungi: r.diseasedFungi,
                  diseasedBacteria: r.diseasedBacteria,
                  notGerminated: r.notGerminated,
                  otherSeeds: r.otherSeeds,
                  inertMatter: r.inertMatter,
                  createdAt: r.createdAt,
                  updatedAt: r.updatedAt,
                )).toList())
            : 0.0)
        .reduce((a, b) => a + b) / subtestResults.length;

    final classification = classifyResult(avgGermination, avgGermination, avgDiseased);

    return GerminationTestResults(
      testId: testId,
      finalGerminationPercentage: avgGermination,
      averageGerminationTime: avgTime,
      diseasedPercentage: avgDiseased,
      purityPercentage: avgPurity,
      classification: classification,
      subtestResults: subtestResults,
      calculatedAt: DateTime.now(),
    );
  }

  /// Calcula resultados de um subteste específico
  static GerminationSubtestResults calculateSubtestResults(
    int subtestId,
    String subtestCode,
    String subtestName,
    List<GerminationSubtestDailyRecord> records,
    int totalSeeds,
  ) {
    if (records.isEmpty || totalSeeds <= 0) {
      return GerminationSubtestResults(
        subtestId: subtestId,
        subtestCode: subtestCode,
        subtestName: subtestName,
        germinationPercentage: 0.0,
        diseasedPercentage: 0.0,
        purityPercentage: 0.0,
        classification: 'Baixa',
        dailyRecords: records,
      );
    }

    // Converter para GerminationDailyRecord para usar os métodos existentes
    final dailyRecords = records.map((r) => GerminationDailyRecord(
      germinationTestId: 0, // Não usado no cálculo
      day: r.day,
      recordDate: r.recordDate,
      normalGerminated: r.normalGerminated,
      abnormalGerminated: r.abnormalGerminated,
      diseasedFungi: r.diseasedFungi,
      diseasedBacteria: r.diseasedBacteria,
      notGerminated: r.notGerminated,
      otherSeeds: r.otherSeeds,
      inertMatter: r.inertMatter,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    )).toList();

    final germinationPercentage = calculateAccumulatedGermination(dailyRecords, totalSeeds);
    final diseasedPercentage = calculateContaminationPercentage(dailyRecords, totalSeeds);
    final purityPercentage = calculatePurityPercentage(dailyRecords, totalSeeds);
    final classification = classifyResult(germinationPercentage, germinationPercentage, diseasedPercentage);

    return GerminationSubtestResults(
      subtestId: subtestId,
      subtestCode: subtestCode,
      subtestName: subtestName,
      germinationPercentage: germinationPercentage,
      diseasedPercentage: diseasedPercentage,
      purityPercentage: purityPercentage,
      classification: classification,
      dailyRecords: records,
    );
  }

  /// Valida dados de entrada para cálculos
  static bool validateCalculationData(
    List<GerminationDailyRecord> records,
    int totalSeeds,
  ) {
    if (totalSeeds <= 0) return false;
    if (records.isEmpty) return false;
    
    // Verificar se todos os registros têm dados válidos
    for (final record in records) {
      if (record.day <= 0) return false;
      if (record.normalGerminated < 0) return false;
      if (record.abnormalGerminated < 0) return false;
      if (record.diseasedFungi < 0) return false;
      if (record.diseasedBacteria < 0) return false;
      if (record.notGerminated < 0) return false;
    }
    
    return true;
  }

  /// Obtém estatísticas resumidas de um teste
  static Map<String, dynamic> getTestSummary(
    List<GerminationDailyRecord> records,
    int totalSeeds,
  ) {
    if (!validateCalculationData(records, totalSeeds)) {
      return {
        'isValid': false,
        'error': 'Dados inválidos para cálculo',
      };
    }

    final germinationPercentage = calculateAccumulatedGermination(records, totalSeeds);
    final vigor = calculateVigor(records, totalSeeds);
    final contaminationPercentage = calculateContaminationPercentage(records, totalSeeds);
    final purityPercentage = calculatePurityPercentage(records, totalSeeds);
    final averageTime = calculateAverageGerminationTime(records);
    final classification = classifyResult(germinationPercentage, vigor, contaminationPercentage);
    final culturalValue = calculateCulturalValue(germinationPercentage, vigor);

    return {
      'isValid': true,
      'germinationPercentage': germinationPercentage,
      'vigor': vigor,
      'contaminationPercentage': contaminationPercentage,
      'purityPercentage': purityPercentage,
      'averageTime': averageTime,
      'classification': classification,
      'culturalValue': culturalValue,
      'firstCountDay': calculateFirstCountDay(records),
      'day50PercentGermination': calculateDay50PercentGermination(records, totalSeeds),
      'totalRecords': records.length,
    };
  }
}
