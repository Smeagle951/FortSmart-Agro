import 'dart:io';
import 'package:flutter/material.dart';

/// Wrapper para notificações que não depende de plugins externos
class NotificationsWrapper {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static final List<NotificationData> _pendingNotifications = [];
  static bool _initialized = false;

  /// Obtém a chave do ScaffoldMessenger para ser usada no MaterialApp
  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey => _scaffoldMessengerKey;

  /// Inicializa o sistema de notificações
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
  }

  /// Exibe uma notificação na interface do usuário
  static void showNotification({
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final notification = NotificationData(
      title: title,
      body: body,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );

    if (_scaffoldMessengerKey.currentState != null) {
      _showSnackBarNotification(notification);
    } else {
      _pendingNotifications.add(notification);
    }
  }

  /// Processa notificações pendentes
  static void processPendingNotifications() {
    if (_pendingNotifications.isEmpty) return;
    
    if (_scaffoldMessengerKey.currentState != null) {
      // Exibe a primeira notificação pendente
      final notification = _pendingNotifications.removeAt(0);
      _showSnackBarNotification(notification);
      
      // Agenda as demais notificações com um pequeno atraso entre elas
      for (int i = 0; i < _pendingNotifications.length; i++) {
        Future.delayed(
          Duration(milliseconds: (i + 1) * 500),
          () {
            if (_scaffoldMessengerKey.currentState != null) {
              _showSnackBarNotification(_pendingNotifications[i]);
            }
          },
        );
      }
      
      _pendingNotifications.clear();
    }
  }

  /// Exibe uma notificação como SnackBar
  static void _showSnackBarNotification(NotificationData notification) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(notification.body),
        ],
      ),
      duration: notification.duration,
      action: notification.actionLabel != null && notification.onAction != null
          ? SnackBarAction(
              label: notification.actionLabel!,
              onPressed: notification.onAction!,
            )
          : null,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }
  
  /// Exibe uma mensagem de sucesso
  static void showSuccessMessage(String message) {
    showNotification(
      title: 'Sucesso',
      body: message,
    );
  }
  
  /// Exibe uma mensagem de erro
  static void showErrorMessage(String message) {
    showNotification(
      title: 'Erro',
      body: message,
    );
  }
  
  /// Exibe uma notificação de erro
  static void showErrorNotification(String message, {String? title}) {
    showNotification(
      title: title ?? 'Erro',
      body: message,
    );
  }
  
  /// Exibe um diálogo de confirmação e retorna a escolha do usuário
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Exibe uma notificação usando um contexto específico
  void showNotificationWithContext({
    required BuildContext context,
    required String message,
    String? title,
    NotificationType type = NotificationType.info,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(message),
          ],
        ),
        // backgroundColor: _getColorForType(type), // backgroundColor não é suportado em flutter_map 5.0.0
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Exibe uma notificação na interface do usuário usando um contexto específico
  void showContextNotification(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(message),
        ],
      ),
      duration: duration,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
      default:
        return Colors.blue;
    }
  }
}

/// Dados de uma notificação
class NotificationData {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  NotificationData({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.duration = const Duration(seconds: 4),
  });
}

enum NotificationType { info, success, error, warning }
