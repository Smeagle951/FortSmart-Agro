import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Adapter class to provide compatibility between different map libraries
/// This helps transition from mapbox_gl to flutter_map without changing all code
class MapboxLatLng {
  final double latitude;
  final double longitude;

  const MapboxLatLng(this.latitude, this.longitude);

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  static MapboxLatLng fromLatLng(LatLng latLng) {
    return MapboxLatLng(latLng.latitude, latLng.longitude);
  }

  @override
  String toString() {
    return 'MapboxLatLng(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapboxLatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Adapter for polygon models
class MapboxPolygon {
  final List<MapboxLatLng> points;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;

  MapboxPolygon({
    required this.points,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
  });

  List<LatLng> toLatLngList() {
    return points.map((point) => point.toLatLng()).toList();
  }

  static MapboxPolygon fromLatLngList(List<LatLng> latLngList, {
    Color? fillColor,
    Color? strokeColor,
    double strokeWidth = 1.0,
  }) {
    return MapboxPolygon(
      points: latLngList.map((latLng) => MapboxLatLng.fromLatLng(latLng)).toList(),
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }
}

/// Utility functions for converting between different coordinate formats
class CoordinateConverter {
  /// Convert from MapboxLatLng to LatLng
  static LatLng toLatLng(MapboxLatLng mapboxLatLng) {
    return LatLng(mapboxLatLng.latitude, mapboxLatLng.longitude);
  }

  /// Convert from LatLng to MapboxLatLng
  static MapboxLatLng fromLatLng(LatLng latLng) {
    return MapboxLatLng(latLng.latitude, latLng.longitude);
  }

  /// Convert a list of MapboxLatLng to a list of LatLng
  static List<LatLng> toLatLngList(List<MapboxLatLng> mapboxLatLngList) {
    return mapboxLatLngList.map((point) => toLatLng(point)).toList();
  }

  /// Convert a list of LatLng to a list of MapboxLatLng
  static List<MapboxLatLng> fromLatLngList(List<LatLng> latLngList) {
    return latLngList.map((point) => fromLatLng(point)).toList();
  }
}
