/// Modelo para produtos do estoque
class StockProduct {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double availableQuantity;
  final double unitValue;
  final String? lotNumber;
  final DateTime expirationDate;
  final String? supplier;
  final String status;
  final String? storageLocation;
  final String? observations;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.availableQuantity,
    required this.unitValue,
    this.lotNumber,
    required this.expirationDate,
    this.supplier,
    required this.status,
    this.storageLocation,
    this.observations,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Valor total do lote
  double get totalLotValue => availableQuantity * unitValue;

  /// Verifica se o produto está vencido
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  /// Verifica se o produto está vencendo em breve (30 dias)
  bool get isExpiringSoon {
    final daysUntilExpiration = expirationDate.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 30 && daysUntilExpiration > 0;
  }

  /// Verifica se o estoque está baixo (menos de 10% da quantidade inicial)
  bool get isLowStock => availableQuantity <= 10;

  /// Cria uma cópia do produto com alterações
  StockProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? availableQuantity,
    double? unitValue,
    String? lotNumber,
    DateTime? expirationDate,
    String? supplier,
    String? status,
    String? storageLocation,
    String? observations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      unitValue: unitValue ?? this.unitValue,
      lotNumber: lotNumber ?? this.lotNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      storageLocation: storageLocation ?? this.storageLocation,
      observations: observations ?? this.observations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'availableQuantity': availableQuantity,
      'unitValue': unitValue,
      'lotNumber': lotNumber,
      'expirationDate': expirationDate.toIso8601String(),
      'supplier': supplier,
      'status': status,
      'storageLocation': storageLocation,
      'observations': observations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Cria a partir de Map
  factory StockProduct.fromMap(Map<String, dynamic> map) {
    return StockProduct(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      unit: map['unit'] ?? '',
      availableQuantity: (map['availableQuantity'] ?? 0.0).toDouble(),
      unitValue: (map['unitValue'] ?? 0.0).toDouble(),
      lotNumber: map['lotNumber'],
      expirationDate: DateTime.parse(map['expirationDate']),
      supplier: map['supplier'],
      status: map['status'] ?? 'Disponível',
      storageLocation: map['storageLocation'],
      observations: map['observations'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'StockProduct(id: $id, name: $name, category: $category, availableQuantity: $availableQuantity, unitValue: $unitValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
