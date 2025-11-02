// Removendo importação não utilizada
import '../../../modules/inventory/models/inventory_product_model.dart';

/// Modelo para o relatório de conferência de estoque atual
class InventoryStockReportModel {
  /// Data de início do período de filtro
  final DateTime? startDate;
  
  /// Data de fim do período de filtro
  final DateTime? endDate;
  
  /// Nome do produto para filtro (opcional)
  final String? productName;
  
  /// Tipo de produto para filtro (opcional)
  final String? productType;
  
  /// Fornecedor para filtro (opcional)
  final String? supplier;
  
  /// Lote para filtro (opcional)
  final String? batchNumber;
  
  /// Lista de produtos incluídos no relatório
  final List<InventoryProductModel> products;
  
  /// Nome da propriedade/fazenda
  final String farmName;
  
  /// Responsável pela conferência
  final String responsiblePerson;
  
  /// Data e hora da geração do relatório
  final DateTime generationDate;

  InventoryStockReportModel({
    this.startDate,
    this.endDate,
    this.productName,
    this.productType,
    this.supplier,
    this.batchNumber,
    required this.products,
    required this.farmName,
    required this.responsiblePerson,
    DateTime? generationDate,
  }) : this.generationDate = generationDate ?? DateTime.now();

  /// Retorna os produtos filtrados com base nos critérios do relatório
  List<InventoryProductModel> get filteredProducts {
    List<InventoryProductModel> result = List.from(products);
    
    if (productName?.isNotEmpty ?? false) {
      result = result.where((p) => 
        p.name.toLowerCase().contains(productName!.toLowerCase())).toList();
    }
    
    if (productType?.isNotEmpty ?? false) {
      result = result.where((p) => 
        p.productClass.toString().contains(productType!)).toList();
    }
    
    if (supplier?.isNotEmpty ?? false) {
      result = result.where((p) => 
        p.supplier?.toLowerCase().contains(supplier!.toLowerCase()) ?? false).toList();
    }
    
    if (batchNumber?.isNotEmpty ?? false) {
      result = result.where((p) => 
        p.batchNumber.toLowerCase().contains(batchNumber!.toLowerCase())).toList();
    }
    
    if (startDate != null && endDate != null) {
      result = result.where((p) => 
        p.expirationDate.isAfter(startDate!) && 
        p.expirationDate.isBefore(endDate!.add(const Duration(days: 1)))).toList();
    } else if (startDate != null) {
      result = result.where((p) => 
        p.expirationDate.isAfter(startDate!)).toList();
    } else if (endDate != null) {
      result = result.where((p) => 
        p.expirationDate.isBefore(endDate!.add(const Duration(days: 1)))).toList();
    }
    
    return result;
  }

  /// Calcula o valor total do estoque
  double get totalStockValue {
    return filteredProducts.fold(0.0, (sum, product) => 
      sum + (product.quantity * (product.pricePerUnit ?? 0.0)));
  }
}
