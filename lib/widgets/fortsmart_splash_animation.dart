import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Widget de animação de splash screen do FortSmart
class FortSmartSplashAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final double? width;
  final double? height;

  const FortSmartSplashAnimation({
    Key? key,
    this.onAnimationComplete,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<FortSmartSplashAnimation> createState() => _FortSmartSplashAnimationState();
}

class _FortSmartSplashAnimationState extends State<FortSmartSplashAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _subtextFadeAnimation;
  late Animation<Offset> _subtextSlideAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador principal (2.5 segundos)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Animação do logo: Scale 0 → 120% → 100% (0s → 0.8s)
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.32, curve: Curves.elasticOut),
    ));

    // Animação da opacidade do logo
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.32, curve: Curves.easeInOut),
    ));

    // Animação do brilho (0.6s → 1.2s)
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.24, 0.48, curve: Curves.easeInOut),
    ));

    // Animação do texto "FORTSMART" (1.0s → 1.6s)
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.64, curve: Curves.easeInOut),
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.64, curve: Curves.easeOutCubic),
    ));

    // Animação do subtexto (1.4s → 2.0s)
    _subtextFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.56, 0.8, curve: Curves.easeInOut),
    ));

    _subtextSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.56, 0.8, curve: Curves.easeOutCubic),
    ));

    // Fade out geral (2.0s → 2.5s)
    _fadeOutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
    ));

    // Iniciar animação
    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      color: const Color(0xFFFAFAFA), // Fundo branco perolado
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOutAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo FortSmart com animação
                  Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D9CDB), // Azul FortSmart
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D9CDB).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Texto "FORTSMART"
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: const Text(
                        'FORTSMART',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          color: Color(0xFF2C2C2C),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Subtexto
                  SlideTransition(
                    position: _subtextSlideAnimation,
                    child: FadeTransition(
                      opacity: _subtextFadeAnimation,
                      child: const Text(
                        'Tudo na palma da mão',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          color: Color(0xFF2D9CDB),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget alternativo usando Lottie (quando tiver o arquivo JSON)
class FortSmartLottieSplash extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final String? lottiePath;

  const FortSmartLottieSplash({
    Key? key,
    this.onAnimationComplete,
    this.lottiePath,
  }) : super(key: key);

  @override
  State<FortSmartLottieSplash> createState() => _FortSmartLottieSplashState();
}

class _FortSmartLottieSplashState extends State<FortSmartLottieSplash> 
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFFAFAFA),
      child: Lottie.asset(
        widget.lottiePath ?? 'assets/animations/fortsmart_splash.json',
        controller: _controller,
        onLoaded: (composition) {
          _controller
            ..duration = composition.duration
            ..forward().then((_) {
              widget.onAnimationComplete?.call();
            });
        },
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Tela de splash completa
class FortSmartSplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  final Duration? duration;

  const FortSmartSplashScreen({
    Key? key,
    this.nextScreen,
    this.duration,
  }) : super(key: key);

  @override
  State<FortSmartSplashScreen> createState() => _FortSmartSplashScreenState();
}

class _FortSmartSplashScreenState extends State<FortSmartSplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FortSmartSplashAnimation(
        onAnimationComplete: () {
          if (widget.nextScreen != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => widget.nextScreen!),
            );
          }
        },
      ),
    );
  }
}
