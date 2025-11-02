import 'package:uuid/uuid.dart';

/// Tipo de operação agrícola
enum OperationType {
  application,  // Aplicação
  planting,     // Plantio
  fertilization, // Fertilização
  harvest,      // Colheita
  other,        // Outro
}

/// Modelo para representar dados de uma operação agrícola
class OperationData {
  final String operationId;
  final String talhaoId;
  final String productId;
  final double dose; // ex.: 2 L/ha
  final double talhaoArea; // ha
  final double totalQuantity; // dose × área
  final OperationType operationType;
  final DateTime operationDate;
  final double? costPerHectare; // calculado pelo estoque
  final double? totalCost; // calculado pelo estoque
  
  // Campos adicionais
  final String? notes;
  final String? operatorName;
  final String? equipment;
  final String? weatherConditions;
  final bool isSynced;
  final String? fazendaId;

  OperationData({
    String? operationId,
    required this.talhaoId,
    required this.productId,
    required this.dose,
    required this.talhaoArea,
    required this.operationType,
    required this.operationDate,
    this.costPerHectare,
    this.totalCost,
    this.notes,
    this.operatorName,
    this.equipment,
    this.weatherConditions,
    this.isSynced = false,
    this.fazendaId,
  }) : 
    operationId = operationId ?? const Uuid().v4(),
    totalQuantity = dose * talhaoArea;

  /// Retorna o tipo de operação como string
  String get operationTypeString {
    switch (operationType) {
      case OperationType.application:
        return 'Aplicação';
      case OperationType.planting:
        return 'Plantio';
      case OperationType.fertilization:
        return 'Fertilização';
      case OperationType.harvest:
        return 'Colheita';
      case OperationType.other:
        return 'Outro';
    }
  }

  /// Calcula o custo total se não foi calculado
  double get calculatedTotalCost {
    if (totalCost != null) return totalCost!;
    if (costPerHectare != null) return costPerHectare! * talhaoArea;
    return 0.0;
  }

  /// Calcula o custo por hectare se não foi calculado
  double get calculatedCostPerHectare {
    if (costPerHectare != null) return costPerHectare!;
    if (totalCost != null) return totalCost! / talhaoArea;
    return 0.0;
  }

  /// Cria uma cópia do objeto com os campos atualizados
  OperationData copyWith({
    String? operationId,
    String? talhaoId,
    String? productId,
    double? dose,
    double? talhaoArea,
    OperationType? operationType,
    DateTime? operationDate,
    double? costPerHectare,
    double? totalCost,
    String? notes,
    String? operatorName,
    String? equipment,
    String? weatherConditions,
    bool? isSynced,
    String? fazendaId,
  }) {
    return OperationData(
      operationId: operationId ?? this.operationId,
      talhaoId: talhaoId ?? this.talhaoId,
      productId: productId ?? this.productId,
      dose: dose ?? this.dose,
      talhaoArea: talhaoArea ?? this.talhaoArea,
      operationType: operationType ?? this.operationType,
      operationDate: operationDate ?? this.operationDate,
      costPerHectare: costPerHectare ?? this.costPerHectare,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      operatorName: operatorName ?? this.operatorName,
      equipment: equipment ?? this.equipment,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      isSynced: isSynced ?? this.isSynced,
      fazendaId: fazendaId ?? this.fazendaId,
    );
  }

  /// Converte o objeto para um mapa
  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'talhaoId': talhaoId,
      'productId': productId,
      'dose': dose,
      'talhaoArea': talhaoArea,
      'totalQuantity': totalQuantity,
      'operationType': operationType.index,
      'operationDate': operationDate.toIso8601String(),
      'costPerHectare': costPerHectare,
      'totalCost': totalCost,
      'notes': notes,
      'operatorName': operatorName,
      'equipment': equipment,
      'weatherConditions': weatherConditions,
      'isSynced': isSynced ? 1 : 0,
      'fazendaId': fazendaId,
    };
  }

  /// Cria um objeto a partir de um mapa
  factory OperationData.fromMap(Map<String, dynamic> map) {
    return OperationData(
      operationId: map['operationId'],
      talhaoId: map['talhaoId'],
      productId: map['productId'],
      dose: map['dose'],
      talhaoArea: map['talhaoArea'],
      operationType: OperationType.values[map['operationType']],
      operationDate: DateTime.parse(map['operationDate']),
      costPerHectare: map['costPerHectare'],
      totalCost: map['totalCost'],
      notes: map['notes'],
      operatorName: map['operatorName'],
      equipment: map['equipment'],
      weatherConditions: map['weatherConditions'],
      isSynced: map['isSynced'] == 1,
      fazendaId: map['fazendaId'],
    );
  }

  /// Converte o objeto para JSON
  String toJson() => jsonEncode(toMap());

  /// Cria um objeto a partir de JSON
  factory OperationData.fromJson(String source) => 
      OperationData.fromMap(jsonDecode(source));

  @override
  String toString() {
    return 'OperationData(operationId: $operationId, talhaoId: $talhaoId, productId: $productId, dose: $dose, talhaoArea: $talhaoArea, operationType: $operationTypeString, totalCost: $totalCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperationData && other.operationId == operationId;
  }

  @override
  int get hashCode => operationId.hashCode;
}
