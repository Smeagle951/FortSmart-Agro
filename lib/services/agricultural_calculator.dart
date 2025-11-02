import 'dart:math';

/// Serviço para cálculos técnicos agrícolas
class AgriculturalCalculator {
  static final AgriculturalCalculator _instance = AgriculturalCalculator._internal();
  
  factory AgriculturalCalculator() {
    return _instance;
  }
  
  AgriculturalCalculator._internal();
  
  /// Calcula a quantidade de sementes necessárias para uma área
  /// 
  /// [areaHectares] - Área em hectares
  /// [seedsPerHectare] - Quantidade de sementes por hectare
  /// [germinationRate] - Taxa de germinação (0-100%)
  /// Retorna a quantidade de sementes em kg
  double calculateSeedQuantity({
    required double areaHectares,
    required double seedsPerHectare,
    double germinationRate = 100.0,
  }) {
    // Ajustar para a taxa de germinação
    final adjustedSeedsPerHectare = seedsPerHectare * (100.0 / germinationRate);
    return areaHectares * adjustedSeedsPerHectare;
  }
  
  /// Calcula a quantidade de fertilizante necessária para uma área
  /// 
  /// [areaHectares] - Área em hectares
  /// [ratePerHectare] - Taxa de aplicação por hectare (kg/ha)
  /// Retorna a quantidade de fertilizante em kg
  double calculateFertilizerQuantity({
    required double areaHectares,
    required double ratePerHectare,
  }) {
    return areaHectares * ratePerHectare;
  }
  
  /// Calcula a quantidade de defensivo necessária para uma área
  /// 
  /// [areaHectares] - Área em hectares
  /// [ratePerHectare] - Taxa de aplicação por hectare (L/ha)
  /// [concentration] - Concentração do produto (%)
  /// Retorna a quantidade de defensivo em litros
  double calculatePesticideQuantity({
    required double areaHectares,
    required double ratePerHectare,
    double concentration = 100.0,
  }) {
    return areaHectares * ratePerHectare * (concentration / 100.0);
  }
  
  /// Calcula o volume de calda para aplicação
  /// 
  /// [areaHectares] - Área em hectares
  /// [applicationRate] - Taxa de aplicação (L/ha)
  /// Retorna o volume total de calda em litros
  double calculateSprayVolume({
    required double areaHectares,
    required double applicationRate,
  }) {
    return areaHectares * applicationRate;
  }
  
  /// Calcula a área de um polígono usando o algoritmo Shoelace (Gauss's area formula)
  /// 
  /// [coordinates] - Lista de coordenadas (latitude, longitude) que formam o polígono
  /// Retorna a área em metros quadrados
  double calculatePolygonArea(List<Map<String, double>> coordinates) {
    if (coordinates.length < 3) {
      return 0.0;
    }
    
    double area = 0.0;
    
    for (int i = 0; i < coordinates.length; i++) {
      int j = (i + 1) % coordinates.length;
      
      // Converter para coordenadas UTM ou usar a fórmula de Haversine para maior precisão
      // Aqui usamos uma aproximação simplificada
      area += coordinates[i]['longitude']! * coordinates[j]['latitude']!;
      area -= coordinates[j]['longitude']! * coordinates[i]['latitude']!;
    }
    
    area = (area.abs() / 2.0);
    
    // Converter para metros quadrados (aproximação)
    // Esta é uma aproximação grosseira e deve ser substituída por um cálculo mais preciso
    const double degreesToMeters = 111319.9; // Aproximadamente 111.32 km por grau no equador
    return area * degreesToMeters * degreesToMeters;
  }
  
  /// Calcula a área em hectares
  /// 
  /// [areaSquareMeters] - Área em metros quadrados
  /// Retorna a área em hectares
  double squareMetersToHectares(double areaSquareMeters) {
    return areaSquareMeters / 10000.0;
  }
  
  /// Calcula a distância entre dois pontos usando a fórmula de Haversine
  /// 
  /// [lat1], [lon1] - Coordenadas do primeiro ponto
  /// [lat2], [lon2] - Coordenadas do segundo ponto
  /// Retorna a distância em metros
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Raio da Terra em metros
    
    // Converter graus para radianos
    final double lat1Rad = lat1 * (pi / 180);
    final double lon1Rad = lon1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double lon2Rad = lon2 * (pi / 180);
    
