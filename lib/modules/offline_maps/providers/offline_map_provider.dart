import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/offline_map_model.dart';
import '../models/offline_map_status.dart';
import '../services/offline_map_service.dart';

/// Provider para gerenciamento de estado dos mapas offline
class OfflineMapProvider extends ChangeNotifier {
  final OfflineMapService _offlineMapService = OfflineMapService();
  
  List<OfflineMapModel> _offlineMaps = [];
  bool _isLoading = false;
  String? _error;
  Map<String, StreamSubscription> _downloadSubscriptions = {};

  /// Lista de mapas offline
  List<OfflineMapModel> get offlineMaps => _offlineMaps;

  /// Verifica se está carregando
  bool get isLoading => _isLoading;

  /// Mensagem de erro
  String? get error => _error;

  /// Mapas baixados
  List<OfflineMapModel> get downloadedMaps => 
      _offlineMaps.where((map) => map.status == OfflineMapStatus.downloaded).toList();

  /// Mapas em download
  List<OfflineMapModel> get downloadingMaps => 
      _offlineMaps.where((map) => map.status == OfflineMapStatus.downloading).toList();

  /// Mapas não baixados
  List<OfflineMapModel> get notDownloadedMaps => 
      _offlineMaps.where((map) => map.status == OfflineMapStatus.notDownloaded).toList();

  /// Mapas com erro
  List<OfflineMapModel> get errorMaps => 
      _offlineMaps.where((map) => map.status == OfflineMapStatus.error).toList();

  /// Todos os mapas
  List<OfflineMapModel> get maps => List.unmodifiable(_offlineMaps);

  /// Inicializa o provider
  Future<void> init() async {
    try {
      await _offlineMapService.init();
      await loadOfflineMaps();
    } catch (e) {
      _error = 'Erro ao inicializar mapas offline: $e';
      notifyListeners();
    }
  }

