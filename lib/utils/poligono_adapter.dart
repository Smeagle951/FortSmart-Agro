import 'package:latlong2/latlong.dart';
import '../models/poligono_model.dart';

/// Classe utilitária para adaptar diferentes representações de polígonos
/// Facilita a conversão entre List<LatLng>, List<List<double>>, e PoligonoModel
class PoligonoAdapter {
  /// Converte uma lista de LatLng para uma lista de PoligonoModel
  /// Útil para código legado que usa 'points' em vez de 'poligonos'
  static List<PoligonoModel> fromLatLngList({
    required List<LatLng> points, 
    required String talhaoId
  }) {
    if (points.isEmpty) return [];
    
    // Criar um único polígono com todos os pontos
    final poligono = PoligonoModel.criar(
      pontos: points,
      talhaoId: talhaoId,
    );
    
    return [poligono];
  }

  /// Converte uma lista de PoligonoModel para uma lista de LatLng (pontos)
  /// Útil para código legado que espera 'points' em vez de 'poligonos'
  static List<LatLng> toLatLngList(List<PoligonoModel>? poligonos) {
    if (poligonos == null || poligonos.isEmpty) return [];
    
    // Pegar apenas o primeiro polígono para compatibilidade
    // com código legado que só suporta um polígono por talhão
    return poligonos.first.pontos;
  }

  /// Converte uma lista de listas de coordenadas para uma lista de PoligonoModel
  /// Formato de entrada: [[lat1, lng1], [lat2, lng2], ...]
  static List<PoligonoModel> fromCoordinatesList({
    required List<List<dynamic>> coordinates, 
    required String talhaoId
  }) {
    if (coordinates.isEmpty) return [];
    
    final List<LatLng> points = coordinates.map((coord) {
      if (coord.length >= 2) {
        final lat = coord[0] is num ? (coord[0] as num).toDouble() : 0.0;
        final lng = coord[1] is num ? (coord[1] as num).toDouble() : 0.0;
        return LatLng(lat, lng);
      }
      return LatLng(0, 0);
    }).toList();
    
    return fromLatLngList(points: points, talhaoId: talhaoId);
  }

  /// Converte uma lista de PoligonoModel para uma lista de listas de coordenadas
  /// Formato de saída: [[lat1, lng1], [lat2, lng2], ...]
  static List<List<double>> toCoordinatesList(List<PoligonoModel>? poligonos) {
    if (poligonos == null || poligonos.isEmpty) return [];
    
    // Pegar apenas o primeiro polígono para compatibilidade
    final pontos = poligonos.first.pontos;
    
    return pontos.map((point) => [point.latitude, point.longitude]).toList();
  }

  /// Verifica se uma lista de polígonos é válida
  static bool isValid(List<PoligonoModel>? poligonos) {
    if (poligonos == null || poligonos.isEmpty) return false;
    
    // Verificar se pelo menos um polígono tem pontos suficientes
    return poligonos.any((poligono) => poligono.pontos.length >= 3);
  }
}
