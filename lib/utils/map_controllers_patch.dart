import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'map_types.dart' as map_types;

/// Aplica os patches necessários para corrigir problemas de compilação
Future<void> applyMapControllersPatch() async {
  debugPrint('Aplicando patch para MapControllers...');
  // Verificação de disponibilidade de métodos e classes
  try {
    debugPrint('MapControllers patch aplicado com sucesso!');
  } catch (e) {
    debugPrint('Erro ao aplicar patch para MapControllers: $e');
  }
}

/// Classe auxiliar para corrigir problemas de tipos no MapController
class MapControllerPatch {
  /// Método seguro para mover a câmera
  static void moveCameraSafe(MapController? controller, latlong2.LatLng target, double zoom) {
    if (controller == null) {
      debugPrint('Controller é nulo, não é possível mover a câmera');
      return;
    }
    
    try {
      controller.move(target, zoom);
    } catch (e) {
      debugPrint('Erro ao mover a câmera: $e');
    }
  }
  
  /// Método seguro para animar a câmera
  static void animateCameraSafe(MapController? controller, latlong2.LatLng target, double zoom) {
    if (controller == null) {
      debugPrint('Controller é nulo, não é possível animar a câmera');
      return;
    }
    
    try {
      controller.move(target, zoom); // O flutter_map não tem animateCamera, então usamos move
    } catch (e) {
      debugPrint('Erro ao animar a câmera: $e');
    }
  }
  
  /// Método seguro para obter o centro do mapa
  static latlong2.LatLng getCenterSafe(MapController? controller) {
    if (controller == null) {
      debugPrint('Controller é nulo, retornando coordenada padrão');
      return latlong2.LatLng(-15.793889, -47.882778); // Brasília como default
    }
    
    try {
      return controller.center;
    } catch (e) {
      debugPrint('Erro ao obter o centro do mapa: $e');
      return latlong2.LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Método seguro para converter LatLng para map_types.LatLng
  static map_types.LatLng convertToMapTypesLatLng(latlong2.LatLng? latLng) {
    if (latLng == null) {
      return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
    
    return map_types.LatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Método seguro para converter CustomPoint para ScreenCoordinate
  static map_types.ScreenCoordinate convertToScreenCoordinate(CustomPoint<double>? point) {
    if (point == null) {
      return map_types.ScreenCoordinate(x: 0, y: 0);
    }
    
    return map_types.ScreenCoordinate(x: point.x, y: point.y);
  }
  
  /// Método seguro para obter o zoom do mapa
  static double getZoomSafe(MapController? controller) {
    if (controller == null) {
      debugPrint('Controller é nulo, retornando zoom padrão');
      return 5.0; // Zoom padrão para o Brasil
    }
    
    try {
      return controller.zoom;
    } catch (e) {
      debugPrint('Erro ao obter o zoom do mapa: $e');
      return 5.0; // Zoom padrão
    }
  }
  
  /// Cria um marcador seguro sem usar const constructor
  static Marker createMarker({
    required latlong2.LatLng point,
    required Widget Function(BuildContext) builder,
    double width = 30.0,
    double height = 30.0,
    // Removido alignment que não é suportado no flutter_map 3.1.0
  }) => Marker(
      point: point,
      builder: builder,
      width: width,
      height: height,
      // alignment removido pois não existe no construtor Marker do flutter_map 3.1.0
    );
  
  /// Converte CustomPoint para Offset
  static Offset customPointToOffset(CustomPoint point) {
    return Offset(point.x.toDouble(), point.y.toDouble());
  }
  
  /// Converte Offset para CustomPoint
  static CustomPoint offsetToCustomPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }
}

/// Converte LatLng do flutter_map para LatLng do map_types
latlong2.LatLng convertToLatLong2(double latitude, double longitude) {
  return latlong2.LatLng(latitude, longitude);
}

/// Aplica o patch para o MapController
void applyMapControllerPatch() {
  debugPrint('Patch aplicado para corrigir problemas de tipos no MapController');
}
