import 'package:flutter/material.dart';
import '../routes.dart';

/// Widget de ações rápidas para o módulo Caldaflex
class CaldaflexQuickActionsWidget extends StatelessWidget {
  const CaldaflexQuickActionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Icon(Icons.science, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Ações Rápidas - Caldaflex',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Grid de ações rápidas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              // Nova Calda
              _buildQuickActionCard(
                context,
                title: 'Nova Calda',
                subtitle: 'Criar nova mistura',
                icon: Icons.add_circle,
                color: Colors.green,
                onTap: () => _navigateToCaldaflex(context),
              ),
              
              // Produtos & Doses
              _buildQuickActionCard(
                context,
                title: 'Produtos & Doses',
                subtitle: 'Calcular dosagens',
                icon: Icons.inventory,
                color: Colors.blue,
                onTap: () => _navigateToCaldaflex(context),
              ),
              
              // Pré-Calda
              _buildQuickActionCard(
                context,
                title: 'Pré-Calda',
                subtitle: 'Preparação inicial',
                icon: Icons.local_drink,
                color: Colors.orange,
                onTap: () => _navigateToCaldaflex(context),
              ),
              
              // Teste de Calda
              _buildQuickActionCard(
                context,
                title: 'Teste de Calda',
                subtitle: 'Verificar compatibilidade',
                icon: Icons.science,
                color: Colors.red,
                onTap: () => _navigateToCaldaflex(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Botão principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCaldaflex(context),
              icon: const Icon(Icons.science),
              label: const Text('Abrir Caldaflex Completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói card de ação rápida
  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Navega para o Caldaflex
  void _navigateToCaldaflex(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.caldaflex);
  }
}
