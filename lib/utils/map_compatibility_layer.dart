import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart';
// // import 'package:flutter_map/plugin_api.dart'; // Removido devido a incompatibilidade // Removido devido a incompatibilidade
import 'package:flutter/widgets.dart';
import 'dart:math' as math;
// import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart'; // Removido


// Classes do flutter_map que usamos diretamente
class FlutterMapLatLngBounds {
  final latlong2.LatLng southWest;
  final latlong2.LatLng northEast;
  
  FlutterMapLatLngBounds(this.southWest, this.northEast);
}

class FlutterMapMarker {
  final latlong2.LatLng point;
  final Widget child;
  
  FlutterMapMarker({required this.point, required this.child});
}

class FlutterMapPolygon {
  final List<latlong2.LatLng> points;
  final Color color;
  final double borderWidth;
  final Color borderColor;
  
  FlutterMapPolygon({
    required this.points,
    this.color = Colors.blue,
    this.borderWidth = 1.0,
    this.borderColor = Colors.black,
  });
}

class FlutterMapPolyline {
  final List<latlong2.LatLng> points;
  final Color color;
  final double strokeWidth;
  
  FlutterMapPolyline({
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 1.0,
  });
}

/// Este arquivo fornece uma camada de compatibilidade para facilitar a migração
/// do Google Maps e Mapbox para o MapTiler.
/// 
/// Ele define classes e métodos que imitam a API do Google Maps e Mapbox,
/// mas internamente usam o flutter_map e latlong2.

// Chave de API do MapTiler - Substitua pela sua chave real
const String mapTilerApiKey = 'KQAa9lY3N0TR17zxhk9u';

/// URLs dos tiles do MapTiler
class MapTilerUrl {
  static const String streets = 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerApiKey';
  static const String satellite = 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=$mapTilerApiKey';
  static const String hybrid = 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$mapTilerApiKey';
}

/// Adaptador para LatLng do Google Maps
class GoogleLatLng {
  final double latitude;
  final double longitude;

  const GoogleLatLng(this.latitude, this.longitude);

  // Converter para LatLng do latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }

  // Criar a partir de LatLng do latlong2
  static GoogleLatLng fromLatLong2(latlong2.LatLng latLng) {
    return GoogleLatLng(latLng.latitude, latLng.longitude);
  }

  @override
  String toString() {
    return 'GoogleLatLng($latitude, $longitude)';
  }
}

/// Adaptador para LatLng do Mapbox
class MapboxLatLng {
  final double latitude;
  final double longitude;

  const MapboxLatLng(this.latitude, this.longitude);

  // Converter para LatLng do latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }

  // Criar a partir de LatLng do latlong2
  static MapboxLatLng fromLatLong2(latlong2.LatLng latLng) {
    return MapboxLatLng(latLng.latitude, latLng.longitude);
  }

  @override
  String toString() {
    return 'MapboxLatLng($latitude, $longitude)';
  }
}

/// Adaptador para LatLngBounds do Google Maps
class GoogleLatLngBounds {
  final GoogleLatLng southwest;
  final GoogleLatLng northeast;

  GoogleLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  // Converter para LatLngBounds do flutter_map
  LatLngBounds toFlutterMapBounds() {
    return LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de LatLngBounds do flutter_map
  static GoogleLatLngBounds fromFlutterMapBounds(FlutterMapLatLngBounds bounds) {
    return GoogleLatLngBounds(
      southwest: GoogleLatLng.fromLatLong2(bounds.southWest),
      northeast: GoogleLatLng.fromLatLong2(bounds.northEast),
    );
  }
}

/// Adaptador para LatLngBounds do Mapbox
class MapboxLatLngBounds {
  final MapboxLatLng southwest;
  final MapboxLatLng northeast;

  MapboxLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  // Converter para LatLngBounds do flutter_map
  LatLngBounds toFlutterMapBounds() {
    return LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de LatLngBounds do flutter_map
  static MapboxLatLngBounds fromFlutterMapBounds(FlutterMapLatLngBounds bounds) {
    return MapboxLatLngBounds(
      southwest: MapboxLatLng.fromLatLong2(bounds.southWest),
      northeast: MapboxLatLng.fromLatLong2(bounds.northEast),
    );
  }
}

/// Adaptador para CameraPosition do Google Maps
class GoogleCameraPosition {
  final GoogleLatLng target;
  final double zoom;

  GoogleCameraPosition({
    required this.target,
    this.zoom = 15.0,
  });

  // Converter para MapOptions do flutter_map
  MapOptions toMapOptions() {
    return MapOptions(
      center: target.toLatLong2(),
      zoom: zoom,
    );
  }
}

/// Adaptador para CameraPosition do Mapbox
class MapboxCameraPosition {
  final MapboxLatLng target;
  final double zoom;

  MapboxCameraPosition({
    required this.target,
    this.zoom = 15.0,
  });

  // Converter para MapOptions do flutter_map
  MapOptions toMapOptions() {
    return MapOptions(
      center: target.toLatLong2(),
      zoom: zoom,
    );
  }
}

/// Adaptador para Marker do Google Maps
class GoogleMarker {
  final GoogleLatLng position;
  final Widget? icon;
  final String? title;
  final String? snippet;
  final VoidCallback? onTap;

  GoogleMarker({
    required this.position,
    this.icon,
    this.title,
    this.snippet,
    this.onTap,
  });

  // Converter para Marker do flutter_map
  Marker toFlutterMapMarker() {
    return Marker(
      point: position.toLatLong2(),
      child: icon ?? const Icon(Icons.location_on, color: Colors.red),
      width: 30,
      height: 30,
    );
  }
}

/// Adaptador para Marker do Mapbox
class MapboxMarker {
  final MapboxLatLng position;
  final Widget? icon;
  final String? title;
  final String? snippet;
  final VoidCallback? onTap;

