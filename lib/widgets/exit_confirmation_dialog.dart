import 'package:flutter/material.dart';

/// Widget para exibir um diálogo de confirmação antes de sair da tela de edição
class ExitConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  
  const ExitConfirmationDialog({
    Key? key,
    this.title = 'Deseja sair?',
    this.message = 'Você tem alterações não salvas. Se sair agora, essas alterações serão perdidas.',
    this.confirmLabel = 'Sair sem salvar',
    this.cancelLabel = 'Continuar editando',
  }) : super(key: key);
  
  /// Método estático para mostrar o diálogo de confirmação
  static Future<bool> show(
    BuildContext context, {
    String title = 'Deseja sair?',
    String message = 'Você tem alterações não salvas. Se sair agora, essas alterações serão perdidas.',
    String confirmLabel = 'Sair sem salvar',
    String cancelLabel = 'Continuar editando',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ExitConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    
    return result ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        // Botão de cancelar
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        
        // Botão de confirmar
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
