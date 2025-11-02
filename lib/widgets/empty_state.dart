import 'package:flutter/material.dart';

/// Widget para exibir um estado vazio com ícone, mensagem e botão opcional
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final String? buttonLabel;
  final String? buttonText; 
  final VoidCallback? onButtonPressed;
  final String? actionText; 
  final VoidCallback? onAction; 

  const EmptyState({
    Key? key,
    required this.icon,
    this.title,
    required this.message,
    this.buttonLabel,
    this.buttonText, 
    this.onButtonPressed,
    this.actionText,
    this.onAction,
    // Parâmetro onPressed removido pois não é utilizado no corpo do widget
    // Anteriormente: required Null Function() onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null || buttonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(buttonLabel ?? buttonText ?? ''),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
