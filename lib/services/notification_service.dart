import 'dart:async';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar notificações locais no aplicativo
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  // final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final StreamController<String?> _notificationStreamController = StreamController<String?>.broadcast();
  
  /// Stream para ouvir eventos de notificações
  Stream<String?> get notificationStream => _notificationStreamController.stream;
  
  bool _initialized = false;
  
  // Singleton pattern
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      Logger.log('Inicializando serviço de notificações...');
      
      // Configuração temporariamente comentada
      /*
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings();
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _onNotificationTapped(response.payload);
        },
      );
      */
      
      _initialized = true;
      Logger.log('Serviço de notificações inicializado com sucesso');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de notificações: $e');
    }
  }
  
  /// Callback para quando uma notificação é tocada
  void _onNotificationTapped(String? payload) {
    _notificationStreamController.add(payload);
  }
  
  /// Exibe uma notificação
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationImportance importance = NotificationImportance.normal,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      Logger.log('Exibindo notificação: $title');
      
      // Exibição de notificação temporariamente comentada
      /*
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'fortsmartagro_channel',
        'Notificações FortSmartAgro',
        channelDescription: 'Canal para notificações do aplicativo FortSmartAgro',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      */
      
      // Apenas log para desenvolvimento
      Logger.log('Notificação: $title - $body');
      if (payload != null) {
        _onNotificationTapped(payload);
      }
    } catch (e) {
      Logger.error('Erro ao exibir notificação: $e');
    }
  }
  
  /// Cancela uma notificação específica
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    
    try {
      // await _flutterLocalNotificationsPlugin.cancel(id);
      Logger.log('Notificação $id cancelada');
    } catch (e) {
      Logger.error('Erro ao cancelar notificação: $e');
    }
  }
  
  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    
    try {
      // await _flutterLocalNotificationsPlugin.cancelAll();
      Logger.log('Todas as notificações canceladas');
    } catch (e) {
      Logger.error('Erro ao cancelar todas as notificações: $e');
    }
  }
  
  /// Converte a importância do modelo para a importância do Android
  int _getAndroidImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.low:
        return 0; // Importance.min
      case NotificationImportance.normal:
        return 3; // Importance.defaultImportance
      case NotificationImportance.medium:
        return 3; // Importance.defaultImportance
      case NotificationImportance.high:
        return 4; // Importance.high
      case NotificationImportance.critical:
        return 5; // Importance.max
    }
  }
  
  /// Converte a importância do modelo para a prioridade do Android
  int _getAndroidPriority(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.low:
        return 0; // Priority.min
      case NotificationImportance.normal:
        return 0; // Priority.defaultPriority
      case NotificationImportance.medium:
        return 0; // Priority.defaultPriority
      case NotificationImportance.high:
        return 1; // Priority.high
      case NotificationImportance.critical:
        return 2; // Priority.max
    }
  }
  
  /// Fecha o stream controller
  void dispose() {
    _notificationStreamController.close();
  }
}
