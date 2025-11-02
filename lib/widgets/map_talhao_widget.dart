import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';

/// Widget do mapa para talhões
class MapTalhaoWidget extends StatelessWidget {
  final MapController? mapController;
  final LatLng? userLocation;
  final List<LatLng> currentPoints;
  final List<TalhaoModel> talhoes;
  final bool isDrawing;
  final Function(LatLng) onTap;
  final Function(TalhaoModel) onTalhaoTap;

  const MapTalhaoWidget({
    Key? key,
    this.mapController,
    this.userLocation,
    required this.currentPoints,
    required this.talhoes,
    required this.isDrawing,
    required this.onTap,
    required this.onTalhaoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userLocation ?? const LatLng(-23.5505, -46.6333), // São Paulo
        initialZoom: 15.0,
        onTap: (tapPosition, point) => onTap(point),
        minZoom: 10.0,
        maxZoom: 20.0,
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=YOUR_MAPTILER_KEY',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Polígonos dos talhões
        PolygonLayer(
          polygons: _buildTalhaoPolygons(),
        ),
        
        // Pontos atuais sendo desenhados
        if (currentPoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: currentPoints,
                color: Colors.blue,
                strokeWidth: 3.0,
              ),
            ],
          ),
        
        // Marcadores dos talhões
        MarkerLayer(
          markers: _buildTalhaoMarkers(),
        ),
        
        // Marcador da localização do usuário
        if (userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation!,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<Polygon> _buildTalhaoPolygons() {
    return talhoes.map((talhao) {
      return Polygon(
        points: talhao.pontos,
        color: _getColorForTalhao(talhao).withOpacity(0.3),
        borderColor: _getColorForTalhao(talhao),
        borderStrokeWidth: 2.0,
        isFilled: true,
      );
    }).toList();
  }

  List<Marker> _buildTalhaoMarkers() {
    return talhoes.map((talhao) {
      final centroid = _calculateCentroid(talhao.pontos);
      return Marker(
        point: centroid,
        child: GestureDetector(
          onTap: () => onTalhaoTap(talhao),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorForTalhao(talhao),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              talhao.nome,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getColorForTalhao(TalhaoModel talhao) {
    // Cores baseadas na cultura (pode ser melhorado)
    final colorMap = {
      'Soja': Colors.green,
      'Milho': Colors.yellow,
      'Algodão': const Color(0xFFE0E0E0), // Cinza claro
      'Café': Colors.brown,
      'Cana-de-açúcar': Colors.orange,
    };
    
    return colorMap[talhao.culturaId] ?? Colors.blue;
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0.0;
    double lngSum = 0.0;
    
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}