  /// Carrega todos os mapas offline
  Future<void> loadOfflineMaps() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _offlineMaps = await _offlineMapService.getAllOfflineMaps();
    } catch (e) {
      _error = 'Erro ao carregar mapas offline: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cria um novo mapa offline
  Future<OfflineMapModel?> createOfflineMap({
    required String talhaoId,
    required String talhaoName,
    required List<dynamic> polygon,
    required double area,
    String? fazendaId,
    String? fazendaName,
    int zoomMin = 13,
    int zoomMax = 18,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _error = null;
      
      final offlineMap = await _offlineMapService.createOfflineMap(
        talhaoId: talhaoId,
        talhaoName: talhaoName,
        polygon: polygon,
        area: area,
        fazendaId: fazendaId,
        fazendaName: fazendaName,
        zoomMin: zoomMin,
        zoomMax: zoomMax,
        metadata: metadata,
      );

      _offlineMaps.add(offlineMap);
      notifyListeners();
      return offlineMap;
    } catch (e) {
      _error = 'Erro ao criar mapa offline: $e';
      notifyListeners();
      return null;
    }
  }

  /// Inicia download de um mapa offline
  Future<void> downloadMap(OfflineMapModel offlineMap, {String mapType = 'satellite'}) async {
    try {
      _error = null;
      
      // Atualizar status local
      final index = _offlineMaps.indexWhere((map) => map.id == offlineMap.id);
      if (index != -1) {
        _offlineMaps[index] = offlineMap.copyWith(
          status: OfflineMapStatus.downloading,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      // Iniciar download
      final stream = await _offlineMapService.downloadOfflineMap(
        offlineMap.id,
        mapType: mapType,
      );

      // Escutar progresso do download
      _downloadSubscriptions[offlineMap.id] = stream.listen(
        (updatedMap) {
          final mapIndex = _offlineMaps.indexWhere((map) => map.id == updatedMap.id);
          if (mapIndex != -1) {
            _offlineMaps[mapIndex] = updatedMap;
            notifyListeners();
          }
        },
        onError: (error) {
          _error = 'Erro no download: $error';
          notifyListeners();
        },
        onDone: () {
          _downloadSubscriptions.remove(offlineMap.id);
        },
      );
    } catch (e) {
      _error = 'Erro ao iniciar download: $e';
      notifyListeners();
    }
  }

  /// Pausa download de um mapa offline
  Future<void> pauseDownload(String offlineMapId) async {
    try {
      await _offlineMapService.pauseDownload(offlineMapId);
      
      // Atualizar status local
      final index = _offlineMaps.indexWhere((map) => map.id == offlineMapId);
      if (index != -1) {
        _offlineMaps[index] = _offlineMaps[index].copyWith(
          status: OfflineMapStatus.paused,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      // Cancelar subscription
      if (_downloadSubscriptions.containsKey(offlineMapId)) {
        await _downloadSubscriptions[offlineMapId]?.cancel();
        _downloadSubscriptions.remove(offlineMapId);
      }
    } catch (e) {
      _error = 'Erro ao pausar download: $e';
      notifyListeners();
    }
  }

  /// Retoma download de um mapa offline
  Future<void> resumeDownload(String offlineMapId, {String mapType = 'satellite'}) async {
    try {
      final offlineMap = _offlineMaps.firstWhere((map) => map.id == offlineMapId);
      await downloadMap(offlineMap, mapType: mapType);
    } catch (e) {
      _error = 'Erro ao retomar download: $e';
      notifyListeners();
    }
  }

  /// Remove um mapa offline
  Future<void> deleteOfflineMap(String offlineMapId) async {
    try {
      await _offlineMapService.deleteOfflineMap(offlineMapId);
      
      _offlineMaps.removeWhere((map) => map.id == offlineMapId);
      
      // Cancelar subscription se existir
      if (_downloadSubscriptions.containsKey(offlineMapId)) {
        await _downloadSubscriptions[offlineMapId]?.cancel();
        _downloadSubscriptions.remove(offlineMapId);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover mapa offline: $e';
      notifyListeners();
    }
  }

  /// Baixa todos os mapas não baixados
  Future<void> downloadAll({String mapType = 'satellite'}) async {
    try {
      final notDownloaded = notDownloadedMaps;
      
      for (final offlineMap in notDownloaded) {
        await downloadMap(offlineMap, mapType: mapType);
        // Pequena pausa entre downloads para não sobrecarregar
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      _error = 'Erro ao baixar todos os mapas: $e';
      notifyListeners();
    }
  }

  /// Atualiza um mapa offline
  Future<void> updateOfflineMap(OfflineMapModel offlineMap) async {
    try {
      await _offlineMapService.updateOfflineMap(offlineMap);
      
      final index = _offlineMaps.indexWhere((map) => map.id == offlineMap.id);
      if (index != -1) {
        _offlineMaps[index] = offlineMap;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erro ao atualizar mapa offline: $e';
      notifyListeners();
    }
  }

  /// Obtém estatísticas de uso
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      return await _offlineMapService.getStorageStats();
    } catch (e) {
      _error = 'Erro ao obter estatísticas: $e';
      notifyListeners();
      return {};
    }
  }

  /// Limpa mapas antigos
  Future<void> cleanupOldMaps({int daysOld = 30}) async {
    try {
      await _offlineMapService.cleanupOldMaps(daysOld: daysOld);
      await loadOfflineMaps();
    } catch (e) {
      _error = 'Erro ao limpar mapas antigos: $e';
      notifyListeners();
    }
  }

  /// Verifica se um talhão tem mapas offline
  Future<bool> hasOfflineMaps(String talhaoId) async {
    try {
      return await _offlineMapService.hasOfflineMaps(talhaoId);
    } catch (e) {
      _error = 'Erro ao verificar mapas offline: $e';
      notifyListeners();
      return false;
    }
  }

  /// Obtém mapas offline por talhão
  Future<List<OfflineMapModel>> getOfflineMapsByTalhao(String talhaoId) async {
    try {
      return await _offlineMapService.getOfflineMapsByTalhao(talhaoId);
    } catch (e) {
      _error = 'Erro ao obter mapas do talhão: $e';
      notifyListeners();
      return [];
    }
  }

  /// Limpa erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cancela todos os downloads
  Future<void> cancelAllDownloads() async {
    for (final subscription in _downloadSubscriptions.values) {
      await subscription.cancel();
    }
    _downloadSubscriptions.clear();
    notifyListeners();
  }

  /// Cancela download de um mapa
  Future<void> cancelDownload(String id) async {
    try {
      await _offlineMapService.pauseDownload(id);
      await loadOfflineMaps();
    } catch (e) {
      _error = 'Erro ao cancelar download: $e';
      notifyListeners();
    }
  }

  /// Atualiza um mapa
  Future<void> updateMap(OfflineMapModel map) async {
    try {
      await _offlineMapService.updateOfflineMap(map);
      await loadOfflineMaps();
    } catch (e) {
      _error = 'Erro ao atualizar mapa: $e';
      notifyListeners();
    }
  }

  /// Exclui um mapa
  Future<void> deleteMap(String id) async {
    try {
      await _offlineMapService.deleteOfflineMap(id);
      await loadOfflineMaps();
    } catch (e) {
      _error = 'Erro ao excluir mapa: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancelar todas as subscriptions
    for (final subscription in _downloadSubscriptions.values) {
      subscription.cancel();
    }
    _downloadSubscriptions.clear();
    super.dispose();
  }
}
