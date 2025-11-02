import 'package:flutter/material.dart';

enum InventoryStatusLevel { ok, warning, critical }

class InventoryStatus {
  final String id;
  final String productName;
  final String category;
  final double currentQuantity;
  final double minimumQuantity;
  final double maximumQuantity;
  final double unitPrice;
  final String unit;
  final DateTime lastUpdated;
  final InventoryStatusLevel level;
  
  // Aliases para compatibilidade com código existente
  String? get itemName => productName;
  double? get currentStock => currentQuantity;
  double? get minimumStock => minimumQuantity;
  double? get maximumStock => maximumQuantity;
  double? get currentAmount => currentQuantity;
  double? get criticalLevel => minimumQuantity;
  double? get warningLevel => minimumQuantity * 1.5;
  double? get maxAmount => maximumQuantity;
  
  InventoryStatus({
    required this.id,
    required this.productName,
    required this.category,
    required this.currentQuantity,
    required this.minimumQuantity,
    this.maximumQuantity = 0.0,
    this.unitPrice = 0.0,
    required this.unit,
    required this.lastUpdated,
    required this.level,
  });
  
  // Alias para compatibilidade
  String? get name => productName;
  
  double get currentPercentage {
    // Considerando que minimumQuantity é o limiar crítico (geralmente 20% do estoque ideal)
    // e estoque ideal seria 5x o minimumQuantity
    final idealQuantity = minimumQuantity * 5;
    return (currentQuantity / idealQuantity) * 100;
  }
  
  Color get statusColor {
    switch (level) {
      case InventoryStatusLevel.critical:
        return Colors.red;
      case InventoryStatusLevel.warning:
        return Colors.orange;
      case InventoryStatusLevel.ok:
        return Colors.green;
    }
  }
  
  String get statusText {
    switch (level) {
      case InventoryStatusLevel.critical:
        return 'Crítico';
      case InventoryStatusLevel.warning:
        return 'Atenção';
      case InventoryStatusLevel.ok:
        return 'OK';
    }
  }
  
  static InventoryStatusLevel calculateLevel(double currentQuantity, double minimumQuantity) {
    if (currentQuantity <= minimumQuantity) {
      return InventoryStatusLevel.critical;
    } else if (currentQuantity <= minimumQuantity * 2) {
      return InventoryStatusLevel.warning;
    } else {
      return InventoryStatusLevel.ok;
    }
  }
  
  static InventoryStatus fromMap(Map<String, dynamic> map) {
    final currentQty = map['current_quantity'] ?? 0.0;
    final minQty = map['minimum_quantity'] ?? 0.0;
    
    return InventoryStatus(
      id: map['id'],
      productName: map['product_name'],
      category: map['category'] ?? 'Sem categoria',
      currentQuantity: currentQty is int ? currentQty.toDouble() : currentQty,
      minimumQuantity: minQty is int ? minQty.toDouble() : minQty,
      unit: map['unit'] ?? 'un',
      lastUpdated: DateTime.parse(map['last_updated']),
      level: _parseLevel(map['level']) ?? calculateLevel(currentQty, minQty),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_name': productName,
      'category': category,
      'current_quantity': currentQuantity,
      'minimum_quantity': minimumQuantity,
      'unit': unit,
      'last_updated': lastUpdated.toIso8601String(),
      'level': _levelToString(level),
    };
  }
  
  static InventoryStatusLevel? _parseLevel(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical':
        return InventoryStatusLevel.critical;
      case 'warning':
        return InventoryStatusLevel.warning;
      case 'ok':
        return InventoryStatusLevel.ok;
      default:
        return null;
    }
  }
  
  static String _levelToString(InventoryStatusLevel level) {
    switch (level) {
      case InventoryStatusLevel.critical:
        return 'critical';
      case InventoryStatusLevel.warning:
        return 'warning';
      case InventoryStatusLevel.ok:
        return 'ok';
    }
  }
}
