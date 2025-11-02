import 'package:latlong2/latlong.dart' as latlong2;
import 'map_compatibility.dart';

/// Este arquivo contém classes e definições para manter a compatibilidade
/// com o código existente que usa Mapbox GL, facilitando a migração para o MapTiler

/// Classe de compatibilidade para a classe LatLng do MapTiler
class MapTilerLatLng {
  final double latitude;
  final double longitude;
  
  const MapTilerLatLng(this.latitude, this.longitude);
  
  /// Converte para o formato LatLng do pacote latlong2
  latlong2.LatLng toLatLong2() {
    return latlong2.LatLng(latitude, longitude);
  }
  
  /// Converte para o formato LatLng do nosso adaptador de compatibilidade
  LatLng toCompatLatLng() {
    return LatLng(latitude, longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do pacote latlong2
  static MapTilerLatLng fromLatLong2(latlong2.LatLng latLng) {
    return MapTilerLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Cria uma instância a partir do formato LatLng do nosso adaptador de compatibilidade
  static MapTilerLatLng fromCompatLatLng(LatLng latLng) {
    return MapTilerLatLng(latLng.latitude, latLng.longitude);
  }
  
  @override
  String toString() => 'MapTilerLatLng(latitude: $latitude, longitude: $longitude)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapTilerLatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }
  
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Classe estática com métodos de utilitário para compatibilidade com o MapTiler
class MapTilerCompatibilityAdapter {
  /// Cria um ID único para uma linha
  static String createLineId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Cria um ID único para um símbolo
  static String createSymbolId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Converte uma lista de MapTilerLatLng para uma lista de LatLng do latlong2
  static List<latlong2.LatLng> convertToLatLong2List(List<MapTilerLatLng> points) {
    return points.map((p) => p.toLatLong2()).toList();
  }
  
  /// Converte uma lista de LatLng do latlong2 para uma lista de MapTilerLatLng
  static List<MapTilerLatLng> convertFromLatLong2List(List<latlong2.LatLng> points) {
    return points.map((p) => MapTilerLatLng.fromLatLong2(p)).toList();
  }
  
  /// Converte uma lista de MapTilerLatLng para uma lista de LatLng do nosso adaptador de compatibilidade
  static List<LatLng> convertToCompatLatLngList(List<MapTilerLatLng> points) {
    return points.map((p) => p.toCompatLatLng()).toList();
  }
  
  /// Converte uma lista de LatLng do nosso adaptador de compatibilidade para uma lista de MapTilerLatLng
  static List<MapTilerLatLng> convertFromCompatLatLngList(List<LatLng> points) {
    return points.map((p) => MapTilerLatLng.fromCompatLatLng(p)).toList();
  }
  
  /// Calcula a área de um polígono em hectares
  static double calcularAreaPoligono(List<MapTilerLatLng> pontos) {
    if (pontos.length < 3) return 0;
    
    // Implementação da fórmula de Gauss (Shoelace formula)
    double area = 0;
    final int n = pontos.length;
    
    for (int i = 0; i < n; i++) {
      final MapTilerLatLng p1 = pontos[i];
      final MapTilerLatLng p2 = pontos[(i + 1) % n];
      
      area += (p2.longitude + p1.longitude) * (p2.latitude - p1.latitude);
    }
    
    area = area.abs() * 0.5;
    // Converter para hectares (aproximadamente)
    return area * 111.32 * 111.32 * 0.01;
  }
}
