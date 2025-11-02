import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Extensão para adicionar o método copyWith à classe MapOptions
extension MapOptionsExtension on MapOptions {
  /// Cria uma nova instância de MapOptions com os valores especificados alterados
  MapOptions copyWith({
    LatLng? center,
    double? zoom,
    double? minZoom,
    double? maxZoom,
    bool? enableScrollWheel,
    bool? enableMultiFingerGestureRace,
    bool? enableMultiFingerGestureDrag,
    double? rotationThreshold,
    int? interactiveFlags,
    TapCallback? onTap,
    TapCallback? onLongPress,
    PositionCallback? onPositionChanged,
    bool? keepAlive,
    FitBoundsOptions? boundsOptions,
    LatLngBounds? bounds,
    LatLngBounds? screenBounds,
    bool? adaptiveBoundaries,
    bool? debugMultiFingerGestureWinner,
    double? rotation,
    String? crs,
  }) {
    return MapOptions(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      rotation: rotation ?? this.rotation,
      interactiveFlags: interactiveFlags ?? this.interactiveFlags,
      // onTap: onTap ?? this.onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
      onLongPress: onLongPress ?? this.onLongPress,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
      keepAlive: keepAlive ?? this.keepAlive,
    );
  }
}
