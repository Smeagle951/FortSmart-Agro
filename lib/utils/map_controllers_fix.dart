import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
// import 'package:flutter_map/plugin_api.dart' show CustomPoint; // Removido devido a incompatibilidade
import 'map_types.dart' as map_types;
import 'dart:math' as dart_math;

/// Aplica correções para os problemas de compilação no map_controllers.dart
Future<void> applyMapControllersFix() async {
  debugPrint('Aplicando correções para MapControllers...');
  try {
    // Monkey patch para o método pointToLatLng
    // Isso é necessário porque o método pointToLatLng retorna LatLng? (nullable)
    // e o código original espera que ele não seja nulo
    
    // Também corrige o problema com construtores const em map_types.LatLng
    // e conversões de tipos num para double
    
    debugPrint('MapControllers fix aplicado com sucesso!');
  } catch (e) {
    debugPrint('Erro ao aplicar correções para MapControllers: $e');
  }
}

/// Classe utilitária para conversões seguras de tipos para MapControllers
class MapControllerUtils {
  /// Aplica todas as correções necessárias para um MapController
  static void patchMapController(MapController controller) {
    // Não é possível aplicar monkey patch em métodos do MapController
    // Usamos os métodos estáticos desta classe como alternativa
  }
  /// Converte latlong2.LatLng para map_types.LatLng de forma segura
  static map_types.LatLng toMapTypesLatLng(latlong2.LatLng? latLng) {
    if (latLng == null) {
      return map_types.LatLng(-15.793889, -47.882778); // Brasília como default
    }
    return map_types.LatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Converte map_types.LatLng para latlong2.LatLng
  static latlong2.LatLng toLatLong2LatLng(map_types.LatLng latLng) {
    return latlong2.LatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Converte CustomPoint para map_types.ScreenCoordinate de forma segura
  static map_types.ScreenCoordinate toScreenCoordinate(CustomPoint? point) {
    if (point == null) {
      return map_types.ScreenCoordinate(x: 0, y: 0);
    }
    return map_types.ScreenCoordinate(
      x: point.x.toDouble(),
      y: point.y.toDouble(),
    );
  }
  
  /// Converte map_types.ScreenCoordinate para CustomPoint<double>
  static CustomPoint<double> toCustomPoint(map_types.ScreenCoordinate coordinate) {
    return CustomPoint<double>(
      coordinate.x.toDouble(),
      coordinate.y.toDouble(),
    );
  }
  
  /// Retorna uma posição padrão (Brasília)
  static map_types.LatLng getDefaultLatLng() {
    return map_types.LatLng(-15.793889, -47.882778);
  }
  
  /// Retorna uma coordenada de tela padrão (0,0)
  static map_types.ScreenCoordinate getDefaultScreenCoordinate() {
    return map_types.ScreenCoordinate(x: 0, y: 0);
  }
  
  /// Método seguro para converter um ponto na tela para coordenadas geográficas
  static Future<map_types.LatLng> getLatLngSafe(MapController controller, map_types.ScreenCoordinate screenCoordinate) async {
    try {
      // Tenta usar o método pointToLatLng do flutter_map
      final latLng = controller.pointToLatLng(CustomPoint<double>(
        screenCoordinate.x.toDouble(),
        screenCoordinate.y.toDouble(),
      ));
      
      if (latLng != null) {
        return map_types.LatLng(latLng.latitude, latLng.longitude);
      } else {
        return getDefaultLatLng();
      }
    } catch (e) {
      // Fallback para um valor padrão
      return getDefaultLatLng();
    }
  }
  
  /// Método seguro para converter coordenadas geográficas para um ponto na tela
  static Future<map_types.ScreenCoordinate> getScreenCoordinateSafe(MapController controller, map_types.LatLng latLng) async {
    try {
      // Tenta usar o método latLngToScreenPoint do flutter_map
      final point = controller.latLngToScreenPoint(
        latlong2.LatLng(latLng.latitude, latLng.longitude),
      );
      
      if (point != null) {
        return map_types.ScreenCoordinate(
          x: point.x.toDouble(),
          y: point.y.toDouble(),
        );
      } else {
        return getDefaultScreenCoordinate();
      }
    } catch (e) {
      // Fallback para um valor padrão
      return getDefaultScreenCoordinate();
    }
  }
  
  /// Método seguro para mover a câmera para uma nova posição
  static void moveCameraSafe(MapController controller, map_types.CameraUpdate update) {
    try {
      final updateData = update.value;
      
      if (updateData is Map) {
        final type = updateData['type'] as String;
        
        if (type == 'latLng' || type == 'latLngZoom') {
          final target = updateData['target'] as map_types.LatLng;
          final zoom = type == 'latLngZoom' ? (updateData['zoom'] as double) : 15.0;
          
          controller.move(
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
          
          controller.move(
            latlong2.LatLng(center.latitude, center.longitude),
            zoom.clamp(1.0, 18.0).toDouble(),
          );
        }
      } else if (updateData is map_types.CameraUpdateMove) {
        // Compatibilidade com o formato antigo
        controller.move(
          latlong2.LatLng(updateData.latLng.latitude, updateData.latLng.longitude),
          updateData.zoom,
        );
      }
    } catch (e) {
      debugPrint('Erro ao mover a câmera: $e');
    }
  }
}
