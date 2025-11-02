import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart' as flutter_map;

// Não precisamos importar tuple diretamente, pois é uma dependência do flutter_map

/// Este arquivo fornece adaptadores globais para migrar de Google Maps e Mapbox para MapTiler
/// Ele define classes e tipos que são usados em todo o aplicativo para manter a compatibilidade

/// Classe para representar um ponto de latitude e longitude
class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);

  /// Converte para o formato LatLng do pacote latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }

  /// Cria uma instância a partir do formato LatLng do pacote latlong2
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

/// Classe para representar limites de latitude e longitude
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({required this.southwest, required this.northeast});

  /// Cria limites a partir de uma lista de pontos
  static LatLngBounds fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(-15.793889, -47.882778), // Brasília como default
        northeast: LatLng(-15.793889, -47.882778),
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

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Retorna o ponto central dos limites
  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }

  /// Converte para o formato LatLngBounds do flutter_map
  flutter_map.LatLngBounds toFlutterMapBounds() {
    return flutter_map.LatLngBounds(
      latlong2.LatLng(southwest.latitude, southwest.longitude),
      latlong2.LatLng(northeast.latitude, northeast.longitude),
    );
  }
}

/// Classe para representar um polígono
class Polygon {
  final String polygonId;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final bool geodesic;
  final bool visible;
  final int zIndex;

  const Polygon({
    required this.polygonId,
    required this.points,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.0,
    this.geodesic = false,
    this.visible = true,
    this.zIndex = 0,
  });

  /// Converte para o formato Polygon do flutter_map
  flutter_map.Polygon toFlutterMapPolygon() {
    return flutter_map.Polygon(
      points: points.map((p) => p.toLatLong2()).toList(),
      color: fillColor.withOpacity(0.5),
      borderColor: strokeColor,
      borderStrokeWidth: strokeWidth,
      isFilled: true,
    );
    // O polygonId e outros parâmetros não são usados diretamente no flutter_map.Polygon
    // mas são mantidos para compatibilidade com o código existente
  }
}

/// Classe para representar um marcador
class Marker {
  final String markerId;
  final LatLng position;
  final double rotation;
  final bool visible;
  final double alpha;
  final InfoWindow infoWindow;
  final VoidCallback? onTap;
  final bool draggable;
  final Function(LatLng)? onDragEnd;
  final Widget? child;
  final double width;
  final double height;

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
    this.child,
    this.width = 30.0,
    this.height = 30.0,
  });

  /// Converte para o formato Marker do flutter_map
  flutter_map.Marker toFlutterMapMarker() {
    return flutter_map.Marker(
      point: position.toLatLong2(),
      width: width,
      height: height,
      rotate: true,
      child: GestureDetector(
        onTap: onTap,
        child: child ??
            Icon(
              Icons.location_on,
              color: Colors.red.withOpacity(alpha),
              size: 30.0,
            ),
      ),
    );
  }
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

/// Classe para representar uma posição de câmera
class CameraPosition {
  final LatLng target;
  final double zoom;
  final double bearing;
  final double tilt;

  const CameraPosition({
    required this.target,
    this.zoom = 15.0,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });
}

/// Classe para atualização de câmera
class CameraUpdate {
  final dynamic _update;

  CameraUpdate._(this._update);

  /// Cria uma atualização de câmera para uma nova posição
  static CameraUpdate newLatLng(LatLng latLng) {
    return CameraUpdate._(latLng);
  }

  /// Cria uma atualização de câmera para uma nova posição e zoom
  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) {
    return CameraUpdate._({'latLng': latLng, 'zoom': zoom});
  }

  /// Cria uma atualização de câmera para ajustar aos limites
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, [double padding = 50.0]) {
    return CameraUpdate._({'bounds': bounds, 'padding': padding});
  }
}

/// Classe para representar um controlador de mapa
class MapboxMapController {
  final flutter_map.MapController _controller;

  MapboxMapController(this._controller);

