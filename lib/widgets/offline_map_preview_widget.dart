import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// Widget para visualização de mapas offline
class OfflineMapPreviewWidget extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final double height;
  final bool showControls;
  final VoidCallback? onTap;

  const OfflineMapPreviewWidget({
    Key? key,
    required this.mapData,
    this.height = 200,
    this.showControls = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<OfflineMapPreviewWidget> createState() => _OfflineMapPreviewWidgetState();
}

class _OfflineMapPreviewWidgetState extends State<OfflineMapPreviewWidget> {
  late MapController _mapController;
  String _currentMapType = 'satellite';
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Mapa
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _getMapCenter(),
                zoom: _getInitialZoom(),
                minZoom: 3,
                maxZoom: 20,
                onTap: (tapPosition, point) => widget.onTap?.call(),
              ),
              children: [
                // Camada de tiles
                TileLayer(
                  urlTemplate: _getMapTileUrl(),
                  userAgentPackageName: 'com.fortsmart.agro',
                ),
                
                // Camada de polígonos se disponível
                if (widget.mapData['polygon'] != null)
                  PolygonLayer(
                    polygons: _buildPolygons(),
                  ),
                
                // Camada de marcadores se disponível
                if (widget.mapData['markers'] != null)
                  MarkerLayer(
                    markers: _buildMarkers(),
                  ),
              ],
            ),
            
            // Controles do mapa
            if (widget.showControls)
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    // Botão de alternar tipo de mapa
                    FloatingActionButton(
                      heroTag: 'map_type_${widget.mapData['id']}',
                      mini: true,
                      onPressed: _toggleMapType,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[600],
                      child: Icon(_getMapTypeIcon()),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Botão de centralizar
                    FloatingActionButton(
                      heroTag: 'center_${widget.mapData['id']}',
                      mini: true,
                      onPressed: _centerMap,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[600],
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            
            // Overlay de informações
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.mapData['name'] ?? 'Mapa',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.zoom_in,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Zoom: ${_getZoomRange()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.storage,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.mapData['sizeMB'] ?? 0} MB',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Obtém centro do mapa
  LatLng _getMapCenter() {
    if (widget.mapData['center'] != null) {
      final center = widget.mapData['center'];
      return LatLng(center['lat'], center['lng']);
    }
    
    // Centro padrão (Brasília)
    return const LatLng(-15.7801, -47.9292);
  }
  
  /// Obtém zoom inicial
  double _getInitialZoom() {
    return widget.mapData['initialZoom']?.toDouble() ?? 14.0;
  }
  
  /// Obtém URL do tile do mapa
  String _getMapTileUrl() {
    switch (_currentMapType) {
      case 'satellite':
        return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u';
      case 'hybrid':
        return 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u';
      case 'streets':
        return 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u';
      default:
        return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u';
    }
  }
  
  /// Constrói polígonos
  List<Polygon> _buildPolygons() {
    if (widget.mapData['polygon'] == null) return [];
    
    final polygonData = widget.mapData['polygon'];
    final points = (polygonData['coordinates'] as List)
        .map((coord) => LatLng(coord[1], coord[0]))
        .toList();
    
    return [
      Polygon(
        points: points,
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
      ),
    ];
  }
  
  /// Constrói marcadores
  List<Marker> _buildMarkers() {
    if (widget.mapData['markers'] == null) return [];
    
    return (widget.mapData['markers'] as List).map<Marker>((markerData) {
      return Marker(
        point: LatLng(markerData['lat'], markerData['lng']),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
    }).toList();
  }
  
  /// Alterna tipo de mapa
  void _toggleMapType() {
    setState(() {
      switch (_currentMapType) {
        case 'satellite':
          _currentMapType = 'hybrid';
          break;
        case 'hybrid':
          _currentMapType = 'streets';
          break;
        case 'streets':
          _currentMapType = 'satellite';
          break;
        default:
          _currentMapType = 'satellite';
      }
    });
  }
  
  /// Centraliza mapa
  void _centerMap() {
    _mapController.move(_getMapCenter(), _getInitialZoom());
  }
  
  /// Obtém ícone do tipo de mapa
  IconData _getMapTypeIcon() {
    switch (_currentMapType) {
      case 'satellite':
        return Icons.satellite;
      case 'hybrid':
        return Icons.layers;
      case 'streets':
        return Icons.map;
      default:
        return Icons.satellite;
    }
  }
  
  /// Obtém range de zoom
  String _getZoomRange() {
    final minZoom = widget.mapData['minZoom'] ?? 12;
    final maxZoom = widget.mapData['maxZoom'] ?? 18;
    return '$minZoom-$maxZoom';
  }
}