    // Diferença de coordenadas
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    
    // Fórmula de Haversine
    final double a = sin(dLat / 2) * sin(dLat / 2) +
                     cos(lat1Rad) * cos(lat2Rad) *
                     sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Calcula o perímetro de um polígono
  /// 
  /// [coordinates] - Lista de coordenadas (latitude, longitude) que formam o polígono
  /// Retorna o perímetro em metros
  double calculatePerimeter(List<Map<String, double>> coordinates) {
    if (coordinates.length < 2) {
      return 0.0;
    }
    
    double perimeter = 0.0;
    
    for (int i = 0; i < coordinates.length; i++) {
      int j = (i + 1) % coordinates.length;
      
      perimeter += calculateDistance(
        coordinates[i]['latitude']!,
        coordinates[i]['longitude']!,
        coordinates[j]['latitude']!,
        coordinates[j]['longitude']!
      );
    }
    
    return perimeter;
  }
  
  /// Calcula a produtividade estimada
  /// 
  /// [areaHectares] - Área em hectares
  /// [totalProduction] - Produção total em kg
  /// Retorna a produtividade em kg/ha
  double calculateYield({
    required double areaHectares,
    required double totalProduction,
  }) {
    if (areaHectares <= 0) {
      return 0.0;
    }
    return totalProduction / areaHectares;
  }
  
  /// Calcula a quantidade de água necessária para irrigação
  /// 
  /// [areaHectares] - Área em hectares
  /// [depthMm] - Lâmina de irrigação em mm
  /// Retorna o volume de água em metros cúbicos
  double calculateIrrigationWater({
    required double areaHectares,
    required double depthMm,
  }) {
    // 1 mm em 1 ha = 10 m³
    return areaHectares * depthMm * 10;
  }
  
  /// Calcula o índice de vegetação (NDVI simplificado)
  /// 
  /// [nir] - Valor de reflectância no infravermelho próximo
  /// [red] - Valor de reflectância no vermelho
  /// Retorna o valor do NDVI (-1 a 1)
  double calculateNDVI({
    required double nir,
    required double red,
  }) {
    if (nir + red == 0) {
      return 0.0;
    }
    return (nir - red) / (nir + red);
  }
  
  /// Converte coordenadas de graus decimais para graus, minutos e segundos
  /// 
  /// [decimalDegrees] - Coordenada em graus decimais
  /// Retorna um mapa com graus, minutos e segundos
  Map<String, dynamic> decimalDegreesToDMS(double decimalDegrees) {
    final degrees = decimalDegrees.floor();
    final minutesDecimal = (decimalDegrees - degrees) * 60;
    final minutes = minutesDecimal.floor();
    final seconds = ((minutesDecimal - minutes) * 60).toStringAsFixed(2);
    
    return {
      'degrees': degrees,
      'minutes': minutes,
      'seconds': double.parse(seconds),
    };
  }
  
  /// Interpreta o valor de pH do solo
  /// 
  /// [ph] - Valor de pH do solo
  /// Retorna a interpretação do pH
  String interpretSoilPh(double ph) {
    if (ph < 4.5) return 'Extremamente ácido';
    if (ph < 5.0) return 'Muito ácido';
    if (ph < 5.5) return 'Fortemente ácido';
    if (ph < 6.0) return 'Moderadamente ácido';
    if (ph < 6.5) return 'Levemente ácido';
    if (ph < 7.3) return 'Neutro';
    if (ph < 7.8) return 'Levemente alcalino';
    if (ph < 8.5) return 'Moderadamente alcalino';
    if (ph < 9.0) return 'Fortemente alcalino';
    return 'Extremamente alcalino';
  }
  
  /// Interpreta o valor de matéria orgânica do solo
  /// 
  /// [organicMatter] - Valor de matéria orgânica em %
  /// Retorna a interpretação da matéria orgânica
  String interpretOrganicMatter(double organicMatter) {
    if (organicMatter < 0.8) return 'Muito baixo';
    if (organicMatter < 1.5) return 'Baixo';
    if (organicMatter < 3.0) return 'Médio';
    if (organicMatter < 5.0) return 'Alto';
    return 'Muito alto';
  }
  
