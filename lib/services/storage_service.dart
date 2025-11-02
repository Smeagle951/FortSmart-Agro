import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../database/daos/polygon_dao.dart';
import '../database/models/polygon_model.dart';
import 'polygon_service.dart';

class StorageService {
  final PolygonDao _polygonDao;

  StorageService(this._polygonDao);
  
  /// Getter público para o PolygonDao
  PolygonDao get polygonDao => _polygonDao;

  /// Salva um polígono no banco de dados
  Future<int> savePolygon({
    required String name,
    required String method,
    required List<LatLng> points,
    required double areaHa,
    required double perimeterM,
    double distanceM = 0.0,
    String? fazendaId,
    String? culturaId,
    String? safraId,
  }) async {
    try {
      // Converter pontos para GeoJSON
      final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
      final geojson = {
        "type": "Polygon",
        "coordinates": [coordinates]
      };

      // Criar polígono
      final polygon = PolygonModel(
        name: name,
        method: method,
        coordinates: jsonEncode(geojson),
        areaHa: areaHa,
        perimeterM: perimeterM,
        distanceM: distanceM,
        createdAt: DateTime.now().toIso8601String(),
        fazendaId: fazendaId,
        culturaId: culturaId,
        safraId: safraId,
      );

      final polygonId = await _polygonDao.insertPolygon(polygon);
      print('✅ Polígono salvo com ID: $polygonId');
      return polygonId;

    } catch (e) {
      print('❌ Erro ao salvar polígono: $e');
      rethrow;
    }
  }

  /// Salva trilhas de um polígono
  Future<void> saveTracks(int polygonId, List<Map<String, dynamic>> tracks) async {
    try {
      for (final track in tracks) {
        final trackData = TrackModel(
          polygonId: polygonId,
          lat: track['lat'] as double,
          lon: track['lon'] as double,
          accuracy: track['accuracy'] as double?,
          speed: track['speed'] as double?,
          bearing: track['bearing'] as double?,
          ts: track['ts'] as String,
          status: track['status'] as String?,
        );

        await _polygonDao.insertTrack(trackData);
      }
      print('✅ Trilhas salvas para polígono: $polygonId');

    } catch (e) {
      print('❌ Erro ao salvar trilhas: $e');
      rethrow;
    }
  }

  /// Carrega todos os polígonos
  Future<List<Map<String, dynamic>>> loadAllPolygons() async {
    try {
      final polygons = await _polygonDao.getPolygonsWithStats();
      return polygons.map((polygon) {
        // Converter GeoJSON de volta para pontos
        final geojson = jsonDecode(polygon['coordinates'] as String);
        final coordinates = geojson['coordinates'][0] as List;
        final points = coordinates.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();

        return {
          ...polygon,
          'points': points,
        };
      }).toList();

    } catch (e) {
      print('❌ Erro ao carregar polígonos: $e');
      return [];
    }
  }

  /// Carrega polígonos por fazenda
  Future<List<Map<String, dynamic>>> loadPolygonsByFazenda(String fazendaId) async {
    try {
      final polygons = await _polygonDao.getPolygonsByFazenda(fazendaId);
      return polygons.map((polygon) {
        final geojson = jsonDecode(polygon.coordinates);
        final coordinates = geojson['coordinates'][0] as List;
        final points = coordinates.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();

        return {
          'id': polygon.id,
          'name': polygon.name,
          'method': polygon.method,
          'areaHa': polygon.areaHa,
          'perimeterM': polygon.perimeterM,
          'distanceM': polygon.distanceM,
          'createdAt': polygon.createdAt,
          'fazendaId': polygon.fazendaId,
          'culturaId': polygon.culturaId,
          'safraId': polygon.safraId,
          'points': points,
        };
      }).toList();

    } catch (e) {
      print('❌ Erro ao carregar polígonos da fazenda: $e');
      return [];
    }
  }

  /// Carrega trilhas de um polígono
  Future<List<Map<String, dynamic>>> loadTracksByPolygonId(int polygonId) async {
    try {
      final tracks = await _polygonDao.getTracksByPolygonId(polygonId);
      return tracks.map((track) => {
        'id': track.id,
        'polygonId': track.polygonId,
        'lat': track.lat,
        'lon': track.lon,
        'accuracy': track.accuracy,
        'speed': track.speed,
        'bearing': track.bearing,
        'ts': track.ts,
        'status': track.status,
      }).toList();

    } catch (e) {
      print('❌ Erro ao carregar trilhas: $e');
      return [];
    }
  }

