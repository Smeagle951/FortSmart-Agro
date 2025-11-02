import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../routes.dart';

/// Serviço para notificações e abertura automática da tela
class MonitoringNotificationService {
  static final MonitoringNotificationService _instance = MonitoringNotificationService._internal();
  factory MonitoringNotificationService() => _instance;
  MonitoringNotificationService._internal();

  bool _isNotificationEnabled = true;
  bool _isAutoOpenEnabled = true;
  Timer? _notificationTimer;
  BuildContext? _context;

  /// Define o contexto da aplicação
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Notifica proximidade detectada
  Future<void> notifyProximityDetected({
    required double distance,
    required Map<String, dynamic> point,
    required String talhaoId,
    required int pointIndex,
  }) async {
    try {
      if (!_isNotificationEnabled) return;

      Logger.info('🔔 Notificando proximidade detectada...');
      await _vibrateDevice();
      await _showProximityNotification(distance, point, talhaoId, pointIndex);

      if (_isAutoOpenEnabled) {
        _scheduleAutoOpen(talhaoId, pointIndex);
      }
    } catch (e) {
      Logger.error('❌ Erro ao notificar proximidade: $e');
    }
  }

  /// Notifica vibração acionada
  Future<void> notifyVibrationTriggered({
    required double distance,
    required Map<String, dynamic> point,
    required String talhaoId,
    required int pointIndex,
  }) async {
    try {
      if (!_isNotificationEnabled) return;

      Logger.info('📳 Notificando vibração acionada...');
      await _vibrateDeviceIntense();
      await _showVibrationNotification(distance, point, talhaoId, pointIndex);

      if (_isAutoOpenEnabled) {
        _scheduleAutoOpenImmediate(talhaoId, pointIndex);
      }
    } catch (e) {
      Logger.error('❌ Erro ao notificar vibração: $e');
    }
  }

  /// Vibra o dispositivo
  Future<void> _vibrateDevice() async {
    try {
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.mediumImpact();
    } catch (e) {
      Logger.error('❌ Erro ao vibrar dispositivo: $e');
    }
  }

  /// Vibração intensa
  Future<void> _vibrateDeviceIntense() async {
    try {
      for (int i = 0; i < 3; i++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (e) {
      Logger.error('❌ Erro na vibração intensa: $e');
    }
  }

  /// Mostra notificação de proximidade
  Future<void> _showProximityNotification(
    double distance,
    Map<String, dynamic> point,
    String talhaoId,
    int pointIndex,
  ) async {
    try {
      if (_context == null) return;

      _notificationTimer?.cancel();

      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎯 Próximo ao ponto de monitoramento!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Distância: ${distance.toStringAsFixed(1)}m',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Abrir',
            textColor: Colors.white,
            onPressed: () => _openMonitoringScreen(talhaoId, pointIndex),
          ),
        ),
      );
    } catch (e) {
      Logger.error('❌ Erro ao mostrar notificação de proximidade: $e');
    }
  }

  /// Mostra notificação de vibração
  Future<void> _showVibrationNotification(
    double distance,
    Map<String, dynamic> point,
    String talhaoId,
    int pointIndex,
  ) async {
    try {
      if (_context == null) return;

      _notificationTimer?.cancel();

      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.vibration, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '📳 CHEGOU AO PONTO!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Distância: ${distance.toStringAsFixed(1)}m - Abrindo tela...',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Abrir Agora',
            textColor: Colors.white,
            onPressed: () => _openMonitoringScreen(talhaoId, pointIndex),
          ),
        ),
      );
    } catch (e) {
      Logger.error('❌ Erro ao mostrar notificação de vibração: $e');
    }
  }

  /// Agenda abertura automática
  void _scheduleAutoOpen(String talhaoId, int pointIndex) {
    try {
      _notificationTimer?.cancel();
      _notificationTimer = Timer(const Duration(seconds: 3), () {
        _openMonitoringScreen(talhaoId, pointIndex);
      });
      Logger.info('⏰ Abertura automática agendada em 3s');
    } catch (e) {
      Logger.error('❌ Erro ao agendar abertura automática: $e');
    }
  }

  /// Agenda abertura automática imediata
  void _scheduleAutoOpenImmediate(String talhaoId, int pointIndex) {
    try {
      _notificationTimer?.cancel();
      _notificationTimer = Timer(const Duration(seconds: 1), () {
        _openMonitoringScreen(talhaoId, pointIndex);
      });
      Logger.info('⏰ Abertura automática imediata agendada');
    } catch (e) {
      Logger.error('❌ Erro ao agendar abertura automática imediata: $e');
    }
  }

  /// Abre a tela de monitoramento
  void _openMonitoringScreen(String talhaoId, int pointIndex) {
    try {
      if (_context == null) return;

      Logger.info('📱 Abrindo tela de monitoramento...');

      Navigator.of(_context!).pushNamedAndRemoveUntil(
        AppRoutes.monitoringPoint,
        (route) => false,
        arguments: {
          'talhaoId': talhaoId,
          'pointIndex': pointIndex,
          'fromBackground': true,
        },
      );
    } catch (e) {
      Logger.error('❌ Erro ao abrir tela de monitoramento: $e');
    }
  }

  /// Habilita/desabilita notificações
  void setNotificationEnabled(bool enabled) {
    _isNotificationEnabled = enabled;
    Logger.info('🔔 Notificações ${enabled ? 'habilitadas' : 'desabilitadas'}');
  }

  /// Habilita/desabilita abertura automática
  void setAutoOpenEnabled(bool enabled) {
    _isAutoOpenEnabled = enabled;
    Logger.info('📱 Abertura automática ${enabled ? 'habilitada' : 'desabilitada'}');
  }

  /// Limpa todas as notificações
  void clearAllNotifications() {
    try {
      _notificationTimer?.cancel();
      _notificationTimer = null;
      
      if (_context != null) {
        ScaffoldMessenger.of(_context!).clearSnackBars();
      }

      Logger.info('🧹 Todas as notificações limpas');
    } catch (e) {
      Logger.error('❌ Erro ao limpar notificações: $e');
    }
  }

  /// Dispose do serviço
  void dispose() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _context = null;
  }
}
