import 'package:flutter/material.dart';
import 'maptiler_maps_widget.dart';

// Redirecionamento para manter compatibilidade com código existente
// @deprecated Use MapTilerMapsWidget diretamente em vez desta classe
export 'maptiler_maps_widget.dart';

/// Esta classe é apenas um alias para MapTilerMapsWidget
/// Mantida para compatibilidade durante a migração do Google Maps para MapTiler
@Deprecated('Use MapTilerMapsWidget em vez desta classe. Esta classe será removida em versões futuras.')
typedef GoogleMapsWidget = MapTilerMapsWidget;
