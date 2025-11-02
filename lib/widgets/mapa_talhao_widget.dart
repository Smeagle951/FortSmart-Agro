import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget do mapa principal do Novo Talhão Premium (com MapTiler)
class MapaTalhaoWidget extends StatelessWidget {
  final List<Polygon> polygons;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final Widget? overlay;
  final void Function(LatLng)? onMapTap;
  final LatLng? initialCenter;
  final double initialZoom;

  const MapaTalhaoWidget({
    Key? key,
    this.polygons = const [],
    this.markers = const [],
    this.polylines = const [],
    this.overlay,
    this.onMapTap,
    this.initialCenter,
    this.initialZoom = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: MapOptions(
              center: initialCenter ?? LatLng(-15.793889, -47.882778),
              zoom: initialZoom,
              onTap: (tapPosition, point) => onMapTap?.call(point),
              interactiveFlags: InteractiveFlag.all,
              maxZoom: 20,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u',
                userAgentPackageName: 'com.fortsmart.agro',
                tileProvider: NetworkTileProvider(),
              ),
              if (polygons.isNotEmpty)
                PolygonLayer(polygons: polygons),
              if (polylines.isNotEmpty)
                PolylineLayer(polylines: polylines),
              if (markers.isNotEmpty)
                MarkerLayer(markers: markers),
            ],
          ),
          // Overlay visual para modo de criação de novo talhão
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Modo de Criação de Talhão Ativo',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Overlay customizado (ex: CustomPaint para desenho do polígono)
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
