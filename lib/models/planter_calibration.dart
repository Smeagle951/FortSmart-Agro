import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo para representar uma calibragem de plantadeira (sementes + adubo)
class PlanterCalibration {
  final String id;
  final String name; // Nome da calibragem
  final String? plotId; // ID do talhão (opcional)
  final String cropId; // ID da cultura
  final String? variedadeId; // ID da variedade
  final String? machineId; // ID da máquina
  final String tipo; // 'semente' ou 'adubo'
  final double targetPopulation; // plantas/ha
  final double rowSpacing; // Espaçamento em cm
  final double? thousandSeedWeight; // Peso de mil sementes (g)
  final int planterRows; // Número de linhas da plantadeira
  final double workSpeed; // Velocidade de trabalho
  final double? drivingGear; // Engrenagem motora
  final double? drivenGear; // Engrenagem movida
  final double? wheelTurns; // Voltas da roda
  final int? seedDiscHoles; // Número de furos no disco
  final double? wheelCircumference; // Circunferência da roda
  final bool isAdvanced; // Se é calibragem avançada
  final String createdAt; // Data de criação
  final String? discType; // Tipo de disco
  final double? germinationRate; // Taxa de germinação
  final double? viabilityFactor; // Fator de viabilidade
  final String? responsiblePerson; // Pessoa responsável
  final String? observations; // Observações
  final String? fotos; // URLs das fotos separadas por vírgula
  final String dataRegulagem; // Data da regulagem

  // Getters para compatibilidade com código existente
  double get calibrationDistance => wheelTurns != null && wheelCircumference != null 
      ? wheelTurns! * (wheelCircumference! * 100) // Convertendo para cm
      : 0.0;
      
  int get seedsCount => seedDiscHoles ?? 0;
  
  String get notes => observations ?? '';

  // Getters para exibição na interface
  String? get cropName => null; // Será preenchido pelo repositório
  String? get planterName => null; // Será preenchido pelo repositório
  String? get plotName => null; // Será preenchido pelo repositório
  DateTime get calibrationDate => DateTime.tryParse(dataRegulagem) ?? DateTime.now();
  double get targetSeedRate => targetPopulation.toDouble(); // Taxa alvo em sementes/ha
  
  // Getters adicionais para relatórios
  double get seedsPerMeter => calculateSeedsPerMeter();
  double get estimatedPopulation => targetPopulation;
  
  // Getters adicionais para compatibilidade com FieldOperationsReportService
  String get machineName => machineId != null ? "Plantadeira $machineId" : "Plantadeira";
  
  // Novos getters para facilitar acesso aos dados
  double get relacaoEngrenagens => drivingGear != null && drivenGear != null ? 
      drivenGear! / drivingGear! : 0.0;
      
  String get tipoFormatado => tipo == 'semente' ? 'Sementes' : 'Adubo';
  String get responsible => responsiblePerson ?? '';
  double get desiredPlantsPerMeter => calculateSeedsPerMeter();
  // Getters que fornecem valores padrão para campos opcionais
  double get germinationRateValue => germinationRate ?? 95.0; // Valor padrão se não foi especificado
  double get viabilityFactorValue => viabilityFactor ?? 100.0; // Valor padrão se não foi especificado

