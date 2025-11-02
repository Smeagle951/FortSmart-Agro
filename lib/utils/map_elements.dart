import 'package:flutter/material.dart';
import 'map_types.dart';

/// Classe para representar um identificador de polígono
class PolygonId {
  final String value;

  const PolygonId(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolygonId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PolygonId($value)';
}

/// Classe para representar um polígono
class Polygon {
  final PolygonId polygonId;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final bool consumeTapEvents;
  final Function? onTap;
  final bool visible;
  final int zIndex;

  const Polygon({
    required this.polygonId,
    required this.points,
    this.fillColor = const Color(0x80000000),
    this.strokeColor = const Color(0xFF000000),
    this.strokeWidth = 1.0,
    this.consumeTapEvents = false,
    this.onTap,
    this.visible = true,
    this.zIndex = 0,
  });
}

/// Classe para representar um identificador de marcador
class MarkerId {
  final String value;

  const MarkerId(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarkerId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MarkerId($value)';
}

/// Classe para representar uma janela de informações
class InfoWindow {
  final String title;
  final String snippet;

  const InfoWindow({
    this.title = '',
    this.snippet = '',
  });
}

/// Classe para representar um marcador
class Marker {
  final MarkerId markerId;
  final LatLng position;
  final double rotation;
  final bool visible;
  final double alpha;
  final InfoWindow infoWindow;
  final VoidCallback? onTap;
  final bool draggable;
  final Function(LatLng)? onDragEnd;
  final BitmapDescriptor? icon;

  const Marker({
    required this.markerId,
    required this.position,
    this.rotation = 0.0,
    this.visible = true,
    this.alpha = 1.0,
    this.infoWindow = const InfoWindow(),
    this.onTap,
    this.draggable = false,
    this.onDragEnd,
    this.icon,
  });
}

/// Classe para representar um identificador de polilinha
class PolylineId {
  final String value;

  const PolylineId(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PolylineId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PolylineId($value)';
}

/// Classe para representar uma polilinha
class Polyline {
  final PolylineId polylineId;
  final List<LatLng> points;
  final Color color;
  final double width;
  final bool geodesic;
  final bool visible;
  final int zIndex;

  const Polyline({
    required this.polylineId,
    required this.points,
    this.color = Colors.blue,
    this.width = 1.0,
    this.geodesic = false,
    this.visible = true,
    this.zIndex = 0,
  });
}

/// Classe para representar um descritor de bitmap
class BitmapDescriptor {
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

  final dynamic _descriptor;

  const BitmapDescriptor._(this._descriptor);

  static BitmapDescriptor defaultMarker = const BitmapDescriptor._('defaultMarker');
  
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    return BitmapDescriptor._({'hue': hue});
  }
  
  /// Retorna o descritor interno
  dynamic get descriptor => _descriptor;
}
