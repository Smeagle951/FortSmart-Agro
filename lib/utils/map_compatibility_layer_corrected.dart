import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:fortsmart_agro/patches/positioned_tap_detector_2_fixed/lib/positioned_tap_detector_2.dart' as custom_tpd;
import 'dart:math' as math;

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

/// Adaptador para fm.LatLngBounds do Google Maps
class GoogleLatLngBounds {
  final GoogleLatLng southwest;
  final GoogleLatLng northeast;

  GoogleLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  // Converter para fm.LatLngBounds do flutter_map
  fm.LatLngBounds toFlutterMapBounds() {
    return fm.LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de fm.LatLngBounds do flutter_map
  static GoogleLatLngBounds fromFlutterMapBounds(fm.LatLngBounds bounds) {
    return GoogleLatLngBounds(
      southwest: GoogleLatLng.fromLatLong2(bounds.southWest!),
      northeast: GoogleLatLng.fromLatLong2(bounds.northEast!),
    );
  }
}

/// Adaptador para fm.LatLngBounds do Mapbox
class MapboxLatLngBounds {
  final MapboxLatLng southwest;
  final MapboxLatLng northeast;

  MapboxLatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  // Converter para fm.LatLngBounds do flutter_map
  fm.LatLngBounds toFlutterMapBounds() {
    return fm.LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de fm.LatLngBounds do flutter_map
  static MapboxLatLngBounds fromFlutterMapBounds(fm.LatLngBounds bounds) {
    return MapboxLatLngBounds(
      southwest: MapboxLatLng.fromLatLong2(bounds.southWest!),
      northeast: MapboxLatLng.fromLatLong2(bounds.northEast!)
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

  // Converter para fm.MapOptions do flutter_map
  fm.MapOptions toFlutterMapOptions() {
    return fm.MapOptions(
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

  // Converter para fm.MapOptions do flutter_map
  fm.MapOptions toFlutterMapOptions() {
    return fm.MapOptions(
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
  fm.Marker toFlutterMapMarker() {
    return fm.Marker(
      point: position.toLatLong2(),
      builder: (context) => icon ?? const Icon(Icons.location_on, color: Colors.red),
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
  fm.Marker toFlutterMapMarker() {
    return fm.Marker(
      point: position.toLatLong2(),
      builder: (context) => icon ?? const Icon(Icons.location_on, color: Colors.red),
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
  fm.PolygonLayer toFlutterMapPolygonLayer() {
    return fm.PolygonLayer(
      polygons: [
        fm.Polygon(
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
  fm.PolygonLayer toFlutterMapPolygonLayer() {
    return fm.PolygonLayer(
      polygons: [
        fm.Polygon(
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
  final fm.MapOptions mapOptions;
  final List<fm.Marker> markers;
  final List<fm.PolygonLayer> polygonLayers;
  final List<fm.TileLayer> tileLayers;
  final fm.MapController? mapController;

  GoogleMapAdapter({
    required this.mapOptions,
    this.markers = const [],
    this.polygonLayers = const [],
    this.tileLayers = const [],
    this.mapController,
  });

  // Construir o FlutterMap
  Widget build(BuildContext context) {
    return fm.FlutterMap(
      mapController: mapController,
      options: mapOptions,
      children: [
        ...tileLayers,
        fm.MarkerLayer(markers: markers),
        ...polygonLayers,
      ],
    );
  }
}

/// Adaptador para MapboxMap do Mapbox
class MapboxMapAdapter {
  final fm.MapOptions mapOptions;
  final List<fm.Marker> markers;
  final List<fm.PolygonLayer> polygonLayers;
  final List<fm.TileLayer> tileLayers;
  final fm.MapController? mapController;

  MapboxMapAdapter({
    required this.mapOptions,
    this.markers = const [],
    this.polygonLayers = const [],
    this.tileLayers = const [],
    this.mapController,
  });

  // Construir o FlutterMap
  Widget build(BuildContext context) {
    return fm.FlutterMap(
      mapController: mapController,
      options: mapOptions,
      children: [
        ...tileLayers,
        fm.MarkerLayer(markers: markers),
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
  static fm.LatLngBounds calculateBounds(List<latlong2.LatLng> coordinates) {
    if (coordinates.isEmpty) {
      // Retornar um bound padrão se não houver coordenadas
      return fm.LatLngBounds(
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
    
    return fm.LatLngBounds(
      latlong2.LatLng(minLat, minLng),
      latlong2.LatLng(maxLat, maxLng),
    );
  }
}

/// Extensão para adicionar o método copyWith à classe fm.MapOptions
extension MapOptionsExtension on fm.MapOptions {
  fm.MapOptions copyWith({
    latlong2.LatLng? center,
    double? zoom,
    void Function(custom_tpd.TapPosition, latlong2.LatLng)? onTap,
  }) {
    return fm.MapOptions(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      // onTap: onTap ?? this.onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
    );
  }
}
