import 'package:latlong2/latlong.dart' as latlong2;
import 'map_compatibility.dart';
import 'maptiler_compatibility_adapter.dart';

/// Este arquivo contém classes e definições para manter a compatibilidade
/// entre o código que usa Mapbox e o código que usa MapTiler

/// Reexportando as classes do MapTiler com nomes do Mapbox para compatibilidade
export 'maptiler_compatibility_adapter.dart';

/// Alias para MapTilerLatLng para manter compatibilidade com código existente
class MapboxLatLng extends MapTilerLatLng {
  const MapboxLatLng(super.latitude, super.longitude);
  
  /// Converte para o formato LatLng do pacote latlong2
  @override
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }
  
  /// Converte para o formato LatLng do nosso adaptador de compatibilidade
  @override
  LatLng toCompatLatLng() {
    return LatLng(latitude, longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do pacote latlong2
  static MapboxLatLng fromLatLong2(latlong2.LatLng latLng) {
    return MapboxLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do nosso adaptador de compatibilidade
  static MapboxLatLng fromCompatLatLng(LatLng latLng) {
    return MapboxLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Cria uma instância a partir de MapTilerLatLng
  static MapboxLatLng fromMapTilerLatLng(MapTilerLatLng latLng) {
    return MapboxLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Converte para MapTilerLatLng
  MapTilerLatLng toMapTilerLatLng() {
    return MapTilerLatLng(latitude, longitude);
  }
}

/// Funções de conversão entre tipos Mapbox e MapTiler
class MapboxToMapTilerAdapter {
  /// Converte uma lista de MapboxLatLng para uma lista de MapTilerLatLng
  static List<MapTilerLatLng> convertToMapTilerLatLngList(List<MapboxLatLng> points) {
    return points.map((p) => p.toMapTilerLatLng()).toList();
  }
  
  /// Converte uma lista de MapTilerLatLng para uma lista de MapboxLatLng
  static List<MapboxLatLng> convertToMapboxLatLngList(List<MapTilerLatLng> points) {
    return points.map((p) => MapboxLatLng(p.latitude, p.longitude)).toList();
  }
  
  /// Converte uma lista de listas de MapboxLatLng para uma lista de listas de MapTilerLatLng
  static List<List<MapTilerLatLng>> convertToMapTilerLatLngListList(List<List<MapboxLatLng>> pointsList) {
    return pointsList.map((points) => convertToMapTilerLatLngList(points)).toList();
  }
  
  /// Converte uma lista de listas de MapTilerLatLng para uma lista de listas de MapboxLatLng
  static List<List<MapboxLatLng>> convertToMapboxLatLngListList(List<List<MapTilerLatLng>> pointsList) {
    return pointsList.map((points) => convertToMapboxLatLngList(points)).toList();
  }
}
