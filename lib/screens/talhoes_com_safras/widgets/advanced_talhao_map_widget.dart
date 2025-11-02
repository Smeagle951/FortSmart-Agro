import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget avançado para mapa de talhões
class AdvancedTalhaoMapWidget extends StatefulWidget {
  final List<dynamic> talhoes;
  final Function(dynamic)? onTalhaoSelected;
  final LatLng? center;
  final double? zoom;

  const AdvancedTalhaoMapWidget({
    Key? key,
    required this.talhoes,
    this.onTalhaoSelected,
    this.center,
    this.zoom,
  }) : super(key: key);

  @override
  State<AdvancedTalhaoMapWidget> createState() => _AdvancedTalhaoMapWidgetState();
}

class _AdvancedTalhaoMapWidgetState extends State<AdvancedTalhaoMapWidget> {
  late MapController _mapController;

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
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.center ?? const LatLng(-15.7801, -47.9292),
        zoom: widget.zoom ?? 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    return widget.talhoes.map((talhao) {
      // Placeholder para coordenadas - ajustar conforme necessário
      final latLng = const LatLng(-15.7801, -47.9292);
      
      return Marker(
        point: latLng,
        child: GestureDetector(
          onTap: () => widget.onTalhaoSelected?.call(talhao),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.crop_square,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }
}
