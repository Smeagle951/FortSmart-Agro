// lib/modules/clima/widgets/alert_banner_widget.dart
import 'package:flutter/material.dart';
import '../clima_theme.dart';
import '../clima_constants.dart';

class AlertBannerWidget extends StatelessWidget {
  final String message;
  final String? alertType;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool dismissible;
  final bool showIcon;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const AlertBannerWidget({
    Key? key,
    required this.message,
    this.alertType,
    this.color,
    this.onTap,
    this.onDismiss,
    this.dismissible = false,
    this.showIcon = true,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alertColor = color ?? _getAlertColor();
    final alertIcon = _getAlertIcon();

    Widget banner = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: ClimaTheme.getAlertDecoration(alertColor: alertColor),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              alertIcon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (alertType != null) ...[
                  Text(
                    _getAlertTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
          if (dismissible && onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      banner = GestureDetector(
        onTap: onTap,
        child: banner,
      );
    }

    return banner;
  }

  Color _getAlertColor() {
    if (alertType != null) {
      return ClimaTheme.getAlertColor(alertType!);
    }
    return Colors.orange.shade600;
  }

  IconData _getAlertIcon() {
    switch (alertType?.toLowerCase()) {
      case 'storm':
      case 'thunderstorm':
        return Icons.flash_on;
      case 'heavy_rain':
      case 'rain':
        return Icons.umbrella;
      case 'frost':
      case 'freeze':
        return Icons.ac_unit;
      case 'high_wind':
      case 'wind':
        return Icons.air;
      case 'extreme_heat':
      case 'heat':
        return Icons.whatshot;
      case 'drought':
        return Icons.water_drop_outlined;
      case 'fog':
      case 'mist':
        return Icons.foggy;
      case 'snow':
        return Icons.snowing;
      default:
        return Icons.warning_rounded;
    }
  }

  String _getAlertTitle() {
    switch (alertType?.toLowerCase()) {
      case 'storm':
      case 'thunderstorm':
        return 'Alerta de Tempestade';
      case 'heavy_rain':
        return 'Chuva Forte';
      case 'rain':
        return 'Chuva Prevista';
      case 'frost':
      case 'freeze':
        return 'Risco de Geada';
      case 'high_wind':
        return 'Vento Forte';
      case 'wind':
        return 'Alerta de Vento';
      case 'extreme_heat':
        return 'Calor Extremo';
      case 'heat':
        return 'Alta Temperatura';
      case 'drought':
        return 'Período Seco';
      case 'fog':
      case 'mist':
        return 'Baixa Visibilidade';
      case 'snow':
        return 'Neve Prevista';
      default:
        return 'Alerta Climático';
    }
  }
}

// Widget para múltiplos alertas
class MultipleAlertsWidget extends StatelessWidget {
  final List<AlertData> alerts;
  final int? maxVisible;
  final VoidCallback? onViewAll;

  const MultipleAlertsWidget({
    Key? key,
    required this.alerts,
    this.maxVisible = 3,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    final visibleAlerts = maxVisible != null && alerts.length > maxVisible!
        ? alerts.take(maxVisible!).toList()
        : alerts;

    final hasMore = maxVisible != null && alerts.length > maxVisible!;

    return Column(
      children: [
        ...visibleAlerts.map((alert) => AlertBannerWidget(
          message: alert.message,
          alertType: alert.type,
          color: alert.color,
          onTap: alert.onTap,
          onDismiss: alert.onDismiss,
          dismissible: alert.dismissible,
        )),
        if (hasMore)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade700.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade500,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver mais ${alerts.length - maxVisible!} alertas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Widget para alertas específicos da agricultura
class AgricultureAlertWidget extends StatelessWidget {
  final String cultura;
  final List<String> alertTypes;
  final VoidCallback? onTap;

  const AgricultureAlertWidget({
    Key? key,
    required this.cultura,
    required this.alertTypes,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alertMessages = alertTypes.map(_getAgriculturalMessage).toList();
    final primaryAlert = alertTypes.first;

    return AlertBannerWidget(
      message: alertMessages.join(' • '),
      alertType: primaryAlert,
      onTap: onTap,
      showIcon: true,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  String _getAgriculturalMessage(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'spray_conditions':
        return 'Condições inadequadas para pulverização';
      case 'irrigation_needed':
        return 'Irrigação recomendada para $cultura';
      case 'harvest_delay':
        return 'Considere adiar a colheita';
      case 'pest_risk':
        return 'Condições favoráveis para pragas';
      case 'disease_risk':
        return 'Risco elevado de doenças';
      case 'planting_optimal':
        return 'Condições ideais para plantio';
      case 'fertilizer_application':
        return 'Momento ideal para adubação';
      default:
        return alertType;
    }
  }
}

// Classe de dados para alertas
class AlertData {
  final String message;
  final String? type;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool dismissible;
  final DateTime? timestamp;
  final String? id;

  AlertData({
    required this.message,
    this.type,
    this.color,
    this.onTap,
    this.onDismiss,
    this.dismissible = false,
    this.timestamp,
    this.id,
  });

  factory AlertData.fromClima(String message, String type) {
    return AlertData(
      message: message,
      type: type,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

// Widget animado para alertas críticos
class CriticalAlertWidget extends StatefulWidget {
  final String message;
  final String alertType;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const CriticalAlertWidget({
    Key? key,
    required this.message,
    required this.alertType,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<CriticalAlertWidget> createState() => _CriticalAlertWidgetState();
}

class _CriticalAlertWidgetState extends State<CriticalAlertWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: AlertBannerWidget(
            message: widget.message,
            alertType: widget.alertType,
            onTap: widget.onTap,
            onDismiss: widget.onDismiss,
            dismissible: true,
            color: Colors.red.shade700,
            padding: const EdgeInsets.all(20),
          ),
        );
      },
    );
  }
}
