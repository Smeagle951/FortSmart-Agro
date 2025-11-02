import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/offline_map_model.dart';
import '../models/offline_map_status.dart';
import '../services/offline_map_service.dart';
import '../../../../models/talhao_model.dart';
import '../../../../models/talhoes/talhao_safra_model.dart';

/// Serviço para integração com o sistema de talhões
class TalhaoIntegrationService {
  static final TalhaoIntegrationService _instance = TalhaoIntegrationService._internal();
  factory TalhaoIntegrationService() => _instance;
  TalhaoIntegrationService._internal();

  final OfflineMapService _offlineMapService = OfflineMapService();
  final Map<String, StreamSubscription> _talhaoSubscriptions = {};

  /// Inicializa o serviço
  Future<void> init() async {
    await _offlineMapService.init();
  }

  /// Cria mapa offline automaticamente quando um talhão é criado (TalhaoSafraModel)
  Future<OfflineMapModel?> createOfflineMapForTalhao(TalhaoSafraModel talhao) async {
    try {
      // Verificar se já existe mapa offline para este talhão
      final existingMaps = await _offlineMapService.getOfflineMapsByTalhao(talhao.id);
      if (existingMaps.isNotEmpty) {
        return existingMaps.first;
      }

      // Converter polígono do talhão para formato compatível
      final polygon = talhao.poligonos.isNotEmpty 
          ? talhao.poligonos.first.pontos.map((point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            }).toList()
          : <Map<String, double>>[];

      if (polygon.isEmpty) {
        print('⚠️ Talhão ${talhao.name} não possui polígono válido');
        return null;
      }

      // Criar mapa offline
      final offlineMap = await _offlineMapService.createOfflineMap(
        talhaoId: talhao.id,
        talhaoName: talhao.name,
        polygon: polygon,
        area: talhao.area ?? 0.0,
        fazendaId: talhao.idFazenda,
      );

      print('✅ Mapa offline criado para talhão: ${talhao.name}');
      return offlineMap;
    } catch (e) {
      print('❌ Erro ao criar mapa offline para talhão ${talhao.name}: $e');
      return null;
    }
  }

  /// Cria mapa offline automaticamente quando um talhão é criado (TalhaoModel)
  Future<OfflineMapModel?> createOfflineMapForTalhaoLegacy(TalhaoModel talhao) async {
    try {
      // Verificar se já existe mapa offline para este talhão
      final existingMaps = await _offlineMapService.getOfflineMapsByTalhao(talhao.id);
      if (existingMaps.isNotEmpty) {
        return existingMaps.first;
      }

      // Converter polígono do talhão para formato compatível
      final polygon = talhao.poligonos.isNotEmpty 
          ? talhao.poligonos.first.pontos.map((point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            }).toList()
          : <Map<String, double>>[];

      if (polygon.isEmpty) {
        print('⚠️ Talhão ${talhao.name} não possui polígono válido');
        return null;
      }

      // Criar mapa offline
      final offlineMap = await _offlineMapService.createOfflineMap(
        talhaoId: talhao.id,
        talhaoName: talhao.name,
        polygon: polygon,
        area: talhao.area,
        fazendaId: talhao.fazendaId,
        fazendaName: talhao.fazendaNome,
        zoomMin: 13,
        zoomMax: 18,
        metadata: {
          'created_from': 'talhao_creation',
          'talhao_created_at': talhao.dataCriacao.toIso8601String(),
        },
      );

      print('✅ Mapa offline criado para talhão ${talhao.name}');
      return offlineMap;
    } catch (e) {
      print('❌ Erro ao criar mapa offline para talhão ${talhao.name}: $e');
      return null;
    }
  }

  /// Atualiza mapa offline quando um talhão é editado (TalhaoSafraModel)
  Future<void> updateOfflineMapForTalhao(TalhaoSafraModel talhao) async {
    try {
      final existingMaps = await _offlineMapService.getOfflineMapsByTalhao(talhao.id);
      
      if (existingMaps.isEmpty) {
        // Criar novo mapa se não existir
        await createOfflineMapForTalhao(talhao);
        return;
      }

      // Atualizar mapa existente
      final offlineMap = existingMaps.first;
      
      // Converter polígono atualizado
      final polygon = talhao.poligonos.isNotEmpty 
          ? talhao.poligonos.first.pontos.map((point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            }).toList()
          : <Map<String, double>>[];

      if (polygon.isEmpty) {
        print('⚠️ Talhão ${talhao.name} não possui polígono válido');
        return;
      }

      // Converter polígono para LatLng
      final latLngPolygon = polygon.map((point) => LatLng(
        point['latitude'] ?? 0.0, 
        point['longitude'] ?? 0.0
      )).toList();

      // Atualizar dados do mapa offline
      final updatedMap = offlineMap.copyWith(
        talhaoName: talhao.name,
        polygon: latLngPolygon,
        area: talhao.area ?? 0.0,
        status: OfflineMapStatus.updateAvailable, // Marcar para atualização
        updatedAt: DateTime.now(),
      );
      await _offlineMapService.updateOfflineMap(updatedMap);

      print('✅ Mapa offline atualizado para talhão: ${talhao.name}');
    } catch (e) {
      print('❌ Erro ao atualizar mapa offline para talhão ${talhao.name}: $e');
    }
  }

