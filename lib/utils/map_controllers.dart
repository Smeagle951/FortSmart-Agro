

import 'dart:math' as dart_math;
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart' show CustomPoint;
import 'map_types.dart' as map_types;
import 'map_controllers_fix.dart';

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
      return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Move a câmera para uma nova posição
  void moveCamera(map_types.CameraUpdate update) {
    final updateData = update.value;
    
    if (updateData is Map) {
      final type = updateData['type'] as String;
      
      if (type == 'latLng' || type == 'latLngZoom') {
        final target = updateData['target'] as map_types.LatLng;
        final zoom = type == 'latLngZoom' ? (updateData['zoom'] as double) : 15.0;
        
        _controller.move(
          latlong2.LatLng(target.latitude, target.longitude),
          zoom,
        );
      } else if (type == 'bounds') {
        // Usar o tipo LatLngBounds do arquivo map_types.dart
        final bounds = updateData['bounds'] as map_types.LatLngBounds;
        final padding = updateData['padding'] as double;
        
        // Calcular o centro e zoom apropriado para os limites
        final center = bounds.center;
        
        // Calcular um zoom aproximado com base na distância entre os pontos
        final latDiff = (bounds.northeast.latitude - bounds.southwest.latitude).abs();
        final lngDiff = (bounds.northeast.longitude - bounds.southwest.longitude).abs();
        final maxDiff = dart_math.max(latDiff, lngDiff);
        
        // Ajustar o zoom com base no padding
        final paddingFactor = padding / 500.0; // Fator arbitrário para ajustar o zoom
        
        final zoom = maxDiff > 0 ? 15.0 - (maxDiff * 10.0) - paddingFactor : 15.0 - paddingFactor;
        
        _controller.move(
          latlong2.LatLng(center.latitude, center.longitude),
          zoom.clamp(1.0, 18.0).toDouble(),
        );
      }
    } else if (updateData is map_types.CameraUpdateMove) {
      // Compatibilidade com o formato antigo
      _controller.move(
        latlong2.LatLng(updateData.latLng.latitude, updateData.latLng.longitude),
        updateData.zoom,
      );
    }
  }
  
  /// Anima a câmera para uma nova posição
  void animateCamera(map_types.CameraUpdate update) {
    // No flutter_map não há uma animação nativa, então usamos moveCamera
    // Em uma implementação futura, poderia ser adicionada uma animação personalizada
    moveCamera(update);
  }
  
  /// Obtém a posição atual do usuário (simulação)
  Future<map_types.LatLng> requestMyLocationLatLng() async {
    // Retorna uma posição padrão, pois o flutter_map não tem essa funcionalidade
    return MapControllerUtils.getDefaultLatLng();
  }
  
  /// Converte um ponto na tela para coordenadas geográficas
  Future<map_types.LatLng> getLatLng(map_types.ScreenCoordinate screenCoordinate) async {
    try {
      // Tenta usar o método pointToLatLng do flutter_map
      final latLng = _controller.pointToLatLng(CustomPoint<double>(
        screenCoordinate.x.toDouble(),
        screenCoordinate.y.toDouble(),
      ));
      
      if (latLng != null) {
        return map_types.LatLng(latLng.latitude, latLng.longitude);
      } else {
        return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
      }
    } catch (e) {
      // Fallback para um valor padrão
      return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Converte coordenadas geográficas para um ponto na tela
  Future<map_types.ScreenCoordinate> getScreenCoordinate(map_types.LatLng latLng) async {
    try {
      // Tenta usar o método latLngToScreenPoint do flutter_map
      final point = _controller.latLngToScreenPoint(
        latlong2.LatLng(latLng.latitude, latLng.longitude),
      );
      
      if (point != null) {
        return map_types.ScreenCoordinate(
          x: point.x.toDouble(),
          y: point.y.toDouble(),
        );
      } else {
        return map_types.ScreenCoordinate(x: 0, y: 0);
      }
    } catch (e) {
      // Fallback para um valor padrão
      return map_types.ScreenCoordinate(x: 0, y: 0);
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
      return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Move a câmera para uma nova posição
  Future<void> moveCamera(map_types.CameraUpdate update) async {
    if (update.value is map_types.CameraUpdateMove) {
      final updateMove = update.value as map_types.CameraUpdateMove;
      _controller.move(
        latlong2.LatLng(updateMove.latLng.latitude, updateMove.latLng.longitude),
        updateMove.zoom,
      );
    } else if (update.value is map_types.CameraUpdateBounds) {
      final updateBounds = update.value as map_types.CameraUpdateBounds;
      // Calcular o centro e zoom apropriado para os limites
      final center = updateBounds.bounds.center;
      
      // Calcular um zoom aproximado com base na distância entre os pontos
      final latDiff = (updateBounds.bounds.northeast.latitude - updateBounds.bounds.southwest.latitude).abs();
      final lngDiff = (updateBounds.bounds.northeast.longitude - updateBounds.bounds.southwest.longitude).abs();
      final maxDiff = dart_math.max(latDiff, lngDiff);
      
      final zoom = maxDiff > 0 ? 15.0 - (maxDiff * 10.0) : 15.0;
      
      _controller.move(
        latlong2.LatLng(center.latitude, center.longitude),
        zoom.clamp(1.0, 18.0),
      );
    }
  }
  
  /// Anima a câmera para uma nova posição
  Future<void> animateCamera(map_types.CameraUpdate update) async {
    // No flutter_map, não há diferença entre move e animate
    await moveCamera(update);
  }
  
  /// Converte um ponto na tela para coordenadas geográficas
  Future<map_types.LatLng> getLatLng(map_types.ScreenCoordinate screenCoordinate) async {
    try {
      // Tenta usar o método pointToLatLng do flutter_map
      final latLng = _controller.pointToLatLng(CustomPoint<double>(
        screenCoordinate.x.toDouble(),
        screenCoordinate.y.toDouble(),
      ));
      
      if (latLng != null) {
        return map_types.LatLng(latLng.latitude, latLng.longitude);
      } else {
        return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
      }
    } catch (e) {
      // Fallback para um valor padrão
      return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Converte coordenadas geográficas para um ponto na tela
  Future<map_types.ScreenCoordinate> getScreenCoordinate(map_types.LatLng latLng) async {
    try {
      // Tenta usar o método latLngToScreenPoint do flutter_map
      final point = _controller.latLngToScreenPoint(
        latlong2.LatLng(latLng.latitude, latLng.longitude),
      );
      
      if (point != null) {
        return map_types.ScreenCoordinate(
          x: point.x.toDouble(),
          y: point.y.toDouble(),
        );
      } else {
        return map_types.ScreenCoordinate(x: 0, y: 0);
      }
    } catch (e) {
      // Fallback para um valor padrão
      return map_types.ScreenCoordinate(x: 0, y: 0);
    }
  }
  
  /// Método para configurar o estilo do mapa (apenas compatibilidade, não faz nada no MapTiler)
  void setMapStyle(String mapStyle) {
    // No MapTiler, o estilo é configurado de outra forma
    // Este método existe apenas para compatibilidade com o código existente
    print('MapTiler: setMapStyle não tem efeito, use TileLayer com urlTemplate apropriado');
  }
  
  void dispose() {
    // Nada a fazer aqui, o MapController do flutter_map não tem método dispose
  }
}
