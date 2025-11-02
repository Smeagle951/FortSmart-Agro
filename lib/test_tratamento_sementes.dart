import 'package:flutter/material.dart';
import 'modules/tratamento_sementes/screens/ts_main_screen.dart';
import 'constants/app_colors.dart';

/// Arquivo de teste para compilar o módulo de Tratamento de Sementes
/// Sem conectar as rotas - apenas para verificar se compila corretamente
void main() {
  runApp(const TratamentoSementesTestApp());
}

class TratamentoSementesTestApp extends StatelessWidget {
  const TratamentoSementesTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste - Tratamento de Sementes',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const TratamentoSementesTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TratamentoSementesTestScreen extends StatelessWidget {
  const TratamentoSementesTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Tratamento de Sementes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Módulo de Tratamento de Sementes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Teste de Compilação',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32),
            Text(
              '✅ Módulo compilado com sucesso!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'O módulo está pronto para uso.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TSMainScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Testar Módulo'),
      ),
    );
  }
}
