import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter/material.dart';
// import 'package:flutter_map/plugin_api.dart'; // Removido devido a incompatibilidade

// Importamos o adaptador global para compatibilidade
import 'map_global_adapter.dart' as map_global;

/// Adaptador para o MapController do flutter_map 5.0.0
/// 
/// Esta classe fornece uma camada de compatibilidade para acessar propriedades
/// que existem em versões mais recentes do flutter_map, mas não na versão 5.0.0.
class MapControllerAdapter {
  final MapController _controller;
  
  MapControllerAdapter(this._controller);
  
  /// Obtém o centro do mapa atual
  latlong2.LatLng get center => _controller.center;
  
  /// Obtém o zoom atual do mapa
  double get zoom => _controller.zoom;
  
  /// Move o mapa para uma nova posição
  void move(latlong2.LatLng center, double zoom) {
    _controller.move(center, zoom);
  }
  
  /// Rotaciona o mapa
  void rotate(double degree) {
    _controller.rotate(degree);
  }
  
  /// Converte um ponto da tela para coordenadas LatLng
  latlong2.LatLng pointToLatLng(CustomPoint<num> point) {
    // Convertendo Point<num> para CustomPoint<num>
    final customPoint = CustomPoint<num>(point.x, point.y);
    final result = _controller.pointToLatLng(customPoint);
    // Tratamento de null safety
    return result ?? latlong2.LatLng(-15.793889, -47.882778); // Retorna Brasília como fallback
  }
  
  /// Converte coordenadas LatLng para um ponto na tela
  CustomPoint<num> latLngToPoint(latlong2.LatLng latLng) {
    final result = _controller.latLngToScreenPoint(latLng);
    // Tratamento de null safety
    return result ?? CustomPoint<num>(0, 0); // Retorna ponto (0,0) como fallback
  }
  
  /// Ajusta o mapa para mostrar os limites especificados
  void fitBounds(flutter_map.LatLngBounds bounds, {FitBoundsOptions? options}) {
    _controller.fitBounds(
      bounds,
      options: options ?? const FitBoundsOptions(),
    );
  }
  
  /// Ajusta o mapa para mostrar os limites especificados usando o adaptador global
  void fitBoundsGlobal(map_global.LatLngBounds bounds, {double padding = 0.0}) {
    final flutter_map.LatLngBounds flutterMapBounds = flutter_map.LatLngBounds(
      latlong2.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
      latlong2.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
    );
    
    _controller.fitBounds(
      flutterMapBounds,
      options: FitBoundsOptions(
        padding: EdgeInsets.all(padding),
      ),
    );
  }
  
  /// Classe interna para simular a propriedade camera que existe em versões mais recentes
  CameraAdapter get camera => CameraAdapter(this);
}

/// Adaptador para a classe Camera que não existe na versão 5.0.0
class CameraAdapter {
  final MapControllerAdapter _adapter;
  
  CameraAdapter(this._adapter);
  
  /// Obtém o centro do mapa atual
  latlong2.LatLng get center => _adapter.center;
  
  /// Obtém o zoom atual do mapa
  double get zoom => _adapter.zoom;
}
