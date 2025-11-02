import 'package:flutter/material.dart';
import '../../routes.dart';

/// Widget de ações rápidas para o dashboard
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ações Rápidas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A4F3D),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
             childAspectRatio: 2.8,
            children: [
              _buildQuickActionCard(
                context,
                'Novo Monitoramento',
                Icons.bug_report,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.advancedMonitoring),
              ),
              _buildQuickActionCard(
                context,
                'Cadastrar Talhão',
                Icons.grid_view,
                Colors.blue,
                () => Navigator.pushNamed(context, AppRoutes.talhoesSafra),
              ),
              _buildQuickActionCard(
                context,
                'Registrar Plantio',
                Icons.eco,
                Colors.green,
                () => Navigator.pushNamed(context, AppRoutes.plantioRegistro),
              ),
              _buildQuickActionCard(
                context,
                'Adicionar Estoque',
                Icons.inventory,
                Colors.orange,
                () => Navigator.pushNamed(context, AppRoutes.inventory),
              ),
              _buildQuickActionCard(
                context,
                'Relatórios Agronômicos',
                Icons.analytics,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.agronomistReports),
              ),
              _buildQuickActionCard(
                context,
                'IA Agronômica',
                Icons.psychology,
                Colors.indigo,
                () => Navigator.pushNamed(context, AppRoutes.aiDashboard),
              ),
              // NOVO: Caldaflex
              _buildQuickActionCard(
                context,
                'Caldaflex',
                Icons.science,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.caldaflex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
           decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                   style: TextStyle(
                     fontSize: 11,
                     fontWeight: FontWeight.w600,
                     color: color.withOpacity(0.7),
                   ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
