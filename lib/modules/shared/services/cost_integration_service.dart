import 'dart:convert';
import '../models/operation_data.dart';
import '../../stock/models/stock_product_model.dart';

/// Resultado do cálculo de custo de uma operação
class CostCalculation {
  final double costPerHectare;
  final double totalCost;
  final double quantityUsed;
  final String productName;
  final String productUnit;

  CostCalculation({
    required this.costPerHectare,
    required this.totalCost,
    required this.quantityUsed,
    required this.productName,
    required this.productUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'costPerHectare': costPerHectare,
      'totalCost': totalCost,
      'quantityUsed': quantityUsed,
      'productName': productName,
      'productUnit': productUnit,
    };
  }

  factory CostCalculation.fromMap(Map<String, dynamic> map) {
    return CostCalculation(
      costPerHectare: map['costPerHectare'],
      totalCost: map['totalCost'],
      quantityUsed: map['quantityUsed'],
      productName: map['productName'],
      productUnit: map['productUnit'],
    );
  }
}

/// Filtros para relatórios de custo
class CostReportFilters {
  final String? talhaoId;
  final OperationType? operationType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? productCategory;
  final String? safra;

  CostReportFilters({
    this.talhaoId,
    this.operationType,
    this.startDate,
    this.endDate,
    this.productCategory,
    this.safra,
  });
}

/// Relatório de custos
class CostReport {
  final List<OperationData> operations;
  final double totalCost;
  final double totalArea;
  final double averageCostPerHectare;
  final Map<String, double> costByCategory;
  final Map<String, double> costByTalhao;

  CostReport({
    required this.operations,
    required this.totalCost,
    required this.totalArea,
    required this.averageCostPerHectare,
    required this.costByCategory,
    required this.costByTalhao,
  });
}

/// Serviço principal de integração de custos
class CostIntegrationService {
  static final CostIntegrationService _instance = CostIntegrationService._internal();
  factory CostIntegrationService() => _instance;
  CostIntegrationService._internal();

  // Simulação de dados do estoque (em produção, isso viria do banco de dados)
  final Map<String, StockProduct> _stockProducts = {};

  /// Adiciona um produto ao estoque (simulação)
  void addStockProduct(StockProduct product) {
    _stockProducts[product.id] = product;
  }

  /// Obtém um produto do estoque
  StockProduct? getStockProduct(String productId) {
    return _stockProducts[productId];
  }

  /// Calcula o custo de uma operação
  Future<CostCalculation> calculateOperationCost(OperationData operation) async {
    // Busca o produto no estoque
    final product = getStockProduct(operation.productId);
    
    if (product == null) {
      throw Exception('Produto não encontrado no estoque: ${operation.productId}');
    }

    // Calcula o custo por hectare
    final costPerHectare = product.calculateCostPerHectare(operation.dose);
    
    // Calcula o custo total
    final totalCost = product.calculateTotalCost(operation.dose, operation.talhaoArea);

    return CostCalculation(
      costPerHectare: costPerHectare,
      totalCost: totalCost,
      quantityUsed: operation.totalQuantity,
      productName: product.name,
      productUnit: product.unit,
    );
  }

  /// Registra custo no histórico
  Future<void> recordCostInHistory(OperationData operation, CostCalculation cost) async {
    // Atualiza a operação com os custos calculados
    final updatedOperation = operation.copyWith(
      costPerHectare: cost.costPerHectare,
      totalCost: cost.totalCost,
    );

    // Aqui você salvaria no banco de dados
    // await _historyRepository.saveOperationCost(updatedOperation);
    
    print('Custo registrado no histórico: ${updatedOperation.toString()}');
  }

