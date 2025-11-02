import 'dart:math';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo para calibração de distribuição de fertilizantes
/// Baseado no Guia Técnico FortSmart - Cálculo para Calibração de Fertilizantes (Distribuição Granulada)
class FertilizerCalibration {
  final String id;
  final String fertilizerName;
  final double granulometry; // g/L - Densidade do fertilizante
  final double? expectedWidth; // m - Faixa esperada (opcional)
  final double spacing; // m - Espaçamento entre linhas
  final List<double> weights; // g - Massa coletada por bandeja
  final String operator;
  
  // Campos técnicos da máquina (OBRIGATÓRIOS) - Guia Técnico FortSmart
  final String machine; // Hércules 6.0, Jacto Uniport 5030, etc
  final String distributionSystem; // Paletas rotativas, Z-atirador, etc
  final double smallPaddleValue; // mm - Paleta Pequena
  final double largePaddleValue; // mm - Paleta Grande
  final double rpm; // rpm - Giro dos Pratos
  final double speed; // km/h - Velocidade
  final double density; // g/L - Densidade (Granulometria)
  final double? distanceTraveled; // m - Distância Percorrida (opcional)
  final double? collectionTime; // s - Tempo de Coleta (opcional)
  final String collectionType; // 'distance' ou 'time'
  final double desiredRate; // kg/ha - Taxa Desejada
  
  final DateTime date;
  
  // Resultados calculados seguindo fórmulas científicas
  final double coefficientOfVariation; // CV% - Coeficiente de Variação
  final String cvStatus; // Excelente, Moderado, Ruim (baseado em ISO 5690)
  final double realWidth; // m - Faixa efetiva real calculada
  final String widthStatus; // OK, Incompleta
  final double averageWeight; // g - Média da massa coletada
  final double standardDeviation; // g - Desvio padrão
  final List<int> effectiveRangeIndices; // Índices das bandejas na faixa efetiva
  final double realApplicationRate; // Taxa real aplicada em kg/ha
  final String rateStatus; // OK, Alerta, Recalibrar
  final double errorPercentage; // Erro percentual entre taxa real e desejada
  final String errorStatus; // OK, Recalibrar
  
  FertilizerCalibration({
    String? id,
    required this.fertilizerName,
    required this.granulometry,
    required this.expectedWidth,
    required this.spacing,
    required this.weights,
    required this.operator,
    required this.machine,
    required this.distributionSystem,
    required this.smallPaddleValue,
    required this.largePaddleValue,
    required this.rpm,
    required this.speed,
    required this.density,
    this.distanceTraveled,
    this.collectionTime,
    required this.collectionType,
    required this.desiredRate,
    DateTime? date,
    double? coefficientOfVariation,
    String? cvStatus,
    double? realWidth,
    String? widthStatus,
    double? averageWeight,
    double? standardDeviation,
    List<int>? effectiveRangeIndices,
    double? realApplicationRate,
    String? rateStatus,
    double? errorPercentage,
    String? errorStatus,
  }) : 
    id = id ?? const Uuid().v4(),
    date = date ?? DateTime.now(),
    coefficientOfVariation = coefficientOfVariation ?? 0.0,
    cvStatus = cvStatus ?? '',
    realWidth = realWidth ?? 0.0,
    widthStatus = widthStatus ?? '',
    averageWeight = averageWeight ?? 0.0,
    standardDeviation = standardDeviation ?? 0.0,
    effectiveRangeIndices = effectiveRangeIndices ?? [],
    realApplicationRate = realApplicationRate ?? 0.0,
    rateStatus = rateStatus ?? '',
    errorPercentage = errorPercentage ?? 0.0,
    errorStatus = errorStatus ?? '';

  /// Calcula o coeficiente de variação (CV%) seguindo ISO 5690
  /// CV (%) = (Desvio Padrão / Média da Massa Coletada) × 100
  double calculateCV() {
    if (weights.isEmpty) return 0.0;
    
    final avg = weights.reduce((a, b) => a + b) / weights.length;
    final variance = weights.map((w) => (w - avg) * (w - avg))
        .reduce((a, b) => a + b) / (weights.length - 1);
    final stdDev = sqrt(variance);
    
    return (stdDev / avg) * 100;
  }
  
