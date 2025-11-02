import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'weather_animations.dart';
import 'weather_animation_config.dart';

/// Widget que combina diferentes tipos de animações climáticas
/// baseado nas configurações do usuário e nas condições climáticas
class CombinedWeatherAnimation extends StatefulWidget {
  final String condition;
  final double size;
  final Color? color;
  final WeatherAnimationConfig config;
  
  const CombinedWeatherAnimation({
    Key? key,
    required this.condition,
    this.size = 150,
    this.color,
    required this.config,
  }) : super(key: key);
  
  @override
  State<CombinedWeatherAnimation> createState() => _CombinedWeatherAnimationState();
}

class _CombinedWeatherAnimationState extends State<CombinedWeatherAnimation> {
  late AnimationType _effectiveAnimationType;
  
  @override
  void initState() {
    super.initState();
    _updateEffectiveAnimationType();
  }
  
  @override
  void didUpdateWidget(CombinedWeatherAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition != widget.condition || 
        oldWidget.config.animationType != widget.config.animationType ||
        oldWidget.config.highPerformanceMode != widget.config.highPerformanceMode) {
      _updateEffectiveAnimationType();
    }
  }
  
  void _updateEffectiveAnimationType() {
    _effectiveAnimationType = widget.config.getEffectiveAnimationType(widget.condition);
  }
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? _getDefaultColorForCondition(widget.condition);
    
    // Seleciona o tipo de animação com base na configuração
    switch (_effectiveAnimationType) {
      case AnimationType.lottie:
        return _buildLottieAnimation();
        
      case AnimationType.rive:
        return _buildRiveAnimation();
        
      case AnimationType.flutterAnimate:
        return _buildFlutterAnimateWidget(effectiveColor);
        
      case AnimationType.customPainter:
        return _buildCustomPainterAnimation(effectiveColor);
        
      case AnimationType.hybrid:
        return _buildHybridAnimation(effectiveColor);
        
      default:
        // Fallback para CustomPainter se algo der errado
        return _buildCustomPainterAnimation(effectiveColor);
    }
  }
  
  Widget _buildLottieAnimation() {
    // Por enquanto, usar ícones até implementar Lottie
    return _buildIconAnimation();
  }
  
  Widget _buildRiveAnimation() {
    // Por enquanto, usar ícones até implementar Rive
    return _buildIconAnimation();
  }
  
  Widget _buildIconAnimation() {
    final condition = widget.condition.toLowerCase();
    IconData icon;
    Color color;
    
    if (condition.contains('chuva') || condition.contains('chuvisco')) {
      icon = Icons.grain;
      color = Colors.blue[400]!;
    } else if (condition.contains('tempestade') || condition.contains('trovoada')) {
      icon = Icons.flash_on;
      color = Colors.amber;
    } else if (condition.contains('nublado') || condition.contains('nuvens')) {
      icon = Icons.cloud;
      color = Colors.grey[400]!;
    } else if (condition.contains('neve')) {
      icon = Icons.ac_unit;
      color = Colors.white;
    } else if (condition.contains('neblina') || condition.contains('nevoeiro')) {
      icon = Icons.foggy;
      color = Colors.grey[300]!;
    } else {
      icon = Icons.wb_sunny;
      color = Colors.amber;
    }
    
    return Container(
      width: widget.size,
      height: widget.size,
      child: Icon(
        icon,
        size: widget.size * 0.7,
        color: color,
      ),
    );
  }
  
  Widget _buildFlutterAnimateWidget(Color color) {
    final condition = widget.condition.toLowerCase();
    
    if (condition.contains('chuva') || condition.contains('chuvisco')) {
      return _buildRainAnimation(color);
    } else if (condition.contains('tempestade') || condition.contains('trovoada')) {
      return _buildThunderstormAnimation(color);
    } else if (condition.contains('nublado') || condition.contains('nuvens')) {
      return _buildCloudyAnimation(color);
    } else if (condition.contains('neve')) {
      return _buildSnowAnimation(color);
    } else if (condition.contains('neblina') || condition.contains('nevoeiro')) {
      return _buildFogAnimation(color);
    } else {
      return _buildSunnyAnimation(color);
    }
  }
  
  Widget _buildRainAnimation(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Icon(
            Icons.cloud,
            size: widget.size * 0.8,
            color: Colors.grey[400],
          )
              .animate(onPlay: (controller) => controller.repeat())
              .moveY(begin: -5, end: 0, duration: 2000.ms, curve: Curves.easeInOut)
              .then(delay: 100.ms)
              .moveY(begin: 0, end: -5, duration: 2000.ms, curve: Curves.easeInOut),
          ...List.generate(
            10,
            (index) => Positioned(
              left: (widget.size / 10) * index,
              top: (index % 3) * 10.0,
              child: Container(
                width: 2,
                height: 10,
                color: Colors.blue[400],
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                    delay: (index * 100).ms,
                  )
                  .moveY(
                    begin: 0,
                    end: widget.size,
                    duration: 1500.ms,
                    curve: Curves.easeIn,
                  )
                  .fadeOut(begin: 1.0, duration: 1500.ms),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThunderstormAnimation(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Icon(
            Icons.cloud,
            size: widget.size * 0.8,
            color: Colors.grey[700],
          ),
          Positioned(
            left: widget.size * 0.4,
            top: widget.size * 0.5,
            child: Icon(
              Icons.flash_on,
              size: widget.size * 0.4,
              color: Colors.amber,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 200.ms)
                .then(delay: 200.ms)
                .fadeOut(duration: 200.ms)
                .then(delay: 500.ms),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCloudyAnimation(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: widget.size * 0.3,
            child: Icon(
              Icons.cloud,
              size: widget.size * 0.6,
              color: Colors.grey[400],
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveX(begin: -20, end: 20, duration: 5000.ms, curve: Curves.easeInOut)
                .then()
                .moveX(begin: 20, end: -20, duration: 5000.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            right: 0,
            top: widget.size * 0.2,
            child: Icon(
              Icons.cloud,
              size: widget.size * 0.5,
              color: Colors.grey[300],
            )
                .animate(onPlay: (controller) => controller.repeat())
                .moveX(begin: 20, end: -20, duration: 7000.ms, curve: Curves.easeInOut)
                .then()
                .moveX(begin: -20, end: 20, duration: 7000.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSnowAnimation(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Icon(
            Icons.cloud,
            size: widget.size * 0.8,
            color: Colors.grey[300],
          ),
          ...List.generate(
            8,
            (index) => Positioned(
              left: (widget.size / 8) * index + (index % 2 == 0 ? 5 : 0),
              top: 0,
              child: Icon(
                Icons.ac_unit,
                size: 10 + (index % 3) * 2.0,
                color: Colors.white,
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                    delay: (index * 200).ms,
                  )
                  .moveY(
                    begin: widget.size * 0.3,
                    end: widget.size,
                    duration: 2000.ms + (index * 100).ms,
                    curve: Curves.easeIn,
                  )
                  .rotate(begin: 0, end: 1),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFogAnimation(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          ...List.generate(
            3,
            (index) => Positioned(
              left: 0,
              top: widget.size * (0.3 + index * 0.2),
              child: Container(
                width: widget.size,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey[300]!.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .moveX(
                    begin: -widget.size * 0.2,
                    end: widget.size * 0.2,
                    duration: 3000.ms + (index * 500).ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .moveX(
                    begin: widget.size * 0.2,
                    end: -widget.size * 0.2,
                    duration: 3000.ms + (index * 500).ms,
                    curve: Curves.easeInOut,
                  ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSunnyAnimation(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: Icon(
          Icons.wb_sunny,
          size: widget.size * 0.7,
          color: Colors.amber,
        )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(begin: 0, end: 0.1, duration: 2000.ms, curve: Curves.easeInOut)
            .then(delay: 100.ms)
            .rotate(begin: 0.1, end: 0, duration: 2000.ms, curve: Curves.easeInOut)
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1500.ms)
            .then(delay: 100.ms)
            .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 1500.ms),
      ),
    );
  }
  
  Widget _buildCustomPainterAnimation(Color color) {
    final condition = widget.condition.toLowerCase();
    
    if (condition.contains('chuva') || condition.contains('chuvisco')) {
      return RainAnimation(
        color: Colors.blue[400]!,
        numberOfDrops: 30,
        speed: 1.0,
      );
    } else if (condition.contains('tempestade') || condition.contains('trovoada')) {
      return LightningAnimation(
        color: Colors.amber,
        width: widget.size,
        height: widget.size,
      );
    } else if (condition.contains('nublado') || condition.contains('nuvens')) {
      return CloudAnimation(
        color: Colors.grey[400]!,
        numberOfClouds: 3,
        speed: 1.0,
      );
    } else if (condition.contains('neve')) {
      return RainAnimation(
        color: Colors.white,
        numberOfDrops: 20,
        speed: 0.5,
      );
    } else if (condition.contains('neblina') || condition.contains('nevoeiro')) {
      return CloudAnimation(
        color: Colors.grey[300]!,
        numberOfClouds: 5,
        speed: 0.5,
      );
    } else {
      return SunAnimation(
        color: Colors.amber,
        size: widget.size,
      );
    }
  }
  
  Widget _buildHybridAnimation(Color color) {
    // Combina ícones com efeitos personalizados
    final condition = widget.condition.toLowerCase();
    
    return Stack(
      children: [
        // Base com ícone
        _buildIconAnimation(),
        
        // Efeitos adicionais com CustomPainter
        if (condition.contains('chuva') || condition.contains('chuvisco'))
          Opacity(
            opacity: 0.5,
            child: RainAnimation(
              color: Colors.blue[400]!,
              numberOfDrops: 20,
            ),
          ),
        if (condition.contains('tempestade') || condition.contains('trovoada'))
          Opacity(
            opacity: 0.7,
            child: LightningAnimation(
              color: Colors.amber,
              width: widget.size,
              height: widget.size,
            ),
          ),
      ],
    );
  }
  
  Color _getDefaultColorForCondition(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('chuva') || condition.contains('chuvisco')) {
      return Colors.blue[400]!;
    } else if (condition.contains('tempestade') || condition.contains('trovoada')) {
      return Colors.blueGrey[700]!;
    } else if (condition.contains('nublado') || condition.contains('nuvens')) {
      return Colors.grey[400]!;
    } else if (condition.contains('neve')) {
      return Colors.white;
    } else if (condition.contains('neblina') || condition.contains('nevoeiro')) {
      return Colors.grey[300]!;
    } else {
      return Colors.amber;
    }
  }
}
