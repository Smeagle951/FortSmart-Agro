import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main/monitoring_controller.dart';
import '../../../services/offline_tile_provider.dart';

/// Widget do mapa para o módulo de monitoramento
class MonitoringMapWidget extends StatelessWidget {
  final MonitoringController controller;
  
  const MonitoringMapWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
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
        child: FlutterMap(
          options: MapOptions(
            center: const LatLng(-15.7801, -47.9292), // Brasília
            zoom: 13.0,
          ),
          children: [
            // Usar OfflineTileProvider para cache offline com MapTiler
            OfflineMapTileLayer(
              urlTemplate: 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u',
              userAgentPackageName: 'com.fortsmart.agro',
              maxZoom: 18,
              minZoom: 1,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: const LatLng(-15.7801, -47.9292),
                  builder: (ctx) => const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