  /// Interpreta o valor de fósforo do solo
  /// 
  /// [phosphorus] - Valor de fósforo em mg/dm³
  /// [soilType] - Tipo de solo (argiloso, médio, arenoso)
  /// Retorna a interpretação do fósforo
  String interpretPhosphorus(double phosphorus, String soilType) {
    switch (soilType.toLowerCase()) {
      case 'argiloso':
        if (phosphorus < 3.0) return 'Muito baixo';
        if (phosphorus < 6.0) return 'Baixo';
        if (phosphorus < 9.0) return 'Médio';
        if (phosphorus < 12.0) return 'Alto';
        return 'Muito alto';
      case 'médio':
        if (phosphorus < 5.0) return 'Muito baixo';
        if (phosphorus < 10.0) return 'Baixo';
        if (phosphorus < 15.0) return 'Médio';
        if (phosphorus < 20.0) return 'Alto';
        return 'Muito alto';
      case 'arenoso':
        if (phosphorus < 6.0) return 'Muito baixo';
        if (phosphorus < 12.0) return 'Baixo';
        if (phosphorus < 20.0) return 'Médio';
        if (phosphorus < 30.0) return 'Alto';
        return 'Muito alto';
      default:
        if (phosphorus < 5.0) return 'Muito baixo';
        if (phosphorus < 10.0) return 'Baixo';
        if (phosphorus < 15.0) return 'Médio';
        if (phosphorus < 20.0) return 'Alto';
        return 'Muito alto';
    }
  }
  
  /// Interpreta o valor de potássio do solo
  /// 
  /// [potassium] - Valor de potássio em mmolc/dm³
  /// Retorna a interpretação do potássio
  String interpretPotassium(double potassium) {
    if (potassium < 0.8) return 'Muito baixo';
    if (potassium < 1.5) return 'Baixo';
    if (potassium < 3.0) return 'Médio';
    if (potassium < 6.0) return 'Alto';
    return 'Muito alto';
  }
  
  /// Calcula a necessidade de calagem pelo método da saturação por bases
  /// 
  /// [currentBasesSaturation] - Saturação por bases atual (%)
  /// [targetBasesSaturation] - Saturação por bases desejada (%)
  /// [cec] - Capacidade de troca catiônica (CTC) em cmolc/dm³
  /// [limePurity] - Pureza do calcário (%)
  /// [limeReactivity] - Reatividade do calcário (%)
  /// Retorna a quantidade de calcário em t/ha
  double calculateLimeRequirementWithTarget({
    required double currentBasesSaturation,
    required double targetBasesSaturation,
    required double cec,
    double limePurity = 100.0,
    double limeReactivity = 100.0,
  }) {
    if (currentBasesSaturation >= targetBasesSaturation) {
      return 0.0;
    }
    
    // Fórmula: NC = (V2 - V1) × CTC × f / PRNT
    // onde f = 100/100 = 1 para expressar em t/ha
    final double prnt = (limePurity * limeReactivity) / 100.0;
    return (targetBasesSaturation - currentBasesSaturation) * cec * 0.01 / (prnt / 100.0);
  }
  
  /// Calcula a quantidade de nutriente a ser aplicada com base na análise de solo
  /// 
  /// [currentLevel] - Nível atual do nutriente no solo
  /// [targetLevel] - Nível desejado do nutriente
  /// [nutrientConcentration] - Concentração do nutriente no fertilizante (%)
  /// [areaHectares] - Área em hectares
  /// Retorna a quantidade de fertilizante em kg
  double calculateNutrientRequirement({
    required double currentLevel,
    required double targetLevel,
    required double nutrientConcentration,
    required double areaHectares,
  }) {
    if (currentLevel >= targetLevel) {
      return 0.0;
    }
    
    final double deficiency = targetLevel - currentLevel;
    final double nutrientNeeded = deficiency * 2; // Fator de conversão aproximado
    
    // Quantidade de fertilizante = (nutriente necessário * 100 / concentração) * área
    return (nutrientNeeded * 100.0 / nutrientConcentration) * areaHectares;
  }
  
  /// Calcula a dosagem de produto por tanque
  /// 
  /// [dosePerHectare] - Dose do produto por hectare
  /// [tankCapacity] - Capacidade do tanque em litros
  /// [applicationRate] - Taxa de aplicação em L/ha
  /// Retorna a quantidade de produto por tanque
  double calculateProductPerTank({
    required double dosePerHectare,
    required double tankCapacity,
    required double applicationRate,
  }) {
    // Área que um tanque cobre = capacidade do tanque / taxa de aplicação
    final double areaCoveredByTank = tankCapacity / applicationRate;
    
    // Quantidade de produto = dose por hectare * área coberta pelo tanque
    return dosePerHectare * areaCoveredByTank;
  }
  
  /// Calcula o número de tanques necessários para uma área
  /// 
  /// [areaHectares] - Área em hectares
  /// [tankCapacity] - Capacidade do tanque em litros
  /// [applicationRate] - Taxa de aplicação em L/ha
  /// Retorna o número de tanques necessários
  double calculateNumberOfTanks({
    required double areaHectares,
    required double tankCapacity,
    required double applicationRate,
  }) {
    // Volume total necessário = área * taxa de aplicação
    final double totalVolumeNeeded = areaHectares * applicationRate;
    
    // Número de tanques = volume total / capacidade do tanque
    return totalVolumeNeeded / tankCapacity;
  }
  
