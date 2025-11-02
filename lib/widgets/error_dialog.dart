import 'package:flutter/material.dart';

/// Widget para exibir um diálogo de erro padronizado
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorDialog({
    Key? key,
    this.title = 'Erro',
    required this.message,
    this.onRetry,
  }) : super(key: key);
  
  /// Método estático para mostrar o diálogo de erro
  static Future<void> show(
    BuildContext context, {
    String title = 'Erro',
    required String message,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            child: const Text('Tentar Novamente'),
          ),
      ],
    );
  }
}
