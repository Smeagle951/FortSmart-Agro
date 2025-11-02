import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
// Importar o adaptador global
import 'map_imports.dart' as maps;
import 'map_controller_adapter.dart';

/// Este arquivo contém classes e definições para manter a compatibilidade
/// com o código existente que usa Mapbox GL, facilitando a migração para o MapTiler

/// Classe de compatibilidade para a classe LatLng do Mapbox
/// Agora usa a classe do adaptador global
typedef LatLng = maps.LatLng;

/// Extensão para adicionar métodos de compatibilidade à classe LatLng
extension LatLngCompat on maps.LatLng {
  /// Converte para o formato LatLng do pacote latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }
}

/// Classe com métodos estáticos para conversão de LatLng
class LatLngConverter {
  /// Cria uma instância a partir do formato LatLng do pacote latlong2
  static maps.LatLng fromLatLong2(latlong2.LatLng latLng) {
    return maps.LatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Converte uma lista de pontos do formato latlong2 para o formato do adaptador
  static List<maps.LatLng> convertFromLatLong2List(List<latlong2.LatLng> points) {
    return points.map((point) => fromLatLong2(point)).toList();
  }
  
  /// Converte uma lista de pontos do formato do adaptador para o formato latlong2
  static List<latlong2.LatLng> convertToLatLong2List(List<maps.LatLng> points) {
    return points.map((point) => point.toLatLong2()).toList();
  }
}

/// Enumerador de compatibilidade para os tipos de mapa do Mapbox
enum MapType {
  normal,
  satellite,
  terrain,
  hybrid,
  night,
  outdoors,
}

/// Classe de compatibilidade para estilos de mapa do Mapbox
class MapboxStyles {
  static const String MAPBOX_STREETS = 'streets';
  static const String MAPBOX_OUTDOORS = 'outdoors';
  static const String SATELLITE = 'satellite';
  static const String SATELLITE_STREETS = 'hybrid';
  static const String LIGHT = 'light';
  static const String DARK = 'dark';
}

/// Classe para representar um controlador de mapa compatível
class MapControllerCompat {
  final dynamic _controller;

  MapControllerCompat(this._controller);

  /// Move a câmera para uma nova posição
  void moveCamera(CameraUpdate update) {
    // Implementação específica para o controlador
  }

  /// Anima a câmera para uma nova posição
  void animateCamera(CameraUpdate update) {
    // Implementação específica para o controlador
  }
}

/// Classe de compatibilidade para o controlador do Mapbox
class MapboxMapController {
  final MapControllerCompat _controller;
  MapControllerAdapter? _adapter;
  
  MapboxMapController(this._controller) {
    // Inicializa o adaptador se o controlador for um MapController
    if (_controller._controller is MapController) {
      _adapter = MapControllerAdapter(_controller._controller as MapController);
    }
  }
  
  /// Obtém a posição atual do mapa
  LatLng get center {
    try {
      // Usa o adaptador para acessar o centro do mapa
      if (_adapter != null) {
        final latLng = _adapter!.center;
        return LatLng(latLng.latitude, latLng.longitude);
      }
      // Fallback para um valor padrão
      return LatLng(-15.793889, -47.882778); // Brasília como default
    } catch (e) {
      return LatLng(-15.793889, -47.882778); // Brasília como default
    }
  }
  
  /// Move a câmera para uma nova posição
  void moveCamera(CameraUpdate update) {
    if (_controller._controller is MapController && update is CameraUpdateMove) {
      // Não precisamos da variável flutterMapController, pois já temos _controller
      _controller.moveCamera(update);
    }
  }
  
  /// Anima a câmera para uma nova posição
  void animateCamera(CameraUpdate update) {
    if (_controller._controller is MapController && update is CameraUpdateMove) {
      // Não precisamos da variável flutterMapController, pois já temos _controller
      _controller.animateCamera(update);
    }
  }
  
  /// Método dummy para compatibilidade - não faz nada na implementação MapTiler
  void addLine(Map<String, dynamic> options) {
    // Método vazio para compatibilidade
  }
  
  /// Método dummy para compatibilidade - não faz nada na implementação MapTiler
  void removeLine(String id) {
    // Método vazio para compatibilidade
  }
  
  /// Método dummy para compatibilidade - não faz nada na implementação MapTiler
  void addSymbol(Map<String, dynamic> options) {
    // Método vazio para compatibilidade
  }
  
  /// Método dummy para compatibilidade - não faz nada na implementação MapTiler
  void removeSymbol(String id) {
    // Método vazio para compatibilidade
  }
  
  /// Método dummy para compatibilidade - retorna LatLng(0,0)
  Future<LatLng> requestMyLocationLatLng() async {
    return LatLng(0, 0);
  }
  
  /// Método dummy para compatibilidade - retorna null
  Future<LatLng?> getSymbolLatLng(String id) async {
    return null;
  }
}

/// Classe de compatibilidade para atualizações de câmera do Mapbox
class CameraUpdate {
  /// Cria uma atualização de câmera para uma nova posição e zoom
  static CameraUpdateMove newLatLngZoom(LatLng target, double zoom) {
    return CameraUpdateMove(target, zoom);
  }
}

/// Classe concreta para atualizações de câmera do Mapbox
class CameraUpdateMove extends CameraUpdate {
  final LatLng target;
  final double zoom;
  
  CameraUpdateMove(this.target, this.zoom);
}

/// Classe de compatibilidade para posição de câmera do Mapbox
class CameraPosition {
  final LatLng target;
  final double zoom;
  
  const CameraPosition({required this.target, this.zoom = 15.0});
}

/// Enumerador de compatibilidade para o modo de rastreamento de localização do Mapbox
enum MyLocationTrackingMode {
  None,
  Tracking,
  TrackingCompass,
  TrackingGPS,
}

/// Classe de compatibilidade para a linha do Mapbox
class Line {
  final String id;
  
  Line(this.id);
}

/// Classe de compatibilidade para o símbolo do Mapbox
class Symbol {
  final String id;
  
  Symbol(this.id);
}

/// Classe estática com métodos de utilitário para compatibilidade com o Mapbox
class MapboxCompatibility {
  /// Cria um ID único para uma linha
  static String createLineId() {
    return 'line_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Cria um ID único para um símbolo
  static String createSymbolId() {
    return 'symbol_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Converte uma lista de LatLng do Mapbox para uma lista de LatLng do latlong2
  static List<latlong2.LatLng> convertToLatLong2List(List<LatLng> points) {
    return points.map((point) => point.toLatLong2()).toList();
  }
  
  /// Converte uma lista de LatLng do latlong2 para uma lista de LatLng do Mapbox
  static List<LatLng> convertFromLatLong2List(List<latlong2.LatLng> points) {
    return points.map((point) => LatLngConverter.fromLatLong2(point)).toList();
  }
}

