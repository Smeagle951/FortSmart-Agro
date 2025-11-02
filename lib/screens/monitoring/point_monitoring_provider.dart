import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/infestacao_model.dart';
import '../../models/ponto_monitoramento_model.dart';
import '../../repositories/infestacao_repository.dart';
import '../../repositories/ponto_monitoramento_repository.dart';
import '../../services/location_service.dart';

class PointMonitoringState {
  final PontoMonitoramentoModel? currentPoint;
  final PontoMonitoramentoModel? nextPoint;
  final List<InfestacaoModel> ocorrencias;
  final Position? currentPosition;
  final double? distanceToPoint;
  final bool isSyncing;
  final String? gpsAccuracy;
  final bool hasArrived;
  final String? observacoesGerais;
  final bool isLoading;
  final String? error;

  PointMonitoringState({
    this.currentPoint,
    this.nextPoint,
    this.ocorrencias = const [],
    this.currentPosition,
    this.distanceToPoint,
    this.isSyncing = false,
    this.gpsAccuracy,
    this.hasArrived = false,
    this.observacoesGerais,
    this.isLoading = false,
    this.error,
  });

  PointMonitoringState copyWith({
    PontoMonitoramentoModel? currentPoint,
    PontoMonitoramentoModel? nextPoint,
    List<InfestacaoModel>? ocorrencias,
    Position? currentPosition,
    double? distanceToPoint,
    bool? isSyncing,
    String? gpsAccuracy,
    bool? hasArrived,
    String? observacoesGerais,
    bool? isLoading,
    String? error,
  }) {
    return PointMonitoringState(
      currentPoint: currentPoint ?? this.currentPoint,
      nextPoint: nextPoint ?? this.nextPoint,
      ocorrencias: ocorrencias ?? this.ocorrencias,
      currentPosition: currentPosition ?? this.currentPosition,
      distanceToPoint: distanceToPoint ?? this.distanceToPoint,
      isSyncing: isSyncing ?? this.isSyncing,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      hasArrived: hasArrived ?? this.hasArrived,
      observacoesGerais: observacoesGerais ?? this.observacoesGerais,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PointMonitoringProvider extends ChangeNotifier {
  final InfestacaoRepository _infestacaoRepository;
  final PontoMonitoramentoRepository _pontoRepository;
  final LocationService _locationService;

  PointMonitoringState _state = PointMonitoringState();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _debounceTimer;

  PointMonitoringProvider(
    this._infestacaoRepository,
    this._pontoRepository,
    this._locationService,
  );

  PointMonitoringState get state => _state;

  Future<void> initializePoint(int pontoId, int talhaoId, int culturaId) async {
    _updateState(_state.copyWith(isLoading: true, error: null));

    try {
      // Carregar ponto atual
      final currentPoint = await _pontoRepository.getById(pontoId);
      if (currentPoint == null) {
        throw Exception('Ponto não encontrado');
      }

      // Carregar próximo ponto
      final allPoints = await _pontoRepository.getByTalhaoId(talhaoId);
      final currentIndex = allPoints.indexWhere((p) => p.id == pontoId);
      final nextPoint = currentIndex < allPoints.length - 1 
          ? allPoints[currentIndex + 1] 
          : null;

      // Carregar ocorrências do ponto atual
      final ocorrencias = await _infestacaoRepository.getByPontoId(pontoId);

      // Carregar observações gerais
      final observacoes = currentPoint.observacoesGerais;

      _updateState(_state.copyWith(
        currentPoint: currentPoint,
        nextPoint: nextPoint,
        ocorrencias: ocorrencias,
        observacoesGerais: observacoes,
        isLoading: false,
      ));

      // Iniciar monitoramento GPS
      _startGpsMonitoring();

      // Marcar início do ponto se ainda não foi iniciado
      if (currentPoint.dataHoraInicio == null) {
        await _pontoRepository.startPoint(pontoId);
      }

    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _startGpsMonitoring() {
    _positionSubscription?.cancel();
    
    _positionSubscription = _locationService.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1, // 1 metro
    ).listen(
      (position) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _updateGpsPosition(position);
        });
      },
      onError: (error) {
        _updateState(_state.copyWith(
          gpsAccuracy: 'Erro: $error',
        ));
      },
    );
  }

  void _updateGpsPosition(Position position) {
    final currentPoint = _state.currentPoint;
    if (currentPoint == null) return;

    // Calcular distância até o ponto atual
    final distance = _calculateDistance(
      position.latitude,
      position.longitude,
      currentPoint.latitude,
      currentPoint.longitude,
    );

    // Verificar se chegou ao ponto (≤ 5 metros)
    final hasArrived = distance <= 5.0;
    final previousArrived = _state.hasArrived;

    // Vibrar e tocar som quando chegar pela primeira vez
    if (hasArrived && !previousArrived) {
      _triggerArrivalNotification();
    }

    // Atualizar estado
    _updateState(_state.copyWith(
      currentPosition: position,
      distanceToPoint: distance,
      gpsAccuracy: '${position.accuracy.toStringAsFixed(1)}m',
      hasArrived: hasArrived,
    ));
  }

  void _triggerArrivalNotification() {
    // Implementar vibração e som
    // HapticFeedback.mediumImpact();
    // AudioService.playArrivalSound();
  }

  Future<void> saveOcorrencia({
    required String tipo,
    required String subtipo,
    required String nivel,
    required int percentual,
    String? observacao,
    List<String>? fotoPaths,
  }) async {
    final currentPoint = _state.currentPoint;
    final position = _state.currentPosition;
    
    if (currentPoint == null || position == null) {
      throw Exception('Dados insuficientes para salvar ocorrência');
    }

    // Validar precisão GPS
    const maxAccuracy = 10.0; // 10 metros
    if (position.accuracy > maxAccuracy) {
      throw Exception('Precisão GPS insuficiente (${position.accuracy.toStringAsFixed(1)}m > ${maxAccuracy}m)');
    }

    try {
      // Criar modelo de infestação
      final infestacao = InfestacaoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        talhaoId: currentPoint.talhaoId,
        pontoId: currentPoint.id,
        latitude: position.latitude,
        longitude: position.longitude,
        tipo: tipo,
        subtipo: subtipo,
        nivel: nivel,
        percentual: percentual,
        observacao: observacao,
        fotoPaths: fotoPaths?.join(';'),
        dataHora: DateTime.now(),
      );

      // Salvar no banco
      await _infestacaoRepository.insert(infestacao);

      // Atualizar lista local
      final updatedOcorrencias = [..._state.ocorrencias, infestacao];
      _updateState(_state.copyWith(ocorrencias: updatedOcorrencias));

    } catch (e) {
      _updateState(_state.copyWith(error: 'Erro ao salvar ocorrência: $e'));
      rethrow;
    }
  }

