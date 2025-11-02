import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/fortsmart_splash_animation.dart';
import 'home_screen.dart'; // Ajuste conforme sua estrutura

/// Splash screen premium do FortSmart com animação Lottie
class SplashScreenPremium extends StatefulWidget {
  final Widget? nextScreen;
  final Duration? minimumDuration;
  final Future<void> Function()? onInit;
  final String? lottiePath;

  const SplashScreenPremium({
    Key? key,
    this.nextScreen,
    this.minimumDuration,
    this.onInit,
    this.lottiePath,
  }) : super(key: key);

  @override
  State<SplashScreenPremium> createState() => _SplashScreenPremiumState();
}

class _SplashScreenPremiumState extends State<SplashScreenPremium>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _loadingController;
  bool _animationComplete = false;
  bool _dataLoaded = false;
  bool _minTimeReached = false;

  @override
  void initState() {
    super.initState();
    
    _lottieController = AnimationController(vsync: this);
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Timer para garantir tempo mínimo de exibição
    Future.delayed(widget.minimumDuration ?? const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _minTimeReached = true;
        });
        _checkIfCanNavigate();
      }
    });

    // Carregar dados se função fornecida
    if (widget.onInit != null) {
      try {
        await widget.onInit!();
        if (mounted) {
          setState(() {
            _dataLoaded = true;
          });
          _checkIfCanNavigate();
        }
      } catch (e) {
        // Tratar erro de carregamento
        print('Erro ao carregar dados: $e');
        if (mounted) {
          setState(() {
            _dataLoaded = true; // Continuar mesmo com erro
          });
          _checkIfCanNavigate();
        }
      }
    } else {
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  void _checkIfCanNavigate() {
    if (_animationComplete && _minTimeReached && _dataLoaded) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => widget.nextScreen ?? const HomeScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Fundo branco perolado
      body: Stack(
        children: [
          // Animação Lottie principal
          Center(
            child: Lottie.asset(
              widget.lottiePath ?? 'assets/animations/fortsmart_splash.json',
              controller: _lottieController,
              repeat: false,
              onLoaded: (composition) {
                _lottieController.duration = composition.duration;
                _lottieController.forward().then((_) {
                  if (mounted) {
                    setState(() {
                      _animationComplete = true;
                    });
                    _checkIfCanNavigate();
                  }
                });
              },
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback para animação nativa caso Lottie falhe
                return FortSmartSplashAnimation(
                  onAnimationComplete: () {
                    setState(() {
                      _animationComplete = true;
                    });
                    _checkIfCanNavigate();
                  },
                );
              },
            ),
          ),

          // Indicador de loading premium (apenas se necessário)
          if (!_dataLoaded && _animationComplete)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _loadingController,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D9CDB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D9CDB).withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2D9CDB),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _loadingController,
                    child: Text(
                      'Preparando sua experiência...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Iniciar animação do loading quando necessário
    if (!_dataLoaded && _animationComplete) {
      _loadingController.forward();
    }
  }
}

/// Splash screen simples com Lottie
class SplashScreenLottie extends StatefulWidget {
  final Widget? nextScreen;
  final String? lottiePath;

  const SplashScreenLottie({
    Key? key,
    this.nextScreen,
    this.lottiePath,
  }) : super(key: key);

  @override
  State<SplashScreenLottie> createState() => _SplashScreenLottieState();
}

class _SplashScreenLottieState extends State<SplashScreenLottie>
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Lottie.asset(
          widget.lottiePath ?? 'assets/animations/fortsmart_splash.json',
          controller: _controller,
          repeat: false,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            _controller.forward().then((_) {
              if (mounted && widget.nextScreen != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => widget.nextScreen!,
                  ),
                );
              }
            });
          },
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const FortSmartSplashAnimation();
          },
        ),
      ),
    );
  }
}

/// Widget utilitário para exibir a animação Lottie
class FortSmartLottieAnimation extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final bool repeat;
  final VoidCallback? onComplete;

  const FortSmartLottieAnimation({
    Key? key,
    this.path,
    this.width,
    this.height,
    this.repeat = false,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        path ?? 'assets/animations/fortsmart_splash.json',
        repeat: repeat,
        onLoaded: (composition) {
          if (onComplete != null && !repeat) {
            Future.delayed(composition.duration, onComplete!);
          }
        },
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const FortSmartSplashAnimation();
        },
      ),
    );
  }
}
