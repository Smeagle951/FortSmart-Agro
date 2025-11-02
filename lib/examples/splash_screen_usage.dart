import 'package:flutter/material.dart';
import '../screens/splash_screen_premium.dart';
import '../screens/home_screen.dart'; // Ajuste conforme sua estrutura

/// Exemplos práticos de uso da Splash Screen Premium FortSmart
class SplashScreenUsageExamples extends StatelessWidget {
  const SplashScreenUsageExamples({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplos Splash Screen'),
        backgroundColor: const Color(0xFF2D9CDB),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Splash Screen Simples',
            'Animação básica com Lottie',
            () => _navigateToSplash(context, SplashType.simple),
          ),
          _buildExampleCard(
            context,
            'Splash Screen Premium',
            'Com loading de dados e controle total',
            () => _navigateToSplash(context, SplashType.premium),
          ),
          _buildExampleCard(
            context,
            'Splash com Carregamento',
            'Simula carregamento de dados do app',
            () => _navigateToSplash(context, SplashType.withLoading),
          ),
          _buildExampleCard(
            context,
            'Splash Personalizada',
            'Com configurações customizadas',
            () => _navigateToSplash(context, SplashType.custom),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTap,
                    child: const Text(
                      'Testar',
                      style: TextStyle(
                        color: Color(0xFF2D9CDB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSplash(BuildContext context, SplashType type) {
    Widget splashScreen;

    switch (type) {
      case SplashType.simple:
        splashScreen = const SplashScreenLottie(
          nextScreen: HomeScreen(),
        );
        break;
      case SplashType.premium:
        splashScreen = SplashScreenPremium(
          nextScreen: const HomeScreen(),
          minimumDuration: const Duration(seconds: 2),
          onInit: _simulateDataLoading,
        );
        break;
      case SplashType.withLoading:
        splashScreen = SplashScreenPremium(
          nextScreen: const HomeScreen(),
          minimumDuration: const Duration(seconds: 4),
          onInit: _simulateLongDataLoading,
        );
        break;
      case SplashType.custom:
        splashScreen = SplashScreenPremium(
          nextScreen: const HomeScreen(),
          minimumDuration: const Duration(seconds: 3),
          onInit: _simulateCustomLoading,
          lottiePath: 'assets/animations/fortsmart_splash.json',
        );
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => splashScreen),
    );
  }

  // Simula carregamento rápido de dados
  Future<void> _simulateDataLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    // Simular carregamento de:
    // - Configurações do usuário
    // - Dados iniciais
    // - Verificação de conectividade
  }

  // Simula carregamento longo de dados
  Future<void> _simulateLongDataLoading() async {
    await Future.delayed(const Duration(seconds: 3));
    // Simular carregamento pesado:
    // - Sincronização de dados
    // - Download de atualizações
    // - Inicialização de serviços
  }

  // Simula carregamento customizado
  Future<void> _simulateCustomLoading() async {
    // Simular múltiplas etapas de carregamento
    await Future.delayed(const Duration(milliseconds: 500));
    print('Etapa 1: Carregando configurações...');
    
    await Future.delayed(const Duration(milliseconds: 800));
    print('Etapa 2: Verificando conectividade...');
    
    await Future.delayed(const Duration(milliseconds: 700));
    print('Etapa 3: Inicializando serviços...');
  }
}

enum SplashType {
  simple,
  premium,
  withLoading,
  custom,
}

/// Widget de exemplo para demonstrar uso da animação Lottie
class LottieAnimationExample extends StatefulWidget {
  const LottieAnimationExample({Key? key}) : super(key: key);

  @override
  State<LottieAnimationExample> createState() => _LottieAnimationExampleState();
}

class _LottieAnimationExampleState extends State<LottieAnimationExample> {
  bool _showAnimation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo Animação Lottie'),
        backgroundColor: const Color(0xFF2D9CDB),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showAnimation)
              const FortSmartLottieAnimation(
                width: 300,
                height: 300,
                repeat: false,
              )
            else
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Clique para ver a animação',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _showAnimation = !_showAnimation;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D9CDB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _showAnimation ? 'Esconder Animação' : 'Mostrar Animação',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de demonstração das cores da marca
class BrandColorsDemo extends StatelessWidget {
  const BrandColorsDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = [
      {'name': 'Azul FortSmart', 'color': const Color(0xFF2D9CDB)},
      {'name': 'Fundo Perolado', 'color': const Color(0xFFFAFAFA)},
      {'name': 'Texto Principal', 'color': const Color(0xFF2C2C2C)},
      {'name': 'Cinza Médio', 'color': const Color(0xFF757575)},
      {'name': 'Cinza Claro', 'color': const Color(0xFFE0E0E0)},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cores da Marca FortSmart'),
        backgroundColor: const Color(0xFF2D9CDB),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: colors.map((colorData) {
          final color = colorData['color'] as Color;
          final name = colorData['name'] as String;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget de teste para validar a animação
class SplashScreenTest extends StatelessWidget {
  const SplashScreenTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SplashScreenPremium(
      nextScreen: HomeScreen(),
      minimumDuration: Duration(seconds: 2),
      onInit: _testInitialization,
    );
  }

  static Future<void> _testInitialization() async {
    // Simular inicialização de teste
    await Future.delayed(const Duration(seconds: 1));
    print('Teste de inicialização concluído!');
  }
}
