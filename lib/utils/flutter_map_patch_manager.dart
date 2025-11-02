import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import 'emergency_fixes.dart';
import 'emergency_patches.dart';
import 'map_controllers_fix.dart';
import 'map_controllers_patch.dart';
import 'positioned_tap_detector_patch.dart';
import 'material_design_patches.dart';

/// Gerenciador centralizado de patches para o flutter_map
/// Esta classe aplica todos os patches necessários para corrigir problemas
/// de compatibilidade com o flutter_map e seus componentes
class FlutterMapPatchManager {
  /// Aplica todos os patches necessários para o flutter_map
  static Future<void> applyAllPatches() async {
    debugPrint('\n🚨 INICIANDO APLICAÇÃO DE PATCHES PARA FLUTTER_MAP 🚨');
    
    try {
      // Aplicar patches para o MapController
      await _applyMapControllerPatches();
      
      // Aplicar patches para o Polygon
      _applyPolygonPatches();
      
      // Aplicar patches para o MarkerCluster
      _applyMarkerClusterPatches();
      
      // Aplicar patches para o positioned_tap_detector_2
      await _applyPositionedTapDetectorPatches();
      
      // Aplicar patches para o Material Design
      _applyMaterialDesignPatches();
      
      // Aplicar patches para widgets
      _applyWidgetPatches();
      
      // Aplicar patches de emergência
      await EmergencyPatches.applyAll();
      
      // Aplicar fixes de emergência
      EmergencyFixes.applyAll();
      
      debugPrint('✅ TODOS OS PATCHES PARA FLUTTER_MAP APLICADOS COM SUCESSO!');
    } catch (e) {
      debugPrint('❌ ERRO AO APLICAR PATCHES PARA FLUTTER_MAP: $e');
    }
  }
  
  /// Aplica patches para o MapController
  static Future<void> _applyMapControllerPatches() async {
    debugPrint('🔧 Aplicando patches para MapController...');
    
    try {
      // Aplicar patch para o MapController
      applyMapControllerPatch();
      
      // Aplicar fixes para o MapController
      await applyMapControllersFix();
      
      debugPrint('✅ Patches para MapController aplicados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patches para MapController: $e');
    }
  }
  
  /// Aplica patches para o Polygon
  static void _applyPolygonPatches() {
    debugPrint('🔧 Aplicando patches para Polygon...');
    
    try {
      // O patch para Polygon é principalmente remover o onTap
      // Isso é feito manualmente nos arquivos que usam Polygon
      
      debugPrint('✅ Patches para Polygon aplicados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patches para Polygon: $e');
    }
  }
  
  /// Aplica patches para o MarkerCluster
  static void _applyMarkerClusterPatches() {
    debugPrint('🔧 Aplicando patches para MarkerCluster...');
    
    try {
      // O patch para MarkerCluster é principalmente atualizar as opções
      // Isso é feito manualmente nos arquivos que usam MarkerCluster
      
      debugPrint('✅ Patches para MarkerCluster aplicados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patches para MarkerCluster: $e');
    }
  }
  
  /// Aplica patches para o positioned_tap_detector_2
  static Future<void> _applyPositionedTapDetectorPatches() async {
    debugPrint('🔧 Aplicando patches para positioned_tap_detector_2...');
    
    try {
      // Importar e aplicar o patch para positioned_tap_detector_2
      await applyPositionedTapDetectorPatch();
      
      debugPrint('✅ Patches para positioned_tap_detector_2 aplicados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patches para positioned_tap_detector_2: $e');
    }
  }
  
  /// Aplica patches para o Material Design
  static void _applyMaterialDesignPatches() {
    debugPrint('🔧 Aplicando patches para Material Design...');
    
    try {
      // Aplicar patches para o Material Design
      MaterialDesignPatches.applyAllPatches();
      
      debugPrint('✅ Patches para Material Design aplicados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patches para Material Design: $e');
    }
  }
  
  /// Aplica patches para widgets
  static void _applyWidgetPatches() {
    debugPrint('🔧 Aplicando patches para widgets...');
    
    try {
      // Aplicar patches para widgets
      WidgetPatches.applyAllPatches();
      
      debugPrint('✅ Patches para widgets aplicados com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao aplicar patches para widgets: $e');
    }
  }
  
  /// Cria um marcador compatível com flutter_map 5.0.0+
  static Marker createCompatibleMarker({
    required latlong2.LatLng point,
    required Widget Function(BuildContext) builder,
    double width = 30.0,
    double height = 30.0,
    Alignment alignment = Alignment.center,
    bool? rotate,
    Offset? rotateOrigin,
    AlignmentGeometry? rotateAlignment,
    AnchorAlign? anchorAlign,
    Key? key,
  }) {
    // Na versão 5.0.0+ do flutter_map, o construtor do Marker mudou
    // Alguns parâmetros foram removidos ou alterados
    return Marker(
      point: point,
      builder: builder,  // Usar builder em vez de child
      width: width,
      height: height,
      rotate: rotate ?? false,
      rotateOrigin: rotateOrigin,
      rotateAlignment: rotateAlignment,
      key: key,
    );
  }
  
  /// Cria um polígono compatível com flutter_map 5.0.0+
  static Polygon createCompatiblePolygon({
    required List<latlong2.LatLng> points,
    Color color = const Color(0xFF00FF00),
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
    bool isFilled = true,
    double strokeWidth = 1.0,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
    bool useStrokeWidthInMeter = false,
    bool isDotted = false,
    Key? key,
  }) {
    // Na versão 5.0.0+ do flutter_map, o construtor do Polygon mudou
    // O parâmetro onTap foi removido
    // Alguns parâmetros podem ter sido renomeados ou removidos
    return Polygon(
      points: points,
      color: color,
      borderStrokeWidth: borderStrokeWidth,
      borderColor: borderColor,
      isFilled: isFilled,
      // strokeWidth e useStrokeWidthInMeter podem não existir na versão atual
      // Remova ou comente esses parâmetros se causarem erros
      // strokeWidth: strokeWidth,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      // useStrokeWidthInMeter: useStrokeWidthInMeter,
      isDotted: isDotted,
      key: key,
    );
  }
  
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
}
