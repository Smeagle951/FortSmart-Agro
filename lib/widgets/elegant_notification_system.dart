import 'package:flutter/material.dart';
import 'dart:async';

/// Sistema de notificações elegantes com animações avançadas
class ElegantNotificationSystem {
  static OverlayEntry? _currentOverlay;
  static Timer? _hideTimer;
  
  /// Exibe uma notificação elegante com animação
  static void showElegantNotification({
    required BuildContext context,
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool dismissible = true,
  }) {
    // Remover notificação anterior se existir
    _hideCurrentNotification();
    
    // Criar overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => _ElegantNotificationWidget(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: dismissible ? _hideCurrentNotification : null,
      ),
    );
    
    // Inserir no overlay
    Overlay.of(context).insert(_currentOverlay!);
    
    // Auto-hide após duração especificada
    _hideTimer = Timer(duration, _hideCurrentNotification);
  }
  
  /// Esconde a notificação atual
  static void _hideCurrentNotification() {
    _hideTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
  
  /// Notificação de sucesso
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showElegantNotification(
      context: context,
      message: message,
      type: NotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Notificação de erro
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showElegantNotification(
      context: context,
      message: message,
      type: NotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Notificação de informação
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showElegantNotification(
      context: context,
      message: message,
      type: NotificationType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Notificação de aviso
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showElegantNotification(
      context: context,
      message: message,
      type: NotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Tipos de notificação
enum NotificationType {
  success,
  error,
  info,
  warning,
}

/// Widget de notificação elegante
class _ElegantNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  
  const _ElegantNotificationWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });
  
  @override
  State<_ElegantNotificationWidget> createState() => _ElegantNotificationWidgetState();
}

class _ElegantNotificationWidgetState extends State<_ElegantNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Controllers de animação
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Animações
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Iniciar animações
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildNotificationCard(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotificationCard() {
    final colors = _getColorsForType();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors['shadow']!,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colors['border']!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors['iconBackground'],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForType(),
              color: colors['icon'],
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTitleForType(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors['text'],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors['text']!.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Botão de ação (se fornecido)
          if (widget.actionLabel != null && widget.onAction != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: widget.onAction,
                style: TextButton.styleFrom(
                  backgroundColor: colors['actionBackground'],
                  foregroundColor: colors['actionText'],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.actionLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          // Botão de fechar (se dismissible)
          if (widget.onDismiss != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: IconButton(
                onPressed: widget.onDismiss,
                icon: Icon(
                  Icons.close,
                  color: colors['text']!.withOpacity(0.6),
                  size: 18,
                ),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
  
  Map<String, Color> _getColorsForType() {
    switch (widget.type) {
      case NotificationType.success:
        return {
          'background': Colors.green.shade50,
          'border': Colors.green.shade200,
          'shadow': Colors.green.withOpacity(0.2),
          'iconBackground': Colors.green.shade100,
          'icon': Colors.green.shade700,
          'text': Colors.green.shade900,
          'actionBackground': Colors.green.shade600,
          'actionText': Colors.white,
        };
      case NotificationType.error:
        return {
          'background': Colors.red.shade50,
          'border': Colors.red.shade200,
          'shadow': Colors.red.withOpacity(0.2),
          'iconBackground': Colors.red.shade100,
          'icon': Colors.red.shade700,
          'text': Colors.red.shade900,
          'actionBackground': Colors.red.shade600,
          'actionText': Colors.white,
        };
      case NotificationType.warning:
        return {
          'background': Colors.orange.shade50,
          'border': Colors.orange.shade200,
          'shadow': Colors.orange.withOpacity(0.2),
          'iconBackground': Colors.orange.shade100,
          'icon': Colors.orange.shade700,
          'text': Colors.orange.shade900,
          'actionBackground': Colors.orange.shade600,
          'actionText': Colors.white,
        };
      case NotificationType.info:
        return {
          'background': Colors.blue.shade50,
          'border': Colors.blue.shade200,
          'shadow': Colors.blue.withOpacity(0.2),
          'iconBackground': Colors.blue.shade100,
          'icon': Colors.blue.shade700,
          'text': Colors.blue.shade900,
          'actionBackground': Colors.blue.shade600,
          'actionText': Colors.white,
        };
    }
  }
  
  IconData _getIconForType() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }
  
  String _getTitleForType() {
    switch (widget.type) {
      case NotificationType.success:
        return 'Sucesso';
      case NotificationType.error:
        return 'Erro';
      case NotificationType.warning:
        return 'Atenção';
      case NotificationType.info:
        return 'Informação';
    }
  }
}
