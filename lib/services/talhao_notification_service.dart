import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Serviço para gerenciar notificações e mensagens de sucesso dos talhões
/// Inclui persistência e histórico de mensagens
class TalhaoNotificationService {
  static const String _keyNotifications = 'talhao_notifications';
  static const String _keySuccessMessages = 'talhao_success_messages';
  static const String _keyErrorMessages = 'talhao_error_messages';
  
  /// Exibe uma mensagem de sucesso persistente
  Future<void> showSuccessMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
    bool persist = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    // Salvar mensagem se persistir
    if (persist) {
      await _saveSuccessMessage(message);
    }
    
    // Exibir SnackBar usando o contexto global
    _showSnackBar(
      message,
      backgroundColor: Colors.green[600]!,
      icon: Icons.check_circle,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Exibe uma mensagem de erro persistente
  Future<void> showErrorMessage(
    String message, {
    Duration duration = const Duration(seconds: 5),
    bool persist = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    // Salvar mensagem se persistir
    if (persist) {
      await _saveErrorMessage(message);
    }
    
    // Exibir SnackBar usando o contexto global
    _showSnackBar(
      message,
      backgroundColor: Colors.red[600]!,
      icon: Icons.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Exibe uma notificação informativa
  Future<void> showInfoMessage(
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool persist = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    // Salvar mensagem se persistir
    if (persist) {
      await _saveNotification(message, 'info');
    }
    
    // Exibir SnackBar usando o contexto global
    _showSnackBar(
      message,
      backgroundColor: Colors.blue[600]!,
      icon: Icons.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Exibe uma notificação de aviso
  Future<void> showWarningMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
    bool persist = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    // Salvar mensagem se persistir
    if (persist) {
      await _saveNotification(message, 'warning');
    }
    
    // Exibir SnackBar usando o contexto global
    _showSnackBar(
      message,
      backgroundColor: Colors.orange[600]!,
      icon: Icons.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Exibe um diálogo de confirmação
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    Color? cancelColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: confirmColor ?? Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(color: cancelColor ?? Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Exibe um diálogo de sucesso
  Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
  
  /// Exibe uma mensagem usando SnackBar global
  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    try {
      // Verificar se o contexto está disponível
      final context = navigatorKey.currentContext;
      if (context == null) {
        // Fallback para print se não há contexto disponível
        print('📱 NOTIFICAÇÃO: $message');
        return;
      }
      
      // Usar o ScaffoldMessenger global se disponível
      final messenger = ScaffoldMessenger.of(context);
      
      final snackBar = SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      );
      
      messenger.showSnackBar(snackBar);
    } catch (e) {
      // Fallback para print em caso de erro
      print('❌ Erro ao exibir notificação: $e');
      print('📱 NOTIFICAÇÃO: $message');
    }
  }
  
  // Chave global para acessar o contexto
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Salva uma mensagem de sucesso
  Future<void> _saveSuccessMessage(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messages = prefs.getStringList(_keySuccessMessages) ?? [];
      messages.add('${DateTime.now().toIso8601String()}: $message');
      
      // Manter apenas as últimas 100 mensagens
      if (messages.length > 100) {
        messages.removeRange(0, messages.length - 100);
      }
      
      await prefs.setStringList(_keySuccessMessages, messages);
    } catch (e) {
      debugPrint('❌ Erro ao salvar mensagem de sucesso: $e');
    }
  }
  
  /// Salva uma mensagem de erro
  Future<void> _saveErrorMessage(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messages = prefs.getStringList(_keyErrorMessages) ?? [];
      messages.add('${DateTime.now().toIso8601String()}: $message');
      
      // Manter apenas as últimas 100 mensagens
      if (messages.length > 100) {
        messages.removeRange(0, messages.length - 100);
      }
      
      await prefs.setStringList(_keyErrorMessages, messages);
    } catch (e) {
      debugPrint('❌ Erro ao salvar mensagem de erro: $e');
    }
  }
  
  /// Salva uma notificação genérica
  Future<void> _saveNotification(String message, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList(_keyNotifications) ?? [];
      
      final notification = {
        'message': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      notifications.add(jsonEncode(notification));
      
      // Manter apenas as últimas 100 notificações
      if (notifications.length > 100) {
        notifications.removeRange(0, notifications.length - 100);
      }
      
      await prefs.setStringList(_keyNotifications, notifications);
    } catch (e) {
      debugPrint('❌ Erro ao salvar notificação: $e');
    }
  }
  
  /// Obtém todas as mensagens de sucesso
  Future<List<String>> getSuccessMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keySuccessMessages) ?? [];
    } catch (e) {
      debugPrint('❌ Erro ao obter mensagens de sucesso: $e');
      return [];
    }
  }
  
  /// Obtém todas as mensagens de erro
  Future<List<String>> getErrorMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_keyErrorMessages) ?? [];
    } catch (e) {
      debugPrint('❌ Erro ao obter mensagens de erro: $e');
      return [];
    }
  }
  
  /// Obtém todas as notificações
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList(_keyNotifications) ?? [];
      
      return notifications.map((notification) {
        try {
          return jsonDecode(notification) as Map<String, dynamic>;
        } catch (e) {
          return <String, dynamic>{
            'message': notification,
            'type': 'unknown',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao obter notificações: $e');
      return [];
    }
  }
  
  /// Obtém todas as mensagens
  Future<List<Map<String, dynamic>>> getAllMessages() async {
    final successMessages = await getSuccessMessages();
    final errorMessages = await getErrorMessages();
    final notifications = await getNotifications();
    
    final allMessages = <Map<String, dynamic>>[];
    
    // Adicionar mensagens de sucesso
    for (final message in successMessages) {
      allMessages.add({
        'message': message,
        'type': 'success',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    // Adicionar mensagens de erro
    for (final message in errorMessages) {
      allMessages.add({
        'message': message,
        'type': 'error',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    // Adicionar notificações
    allMessages.addAll(notifications);
    
    // Ordenar por timestamp
    allMessages.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return bTime.compareTo(aTime);
    });
    
    return allMessages;
  }
  
  /// Limpa todas as mensagens
  Future<void> clearAllMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySuccessMessages);
      await prefs.remove(_keyErrorMessages);
      await prefs.remove(_keyNotifications);
    } catch (e) {
      debugPrint('❌ Erro ao limpar mensagens: $e');
    }
  }
  
  /// Obtém estatísticas das mensagens
  Future<Map<String, dynamic>> getMessageStats() async {
    try {
      final successMessages = await getSuccessMessages();
      final errorMessages = await getErrorMessages();
      final notifications = await getNotifications();
      
      return {
        'total': successMessages.length + errorMessages.length + notifications.length,
        'success': successMessages.length,
        'error': errorMessages.length,
        'notifications': notifications.length,
        'lastSuccess': successMessages.isNotEmpty ? successMessages.last : null,
        'lastError': errorMessages.isNotEmpty ? errorMessages.last : null,
      };
    } catch (e) {
      debugPrint('❌ Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'success': 0,
        'error': 0,
        'notifications': 0,
        'lastSuccess': null,
        'lastError': null,
      };
    }
  }
  
  /// Exibe histórico de mensagens
  Future<void> showMessageHistory(BuildContext context) async {
    final messages = await getAllMessages();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Histórico de Mensagens'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final type = message['type'] ?? 'unknown';
                final text = message['message'] ?? '';
                final timestamp = message['timestamp'] ?? '';
                
                Color color;
                IconData icon;
                
                switch (type) {
                  case 'success':
                    color = Colors.green;
                    icon = Icons.check_circle;
                    break;
                  case 'error':
                    color = Colors.red;
                    icon = Icons.error;
                    break;
                  case 'info':
                    color = Colors.blue;
                    icon = Icons.info;
                    break;
                  case 'warning':
                    color = Colors.orange;
                    icon = Icons.warning;
                    break;
                  default:
                    color = Colors.grey;
                    icon = Icons.message;
                }
                
                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(text),
                  subtitle: Text(timestamp),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      // Implementar remoção individual
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await clearAllMessages();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Limpar Tudo'),
            ),
          ],
        ),
      );
    }
  }
}