  /// Exclui um polígono e suas trilhas
  Future<bool> deletePolygon(int id) async {
    try {
      // Excluir trilhas primeiro
      await _polygonDao.deleteTracksByPolygonId(id);
      
      // Excluir polígono
      final deleted = await _polygonDao.deletePolygon(id);
      print('✅ Polígono excluído: $id');
      return deleted > 0;

    } catch (e) {
      print('❌ Erro ao excluir polígono: $e');
      return false;
    }
  }

  /// Atualiza um polígono existente
  Future<bool> updatePolygon({
    required int id,
    String? name,
    List<LatLng>? points,
    double? areaHa,
    double? perimeterM,
    double? distanceM,
    String? fazendaId,
    String? culturaId,
    String? safraId,
  }) async {
    try {
      // Buscar polígono atual
      final current = await _polygonDao.getPolygonById(id);
      if (current == null) return false;

      // Preparar dados para atualização
      String coordinates = current.coordinates;
      if (points != null) {
        final coords = points.map((p) => [p.longitude, p.latitude]).toList();
        final geojson = {
          "type": "Polygon",
          "coordinates": [coords]
        };
        coordinates = jsonEncode(geojson);
      }

      final polygon = PolygonModel(
        id: id,
        name: name ?? current.name,
        method: current.method,
        coordinates: coordinates,
        areaHa: areaHa ?? current.areaHa,
        perimeterM: perimeterM ?? current.perimeterM,
        distanceM: distanceM ?? current.distanceM,
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        fazendaId: fazendaId ?? current.fazendaId,
        culturaId: culturaId ?? current.culturaId,
        safraId: safraId ?? current.safraId,
      );

      print('🔄 Chamando _polygonDao.updatePolygon...');
      final success = await _polygonDao.updatePolygon(polygon);
      print('📊 Resultado do DAO: $success');
      print('📊 Tipo do resultado: ${success.runtimeType}');
      print('✅ Polígono atualizado: $id');
      final result = success > 0;
      print('📊 Retornando: $result');
      return result;

    } catch (e) {
      print('❌ Erro ao atualizar polígono: $e');
      return false;
    }
  }

  /// Busca polígonos por método
  Future<List<Map<String, dynamic>>> getPolygonsByMethod(String method) async {
    try {
      final polygons = await _polygonDao.getPolygonsByMethod(method);
      return polygons.map((polygon) {
        final geojson = jsonDecode(polygon.coordinates);
        final coordinates = geojson['coordinates'][0] as List;
        final points = coordinates.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();

        return {
          'id': polygon.id,
          'name': polygon.name,
          'method': polygon.method,
          'areaHa': polygon.areaHa,
          'perimeterM': polygon.perimeterM,
          'distanceM': polygon.distanceM,
          'createdAt': polygon.createdAt,
          'fazendaId': polygon.fazendaId,
          'culturaId': polygon.culturaId,
          'safraId': polygon.safraId,
          'points': points,
        };
      }).toList();

    } catch (e) {
      print('❌ Erro ao buscar polígonos por método: $e');
      return [];
    }
  }

  /// Exporta polígonos para GeoJSON
  Future<String> exportToGeoJSON(List<int> polygonIds) async {
    try {
      final features = <Map<String, dynamic>>[];

      for (final id in polygonIds) {
        final polygon = await _polygonDao.getPolygonById(id);
        if (polygon != null) {
          final geojson = jsonDecode(polygon.coordinates);
          final feature = {
            "type": "Feature",
            "geometry": geojson,
            "properties": {
              "id": polygon.id,
              "name": polygon.name,
              "method": polygon.method,
              "area_ha": polygon.areaHa,
              "perimeter_m": polygon.perimeterM,
              "distance_m": polygon.distanceM,
              "created_at": polygon.createdAt,
              "fazenda_id": polygon.fazendaId,
              "cultura_id": polygon.culturaId,
              "safra_id": polygon.safraId,
            }
          };
          features.add(feature);
        }
      }

      final featureCollection = {
        "type": "FeatureCollection",
        "features": features,
      };

      return jsonEncode(featureCollection);

    } catch (e) {
      print('❌ Erro ao exportar GeoJSON: $e');
      rethrow;
    }
  }
}
