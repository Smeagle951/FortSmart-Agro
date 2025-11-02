import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../models/talhao_model.dart';
import '../../../models/poligono_model.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../utils/logger.dart';
import '../../../utils/precise_geo_calculator.dart';
import 'infestation_cache_service.dart';

/// Serviço para integração com o módulo de talhões
/// Obtém coordenadas reais e informações geográficas dos talhões
class TalhaoIntegrationService {
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final InfestationCacheService _cacheService = InfestationCacheService();

  /// Obtém o centro geográfico de um talhão
  Future<LatLng?> getTalhaoCenter(String talhaoId) async {
    try {
      Logger.info('🔍 Obtendo centro do talhão: $talhaoId');
      
      // Tentar obter do cache primeiro
      final cachedData = await _cacheService.getTalhaoCoordinatesCache(talhaoId);
      if (cachedData != null && cachedData['centro'] != null) {
        final cachedCenter = cachedData['centro'] as Map<String, dynamic>;
        final center = LatLng(
          cachedCenter['latitude'] as double,
          cachedCenter['longitude'] as double,
        );
        Logger.info('✅ Centro do talhão obtido do cache: $center');
        return center;
      }
      
      // Se não estiver no cache, buscar do repositório
      final talhao = await _talhaoRepository.getTalhaoById(int.tryParse(talhaoId) ?? 0);
      if (talhao == null || talhao.poligonos.isEmpty) {
        Logger.warning('⚠️ Talhão não encontrado ou sem polígonos: $talhaoId');
        return null;
      }

      // Usar o primeiro polígono (principal)
      final poligono = talhao.poligonos.first;
      if (poligono.pontos.isEmpty) {
        Logger.warning('⚠️ Polígono sem pontos: $talhaoId');
        return null;
      }

      // Calcular centro usando o utilitário geo
      final center = PreciseGeoCalculator.calculatePolygonCenter(poligono.pontos);
      
      // Salvar no cache
      if (center != null) {
        final coordinatesData = {
          'centro': {
            'latitude': center.latitude,
            'longitude': center.longitude,
          },
          'timestamp': DateTime.now().toIso8601String(),
        };
        await _cacheService.cacheTalhaoCoordinates(talhaoId, coordinatesData);
        Logger.info('💾 Coordenadas salvas no cache para talhão: $talhaoId');
      }
      
      Logger.info('✅ Centro do talhão obtido: $center');
      return center;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter centro do talhão: $e');
      return null;
    }
  }

  /// Obtém o polígono completo de um talhão
  Future<List<LatLng>?> getTalhaoPolygon(String talhaoId) async {
    try {
      Logger.info('🔍 Obtendo polígono do talhão: $talhaoId');
      
      // Tentar obter do cache primeiro
      final cachedData = await _cacheService.getTalhaoCoordinatesCache(talhaoId);
      if (cachedData != null && cachedData['poligono_pontos'] != null) {
        final cachedPoints = cachedData['poligono_pontos'] as List;
        if (cachedPoints.isNotEmpty) {
          final polygon = cachedPoints.map((point) {
            final pointMap = point as Map<String, dynamic>;
            return LatLng(
              pointMap['latitude'] as double,
              pointMap['longitude'] as double,
            );
          }).toList();
          Logger.info('✅ Polígono do talhão obtido do cache: ${polygon.length} pontos');
          return polygon;
        }
      }
      
      // Se não estiver no cache, buscar do repositório
      final talhao = await _talhaoRepository.getTalhaoById(int.tryParse(talhaoId) ?? 0);
      if (talhao == null || talhao.poligonos.isEmpty) {
        Logger.warning('⚠️ Talhão não encontrado ou sem polígonos: $talhaoId');
        return null;
      }

      // Usar o primeiro polígono (principal)
      final poligono = talhao.poligonos.first;
      if (poligono.pontos.isEmpty) {
        Logger.warning('⚠️ Polígono sem pontos: $talhaoId');
        return null;
      }

      // Salvar no cache se já tivermos dados de coordenadas
      final existingCache = await _cacheService.getTalhaoCoordinatesCache(talhaoId);
      if (existingCache != null) {
        final updatedCache = Map<String, dynamic>.from(existingCache);
        updatedCache['poligono_pontos'] = poligono.pontos.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList();
        await _cacheService.cacheTalhaoCoordinates(talhaoId, updatedCache);
        Logger.info('💾 Polígono salvo no cache para talhão: $talhaoId');
      }

      Logger.info('✅ Polígono do talhão obtido: ${poligono.pontos.length} pontos');
      return poligono.pontos;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter polígono do talhão: $e');
      return null;
    }
  }

