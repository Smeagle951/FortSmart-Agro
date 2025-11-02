import 'package:flutter/material.dart';
import '../../utils/fortsmart_theme.dart';
import '../../widgets/app_bar_widget.dart';
import 'monitoring_dashboard.dart';
import 'planting_report_screen.dart';
import 'application_report_screen.dart';
import '../colheita/colheita_main_screen.dart';
import 'germination_canteiro_dashboard.dart';
import 'infestation_dashboard.dart';
import 'integrated_reports_dashboard.dart';

/// Dashboard centralizado e aprimorado de relatórios FortSmart Agro
/// Versão premium com acesso a todos os tipos de relatórios
class EnhancedReportsDashboard extends StatelessWidget {
  const EnhancedReportsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Relatórios FortSmart',
        showBackButton: true,
        backgroundColor: FortSmartTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(context),
            const SizedBox(height: 24),
            _buildReportsGrid(context),
            const SizedBox(height: 24),
            _buildAdvancedReports(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FortSmartTheme.primaryColor, FortSmartTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatórios Inteligentes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Análise completa da sua fazenda com IA FortSmart',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Plantios',
            '12',
            Icons.grass,
            FortSmartTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Aplicações',
            '8',
            Icons.local_drink,
            FortSmartTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Monitoramentos',
            '24',
            Icons.visibility,
            FortSmartTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relatórios por Módulo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FortSmartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildReportCard(
              context,
              'Monitoramento',
              'Dashboard inteligente com IA',
              Icons.visibility,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MonitoringDashboard(),
                ),
              ),
            ),
            _buildReportCard(
              context,
              'Plantio',
              'Relatórios de plantio detalhados',
              Icons.grass,
              Colors.brown,
              () => Navigator.pushNamed(context, PlantingReportScreen.routeName),
            ),
            _buildReportCard(
              context,
              'Aplicação',
              'Aplicações de produtos',
              Icons.local_drink,
              Colors.blue,
              () => Navigator.pushNamed(context, ApplicationReportScreen.routeName),
            ),
            _buildReportCard(
              context,
              'Colheita',
              'Perdas e cálculos',
              Icons.agriculture,
              Colors.amber,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ColheitaMainScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedReports(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relatórios Avançados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FortSmartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildAdvancedReportCard(
          context,
          'Canteiros de Germinação',
          'Dashboard visual 4x4 com análise FortSmart',
          Icons.grid_view,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GerminationCanteiroDashboard(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdvancedReportCard(
          context,
          'Mapa de Infestação',
          'Análise híbrida IA + FortSmart com aprendizado',
          Icons.bug_report,
          Colors.red,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InfestationDashboard(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildAdvancedReportCard(
          context,
          'Relatório Consolidado',
          'Visão completa de todas as operações da safra',
          Icons.analytics,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IntegratedReportsDashboard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildAdvancedReportCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: FortSmartTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
