import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../utils/map_constants.dart';

/// Serviço para gerenciar funcionalidades relacionadas ao MapTiler
class MapsService {
  static final MapsService _instance = MapsService._internal();
  
  factory MapsService() {
    return _instance;
  }
  
  MapsService._internal();
  
  /// Retorna a chave da API do MapTiler
  String get apiKey => MapConstants.mapTilerApiKey;
  
  /// Cria um polígono padrão para flutter_map
  Polygon createDefaultPolygon({
    required String id,
    required List<LatLng> points,
    bool isSelected = false,
  }) {
    return Polygon(
      points: points,
      color: isSelected 
          ? Color(MapConstants.selectedPolygonColor)
          : Color(MapConstants.defaultPolygonColor),
      borderColor: isSelected
          ? Color(MapConstants.selectedPolygonStrokeColor)
          : Color(MapConstants.defaultPolygonStrokeColor),
      borderStrokeWidth: isSelected
          ? MapConstants.selectedPolygonStrokeWidth
          : MapConstants.defaultPolygonStrokeWidth,
      isFilled: true,
    );
  }
  
  /// Converte uma lista de coordenadas para uma lista de LatLng
  List<LatLng> convertCoordinatesToLatLng(List<Map<String, dynamic>> coordinates) {
    return coordinates.map((coord) {
      return LatLng(
        coord['latitude'] as double,
        coord['longitude'] as double,
      );
    }).toList();
  }
  
  /// Converte uma lista de LatLng para uma lista de coordenadas
  List<Map<String, dynamic>> convertLatLngToCoordinates(List<LatLng> points) {
    return points.map((point) {
      return {
        'latitude': point.latitude,
        'longitude': point.longitude,
      };
    }).toList();
  }
  
  /// Cria um ícone personalizado para marcador
  Widget createCustomMarkerIcon({
    required IconData icon,
    required Color color,
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
  
  /// Calcula o centro de um conjunto de pontos
  LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(-15.7801, -47.9292); // Brasília como padrão
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }
    
    return LatLng(sumLat / points.length, sumLng / points.length);
  }
  
  /// Calcula a área de um polígono em metros quadrados
  double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) {
      return 0;
    }
    
    double area = 0;
    
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = area.abs() * 0.5;
    // Conversão aproximada para metros quadrados usando um fator de escala
    // Este é um cálculo aproximado, para cálculos mais precisos seria necessário
    // usar uma biblioteca de cálculos geoespaciais
    const double EARTH_RADIUS = 6378137.0; // em metros
    area = area * (Math.pi / 180) * EARTH_RADIUS * EARTH_RADIUS;
    
    return area;
  }
  
  /// Converte área em metros quadrados para hectares
  double squareMetersToHectares(double areaInSquareMeters) {
    return areaInSquareMeters / 10000;
  }
}

/// Classe auxiliar para cálculos matemáticos
class Math {
  static const double pi = 3.1415926535897932;
}