  /// Calcula a taxa real aplicada em kg/ha seguindo fórmula científica
  /// Taxa Real (kg/ha) = (Massa Total Coletada (g) × 10) / (Número de Bandejas × Largura da Bandeja (m) × Distância Percorrida (m))
  double calculateRealApplicationRate() {
    if (weights.isEmpty) return 0.0;
    
    // Verificar se temos distância percorrida
    if (distanceTraveled == null || distanceTraveled! <= 0) return 0.0;
    
    // Calcular massa total coletada em gramas
    final totalMassGrams = weights.reduce((a, b) => a + b);
    
    // Largura da bandeja (assumindo 0.5m por bandeja - padrão técnico)
    final bandejaWidth = 0.5; // m - Largura de cada bandeja
    
    // Número de bandejas com massa válida (> 0)
    final validBandejas = weights.where((w) => w > 0).length;
    
    if (validBandejas == 0) return 0.0;
    
    // Aplicar fórmula científica corrigida
    // Taxa Real (kg/ha) = (Massa Total (g) × 10) / (N × Largura Bandeja (m) × Distância (m))
    final taxaReal = (totalMassGrams * 10.0) / (validBandejas * bandejaWidth * distanceTraveled!);
    
    return taxaReal;
  }
  
  /// Calcula a área percorrida em hectares baseada na largura das bandejas
  /// Para coleta por distância: A = (D × Largura Total das Bandejas) / 10.000
  /// Para coleta por tempo: A = (V × T × Largura Total das Bandejas) / 10.000
  double _calculateArea() {
    // Largura total das bandejas (assumindo 0.5m por bandeja)
    final bandejaWidth = 0.5; // m - Largura de cada bandeja
    final totalWidth = weights.length * bandejaWidth;
    
    double distance;
    
    if (collectionType == 'distance') {
      // Coleta por distância
      if (distanceTraveled == null || distanceTraveled! <= 0) {
        throw ArgumentError('Distância percorrida deve ser informada e maior que zero');
      }
      distance = distanceTraveled!;
    } else {
      // Coleta por tempo
      if (collectionTime == null || collectionTime! <= 0) {
        throw ArgumentError('Tempo de coleta deve ser informado e maior que zero');
      }
      // Converter velocidade de km/h para m/s e calcular distância
      final speedMs = speed / 3.6; // km/h para m/s
      distance = speedMs * collectionTime!; // m/s × s = m
    }
    
    return (distance * totalWidth) / 10000.0; // Converter para hectares
  }
  
  /// Calcula a média dos pesos coletados
  double calculateAverageWeight() {
    if (weights.isEmpty) return 0.0;
    return weights.reduce((a, b) => a + b) / weights.length;
  }
  
  /// Calcula o desvio padrão dos pesos
  double calculateStandardDeviation() {
    if (weights.length < 2) return 0.0;
    
    final avg = calculateAverageWeight();
    final variance = weights.map((w) => (w - avg) * (w - avg))
        .reduce((a, b) => a + b) / (weights.length - 1);
    
    return sqrt(variance);
  }
  
  /// Calcula o erro percentual entre taxa real e desejada
  double calculateErrorPercentage() {
    if (desiredRate <= 0) return 0.0;
    
    final realRate = calculateRealApplicationRate();
    return ((realRate - desiredRate) / desiredRate) * 100;
  }
  
  /// Calcula as taxas por bandeja em kg/ha
  /// T_i = (peso_i em kg) / (área por bandeja)
  List<double> calculateTrayRates() {
    if (weights.isEmpty) return [];
    
    final area = _calculateArea();
    if (area <= 0) return [];
    
    final n = weights.length;
    final areaPerTray = area / n;
    
    return weights.map((weightGrams) {
      final weightKg = weightGrams / 1000.0;
      return weightKg / areaPerTray;
    }).toList();
  }
  
  /// Calcula a média das taxas por bandeja
  double calculateMeanTrayRate() {
    final trayRates = calculateTrayRates();
    if (trayRates.isEmpty) return 0.0;
    return trayRates.reduce((a, b) => a + b) / trayRates.length;
  }
  
  /// Calcula o desvio padrão das taxas por bandeja
  double calculateStandardDeviationTrayRates() {
    final trayRates = calculateTrayRates();
    if (trayRates.length < 2) return 0.0;
    
    final mean = calculateMeanTrayRate();
    final variance = trayRates.map((t) => (t - mean) * (t - mean))
        .reduce((a, b) => a + b) / (trayRates.length - 1);
    
    return sqrt(variance);
  }
  
