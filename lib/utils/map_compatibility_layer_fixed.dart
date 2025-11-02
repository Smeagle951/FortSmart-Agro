import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:math' as math;

/// Extensão para adicionar o método copyWith à classe MapOptions
extension MapOptionsExtension on MapOptions {
  MapOptions copyWith({
    latlong2.LatLng? center,
    double? zoom,

  }) {
    return MapOptions(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      // onTap: onTap ?? this.onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
    );
  }
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
  String toString() => 'GoogleLatLng(latitude: $latitude, longitude: $longitude)';
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
  String toString() => 'MapboxLatLng(latitude: $latitude, longitude: $longitude)';
}

/// Adaptador para LatLngBounds do Google Maps
class GoogleLatLngBounds {
  final GoogleLatLng southwest;
  final GoogleLatLng northeast;

  GoogleLatLngBounds({required this.southwest, required this.northeast});

  // Converter para LatLngBounds do flutter_map
  LatLngBounds toFlutterMapBounds() {
    return LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de LatLngBounds do flutter_map
  static GoogleLatLngBounds fromFlutterMapBounds(LatLngBounds bounds) {
    return GoogleLatLngBounds(
      southwest: GoogleLatLng.fromLatLong2(bounds.southWest!),
      northeast: GoogleLatLng.fromLatLong2(bounds.northEast!),
    );
  }
}

/// Adaptador para LatLngBounds do Mapbox
class MapboxLatLngBounds {
  final MapboxLatLng southwest;
  final MapboxLatLng northeast;

  MapboxLatLngBounds({required this.southwest, required this.northeast});

  // Converter para LatLngBounds do flutter_map
  LatLngBounds toFlutterMapBounds() {
    return LatLngBounds(
      southwest.toLatLong2(),
      northeast.toLatLong2(),
    );
  }

  // Criar a partir de LatLngBounds do flutter_map
  static MapboxLatLngBounds fromFlutterMapBounds(LatLngBounds bounds) {
    return MapboxLatLngBounds(
      southwest: MapboxLatLng.fromLatLong2(bounds.southWest!),
      northeast: MapboxLatLng.fromLatLong2(bounds.northEast!),
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
      interactiveFlags: InteractiveFlag.all,
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
      interactiveFlags: InteractiveFlag.all,
    );
  }
}

/// Adaptador para Marker do Google Maps
class GoogleMarker {
  final String id;
  final GoogleLatLng position;
  final bool draggable;
  final Function(String, GoogleLatLng)? onDragEnd;
  final Widget? icon;
  final VoidCallback? onTap;

  GoogleMarker({
    required this.id,
    required this.position,
    this.draggable = false,
    this.onDragEnd,
    this.icon,
    this.onTap,
  });

  // Converter para Marker do flutter_map
  Marker toFlutterMapMarker() {
    return Marker(
      point: position.toLatLong2(),
      builder: (context) => icon ?? const Icon(Icons.location_on, color: Colors.red),
      width: 30,
      height: 30,
    );
  }
}

/// Adaptador para Marker do Mapbox
class MapboxMarker {
  final String id;
  final MapboxLatLng position;
  final bool draggable;
  final Function(String, MapboxLatLng)? onDragEnd;
  final Widget? icon;
  final VoidCallback? onTap;

  MapboxMarker({
    required this.id,
    required this.position,
    this.draggable = false,
    this.onDragEnd,
    this.icon,
    this.onTap,
  });

  // Converter para Marker do flutter_map
  Marker toFlutterMapMarker() {
    return Marker(
      point: position.toLatLong2(),
      builder: (context) => icon ?? const Icon(Icons.location_on, color: Colors.red),
      width: 30,
      height: 30,
    );
  }
}

/// Adaptador para Polygon do Google Maps
class GooglePolygon {
  final String id;
  final List<GoogleLatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  GooglePolygon({
    required this.id,
    required this.points,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2,
  });

