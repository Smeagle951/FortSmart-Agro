import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import 'maptiler_talhao_widget.dart';

/// Widget para exibir o mapa com os talhões, agora usando MapTiler
/// Mantém a mesma API do widget original para facilitar a migração
class TalhaoMapWidget extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  final TalhaoModel? selectedTalhao;
  final List<LatLng> drawingPoints;
  final bool isDrawingMode;
  final bool isSatelliteMode;
  final Function(LatLng) onMapTap;
  final Function(TalhaoModel) onTalhaoTap;
  final Function(dynamic) onMapCreated;
  final Function() onMyLocationPressed;
  final Function() onDrawingModeToggled;
  final Function() onClearDrawing;

  const TalhaoMapWidget({
    Key? key,
    required this.talhoes,
    this.selectedTalhao,
    required this.drawingPoints,
    required this.isDrawingMode,
    required this.isSatelliteMode,
    required this.onMapTap,
    required this.onTalhaoTap,
    required this.onMapCreated,
    required this.onMyLocationPressed,
    required this.onDrawingModeToggled,
    required this.onClearDrawing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirecionar para o widget compatível com MapTiler
    return MapTilerTalhaoWidget(
      talhoes: talhoes,
      selectedTalhao: selectedTalhao,
      drawingPoints: drawingPoints,
      isDrawingMode: isDrawingMode,
      isSatelliteMode: isSatelliteMode,
      onMapTap: onMapTap,
      onTalhaoTap: onTalhaoTap,
      onMapCreated: onMapCreated,
      onMyLocationPressed: onMyLocationPressed,
      onDrawingModeToggled: onDrawingModeToggled,
      onClearDrawing: onClearDrawing,
    );
  }
}
