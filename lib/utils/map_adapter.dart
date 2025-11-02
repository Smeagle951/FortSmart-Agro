import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;

/// Classe adaptadora para facilitar a migração do Mapbox GL para o flutter_map
/// Permite usar a nova implementação do flutter_map mantendo compatibilidade
/// com o código existente que usa Mapbox GL
class MapAdapter {
  /// Converte LatLng do Mapbox para LatLng do flutter_map (latlong2)
  static latlong2.LatLng fromMapboxLatLng(dynamic mapboxLatLng) {
    // Se já for do tipo correto, retorna diretamente
    if (mapboxLatLng is latlong2.LatLng) {
      return mapboxLatLng;
    }
    
    // Extrai latitude e longitude do objeto Mapbox
    double lat = 0.0;
    double lng = 0.0;
    
    if (mapboxLatLng != null) {
      // Tenta acessar as propriedades latitude e longitude
      try {
        lat = mapboxLatLng.latitude ?? 0.0;
        lng = mapboxLatLng.longitude ?? 0.0;
      } catch (e) {
        // Se falhar, tenta acessar como um Map
        try {
          if (mapboxLatLng is Map) {
            lat = (mapboxLatLng['latitude'] ?? 0.0).toDouble();
            lng = (mapboxLatLng['longitude'] ?? 0.0).toDouble();
          }
        } catch (e) {
          print('Erro ao converter coordenadas: $e');
        }
      }
    }
    
    return latlong2.LatLng(lat, lng);
  }

  /// Converte LatLng do Google Maps para LatLng do flutter_map
  static latlong2.LatLng fromGoogleMapsLatLng(google_maps.LatLng googleLatLng) {
    return latlong2.LatLng(googleLatLng.latitude, googleLatLng.longitude);
  }

  /// Converte LatLng do flutter_map para LatLng do Google Maps
  static google_maps.LatLng toGoogleMapsLatLng(latlong2.LatLng latLng) {
    return google_maps.LatLng(latLng.latitude, latLng.longitude);
  }

  /// Converte uma lista de coordenadas do Mapbox para o formato do flutter_map
  static List<latlong2.LatLng> convertCoordinatesList(List<dynamic> coordinates) {
    return coordinates.map((coord) => fromMapboxLatLng(coord)).toList();
  }

  /// Cria um polígono do flutter_map a partir de coordenadas
  static Polygon createPolygon(List<latlong2.LatLng> points, {
    Color color = Colors.blue,
    Color borderColor = Colors.black,
    double borderStrokeWidth = 2.0,
    bool isDotted = false,
  }) {
    return Polygon(
      points: points,
      color: color.withOpacity(0.3),
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      isFilled: true,
    );
  }

  /// Cria um marcador do flutter_map
  static Marker createMarker(latlong2.LatLng point, {
    Widget? child,
    double width = 30.0,
    double height = 30.0,
    Alignment alignment = Alignment.center,
  }) {
    return Marker(
      point: point,
      width: width,
      height: height,
      // alignment: alignment, // alignment não é suportado em Marker no flutter_map 5.0.0
      builder: (context) => child ?? const Icon(Icons.location_on, color: Colors.red, size: 30),
    );
  }

  /// Cria uma URL para tiles do Mapbox
  static String createMapboxTileUrl(String mapboxToken, String style) {
    // Estilos comuns: streets-v11, outdoors-v11, light-v10, dark-v10, satellite-v9
    return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/{z}/{x}/{y}?access_token=$mapboxToken';
  }
  
  /// Cria uma URL para tiles do MapLibre (OpenStreetMap)
  static String createMapLibreTileUrl() {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }
}