  PlanterCalibration({
    String? id,
    required this.name,
    this.plotId,
    required this.cropId,
    this.variedadeId,
    this.machineId,
    required this.tipo,
    required this.targetPopulation,
    required this.rowSpacing,
    required this.planterRows,
    required this.workSpeed,
    this.thousandSeedWeight,
    this.drivingGear,
    this.drivenGear,
    this.wheelTurns,
    this.seedDiscHoles,
    this.wheelCircumference,
    this.isAdvanced = false,
    String? createdAt,
    String? dataRegulagem,
    this.discType,
    this.germinationRate,
    this.viabilityFactor,
    this.responsiblePerson,
    this.observations,
    this.fotos,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now().toIso8601String(),
    dataRegulagem = dataRegulagem ?? DateTime.now().toIso8601String();

  /// Cria uma cópia do objeto com os campos atualizados
  PlanterCalibration copyWith({
    String? id,
    String? name,
    String? plotId,
    String? cropId,
    String? variedadeId,
    String? machineId,
    String? tipo,
    double? targetPopulation,
    double? rowSpacing,
    double? thousandSeedWeight,
    int? planterRows,
    double? workSpeed,
    double? drivingGear,
    double? drivenGear,
    double? wheelTurns,
    int? seedDiscHoles,
    double? wheelCircumference,
    bool? isAdvanced,
    String? createdAt,
    String? dataRegulagem,
    String? discType,
    double? germinationRate,
    double? viabilityFactor,
    String? responsiblePerson,
    String? observations,
    String? fotos,
  }) {
    return PlanterCalibration(
      id: id ?? this.id,
      name: name ?? this.name,
      plotId: plotId ?? this.plotId,
      cropId: cropId ?? this.cropId,
      variedadeId: variedadeId ?? this.variedadeId,
      machineId: machineId ?? this.machineId,
      tipo: tipo ?? this.tipo,
      targetPopulation: targetPopulation ?? this.targetPopulation,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      planterRows: planterRows ?? this.planterRows,
      workSpeed: workSpeed ?? this.workSpeed,
      thousandSeedWeight: thousandSeedWeight ?? this.thousandSeedWeight,
      drivingGear: drivingGear ?? this.drivingGear,
      drivenGear: drivenGear ?? this.drivenGear,
      wheelTurns: wheelTurns ?? this.wheelTurns,
      seedDiscHoles: seedDiscHoles ?? this.seedDiscHoles,
      wheelCircumference: wheelCircumference ?? this.wheelCircumference,
      isAdvanced: isAdvanced ?? this.isAdvanced,
      createdAt: createdAt ?? this.createdAt,
      dataRegulagem: dataRegulagem ?? this.dataRegulagem,
      discType: discType ?? this.discType,
      germinationRate: germinationRate ?? this.germinationRate,
      viabilityFactor: viabilityFactor ?? this.viabilityFactor,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      observations: observations ?? this.observations,
      fotos: fotos ?? this.fotos,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plotId': plotId,
      'cropId': cropId,
      'variedadeId': variedadeId,
      'machineId': machineId,
      'tipo': tipo,
      'targetPopulation': targetPopulation,
      'rowSpacing': rowSpacing,
      'thousandSeedWeight': thousandSeedWeight,
      'planterRows': planterRows,
      'workSpeed': workSpeed,
      'drivingGear': drivingGear,
      'drivenGear': drivenGear,
      'wheelTurns': wheelTurns,
      'seedDiscHoles': seedDiscHoles,
      'wheelCircumference': wheelCircumference,
      'isAdvanced': isAdvanced ? 1 : 0,
      'createdAt': createdAt,
      'dataRegulagem': dataRegulagem,
      'responsiblePerson': responsiblePerson,
      'observations': observations,
      'discType': discType,
      'germinationRate': germinationRate,
      'viabilityFactor': viabilityFactor,
      'fotos': fotos,
    };
  }

  /// Converte o objeto para JSON
  String toJson() => json.encode(toMap());

  /// Cria um objeto a partir de um mapa
  factory PlanterCalibration.fromMap(Map<String, dynamic> map) {
    return PlanterCalibration(
      id: map['id'],
      name: map['name'],
      plotId: map['plotId'],
      cropId: map['cropId'],
      variedadeId: map['variedadeId'],
      machineId: map['machineId'],
      tipo: map['tipo'] ?? 'semente',
      targetPopulation: map['targetPopulation']?.toDouble() ?? 0.0,
      rowSpacing: map['rowSpacing']?.toDouble() ?? 0.0,
      planterRows: map['planterRows'] ?? 0,
      workSpeed: map['workSpeed']?.toDouble() ?? 0.0,
      thousandSeedWeight: map['thousandSeedWeight']?.toDouble(),
      drivingGear: map['drivingGear']?.toDouble(),
      drivenGear: map['drivenGear']?.toDouble(),
      wheelTurns: map['wheelTurns']?.toDouble(),
      seedDiscHoles: map['seedDiscHoles'],
      wheelCircumference: map['wheelCircumference']?.toDouble(),
      isAdvanced: map['isAdvanced'] == 1,
      createdAt: map['createdAt'],
      dataRegulagem: map['dataRegulagem'],
      discType: map['discType'],
      germinationRate: map['germinationRate']?.toDouble(),
      viabilityFactor: map['viabilityFactor']?.toDouble(),
      responsiblePerson: map['responsiblePerson'],
      observations: map['observations'],
      fotos: map['fotos'],
    );
  }

  /// Cria um objeto a partir de JSON
  factory PlanterCalibration.fromJson(String source) => PlanterCalibration.fromMap(json.decode(source));
      
  /// Calcula as sementes por metro para calibragem simples
  double calculateSeedsPerMeter() {
    // sementes_metro = (população_ha × espaçamento_cm) / 10000
    return (targetPopulation * rowSpacing) / 10000;
  }
  
  /// Calcula o peso total de sementes por hectare para calibragem simples
  double? calculateTotalWeightPerHectare() {
    if (thousandSeedWeight == null) return null;
    // peso_total_kg_ha = (população_ha / 1000) × PMS / 1000
    return (targetPopulation / 1000) * thousandSeedWeight! / 1000;
  }
  
  /// Calcula a relação de transmissão para calibragem avançada
  double? calculateTransmissionRatio() {
    if (drivingGear == null || drivenGear == null) return null;
    // relação_transmissão = engrenagem_motora / engrenagem_movida
    return drivingGear! / drivenGear!;
  }
  
  /// Calcula as rotações do disco para calibragem avançada
  double? calculateDiscRotations() {
    if (wheelTurns == null) return null;
    final ratio = calculateTransmissionRatio();
    if (ratio == null) return null;
    // rotações_disco = voltas_roda × relação_transmissão
    return wheelTurns! * ratio;
  }
  
  /// Calcula o total de sementes para calibragem avançada
  double? calculateTotalSeeds() {
    if (seedDiscHoles == null) return null;
    final discRotations = calculateDiscRotations();
    if (discRotations == null) return null;
    // sementes_totais = rotações_disco × furos_disco
    return discRotations * seedDiscHoles!;
  }
  
  /// Calcula a distância em metros para calibragem avançada
  double? calculateDistanceInMeters() {
    if (wheelTurns == null || wheelCircumference == null) return null;
    // distancia_metros = voltas_roda × circunferência_roda
    return wheelTurns! * wheelCircumference!;
  }
  
  /// Calcula as sementes por metro para calibragem avançada
  double? calculateAdvancedSeedsPerMeter() {
    final totalSeeds = calculateTotalSeeds();
    final distance = calculateDistanceInMeters();
    if (totalSeeds == null || distance == null) return null;
    // sementes_metro = sementes_totais / distancia_metros
    return totalSeeds / distance;
  }
  
  /// Calcula a população por hectare para calibragem avançada
  double? calculateAdvancedPopulationPerHectare() {
    final seedsPerMeter = calculateAdvancedSeedsPerMeter();
    if (seedsPerMeter == null) return null;
    // população_ha = sementes_metro × (10000 / espaçamento_cm)
    return seedsPerMeter * (10000 / rowSpacing);
  }
  
  /// Calcula a diferença percentual entre a população alvo e a calculada
  double? calculatePopulationDifferencePercentage() {
    final calculatedPopulation = isAdvanced 
        ? calculateAdvancedPopulationPerHectare() 
        : targetPopulation;
    if (calculatedPopulation == null) return null;
    // diferença_percentual = (calculada - alvo) / alvo * 100
    return (calculatedPopulation - targetPopulation) / targetPopulation * 100;
  }

  /// Calcula o peso total de sementes em kg/ha
  double calculateTotalSeedWeight() {
    if (thousandSeedWeight == null || thousandSeedWeight! <= 0) {
      return 0.0;
    }
    
    // Cálculo: (população/ha * peso de mil sementes em g) / 1000 para obter kg/ha
    return (targetPopulation * (thousandSeedWeight! / 1000)) / 1000;
  }

  /// Calcula a população por hectare com base nos parâmetros da calibragem
  int calculatePopulationPerHectare() {
    if (!isAdvanced || 
        seedDiscHoles == null || 
        wheelCircumference == null || 
        drivingGear == null || 
        drivenGear == null || 
        rowSpacing <= 0) {
      // Se não for calibragem avançada ou faltar parâmetros, retorna a população alvo
      return targetPopulation.round();
    }
    
    // Cálculo da população com base nos parâmetros mecânicos
    // Área ocupada por uma linha em 1 hectare (em metros quadrados)
    final areaPerRow = 10000 / (100 / rowSpacing); // 10000m² = 1ha, rowSpacing em cm
    
    // Relação de transmissão
    final gearRatio = drivenGear! / drivingGear!;
    
    // Distância percorrida em uma volta da roda (metros)
    final distancePerTurn = wheelCircumference!;
    
    // Sementes por metro linear
    final seedsPerMeter = (seedDiscHoles! * gearRatio) / distancePerTurn;
    
    // Sementes por linha em 1 hectare
    final seedsPerRowPerHectare = seedsPerMeter * (areaPerRow / rowSpacing * 100);
    
    return seedsPerRowPerHectare.round();
  }
}
