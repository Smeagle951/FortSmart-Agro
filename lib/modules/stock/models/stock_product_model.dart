import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Modelo para representar um produto no estoque com informações de custo
class StockProduct {
  final String id;
  final String name;
  final String category; // semente, herbicida, fertilizante, etc.
  final String unit; // kg, L, saca, mL
  final double availableQuantity;
  final double unitValue; // R$
  final double totalLotValue; // calculado: quantidade × valor_unitario
  final double? costPerHectare; // calculado dinamicamente quando vinculado a um talhão
  
  // Campos extras para profissionalização
  final String? supplier;
  final String? lotNumber;
  final String? storageLocation;
  final DateTime? expirationDate;
  final String? observations;
  
  // Campos de controle
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? fazendaId;

  StockProduct({
    String? id,
    required this.name,
    required this.category,
    required this.unit,
    required this.availableQuantity,
    required this.unitValue,
    this.costPerHectare,
    this.supplier,
    this.lotNumber,
    this.storageLocation,
    this.expirationDate,
    this.observations,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.fazendaId,
  }) : 
    id = id ?? const Uuid().v4(),
    totalLotValue = availableQuantity * unitValue,
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  /// Calcula o custo por hectare baseado na dose aplicada
  double calculateCostPerHectare(double dose) {
    return unitValue * dose;
  }

  /// Calcula o custo total de uma operação
  double calculateTotalCost(double dose, double area) {
    return calculateCostPerHectare(dose) * area;
  }

  /// Verifica se o produto está próximo do vencimento (30 dias)
  bool get isNearExpiration {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration >= 0;
  }

  /// Verifica se o produto está vencido
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// Verifica se o produto está vencendo em breve (7 dias)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration >= 0;
  }

  /// Verifica se o estoque está baixo (menos de 10% da quantidade inicial)
  bool get isLowStock {
    // Assumindo que a quantidade inicial é baseada em algum histórico
    // Por enquanto, vamos considerar baixo estoque se for menos de 10 unidades
    return availableQuantity < 10;
  }

  /// Cria uma cópia do objeto com os campos atualizados
  StockProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? availableQuantity,
    double? unitValue,
    double? costPerHectare,
    String? supplier,
    String? lotNumber,
    String? storageLocation,
    DateTime? expirationDate,
    String? observations,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? fazendaId,
  }) {
    return StockProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unitValue: unitValue ?? this.unitValue,
      costPerHectare: costPerHectare ?? this.costPerHectare,
      supplier: supplier ?? this.supplier,
      lotNumber: lotNumber ?? this.lotNumber,
      storageLocation: storageLocation ?? this.storageLocation,
      expirationDate: expirationDate ?? this.expirationDate,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      fazendaId: fazendaId ?? this.fazendaId,
    );
  }

  /// Converte o objeto para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'availableQuantity': availableQuantity,
      'unitValue': unitValue,
      'totalLotValue': totalLotValue,
      'costPerHectare': costPerHectare,
      'supplier': supplier,
      'lotNumber': lotNumber,
      'storageLocation': storageLocation,
      'expirationDate': expirationDate?.toIso8601String(),
      'observations': observations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'fazendaId': fazendaId,
    };
  }

  /// Cria um objeto a partir de JSON
  factory StockProduct.fromJson(Map<String, dynamic> json) {
    return StockProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      availableQuantity: (json['availableQuantity'] as num).toDouble(),
      unitValue: (json['unitValue'] as num).toDouble(),
      costPerHectare: json['costPerHectare'] != null 
          ? (json['costPerHectare'] as num).toDouble() 
          : null,
      supplier: json['supplier'] as String?,
      lotNumber: json['lotNumber'] as String?,
      storageLocation: json['storageLocation'] as String?,
      expirationDate: json['expirationDate'] != null 
          ? DateTime.parse(json['expirationDate'] as String)
          : null,
      observations: json['observations'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      fazendaId: json['fazendaId'] as String?,
    );
  }

  @override
  String toString() {
    return 'StockProduct(id: $id, name: $name, category: $category, availableQuantity: $availableQuantity $unit, unitValue: R\$ $unitValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