  /// Calcula o CV% baseado nas taxas por bandeja (mais preciso)
  double calculateCVFromTrayRates() {
    final trayRates = calculateTrayRates();
    if (trayRates.isEmpty) return 0.0;
    
    final mean = calculateMeanTrayRate();
    if (mean == 0) return 0.0;
    
    final std = calculateStandardDeviationTrayRates();
    return (std / mean) * 100;
  }
  
  /// Calcula o fator de ajuste recomendado
  double calculateAdjustmentFactor() {
    if (desiredRate <= 0) return 1.0;
    
    final realRate = calculateRealApplicationRate();
    if (realRate == 0) return 1.0;
    
    return desiredRate / realRate;
  }
  
  /// Calcula o percentual de ajuste recomendado
  double calculateAdjustmentPercentage() {
    final factor = calculateAdjustmentFactor();
    return (factor - 1.0) * 100.0; // positivo = aumentar, negativo = reduzir
  }





  /// Determina o status do CV baseado em classificação agronômica
  /// < 10%: Excelente | 10-20%: Moderado | > 20%: Ruim
  String getCVStatus(double cv) {
    if (cv < 10) return 'Excelente';
    if (cv <= 20) return 'Moderado';
    return 'Ruim';
  }

  /// Calcula a faixa efetiva real usando fórmula empírica
  /// Faixa Efetiva = k × PaletaG × √RPM × Densidade^n
  /// Onde k e n são coeficientes ajustados por testes de campo
  double calculateRealWidth() {
    if (weights.isEmpty) return 0.0;
    
    // Coeficientes empíricos baseados em testes de campo
    const double k = 0.0015; // Coeficiente de ajuste
    const double n = 0.3; // Expoente da densidade
    
    // Usar paleta grande para cálculo da faixa efetiva
    final paletaValue = largePaddleValue;
    
    // Fórmula empírica para estimar faixa efetiva
    final estimatedWidth = k * paletaValue * sqrt(rpm) * pow(granulometry, n);
    
    // Validar com base nos pesos coletados
    // Se a faixa estimada for muito diferente da esperada, ajustar
    if (expectedWidth != null && expectedWidth! > 0) {
      final ratio = estimatedWidth / expectedWidth!;
      if (ratio < 0.7 || ratio > 1.3) {
        // Ajustar baseado na distribuição real dos pesos
        return _calculateWidthFromWeights();
      }
    }
    
    return estimatedWidth;
  }

  /// Calcula a faixa efetiva baseada na distribuição real dos pesos
  double _calculateWidthFromWeights() {
    if (weights.isEmpty) return 0.0;
    
    // Identificar bandejas com peso significativo (> 10% da média)
    final avgWeight = weights.reduce((a, b) => a + b) / weights.length;
    final threshold = avgWeight * 0.1;
    
    int effectiveBandejas = 0;
    for (final weight in weights) {
      if (weight > threshold) {
        effectiveBandejas++;
      }
    }
    
    // Assumir que cada bandeja representa 0.5m de largura
    return effectiveBandejas * 0.5;
  }



  /// Determina o status do erro
  /// Se erro absoluto > 5%, sugerir recalibragem
  String getErrorStatus(double error) {
    if (error.abs() <= 5) return 'OK';
    return 'Recalibrar';
  }

  /// Determina o status da taxa de aplicação
  String getRateStatus() {
    if (errorPercentage.abs() <= 5) return 'OK';
    if (errorPercentage.abs() <= 10) return 'Alerta';
    return 'Recalibrar';
  }



  /// Identifica as bandejas na faixa efetiva
  List<int> calculateEffectiveRangeIndices() {
    if (weights.isEmpty) return [];
    
    final avgWeight = calculateAverageWeight();
    final threshold = avgWeight * 0.1; // 10% da média
    
    final List<int> indices = [];
    for (int i = 0; i < weights.length; i++) {
      if (weights[i] > threshold) {
        indices.add(i);
      }
    }
    
    return indices;
  }

