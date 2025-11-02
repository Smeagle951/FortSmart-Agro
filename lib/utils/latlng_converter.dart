import 'package:latlong2/latlong.dart' as latlong2;
import 'google_maps_compatibility.dart' as google;
import 'mapbox_compatibility_adapter.dart' as mapbox;

/// Utilitário para converter entre diferentes implementações de LatLng
/// utilizadas pelas bibliotecas de mapas (Google Maps, Mapbox e latlong2)
/// 
/// Esta classe fornece métodos de conversão entre diferentes implementações de LatLng
/// para facilitar a interoperabilidade entre as bibliotecas de mapas
class LatLngConverter {
  /// Converte um ponto do Google Maps para Mapbox
  static mapbox.MapboxLatLng googleToMapbox(google.GoogleLatLng point) {
    return mapbox.MapboxLatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do Google Maps para Mapbox
  static List<mapbox.MapboxLatLng> googleListToMapbox(List<google.GoogleLatLng> points) {
    return points.map((point) => googleToMapbox(point)).toList();
  }

  /// Converte um ponto do Mapbox para Google Maps
  static google.GoogleLatLng mapboxToGoogle(mapbox.MapboxLatLng point) {
    return google.GoogleLatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do Mapbox para Google Maps
  static List<google.GoogleLatLng> mapboxListToGoogle(List<mapbox.MapboxLatLng> points) {
    return points.map((point) => mapboxToGoogle(point)).toList();
  }

  /// Converte um ponto do LatLong2 para Mapbox
  static mapbox.MapboxLatLng latlong2ToMapbox(latlong2.LatLng point) {
    return mapbox.MapboxLatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do LatLong2 para Mapbox
  static List<mapbox.MapboxLatLng> latlong2ListToMapbox(List<latlong2.LatLng> points) {
    return points.map((point) => latlong2ToMapbox(point)).toList();
  }

  /// Converte um ponto do Mapbox para LatLong2
  static latlong2.LatLng mapboxToLatlong2(mapbox.MapboxLatLng point) {
    return latlong2.LatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do Mapbox para LatLong2
  static List<latlong2.LatLng> mapboxListToLatlong2(List<mapbox.MapboxLatLng> points) {
    return points.map((point) => mapboxToLatlong2(point)).toList();
  }

  /// Converte um ponto do Google Maps para LatLong2
  static latlong2.LatLng googleToLatlong2(google.GoogleLatLng point) {
    return latlong2.LatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do Google Maps para LatLong2
  static List<latlong2.LatLng> googleListToLatlong2(List<google.GoogleLatLng> points) {
    return points.map((point) => googleToLatlong2(point)).toList();
  }

  /// Converte um ponto do LatLong2 para Google Maps
  static google.GoogleLatLng latlong2ToGoogle(latlong2.LatLng point) {
    return google.GoogleLatLng(point.latitude, point.longitude);
  }

  /// Converte uma lista de pontos do LatLong2 para Google Maps
  static List<google.GoogleLatLng> latlong2ListToGoogle(List<latlong2.LatLng> points) {
    return points.map((point) => latlong2ToGoogle(point)).toList();
  }

  /// Converte uma lista aninhada de pontos do Google Maps para Mapbox
  static List<List<mapbox.MapboxLatLng>> googleNestedListToMapbox(List<List<google.GoogleLatLng>> nestedPoints) {
    return nestedPoints.map((points) => googleListToMapbox(points)).toList();
  }

  /// Converte uma lista aninhada de pontos do Mapbox para Google Maps
  static List<List<google.GoogleLatLng>> mapboxNestedListToGoogle(List<List<mapbox.MapboxLatLng>> nestedPoints) {
    return nestedPoints.map((points) => mapboxListToGoogle(points)).toList();
  }
}
