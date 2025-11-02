import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong2;
import './maptiler_compatibility.dart' as maptiler;
import 'dart:math' as math;

// Importar apenas o que precisamos para evitar conflitos
import 'google_maps_types.dart' as google_maps_types;
import 'maptiler_config.dart';

// Adaptador para compatibilidade com código que usava Google Maps
// Isso permite uma migração mais suave sem precisar reescrever todo o código

// Adaptador para LatLng do Google Maps
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  // Converter para LatLng do latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }

  // Criar a partir de LatLng do latlong2
  static LatLng fromLatLong2(latlong2.LatLng latLng) {
    return LatLng(latLng.latitude, latLng.longitude);
  }

  @override
  String toString() => 'LatLng(latitude: $latitude, longitude: $longitude)';
}

// Adaptador para LatLngBounds do Google Maps
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds(this.southwest, this.northeast);

  // Construtor nomeado para compatibilidade com código existente
  LatLngBounds.fromPoints(List<LatLng> points) :
    southwest = _calculateSouthWest(points),
    northeast = _calculateNorthEast(points);

  // Método estático para calcular o ponto sudoeste
  static LatLng _calculateSouthWest(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(-10, -10); // Valor padrão
    }

    double minLat = double.infinity;
    double minLng = double.infinity;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
    }

    return LatLng(minLat, minLng);
  }

  // Método estático para calcular o ponto nordeste
  static LatLng _calculateNorthEast(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(10, 10); // Valor padrão
    }

    double maxLat = -double.infinity;
    double maxLng = -double.infinity;

    for (final point in points) {
      maxLat = math.max(maxLat, point.latitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLng(maxLat, maxLng);
  }

  // Converter para LatLngBounds do flutter_map
  LatLngBounds.fromLatLng(LatLng southwest, LatLng northeast) :
    southwest = southwest,
    northeast = northeast;

  // Converter para LatLngBounds do latlong2
  maptiler.LatLngBounds toLatLong2Bounds() {
    return maptiler.LatLngBounds(
      latlong2.LatLng(southwest.latitude, southwest.longitude),
      latlong2.LatLng(northeast.latitude, northeast.longitude),
    );
  }

  // Criar a partir de LatLngBounds do latlong2
  static LatLngBounds fromLatLong2Bounds(maptiler.LatLngBounds bounds) {
    return LatLngBounds(
      LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
      LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
    );
  }

  // Método para calcular o centro do bounds
  LatLng getCenter() {
    final lat = (southwest.latitude + northeast.latitude) / 2;
    final lng = (southwest.longitude + northeast.longitude) / 2;
    return LatLng(lat, lng);
  }

  // Método para verificar se um ponto está dentro do bounds
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
}

// Adaptador para Marker do Google Maps
class Marker {
  final MarkerId markerId;
  final LatLng position;
  final bool draggable;
  final Function(MarkerId, LatLng)? onDragEnd;
  final BitmapDescriptor? icon;
  final Function()? onTap;

  Marker({
    required this.markerId,
    required this.position,
    this.draggable = false,
    this.onDragEnd,
    this.icon,
    this.onTap,
  });

  // Converter para Marker do flutter_map
  Marker copyWith({
    MarkerId? markerId,
    LatLng? position,
    bool? draggable,
    Function(MarkerId, LatLng)? onDragEnd,
    BitmapDescriptor? icon,
    Function()? onTap,
  }) {
    return Marker(
      markerId: markerId ?? this.markerId,
      position: position ?? this.position,
      draggable: draggable ?? this.draggable,
      onDragEnd: onDragEnd ?? this.onDragEnd,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
    );
  }
}

// Adaptador para MarkerId do Google Maps
class MarkerId {
  final String value;

  MarkerId(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkerId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

// Adaptador para Polygon do Google Maps
class Polygon {
  final PolygonId polygonId;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;

  Polygon({
    required this.polygonId,
    required this.points,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2,
  });
}

// Adaptador para PolygonId do Google Maps
class PolygonId {
  final String value;

  PolygonId(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolygonId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

// Adaptador para BitmapDescriptor do Google Maps
class BitmapDescriptor {
  static const double hueRed = 0.0;
  static const double hueGreen = 120.0;
  static const double hueBlue = 240.0;

  static BitmapDescriptor defaultMarker = BitmapDescriptor._();
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    return BitmapDescriptor._();
  }

  BitmapDescriptor._();
}

// Adaptador para CameraPosition do Google Maps
class CameraPosition {
  final LatLng target;
  final double zoom;

  CameraPosition({
    required this.target,
    this.zoom = 15.0,
  });
}

// Adaptador para CameraUpdate do Google Maps
class CameraUpdate {
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdate._();
  }

  CameraUpdate._();
}

// Adaptador para GoogleMapController do Google Maps
class GoogleMapController {
  Future<void> animateCamera(CameraUpdate cameraUpdate) async {}
  Future<void> moveCamera(CameraUpdate cameraUpdate) async {}
  void dispose() {}
}

// Widget adaptador para GoogleMap
class GoogleMap extends StatefulWidget {
  final Function(GoogleMapController)? onMapCreated;
  final CameraPosition initialCameraPosition;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final Set<google_maps_types.Marker>? markers;
  final Set<google_maps_types.Polygon>? polygons;
  final Set<google_maps_types.Polyline>? polylines;
  final Function(LatLng)? onTap;
  final google_maps_types.MapType mapType;

  const GoogleMap({
    Key? key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.markers,
    this.polygons,
    this.polylines,
    this.onTap,
    this.mapType = google_maps_types.MapType.normal,
  }) : super(key: key);

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  @override
  Widget build(BuildContext context) {
    // Implementação usando flutter_map
    return flutter_map.FlutterMap(
      options: flutter_map.MapOptions(
        initialCenter: widget.initialCameraPosition.target.toLatLong2(),
        initialZoom: widget.initialCameraPosition.zoom,
        onTap: widget.onTap != null
            ? (tapPosition, latLng) => widget.onTap!(LatLng.fromLatLong2(latLng))
            : null,
      ),
      children: [
        flutter_map.TileLayer(
          urlTemplate: MapTilerConfig.getMapStyleUrl(widget.mapType),
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        // Implementar markers se existirem
        if (widget.markers != null && widget.markers!.isNotEmpty)
          flutter_map.MarkerLayer(
            markers: widget.markers!.map((marker) {
              return flutter_map.Marker(
                point: marker.position.toLatLong2(),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    if (marker.onTap != null) {
                      marker.onTap!();
                    }
                  },
                  child: const Icon(Icons.location_on, color: Colors.red),
                ),
              );
            }).toList(),
          ),
        // Implementar polygons se existirem
        if (widget.polygons != null && widget.polygons!.isNotEmpty)
          flutter_map.PolygonLayer(
            polygons: widget.polygons!.map((polygon) {
              return flutter_map.Polygon(
                points: polygon.points.map((point) => point.toLatLong2()).toList(),
                color: polygon.fillColor.withOpacity(0.5),
                borderColor: polygon.strokeColor,
                borderStrokeWidth: polygon.strokeWidth,
                isFilled: true,
              );
            }).toList(),
          ),
        // Implementar polylines se existirem
        if (widget.polylines != null && widget.polylines!.isNotEmpty)
          flutter_map.PolylineLayer(
            polylines: widget.polylines!.map((polyline) {
              return flutter_map.Polyline(
                points: polyline.points.map((point) => point.toLatLong2()).toList(),
                color: polyline.color,
                strokeWidth: polyline.width,
              );
            }).toList(),
          ),
      ],
    );
  }
}

