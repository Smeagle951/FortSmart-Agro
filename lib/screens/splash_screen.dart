import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/fortsmart_splash_animation.dart';
import '../screens/home_screen.dart'; // Ajuste conforme sua estrutura

/// Tela de splash screen premium do FortSmart
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _animationComplete = false;

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
      backgroundColor: const Color(0xFFFAFAFA), // Fundo branco perolado
      body: Center(
        child: Lottie.asset(
          'assets/animations/fortsmart_splash.json',
          controller: _controller,
          repeat: false,
          onLoaded: (composition) {
            // Configurar duração da animação
            _controller.duration = composition.duration;
            
            // Iniciar animação
            _controller.forward().then((_) {
              if (mounted) {
                setState(() {
                  _animationComplete = true;
                });
                
                // Navegar para a tela principal após a animação
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              }
            });
          },
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback caso o arquivo Lottie não carregue
            return const FortSmartSplashAnimation(
              onAnimationComplete: null,
            );
          },
        ),
      ),
    );
  }
}

/// Exemplo de uso alternativo com Lottie
class SplashScreenLottie extends StatefulWidget {
  const SplashScreenLottie({Key? key}) : super(key: key);

  @override
  State<SplashScreenLottie> createState() => _SplashScreenLottieState();
}

class _SplashScreenLottieState extends State<SplashScreenLottie> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FortSmartLottieSplash(
        lottiePath: 'assets/animations/fortsmart_splash.json',
        onAnimationComplete: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// Exemplo de splash screen com delay adicional
class SplashScreenWithDelay extends StatefulWidget {
  final Duration? minimumDuration;

  const SplashScreenWithDelay({
    Key? key,
    this.minimumDuration,
  }) : super(key: key);

  @override
  State<SplashScreenWithDelay> createState() => _SplashScreenWithDelayState();
}

class _SplashScreenWithDelayState extends State<SplashScreenWithDelay> {
  bool _animationComplete = false;
  bool _minTimeReached = false;

  @override
  void initState() {
    super.initState();
    
    // Timer para garantir tempo mínimo de exibição
    Future.delayed(widget.minimumDuration ?? const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _minTimeReached = true;
        });
        _checkIfCanNavigate();
      }
    });
  }

  void _checkIfCanNavigate() {
    if (_animationComplete && _minTimeReached) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FortSmartSplashAnimation(
        onAnimationComplete: () {
          setState(() {
            _animationComplete = true;
          });
          _checkIfCanNavigate();
        },
      ),
    );
  }
}

/// Splash screen com loading de dados
class SplashScreenWithLoading extends StatefulWidget {
  const SplashScreenWithLoading({Key? key}) : super(key: key);

  @override
  State<SplashScreenWithLoading> createState() => _SplashScreenWithLoadingState();
}

class _SplashScreenWithLoadingState extends State<SplashScreenWithLoading> {
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAppData();
  }

  Future<void> _loadAppData() async {
    // Simular carregamento de dados
    await Future.delayed(const Duration(seconds: 2));
    
    // Aqui você pode carregar:
    // - Configurações do usuário
    // - Dados iniciais
    // - Verificar conectividade
    // - Inicializar serviços
    
    setState(() {
      _dataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FortSmartSplashAnimation(
            onAnimationComplete: () {
              if (_dataLoaded) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              }
            },
          ),
          
          // Indicador de loading (opcional)
          if (!_dataLoaded)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D9CDB)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Exemplo de splash screen personalizado
class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({Key? key}) : super(key: key);

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D9CDB),
              Color(0xFF1E88E5),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.agriculture,
                  size: 120,
                  color: Colors.white,
                ),
                SizedBox(height: 30),
                Text(
                  'FORTSMART',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tudo na palma da mão',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}