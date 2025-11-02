import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/api_config.dart';
import '../utils/logger.dart';

/// Serviço centralizado para interações com MapTiler API
class MapTilerService {
  static final MapTilerService _instance = MapTilerService._internal();
  factory MapTilerService() => _instance;
  MapTilerService._internal();

  /// Obtém URL do mapa por tipo
  String getMapUrl(String mapType) {
    return APIConfig.getMapTilerUrl(mapType);
  }

  /// Obtém URL de fallback
  String getFallbackUrl() {
    return APIConfig.getFallbackUrl();
  }

  /// Obtém tipos de mapa disponíveis
  List<String> getAvailableMapTypes() {
    return APIConfig.getAvailableMapTypes();
  }

  /// Verifica status da API MapTiler
  Future<bool> checkApiStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.maptiler.com/maps/satellite-v2/256/0/0/0.jpg?key=${APIConfig.mapTilerAPIKey}'),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      Logger.error('❌ Erro ao verificar status da API MapTiler: $e');
      return false;
    }
  }

  /// Geocoding - Converte endereço em coordenadas
  Future<LatLng?> geocode(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = APIConfig.mapTilerGeocodingUrl.replaceAll('{query}', encodedAddress);
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final coordinates = feature['geometry']['coordinates'];
          // MapTiler retorna [longitude, latitude]
          return LatLng(coordinates[1].toDouble(), coordinates[0].toDouble());
        }
      }
      
      Logger.warning('⚠️ Nenhum resultado encontrado para: $address');
      return null;
    } catch (e) {
      Logger.error('❌ Erro no geocoding: $e');
      return null;
    }
  }

  /// Reverse Geocoding - Converte coordenadas em endereço
  Future<String?> reverseGeocode(LatLng coordinates) async {
    try {
      final url = 'https://api.maptiler.com/geocoding/${coordinates.longitude},${coordinates.latitude}.json?key=${APIConfig.mapTilerAPIKey}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          return feature['place_name'] ?? 'Localização desconhecida';
        }
      }
      
      return 'Localização desconhecida';
    } catch (e) {
      Logger.error('❌ Erro no reverse geocoding: $e');
      return 'Localização desconhecida';
    }
  }

  /// Obtém direções entre dois pontos
  Future<List<LatLng>?> getDirections(LatLng origin, LatLng destination, {String profile = 'driving'}) async {
    try {
      final url = '${APIConfig.mapTilerDirectionsUrl}&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&profile=$profile';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          // Decodificar geometria (pode ser encoded polyline ou GeoJSON)
          if (geometry['type'] == 'LineString' && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            return coordinates.map((coord) {
              // MapTiler retorna [longitude, latitude]
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
          }
        }
      }
      
      Logger.warning('⚠️ Nenhuma rota encontrada');
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter direções: $e');
      return null;
    }
  }

  /// Obtém elevação de coordenadas
  Future<double?> getElevation(LatLng coordinates) async {
    try {
      final url = APIConfig.mapTilerElevationUrl.replaceAll('{coordinates}', '${coordinates.longitude},${coordinates.latitude}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0]['elevation']?.toDouble();
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter elevação: $e');
      return null;
    }
  }

  /// Obtém informações do tile
  Future<Map<String, dynamic>?> getTileInfo(int z, int x, int y, String mapType) async {
    try {
      final url = getMapUrl(mapType).replaceAll('{z}', z.toString()).replaceAll('{x}', x.toString()).replaceAll('{y}', y.toString());
      
      final response = await http.head(
        Uri.parse(url),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      return {
        'available': response.statusCode == 200,
        'statusCode': response.statusCode,
        'contentType': response.headers['content-type'],
        'url': url,
      };
    } catch (e) {
      Logger.error('❌ Erro ao obter informações do tile: $e');
      return null;
    }
  }

  /// Valida chave API
  bool validateApiKey() {
    return APIConfig.isMapTilerConfigured();
  }

  /// Obtém estatísticas de uso (se disponível)
  Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final url = 'https://api.maptiler.com/usage?key=${APIConfig.mapTilerAPIKey}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FortSmartAgro/1.0'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas de uso: $e');
      return null;
    }
  }
}