  /// Obtém a posição atual do mapa
  LatLng get center => LatLng.fromLatLong2(_controller.center);

  /// Move a câmera para uma nova posição
  void moveCamera(CameraUpdate update) {
    if (update._update is LatLng) {
      final latLng = update._update as LatLng;
      _controller.move(latLng.toLatLong2(), _controller.zoom);
    } else if (update._update is Map) {
      final updateMap = update._update as Map;
      if (updateMap.containsKey('latLng') && updateMap.containsKey('zoom')) {
        final latLng = updateMap['latLng'] as LatLng;
        final zoom = updateMap['zoom'] as double;
        _controller.move(latLng.toLatLong2(), zoom);
      } else if (updateMap.containsKey('bounds') && updateMap.containsKey('padding')) {
        // Implementação para ajustar aos limites
        // Esta é uma simplificação, pois o flutter_map não tem um método direto para isso
        final bounds = updateMap['bounds'] as LatLngBounds;
        final centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
        final centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
        final center = latlong2.LatLng(centerLat, centerLng);
        
        // Calcular o zoom apropriado com base nos limites
        // Esta é uma aproximação simples
        final latDiff = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
        final lngDiff = (bounds.northeast.longitude - bounds.southwest.longitude).abs();
        final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
        
        // Fórmula aproximada para zoom baseada na diferença de coordenadas
        final zoom = maxDiff > 0 ? 15.0 - (maxDiff * 10.0) : 15.0;
        
        _controller.move(center, zoom.clamp(1.0, 18.0).toDouble());
      }
    }
  }

  /// Anima a câmera para uma nova posição
  void animateCamera(CameraUpdate update) {
    // No flutter_map, não há diferença entre move e animate
    moveCamera(update);
  }

  /// Obtém a posição atual do usuário (simulação)
  Future<LatLng> requestMyLocationLatLng() async {
    // Retorna uma posição padrão, pois o flutter_map não tem essa funcionalidade
    return LatLng(-15.793889, -47.882778); // Brasília como default
  }
}

/// Enumerador para o tipo de mapa
enum MapType {
  normal,
  satellite,
  terrain,
  hybrid,
  none,
}

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

  /// Converte para o formato Polyline do flutter_map
  flutter_map.Polyline toFlutterMapPolyline() {
    return flutter_map.Polyline(
      points: points.map((p) => p.toLatLong2()).toList(),
      color: color,
      strokeWidth: width,
    );
  }
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
  
  /// Retorna o descritor interno
  dynamic get descriptor => _descriptor;
  
  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    return BitmapDescriptor._({'hue': hue});
  }
}

/// Classe para representar uma coordenada na tela
class ScreenCoordinate {
  final int x;
  final int y;

  const ScreenCoordinate({required this.x, required this.y});
}

/// Utilitários para conversão entre diferentes formatos de coordenadas
class MapUtils {
  /// Converte uma lista de LatLng para uma lista de latlong2.LatLng
  static List<latlong2.LatLng> toLatLong2List(List<LatLng> points) {
    return points.map((p) => p.toLatLong2()).toList();
  }

  /// Converte uma lista de latlong2.LatLng para uma lista de LatLng
  static List<LatLng> fromLatLong2List(List<latlong2.LatLng> points) {
    return points.map((p) => LatLng.fromLatLong2(p)).toList();
  }

  /// Calcula a área de um polígono em hectares
  static double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    const double earthRadius = 6371000; // em metros
    double area = 0;

    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      
      final p1 = points[i];
      final p2 = points[j];
      
      final lat1 = p1.latitude * pi / 180;
      final lat2 = p2.latitude * pi / 180;
      final lon1 = p1.longitude * pi / 180;
      final lon2 = p2.longitude * pi / 180;
      
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area * earthRadius * earthRadius / 2.0;
    area = area.abs();
    
    // Converter de metros quadrados para hectares
    return area / 10000;
  }
}

