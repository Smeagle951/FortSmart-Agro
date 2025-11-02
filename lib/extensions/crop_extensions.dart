import 'package:flutter/material.dart';
import '../database/models/crop.dart';

/// Extensões para a classe Crop
extension CropExtensions on Crop {
  /// Retorna cor verde padrão para todos os polígonos (sem cores por cultura)
  Color get corDinamica {
    // Retorna sempre cor verde padrão - sistema de cores por cultura descontinuado
    return Colors.green;
  }
}
