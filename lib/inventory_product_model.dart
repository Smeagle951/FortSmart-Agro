import 'package:flutter/material.dart';
import 'product_class.dart';

class InventoryProductModel {
  final String id;
  final String name;
  final ProductClass productClass;
  final String unit; // kg, L, semente
  final double quantity;
  final String batchNumber;
  final String supplier;
  final double unitCost;
  final DateTime expirationDate;
  final String? brand; // opcional
  final DateTime createdAt;
  final DateTime? updatedAt;

  InventoryProductModel({
    required this.id,
    required this.name,
    required this.productClass,
    required this.unit,
    required this.quantity,
    required this.batchNumber,
    required this.supplier,
    required this.unitCost,
    required this.expirationDate,
    this.brand,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Inferir tipo (Defensivo, Fertilizante, Semente…) a partir da classe
  String get type {
    switch (productClass) {
      case ProductClass.sementes:
        return 'Semente';
      case ProductClass.fertilizanteSolido:
      case ProductClass.fertilizanteLiquido:
      case ProductClass.macroNutriente:
      case ProductClass.microNutriente:
        return 'Fertilizante';
      case ProductClass.fungicida:
      case ProductClass.inseticida:
      case ProductClass.herbicida:
      case ProductClass.oleoMineral:
      case ProductClass.adjuvante:
      case ProductClass.biologico:
        return 'Defensivo';
      case ProductClass.outros:
        return 'Outro';
    }
  }

  // Para filtros rápidos
  bool isCriticalStock(double minStock) => quantity <= minStock;
  bool isExpired() => expirationDate.isBefore(DateTime.now());
  bool isNearExpiration({int days = 30}) =>
      expirationDate.isBefore(DateTime.now().add(Duration(days: days)));

  // Conversão para Map (para persistência/local storage)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'productClass': productClass.index,
        'unit': unit,
        'quantity': quantity,
        'batchNumber': batchNumber,
        'supplier': supplier,
        'unitCost': unitCost,
        'expirationDate': expirationDate.toIso8601String(),
        'brand': brand,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // Conversão de Map
  factory InventoryProductModel.fromMap(Map<String, dynamic> map) {
    return InventoryProductModel(
      id: map['id'],
      name: map['name'],
      productClass: ProductClass.values[map['productClass']],
      unit: map['unit'],
      quantity: map['quantity'],
      batchNumber: map['batchNumber'],
      supplier: map['supplier'],
      unitCost: map['unitCost'],
      expirationDate: DateTime.parse(map['expirationDate']),
      brand: map['brand'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}
