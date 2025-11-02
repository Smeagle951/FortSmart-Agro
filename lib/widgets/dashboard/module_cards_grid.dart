import 'package:flutter/material.dart';
import '../../routes.dart';
import '../maps_navigation_widget.dart';
import '../caldaflex_quick_actions_widget.dart';

/// Grid de cards dos módulos principais do aplicativo
class ModuleCardsGrid extends StatelessWidget {
  const ModuleCardsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          const Text(
            'Módulos Principais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid de módulos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              // Card de Talhões
              _buildModuleCard(
                context,
                title: 'Talhões',
                subtitle: 'Gerenciar áreas',
                icon: Icons.map,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.talhoesSafra),
              ),
              
              // Card de Monitoramento
              _buildModuleCard(
                context,
                title: 'Monitoramento',
                subtitle: 'Pontos de coleta',
                icon: Icons.location_on,
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/monitoring/history-v2'),
              ),
              
              // Card de Mapa de Infestação - Redirecionado para Relatório Agronômico
              _buildModuleCard(
                context,
                title: 'Relatório Agronômico',
                subtitle: 'Monitoramento e Infestação',
                icon: Icons.analytics,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
              ),
              
              // Card de Mapas Offline
              _buildModuleCard(
                context,
                title: 'Mapas Offline - DEV',
                subtitle: 'Cache de mapas',
                icon: Icons.offline_bolt,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.offlineMapsManagement),
              ),
              
              // Card de Caldaflex
              _buildModuleCard(
                context,
                title: 'Caldaflex',
                subtitle: 'Gestão de caldas',
                icon: Icons.science,
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, AppRoutes.caldaflex),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Seção de Mapas (integrada)
          const MapsNavigationWidget(),
          
          const SizedBox(height: 16),
          
          // Seção de Caldaflex (integrada)
          const CaldaflexQuickActionsWidget(),
        ],
      ),
    );
  }

  /// Constrói um card de módulo
  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // Subtítulo
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
