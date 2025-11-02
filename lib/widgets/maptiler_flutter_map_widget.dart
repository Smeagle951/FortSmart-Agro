import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import '../utils/maptiler_constants.dart';

/// Widget de mapa usando flutter_map com MapTiler como provedor de tiles
/// Substitui o FlutterMapWidget original, mas mantém a mesma API
class MapTilerFlutterMapWidget extends StatefulWidget {
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
  final String mapStyle;
  final bool useSatellite;

  const MapTilerFlutterMapWidget({
    Key? key,
    this.initialPosition = const LatLng(0, 0),
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
    this.mapStyle = 'streets',
    this.useSatellite = true,
  }) : super(key: key);

  @override
  State<MapTilerFlutterMapWidget> createState() => _MapTilerFlutterMapWidgetState();
}

class _MapTilerFlutterMapWidgetState extends State<MapTilerFlutterMapWidget> {
  final PopupController _popupController = PopupController();
  late MapController _mapController;
  String _tileUrl = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _updateTileUrl();
  }

  @override
  void didUpdateWidget(MapTilerFlutterMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapStyle != widget.mapStyle || 
        oldWidget.useSatellite != widget.useSatellite) {
      _updateTileUrl();
    }
  }

  void _updateTileUrl() {
    if (widget.useSatellite) {
      _tileUrl = MapTilerConstants.satelliteUrl;
    } else {
      switch (widget.mapStyle) {
        case 'streets':
          _tileUrl = MapTilerConstants.streetsUrl;
          break;
        case 'outdoor':
          _tileUrl = MapTilerConstants.outdoorUrl;
          break;
        case 'basic':
          _tileUrl = MapTilerConstants.basicUrl;
          break;
        default:
          _tileUrl = MapTilerConstants.streetsUrl;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.initialPosition,
        zoom: widget.initialZoom,
        minZoom: MapTilerConstants.minZoom,
        maxZoom: MapTilerConstants.maxZoom,
        onTap: widget.onTap != null 
          ? (tapPosition, point) => widget.onTap!(point)
          : null,
        onLongPress: widget.onLongPress != null 
          ? (tapPosition, point) => widget.onLongPress!(point)
          : null,
        onPositionChanged: widget.onPositionChanged,
      ),
      children: [
        // Camada de mapa base
        TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'com.fortsmartagro.app',
          tileProvider: NetworkTileProvider(),
          // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
        
        // Camada de polígonos
        PolygonLayer(
          polygons: widget.polygons,
        ),
        
        // Camada de polylines
        PolylineLayer(
          polylines: widget.polylines,
        ),
        
        // Camada de marcadores com popup
        MarkerLayer(
          markers: widget.markers,
        ),
        
        // Atribuição (se fornecida)
        if (widget.attributionWidget != null)
          AttributionLayer(
            attributionBuilder: (context) => widget.attributionWidget!,
          ),
      ],
    );
  }
  
  AttributionLayer({required Widget Function(dynamic context) attributionBuilder}) {}
}

// Widget auxiliar para envolver o conteúdo do popup
class PopupScope extends StatelessWidget {
  final Widget child;
  
  const PopupScope({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}
