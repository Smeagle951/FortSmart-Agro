import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';
import 'background_gps_tracking_service.dart';

/// Serviço avançado de rastreamento GPS
/// Implementa todos os requisitos de precisão < 10m sem Kalman
/// ATUALIZADO: Agora usa BackgroundGpsTrackingService para funcionar em background
class AdvancedGpsTrackingService {
  // Configurações de precisão otimizadas para fluidez
  static const double _maxAccuracy = 15.0; // metros (mais permissivo)
  static const double _minDistance = 0.5; // metros (menor para mais fluidez)
  static const double _maxSpeed = 20.0; // m/s (72 km/h - mais permissivo)
  static const double _minDistanceBetweenPoints = 0.2; // metros (menor para mais pontos)
  static const double _maxJumpDistance = 50.0; // metros (mais permissivo)
  static const int _maxJumpTime = 3; // segundos (mais permissivo)
  static const int _warmupPoints = 2; // pontos para warm-up (reduzido)
  static const int _accuracyAveragePoints = 3; // pontos para média de precisão (reduzido)
  
  // Serviço de background
  final BackgroundGpsTrackingService _backgroundService = BackgroundGpsTrackingService();
  
  // Callbacks adicionais
  Function(List<LatLng>)? _onRealTimeLineUpdate;
  Function(LatLng)? _onNewPoint;
  Function(double)? _onSpeedChanged;
  Function(String)? _onError;
  
  /// Inicializa o serviço
  Future<void> initialize() async {
    try {
      Logger.info('✅ AdvancedGpsTrackingService inicializado (usando BackgroundGpsTrackingService)');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar AdvancedGpsTrackingService: $e');
      rethrow;
    }
  }
  
  /// Inicia o rastreamento GPS em background
  Future<bool> startTracking({
    required Function(List<LatLng>) onPointsChanged,
    required Function(double) onDistanceChanged,
    required Function(double) onAccuracyChanged,
    required Function(String) onStatusChanged,
    required Function(bool) onTrackingStateChanged,
  }) async {
    try {
      Logger.info('🚀 Iniciando rastreamento GPS em background...');
      
      // Delegar para o serviço de background
      return await _backgroundService.startTracking(
        onPointsChanged: onPointsChanged,
        onDistanceChanged: onDistanceChanged,
        onAccuracyChanged: onAccuracyChanged,
        onStatusChanged: onStatusChanged,
        onTrackingStateChanged: onTrackingStateChanged,
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao iniciar rastreamento: $e');
      onStatusChanged('Erro ao iniciar rastreamento: $e');
      return false;
    }
  }
  
  /// Pausa o rastreamento
  void pauseTracking() {
    _backgroundService.pauseTracking();
  }
  
  /// Retoma o rastreamento
  void resumeTracking() {
    _backgroundService.resumeTracking();
  }
  
  /// Para o rastreamento
  Future<void> stopTracking() async {
    await _backgroundService.stopTracking();
  }

  /// Limpa todos os dados de rastreamento
  void clearData() {
    // Não há mais dados locais para limpar
    Logger.info('Dados limpos (delegado ao BackgroundGpsTrackingService)');
  }
  
  /// Obtém estatísticas do rastreamento
  Map<String, dynamic> getTrackingStats() {
    return _backgroundService.getTrackingStats();
  }
  
  /// Obtém pontos do rastreamento
  List<LatLng> getTrackPoints() {
    return _backgroundService.getTrackPoints();
  }
  
  /// Fecha polígono automaticamente
  List<LatLng> closePolygon(List<LatLng> points) {
    if (points.length < 3) return points;
    
    final first = points.first;
    final last = points.last;
    final distance = Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      last.latitude,
      last.longitude,
    );
    
    // Se a distância entre primeiro e último ponto for > 2m, adicionar primeiro ponto no final
    if (distance > 2.0) {
      points.add(first);
      Logger.info('🔗 Polígono fechado automaticamente (distância: ${distance.toStringAsFixed(1)}m)');
    }
    
    return points;
  }
  
  /// Dispose do serviço
  void dispose() {
    _backgroundService.dispose();
  }
  
  // Getters delegados ao serviço de background
  bool get isTracking => _backgroundService.isTracking;
  bool get isPaused => _backgroundService.isPaused;
  List<LatLng> get trackPoints => _backgroundService.trackPoints;
  double get totalDistance => _backgroundService.totalDistance;
  double get currentAccuracy => _backgroundService.currentAccuracy;
  int get pointsCount => _backgroundService.pointsCount;
  
  // Setters para callbacks adicionais
  set onRealTimeLineUpdate(Function(List<LatLng>)? callback) {
    _onRealTimeLineUpdate = callback;
  }

  set onNewPoint(Function(LatLng)? callback) {
    _onNewPoint = callback;
  }

  set onSpeedChanged(Function(double)? callback) {
    _onSpeedChanged = callback;
  }

  set onError(Function(String)? callback) {
    _onError = callback;
  }
}
