import 'dart:math';
import 'package:flutter/material.dart';

/// Widget para animação de gotas de chuva
class RainAnimation extends StatefulWidget {
  final int numberOfDrops;
  final Color color;
  final double speed;

  const RainAnimation({
    Key? key,
    this.numberOfDrops = 50,
    this.color = Colors.blue,
    this.speed = 1.0,
  }) : super(key: key);

  @override
  State<RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<RainAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<RainDrop> _rainDrops;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rainDrops = List.generate(widget.numberOfDrops, (_) => _createRainDrop());
  }

  RainDrop _createRainDrop() {
    return RainDrop(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      length: 0.1 + _random.nextDouble() * 0.2,
      speed: 0.1 + _random.nextDouble() * 0.3 * widget.speed,
      thickness: 1 + _random.nextDouble() * 2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RainPainter(
            rainDrops: _rainDrops,
            progress: _controller.value,
            color: widget.color,
          ),
          child: child,
        );
      },
    );
  }
}

class RainDrop {
  double x;
  double y;
  double length;
  double speed;
  double thickness;

  RainDrop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.thickness,
  });
}

class RainPainter extends CustomPainter {
  final List<RainDrop> rainDrops;
  final double progress;
  final Color color;

  RainPainter({
    required this.rainDrops,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var drop in rainDrops) {
      final y = (drop.y + progress * drop.speed) % 1.0;
      paint.strokeWidth = drop.thickness;
      
      canvas.drawLine(
        Offset(drop.x * size.width, y * size.height),
        Offset(drop.x * size.width, (y + drop.length) * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(RainPainter oldDelegate) => true;
}

/// Widget para animação de nuvens em movimento
class CloudAnimation extends StatefulWidget {
  final int numberOfClouds;
  final Color color;
  final double speed;

  const CloudAnimation({
    Key? key,
    this.numberOfClouds = 3,
    this.color = Colors.white,
    this.speed = 1.0,
  }) : super(key: key);

  @override
  State<CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends State<CloudAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Cloud> _clouds;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _clouds = List.generate(widget.numberOfClouds, (_) => _createCloud());
  }

  Cloud _createCloud() {
    return Cloud(
      x: _random.nextDouble(),
      y: 0.1 + _random.nextDouble() * 0.3,
      size: 0.2 + _random.nextDouble() * 0.3,
      speed: 0.01 + _random.nextDouble() * 0.03 * widget.speed,
      opacity: 0.7 + _random.nextDouble() * 0.3,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CloudPainter(
            clouds: _clouds,
            progress: _controller.value,
            color: widget.color,
          ),
          child: child,
        );
      },
    );
  }
}

class Cloud {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Cloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class CloudPainter extends CustomPainter {
  final List<Cloud> clouds;
  final double progress;
  final Color color;

  CloudPainter({
    required this.clouds,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var cloud in clouds) {
      final x = (cloud.x + progress * cloud.speed) % 1.2 - 0.2;
      
      final paint = Paint()
        ..color = color.withOpacity(cloud.opacity)
        ..style = PaintingStyle.fill;
      
      final cloudSize = cloud.size * size.width;
      final centerX = x * size.width;
      final centerY = cloud.y * size.height;
      
      // Desenha uma nuvem simples com círculos
      canvas.drawCircle(Offset(centerX, centerY), cloudSize * 0.5, paint);
      canvas.drawCircle(Offset(centerX + cloudSize * 0.4, centerY), cloudSize * 0.4, paint);
      canvas.drawCircle(Offset(centerX - cloudSize * 0.4, centerY), cloudSize * 0.4, paint);
      canvas.drawCircle(Offset(centerX + cloudSize * 0.2, centerY - cloudSize * 0.3), cloudSize * 0.3, paint);
      canvas.drawCircle(Offset(centerX - cloudSize * 0.2, centerY - cloudSize * 0.3), cloudSize * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(CloudPainter oldDelegate) => true;
}

/// Widget para animação de sol pulsando
class SunAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const SunAnimation({
    Key? key,
    this.color = Colors.amber,
    this.size = 50,
  }) : super(key: key);

  @override
  State<SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends State<SunAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _sizeAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * pi,
          child: Container(
            width: widget.size * _sizeAnimation.value,
            height: widget.size * _sizeAnimation.value,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CustomPaint(
              painter: SunRaysPainter(
                color: widget.color,
                progress: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SunRaysPainter extends CustomPainter {
  final Color color;
  final double progress;

  SunRaysPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rayLength = radius * 0.3 * (0.8 + progress * 0.4);
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final startPoint = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      final endPoint = Offset(
        center.dx + cos(angle) * (radius + rayLength),
        center.dy + sin(angle) * (radius + rayLength),
      );
      
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(SunRaysPainter oldDelegate) => true;
}

/// Widget para animação de raios
class LightningAnimation extends StatefulWidget {
  final Color color;
  final double width;
  final double height;

  const LightningAnimation({
    Key? key,
    this.color = Colors.yellowAccent,
    this.width = 100,
    this.height = 150,
  }) : super(key: key);

  @override
  State<LightningAnimation> createState() => _LightningAnimationState();
}

class _LightningAnimationState extends State<LightningAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  bool _showLightning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showLightning = false;
        });
        Future.delayed(Duration(seconds: 2 + _random.nextInt(5)), () {
          if (mounted) {
            setState(() {
              _showLightning = true;
            });
            _controller.forward(from: 0);
          }
        });
      }
    });

    // Inicia a primeira animação após um atraso aleatório
    Future.delayed(Duration(seconds: _random.nextInt(3)), () {
      if (mounted) {
        setState(() {
          _showLightning = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _showLightning ? _controller.value : 0,
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: LightningPainter(
              color: widget.color,
              seed: _random.nextInt(1000),
            ),
          ),
        );
      },
    );
  }
}

class LightningPainter extends CustomPainter {
  final Color color;
  final int seed;
  final Random random;

  LightningPainter({
    required this.color,
    required this.seed,
  }) : random = Random(seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Ponto inicial no topo
    double x = size.width / 2;
    double y = 0;
    
    path.moveTo(x, y);
    
    // Número de segmentos do raio
    final segments = 5 + random.nextInt(3);
    
    for (int i = 0; i < segments; i++) {
      // Calcula o próximo ponto com alguma aleatoriedade
      x += (random.nextDouble() - 0.5) * size.width * 0.5;
      y += size.height / segments;
      
      // Mantém o raio dentro dos limites
      x = x.clamp(0, size.width);
      
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
    
    // Adiciona um brilho ao redor do raio
    paint.strokeWidth = 8;
    paint.color = color.withOpacity(0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LightningPainter oldDelegate) => true;
}