  Future<void> deleteOcorrencia(String id) async {
    try {
      await _infestacaoRepository.delete(id);
      final updatedOcorrencias = _state.ocorrencias.where((o) => o.id != id).toList();
      _updateState(_state.copyWith(ocorrencias: updatedOcorrencias));
    } catch (e) {
      _updateState(_state.copyWith(error: 'Erro ao deletar ocorrência: $e'));
      rethrow;
    }
  }

  Future<void> nextPoint() async {
    final currentPoint = _state.currentPoint;
    final nextPoint = _state.nextPoint;
    final distance = _state.distanceToPoint;

    if (currentPoint == null || nextPoint == null) {
      throw Exception('Não há próximo ponto disponível');
    }

    if (distance != null && distance > 5.0) {
      throw Exception('Você está a ${distance.toStringAsFixed(1)}m do próximo ponto. Aproxime-se a ≤5m para habilitar avanço.');
    }

    try {
      // Marcar fim do ponto atual
      await _pontoRepository.updateEndTime(currentPoint.id, DateTime.now());
      
      // Salvar observações gerais se houver
      if (_state.observacoesGerais != null && _state.observacoesGerais!.isNotEmpty) {
        await _pontoRepository.updateObservacoes(currentPoint.id, _state.observacoesGerais);
      }

      // Atualizar estado para o próximo ponto
      await initializePoint(nextPoint.id, nextPoint.talhaoId, 0); // culturaId será carregado do talhão

    } catch (e) {
      _updateState(_state.copyWith(error: 'Erro ao avançar para próximo ponto: $e'));
      rethrow;
    }
  }

  Future<void> previousPoint() async {
    final currentPoint = _state.currentPoint;
    if (currentPoint == null) return;

    try {
      // Buscar ponto anterior
      final allPoints = await _pontoRepository.getByTalhaoId(currentPoint.talhaoId);
      final currentIndex = allPoints.indexWhere((p) => p.id == currentPoint.id);
      
      if (currentIndex > 0) {
        final previousPoint = allPoints[currentIndex - 1];
        await initializePoint(previousPoint.id, previousPoint.talhaoId, 0);
      }

    } catch (e) {
      _updateState(_state.copyWith(error: 'Erro ao voltar ao ponto anterior: $e'));
      rethrow;
    }
  }

  void updateObservacoesGerais(String? observacoes) {
    _updateState(_state.copyWith(observacoesGerais: observacoes));
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  double? calculateBearingToNextPoint() {
    final currentPos = _state.currentPosition;
    final nextPoint = _state.nextPoint;
    
    if (currentPos == null || nextPoint == null) return null;
    
    return Geolocator.bearingBetween(
      currentPos.latitude,
      currentPos.longitude,
      nextPoint.latitude,
      nextPoint.longitude,
    );
  }

  void _updateState(PointMonitoringState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