  // Converter para Polygon do flutter_map
  PolygonLayer toFlutterMapPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: points.map((p) => p.toLatLong2()).toList(),
          color: fillColor.withOpacity(0.5),
          borderColor: strokeColor,
          borderStrokeWidth: strokeWidth,
        ),
      ],
    );
  }
}

/// Adaptador para Polygon do Mapbox
class MapboxPolygon {
  final String id;
  final List<MapboxLatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  MapboxPolygon({
    required this.id,
    required this.points,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.red,
    this.strokeWidth = 2,
  });

  // Converter para Polygon do flutter_map
  PolygonLayer toFlutterMapPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: points.map((p) => p.toLatLong2()).toList(),
          color: fillColor.withOpacity(0.5),
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
  final List<GoogleMarker> markers;
  final List<GooglePolygon> polygons;

  GoogleMapAdapter({
    required this.mapOptions,
    this.markers = const [],
    this.polygons = const [],
  });

  // Construir o widget FlutterMap
  Widget build(BuildContext context) {
    return FlutterMap(
      options: mapOptions,
      children: [
        // Camada de tiles
        TileLayer(
          urlTemplate: MapTilerUrl.streets,
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Camada de marcadores
        MarkerLayer(
          markers: markers.map((m) => m.toFlutterMapMarker()).toList(),
        ),
        
        // Camadas de polígonos
        ...polygons.map((p) => p.toFlutterMapPolygonLayer()).toList(),
      ],
    );
  }
}

/// Adaptador para MapboxMap do Mapbox
class MapboxMapAdapter {
  final MapOptions mapOptions;
  final List<MapboxMarker> markers;
  final List<MapboxPolygon> polygons;

  MapboxMapAdapter({
    required this.mapOptions,
    this.markers = const [],
    this.polygons = const [],
  });

  // Construir o widget FlutterMap
  Widget build(BuildContext context) {
    return FlutterMap(
      options: mapOptions,
      children: [
        // Camada de tiles
        TileLayer(
          urlTemplate: MapTilerUrl.streets,
          userAgentPackageName: 'com.fortsmart.agro',
        ),
        
        // Camada de marcadores
        MarkerLayer(
          markers: markers.map((m) => m.toFlutterMapMarker()).toList(),
        ),
        
        // Camadas de polígonos
        ...polygons.map((p) => p.toFlutterMapPolygonLayer()).toList(),
      ],
    );
  }
}

/// Classe de utilidades para cálculos geográficos
class GeoUtils {
  /// Calcula a área do polígono em metros quadrados
  static double calculateArea(List<latlong2.LatLng> points) {
    if (points.length < 3) return 0.0;
    
    double area = 0.0;
    final int n = points.length;
    
    for (int i = 0; i < n; i++) {
      final latlong2.LatLng current = points[i];
      final latlong2.LatLng next = points[(i + 1) % n];
      
      // Fórmula da área de Gauss (Shoelace formula)
      area += (next.longitude + current.longitude) * (next.latitude - current.latitude);
    }
    
    // Converter para metros quadrados usando o fator de conversão aproximado
    area = area.abs() * 0.5 * 111319.9 * 111319.9;
    
    return area;
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
    
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return latlong2.LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }
  
  /// Calcula os limites (bounds) que contêm todas as coordenadas
  static LatLngBounds calculateBounds(List<latlong2.LatLng> coordinates) {
    if (coordinates.isEmpty) {
      // Retorna um bound padrão se a lista estiver vazia
      return LatLngBounds(
        latlong2.LatLng(-23.5505, -46.6333), // São Paulo
        latlong2.LatLng(-23.5505, -46.6333),
      );
    }
    
    double minLat = coordinates[0].latitude;
    double maxLat = coordinates[0].latitude;
    double minLng = coordinates[0].longitude;
    double maxLng = coordinates[0].longitude;
    
    for (final coord in coordinates) {
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
