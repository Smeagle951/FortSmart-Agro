import '../../models/calda/product.dart';
import '../../models/calda/calda_config.dart';
import '../../models/calda/dose_unit.dart';

/// Resultado do cálculo de produto na calda
class ProductCalculationResult {
  final Product product;
  final double dosePerHectare;
  final double totalDose;
  final String displayUnit;
  final String displayValue;

  ProductCalculationResult({
    required this.product,
    required this.dosePerHectare,
    required this.totalDose,
    required this.displayUnit,
    required this.displayValue,
  });
}

/// Resultado do cálculo da receita completa
class RecipeCalculationResult {
  final List<ProductCalculationResult> products;
  final double totalVolume;
  final double hectaresCovered;
  final double volumePerHectare;

  RecipeCalculationResult({
    required this.products,
    required this.totalVolume,
    required this.hectaresCovered,
    required this.volumePerHectare,
  });
}

/// Serviço para cálculos de calda
class CaldaCalculationService {
  /// Calcula a receita completa
  static RecipeCalculationResult calculateRecipe(
    List<Product> products,
    CaldaConfig config,
  ) {
    List<ProductCalculationResult> results = [];
    
    for (Product product in products) {
      final result = _calculateProduct(product, config);
      results.add(result);
    }
    
    return RecipeCalculationResult(
      products: results,
      totalVolume: config.volumeLiters,
      hectaresCovered: config.hectaresCovered,
      volumePerHectare: config.volumePerHectare,
    );
  }

  /// Calcula um produto específico
  static ProductCalculationResult _calculateProduct(
    Product product,
    CaldaConfig config,
  ) {
    double dosePerHectare = _convertToDosePerHectare(product, config);
    double totalDose = dosePerHectare * config.hectaresCovered;
    
    // Converte para unidade de exibição apropriada
    String displayUnit;
    String displayValue;
    
    if (product.doseUnit == DoseUnit.g || product.doseUnit == DoseUnit.gPer100l) {
      if (totalDose >= 1000) {
        displayUnit = 'kg';
        displayValue = (totalDose / 1000).toStringAsFixed(2);
      } else {
        displayUnit = 'g';
        displayValue = totalDose.toStringAsFixed(2);
      }
    } else if (product.doseUnit == DoseUnit.ml || 
               product.doseUnit == DoseUnit.mlPer100l ||
               product.doseUnit == DoseUnit.l ||
               product.doseUnit == DoseUnit.lPer100l) {
      if (totalDose >= 1000) {
        displayUnit = 'L';
        displayValue = (totalDose / 1000).toStringAsFixed(2);
      } else {
        displayUnit = 'mL';
        displayValue = (totalDose * 1000).toStringAsFixed(0);
      }
    } else {
      displayUnit = product.doseUnit.symbol;
      displayValue = totalDose.toStringAsFixed(2);
    }
    
    return ProductCalculationResult(
      product: product,
      dosePerHectare: dosePerHectare,
      totalDose: totalDose,
      displayUnit: displayUnit,
      displayValue: displayValue,
    );
  }

  /// Converte dose do produto para dose por hectare
  static double _convertToDosePerHectare(Product product, CaldaConfig config) {
    double volumePerHectare = config.volumePerHectare;
    
    switch (product.doseUnit) {
      case DoseUnit.l:
        return product.dose;
      case DoseUnit.lPer100l:
        return (product.dose / 100) * volumePerHectare;
      case DoseUnit.ml:
        return product.dose / 1000; // Converte mL para L
      case DoseUnit.mlPer100l:
        return (product.dose / 100) * volumePerHectare / 1000;
      case DoseUnit.g:
        return product.dose;
      case DoseUnit.gPer100l:
        return (product.dose / 100) * volumePerHectare;
      case DoseUnit.kg:
        return product.dose * 1000; // Converte kg para g
      case DoseUnit.kgPer100l:
        return (product.dose / 100) * volumePerHectare * 1000;
      case DoseUnit.percentVv:
        return (product.dose / 100) * volumePerHectare;
    }
  }

  /// Calcula pré-calda baseada em volume específico
  static RecipeCalculationResult calculatePreCalda(
    List<Product> products,
    CaldaConfig originalConfig,
    double preCaldaVolume,
  ) {
    // Cria nova configuração com volume da pré-calda
    final preCaldaConfig = CaldaConfig(
      volumeLiters: preCaldaVolume,
      flowRate: originalConfig.flowRate,
      isFlowPerHectare: originalConfig.isFlowPerHectare,
      area: originalConfig.area,
      createdAt: originalConfig.createdAt,
    );
    
    return calculateRecipe(products, preCaldaConfig);
  }

  /// Sugere ordem de mistura dos produtos
  static List<Product> getMixingOrder(List<Product> products) {
    // Ordem sugerida baseada no tipo de formulação
    final orderPriority = {
      'SL': 1, // Soluções primeiro
      'SC': 2, // Suspensões
      'EC': 3, // Concentrados emulsionáveis
      'WG': 4, // Grânulos dispersíveis
      'WP': 5, // Pós molháveis
      'AD': 6, // Adjuvantes por último
    };
    
    List<Product> sortedProducts = List.from(products);
    sortedProducts.sort((a, b) {
      int priorityA = orderPriority[a.formulation.code] ?? 10;
      int priorityB = orderPriority[b.formulation.code] ?? 10;
      return priorityA.compareTo(priorityB);
    });
    
    return sortedProducts;
  }
}
