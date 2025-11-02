import 'package:flutter/material.dart';

/// Widget animado para cards da dashboard com mudanças de cor baseadas em dados
class AnimatedDashboardCard extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? activeColor;
  final Color? successColor;
  final bool hasData;
  final bool isActive;
  final Duration animationDuration;
  final VoidCallback? onTap;

  const AnimatedDashboardCard({
    Key? key,
    required this.child,
    this.baseColor,
    this.activeColor,
    this.successColor,
    this.hasData = false,
    this.isActive = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<AnimatedDashboardCard>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late AnimationController _scaleController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _colorController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: widget.baseColor ?? Colors.grey.shade50,
      end: widget.hasData 
          ? (widget.successColor ?? Colors.green.shade50)
          : (widget.activeColor ?? Colors.blue.shade50),
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animação se tiver dados
    if (widget.hasData) {
      _colorController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.hasData != oldWidget.hasData) {
      if (widget.hasData) {
        _colorController.forward();
      } else {
        _colorController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_colorAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: widget.hasData ? 6 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: widget.hasData 
                  ? BorderSide(
                      color: widget.successColor ?? Colors.green,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: widget.hasData ? [
                    BoxShadow(
                      color: (widget.successColor ?? Colors.green).withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ] : null,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cores específicas para cada módulo
class ModuleColors {
  static const Color farm = Color(0xFF4CAF50); // Verde para fazenda
  static const Color alerts = Color(0xFFF44336); // Vermelho para alertas
  static const Color talhoes = Color(0xFF2196F3); // Azul para talhões
  static const Color plantios = Color(0xFF8BC34A); // Verde claro para plantios
  static const Color monitoramento = Color(0xFF9C27B0); // Roxo para monitoramento
  static const Color estoque = Color(0xFFFF9800); // Laranja para estoque
  static const Color weather = Color(0xFF00BCD4); // Ciano para clima
  
  static Color getFarmColor() => farm;
  static Color getAlertsColor() => alerts;
  static Color getTalhoesColor() => talhoes;
  static Color getPlantiosColor() => plantios;
  static Color getMonitoramentoColor() => monitoramento;
  static Color getEstoqueColor() => estoque;
  static Color getWeatherColor() => weather;
}
