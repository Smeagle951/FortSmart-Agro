import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

// Redirecionamento para a nova implementação com MapTiler
import 'maptiler_flutter_map_widget.dart';

/// Widget de mapa usando flutter_map
/// Esta classe agora redireciona para MapTilerFlutterMapWidget
class FlutterMapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final double initialZoom;
  final List<Marker> markers;
  final List<Polygon> polygons;
  final List<Polyline> polylines;
  final bool showLocationMarker;
  final bool enableRotation;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final Function(MapPosition, bool)? onPositionChanged;
  final Widget? attributionWidget;
  final String? mapboxToken; // Mantido para compatibilidade
  final String mapStyle;
  final bool useMapbox; // Mantido para compatibilidade

  const FlutterMapWidget({
    Key? key,
    this.initialPosition = LatLng(0, 0),
    this.initialZoom = 13.0,
    this.markers = const [],
    this.polygons = const [],
    this.polylines = const [],
    this.showLocationMarker = false,
    this.enableRotation = false,
    this.onTap,
    this.onLongPress,
    this.onPositionChanged,
    this.attributionWidget,
    this.mapboxToken,
    this.mapStyle = 'streets-v11',
    this.useMapbox = false,
  }) : super(key: key);

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  final PopupController _popupController = PopupController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Redirecionar para a nova implementação com MapTiler
    return MapTilerFlutterMapWidget(
      initialPosition: widget.initialPosition,
      initialZoom: widget.initialZoom,
      markers: widget.markers,
      polygons: widget.polygons,
      polylines: widget.polylines,
      showLocationMarker: widget.showLocationMarker,
      enableRotation: widget.enableRotation,
      // onTap: widget.onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
      onLongPress: widget.onLongPress,
      onPositionChanged: widget.onPositionChanged,
      attributionWidget: widget.attributionWidget,
      mapStyle: widget.mapStyle.replaceAll('-v11', ''),
      useSatellite: widget.mapStyle.contains('satellite'), zoom: widget.initialZoom,
    );
  }
  
  @override
  void dispose() {
    _popupController.dispose();
    super.dispose();
  }
}

extension on PopupController {
  void dispose() {}
}

// Widget auxiliar para envolver o conteúdo do popup
class PopupScope extends StatelessWidget {
  final Widget child;
  
  const PopupScope({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return child;
  }
}
