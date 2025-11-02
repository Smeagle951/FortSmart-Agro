import 'package:flutter/material.dart';

/// Widget para exibir um botão flutuante de ajuda
class HelpFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  
  const HelpFab({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Ajuda',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'helpFab',
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2196F3),
      tooltip: tooltip,
      child: const Icon(Icons.help_outline),
    );
  }
  
  /// Método estático para mostrar um diálogo de ajuda
  static void showHelpDialog(BuildContext context, {
    required String title,
    required List<HelpItem> items,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: Color(0xFF2196F3),
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => _buildHelpItem(item)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
  
  /// Constrói um item de ajuda com ícone, título e descrição
  static Widget _buildHelpItem(HelpItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: item.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe para representar um item de ajuda
class HelpItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  
  HelpItem({
    required this.icon,
    required this.title,
    required this.description,
    this.color = const Color(0xFF4CAF50),
  });
}
