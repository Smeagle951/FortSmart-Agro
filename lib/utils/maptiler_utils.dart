import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_map/flutter_map.dart' as fm;
import '../utils/constants.dart';
import 'package:fortsmart_agro/patches/positioned_tap_detector_2_fixed/lib/positioned_tap_detector_2.dart' as custom_tpd;

/// Classe utilitária para MapTiler, substituindo as funções do Mapbox
class MapTilerUtils {
  /// API Key do MapTiler
  static String get apiKey => APIKeys.mapTilerAPIKey;

  /// URL para os tiles de satélite do MapTiler
  static String get satelliteUrl => 
    'https://api.maptiler.com/maps/satellite/256/{z}/{x}/{y}.jpg?key=$apiKey';

  /// URL para os tiles de mapa de ruas do MapTiler
  static String get streetsUrl => 
    'https://api.maptiler.com/maps/streets/256/{z}/{x}/{y}.png?key=$apiKey';

  /// Cria uma camada de tiles para mapas do MapTiler
  static fm.TileLayer createTileLayer({bool isSatellite = true}) {
    return fm.TileLayer(
      urlTemplate: isSatellite ? satelliteUrl : streetsUrl,
      userAgentPackageName: 'com.fortsmartagro.app',
      tileProvider: fm.NetworkTileProvider(),
      // backgroundColor: Colors.black, // backgroundColor não é suportado em flutter_map 5.0.0
      maxZoom: 22,
    );
  }

  /// Calcula o centro de uma lista de pontos
  static ll.LatLng calculateCenter(List<ll.LatLng> points) {
    if (points.isEmpty) {
      // Retorna o centro do Brasil como padrão
      return ll.LatLng(-15.7801, -47.9292);
    }
    double sumLat = 0;
    double sumLng = 0;
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    return ll.LatLng(sumLat / points.length, sumLng / points.length);
  }

  /// Calcula os limites de uma lista de pontos para ajustar o zoom
  static fm.LatLngBounds calculateBounds(List<ll.LatLng> points) {
    if (points.isEmpty) {
      // Retorna limites padrão para o Brasil
      return fm.LatLngBounds(
        ll.LatLng(-33.7683, -73.9874),
        ll.LatLng(5.2699, -34.7299),
      );
    }

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    const padding = 0.01;
    return fm.LatLngBounds(
      ll.LatLng(minLat - padding, minLng - padding),
      ll.LatLng(maxLat + padding, maxLng + padding),
    );
  }

  /// Calcula a área aproximada de um polígono em hectares
  static double calculateAreaInHectares(List<ll.LatLng> points) {
    if (points.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = area.abs() / 2;

    // Fator aproximado para conversão de grau² para hectares
    double areaInHectares = area * 1232137.0;
    return areaInHectares;
  }

  /// Cria opções de mapa para o FlutterMap
  static fm.MapOptions createMapOptions({
    ll.LatLng? initialCenter,
    double initialZoom = 5.0,
    Function(custom_tpd.TapPosition, ll.LatLng)? onTap,
    Function()? onMapReady,
    Function(fm.MapPosition, bool)? onPositionChanged,
  }) {
    return fm.MapOptions(
      center: initialCenter ?? ll.LatLng(-15.7801, -47.9292), // Brasil
      zoom: initialZoom,
      // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
      onMapReady: onMapReady,
      onPositionChanged: onPositionChanged,
      maxZoom: 18.0,
      minZoom: 3.0,
    );
  }

  /// Cria um marcador para o mapa
  static fm.Marker createMarker({
    required ll.LatLng point,
    required Widget Function(BuildContext) builder,
    double width = 30.0,
    double height = 30.0,
  }) {
    return fm.Marker(
      point: point,
      builder: builder,
      width: width,
      height: height,
    );
  }

  /// Cria um polígono para o mapa
  static fm.Polygon createPolygon({
    required List<ll.LatLng> points,
    Color color = Colors.blue,
    Color borderColor = Colors.blue,
    double borderStrokeWidth = 2.0,
    bool isFilled = true,
    double opacity = 0.3,
  }) {
    return fm.Polygon(
      points: points,
      color: isFilled ? color.withOpacity(opacity) : Colors.transparent,
      borderColor: borderColor.withOpacity(0.7),
      borderStrokeWidth: borderStrokeWidth,
    );
  }

  /// Cria uma polilinha para o mapa
  static fm.Polyline createPolyline({
    required List<ll.LatLng> points,
    Color color = Colors.blue,
    double strokeWidth = 2.0,
    bool isDotted = false,
  }) {
    return fm.Polyline(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      isDotted: isDotted,
    );
  }
}
