/// Modelo para Cálculo Básico de Calibração de Fertilizantes
/// Seguindo o padrão especificado no documento MD

enum InputMode { time, distance }

class BasicInput {
  final InputMode mode;
  final double timeSeconds;     // usado se mode == time
  final double? distanceMeters; // usado se mode == distance (pode ser null quando mode == time)
  final double widthMeters;     // L (m)
  final double speedKmh;        // V (km/h) (usado quando mode == time)
  final double collectedKg;     // W (kg)
  final double desiredKgHa;     // Td (kg/ha)

  BasicInput({
    required this.mode,
    this.timeSeconds = 0,
    this.distanceMeters,
    required this.widthMeters,
    required this.speedKmh,
    required this.collectedKg,
    required this.desiredKgHa,
  });
}

class BasicResult {
  final double distanceMeters;
  final double areaM2;
  final double areaHa;
  final double taxaKgHa;      // Tr
  final double erroPercent;   // Erro%
  final double ajustePercent; // % alteração sugerida (positivo = aumentar)

  BasicResult({
    required this.distanceMeters,
    required this.areaM2,
    required this.areaHa,
    required this.taxaKgHa,
    required this.erroPercent,
    required this.ajustePercent,
  });
}

class CalculoBasicoCalibracaoModel {
  final String id;
  final DateTime dataCriacao;
  final String calcVersion;
  
  // Entradas brutas (para auditoria)
  final BasicInput rawInputs;
  
  // Resultados computados
  final BasicResult computedResults;
  
  // Campos adicionais para registro (não usados no cálculo)
  final String? operador;
  final String? maquina;
  final String? comporta;
  final String? fertilizante;
  final String? nomeCalibracao;
  final String? observacoes;

  CalculoBasicoCalibracaoModel({
    required this.id,
    required this.dataCriacao,
    required this.calcVersion,
    required this.rawInputs,
    required this.computedResults,
    this.operador,
    this.maquina,
    this.comporta,
    this.fertilizante,
    this.nomeCalibracao,
    this.observacoes,
  });

  /// Cria uma nova calibração com cálculos automáticos
  factory CalculoBasicoCalibracaoModel.calcular({
    String? id,
    required BasicInput inputs,
    String? operador,
    String? maquina,
    String? comporta,
    String? fertilizante,
    String? nomeCalibracao,
    String? observacoes,
  }) {
    final result = computeBasicCalibration(inputs);
    
    return CalculoBasicoCalibracaoModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      dataCriacao: DateTime.now(),
      calcVersion: "v2025-09-17-01",
      rawInputs: inputs,
      computedResults: result,
      operador: operador,
      maquina: maquina,
      comporta: comporta,
      fertilizante: fertilizante,
      nomeCalibracao: nomeCalibracao,
      observacoes: observacoes,
    );
  }

  /// Converte para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dataCriacao': dataCriacao.toIso8601String(),
      'calcVersion': calcVersion,
      'rawInputs': {
        'mode': rawInputs.mode.name,
        'timeSeconds': rawInputs.timeSeconds,
        'distanceMeters': rawInputs.distanceMeters,
        'widthMeters': rawInputs.widthMeters,
        'speedKmh': rawInputs.speedKmh,
        'collectedKg': rawInputs.collectedKg,
        'desiredKgHa': rawInputs.desiredKgHa,
      },
      'computedResults': {
        'distanceMeters': computedResults.distanceMeters,
        'areaM2': computedResults.areaM2,
        'areaHa': computedResults.areaHa,
        'taxaKgHa': computedResults.taxaKgHa,
        'erroPercent': computedResults.erroPercent,
        'ajustePercent': computedResults.ajustePercent,
      },
      'operador': operador,
      'maquina': maquina,
      'comporta': comporta,
      'fertilizante': fertilizante,
      'nomeCalibracao': nomeCalibracao,
      'observacoes': observacoes,
    };
  }

  /// Cria a partir de Map
  factory CalculoBasicoCalibracaoModel.fromMap(Map<String, dynamic> map) {
    final rawInputsMap = map['rawInputs'] as Map<String, dynamic>;
    final computedResultsMap = map['computedResults'] as Map<String, dynamic>;
    
    return CalculoBasicoCalibracaoModel(
      id: map['id'],
      dataCriacao: DateTime.parse(map['dataCriacao']),
      calcVersion: map['calcVersion'],
      rawInputs: BasicInput(
        mode: InputMode.values.firstWhere((e) => e.name == rawInputsMap['mode']),
        timeSeconds: rawInputsMap['timeSeconds']?.toDouble() ?? 0,
        distanceMeters: rawInputsMap['distanceMeters']?.toDouble(),
        widthMeters: rawInputsMap['widthMeters'].toDouble(),
        speedKmh: rawInputsMap['speedKmh'].toDouble(),
        collectedKg: rawInputsMap['collectedKg'].toDouble(),
        desiredKgHa: rawInputsMap['desiredKgHa'].toDouble(),
      ),
      computedResults: BasicResult(
        distanceMeters: computedResultsMap['distanceMeters'].toDouble(),
        areaM2: computedResultsMap['areaM2'].toDouble(),
        areaHa: computedResultsMap['areaHa'].toDouble(),
        taxaKgHa: computedResultsMap['taxaKgHa'].toDouble(),
        erroPercent: computedResultsMap['erroPercent'].toDouble(),
        ajustePercent: computedResultsMap['ajustePercent'].toDouble(),
      ),
      operador: map['operador'],
      maquina: map['maquina'],
      comporta: map['comporta'],
      fertilizante: map['fertilizante'],
      nomeCalibracao: map['nomeCalibracao'],
      observacoes: map['observacoes'],
    );
  }
}

/// Função de cálculo básico de calibração
/// Implementa as fórmulas especificadas no documento MD
BasicResult computeBasicCalibration(BasicInput inpt) {
  // 1) distância
  final double D = (inpt.mode == InputMode.distance)
    ? (inpt.distanceMeters ?? 0.0)
    : (inpt.speedKmh * 1000.0 / 3600.0) * inpt.timeSeconds;

  if (D <= 0) throw ArgumentError('Distância calculada/informada deve ser > 0');
  if (inpt.widthMeters <= 0) throw ArgumentError('Largura deve ser > 0');
  if (inpt.desiredKgHa == 0) throw ArgumentError('Taxa desejada (Td) deve ser != 0');

  // 2) área
  final double areaM2 = D * inpt.widthMeters;
  final double areaHa = areaM2 / 10000.0;

  // 3) taxa Tr
  final double taxaKgHa = areaHa > 0 ? inpt.collectedKg / areaHa : 0.0;

  // 4) erro %
  final double erroPercent = (taxaKgHa - inpt.desiredKgHa) / inpt.desiredKgHa * 100.0;

  // 5) ajuste (%)
  final double fatorAjuste = taxaKgHa == 0 ? double.infinity : (inpt.desiredKgHa / taxaKgHa);
  final double ajustePercent = (fatorAjuste - 1.0) * 100.0;

  return BasicResult(
    distanceMeters: D,
    areaM2: areaM2,
    areaHa: areaHa,
    taxaKgHa: taxaKgHa,
    erroPercent: erroPercent,
    ajustePercent: ajustePercent,
  );
}
