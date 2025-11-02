import 'package:flutter/material.dart';

/// Indicador elegante do status GPS com animações
class ElegantGpsIndicator extends StatefulWidget {
  final bool isActive;
  final bool isPaused;
  final double? accuracy;
  final VoidCallback? onTap;

  const ElegantGpsIndicator({
    super.key,
    required this.isActive,
    this.isPaused = false,
    this.accuracy,
    this.onTap,
  });

  @override
  State<ElegantGpsIndicator> createState() => _ElegantGpsIndicatorState();
}

class _ElegantGpsIndicatorState extends State<ElegantGpsIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.isActive && !widget.isPaused) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ElegantGpsIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !widget.isPaused) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _pulseController.stop();
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();
    final statusIcon = _getStatusIcon();

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive && !widget.isPaused ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (widget.isActive && !widget.isPaused)
                  BoxShadow(
                    color: statusColor.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone animado
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: widget.isActive && !widget.isPaused 
                              ? _rotationAnimation.value * 2 * 3.14159 
                              : 0,
                          child: Icon(
                            statusIcon,
                            color: Colors.white,
                            size: 18,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Texto do status
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    // Indicador de precisão
                    if (widget.accuracy != null && widget.isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.accuracy!.toStringAsFixed(1)}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    if (!widget.isActive) return Colors.grey;
    if (widget.isPaused) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (!widget.isActive) return 'GPS Inativo';
    if (widget.isPaused) return 'GPS Pausado';
    return 'GPS Ativo';
  }

  IconData _getStatusIcon() {
    if (!widget.isActive) return Icons.gps_off;
    if (widget.isPaused) return Icons.pause;
    return Icons.gps_fixed;
  }
}
