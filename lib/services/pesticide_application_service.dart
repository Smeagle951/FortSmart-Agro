import 'agricultural_calculator.dart';

/// Serviço para gerenciar operações relacionadas à aplicação de defensivos
class PesticideApplicationService {
  static final PesticideApplicationService _instance = PesticideApplicationService._internal();
  final AgriculturalCalculator _calculator = AgriculturalCalculator();
  
  factory PesticideApplicationService() {
    return _instance;
  }
  
  PesticideApplicationService._internal();
  
  /// Calcula o volume total de calda para uma área
  double calculateTotalSprayVolume(double caldaVolumePerHa, double totalArea) {
    return _calculator.calculateSprayVolume(
      areaHectares: totalArea,
      applicationRate: caldaVolumePerHa,
    );
  }
  
  /// Calcula a quantidade total de produto para uma área
  double calculateTotalProductAmount(double dosePerHa, double totalArea) {
    return _calculator.calculatePesticideQuantity(
      areaHectares: totalArea,
      ratePerHectare: dosePerHa,
      concentration: 100.0,
    );
  }
  
  /// Calcula a taxa de aplicação com base na vazão do bico, espaçamento e velocidade
  double calculateApplicationRate(double flowRate, double nozzleSpacing, double speed) {
    return _calculator.calculateApplicationRate(
      flowRate: flowRate,
      nozzleSpacing: nozzleSpacing,
      speed: speed,
    );
  }
  
  /// Calcula a quantidade de produto por tanque
  double calculateProductPerTank(double dosePerHa, double tankCapacity, double applicationRate) {
    return _calculator.calculateProductPerTank(
      dosePerHectare: dosePerHa,
      tankCapacity: tankCapacity,
      applicationRate: applicationRate,
    );
  }
  
  /// Calcula o número de tanques necessários para uma área
  double calculateNumberOfTanks(double areaHectares, double tankCapacity, double applicationRate) {
    return _calculator.calculateNumberOfTanks(
      areaHectares: areaHectares,
      tankCapacity: tankCapacity,
      applicationRate: applicationRate,
    );
  }
  
  /// Verifica se as condições climáticas são adequadas para aplicação
  bool areWeatherConditionsSuitableForApplication(double temperature, double humidity, double windSpeed) {
    // Condições ideais para aplicação:
    // - Temperatura: entre 10°C e 30°C
    // - Umidade relativa: acima de 55%
    // - Velocidade do vento: entre 3 km/h e 10 km/h
    
    bool isTemperatureSuitable = temperature >= 10 && temperature <= 30;
    bool isHumiditySuitable = humidity >= 55;
    bool isWindSpeedSuitable = windSpeed >= 3 && windSpeed <= 10;
    
    return isTemperatureSuitable && isHumiditySuitable && isWindSpeedSuitable;
  }
  
  /// Avalia o risco de deriva com base nas condições climáticas
  String evaluateDriftRisk(double temperature, double humidity, double windSpeed) {
    // Fatores de risco:
    // - Temperatura alta (> 30°C)
    // - Umidade baixa (< 55%)
    // - Vento forte (> 10 km/h)
    
    int riskFactors = 0;
    
    if (temperature > 30) riskFactors++;
    if (humidity < 55) riskFactors++;
    if (windSpeed > 10) riskFactors++;
    
    if (riskFactors == 0) return 'Baixo';
    if (riskFactors == 1) return 'Médio';
    return 'Alto';
  }
  
  /// Calcula o intervalo de segurança para reentrada na área
  int calculateReentryInterval(String productType, double dosePerHa) {
    // Valores em horas
    if (productType.toLowerCase().contains('herbicida')) {
      return dosePerHa > 2.0 ? 48 : 24;
    } else if (productType.toLowerCase().contains('inseticida')) {
      return dosePerHa > 1.0 ? 72 : 48;
    } else if (productType.toLowerCase().contains('fungicida')) {
      return dosePerHa > 1.5 ? 48 : 24;
    } else {
      return 24; // Valor padrão para outros tipos
    }
  }
  
  /// Calcula o intervalo de segurança para colheita
  int calculateHarvestSafetyInterval(String productType) {
    // Valores em dias (exemplos genéricos, devem ser ajustados conforme bula do produto)
    if (productType.toLowerCase().contains('herbicida')) {
      return 30;
    } else if (productType.toLowerCase().contains('inseticida')) {
      return 21;
    } else if (productType.toLowerCase().contains('fungicida')) {
      return 14;
    } else {
      return 21; // Valor padrão para outros tipos
    }
  }
  
  /// Calcula a eficiência da aplicação com base nas condições
  double calculateApplicationEfficiency(double temperature, double humidity, double windSpeed) {
    // Base de eficiência: 100%
    double efficiency = 100.0;
    
    // Redução por temperatura inadequada
    if (temperature < 10) {
      efficiency -= 10 + (10 - temperature) * 2;
    } else if (temperature > 30) {
      efficiency -= 10 + (temperature - 30) * 3;
    }
    
    // Redução por umidade inadequada
    if (humidity < 55) {
      efficiency -= 10 + (55 - humidity) * 0.5;
    }
    
    // Redução por vento inadequado
    if (windSpeed < 3) {
      efficiency -= 5;
    } else if (windSpeed > 10) {
      efficiency -= 10 + (windSpeed - 10) * 5;
    }
    
    // Garantir que a eficiência não seja negativa
    return efficiency > 0 ? efficiency : 0;
  }
  
  /// Calcula a cobertura de gotas por cm²
  double calculateDropletCoverage(double flowRate, double speed, double nozzleSpacing, int dropletSize) {
    // Estimativa simplificada da cobertura de gotas por cm²
    // flowRate: L/min
    // speed: km/h
    // nozzleSpacing: m
    // dropletSize: diâmetro médio das gotas em micrômetros
    
    // Converter velocidade para m/min
    final double speedMPerMin = (speed * 1000) / 60;
    
    // Calcular volume aplicado por m²
    final double volumePerSqm = (flowRate / (speedMPerMin * nozzleSpacing)) * 1000; // mL/m²
    
    // Estimar número de gotas por cm² com base no volume e tamanho da gota
    // Volume de uma gota = (4/3) * π * (diâmetro/2)³
    final double dropletVolumeMl = (4/3) * 3.14159 * pow(dropletSize / 2000, 3);
    
    // Gotas por mL
    final double dropsPerMl = 1 / dropletVolumeMl;
    
    // Gotas por cm²
    return (volumePerSqm * dropsPerMl) / 10000;
  }
  
  /// Função auxiliar para cálculo de potência
  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
