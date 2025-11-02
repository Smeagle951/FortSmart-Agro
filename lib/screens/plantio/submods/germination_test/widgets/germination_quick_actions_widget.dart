/// 🌱 Widget de Ações Rápidas de Germinação
/// 
/// Exibe ações rápidas para testes de germinação
/// com design elegante seguindo padrão FortSmart

import 'package:flutter/material.dart';
import '../../../../../utils/fortsmart_theme.dart';

class GerminationQuickActionsWidget extends StatelessWidget {
  const GerminationQuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: FortSmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ações Rápidas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildActionCard(
          context,
          'Novo Teste Individual',
          Icons.add_circle,
          Colors.green,
          () => _navigateToCreateIndividualTest(context),
        ),
        _buildActionCard(
          context,
          'Novo Teste com Subtestes',
          Icons.science,
          Colors.blue,
          () => _navigateToCreateSubtestTest(context),
        ),
        _buildActionCard(
          context,
          'Listar Testes',
          Icons.list,
          Colors.orange,
          () => _navigateToTestList(context),
        ),
        _buildActionCard(
          context,
          'Canteiro Virtual',
          Icons.grid_view,
          Colors.purple,
          () => _navigateToCanteiro(context),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateIndividualTest(BuildContext context) {
    // TODO: Implementar navegação para teste individual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Criando teste individual...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToCreateSubtestTest(BuildContext context) {
    // TODO: Implementar navegação para teste com subtestes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Criando teste com subtestes...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToTestList(BuildContext context) {
    // TODO: Implementar navegação para lista de testes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo lista de testes...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToCanteiro(BuildContext context) {
    // TODO: Implementar navegação para canteiro virtual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo canteiro virtual...'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
