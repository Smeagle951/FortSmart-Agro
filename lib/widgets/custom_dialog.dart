import 'package:flutter/material.dart';

/// Classe utilitária para exibir diálogos padronizados no aplicativo
class CustomDialog {
  /// Exibe um diálogo customizado
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String primaryButtonText = 'OK',
    String? secondaryButtonText,
    VoidCallback? onPrimaryButtonPressed,
    VoidCallback? onSecondaryButtonPressed,
    bool barrierDismissible = true,
    Widget? customContent,
    bool showCloseButton = false,
    bool isDestructiveAction = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            if (showCloseButton)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
          ],
        ),
        content: customContent ?? Text(message),
        actions: [
          if (secondaryButtonText != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onSecondaryButtonPressed?.call();
              },
              child: Text(secondaryButtonText),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onPrimaryButtonPressed?.call();
            },
            style: isDestructiveAction ? ElevatedButton.styleFrom(
              // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
              foregroundColor: Colors.white,
            ) : null,
            child: Text(primaryButtonText),
          ),
        ],
      ),
    );
  }
  
  /// Exibe um diálogo de confirmação
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  /// Exibe um diálogo de erro
  static Future<void> showError(
    BuildContext context, {
    String title = 'Erro',
    required String message,
    String buttonText = 'OK',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      primaryButtonText: buttonText,
    );
  }
  
  /// Exibe um diálogo de sucesso
  static Future<void> showSuccess(
    BuildContext context, {
    String title = 'Sucesso',
    required String message,
    String buttonText = 'OK',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      primaryButtonText: buttonText,
    );
  }
}
