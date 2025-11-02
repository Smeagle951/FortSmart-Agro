import 'package:flutter/material.dart';

/// Enum que representa as classes de produtos agrícolas disponíveis no sistema
enum ProductClass {
  seeds,
  solidFertilizers,
  liquidFertilizers,
  macroNutrients,
  microNutrients,
  fungicides,
  insecticides,
  herbicides,
  mineralOil,
  adjuvants,
  biological,
  other
}

/// Classe auxiliar para trabalhar com ProductClass, fornecendo métodos para
/// obter nome, cor, ícone e tipo de produto com base na classe
class ProductClassHelper {
  /// Obtém o nome em português da classe de produto
  static String getName(ProductClass productClass) {
    switch (productClass) {
      case ProductClass.seeds:
        return 'Sementes';
      case ProductClass.solidFertilizers:
        return 'Fertilizantes Sólidos';
      case ProductClass.liquidFertilizers:
        return 'Fertilizantes Líquidos Foliares';
      case ProductClass.macroNutrients:
        return 'Fertilizantes - Macro Nutrientes';
      case ProductClass.microNutrients:
        return 'Fertilizantes - Micro Nutrientes';
      case ProductClass.fungicides:
        return 'Fungicidas';
      case ProductClass.insecticides:
        return 'Inseticidas';
      case ProductClass.herbicides:
        return 'Herbicidas';
      case ProductClass.mineralOil:
        return 'Óleo Mineral';
      case ProductClass.adjuvants:
        return 'Adjuvantes';
      case ProductClass.biological:
        return 'Biológicos';
      case ProductClass.other:
        return 'Outros';
    }
  }

  /// Obtém a cor associada à classe de produto
  static Color getColor(ProductClass productClass) {
    switch (productClass) {
      case ProductClass.seeds:
        return const Color(0xFF8D6E63); // Marrom
      case ProductClass.solidFertilizers:
        return const Color(0xFF689F38); // Verde Musgo
      case ProductClass.liquidFertilizers:
        return const Color(0xFF4FC3F7); // Azul Claro
      case ProductClass.macroNutrients:
        return const Color(0xFF388E3C); // Verde
      case ProductClass.microNutrients:
        return const Color(0xFF7E57C2); // Roxo
      case ProductClass.fungicides:
        return const Color(0xFF9575CD); // Lilás
      case ProductClass.insecticides:
        return const Color(0xFFE53935); // Vermelho
      case ProductClass.herbicides:
        return const Color(0xFFFB8C00); // Laranja
      case ProductClass.mineralOil:
        return const Color(0xFF546E7A); // Cinza Escuro
      case ProductClass.adjuvants:
        return const Color(0xFFFBC02D); // Amarelo
      case ProductClass.biological:
        return const Color(0xFF1976D2); // Azul Escuro
      case ProductClass.other:
        return const Color(0xFF9E9E9E); // Cinza
    }
  }

  /// Obtém o ícone associado à classe de produto
  static IconData getIcon(ProductClass productClass) {
    switch (productClass) {
      case ProductClass.seeds:
        return Icons.grass;
      case ProductClass.solidFertilizers:
        return Icons.landscape;
      case ProductClass.liquidFertilizers:
        return Icons.water_drop;
      case ProductClass.macroNutrients:
        return Icons.grain;
      case ProductClass.microNutrients:
        return Icons.science;
      case ProductClass.fungicides:
        return Icons.bug_report;
      case ProductClass.insecticides:
        return Icons.pest_control;
      case ProductClass.herbicides:
        return Icons.eco;
      case ProductClass.mineralOil:
        return Icons.oil_barrel;
      case ProductClass.adjuvants:
        return Icons.add_circle_outline;
      case ProductClass.biological:
        return Icons.biotech;
      case ProductClass.other:
        return Icons.category;
    }
  }

  /// Obtém o tipo de produto com base na classe
  static String getProductType(ProductClass productClass) {
    switch (productClass) {
      case ProductClass.seeds:
        return 'Semente';
      case ProductClass.solidFertilizers:
      case ProductClass.liquidFertilizers:
      case ProductClass.macroNutrients:
      case ProductClass.microNutrients:
        return 'Fertilizante';
      case ProductClass.fungicides:
      case ProductClass.insecticides:
      case ProductClass.herbicides:
        return 'Defensivo';
      case ProductClass.mineralOil:
      case ProductClass.adjuvants:
        return 'Adjuvante';
      case ProductClass.biological:
        return 'Biológico';
      case ProductClass.other:
        return 'Outro';
    }
  }

  /// Converte uma string para o enum ProductClass
  static ProductClass fromString(String value) {
    return ProductClass.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ProductClass.other,
    );
  }

  /// Lista todas as classes de produtos disponíveis
  static List<ProductClass> getAllClasses() {
    return ProductClass.values;
  }
}
