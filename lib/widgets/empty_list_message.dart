import 'package:flutter/material.dart';

class EmptyListMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRefresh;
  final String? actionLabel;

  const EmptyListMessage({
    Key? key,
    required this.message,
    this.icon = Icons.info_outline,
    this.onRefresh,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? 'Atualizar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
