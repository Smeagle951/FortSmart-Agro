import 'package:latlong2/latlong.dart' as latlong2;

// Importamos nossas classes de compatibilidade em vez dos pacotes originais
import 'google_maps_compatibility.dart' as google_compat;
import 'mapbox_compatibility_adapter.dart' as mapbox_compat;

/// Classe utilitária para converter entre diferentes formatos de coordenadas
/// Facilita a migração de Google Maps e Mapbox para MapTiler
class LatLngAdapter {
  /// Converte de coordenadas numéricas para latlong2.LatLng
  static latlong2.LatLng fromCoordinates(double latitude, double longitude) {
    return latlong2.LatLng(latitude, longitude);
  }

  /// Converte de Map/JSON para latlong2.LatLng
  static latlong2.LatLng fromMap(Map<String, dynamic> map) {
    return latlong2.LatLng(
      map['latitude'] ?? map['lat'] ?? 0.0,
      map['longitude'] ?? map['lng'] ?? map['lon'] ?? 0.0,
    );
  }

  /// Converte latlong2.LatLng para Map/JSON
  static Map<String, double> toMap(latlong2.LatLng latLng) {
    return {
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
    };
  }

  /// Converte qualquer tipo de coordenada para latlong2.LatLng
  static latlong2.LatLng toLatLong2(dynamic coord) {
    if (coord is latlong2.LatLng) {
      return coord;
    } else if (coord is mapbox_compat.MapboxLatLng) {
      return fromMapboxLatLng(coord);
    } else if (coord is google_compat.GoogleLatLng) {
      return fromGoogleLatLng(coord);
    } else if (coord is Map<String, dynamic>) {
      return fromMap(coord);
    } else {
      // Retorna um valor padrão se não conseguir converter
      return latlong2.LatLng(0, 0);
    }
  }

  /// Converte uma lista de Maps para uma lista de latlong2.LatLng
  static List<latlong2.LatLng> fromMapList(List<Map<String, dynamic>> mapList) {
    return mapList.map((map) => fromMap(map)).toList();
  }

  /// Converte uma lista de latlong2.LatLng para uma lista de Maps
  static List<Map<String, double>> toMapList(List<latlong2.LatLng> latLngList) {
    return latLngList.map((latLng) => toMap(latLng)).toList();
  }
  
  /// Converte de qualquer outro formato de LatLng para o formato do latlong2
  static latlong2.LatLng fromGenericLatLng(dynamic latLng) {
    if (latLng is latlong2.LatLng) {
      return latLng;
    }
    
    try {
      // Tenta extrair latitude e longitude de um objeto genérico
      final double lat = latLng.latitude ?? 0.0;
      final double lng = latLng.longitude ?? latLng.lng ?? 0.0;
      return latlong2.LatLng(lat, lng);
    } catch (e) {
      // Se falhar, retorna coordenadas padrão (0,0)
      return latlong2.LatLng(0, 0);
    }
  }
  
  /// Converte uma lista de coordenadas genéricas para LatLng do latlong2
  static List<latlong2.LatLng> fromGenericLatLngList(List<dynamic> latLngList) {
    return latLngList.map((latLng) => fromGenericLatLng(latLng)).toList();
  }
  
  /// Converte de Mapbox LatLng para latlong2 LatLng
  static latlong2.LatLng fromMapboxLatLng(dynamic mapboxLatLng) {
    try {
      if (mapboxLatLng is mapbox_compat.MapboxLatLng) {
        return latlong2.LatLng(mapboxLatLng.latitude, mapboxLatLng.longitude);
      } else {
        return latlong2.LatLng(
          mapboxLatLng.latitude,
          mapboxLatLng.longitude,
        );
      }
    } catch (e) {
      return latlong2.LatLng(0, 0);
    }
  }
  
  /// Converte de Google Maps LatLng para latlong2 LatLng
  static latlong2.LatLng fromGoogleLatLng(dynamic googleLatLng) {
    try {
      if (googleLatLng is google_compat.GoogleLatLng) {
        return latlong2.LatLng(googleLatLng.latitude, googleLatLng.longitude);
      } else {
        return latlong2.LatLng(
          googleLatLng.latitude,
          googleLatLng.longitude,
        );
      }
    } catch (e) {
      return latlong2.LatLng(0, 0);
    }
  }
  
  /// Converte uma lista de Mapbox LatLng para latlong2 LatLng
  static List<latlong2.LatLng> fromMapboxLatLngList(List<dynamic> mapboxLatLngList) {
    return mapboxLatLngList.map((latLng) => fromMapboxLatLng(latLng)).toList();
  }
  
  /// Converte uma lista de Google Maps LatLng para latlong2 LatLng
  static List<latlong2.LatLng> fromGoogleLatLngList(List<dynamic> googleLatLngList) {
    return googleLatLngList.map((latLng) => fromGoogleLatLng(latLng)).toList();
  }

  /// Converte uma lista de coordenadas genéricas para uma lista de LatLng do latlong2
  static List<latlong2.LatLng> fromGenericList(List<dynamic> latLngList) {
    return latLngList.map((latLng) => fromGenericLatLng(latLng)).toList();
  }
  
  /// Converte uma lista de LatLng do latlong2 para uma lista de LatLng do Mapbox
  static List<mapbox_compat.MapboxLatLng> fromLatLong2List(List<latlong2.LatLng> latLngList) {
    return latLngList.map((latLng) => toMapboxLatLng(latLng)).toList();
  }
  
  /// Calcula a distância entre dois pontos em metros
  static double calculateDistance(latlong2.LatLng point1, latlong2.LatLng point2) {
    final latlong2.Distance distance = latlong2.Distance();
    return distance.as(latlong2.LengthUnit.Meter, point1, point2);
  }
  
  /// Calcula a área de um polígono em metros quadrados
  static double calculateArea(List<latlong2.LatLng> points) {
    if (points.length < 3) return 0;
    
    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    
    area = area.abs() * 0.5;
    
    // Conversão aproximada para metros quadrados
    const double metersPerDegreeAtEquator = 111319.9;
    return area * metersPerDegreeAtEquator * metersPerDegreeAtEquator;
  }
  
  /// Converte de latlong2 LatLng para MapboxLatLng
  static mapbox_compat.MapboxLatLng toMapboxLatLng(latlong2.LatLng latLng) {
    return mapbox_compat.MapboxLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Converte de latlong2 LatLng para GoogleLatLng
  static google_compat.GoogleLatLng toGoogleLatLng(latlong2.LatLng latLng) {
    return google_compat.GoogleLatLng(latLng.latitude, latLng.longitude);
  }
  
  /// Converte uma lista de latlong2 LatLng para MapboxLatLng
  static List<mapbox_compat.MapboxLatLng> toMapboxLatLngList(List<latlong2.LatLng> latLngList) {
    return latLngList.map((latLng) => toMapboxLatLng(latLng)).toList();
  }
  
  /// Converte uma lista de latlong2 LatLng para GoogleLatLng
  static List<google_compat.GoogleLatLng> toGoogleLatLngList(List<latlong2.LatLng> latLngList) {
    return latLngList.map((latLng) => toGoogleLatLng(latLng)).toList();
  }
}
