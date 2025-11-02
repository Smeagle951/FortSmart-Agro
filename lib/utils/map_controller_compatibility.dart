import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'dart:math' as math;
import 'package:flutter_map/src/misc/point.dart';

/// Adaptador para o MapController do flutter_map 5.0.0
/// 
/// Esta classe fornece uma camada de compatibilidade para acessar propriedades
/// que existem em versões mais recentes do flutter_map, mas não na versão 5.0.0.
class MapControllerCompat {
  final MapController _controller;
  
  MapControllerCompat(this._controller);
  
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
  latlong2.LatLng pointToLatLng(math.Point<num> point) {
    // Convertendo Point<num> para CustomPoint<num>
    final customPoint = CustomPoint<num>(point.x, point.y);
    return _controller.pointToLatLng(customPoint);
  }
  
  /// Converte coordenadas LatLng para um ponto na tela
  CustomPoint<num> latLngToPoint(latlong2.LatLng latLng) {
    return _controller.latLngToScreenPoint(latLng);
  }
  
  /// Ajusta o mapa para mostrar os limites especificados
  void fitBounds(LatLngBounds bounds, {FitBoundsOptions? options}) {
    _controller.fitBounds(bounds, options: options ?? const FitBoundsOptions());
  }
  
  /// Classe interna para simular a propriedade camera que existe em versões mais recentes
  CameraCompat get camera => CameraCompat(this);
  
  /// Acesso direto ao controlador original
  MapController get controller => _controller;
}

/// Adaptador para a classe Camera que não existe na versão 5.0.0
class CameraCompat {
  final MapControllerCompat _adapter;
  
  CameraCompat(this._adapter);
  
  /// Obtém o centro do mapa atual
  latlong2.LatLng get center => _adapter.center;
  
  /// Obtém o zoom atual do mapa
  double get zoom => _adapter.zoom;
}

/// Extensão para facilitar a conversão entre MapController e MapControllerCompat
extension MapControllerCompatExtension on MapController {
  /// Converte um MapController para MapControllerCompat
  MapControllerCompat get compat => MapControllerCompat(this);
}
