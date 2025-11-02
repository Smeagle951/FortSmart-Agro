import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Constantes utilizadas na tela de talhões
class PlotConstants {
  // Cores
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF388E3C);
  static const Color accentColor = Color(0xFF8BC34A);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA000);
  
  // Estilos de polígono
  static const PolygonId defaultPolygonId = PolygonId('plot_polygon');
  
  static const polygonFillColor = Color(0xFF4CAF50);
  static const polygonStrokeColor = Color(0xFF388E3C);
  static const polygonFillOpacity = 0.3;
  static const polygonStrokeWidth = 2.0;
  
  static const selectedPolygonFillColor = Color(0xFF8BC34A);
  static const selectedPolygonStrokeColor = Color(0xFF689F38);
  static const selectedPolygonFillOpacity = 0.5;
  static const selectedPolygonStrokeWidth = 3.0;
  
  // Configurações do mapa
  static const mapZoomDefault = 15.0;
  static const mapZoomMin = 5.0;
  static const mapZoomMax = 20.0;
  
  // Configurações de GPS
  static const gpsMinAccuracy = 10.0; // metros
  static const gpsMinDistance = 5.0; // metros entre pontos
  
  // Mensagens
  static const msgSaving = 'Salvando talhão...';
  static const msgLoading = 'Carregando talhões...';
  static const msgImporting = 'Importando arquivo KML...';
  static const msgGpsTracking = 'Rastreamento GPS ativado. Toque para adicionar pontos.';
  static const msgDrawMode = 'Modo desenho ativado. Toque no mapa para adicionar pontos.';
  static const msgEraseMode = 'Modo borracha ativado. Toque nos pontos para removê-los.';
  
  // Textos de ajuda
  static const helpDrawMode = 'Toque no mapa para adicionar pontos e formar o talhão.';
  static const helpGpsMode = 'Use o GPS para adicionar pontos automaticamente enquanto se move pelo talhão.';
  static const helpEraseMode = 'Toque em um ponto existente para removê-lo do talhão.';
  static const helpImportKml = 'Importe um arquivo KML para criar um talhão automaticamente.';
  
  // Configurações de interface
  static const double drawerWidth = 320.0;
  static const double fabSpacing = 8.0;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
}