  /// Calcula a necessidade de calagem com base no pH, CTC e saturação por bases
  /// 
  /// [currentPH] - pH atual do solo
  /// [cec] - Capacidade de troca catiônica (CTC) em cmolc/dm³
  /// [baseSaturation] - Saturação por bases atual (%)
  /// Retorna a quantidade de calcário em toneladas por hectare
  double calculateLimeRequirement(
    double currentPH,
    double cec,
    double baseSaturation,
  ) {
    // Saturação por bases desejada com base no pH atual
    double targetBS = 70.0;
    if (currentPH < 5.0) targetBS = 60.0;
    if (currentPH > 6.0) targetBS = 80.0;
    
    return calculateLimeRequirementWithTarget(
      currentBasesSaturation: baseSaturation,
      targetBasesSaturation: targetBS,
      cec: cec,
    );
  }
  
  /// Calcula a necessidade de fósforo com base na análise de solo
  /// 
  /// [currentP] - Teor atual de fósforo no solo (mg/dm³)
  /// [clayContent] - Teor de argila no solo (%)
  /// Retorna a quantidade de P2O5 em kg por hectare
  double calculatePhosphorusRequirement(
    double currentP,
    double clayContent,
  ) {
    // Definir o nível crítico com base no teor de argila
    double criticalLevel = 12.0;
    if (clayContent > 60) criticalLevel = 8.0;
    else if (clayContent > 40) criticalLevel = 10.0;
    
    // Calcular a necessidade de P2O5
    double pRequirement = 0.0;
    if (currentP < criticalLevel) {
      // Quanto maior a diferença, maior a necessidade
      pRequirement = (criticalLevel - currentP) * 10.0;
      
      // Adicionar dose de manutenção
      pRequirement += 40.0;
    } else {
      // Apenas dose de manutenção
      pRequirement = 40.0;
    }
    
    return double.parse(pRequirement.toStringAsFixed(2));
  }
  
  /// Calcula a necessidade de potássio com base na análise de solo
  /// 
  /// [currentK] - Teor atual de potássio no solo (cmolc/dm³)
  /// [cec] - Capacidade de troca catiônica (CTC) em cmolc/dm³
  /// Retorna a quantidade de K2O em kg por hectare
  double calculatePotassiumRequirement(
    double currentK,
    double cec,
  ) {
    // Definir o nível crítico com base na CTC
    double criticalLevel = 0.15;
    if (cec > 15) criticalLevel = 0.25;
    else if (cec > 10) criticalLevel = 0.20;
    
    // Calcular a necessidade de K2O
    double kRequirement = 0.0;
    if (currentK < criticalLevel) {
      // Quanto maior a diferença, maior a necessidade
      kRequirement = (criticalLevel - currentK) * 400.0;
      
      // Adicionar dose de manutenção
      kRequirement += 60.0;
    } else {
      // Apenas dose de manutenção
      kRequirement = 60.0;
    }
    
    return double.parse(kRequirement.toStringAsFixed(2));
  }
  
  /// Interpreta o valor de saturação por bases do solo
  /// 
  /// [baseSaturation] - Valor de saturação por bases em %
  /// Retorna a interpretação da saturação por bases
  String interpretBaseSaturation(double baseSaturation) {
    if (baseSaturation < 20) return 'Muito baixa';
    if (baseSaturation < 40) return 'Baixa';
    if (baseSaturation < 60) return 'Média';
    if (baseSaturation < 80) return 'Alta';
    return 'Muito alta';
  }
  
  /// Calcula a perda de grãos na colheita em kg/ha
  /// 
  /// [grainsPerSqm] - Número de grãos por metro quadrado
  /// [thousandGrainWeight] - Peso de mil grãos em gramas
  /// Retorna a perda em kg/ha
  double calculateHarvestLoss({
    required double grainsPerSqm,
    required double thousandGrainWeight,
  }) {
    // Converter o peso de mil grãos para peso por grão em gramas
    final double grainWeightGrams = thousandGrainWeight / 1000;
    
    // Calcular o peso dos grãos por metro quadrado em gramas
    final double weightPerSqmGrams = grainsPerSqm * grainWeightGrams;
    
    // Converter para kg/ha (1 ha = 10.000 m²)
    return weightPerSqmGrams * 10;
  }
  
