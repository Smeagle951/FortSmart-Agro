import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget responsável pelo mini mapa do ponto de monitoramento
class MiniMapWidget extends StatelessWidget {
  final LatLng centerPoint;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<Polygon> polygons;
  final VoidCallback? onMapTap;
  final VoidCallback? onFullMapTap;
  final double height;
  final double zoom;

  const MiniMapWidget({
    Key? key,
    required this.centerPoint,
    this.markers = const [],
    this.polylines = const [],
    this.polygons = const [],
    this.onMapTap,
    this.onFullMapTap,
    this.height = 300.0,
    this.zoom = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Stack(
            children: [
              // Mapa principal
              FlutterMap(
                options: MapOptions(
                  initialCenter: centerPoint,
                  initialZoom: zoom,
                  minZoom: 12.0,
                  maxZoom: 18.0,
                  onTap: (_, __) => onMapTap?.call(),
                ),
                children: [
                  // Camada de tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fortsmart.agro',
                    maxZoom: 18,
                  ),
                  
                  // Camada de polígonos (talhões)
                  if (polygons.isNotEmpty)
                    PolygonLayer(polygons: polygons),
                  
                  // Camada de polylines (rotas)
                  if (polylines.isNotEmpty)
                    PolylineLayer(polylines: polylines),
                  
                  // Camada de marcadores
                  if (markers.isNotEmpty)
                    MarkerLayer(markers: markers),
                ],
              ),
              
              // Botão de mapa completo
              if (onFullMapTap != null)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: FloatingActionButton.small(
                    onPressed: onFullMapTap,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    child: const Icon(Icons.fullscreen),
                  ),
                ),
              
              // Indicador de carregamento (se necessário)
              if (markers.isEmpty && polylines.isEmpty)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Classe MapMarkerHelper movida para utils/map_marker_helper.dart