  /// Aplica todos os cálculos e retorna uma nova instância com resultados
  FertilizerCalibration withCalculations() {
    final avgWeight = calculateAverageWeight();
    final stdDev = calculateStandardDeviation();
    final cv = calculateCV();
    final cvStatus = getCVStatus(cv);
    final realWidth = calculateRealWidth();
    final realRate = calculateRealApplicationRate();
    final errorPercentage = calculateErrorPercentage();
    final errorStatus = getErrorStatus(errorPercentage);
    final rateStatus = getRateStatus();
    final effectiveIndices = calculateEffectiveRangeIndices();
    
    // Determinar status da faixa
    String widthStatus = 'OK';
    if (expectedWidth != null && expectedWidth! > 0) {
      final ratio = realWidth / expectedWidth!;
      if (ratio < 0.8 || ratio > 1.2) {
        widthStatus = 'Incompleta';
      }
    }
    
    return FertilizerCalibration(
      id: id,
      fertilizerName: fertilizerName,
      granulometry: granulometry,
      expectedWidth: expectedWidth,
      spacing: spacing,
      weights: weights,
      operator: operator,
      machine: machine,
      distributionSystem: distributionSystem,
      smallPaddleValue: smallPaddleValue,
      largePaddleValue: largePaddleValue,
      rpm: rpm,
      speed: speed,
      density: density,
      distanceTraveled: distanceTraveled,
      collectionTime: collectionTime,
      collectionType: collectionType,
      desiredRate: desiredRate,
      date: date,
      coefficientOfVariation: cv,
      cvStatus: cvStatus,
      realWidth: realWidth,
      widthStatus: widthStatus,
      averageWeight: avgWeight,
      standardDeviation: stdDev,
      effectiveRangeIndices: effectiveIndices,
      realApplicationRate: realRate,
      rateStatus: rateStatus,
      errorPercentage: errorPercentage,
      errorStatus: errorStatus,
    );
  }

