import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'map_global_adapter.dart' as maps;

/// Classe de compatibilidade para o MapTiler
/// 
/// Esta classe fornece métodos e classes auxiliares para garantir
/// a compatibilidade com o adaptador global de mapas
class MapTilerCompatibility {
  /// Converte um ponto do adaptador para latlong2
  static latlong2.LatLng adapterToLatlong2(maps.LatLng point) {
    return latlong2.LatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do adaptador para latlong2
  static List<latlong2.LatLng> adapterListToLatlong2(List<maps.LatLng> points) {
    return points.map((point) => adapterToLatlong2(point)).toList();
  }

  /// Converte um ponto do latlong2 para o adaptador
  static maps.LatLng latlong2ToAdapter(latlong2.LatLng point) {
    return maps.LatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do latlong2 para o adaptador
  static List<maps.LatLng> latlong2ListToAdapter(List<latlong2.LatLng> points) {
    return points.map((point) => latlong2ToAdapter(point)).toList();
  }

  /// Converte uma lista aninhada de pontos do latlong2 para o adaptador
  static List<List<maps.LatLng>> latlong2NestedListToAdapter(
      List<List<latlong2.LatLng>> nestedPoints) {
    return nestedPoints
        .map((points) => latlong2ListToAdapter(points))
        .toList();
  }

  /// Cria um objeto de linha para o flutter_map
  static Map<String, dynamic> createLineOptions({
    required List<latlong2.LatLng> points,
    required Color strokeColor,
    required double strokeWidth,
    required double opacity,
    bool? isDraggable,
  }) {
    return {
      'points': points,
      'color': strokeColor.withOpacity(opacity),
      'strokeWidth': strokeWidth,
      'isDraggable': isDraggable ?? false,
    };
  }

  /// Cria um objeto de marcador para o flutter_map
  static Map<String, dynamic> createMarkerOptions({
    required latlong2.LatLng point,
    Widget? icon,
    double? width,
    double? height,
    bool? draggable,
  }) {
    return {
      'point': point,
      'width': width ?? 30.0,
      'height': height ?? 30.0,
      'builder': (context) => icon ?? const Icon(Icons.location_on, color: Colors.red),
      'draggable': draggable ?? false,
    };
  }
}

/// Extensão para facilitar o uso de cores
extension ColorExtension on Color {
  String toHexString() {
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
