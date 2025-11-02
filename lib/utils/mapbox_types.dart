
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart';

/// Este arquivo fornece tipos de compatibilidade para facilitar a migração do Mapbox para o MapTiler
/// Ele define apenas os tipos essenciais e simplifica a interface

// Tipos básicos
typedef LatLng = latlong2.LatLng;
typedef MapboxMapController = MapController;

// Classe simplificada para posição da câmera
class CameraPosition {
  final latlong2.LatLng target;
  final double zoom;
  
  CameraPosition({required this.target, this.zoom = 15.0});
}

// Classe simplificada para atualização da câmera
class CameraUpdate {
  static CameraUpdate newLatLng(latlong2.LatLng latLng) {
    return CameraUpdate._create(latLng, null);
  }
  
  static CameraUpdate newLatLngZoom(latlong2.LatLng latLng, double zoom) {
    return CameraUpdate._create(latLng, zoom);
  }
  
  final latlong2.LatLng latLng;
  final double? zoom;
  
  CameraUpdate._create(this.latLng, this.zoom);
}

// Classe simplificada para limites de coordenadas
class LatLngBounds {
  final latlong2.LatLng southwest;
  final latlong2.LatLng northeast;
  
  LatLngBounds({required this.southwest, required this.northeast});
}

// Constantes para estilos do MapTiler
class MapboxStyles {
  static const String MAPBOX_STREETS = 'https://api.maptiler.com/maps/streets/style.json';
  static const String MAPBOX_OUTDOORS = 'https://api.maptiler.com/maps/outdoor/style.json';
  static const String MAPBOX_SATELLITE = 'https://api.maptiler.com/maps/satellite/style.json';
  static const String MAPBOX_SATELLITE_STREETS = 'https://api.maptiler.com/maps/hybrid/style.json';
}

// Classe para coordenadas na tela
class ScreenCoordinate {
  final double x;
  final double y;
  
  ScreenCoordinate(this.x, this.y);
}

// Classe para opções de símbolos
class SymbolOptions {
  final latlong2.LatLng? geometry;
  final String? iconImage;
  final double? iconSize;
  final Color? iconColor;
  final bool? draggable;
  final String? textField;
  final double? textSize;
  final Color? textColor;
  final bool? consumeTapEvents;
  final Function? onTap;
  
  SymbolOptions({
    this.geometry,
    this.iconImage,
    this.iconSize,
    this.iconColor,
    this.draggable,
    this.textField,
    this.textSize,
    this.textColor,
    this.consumeTapEvents,
    this.onTap,
  });
}

// Classe para símbolos
class Symbol {
  final String id;
  final SymbolOptions options;
  
  Symbol(this.id, this.options);
}

// Classe para opções de linhas
class LineOptions {
  final List<latlong2.LatLng>? geometry;
  final Color? color;
  final double? width;
  
  LineOptions({
    this.geometry,
    this.color,
    this.width,
  });
}

// Classe para linhas
class Line {
  final String id;
  final LineOptions options;
  
  Line(this.id, this.options);
}

// Classe para opções de círculos
class CircleOptions {
  final latlong2.LatLng? geometry;
  final Color? circleColor;
  final double? circleRadius;
  final Color? circleStrokeColor;
  final double? circleStrokeWidth;
  
  CircleOptions({
    this.geometry,
    this.circleColor,
    this.circleRadius,
    this.circleStrokeColor,
    this.circleStrokeWidth,
  });
}

// Classe para círculos
class Circle {
  final String id;
  final CircleOptions options;
  
  Circle(this.id, this.options);
}

// Classe para opções de polígonos
class FillOptions {
  final List<List<latlong2.LatLng>>? geometry;
  final Color? fillColor;
  final Color? fillOutlineColor;
  
  FillOptions({
    this.geometry,
    this.fillColor,
    this.fillOutlineColor,
  });
}

// Classe para polígonos
class Fill {
  final String id;
  final FillOptions options;
  
  Fill(this.id, this.options);
}

/// Extensão para facilitar a conversão entre tipos
extension LatLngExtension on latlong2.LatLng {
  latlong2.LatLng toMapTiler() {
    return this; // Já é latlong2.LatLng
  }
}
