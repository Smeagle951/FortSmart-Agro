import 'package:flutter/material.dart';
import '../models/talhao_model.dart';
import '../utils/map_global_adapter.dart';
import 'maptiler_widget.dart';

/// Widget de mapa usando MapTiler
/// Esta classe oferece a mesma API que era usada anteriormente com o GoogleMapsWidget
/// para facilitar a migração do Google Maps para o MapTiler
class MapTilerMapsWidget extends StatelessWidget {
  final List<TalhaoModel> talhoes;
  final Function(TalhaoModel)? onTalhaoSelected;
  final Function(LatLng)? onMapTap;
  final List<LatLng>? drawingPoints;
  final Function(List<LatLng>)? onDrawingPointsChanged;
  final TalhaoModel? selectedTalhao;
  final bool isEditMode;
  final bool enableDrawing;
  final Color? drawingColor;
  final double? initialZoom;
  final LatLng? initialCenter;
  final bool showControls;
  final Function(LatLng)? onAddPoint;
  final Function(int)? onRemovePoint;
  final Function(int, LatLng)? onMovePoint;
  
  const MapTilerMapsWidget({
    super.key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.onMapTap,
    this.drawingPoints,
    this.onDrawingPointsChanged,
    this.selectedTalhao,
    this.isEditMode = false,
    this.enableDrawing = false,
    this.drawingColor = Colors.blue,
    this.initialZoom = 13.0,
    this.initialCenter,
    this.showControls = true,
    this.onAddPoint,
    this.onRemovePoint,
    this.onMovePoint,
  });

  @override
  Widget build(BuildContext context) {
    // Redirecionar para o widget MapTiler
    return MapTilerWidget(
      talhoes: talhoes,
      onTalhaoSelected: onTalhaoSelected,
      onMapTap: onMapTap,
      drawingPoints: drawingPoints,
      onDrawingPointsChanged: onDrawingPointsChanged,
      selectedTalhao: selectedTalhao,
      isEditMode: isEditMode,
      enableDrawing: enableDrawing,
      drawingColor: drawingColor,
      initialZoom: initialZoom,
      initialCenter: initialCenter,
      showControls: showControls,
      onAddPoint: onAddPoint,
      onRemovePoint: onRemovePoint,
      onMovePoint: onMovePoint,
    );
  }
}
