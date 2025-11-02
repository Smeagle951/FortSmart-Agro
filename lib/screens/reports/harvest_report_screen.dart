import 'package:flutter/material.dart';
import '../colheita/colheita_main_screen.dart';

/// Tela de relatório de colheita redirecionada
/// Esta tela agora redireciona para o novo módulo de colheita
class HarvestReportScreen extends StatelessWidget {
  static const String routeName = '/reports/harvest';

  const HarvestReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redireciona automaticamente para o novo módulo de colheita
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ColheitaMainScreen(),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Redirecionando...')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Redirecionando para o novo módulo de colheita...'),
          ],
        ),
      ),
    );
  }
}