// Script para corrigir erros de flutter_map
// Este arquivo contém as correções necessárias para compatibilidade

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Classe utilitária para corrigir problemas de compatibilidade do flutter_map
class FlutterMapFix {
  
  /// Corrige o parâmetro 'builder' para 'child' em Markers
  static Marker createMarker({
    required LatLng point,
    required Widget child,
    double? width,
    double? height,
  }) {
    return Marker(
      point: point,
      child: child,
      width: width,
      height: height,
    );
  }
  
  /// Corrige as opções do mapa
  static MapOptions createMapOptions({
    LatLng? initialCenter,
    double? initialZoom,
    double? minZoom,
    double? maxZoom,
    bool? interactiveFlags,
  }) {
    return MapOptions(
      initialCenter: initialCenter ?? const LatLng(-23.5505, -46.6333),
      initialZoom: initialZoom ?? 13.0,
      minZoom: minZoom ?? 3.0,
      maxZoom: maxZoom ?? 18.0,
      interactiveFlags: interactiveFlags ?? InteractiveFlag.all,
    );
  }
} 