  /// Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fertilizer_name': fertilizerName,
      'granulometry': granulometry,
      'expected_width': expectedWidth,
      'spacing': spacing,
      'weights': jsonEncode(weights), // Serializar List<double> como JSON
      'operator': operator,
      'machine': machine,
      'distribution_system': distributionSystem,
      'small_paddle_value': smallPaddleValue,
      'large_paddle_value': largePaddleValue,
      'rpm': rpm,
      'speed': speed,
      'density': density,
      'distance_traveled': distanceTraveled,
      'collection_time': collectionTime,
      'collection_type': collectionType,
      'desired_rate': desiredRate,
      'date': date.toIso8601String(),
      'coefficient_of_variation': coefficientOfVariation,
      'cv_status': cvStatus,
      'real_width': realWidth,
      'width_status': widthStatus,
      'average_weight': averageWeight,
      'standard_deviation': standardDeviation,
      'effective_range_indices': jsonEncode(effectiveRangeIndices), // Serializar List<int> como JSON
      'real_application_rate': realApplicationRate,
      'rate_status': rateStatus,
      'error_percentage': errorPercentage,
      'error_status': errorStatus,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Cria a partir de Map
  factory FertilizerCalibration.fromMap(Map<String, dynamic> map) {
    // Deserializar List<double> weights
    List<double> weights = [];
    if (map['weights'] != null) {
      if (map['weights'] is String) {
        // Se for string JSON, fazer parse
        try {
          final List<dynamic> raw = jsonDecode(map['weights']);
          weights = raw.map((e) => (e as num).toDouble()).toList();
        } catch (e) {
          print('Erro ao deserializar weights: $e');
          weights = [];
        }
      } else if (map['weights'] is List) {
        // Se for lista, converter diretamente
        weights = List<double>.from(map['weights']);
      }
    }

    // Deserializar List<int> effectiveRangeIndices
    List<int> effectiveRangeIndices = [];
    if (map['effective_range_indices'] != null) {
      if (map['effective_range_indices'] is String) {
        // Se for string JSON, fazer parse
        try {
          final List<dynamic> raw = jsonDecode(map['effective_range_indices']);
          effectiveRangeIndices = raw.map((e) => (e as num).toInt()).toList();
        } catch (e) {
          print('Erro ao deserializar effective_range_indices: $e');
          effectiveRangeIndices = [];
        }
      } else if (map['effective_range_indices'] is List) {
        // Se for lista, converter diretamente
        effectiveRangeIndices = List<int>.from(map['effective_range_indices']);
      }
    }

    return FertilizerCalibration(
      id: map['id'] ?? '',
      fertilizerName: map['fertilizer_name'] ?? '',
      granulometry: (map['granulometry'] ?? 0.0).toDouble(),
      expectedWidth: map['expected_width'] != null ? (map['expected_width'] as num).toDouble() : null,
      spacing: (map['spacing'] ?? 0.0).toDouble(),
      weights: weights,
      operator: map['operator'] ?? '',
      machine: map['machine'] ?? '',
      distributionSystem: map['distribution_system'] ?? '',
      smallPaddleValue: (map['small_paddle_value'] ?? 0.0).toDouble(),
      largePaddleValue: (map['large_paddle_value'] ?? 0.0).toDouble(),
      rpm: (map['rpm'] ?? 0.0).toDouble(),
      speed: (map['speed'] ?? 0.0).toDouble(),
      density: (map['density'] ?? 0.0).toDouble(),
      distanceTraveled: map['distance_traveled'] != null ? (map['distance_traveled'] as num).toDouble() : null,
      collectionTime: map['collection_time'] != null ? (map['collection_time'] as num).toDouble() : null,
      collectionType: map['collection_type'] ?? 'distance',
      desiredRate: (map['desired_rate'] ?? 0.0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      coefficientOfVariation: (map['coefficient_of_variation'] ?? 0.0).toDouble(),
      cvStatus: map['cv_status'] ?? '',
      realWidth: (map['real_width'] ?? 0.0).toDouble(),
      widthStatus: map['width_status'] ?? '',
      averageWeight: (map['average_weight'] ?? 0.0).toDouble(),
      standardDeviation: (map['standard_deviation'] ?? 0.0).toDouble(),
      effectiveRangeIndices: effectiveRangeIndices,
      realApplicationRate: (map['real_application_rate'] ?? 0.0).toDouble(),
      rateStatus: map['rate_status'] ?? '',
      errorPercentage: (map['error_percentage'] ?? 0.0).toDouble(),
      errorStatus: map['error_status'] ?? '',
    );
  }

  /// Cria uma cópia com novos valores
  FertilizerCalibration copyWith({
    String? id,
    String? fertilizerName,
    double? granulometry,
    double? expectedWidth,
    double? spacing,
    List<double>? weights,
    String? operator,
    String? machine,
    String? distributionSystem,
    double? smallPaddleValue,
    double? largePaddleValue,
    double? rpm,
    double? speed,
    double? density,
    double? distanceTraveled,
    double? collectionTime,
    String? collectionType,
    double? desiredRate,
    DateTime? date,
    double? coefficientOfVariation,
    String? cvStatus,
    double? realWidth,
    String? widthStatus,
    double? averageWeight,
    double? standardDeviation,
    List<int>? effectiveRangeIndices,
    double? realApplicationRate,
    String? rateStatus,
    double? errorPercentage,
    String? errorStatus,
  }) {
    return FertilizerCalibration(
      id: id ?? this.id,
      fertilizerName: fertilizerName ?? this.fertilizerName,
      granulometry: granulometry ?? this.granulometry,
      expectedWidth: expectedWidth ?? this.expectedWidth,
      spacing: spacing ?? this.spacing,
      weights: weights ?? this.weights,
      operator: operator ?? this.operator,
      machine: machine ?? this.machine,
      distributionSystem: distributionSystem ?? this.distributionSystem,
      smallPaddleValue: smallPaddleValue ?? this.smallPaddleValue,
      largePaddleValue: largePaddleValue ?? this.largePaddleValue,
      rpm: rpm ?? this.rpm,
      speed: speed ?? this.speed,
      density: density ?? this.density,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      collectionTime: collectionTime ?? this.collectionTime,
      collectionType: collectionType ?? this.collectionType,
      desiredRate: desiredRate ?? this.desiredRate,
      date: date ?? this.date,
      coefficientOfVariation: coefficientOfVariation ?? this.coefficientOfVariation,
      cvStatus: cvStatus ?? this.cvStatus,
      realWidth: realWidth ?? this.realWidth,
      widthStatus: widthStatus ?? this.widthStatus,
      averageWeight: averageWeight ?? this.averageWeight,
      standardDeviation: standardDeviation ?? this.standardDeviation,
      effectiveRangeIndices: effectiveRangeIndices ?? this.effectiveRangeIndices,
      realApplicationRate: realApplicationRate ?? this.realApplicationRate,
      rateStatus: rateStatus ?? this.rateStatus,
      errorPercentage: errorPercentage ?? this.errorPercentage,
      errorStatus: errorStatus ?? this.errorStatus,
    );
  }
} 