import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_map/src/geo/latlng_bounds.dart' as flutter_map_bounds;
import 'dart:math' as math;

// Enum para os tipos de mapa
enum MapType {
  normal,
  satellite,
  hybrid,
  terrain,
  none,
}

// Enum para unidades de comprimento
enum LengthUnit {
  Meter,
  Kilometer,
  Mile,
}

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
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng && 
           other.latitude == latitude && 
           other.longitude == longitude;
  }
  
  @override
  int get hashCode => Object.hash(latitude, longitude);
}

// Adaptador para LatLngBounds do Google Maps
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  LatLngBounds(this.southwest, this.northeast);

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
  flutter_map_bounds.LatLngBounds toLatLong2Bounds() {
    return flutter_map_bounds.LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de LatLngBounds do flutter_map
  static LatLngBounds fromLatLong2Bounds(flutter_map_bounds.LatLngBounds bounds) {
    return LatLngBounds(
      LatLng.fromLatLong2(bounds.southWest ?? latlong2.LatLng(0, 0)),
      LatLng.fromLatLong2(bounds.northEast ?? latlong2.LatLng(0, 0)),
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

// Classe para cálculos de distância
class Distance {
  // Constante do raio da Terra em metros
  static const double earthRadius = 6378137.0;

  // Método para calcular a distância entre dois pontos em metros
  double as(LengthUnit unit, latlong2.LatLng p1, latlong2.LatLng p2) {
    final double lat1 = p1.latitude * math.pi / 180;
    final double lat2 = p2.latitude * math.pi / 180;
    final double lon1 = p1.longitude * math.pi / 180;
    final double lon2 = p2.longitude * math.pi / 180;

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                     math.cos(lat1) * math.cos(lat2) *
                     math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = earthRadius * c;

    switch (unit) {
      case LengthUnit.Meter:
        return distance;
      case LengthUnit.Kilometer:
        return distance / 1000;
      case LengthUnit.Mile:
        return distance / 1609.344;
      default:
        return distance;
    }
  }
}

// Adaptador para CameraPosition do Google Maps
class CameraPosition {
  final LatLng target;
  final double zoom;
  final double? tilt;
  final double? bearing;

  const CameraPosition({
    required this.target,
    this.zoom = 15.0,
    this.tilt,
    this.bearing,
  });
}

// Adaptador para CameraUpdate do Google Maps
class CameraUpdate {
  final LatLng? _latLng;
  final double? _zoom;
  final LatLngBounds? _bounds;
  final double? _padding;

  CameraUpdate._({
    LatLng? latLng,
    double? zoom,
    LatLngBounds? bounds,
    double? padding,
  })  : _latLng = latLng,
        _zoom = zoom,
        _bounds = bounds,
        _padding = padding;

  static CameraUpdate newLatLng(LatLng latLng) {
    return CameraUpdate._(latLng: latLng);
  }

  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdate._(latLng: latLng, zoom: zoom);
  }

  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) {
    return CameraUpdate._(bounds: bounds, padding: padding);
  }
}

// Adaptador para GoogleMapController do Google Maps
class GoogleMapController {
  final flutter_map.MapController _mapController;
  
  GoogleMapController(this._mapController);

  void animateCamera(CameraUpdate cameraUpdate) {
    if (cameraUpdate._latLng != null && cameraUpdate._zoom != null) {
      _mapController.move(
        cameraUpdate._latLng!.toLatLong2(),
        cameraUpdate._zoom!,
      );
    } else if (cameraUpdate._latLng != null) {
      _mapController.move(
        cameraUpdate._latLng!.toLatLong2(),
        _mapController.zoom,
      );
    } else if (cameraUpdate._bounds != null) {
      final bounds = cameraUpdate._bounds!.toLatLong2Bounds();
      _mapController.fitBounds(
        bounds,
        options: flutter_map.FitBoundsOptions(
          padding: EdgeInsets.all(cameraUpdate._padding ?? 50.0),
        ),
      );
    }
  }

  void moveCamera(CameraUpdate cameraUpdate) {
    animateCamera(cameraUpdate);
  }
  
  // Método para configurar o estilo do mapa (apenas compatibilidade, não faz nada no MapTiler)
  void setMapStyle(String mapStyle) {
    // No MapTiler, o estilo é configurado de outra forma
    // Este método existe apenas para compatibilidade com o código existente
    print('MapTiler: setMapStyle não tem efeito, use TileLayer com urlTemplate apropriado');
  }

  void dispose() {
    // Nada a fazer aqui, o MapController do flutter_map não tem método dispose
  }
}

// Adaptador para Marker do Google Maps
class Marker {
  final MarkerId markerId;
  final LatLng position;
  final InfoWindow infoWindow;
  final double alpha;
  final bool draggable;
  final bool visible;
  final double zIndex;
  final BitmapDescriptor icon;
  final Function(LatLng)? onDragEnd;
  final Function()? onTap;

  Marker({
    required this.markerId,
    required this.position,
    this.infoWindow = InfoWindow.noText,
    this.alpha = 1.0,
    this.draggable = false,
    this.visible = true,
    this.zIndex = 0.0,
    this.icon = BitmapDescriptor.defaultMarker,
    this.onDragEnd,
    this.onTap,
  });

  // Converter para Marker do flutter_map
  flutter_map.Marker toFlutterMapMarker() {
    return flutter_map.Marker(
      point: position.toLatLong2(),
      child: GestureDetector(
        onTap: onTap,
        child: icon.toWidget(),
      ),
      width: 30,
      height: 30,
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

// Adaptador para InfoWindow do Google Maps
class InfoWindow {
  final String title;
  final String snippet;

  const InfoWindow({
    this.title = '',
    this.snippet = '',
  });

  static const InfoWindow noText = InfoWindow();
}

// Adaptador para BitmapDescriptor do Google Maps
class BitmapDescriptor {
  final Color color;

  
  // Constantes para cores de marcadores
  static const double hueRed = 0.0;
  static const double hueOrange = 30.0;
  static const double hueYellow = 60.0;
  static const double hueGreen = 120.0;
  static const double hueCyan = 180.0;
  static const double hueAzure = 210.0;
  static const double hueBlue = 240.0;
  static const double hueViolet = 270.0;
  static const double hueMagenta = 300.0;
  static const double hueRose = 330.0;

  const BitmapDescriptor._({
    this.color = Colors.red,

  });

  static const BitmapDescriptor defaultMarker = BitmapDescriptor._();

  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    final color = HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
    return BitmapDescriptor._(color: color);
  }

  Widget toWidget() {
    return Icon(Icons.location_on, color: color);
  }
}

// Adaptador para Polygon do Google Maps
class Polygon {
  final PolygonId polygonId;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final bool visible;

  Polygon({
    required this.polygonId,
    required this.points,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2,
    this.visible = true,
  });

  // Converter para Polygon do flutter_map
  flutter_map.Polygon toFlutterMapPolygon() {
    return flutter_map.Polygon(
      points: points.map((p) => p.toLatLong2()).toList(),
      color: fillColor.withOpacity(0.5),
      borderColor: strokeColor,
      borderStrokeWidth: strokeWidth,
    );
  }
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

// Adaptador para Polyline do Google Maps
class Polyline {
  final PolylineId polylineId;
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool visible;

  Polyline({
    required this.polylineId,
    required this.points,
    this.color = Colors.blue,
    this.width = 2,
    this.visible = true,
  });

  // Converter para Polyline do flutter_map
  flutter_map.Polyline toFlutterMapPolyline() {
    return flutter_map.Polyline(
      points: points.map((p) => p.toLatLong2()).toList(),
      color: color,
      strokeWidth: width,
    );
  }
}

// Adaptador para PolylineId do Google Maps
class PolylineId {
  final String value;
  
  const PolylineId(this.value);
  
  @override
  String toString() => value;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolylineId &&
          runtimeType == other.runtimeType &&
          value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}

// Adaptador para ScreenCoordinate do Google Maps/Mapbox
class ScreenCoordinate {
  final double x;
  final double y;
  
  const ScreenCoordinate({required this.x, required this.y});
  
  @override
  String toString() => 'ScreenCoordinate(x: $x, y: $y)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenCoordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;
  
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

// Widget adaptador para GoogleMap
class GoogleMap extends StatefulWidget {
  final Function(GoogleMapController)? onMapCreated;
  final CameraPosition initialCameraPosition;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final Set<Marker>? markers;
  final Set<Polygon>? polygons;
  final Set<Polyline>? polylines;
  final Function(LatLng)? onTap;
  final MapType mapType;

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
    this.mapType = MapType.normal,
  }) : super(key: key);
  
  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  flutter_map.MapController? _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = flutter_map.MapController();
    
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(GoogleMapController(_controller!));
    }
  }
  
  String _getTileUrl() {
    switch (widget.mapType) {
      case MapType.satellite:
        return 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u';
      case MapType.hybrid:
        return 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=KQAa9lY3N0TR17zxhk9u';
      case MapType.terrain:
        return 'https://api.maptiler.com/maps/topo/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u';
      case MapType.normal:
      default:
        return 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=KQAa9lY3N0TR17zxhk9u';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Converter marcadores e polígonos para o formato do flutter_map
    final markers = widget.markers?.map((marker) => marker.toFlutterMapMarker()).toList() ?? [];
    final polygons = widget.polygons?.map((polygon) => polygon.toFlutterMapPolygon()).toList() ?? [];
    final polylines = widget.polylines?.map((polyline) => polyline.toFlutterMapPolyline()).toList() ?? [];
    
    return flutter_map.FlutterMap(
      mapController: _controller,
      options: flutter_map.MapOptions(
        initialCenter: widget.initialCameraPosition.target.toLatLong2(),
        initialZoom: widget.initialCameraPosition.zoom,
        // onTap: widget.onTap != null ? (_, // onTap não é suportado em Polygon no flutter_map 5.0.0 point) => widget.onTap!(LatLng.fromLatLong2(point)) : null,
      ),
      children: [
        flutter_map.TileLayer(
          urlTemplate: _getTileUrl(),
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        if (polygons.isNotEmpty)
          flutter_map.PolygonLayer(polygons: polygons),
        if (polylines.isNotEmpty)
          flutter_map.PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty)
          flutter_map.MarkerLayer(markers: markers),
      ],
    );
  }
}