  /// Gera relatório de custos
  Future<CostReport> generateCostReport(CostReportFilters filters) async {
    // Simulação de operações (em produção, viria do banco de dados)
    final List<OperationData> allOperations = [];
    
    // Filtra as operações
    List<OperationData> filteredOperations = allOperations.where((operation) {
      if (filters.talhaoId != null && operation.talhaoId != filters.talhaoId) {
        return false;
      }
      if (filters.operationType != null && operation.operationType != filters.operationType) {
        return false;
      }
      if (filters.startDate != null && operation.operationDate.isBefore(filters.startDate!)) {
        return false;
      }
      if (filters.endDate != null && operation.operationDate.isAfter(filters.endDate!)) {
        return false;
      }
      return true;
    }).toList();

    // Calcula totais
    double totalCost = 0;
    double totalArea = 0;
    Map<String, double> costByCategory = {};
    Map<String, double> costByTalhao = {};

    for (final operation in filteredOperations) {
      totalCost += operation.calculatedTotalCost;
      totalArea += operation.talhaoArea;

      // Agrupa por categoria
      final product = getStockProduct(operation.productId);
      if (product != null) {
        final category = product.category;
        costByCategory[category] = (costByCategory[category] ?? 0) + operation.calculatedTotalCost;
      }

      // Agrupa por talhão
      costByTalhao[operation.talhaoId] = (costByTalhao[operation.talhaoId] ?? 0) + operation.calculatedTotalCost;
    }

    final averageCostPerHectare = totalArea > 0 ? totalCost / totalArea : 0;

    return CostReport(
      operations: filteredOperations,
      totalCost: totalCost,
      totalArea: totalArea,
      averageCostPerHectare: averageCostPerHectare,
      costByCategory: costByCategory,
      costByTalhao: costByTalhao,
    );
  }

  /// Registra uma operação completa (cálculo + histórico)
  Future<void> registerOperation(OperationData operation) async {
    try {
      // 1. Calcula o custo da operação
      final costCalculation = await calculateOperationCost(operation);
      
      // 2. Registra no histórico
      await recordCostInHistory(operation, costCalculation);
      
      // 3. Atualiza o estoque (diminui a quantidade)
      await _updateStockQuantity(operation);
      
      print('Operação registrada com sucesso: ${operation.operationTypeString}');
      print('Custo total: R\$ ${costCalculation.totalCost.toStringAsFixed(2)}');
      print('Custo por hectare: R\$ ${costCalculation.costPerHectare.toStringAsFixed(2)}/ha');
      
    } catch (e) {
      print('Erro ao registrar operação: $e');
      rethrow;
    }
  }

  /// Atualiza a quantidade no estoque
  Future<void> _updateStockQuantity(OperationData operation) async {
    final product = getStockProduct(operation.productId);
    if (product != null) {
      final newQuantity = product.availableQuantity - operation.totalQuantity;
      
      if (newQuantity < 0) {
        throw Exception('Quantidade insuficiente no estoque para ${product.name}');
      }

      // Atualiza o produto no estoque
      final updatedProduct = product.copyWith(
        availableQuantity: newQuantity,
        updatedAt: DateTime.now(),
      );
      
      _stockProducts[product.id] = updatedProduct;
      
      print('Estoque atualizado: ${product.name} - ${newQuantity.toStringAsFixed(2)} ${product.unit}');
    }
  }

  /// Obtém produtos com estoque baixo
  List<StockProduct> getLowStockProducts() {
    return _stockProducts.values.where((product) => product.isLowStock).toList();
  }

  /// Obtém produtos próximos do vencimento
  List<StockProduct> getNearExpirationProducts() {
    return _stockProducts.values.where((product) => product.isNearExpiration).toList();
  }

  /// Obtém produtos vencidos
  List<StockProduct> getExpiredProducts() {
    return _stockProducts.values.where((product) => product.isExpired).toList();
  }

  /// Calcula o valor total do estoque
  double getTotalStockValue() {
    return _stockProducts.values.fold(0.0, (sum, product) => sum + product.totalLotValue);
  }

  /// Exporta dados para JSON
  String exportToJson() {
    final data = {
      'stockProducts': _stockProducts.values.map((p) => p.toMap()).toList(),
      'totalStockValue': getTotalStockValue(),
      'lowStockProducts': getLowStockProducts().map((p) => p.toMap()).toList(),
      'nearExpirationProducts': getNearExpirationProducts().map((p) => p.toMap()).toList(),
      'expiredProducts': getExpiredProducts().map((p) => p.toMap()).toList(),
    };
    
    return jsonEncode(data);
  }
}
