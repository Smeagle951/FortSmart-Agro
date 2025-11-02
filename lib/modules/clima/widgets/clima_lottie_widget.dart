// lib/modules/clima/widgets/clima_lottie_widget.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../clima_constants.dart';

class ClimaLottieWidget extends StatelessWidget {
  final String iconCode;
  final double size;
  final bool animate;
  final bool repeat;
  final BoxFit fit;
  final Color? color;
  final Duration? duration;

  const ClimaLottieWidget({
    Key? key,
    required this.iconCode,
    this.size = 180,
    this.animate = true,
    this.repeat = true,
    this.fit = BoxFit.contain,
    this.color,
    this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileName = ClimaConstants.weatherIconMap[iconCode] ?? 'partly_cloudy.json';
    final assetPath = 'assets/lottie/$fileName';

    return Container(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        animate: animate,
        repeat: repeat,
        duration: duration,
        // Fallback em caso de erro ao carregar Lottie
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
        // Configurações de performance
        options: LottieOptions(
          enableMergePaths: true,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    IconData fallbackIcon;
    Color fallbackColor = color ?? Colors.white;

    // Mapear ícones de fallback baseados no código do clima
    switch (iconCode.substring(0, 2)) {
      case '01': // Céu limpo
        fallbackIcon = ClimaConstants.isDayTime(iconCode) 
          ? Icons.wb_sunny 
          : Icons.brightness_3;
        fallbackColor = ClimaConstants.isDayTime(iconCode) 
          ? Colors.orange 
          : Colors.indigo;
        break;
      case '02': // Parcialmente nublado
        fallbackIcon = ClimaConstants.isDayTime(iconCode) 
          ? Icons.wb_cloudy 
          : Icons.cloud;
        fallbackColor = Colors.grey.shade300;
        break;
      case '03': // Nublado
      case '04':
        fallbackIcon = Icons.cloud;
        fallbackColor = Colors.grey.shade400;
        break;
      case '09': // Chuva leve
        fallbackIcon = Icons.grain;
        fallbackColor = Colors.blue.shade300;
        break;
      case '10': // Chuva
        fallbackIcon = Icons.umbrella;
        fallbackColor = Colors.blue.shade600;
        break;
      case '11': // Tempestade
        fallbackIcon = Icons.flash_on;
        fallbackColor = Colors.yellow.shade600;
        break;
      case '13': // Neve
        fallbackIcon = Icons.ac_unit;
        fallbackColor = Colors.white;
        break;
      case '50': // Névoa
        fallbackIcon = Icons.foggy;
        fallbackColor = Colors.grey.shade300;
        break;
      default:
        fallbackIcon = Icons.wb_cloudy;
        fallbackColor = Colors.grey.shade300;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Icon(
        fallbackIcon,
        size: size * 0.6,
        color: fallbackColor,
      ),
    );
  }
}

// Widget especializado para ícones pequenos (cards secundários)
class ClimaIconeWidget extends StatelessWidget {
  final String iconCode;
  final double size;
  final Color? color;

  const ClimaIconeWidget({
    Key? key,
    required this.iconCode,
    this.size = 40,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClimaLottieWidget(
      iconCode: iconCode,
      size: size,
      animate: true,
      repeat: true,
      color: color,
      duration: const Duration(seconds: 2), // Animação mais rápida para ícones pequenos
    );
  }
}

// Widget para animação de transição entre estados climáticos
class ClimaTransitionWidget extends StatefulWidget {
  final String fromIconCode;
  final String toIconCode;
  final double size;
  final Duration transitionDuration;
  final VoidCallback? onTransitionComplete;

  const ClimaTransitionWidget({
    Key? key,
    required this.fromIconCode,
    required this.toIconCode,
    this.size = 180,
    this.transitionDuration = const Duration(milliseconds: 500),
    this.onTransitionComplete,
  }) : super(key: key);

  @override
  State<ClimaTransitionWidget> createState() => _ClimaTransitionWidgetState();
}

class _ClimaTransitionWidgetState extends State<ClimaTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showSecondIcon = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showSecondIcon = true;
        });
        _fadeController.reverse().then((_) {
          if (widget.onTransitionComplete != null) {
            widget.onTransitionComplete!();
          }
        });
      }
    });

    // Iniciar transição automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: ClimaLottieWidget(
            iconCode: _showSecondIcon ? widget.toIconCode : widget.fromIconCode,
            size: widget.size,
          ),
        );
      },
    );
  }
}

// Widget para mostrar múltiplas condições climáticas (previsão)
class ClimaPrevisaoWidget extends StatelessWidget {
  final List<String> iconCodes;
  final double itemSize;
  final double spacing;
  final Axis direction;

  const ClimaPrevisaoWidget({
    Key? key,
    required this.iconCodes,
    this.itemSize = 60,
    this.spacing = 8,
    this.direction = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widgets = iconCodes.map((iconCode) {
      return ClimaIconeWidget(
        iconCode: iconCode,
        size: itemSize,
      );
    }).toList();

    return direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: _addSpacing(widgets),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: _addSpacing(widgets),
          );
  }

  List<Widget> _addSpacing(List<Widget> widgets) {
    final spacedWidgets = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      spacedWidgets.add(widgets[i]);
      if (i < widgets.length - 1) {
        spacedWidgets.add(direction == Axis.horizontal
            ? SizedBox(width: spacing)
            : SizedBox(height: spacing));
      }
    }
    return spacedWidgets;
  }
}
