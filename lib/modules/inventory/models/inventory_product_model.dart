import 'package:uuid/uuid.dart';
import '../../../models/agricultural_product.dart';
import 'product_class_model.dart';

/// Modelo para representar um produto no estoque
class InventoryProductModel {
  final String id;
  final String productId; // ID do produto agrícola relacionado
  final String name;
  final ProductType type;
  final ProductClass productClass; // Nova propriedade para classificação do produto
  final String unit;
  final double quantity;
  final DateTime expirationDate;
  final String batchNumber;
  final DateTime entryDate;
  final String? supplier;
  final String? invoiceNumber;
  final double? pricePerUnit;
  final double? recommendedDose;
  final String? recommendedDoseUnit;
  final List<String> associatedCropIds;
  final double minimumStock;
  final bool hasRestriction;
  final bool trackByBatch;
  final int expirationAlertDays;
  final String? notes; // Observações sobre o produto
  final String? description; // Descrição do produto
  final double? unitCost; // Custo unitário
  final double? minQuantity; // Quantidade mínima
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  InventoryProductModel({
    String? id,
    required this.productId,
    required this.name,
    required this.type,
    required this.productClass, // Nova propriedade obrigatória
    required this.unit,
    required this.quantity,
    required this.expirationDate,
    required this.batchNumber,
    DateTime? entryDate,
    this.supplier,
    this.invoiceNumber,
    this.pricePerUnit,
    this.recommendedDose,
    this.recommendedDoseUnit,
    this.associatedCropIds = const [],
    this.minimumStock = 0,
    this.hasRestriction = false,
    this.trackByBatch = true,
    this.expirationAlertDays = 30,
    this.notes,
    this.description,
    this.unitCost,
    this.minQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.entryDate = entryDate ?? DateTime.now(),
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  /// Verifica se o estoque está crítico (abaixo do mínimo)
  bool get isStockCritical => quantity <= minimumStock;

  /// Verifica se o estoque está baixo (até 30% acima do mínimo)
  bool get isStockLow => quantity > minimumStock && quantity <= minimumStock * 1.3;

  /// Verifica se o estoque está OK (mais de 30% acima do mínimo)
  bool get isStockOk => quantity > minimumStock * 1.3;

  /// Verifica se o produto está vencido
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  /// Verifica se o produto está próximo do vencimento
  bool get isNearExpiration {
    final daysToExpiration = expirationDate.difference(DateTime.now()).inDays;
    return daysToExpiration <= expirationAlertDays && daysToExpiration > 0;
  }

  /// Retorna o status do estoque como string
  String get stockStatus {
    if (isExpired) return 'Vencido';
    if (isStockCritical) return 'Crítico';
    if (isStockLow) return 'Baixo';
    return 'OK';
  }

  /// Retorna a cor do status do estoque
  /// Vermelho: Vencido ou Crítico
  /// Amarelo: Baixo ou Próximo do Vencimento
  /// Verde: OK
  String get statusColor {
    if (isExpired || isStockCritical) return 'red';
    if (isStockLow || isNearExpiration) return 'yellow';
    return 'green';
  }

  /// Cria uma cópia do modelo com os campos atualizados
  InventoryProductModel copyWith({
    String? id,
    String? productId,
    String? name,
    ProductType? type,
    ProductClass? productClass, // Adicionado campo para classe do produto
    String? unit,
    double? quantity,
    DateTime? expirationDate,
    String? batchNumber,
    DateTime? entryDate,
    String? supplier,
    String? invoiceNumber,
    double? pricePerUnit,
    double? recommendedDose,
    String? recommendedDoseUnit,
    List<String>? associatedCropIds,
    double? minimumStock,
    bool? hasRestriction,
    bool? trackByBatch,
    int? expirationAlertDays,
    String? notes,
    String? description,
    double? unitCost,
    double? minQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return InventoryProductModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      type: type ?? this.type,
      productClass: productClass ?? this.productClass, // Adicionado campo para classe do produto
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      batchNumber: batchNumber ?? this.batchNumber,
      entryDate: entryDate ?? this.entryDate,
      supplier: supplier ?? this.supplier,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      recommendedDose: recommendedDose ?? this.recommendedDose,
      recommendedDoseUnit: recommendedDoseUnit ?? this.recommendedDoseUnit,
      associatedCropIds: associatedCropIds ?? this.associatedCropIds,
      minimumStock: minimumStock ?? this.minimumStock,
      hasRestriction: hasRestriction ?? this.hasRestriction,
      trackByBatch: trackByBatch ?? this.trackByBatch,
      expirationAlertDays: expirationAlertDays ?? this.expirationAlertDays,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      unitCost: unitCost ?? this.unitCost,
      minQuantity: minQuantity ?? this.minQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Converte o modelo para um mapa para armazenamento no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': _getCategoryFromType(type), // Converter enum para string
      'class': _getClassFromProductClass(productClass), // Converter enum para string
      'unit': unit,
      'min_stock': minimumStock,
      'max_stock': null, // Não usado no modelo atual
      'current_stock': quantity, // Mapear quantity para current_stock
      'price': unitCost, // Mapear unitCost para price
      'supplier': supplier,
      'batch_number': batchNumber,
      'expiration_date': expirationDate.toIso8601String(),
      'manufacturing_date': entryDate.toIso8601String(), // Mapear entryDate para manufacturing_date
      'registration_number': null, // Não usado no modelo atual
      'active_ingredient': null, // Não usado no modelo atual
      'concentration': null, // Não usado no modelo atual
      'formulation': null, // Não usado no modelo atual
      'toxicity_class': null, // Não usado no modelo atual
      'application_method': null, // Não usado no modelo atual
      'waiting_period': null, // Não usado no modelo atual
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Converte ProductType para categoria string
  String _getCategoryFromType(ProductType type) {
    switch (type) {
      case ProductType.herbicide:
        return 'Herbicida';
      case ProductType.insecticide:
        return 'Inseticida';
      case ProductType.fungicide:
        return 'Fungicida';
      case ProductType.fertilizer:
        return 'Fertilizante';
      case ProductType.growth:
        return 'Regulador de Crescimento';
      case ProductType.adjuvant:
        return 'Adjuvante';
      case ProductType.seed:
        return 'Semente';
      case ProductType.other:
        return 'Outros';
    }
  }

  /// Converte ProductClass para classe string
  String _getClassFromProductClass(ProductClass productClass) {
    switch (productClass) {
      case ProductClass.herbicides:
        return 'Herbicidas';
      case ProductClass.insecticides:
        return 'Inseticidas';
      case ProductClass.fungicides:
        return 'Fungicidas';
      case ProductClass.solidFertilizers:
        return 'Fertilizantes Sólidos';
      case ProductClass.liquidFertilizers:
        return 'Fertilizantes Líquidos';
      case ProductClass.adjuvants:
        return 'Adjuvantes';
      case ProductClass.seeds:
        return 'Sementes';
      case ProductClass.macroNutrients:
        return 'Macronutrientes';
      case ProductClass.microNutrients:
        return 'Micronutrientes';
      case ProductClass.mineralOil:
        return 'Óleo Mineral';
      case ProductClass.biological:
        return 'Biológicos';
      case ProductClass.other:
        return 'Outros';
    }
  }

  /// Converte string de categoria para ProductType
  static ProductType _getTypeFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'herbicida':
        return ProductType.herbicide;
      case 'inseticida':
        return ProductType.insecticide;
      case 'fungicida':
        return ProductType.fungicide;
      case 'fertilizante':
        return ProductType.fertilizer;
      case 'regulador de crescimento':
        return ProductType.growth;
      case 'adjuvante':
        return ProductType.adjuvant;
      case 'semente':
        return ProductType.seed;
      case 'outros':
      default:
        return ProductType.other;
    }
  }

  /// Converte string de classe para ProductClass
  static ProductClass _getClassFromString(String className) {
    switch (className.toLowerCase()) {
      case 'herbicidas':
        return ProductClass.herbicides;
      case 'inseticidas':
        return ProductClass.insecticides;
      case 'fungicidas':
        return ProductClass.fungicides;
      case 'fertilizantes sólidos':
        return ProductClass.solidFertilizers;
      case 'fertilizantes líquidos':
        return ProductClass.liquidFertilizers;
      case 'adjuvantes':
        return ProductClass.adjuvants;
      case 'sementes':
        return ProductClass.seeds;
      case 'macronutrientes':
        return ProductClass.macroNutrients;
      case 'micronutrientes':
        return ProductClass.microNutrients;
      case 'óleo mineral':
        return ProductClass.mineralOil;
      case 'biológicos':
        return ProductClass.biological;
      case 'outros':
      default:
        return ProductClass.other;
    }
  }

  /// Cria um modelo a partir de um mapa do banco de dados
  // Método auxiliar para inferir a classe do produto a partir do tipo
  static ProductClass _inferProductClass(ProductType type) {
    switch (type) {
      case ProductType.herbicide:
        return ProductClass.herbicides;
      case ProductType.insecticide:
        return ProductClass.insecticides;
      case ProductType.fungicide:
        return ProductClass.fungicides;
      case ProductType.fertilizer:
        return ProductClass.solidFertilizers; // Por padrão assume fertilizante sólido
      case ProductType.growth:
        return ProductClass.other;
      case ProductType.adjuvant:
        return ProductClass.adjuvants;
      case ProductType.seed:
        return ProductClass.seeds;
      case ProductType.other:
      default:
        return ProductClass.other;
    }
  }

  factory InventoryProductModel.fromMap(Map<String, dynamic> map) {
    // Mapear campos da tabela para o modelo
    final category = map['category'] as String? ?? 'Outros';
    final productClass = map['class'] as String? ?? 'Outros';
    
    // Converter string para enum
    ProductType type;
    try {
      type = _getTypeFromCategory(category);
    } catch (e) {
      type = ProductType.other;
    }
    
    ProductClass inferredClass;
    try {
      inferredClass = _getClassFromString(productClass);
    } catch (e) {
      inferredClass = _inferProductClass(type);
    }
    
    return InventoryProductModel(
      id: map['id'] ?? '',
      productId: map['id'] ?? '', // Usar id como productId se não existir
      name: map['name'] ?? '',
      type: type,
      productClass: inferredClass,
      unit: map['unit'] ?? 'L',
      quantity: (map['current_stock'] as num?)?.toDouble() ?? 0.0,
      expirationDate: map['expiration_date'] != null 
          ? DateTime.parse(map['expiration_date']) 
          : DateTime.now().add(Duration(days: 365)),
      batchNumber: map['batch_number'] ?? '',
      entryDate: map['manufacturing_date'] != null 
          ? DateTime.parse(map['manufacturing_date']) 
          : DateTime.now(),
      supplier: map['supplier'],
      invoiceNumber: null, // Não usado na tabela atual
      pricePerUnit: null, // Não usado na tabela atual
      recommendedDose: null, // Não usado na tabela atual
      recommendedDoseUnit: null, // Não usado na tabela atual
      associatedCropIds: [], // Não usado na tabela atual
      minimumStock: (map['min_stock'] as num?)?.toDouble() ?? 0.0,
      hasRestriction: false, // Não usado na tabela atual
      trackByBatch: true, // Não usado na tabela atual
      expirationAlertDays: 30, // Não usado na tabela atual
      notes: map['notes'],
      description: map['description'],
      unitCost: (map['price'] as num?)?.toDouble(),
      minQuantity: (map['min_stock'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      isSynced: map['is_synced'] == 1,
    );
  }
}
