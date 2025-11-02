import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Utilitários para criar marcadores padronizados do mapa
class MapMarkerHelper {
  /// Cria marcador para o ponto atual
  static Marker createCurrentPointMarker(LatLng position) {
    return Marker(
      point: position,
      width: 35,
      height: 35,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.location_on,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Cria marcador para o próximo ponto
  static Marker createNextPointMarker(LatLng position) {
    return Marker(
      point: position,
      width: 35,
      height: 35,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.navigation,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Cria marcador para infestação
  static Marker createInfestationMarker(
    LatLng position, 
    String type, 
    double severity,
  ) {
    Color markerColor;
    IconData iconData;
    
    switch (type.toLowerCase()) {
      case 'pest':
        markerColor = Colors.orange.shade600;
        iconData = Icons.bug_report;
        break;
      case 'disease':
        markerColor = Colors.red.shade600;
        iconData = Icons.healing;
        break;
      case 'weed':
        markerColor = Colors.purple.shade600;
        iconData = Icons.local_florist;
        break;
      default:
        markerColor = Colors.grey.shade600;
        iconData = Icons.warning;
    }
    
    return Marker(
      point: position,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            iconData,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  /// Cria marcador para alerta
  static Marker createAlertMarker(LatLng position, String severity) {
    Color markerColor;
    
    switch (severity.toLowerCase()) {
      case 'critical':
        markerColor = Colors.red.shade800;
        break;
      case 'high':
        markerColor = Colors.orange.shade800;
        break;
      case 'medium':
        markerColor = Colors.yellow.shade800;
        break;
      default:
        markerColor = Colors.grey.shade800;
    }
    
    return Marker(
      point: position,
      width: 25,
      height: 25,
      child: Container(
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.warning,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }
}
