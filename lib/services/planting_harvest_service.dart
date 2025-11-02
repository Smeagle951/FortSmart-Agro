import 'agricultural_calculator.dart';

/// Serviço para gerenciar operações relacionadas ao plantio e colheita
class PlantingHarvestService {
  static final PlantingHarvestService _instance = PlantingHarvestService._internal();
  final AgriculturalCalculator _calculator = AgriculturalCalculator();
  
  factory PlantingHarvestService() {
    return _instance;
  }
  
  PlantingHarvestService._internal();
  
  /// Calcula a perda na colheita em kg/ha
  double calculateHarvestLoss(double grainsPerSqm, double thousandGrainWeight) {
    return _calculator.calculateHarvestLoss(
      grainsPerSqm: grainsPerSqm,
      thousandGrainWeight: thousandGrainWeight,
    );
  }
  
  /// Calcula a perda financeira na colheita
  double calculateHarvestFinancialLoss(double lossKgPerHa, double pricePerKg, double totalArea) {
    return _calculator.calculateHarvestFinancialLoss(
      lossKgPerHa: lossKgPerHa,
      pricePerKg: pricePerKg,
      totalArea: totalArea,
    );
  }
  
  /// Calcula o número de sementes por metro para calibração da plantadeira
  double calculatePlanterCalibration(
    double desiredPlants,
    double rowSpacing,
    double germinationRate,
    double viabilityFactor,
  ) {
    return _calculator.calculatePlanterCalibration(
      desiredPlants: desiredPlants,
      rowSpacing: rowSpacing,
      germinationRate: germinationRate,
      viabilityFactor: viabilityFactor,
    );
  }
  
  /// Calcula a população de plantas por hectare
  double calculatePlantPopulation(double plantsPerMeter, double rowSpacing) {
    return _calculator.calculatePlantPopulation(
      plantsPerMeter: plantsPerMeter,
      rowSpacing: rowSpacing,
    );
  }
  
  /// Calcula a velocidade ideal de plantio
  double calculatePlantingSpeed(
    double desiredSeedsPerHa,
    int discHoles,
    double rowSpacing,
    double discRpm,
  ) {
    return _calculator.calculatePlantingSpeed(
      desiredSeedsPerHa: desiredSeedsPerHa,
      discHoles: discHoles,
      rowSpacing: rowSpacing,
      discRpm: discRpm,
    );
  }
  
  /// Calcula a quantidade de sementes necessárias para uma área
  double calculateSeedQuantity(double areaHectares, double seedsPerHectare, double germinationRate) {
    return _calculator.calculateSeedQuantity(
      areaHectares: areaHectares,
      seedsPerHectare: seedsPerHectare,
      germinationRate: germinationRate,
    );
  }
  
  /// Calcula o espaçamento entre plantas para uma população desejada
  double calculatePlantSpacing(double plantsPerHa, double rowSpacing) {
    // Metros lineares por hectare
    final double linearMetersPerHa = 10000 / rowSpacing;
    
    // Plantas por metro linear
    final double plantsPerMeter = plantsPerHa / linearMetersPerHa;
    
    // Espaçamento entre plantas em metros
    return 1 / plantsPerMeter;
  }
  
  /// Interpreta o nível de perda na colheita
  String interpretHarvestLoss(double lossKgPerHa, String cropType) {
    if (cropType.toLowerCase().contains('soja')) {
      if (lossKgPerHa < 60) return 'Baixa';
      if (lossKgPerHa < 120) return 'Média';
      return 'Alta';
    } else if (cropType.toLowerCase().contains('milho')) {
      if (lossKgPerHa < 80) return 'Baixa';
      if (lossKgPerHa < 160) return 'Média';
      return 'Alta';
    } else {
      if (lossKgPerHa < 70) return 'Baixa';
      if (lossKgPerHa < 140) return 'Média';
      return 'Alta';
    }
  }
  
  /// Calcula a profundidade ideal de plantio para uma cultura
  double calculateIdealPlantingDepth(String cropType, String soilType) {
    // Valores em centímetros
    if (cropType.toLowerCase().contains('soja')) {
      if (soilType.toLowerCase().contains('arenos')) return 3.5;
      if (soilType.toLowerCase().contains('argil')) return 2.5;
      return 3.0; // Médio
    } else if (cropType.toLowerCase().contains('milho')) {
      if (soilType.toLowerCase().contains('arenos')) return 5.0;
      if (soilType.toLowerCase().contains('argil')) return 3.5;
      return 4.0; // Médio
    } else if (cropType.toLowerCase().contains('algod')) {
      if (soilType.toLowerCase().contains('arenos')) return 4.0;
      if (soilType.toLowerCase().contains('argil')) return 2.5;
      return 3.0; // Médio
    } else {
      return 3.0; // Valor padrão para outras culturas
    }
  }
  
  /// Calcula o número de dias para a colheita com base na data de plantio e ciclo da cultura
  int calculateDaysToHarvest(DateTime plantingDate, int cultureCycleDays) {
    final DateTime expectedHarvestDate = plantingDate.add(Duration(days: cultureCycleDays));
    final DateTime today = DateTime.now();
    
    if (today.isAfter(expectedHarvestDate)) {
      return 0;
    }
    
    return expectedHarvestDate.difference(today).inDays;
  }
  
  /// Estima a produtividade com base em dados de monitoramento
  double estimateYield(
    String cropType,
    double plantsPerHa,
    double grainsPerPlant,
    double thousandGrainWeight,
  ) {
    // Calcular o número total de grãos por hectare
    final double grainsPerHa = plantsPerHa * grainsPerPlant;
    
    // Calcular o peso total em kg/ha
    return (grainsPerHa * thousandGrainWeight) / 1000000;
  }
}
