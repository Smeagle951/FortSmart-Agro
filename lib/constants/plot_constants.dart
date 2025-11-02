import 'package:flutter/material.dart';

/// Constantes para a exibição de talhões no mapa
class PlotConstants {
  // Cores de preenchimento
  static const Color polygonFillColor = Color(0xFF4CAF50);
  static const Color selectedPolygonFillColor = Color(0xFF2196F3);
  
  // Opacidade de preenchimento
  static const double polygonFillOpacity = 0.3;
  static const double selectedPolygonFillOpacity = 0.5;
  
  // Cores de contorno
  static const Color polygonStrokeColor = Color(0xFF388E3C);
  static const Color selectedPolygonStrokeColor = Color(0xFF1976D2);
  
  // Largura de contorno
  static const int polygonStrokeWidth = 2;
  static const int selectedPolygonStrokeWidth = 3;
  
  // Tamanho dos marcadores
  static const double markerSize = 30.0;
  
  // Zoom padrão do mapa
  static const double defaultZoom = 15.0;
}
