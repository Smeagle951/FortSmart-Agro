import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'google_maps_types.dart';

/// Chave de API do MapTiler - Substitua pela sua chave real
const String mapTilerApiKey = 'KQAa9lY3N0TR17zxhk9u';

/// URLs dos estilos de mapa do MapTiler
class MapTilerStyle {
  static const String streets = 'https://api.maptiler.com/maps/streets/style.json?key=$mapTilerApiKey';
  static const String satellite = 'https://api.maptiler.com/maps/satellite/style.json?key=$mapTilerApiKey';
  static const String hybrid = 'https://api.maptiler.com/maps/hybrid/style.json?key=$mapTilerApiKey';
  static const String basic = 'https://api.maptiler.com/maps/basic/style.json?key=$mapTilerApiKey';
  static const String outdoor = 'https://api.maptiler.com/maps/outdoor/style.json?key=$mapTilerApiKey';
}

/// URLs dos tiles do MapTiler
class MapTilerTileUrl {
  static const String streets = 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$mapTilerApiKey';
  static const String satellite = 'https://api.maptiler.com/maps/satellite/{z}/{x}/{y}.jpg?key=$mapTilerApiKey';
  static const String hybrid = 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$mapTilerApiKey';
  static const String basic = 'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=$mapTilerApiKey';
  static const String outdoor = 'https://api.maptiler.com/maps/outdoor/{z}/{x}/{y}.png?key=$mapTilerApiKey';
}

/// Configurações padrão para o mapa
class MapTilerConfig {
  /// Zoom inicial padrão
  static const double defaultZoom = 15.0;
  
  /// Posição inicial padrão (Brasil)
  static final latlong2.LatLng defaultPosition = latlong2.LatLng(-15.7801, -47.9292);
  
  /// Limites de zoom
  static const double minZoom = 2.0;
  static const double maxZoom = 19.0;
  
  /// Opções de mapa padrão
  static flutter_map.MapOptions defaultMapOptions() {
    return flutter_map.MapOptions(
      initialCenter: defaultPosition,
      initialZoom: defaultZoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }
  
  /// Retorna a URL do estilo de mapa com base no tipo de mapa
  static String getMapStyleUrl(MapType mapType) {
    if (mapType == MapType.satellite) {
      return MapTilerTileUrl.satellite;
    } else if (mapType == MapType.hybrid) {
      return MapTilerTileUrl.hybrid;
    } else if (mapType == MapType.terrain) {
      return MapTilerTileUrl.outdoor;
    } else if (mapType == MapType.none) {
      return '';
    } else {
      // MapType.normal e default
      return MapTilerTileUrl.streets;
    }
  }
  
  /// Camada de tiles padrão (estilo streets)
  static flutter_map.TileLayer defaultTileLayer() {
    return flutter_map.TileLayer(
      urlTemplate: MapTilerTileUrl.streets,
      subdomains: ['a', 'b', 'c'],
      userAgentPackageName: 'com.fortsmart.agro',
    );
  }
  
  /// Camada de tiles de satélite
  static flutter_map.TileLayer satelliteTileLayer() {
    return flutter_map.TileLayer(
      urlTemplate: MapTilerTileUrl.satellite,
      subdomains: ['a', 'b', 'c'],
    );
  }
  
  /// Camada de tiles híbrida (satélite + estradas)
  static flutter_map.TileLayer hybridTileLayer() {
    return flutter_map.TileLayer(
      urlTemplate: MapTilerTileUrl.hybrid,
      subdomains: ['a', 'b', 'c'],
      userAgentPackageName: 'com.fortsmart.agro',
    );
  }
}

/// Extensão para trabalhar com limites (bounds) no mapa
extension LatLngBoundsExtension on List<latlong2.LatLng> {
  /// Calcula os limites (bounds) que contêm todas as coordenadas
  flutter_map.LatLngBounds calculateBounds() {
    if (isEmpty) {
      // Criar um bounds com pontos padrão
      final southwest = latlong2.LatLng(-10, -10);
      final northeast = latlong2.LatLng(10, 10);
      return flutter_map.LatLngBounds(southwest, northeast);
    }
    
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;
    
    for (final coord in this) {
      minLat = minLat < coord.latitude ? minLat : coord.latitude;
      maxLat = maxLat > coord.latitude ? maxLat : coord.latitude;
      minLng = minLng < coord.longitude ? minLng : coord.longitude;
      maxLng = maxLng > coord.longitude ? maxLng : coord.longitude;
    }
    
    // Adicionar um pequeno padding
    final southwest = latlong2.LatLng(minLat - 0.01, minLng - 0.01);
    final northeast = latlong2.LatLng(maxLat + 0.01, maxLng + 0.01);
    
    return flutter_map.LatLngBounds(southwest, northeast);
  }
}

/// Extensão para calcular a área de um polígono
extension PolygonAreaExtension on List<latlong2.LatLng> {
  /// Calcula a área de um polígono em metros quadrados
  double calculateArea() {
    if (length < 3) return 0;
    
    double area = 0;
    final earthRadius = 6378137.0; // Raio da Terra em metros
    
    for (int i = 0; i < length; i++) {
      int j = (i + 1) % length;
      
      area += (this[j].longitude - this[i].longitude) * 
              (this[i].latitude + this[j].latitude);
    }
    
    area = area * earthRadius * earthRadius / 2.0;
    return area.abs();
  }
  
  /// Calcula a área de um polígono em hectares
  double calculateAreaInHectares() {
    return calculateArea() / 10000;
  }
}

/// Extensão para converter entre tipos de coordenadas
extension LatLngConversionExtension on latlong2.LatLng {
  /// Converte para um Map
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  /// Cria a partir de um Map
  static latlong2.LatLng fromMap(Map<String, dynamic> map) {
    return latlong2.LatLng(
      map['latitude'] as double,
      map['longitude'] as double,
    );
  }
}