  MapboxMarker({
    required this.position,
    this.icon,
    this.title,
    this.snippet,
    this.onTap,
  });

  // Converter para Marker do flutter_map
  Marker toFlutterMapMarker() {
    return Marker(
      point: position.toLatLong2(),
      child: icon ?? const Icon(Icons.location_on, color: Colors.red),
      width: 30,
      height: 30,
    );
  }
}

/// Adaptador para Polygon do Google Maps
class GooglePolygon {
  final List<GoogleLatLng> points;
  final Color strokeColor;
  final double strokeWidth;
  final Color fillColor;
  final bool geodesic;
  final VoidCallback? onTap;

  GooglePolygon({
    required this.points,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.fillColor = const Color(0x88FF0000),
    this.geodesic = false,
    this.onTap,
  });

  // Converter para PolygonLayer do flutter_map
  PolygonLayer toFlutterMapPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: points.map((p) => p.toLatLong2()).toList(),
          color: fillColor,
          borderColor: strokeColor,
          borderStrokeWidth: strokeWidth,
        ),
      ],
    );
  }
}

/// Adaptador para Polygon do Mapbox
class MapboxPolygon {
  final List<MapboxLatLng> points;
  final Color strokeColor;
  final double strokeWidth;
  final Color fillColor;
  final VoidCallback? onTap;

  MapboxPolygon({
    required this.points,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.fillColor = const Color(0x88FF0000),
    this.onTap,
  });

  // Converter para PolygonLayer do flutter_map
  PolygonLayer toFlutterMapPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: points.map((p) => p.toLatLong2()).toList(),
          color: fillColor,
          borderColor: strokeColor,
          borderStrokeWidth: strokeWidth,
        ),
      ],
    );
  }
}

/// Adaptador para GoogleMap do Google Maps
class GoogleMapAdapter {
  final MapOptions mapOptions;
  final List<Marker> markers;
  final List<PolygonLayer> polygonLayers;
  final List<TileLayer> tileLayers;
  final MapController? mapController;

  GoogleMapAdapter({
    required this.mapOptions,
    this.markers = const [],
    this.polygonLayers = const [],
    this.tileLayers = const [],
    this.mapController,
  });

  // Construir o FlutterMap
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: mapOptions,
      children: [
        ...tileLayers,
        MarkerLayer(markers: markers),
        ...polygonLayers,
      ],
    );
  }
}

/// Adaptador para MapboxMap do Mapbox
class MapboxMapAdapter {
  final MapOptions mapOptions;
  final List<Marker> markers;
  final List<PolygonLayer> polygonLayers;
  final List<TileLayer> tileLayers;
  final MapController? mapController;

  MapboxMapAdapter({
    required this.mapOptions,
    this.markers = const [],
    this.polygonLayers = const [],
    this.tileLayers = const [],
    this.mapController,
  });

  // Construir o FlutterMap
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: mapOptions,
      children: [
        ...tileLayers,
        MarkerLayer(markers: markers),
        ...polygonLayers,
      ],
    );
  }
}

/// Classe de utilidades para cálculos geográficos
class GeoUtils {
  /// Calcula a área de um polígono em hectares
  static double calculatePolygonArea(List<latlong2.LatLng> points) {
    if (points.length < 3) return 0;
    
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() * 0.5;
    // Converter para hectares (aproximadamente)
    return area * 111.32 * 111.32 * 0.01;
  }
  
  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(latlong2.LatLng p1, latlong2.LatLng p2) {
    const double radiusEarth = 6371000; // em metros
    
    double lat1 = p1.latitude * math.pi / 180;
    double lon1 = p1.longitude * math.pi / 180;
    double lat2 = p2.latitude * math.pi / 180;
    double lon2 = p2.longitude * math.pi / 180;
    
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    
    double a = math.sin(dLat/2) * math.sin(dLat/2) +
              math.cos(lat1) * math.cos(lat2) *
              math.sin(dLon/2) * math.sin(dLon/2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return radiusEarth * c;
  }
  
  /// Calcula o centro de um conjunto de pontos
  static latlong2.LatLng calculateCenter(List<latlong2.LatLng> points) {
    if (points.isEmpty) {
      return latlong2.LatLng(0, 0);
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (var point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return latlong2.LatLng(sumLat / points.length, sumLng / points.length);
  }
  
  /// Calcula os limites (bounds) que contêm todas as coordenadas
  static LatLngBounds calculateBounds(List<latlong2.LatLng> coordinates) {
    if (coordinates.isEmpty) {
      // Retornar um bound padrão se não houver coordenadas
      return LatLngBounds(
        latlong2.LatLng(-90, -180),
        latlong2.LatLng(90, 180),
      );
    }
    
    double minLat = coordinates[0].latitude;
    double maxLat = coordinates[0].latitude;
    double minLng = coordinates[0].longitude;
    double maxLng = coordinates[0].longitude;
    
    for (var coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }
    
    return LatLngBounds(
      latlong2.LatLng(minLat, minLng),
      latlong2.LatLng(maxLat, maxLng),
    );
  }
}

/// Extensão para adicionar o método copyWith à classe MapOptions
extension MapOptionsExtension on MapOptions {
  MapOptions copyWith({
    latlong2.LatLng? center,
    double? zoom,
    void Function(TapPosition, latlong2.LatLng)? onTap,
  }) {
    return MapOptions(
      initialCenter: center ?? this.initialCenter,
      initialZoom: zoom ?? this.initialZoom,
      onTap: onTap,
    );
  }
}
