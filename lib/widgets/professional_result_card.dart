import 'package:flutter/material.dart';

/// Widget de card profissional para resultados de calibração
class ProfessionalResultCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final String? tooltip;
  final VoidCallback? onTap;
  final bool showGradient;
  final bool showAnimation;

  const ProfessionalResultCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.primaryColor,
    this.secondaryColor,
    this.tooltip,
    this.onTap,
    this.showGradient = true,
    this.showAnimation = true,
  });

  @override
  State<ProfessionalResultCard> createState() => _ProfessionalResultCardState();
}

class _ProfessionalResultCardState extends State<ProfessionalResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    if (widget.showAnimation) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Tooltip(
      message: widget.tooltip ?? widget.title,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: widget.showGradient
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primaryColor.withOpacity(0.1),
                          widget.primaryColor.withOpacity(0.05),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    )
                  : BoxDecoration(
                      color: Colors.white,
                    ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho com ícone e título
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.primaryColor,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Valor principal
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      // Indicador de status (se aplicável)
                      if (widget.onTap != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Toque para detalhes',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para card de status com indicador visual
class StatusIndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final IconData icon;
  final Color statusColor;
  final String? description;

  const StatusIndicatorCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
    required this.statusColor,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ProfessionalResultCard(
      title: title,
      value: value,
      subtitle: status,
      icon: icon,
      primaryColor: statusColor,
      tooltip: description,
      showGradient: true,
    );
  }
}

/// Widget para card de comparação
class ComparisonCard extends StatelessWidget {
  final String title;
  final String currentValue;
  final String targetValue;
  final String unit;
  final IconData icon;
  final Color color;
  final double percentage;

  const ComparisonCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.icon,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentage >= 0;
    final statusColor = isPositive ? Colors.green : Colors.red;
    final statusText = isPositive ? 'Acima da meta' : 'Abaixo da meta';

    return ProfessionalResultCard(
      title: title,
      value: '$currentValue $unit',
      subtitle: 'Meta: $targetValue $unit',
      icon: icon,
      primaryColor: color,
      tooltip: '$statusText (${percentage.abs().toStringAsFixed(1)}%)',
    );
  }
}
