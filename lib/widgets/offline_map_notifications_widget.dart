import 'package:flutter/material.dart';

/// Widget para notificações de mapas offline
class OfflineMapNotificationsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback? onClearAll;
  final Function(String)? onDismiss;

  const OfflineMapNotificationsWidget({
    Key? key,
    required this.notifications,
    this.onClearAll,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<OfflineMapNotificationsWidget> createState() => _OfflineMapNotificationsWidgetState();
}

class _OfflineMapNotificationsWidgetState extends State<OfflineMapNotificationsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Notificações',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  if (widget.onClearAll != null)
                    TextButton(
                      onPressed: widget.onClearAll,
                      child: const Text('Limpar Todas'),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Lista de notificações
              ...widget.notifications.map((notification) => 
                _buildNotificationItem(notification)
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item de notificação
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'info';
    final title = notification['title'] ?? 'Notificação';
    final message = notification['message'] ?? '';
    final timestamp = notification['timestamp'] ?? DateTime.now();
    final isRead = notification['isRead'] ?? false;

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
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'info':
      default:
        color = Colors.blue;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRead ? Colors.grey[300]! : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (widget.onDismiss != null)
            IconButton(
              onPressed: () => widget.onDismiss!(notification['id']),
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Dispensar',
            ),
        ],
      ),
    );
  }

  /// Formata timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}
