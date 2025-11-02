import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/talhao_model.dart';
import 'mapbox_compatibility_adapter.dart' as mapbox;

/// Classe de compatibilidade para facilitar a transição do MapTilerMapWidget para o CleanMapWidget
/// Esta classe fornece métodos para converter entre os tipos de coordenadas usados pelo modelo TalhaoModel
/// e os tipos usados pelo CleanMapWidget (latlong2.LatLng)
class CleanMapCompatibility {
  /// Converte uma lista de polígonos do formato MapboxLatLng para o formato LatLng do latlong2
  static List<List<LatLng>> convertPoligonos(List<List<mapbox.MapboxLatLng>> poligonos) {
    return poligonos.map((poligono) => 
      poligono.map((ponto) => LatLng(ponto.latitude, ponto.longitude)).toList()
    ).toList();
  }
  
  /// Converte um único polígono do formato MapboxLatLng para o formato LatLng do latlong2
  static List<LatLng> convertPoligono(List<mapbox.MapboxLatLng> poligono) {
    return poligono.map((ponto) => LatLng(ponto.latitude, ponto.longitude)).toList();
  }
  
  /// Converte uma lista de pontos do formato LatLng do latlong2 para o formato MapboxLatLng
  static List<mapbox.MapboxLatLng> convertToMapboxFormat(List<LatLng> pontos) {
    return pontos.map((ponto) => mapbox.MapboxLatLng(ponto.latitude, ponto.longitude)).toList();
  }
  
  /// Converte uma lista de polígonos do formato LatLng do latlong2 para o formato MapboxLatLng
  static List<List<mapbox.MapboxLatLng>> convertToMapboxFormatPoligonos(List<List<LatLng>> poligonos) {
    return poligonos.map((poligono) => 
      poligono.map((ponto) => mapbox.MapboxLatLng(ponto.latitude, ponto.longitude)).toList()
    ).toList();
  }
  
  /// Calcula a área de um polígono em hectares usando coordenadas do formato LatLng do latlong2
  static double calcularAreaPoligono(List<LatLng> pontos) {
    if (pontos.length < 3) return 0;
    
    // Implementação da fórmula de Shoelace para calcular área em coordenadas geográficas
    const double raioTerra = 6371000; // em metros
    double area = 0;
    
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      
      final p1 = pontos[i];
      final p2 = pontos[j];
      
      final lat1 = p1.latitude * 3.14159265359 / 180;
      final lon1 = p1.longitude * 3.14159265359 / 180;
      final lat2 = p2.latitude * 3.14159265359 / 180;
      final lon2 = p2.longitude * 3.14159265359 / 180;
      
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area * raioTerra * raioTerra / 2;
    area = area.abs();
    
    // Converter de metros quadrados para hectares
    return area / 10000;
  }
}
