import 'package:flutter/material.dart';
import '../../routes.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_bar_widget.dart';

/// Tela principal do módulo de Aplicação Agrícola
class AplicacaoHomeScreen extends StatefulWidget {
  const AplicacaoHomeScreen({super.key});

  @override
  _AplicacaoHomeScreenState createState() => _AplicacaoHomeScreenState();
}

class _AplicacaoHomeScreenState extends State<AplicacaoHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'FortSmart Agro',
        actions: const [],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aplicação Agrícola',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registre e gerencie aplicações terrestres e aéreas',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      'Nova Aplicação',
                      Icons.add_circle_outline,
                      Colors.blue,
                      () => Navigator.pushNamed(context, AppRoutes.novaPrescricao),
                    ),
                    _buildMenuCard(
                      context,
                      'Histórico',
                      Icons.history,
                      Colors.green,
                      () => Navigator.pushNamed(context, AppRoutes.aplicacaoLista),
                    ),
                    _buildMenuCard(
                      context,
                      'Relatórios',
                      Icons.assessment,
                      Colors.orange,
                      () => Navigator.pushNamed(context, AppRoutes.aplicacaoRelatorio),
                    ),
                    _buildMenuCard(
                      context,
                      'Configurações',
                      Icons.settings,
                      Colors.grey,
                      () => Navigator.pushNamed(context, AppRoutes.aplicacaoRelatorio),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
