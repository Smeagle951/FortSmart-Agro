import 'package:flutter/material.dart';
import '../utils/map_global_adapter.dart';
import '../models/talhao_model.dart';
import 'maptiler_widget.dart';

/// Widget de mapa usando MapTiler como substituto do Google Maps
/// Esta classe é apenas um redirecionamento para MapTilerWidget para manter compatibilidade
/// com código existente que ainda usa GoogleMapsWidget
class GoogleMapsWidget extends StatelessWidget {
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
  
  const GoogleMapsWidget({
    Key? key,
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
  }) : super(key: key);

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
      zoom: initialZoom,
      center: initialCenter,
      showControls: showControls,
      onAddPoint: onAddPoint,
      onRemovePoint: onRemovePoint,
      onMovePoint: onMovePoint,
    );
  }
}
