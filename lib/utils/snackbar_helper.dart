import 'package:flutter/material.dart';
import '../widgets/safe_text.dart';

/// Classe auxiliar para exibir snackbars padronizados
class SnackbarHelper {
  /// Exibe um snackbar de sucesso
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: SafeText(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Exibe um snackbar de erro
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: SafeText(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Exibe um snackbar de informação
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: SafeText(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Exibe um snackbar de aviso
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: SafeText(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Exibe um snackbar com ação
  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color backgroundColor = Colors.blueGrey,
    Duration duration = const Duration(seconds: 6),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SafeText(message, style: const TextStyle(color: Colors.white)),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Exibe um snackbar de carregamento
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message,
  ) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: SafeText(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.grey.shade800,
        duration: const Duration(days: 1), // Longa duração, deve ser fechado manualmente
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Fecha qualquer snackbar ativo
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Métodos simplificados para uso nas novas telas
  
  /// Exibe um snackbar de sucesso (versão simplificada)
  static void showSuccessSnackbar(BuildContext context, String message) {
    showSuccess(context, message);
  }
  
  /// Exibe um snackbar de erro (versão simplificada)
  static void showErrorSnackbar(BuildContext context, String message) {
    showError(context, message);
  }
  
  /// Exibe um snackbar de informação (versão simplificada)
  static void showInfoSnackbar(BuildContext context, String message) {
    showInfo(context, message);
  }
  
  /// Exibe um snackbar de aviso (versão simplificada)
  static void showWarningSnackbar(BuildContext context, String message) {
    showWarning(context, message);
  }
}
