/// 🌱 Tela Principal do Módulo Antigo de Germinação
/// 
/// Wrapper que redireciona para o novo módulo de germinação
/// Mantém compatibilidade com navegação existente

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/germination_test_provider.dart';
import 'screens/germination_main_screen.dart';

class GerminationTestMainScreen extends StatelessWidget {
  const GerminationTestMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Envolver com o provider necessário para o módulo de germinação
    return ChangeNotifierProvider<GerminationTestProvider>(
      create: (context) => GerminationTestProvider(null), // Usa banco interno
      child: const GerminationMainScreen(),
    );
  }
}