  /// Obtém informações completas de um talhão
  Future<Map<String, dynamic>?> getTalhaoInfo(String talhaoId) async {
    try {
      Logger.info('🔍 Obtendo informações do talhão: $talhaoId');
      
      final talhao = await _talhaoRepository.getTalhaoById(int.tryParse(talhaoId) ?? 0);
      if (talhao == null) {
        Logger.warning('⚠️ Talhão não encontrado: $talhaoId');
        return null;
      }

      // Calcular informações geográficas
      final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
      final center = poligono != null && poligono.pontos.isNotEmpty 
          ? PreciseGeoCalculator.calculatePolygonCenter(poligono.pontos)
          : null;
      final bounds = poligono != null && poligono.pontos.isNotEmpty
          ? PreciseGeoCalculator.calculatePolygonBounds(poligono.pontos)
          : null;
      final area = poligono != null && poligono.pontos.isNotEmpty
          ? PreciseGeoCalculator.calculatePolygonArea(poligono.pontos)
          : 0.0;
      final perimetro = poligono != null && poligono.pontos.isNotEmpty
          ? PreciseGeoCalculator.calculatePolygonPerimeter(poligono.pontos)
          : 0.0;

      final info = {
        'id': talhao.id,
        'nome': talhao.name,
        'area': area,
        'perimetro': perimetro,
        'centro': center != null ? {
          'latitude': center.latitude,
          'longitude': center.longitude,
        } : null,
        'bounds': bounds != null ? {
          'min_lat': bounds['min_lat'],
          'max_lat': bounds['max_lat'],
          'min_lon': bounds['min_lon'],
          'max_lon': bounds['max_lon'],
        } : null,
        'poligono_pontos': poligono?.pontos.map((p) => {
          'latitude': p.latitude,
          'longitude': p.longitude,
        }).toList() ?? [],
        'cultura_id': talhao.culturaId,
        'safra_id': talhao.safraId,
        'fazenda_id': talhao.fazendaId,
        'data_criacao': talhao.dataCriacao.toIso8601String(),
        'data_atualizacao': talhao.dataAtualizacao.toIso8601String(),
        'metadados': talhao.metadados,
      };

      Logger.info('✅ Informações do talhão obtidas: ${info['nome']}');
      return info;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter informações do talhão: $e');
      return null;
    }
  }

  /// Lista todos os talhões disponíveis
  Future<List<Map<String, dynamic>>> getAllTalhoes() async {
    try {
      Logger.info('🔍 Listando todos os talhões disponíveis');
      
      final talhoes = await _talhaoRepository.loadTalhoes();
      final talhoesInfo = <Map<String, dynamic>>[];

      for (final talhao in talhoes) {
        final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
        final center = poligono != null && poligono.pontos.isNotEmpty 
            ? PreciseGeoCalculator.calculatePolygonCenter(poligono.pontos)
            : null;

        talhoesInfo.add({
          'id': talhao.id,
          'nome': talhao.name,
          'area': talhao.area,
          'centro': center != null ? {
            'latitude': center.latitude,
            'longitude': center.longitude,
          } : null,
          'cultura_id': talhao.culturaId,
          'safra_id': talhao.safraId,
          'fazenda_id': talhao.fazendaId,
        });
      }

      Logger.info('✅ ${talhoesInfo.length} talhões listados');
      return talhoesInfo;
      
    } catch (e) {
      Logger.error('❌ Erro ao listar talhões: $e');
      return [];
    }
  }

  /// Obtém talhões por fazenda
  Future<List<Map<String, dynamic>>> getTalhoesByFazenda(String fazendaId) async {
    try {
      Logger.info('🔍 Obtendo talhões da fazenda: $fazendaId');
      
      final talhoes = await _talhaoRepository.loadTalhoes();
      final talhoesFazenda = talhoes.where((t) => t.fazendaId == fazendaId).toList();
      final talhoesInfo = <Map<String, dynamic>>[];

      for (final talhao in talhoesFazenda) {
        final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
        final center = poligono != null && poligono.pontos.isNotEmpty 
            ? PreciseGeoCalculator.calculatePolygonCenter(poligono.pontos)
            : null;

        talhoesInfo.add({
          'id': talhao.id,
          'nome': talhao.name,
          'area': talhao.area,
          'centro': center != null ? {
            'latitude': center.latitude,
            'longitude': center.longitude,
          } : null,
          'cultura_id': talhao.culturaId,
          'safra_id': talhao.safraId,
          'fazenda_id': talhao.fazendaId,
        });
      }

      Logger.info('✅ ${talhoesInfo.length} talhões encontrados na fazenda');
      return talhoesInfo;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter talhões da fazenda: $e');
      return [];
    }
  }

