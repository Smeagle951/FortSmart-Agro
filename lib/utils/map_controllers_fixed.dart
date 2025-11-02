import 'dart:math' as dart_math;

import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong2;
import 'map_types.dart' as map_types;

/// Classe para representar um controlador de mapa compatível com MapTiler
class MapboxMapController {
  final flutter_map.MapController _controller;
  
  MapboxMapController(this._controller);
  
  /// Obtém a posição atual do mapa
  map_types.LatLng get center {
    try {
      return map_types.LatLng(
        _controller.center.latitude,
        _controller.center.longitude,
      );
    } catch (e) {
      return const map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Obtém o nível de zoom atual do mapa
  double get zoom {
    try {
      return _controller.zoom;
    } catch (e) {
      return 15.0; // Zoom padrão
    }
  }
  
  /// Move o mapa para uma posição específica
  Future<void> moveCamera(map_types.CameraPosition cameraPosition) async {
    try {
      _controller.move(
        latlong2.LatLng(
          cameraPosition.target.latitude,
          cameraPosition.target.longitude,
        ),
        cameraPosition.zoom,
      );
    } catch (e) {
      // Ignora erros
    }
  }
  
  /// Move o mapa para uma posição específica com animação
  Future<void> animateCamera(map_types.CameraPosition cameraPosition) async {
    try {
      _controller.move(
        latlong2.LatLng(
          cameraPosition.target.latitude,
          cameraPosition.target.longitude,
        ),
        cameraPosition.zoom,
      );
    } catch (e) {
      // Ignora erros
    }
  }
  
  /// Obtém a posição atual do usuário
  Future<map_types.LatLng> requestMyLocationLatLng() async {
    // Retorna uma posição padrão, pois o flutter_map não tem essa funcionalidade
    return const map_types.LatLng(-15.793889, -47.882778); // Brasília como default
  }
  
  /// Converte um ponto na tela para coordenadas geográficas
  Future<map_types.LatLng> getLatLng(map_types.ScreenCoordinate screenCoordinate) async {
    try {
      // Tenta usar o método pointToLatLng do flutter_map
      final latLng = _controller.pointToLatLng(CustomPoint<double>(
        screenCoordinate.x.toDouble(),
        screenCoordinate.y.toDouble(),
      ));
      
      return map_types.LatLng(latLng.latitude, latLng.longitude);
    } catch (e) {
      // Fallback para um valor padrão
      return const map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Calcula os limites visíveis do mapa
  map_types.LatLngBounds getVisibleRegion() {
    try {
      final bounds = _controller.bounds;
      
      return map_types.LatLngBounds(
        map_types.LatLng(bounds.south, bounds.west),
        map_types.LatLng(bounds.north, bounds.east),
      );
    } catch (e) {
      // Fallback para um valor padrão
      return map_types.LatLngBounds(
        const map_types.LatLng(-23.6821, -46.8754), // São Paulo SW
        const map_types.LatLng(-23.4821, -46.6754), // São Paulo NE
      );
    }
  }
}

/// Classe para representar um controlador de mapa compatível com Google Maps
class GoogleMapController {
  final flutter_map.MapController _controller;
  
  GoogleMapController(this._controller);
  
  /// Obtém a posição atual do mapa
  map_types.LatLng get center {
    try {
      return map_types.LatLng(
        _controller.center.latitude,
        _controller.center.longitude,
      );
    } catch (e) {
      return const map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Obtém o nível de zoom atual do mapa
  double get zoom {
    try {
      return _controller.zoom;
    } catch (e) {
      return 15.0; // Zoom padrão
    }
  }
  
  /// Move o mapa para uma posição específica
  Future<void> moveCamera(map_types.CameraPosition cameraPosition) async {
    try {
      _controller.move(
        latlong2.LatLng(
          cameraPosition.target.latitude,
          cameraPosition.target.longitude,
        ),
        cameraPosition.zoom,
      );
    } catch (e) {
      // Ignora erros
    }
  }
  
  /// Move o mapa para uma posição específica com animação
  Future<void> animateCamera(map_types.CameraPosition cameraPosition) async {
    try {
      _controller.move(
        latlong2.LatLng(
          cameraPosition.target.latitude,
          cameraPosition.target.longitude,
        ),
        cameraPosition.zoom,
      );
    } catch (e) {
      // Ignora erros
    }
  }
  
  /// Obtém a posição atual do usuário
  Future<map_types.LatLng> requestMyLocationLatLng() async {
    // Retorna uma posição padrão, pois o flutter_map não tem essa funcionalidade
    return const map_types.LatLng(-15.793889, -47.882778); // Brasília como default
  }
  
  /// Converte um ponto na tela para coordenadas geográficas
  Future<map_types.LatLng> getLatLng(map_types.ScreenCoordinate screenCoordinate) async {
    try {
      // Tenta usar o método pointToLatLng do flutter_map
      final latLng = _controller.pointToLatLng(CustomPoint<double>(
        screenCoordinate.x.toDouble(),
        screenCoordinate.y.toDouble(),
      ));
      
      return map_types.LatLng(latLng.latitude, latLng.longitude);
    } catch (e) {
      // Fallback para um valor padrão
      return const map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Calcula os limites visíveis do mapa
  map_types.LatLngBounds getVisibleRegion() {
    try {
      final bounds = _controller.bounds;
      
      return map_types.LatLngBounds(
        map_types.LatLng(bounds.south, bounds.west),
        map_types.LatLng(bounds.north, bounds.east),
      );
    } catch (e) {
      // Fallback para um valor padrão
      return map_types.LatLngBounds(
        const map_types.LatLng(-23.6821, -46.8754), // São Paulo SW
        const map_types.LatLng(-23.4821, -46.6754), // São Paulo NE
      );
    }
  }
}
