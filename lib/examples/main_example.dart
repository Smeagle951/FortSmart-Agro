import 'package:flutter/material.dart';
import '../screens/splash_screen_premium.dart';
import '../screens/home/home_screen.dart';

/// Exemplo prático de como usar a Splash Screen Premium no main.dart
void main() {
  runApp(const FortSmartExampleApp());
}

class FortSmartExampleApp extends StatelessWidget {
  const FortSmartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FortSmart - Exemplo Splash Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2D9CDB), // Azul FortSmart
      ),
      home: SplashScreenPremium(
        nextScreen: const HomeScreen(),
        minimumDuration: const Duration(seconds: 3),
        onInit: _initializeAppData,
      ),
    );
  }
}

/// Exemplo de função de inicialização com dados reais do FortSmart
Future<void> _initializeAppData() async {
  try {
    print('🚀 Inicializando FortSmart...');
    
    // Etapa 1: Carregar configurações do usuário
    await Future.delayed(const Duration(milliseconds: 500));
    print('✅ Configurações do usuário carregadas');
    
    // Etapa 2: Verificar conectividade
    await Future.delayed(const Duration(milliseconds: 300));
    print('✅ Conectividade verificada');
    
    // Etapa 3: Inicializar banco de dados local
    await Future.delayed(const Duration(milliseconds: 400));
    print('✅ Banco de dados inicializado');
    
    // Etapa 4: Carregar dados offline
    await Future.delayed(const Duration(milliseconds: 300));
    print('✅ Dados offline carregados');
    
    // Etapa 5: Inicializar serviços de localização
    await Future.delayed(const Duration(milliseconds: 200));
    print('✅ Serviços de localização inicializados');
    
    print('🎉 FortSmart inicializado com sucesso!');
    
  } catch (e) {
    print('❌ Erro ao inicializar FortSmart: $e');
    // Continuar mesmo com erro - não bloquear o app
  }
}

/// Exemplo alternativo com diferentes configurações
class FortSmartExampleAppAlternative extends StatelessWidget {
  const FortSmartExampleAppAlternative({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FortSmart - Exemplo Alternativo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: SplashScreenPremium(
        nextScreen: const HomeScreen(),
        minimumDuration: const Duration(seconds: 2), // Mais rápido
        onInit: _initializeAppDataFast, // Inicialização mais rápida
        lottiePath: 'assets/animations/fortsmart_splash.json', // Caminho explícito
      ),
    );
  }
}

/// Inicialização mais rápida para teste
Future<void> _initializeAppDataFast() async {
  await Future.delayed(const Duration(milliseconds: 200));
  print('🚀 FortSmart inicializado rapidamente!');
}

/// Exemplo com tratamento de erro mais robusto
class FortSmartExampleAppRobust extends StatelessWidget {
  const FortSmartExampleAppRobust({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FortSmart - Exemplo Robusto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2D9CDB),
      ),
      home: SplashScreenPremium(
        nextScreen: const HomeScreen(),
        minimumDuration: const Duration(seconds: 4),
        onInit: _initializeAppDataRobust,
      ),
    );
  }
}

/// Inicialização robusta com tratamento de erros
Future<void> _initializeAppDataRobust() async {
  try {
    print('🚀 Iniciando inicialização robusta do FortSmart...');
    
    // Simular carregamento com possíveis erros
    final tasks = [
      _loadUserSettings(),
      _checkConnectivity(),
      _initializeDatabase(),
      _loadOfflineData(),
      _setupLocationServices(),
    ];
    
    // Executar todas as tarefas em paralelo
    await Future.wait(tasks);
    
    print('🎉 FortSmart inicializado com sucesso!');
    
  } catch (e) {
    print('⚠️ Alguns serviços falharam, mas o app continuará: $e');
    // O app continua funcionando mesmo com alguns erros
  }
}

/// Tarefas individuais de inicialização
Future<void> _loadUserSettings() async {
  await Future.delayed(const Duration(milliseconds: 600));
  print('✅ Configurações do usuário carregadas');
}

Future<void> _checkConnectivity() async {
  await Future.delayed(const Duration(milliseconds: 400));
  print('✅ Conectividade verificada');
}

Future<void> _initializeDatabase() async {
  await Future.delayed(const Duration(milliseconds: 800));
  print('✅ Banco de dados inicializado');
}

Future<void> _loadOfflineData() async {
  await Future.delayed(const Duration(milliseconds: 500));
  print('✅ Dados offline carregados');
}

Future<void> _setupLocationServices() async {
  await Future.delayed(const Duration(milliseconds: 300));
  print('✅ Serviços de localização configurados');
}
