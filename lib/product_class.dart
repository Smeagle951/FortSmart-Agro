import 'package:flutter/material.dart';

/// Enumeração das classes de produtos agrícolas
/// Usada para cadastro, filtro e exibição de tags coloridas

enum ProductClass {
  sementes,
  fertilizanteSolido,
  fertilizanteLiquido,
  macroNutriente,
  microNutriente,
  fungicida,
  inseticida,
  herbicida,
  oleoMineral,
  adjuvante,
  biologico,
  outros,
}

class ProductClassHelper {
  static String getName(ProductClass c) {
    switch (c) {
      case ProductClass.sementes:
        return 'Sementes';
      case ProductClass.fertilizanteSolido:
        return 'Fertilizantes Sólidos';
      case ProductClass.fertilizanteLiquido:
        return 'Fertilizantes Líquidos Foliares';
      case ProductClass.macroNutriente:
        return 'Fertilizantes – Macro Nutrientes';
      case ProductClass.microNutriente:
        return 'Fertilizantes – Micro Nutrientes';
      case ProductClass.fungicida:
        return 'Fungicidas';
      case ProductClass.inseticida:
        return 'Inseticidas';
      case ProductClass.herbicida:
        return 'Herbicidas';
      case ProductClass.oleoMineral:
        return 'Óleo Mineral';
      case ProductClass.adjuvante:
        return 'Adjuvantes';
      case ProductClass.biologico:
        return 'Biológicos';
      case ProductClass.outros:
        return 'Outros produtos agrícolas';
    }
  }

  static Color getColor(ProductClass c) {
    switch (c) {
      case ProductClass.sementes:
        return const Color(0xFF8D6E63); // Marrom
      case ProductClass.fertilizanteSolido:
        return const Color(0xFF689F38); // Verde Musgo
      case ProductClass.fertilizanteLiquido:
        return const Color(0xFF4FC3F7); // Azul Claro
      case ProductClass.macroNutriente:
        return const Color(0xFF388E3C); // Verde
      case ProductClass.microNutriente:
        return const Color(0xFF7E57C2); // Roxo
      case ProductClass.fungicida:
        return const Color(0xFF9575CD); // Lilás
      case ProductClass.inseticida:
        return const Color(0xFFE53935); // Vermelho
      case ProductClass.herbicida:
        return const Color(0xFFFB8C00); // Laranja
      case ProductClass.oleoMineral:
        return const Color(0xFF546E7A); // Cinza Escuro
      case ProductClass.adjuvante:
        return const Color(0xFFFBC02D); // Amarelo
      case ProductClass.biologico:
        return const Color(0xFF1976D2); // Azul Escuro
      case ProductClass.outros:
        return Colors.grey;
    }
  }
}
