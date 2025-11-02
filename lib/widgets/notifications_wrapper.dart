import 'package:flutter/material.dart';

class NotificationsWrapper {
  void showNotification(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
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
      // backgroundColor: isError ? Colors.red : Colors.green, // backgroundColor não é suportado em flutter_map 5.0.0
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Método para mostrar mensagem de erro
  void showError(BuildContext context, String message) {
    showNotification(
      context,
      title: 'Erro',
      message: message,
      isError: true,
    );
  }

  // Método para mostrar mensagem de sucesso
  void showSuccess(BuildContext context, String message) {
    showNotification(
      context,
      title: 'Sucesso',
      message: message,
      isError: false,
    );
  }

  // Método para mostrar mensagem informativa
  void showInfo(BuildContext context, String message) {
    showNotification(
      context,
      title: 'Informação',
      message: message,
      isError: false,
      duration: const Duration(seconds: 5),
    );
  }

  void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}
