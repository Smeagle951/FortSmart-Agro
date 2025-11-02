import 'package:flutter/material.dart';
import '../../services/module_colors_service.dart';
import '../../services/module_sync_service.dart';

/// Widget de card de módulo com cores dinâmicas e sincronização
class ModuleCardWidget extends StatefulWidget {
  final String moduleName;
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final ModuleSyncResult? syncResult;
  final bool isLoading;

  const ModuleCardWidget({
    Key? key,
    required this.moduleName,
    required this.title,
    required this.icon,
    this.onTap,
    this.syncResult,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ModuleCardWidget> createState() => _ModuleCardWidgetState();
}

class _ModuleCardWidgetState extends State<ModuleCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ModuleColorsService.getModuleColors(widget.moduleName);
    final status = widget.syncResult?.status ?? ModuleStatus.neutral;
    final statusColor = ModuleColorsService.getStatusColor(widget.moduleName, status);
    final backgroundColor = ModuleColorsService.getBackgroundColor(widget.moduleName, status);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com ícone e status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              if (widget.syncResult != null)
                                Text(
                                  widget.syncResult!.message,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          )
                        else
                          _buildStatusIndicator(status, statusColor),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Detalhes do módulo
                    if (widget.syncResult != null && widget.syncResult!.details != null)
                      _buildModuleDetails(widget.syncResult!.details!, statusColor)
                    else
                      _buildEmptyState(statusColor),
                    
                    const SizedBox(height: 12),
                    
                    // Footer com última sincronização
                    if (widget.syncResult != null)
                      _buildFooter(widget.syncResult!, statusColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(ModuleStatus status, Color statusColor) {
    IconData icon;
    switch (status) {
      case ModuleStatus.active:
        icon = Icons.check_circle;
        break;
      case ModuleStatus.warning:
        icon = Icons.warning;
        break;
      case ModuleStatus.error:
        icon = Icons.error;
        break;
      case ModuleStatus.success:
        icon = Icons.verified;
        break;
      case ModuleStatus.neutral:
        icon = Icons.info;
        break;
    }

    return Icon(
      icon,
      color: statusColor,
      size: 20,
    );
  }

  Widget _buildModuleDetails(Map<String, dynamic> details, Color statusColor) {
    final entries = details.entries.take(3).toList(); // Mostrar apenas 3 detalhes
    
    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '${entry.key}: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor.withOpacity(0.8),
                ),
              ),
              Expanded(
                child: Text(
                  _formatValue(entry.value),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: statusColor.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Clique para sincronizar dados',
              style: TextStyle(
                fontSize: 12,
                color: statusColor.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ModuleSyncResult syncResult, Color statusColor) {
    return Row(
      children: [
        Icon(
          Icons.sync,
          color: statusColor.withOpacity(0.6),
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          'Sincronizado: ${_formatTime(syncResult.lastSync)}',
          style: TextStyle(
            fontSize: 10,
            color: statusColor.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        if (syncResult.dataCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${syncResult.dataCount} itens',
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) return value.toStringAsFixed(1);
    if (value is int) return value.toString();
    return value.toString();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'agora';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m atrás';
    if (difference.inHours < 24) return '${difference.inHours}h atrás';
    return '${difference.inDays}d atrás';
  }
}
