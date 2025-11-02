import 'package:flutter/material.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/snackbar_utils.dart';

/// Tela de experimentos agrícolas
class ExperimentoScreen extends StatefulWidget {
  const ExperimentoScreen({super.key});

  @override
  _ExperimentoScreenState createState() => _ExperimentoScreenState();
}

class _ExperimentoScreenState extends State<ExperimentoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Experimentos Agrícolas',
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildEmDesenvolvimento(),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho da tela
  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Experimentos Agrícolas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure e monitore experimentos em campo',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mensagem temporária de funcionalidade em desenvolvimento
  Widget _buildEmDesenvolvimento() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Módulo em Desenvolvimento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'O módulo de experimentos agrícolas estará disponível em breve.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              SnackbarUtils.showInfoSnackBar(
                context, 
                'O módulo de experimentos estará disponível na próxima atualização.'
              );
            },
            child: const Text('Mais Informações'),
          ),
        ],
      ),
    );
  }
}
