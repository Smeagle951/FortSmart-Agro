import 'package:flutter/material.dart';

/// Utilitário para manipulação de cores e ícones de culturas agrícolas
class CropUtils {
  /// Retorna a cor correspondente ao tipo de cultura
  static Color getCropColor(String? cropType) {
    if (cropType == null) return Colors.green.withOpacity(0.7);
    
    switch (cropType.toLowerCase()) {
      case 'soja':
        return Colors.green.shade700;
      case 'milho':
        return Colors.amber.shade600;
      case 'algodão':
        return Colors.lightBlue.shade300;
      case 'trigo':
        return Colors.amber.shade800;
      case 'café':
        return Colors.brown.shade600;
      case 'cana':
      case 'cana-de-açúcar':
        return Colors.lightGreen.shade600;
      case 'arroz':
        return Colors.amber.shade100;
      case 'feijão':
        return Colors.brown.shade400;
      case 'sorgo':
        return Colors.deepOrange.shade300;
      case 'girassol':
        return Colors.yellow.shade600;
      case 'batata':
        return Colors.brown.shade300;
      case 'tomate':
        return Colors.red.shade600;
      case 'citrus':
        return Colors.orange.shade400;
      case 'uva':
        return Colors.purple.shade400;
      case 'mamão':
        return Colors.orange.shade300;
      case 'abacaxi':
        return Colors.amber.shade300;
      case 'banana':
        return Colors.yellow.shade400;
      case 'pastagem':
        return Colors.lightGreen.shade300;
      default:
        return Colors.green.withOpacity(0.7);
    }
  }
  
  /// Retorna o ícone correspondente ao tipo de cultura
  static IconData getCropIcon(String? cropType) {
    if (cropType == null) return Icons.grass;
    
    switch (cropType.toLowerCase()) {
      case 'soja':
        return Icons.eco;
      case 'milho':
        return Icons.grain;
      case 'algodão':
        return Icons.bubble_chart;
      case 'trigo':
        return Icons.grass;
      case 'café':
        return Icons.coffee;
      case 'cana':
      case 'cana-de-açúcar':
        return Icons.grass_outlined;
      case 'arroz':
        return Icons.grain_outlined;
      case 'feijão':
        return Icons.spa;
      case 'sorgo':
        return Icons.grass;
      case 'girassol':
        return Icons.wb_sunny_outlined;
      case 'batata':
        return Icons.circle;
      case 'tomate':
        return Icons.circle;
      case 'citrus':
        return Icons.circle;
      case 'uva':
        return Icons.circle;
      case 'mamão':
        return Icons.circle;
      case 'abacaxi':
        return Icons.circle;
      case 'banana':
        return Icons.circle;
      case 'pastagem':
        return Icons.grass;
      default:
        return Icons.grass;
    }
  }
  
  /// Retorna o nome formatado da cultura
  static String getFormattedCropName(String? cropType, String? cropName) {
    if (cropName != null && cropName.isNotEmpty) {
      return cropName;
    }
    
    if (cropType == null) return "Sem cultura";
    
    // Capitaliza a primeira letra de cada palavra
    return cropType.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