  /// Obtém talhões por safra
  Future<List<Map<String, dynamic>>> getTalhoesBySafra(String safraId) async {
    try {
      Logger.info('🔍 Obtendo talhões da safra: $safraId');
      
      final talhoes = await _talhaoRepository.loadTalhoes();
      final talhoesSafra = talhoes.where((t) => t.safraId == safraId).toList();
      final talhoesInfo = <Map<String, dynamic>>[];

      for (final talhao in talhoesSafra) {
        final poligono = talhao.poligonos.isNotEmpty ? talhao.poligonos.first : null;
        final center = poligono != null && poligono.pontos.isNotEmpty 
            ? PreciseGeoCalculator.calculatePolygonCenter(poligono.pontos)
            : null;

        talhoesInfo.add({
          'id': talhao.id,
          'nome': talhao.name,
          'area': talhao.area,
          'centro': center != null ? {
            'latitude': center.latitude,
            'longitude': center.longitude,
          } : null,
          'cultura_id': talhao.culturaId,
          'safra_id': talhao.safraId,
          'fazenda_id': talhao.fazendaId,
        });
      }

      Logger.info('✅ ${talhoesInfo.length} talhões encontrados na safra');
      return talhoesInfo;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter talhões da safra: $e');
      return [];
    }
  }

  /// Verifica se um ponto está dentro de um talhão
  Future<bool> isPointInTalhao(String talhaoId, LatLng point) async {
    try {
      final poligono = await getTalhaoPolygon(talhaoId);
      if (poligono == null || poligono.isEmpty) {
        return false;
      }

      return _isPointInPolygon(point, poligono);
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar se ponto está no talhão: $e');
      return false;
    }
  }

  /// Obtém talhões próximos a um ponto (dentro de um raio)
  Future<List<Map<String, dynamic>>> getTalhoesNearPoint(
    LatLng point, 
    double radiusKm,
  ) async {
    try {
      Logger.info('🔍 Buscando talhões próximos ao ponto: $point (raio: ${radiusKm}km)');
      
      final talhoes = await _talhaoRepository.loadTalhoes();
      final talhoesProximos = <Map<String, dynamic>>[];

      for (final talhao in talhoes) {
        final center = await getTalhaoCenter(talhao.id.toString());
        if (center != null) {
          final distance = _calculateDistance(point, center);
          if (distance <= radiusKm) {
            talhoesProximos.add({
              'id': talhao.id,
              'nome': talhao.name,
              'area': talhao.area,
              'centro': {
                'latitude': center.latitude,
                'longitude': center.longitude,
              },
              'distancia_km': distance,
              'cultura_id': talhao.culturaId,
              'safra_id': talhao.safraId,
              'fazenda_id': talhao.fazendaId,
            });
          }
        }
      }

      // Ordenar por distância
      talhoesProximos.sort((a, b) => (a['distancia_km'] as double).compareTo(b['distancia_km'] as double));

      Logger.info('✅ ${talhoesProximos.length} talhões encontrados próximos ao ponto');
      return talhoesProximos;
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar talhões próximos: $e');
      return [];
    }
  }

  /// Obtém estatísticas geográficas dos talhões
  Future<Map<String, dynamic>> getTalhoesGeoStats() async {
    try {
      Logger.info('🔍 Obtendo estatísticas geográficas dos talhões');
      
      final talhoes = await _talhaoRepository.loadTalhoes();
      double totalArea = 0.0;
      double totalPerimetro = 0.0;
      int talhoesComPoligono = 0;
      int talhoesSemPoligono = 0;

      for (final talhao in talhoes) {
        if (talhao.poligonos.isNotEmpty && talhao.poligonos.first.pontos.isNotEmpty) {
          final poligono = talhao.poligonos.first;
          totalArea += PreciseGeoCalculator.calculatePolygonArea(poligono.pontos);
          totalPerimetro += PreciseGeoCalculator.calculatePolygonPerimeter(poligono.pontos);
          talhoesComPoligono++;
        } else {
          talhoesSemPoligono++;
        }
      }

      final stats = {
        'total_talhoes': talhoes.length,
        'talhoes_com_poligono': talhoesComPoligono,
        'talhoes_sem_poligono': talhoesSemPoligono,
        'area_total_ha': totalArea,
        'perimetro_total_km': totalPerimetro,
        'area_media_ha': talhoesComPoligono > 0 ? totalArea / talhoesComPoligono : 0.0,
        'perimetro_medio_km': talhoesComPoligono > 0 ? totalPerimetro / talhoesComPoligono : 0.0,
      };

      Logger.info('✅ Estatísticas geográficas obtidas');
      return stats;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas geográficas: $e');
      return {};
    }
  }

  /// Verifica se um ponto está dentro de um polígono
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    
    bool inside = false;
    int j = polygon.length - 1;
    
    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }
    
    return inside;
  }

  /// Calcula a distância entre dois pontos em km
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371.0; // Raio da Terra em km
    
    final lat1Rad = point1.latitude * pi / 180.0;
    final lat2Rad = point2.latitude * pi / 180.0;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180.0;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180.0;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
               cos(lat1Rad) * cos(lat2Rad) *
               sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}