  /// Calcula a perda financeira na colheita
  /// 
  /// [lossKgPerHa] - Perda em kg/ha
  /// [pricePerKg] - Preço por kg do produto
  /// [totalArea] - Área total em hectares
  /// Retorna o valor da perda em reais
  double calculateHarvestFinancialLoss({
    required double lossKgPerHa,
    required double pricePerKg,
    required double totalArea,
  }) {
    return lossKgPerHa * pricePerKg * totalArea;
  }
  
  /// Calcula a calibração de semeadora/plantadeira
  /// 
  /// [desiredPlants] - Número desejado de plantas por metro
  /// [rowSpacing] - Espaçamento entre linhas em metros
  /// [germinationRate] - Taxa de germinação das sementes (0-100%)
  /// [viabilityFactor] - Fator de viabilidade (0-100%)
  /// Retorna o número de sementes a serem distribuídas por metro
  double calculatePlanterCalibration({
    required double desiredPlants,
    required double rowSpacing,
    double germinationRate = 90.0,
    double viabilityFactor = 90.0,
  }) {
    // Ajustar para a taxa de germinação e fator de viabilidade
    return desiredPlants * (100 / germinationRate) * (100 / viabilityFactor);
  }
  
  /// Calcula a população de plantas por hectare
  /// 
  /// [plantsPerMeter] - Número de plantas por metro
  /// [rowSpacing] - Espaçamento entre linhas em metros
  /// Retorna o número de plantas por hectare
  double calculatePlantPopulation({
    required double plantsPerMeter,
    required double rowSpacing,
  }) {
    // 10000 m² (1 hectare) / espaçamento = metros lineares por hectare
    final double linearMetersPerHa = 10000 / rowSpacing;
    return plantsPerMeter * linearMetersPerHa;
  }
  
  /// Calcula a velocidade ideal de plantio
  /// 
  /// [desiredSeedsPerHa] - Número desejado de sementes por hectare
  /// [discHoles] - Número de furos no disco de sementes
  /// [rowSpacing] - Espaçamento entre linhas em metros
  /// [discRpm] - Rotações por minuto do disco de sementes
  /// Retorna a velocidade em km/h
  double calculatePlantingSpeed({
    required double desiredSeedsPerHa,
    required int discHoles,
    required double rowSpacing,
    required double discRpm,
  }) {
    // Calcular sementes por metro
    final double seedsPerMeter = (desiredSeedsPerHa * rowSpacing) / 10000;
    
    // Calcular metros por minuto
    final double metersPerMinute = (discRpm * discHoles) / seedsPerMeter;
    
    // Converter para km/h
    return (metersPerMinute * 60) / 1000;
  }
  
  /// Calcula a taxa de aplicação de defensivos
  /// 
  /// [flowRate] - Vazão do bico em L/min
  /// [nozzleSpacing] - Espaçamento entre bicos em metros
  /// [speed] - Velocidade de aplicação em km/h
  /// Retorna a taxa de aplicação em L/ha
  double calculateApplicationRate({
    required double flowRate,
    required double nozzleSpacing,
    required double speed,
  }) {
    // Converter velocidade para m/min
    final double speedMPerMin = (speed * 1000) / 60;
    
    // Calcular área coberta por minuto (m²/min)
    final double areaCoveredPerMin = speedMPerMin * nozzleSpacing;
    
    // Calcular taxa de aplicação (L/ha)
    return (flowRate / areaCoveredPerMin) * 10000;
  }
  
  /// Calcula a quantidade de produto necessária para um tanque
  /// 
  /// [tankVolume] - Volume do tanque em litros
  /// [dosePerHa] - Dose do produto por hectare
  /// [applicationRate] - Taxa de aplicação em L/ha
  /// Retorna a quantidade de produto para o tanque
  double calculateProductQuantityForTank({
    required double tankVolume,
    required double dosePerHa,
    required double applicationRate,
  }) {
    // Calcular área coberta por tanque (ha)
    final double areaCoveredPerTank = tankVolume / applicationRate;
    
    // Calcular quantidade de produto
    return dosePerHa * areaCoveredPerTank;
  }
  
  /// Calcula o número de plantas por amostra para monitoramento
  /// 
  /// [totalArea] - Área total em hectares
  /// [samplesPerHa] - Número de amostras por hectare
  /// [plantsPerSample] - Número de plantas por amostra
  /// Retorna o número total de plantas a serem amostradas
  int calculateMonitoringSampleSize({
    required double totalArea,
    required double samplesPerHa,
    required int plantsPerSample,
  }) {
    final int totalSamples = (totalArea * samplesPerHa).round();
    return totalSamples * plantsPerSample;
  }
}
