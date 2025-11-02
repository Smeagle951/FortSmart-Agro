import 'package:flutter/material.dart';
import 'plantio_registro_screen.dart';

class PlantioTesteScreen extends StatelessWidget {
  const PlantioTesteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste do Módulo Plantio'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlantioRegistroScreen(),
                  ),
                );
              },
              child: const Text('Novo Plantio'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aqui você pode passar o ID de um plantio existente para edição
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlantioRegistroScreen(plantioId: 'id-de-teste'),
                  ),
                );
              },
              child: const Text('Editar Plantio (Teste)'),
            ),
          ],
        ),
      ),
    );
  }
}
