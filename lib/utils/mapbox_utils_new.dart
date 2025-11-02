import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

/// Classe utilitária para operações com mapas e coordenadas geográficas
class MapboxUtils {
  /// Calcula o centro de uma lista de coordenadas
  static LatLng calculateCenter(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      return LatLng(0, 0);
    }
    
    double sumLat = 0;
    double sumLng = 0;
    
    for (final coord in coordinates) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }
    
    return LatLng(
      sumLat / coordinates.length,
      sumLng / coordinates.length,
    );
  }
  
  /// Verifica se um ponto está dentro de um polígono usando ray-casting
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) {
      return false;
    }
    
    bool isInside = false;
    
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * 
           (point.latitude - polygon[i].latitude) / 
           (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    
    return isInside;
  }
  
  /// Calcula os limites (bounds) que contêm todas as coordenadas
  static LatLngBounds calculateBounds(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      return LatLngBounds(
        LatLng(-15.793889, -47.882778), // Brasília como default
        LatLng(-15.793889, -47.882778)
      );
    }
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final coord in coordinates) {
      minLat = min(minLat, coord.latitude);
      maxLat = max(maxLat, coord.latitude);
      minLng = min(minLng, coord.longitude);
      maxLng = max(maxLng, coord.longitude);
    }
    
    // Adicionar um pequeno padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    
    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }
  
  /// Calcula a área de um polígono em metros quadrados
  static double calculatePolygonArea(List<LatLng> coordinates) {
    if (coordinates.length < 3) return 0;
    
    double area = 0;
    final numPoints = coordinates.length;
    
    for (int i = 0; i < numPoints; i++) {
      int j = (i + 1) % numPoints;
      area += coordinates[i].longitude * coordinates[j].latitude;
      area -= coordinates[j].longitude * coordinates[i].latitude;
    }
    
    // Fator de conversão para metros quadrados usando o raio da Terra em metros (6371000)
    // A fórmula utiliza a projeção equiretangular, que é adequada para áreas pequenas
    final radius = 6371000; // Raio médio da Terra em metros
    area = (area.abs() * 0.5) * (radius * radius) * (pi/180) * (pi/180) * cos(coordinates[0].latitude * pi/180);
    return area;
  }
  
  /// Calcula a área de um polígono em hectares
  static double calculateAreaInHectares(List<LatLng> coordinates) {
    if (coordinates.length < 3) return 0;
    
    // Converter metros quadrados para hectares (1 hectare = 10000m²)
    return calculatePolygonArea(coordinates) / 10000;
  }
  
  /// Converte coordenadas do formato JSON para Mapbox (latlong2.LatLng)
  static List<LatLng> parseCoordinatesFromJson(String coordinatesJson) {
    if (coordinatesJson.isEmpty) return [];
    
    try {
      // Decodificar JSON de coordenadas
      final List<dynamic> coordsList = json.decode(coordinatesJson);
      
      // Mapear para LatLng do Mapbox
      return coordsList.map((coord) {
        // Verificar o formato do JSON (pode ser um objeto com lat/lng ou um array)
        if (coord is Map) {
          return LatLng(
            double.parse(coord['lat'].toString()),
            double.parse(coord['lng'].toString()),
          );
        } else if (coord is List && coord.length == 2) {
          return LatLng(
            double.parse(coord[0].toString()),
            double.parse(coord[1].toString()),
          );
        }
        return LatLng(0, 0);
      }).toList();
    } catch (e) {
      debugPrint('Erro ao converter coordenadas JSON: $e');
      return [];
    }
  }
  
  /// Converte coordenadas do modelo Plot para LatLng do Mapbox
  static List<LatLng> parseCoordinatesFromPlot(List<Map<String, double>>? plotCoordinates) {
    if (plotCoordinates == null || plotCoordinates.isEmpty) return [];
    
    try {
      return plotCoordinates.map((coord) => LatLng(
        coord['latitude'] ?? 0.0,
        coord['longitude'] ?? 0.0
      )).toList();
    } catch (e) {
      debugPrint('Erro ao converter coordenadas do Plot para Mapbox: $e');
      return [];
    }
  }
  
  /// Serializa uma lista de coordenadas em uma string no formato 'lat1,lng1;lat2,lng2;...'
  static String serializeCoordinates(List<LatLng> coordinates) {
    return coordinates.map((coord) => '${coord.latitude},${coord.longitude}').join(';');
  }
  
  /// Parseia coordenadas de um formato GeoJSON
  static List<LatLng> parseGeoJsonCoordinates(String polygonData) {
    List<LatLng> coordinates = [];
    
    try {
      // Lógica simplificada para processamento de GeoJSON
      // Implementação completa depende do formato exato do GeoJSON
      final cleanData = polygonData.replaceAll('[', '').replaceAll(']', '');
      final pairs = cleanData.split(',');
      
      for (int i = 0; i < pairs.length; i += 2) {
        if (i + 1 < pairs.length) {
          final lng = double.tryParse(pairs[i].trim()) ?? 0.0;
          final lat = double.tryParse(pairs[i + 1].trim()) ?? 0.0;
          coordinates.add(LatLng(lat, lng));
        }
      }
    } catch (e) {
      print('Erro ao processar coordenadas GeoJSON: $e');
    }
    
    return coordinates;
  }
}