  /// Atualiza mapa offline quando um talhão é editado (TalhaoModel)
  Future<void> updateOfflineMapForTalhaoLegacy(TalhaoModel talhao) async {
    try {
      final existingMaps = await _offlineMapService.getOfflineMapsByTalhao(talhao.id);
      
      if (existingMaps.isEmpty) {
        // Criar novo mapa se não existir
        await createOfflineMapForTalhaoLegacy(talhao);
        return;
      }

      // Atualizar mapa existente
      final offlineMap = existingMaps.first;
      
      // Converter polígono atualizado
      final polygon = talhao.poligonos.isNotEmpty 
          ? talhao.poligonos.first.pontos.map((point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            }).toList()
          : <Map<String, double>>[];

      if (polygon.isEmpty) {
        print('⚠️ Talhão ${talhao.name} não possui polígono válido para atualização');
        return;
      }

      // Atualizar dados do mapa offline
      final updatedMap = offlineMap.copyWith(
        talhaoName: talhao.name,
        area: talhao.area,
        fazendaId: talhao.fazendaId,
        fazendaName: talhao.fazendaNome,
        status: OfflineMapStatus.updateAvailable, // Marcar para atualização
        updatedAt: DateTime.now(),
        metadata: {
          ...offlineMap.metadata,
          'last_talhao_update': talhao.dataAtualizacao.toIso8601String(),
          'needs_update': true,
        },
      );

      await _offlineMapService.updateOfflineMap(updatedMap);
      print('✅ Mapa offline atualizado para talhão ${talhao.name}');
    } catch (e) {
      print('❌ Erro ao atualizar mapa offline para talhão ${talhao.name}: $e');
    }
  }

  /// Remove mapa offline quando um talhão é removido (TalhaoSafraModel)
  Future<void> removeOfflineMapForTalhao(String talhaoId) async {
    try {
      final existingMaps = await _offlineMapService.getOfflineMapsByTalhao(talhaoId);
      
      for (final offlineMap in existingMaps) {
        await _offlineMapService.deleteOfflineMap(offlineMap.id);
      }

      print('✅ Mapas offline removidos para talhão $talhaoId');
    } catch (e) {
      print('❌ Erro ao remover mapas offline para talhão $talhaoId: $e');
    }
  }

  /// Verifica se um talhão tem mapas offline disponíveis
  Future<bool> hasOfflineMapsForTalhao(String talhaoId) async {
    try {
      return await _offlineMapService.hasOfflineMaps(talhaoId);
    } catch (e) {
      print('❌ Erro ao verificar mapas offline para talhão $talhaoId: $e');
      return false;
    }
  }

  /// Obtém mapas offline de um talhão
  Future<List<OfflineMapModel>> getOfflineMapsForTalhao(String talhaoId) async {
    try {
      return await _offlineMapService.getOfflineMapsByTalhao(talhaoId);
    } catch (e) {
      print('❌ Erro ao obter mapas offline para talhão $talhaoId: $e');
      return [];
    }
  }

  /// Processa todos os talhões existentes para criar mapas offline
  Future<void> processExistingTalhoes(List<TalhaoModel> talhoes) async {
    try {
      print('🔄 Processando ${talhoes.length} talhões para mapas offline...');
      
      int created = 0;
      int updated = 0;
      int skipped = 0;

      for (final talhao in talhoes) {
        try {
          final existingMaps = await _offlineMapService.getOfflineMapsByTalhao(talhao.id);
          
          if (existingMaps.isEmpty) {
            final offlineMap = await createOfflineMapForTalhaoLegacy(talhao);
            if (offlineMap != null) created++;
            else skipped++;
          } else {
            await updateOfflineMapForTalhaoLegacy(talhao);
            updated++;
          }
        } catch (e) {
          print('❌ Erro ao processar talhão ${talhao.name}: $e');
          skipped++;
        }
      }

      print('✅ Processamento concluído: $created criados, $updated atualizados, $skipped ignorados');
    } catch (e) {
      print('❌ Erro ao processar talhões existentes: $e');
    }
  }

  /// Monitora mudanças em talhões e atualiza mapas offline automaticamente
  void startTalhaoMonitoring(Stream<List<TalhaoModel>> talhoesStream) {
    _talhaoSubscriptions['talhoes'] = talhoesStream.listen(
      (talhoes) async {
        await processExistingTalhoes(talhoes);
      },
      onError: (error) {
        print('❌ Erro no monitoramento de talhões: $error');
      },
    );
  }

  /// Para o monitoramento de talhões
  void stopTalhaoMonitoring() {
    _talhaoSubscriptions['talhoes']?.cancel();
    _talhaoSubscriptions.remove('talhoes');
  }

  /// Obtém estatísticas de integração
  Future<Map<String, dynamic>> getIntegrationStats() async {
    try {
      final allMaps = await _offlineMapService.getAllOfflineMaps();
      final storageStats = await _offlineMapService.getStorageStats();
      
      return {
        'total_offline_maps': allMaps.length,
        'downloaded_maps': allMaps.where((m) => m.status == OfflineMapStatus.downloaded).length,
        'downloading_maps': allMaps.where((m) => m.status == OfflineMapStatus.downloading).length,
        'error_maps': allMaps.where((m) => m.status == OfflineMapStatus.error).length,
        'storage_stats': storageStats,
        'integration_active': _talhaoSubscriptions.isNotEmpty,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas de integração: $e');
      return {};
    }
  }

  /// Limpa dados de integração
  Future<void> cleanupIntegration() async {
    try {
      // Parar monitoramento
      stopTalhaoMonitoring();
      
      // Limpar mapas antigos
      await _offlineMapService.cleanupOldMaps();
      
      print('✅ Limpeza de integração concluída');
    } catch (e) {
      print('❌ Erro na limpeza de integração: $e');
    }
  }

  /// Fecha o serviço
  Future<void> dispose() async {
    stopTalhaoMonitoring();
    await _offlineMapService.dispose();
  }
}
