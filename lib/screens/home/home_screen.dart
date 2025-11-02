import 'package:flutter/material.dart';
import '../dashboard/premium_dashboard_screen.dart';

/// Tela inicial do aplicativo FortSmart Agro
/// 
/// Esta tela foi atualizada para usar o dashboard premium avançado
/// que oferece uma visão estratégica completa da fazenda com animações
/// e funcionalidades premium
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usando o PremiumDashboardScreen para uma experiência
    // mais avançada com animações e funcionalidades premium
    return const PremiumDashboardScreen();
  }
}
