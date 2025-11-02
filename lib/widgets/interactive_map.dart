import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/plot.dart';

class InteractiveMap extends StatefulWidget {
  final List<Plot> plots;
  final List<LatLng> drawingPoints;
  final Function(List<LatLng>) onDrawingPointsChanged;
  final Function(LatLng) onMapTap;
  final Function(Plot) onPlotTap;
  final bool isDrawingMode;
  final bool isGpsTrackingMode;
  final bool isEraseMode;
  final double currentArea;

  const InteractiveMap({
    Key? key,
    required this.plots,
    required this.drawingPoints,
    required this.onDrawingPointsChanged,
    required this.onMapTap,
    required this.onPlotTap,
    this.isDrawingMode = false,
    this.isGpsTrackingMode = false,
    this.isEraseMode = false,
    this.currentArea = 0.0,
  }) : super(key: key);

  @override
  _InteractiveMapState createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  late MapController _mapController;
  List<Marker> _markers = [];
  List<Polygon> _polygons = [];
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    _updateMapElements();
  }

  @override
  void didUpdateWidget(InteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plots != widget.plots ||
        oldWidget.drawingPoints != widget.drawingPoints ||
        oldWidget.isDrawingMode != widget.isDrawingMode) {
      _updateMapElements();
    }
  }

  void _updateMapElements() {
    List<Marker> newMarkers = [];
    List<Polygon> newPolygons = [];

    for (final plot in widget.plots) {
      try {
        if (plot.coordinates?.isNotEmpty == true) {
          final coordinates = plot.coordinates!;
          final List<LatLng> points = coordinates
              .map((point) => LatLng(point['latitude'] ?? 0.0, point['longitude'] ?? 0.0))
              .toList();

          if (points.isNotEmpty) {
            newPolygons.add(
              Polygon(
                points: points,
                color: Colors.green.withOpacity(0.3),
                borderColor: Colors.green,
                borderStrokeWidth: 2.0,
              ),
            );

            final LatLng center = _calculatePolygonCenter(points);
            newMarkers.add(
              Marker(
                point: center,
                width: 40,
                height: 40,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Erro ao processar talhão ${plot.id}: $e');
      }
    }

    if (widget.drawingPoints.length > 1) {
      newPolygons.add(
        Polygon(
          points: widget.drawingPoints,
          color: Colors.green.withOpacity(0.3),
          borderColor: Colors.green,
          borderStrokeWidth: 2.0,
        ),
      );
    }

    for (int i = 0; i < widget.drawingPoints.length; i++) {
      newMarkers.add(
        Marker(
          point: widget.drawingPoints[i],
          width: 40,
          height: 40,
          builder: (context) => GestureDetector(
            onTap: () {
              // Atualizar pontos quando o usuário toca em um marcador
              final newPoints = List<LatLng>.from(widget.drawingPoints);
              widget.onDrawingPointsChanged(newPoints);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
      _polygons = newPolygons;
    });
  }

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    double latitude = 0;
    double longitude = 0;

    for (var point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }

    return LatLng(
      latitude / points.length,
      longitude / points.length,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _currentPosition = LatLng(-15.77972, -47.92972); // Brasília como exemplo
      });
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Mapa MapBox
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentPosition ?? LatLng(-22.9068, -43.1729), // Rio de Janeiro
            zoom: 10,
            onTap: widget.isDrawingMode ? (tapPosition, point) => widget.onMapTap.call(point) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://api.mapbox.com/styles/v1/jeferson14/cmb1bkbg500f801se8uocf8hf/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiamVmZXJzb24xNCIsImEiOiJjbTlzeTJiMDEwNXV6MnFwcGRxZXp4bmRpIn0.-yYu9cTGnNyLOaKlMXZyIw',
              additionalOptions: {
                'accessToken': 'pk.eyJ1IjoiamVmZXJzb24xNCIsImEiOiJjbTlzeTJiMDEwNXV6MnFwcGRxZXp4bmRpIn0.-yYu9cTGnNyLOaKlMXZyIw',
              },
            ),
            PolygonLayer(polygons: _polygons),
            MarkerLayer(markers: _markers),
            // Marcador da localização atual
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 40,
                    height: 40,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
          ],
        ),
        
        // Indicador de área (quando em modo de desenho)
        if (widget.isDrawingMode && widget.drawingPoints.length >= 3)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.area_chart, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Text(
                    'Área: ${widget.currentArea.toStringAsFixed(2)} ha',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Modo de desenho
        if (widget.isDrawingMode)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Modo: Desenho Manual',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
