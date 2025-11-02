import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/inventory_report_screen.dart';
import 'screens/product_application_report_screen.dart';
import '../inventory/services/inventory_service.dart';
import '../product_application/services/product_application_service.dart';
import 'services/inventory_report_service.dart';
import 'services/product_application_report_service.dart';
// import '../../../services/germination_report_service.dart'; // Comentado temporariamente
import '../../../services/planting_report_service.dart';
import '../../../services/integrated_report_service.dart';
import '../../../screens/reports/integrated_reports_dashboard.dart';

/// Módulo principal de relatórios do FortSmart Agro
/// Versão atualizada com sistema avançado de relatórios
class ReportsModule extends StatelessWidget {
  const ReportsModule({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Relatórios existentes (compatibilidade)
        Provider<InventoryReportService>(
          create: (context) => InventoryReportService(
            Provider.of<InventoryService>(context, listen: false),
          ),
        ),
        Provider<ProductApplicationReportService>(
          create: (context) => ProductApplicationReportService(
            Provider.of<ProductApplicationService>(context, listen: false),
          ),
        ),
        // Novos serviços de relatórios avançados
        Provider<PlantingReportService>(
          create: (context) => PlantingReportService(),
        ),
        Provider<IntegratedReportService>(
          create: (context) => IntegratedReportService(),
        ),
      ],
      child: const ReportsMenuScreen(),
    );
  }
}

/// Tela de menu principal de relatórios
/// Versão atualizada com acesso ao novo sistema integrado
class ReportsMenuScreen extends StatelessWidget {
  const ReportsMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios FortSmart'),
        backgroundColor: const Color(0xFF2A4F3D), // Verde FortSmart
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header principal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A4F3D), Color(0xFF468750)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Central de Relatórios FortSmart',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Acesse relatórios avançados com análises integradas de germinação, plantio e operações agrícolas.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Dashboard Integrado (Principal)
            _buildReportCard(
              context,
              title: 'Dashboard Integrado',
              description: 'Acesso completo a todos os relatórios com análises avançadas de germinação, plantio e integração.',
              icon: Icons.dashboard,
              color: const Color(0xFF2A4F3D),
              isPrimary: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IntegratedReportsDashboard()),
              ),
            ),
            const SizedBox(height: 16),
            
            // Separador
            const Divider(),
            const SizedBox(height: 16),
            
            // Relatórios específicos
            const Text(
              'Relatórios Específicos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Relatório de Germinação
            _buildReportCard(
              context,
              title: 'Testes de Germinação',
              description: 'Relatórios detalhados de testes de germinação com análises estatísticas e recomendações.',
              icon: Icons.science,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(
                context,
                '/germination/reports',
              ),
            ),
            const SizedBox(height: 16),
            
            // Relatório de Plantio
            _buildReportCard(
              context,
              title: 'Operações de Plantio',
              description: 'Análises de plantio, calibração e densidade com recomendações técnicas.',
              icon: Icons.grass,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(
                context,
                '/reports/planting/enhanced',
              ),
            ),
            const SizedBox(height: 16),
            
            // Relatórios existentes (compatibilidade)
            const Text(
              'Relatórios de Gestão',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Relatório de Estoque
            _buildReportCard(
              context,
              title: 'Relatório de Estoque',
              description: 'Conferência atual de produtos em estoque com filtros por tipo, vencimento, fornecedor e lote.',
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InventoryReportScreen()),
              ),
            ),
            const SizedBox(height: 16),
            
            // Relatório de Aplicações
            _buildReportCard(
              context,
              title: 'Relatório de Aplicações',
              description: 'Gasto de produtos por aplicação com filtros por cultura, talhão, produto e responsável.',
              icon: Icons.agriculture,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductApplicationReportScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Card(
      elevation: isPrimary ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPrimary ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isPrimary ? BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ) : null,
          child: Padding(
            padding: EdgeInsets.all(isPrimary ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: isPrimary ? 70 : 60,
                  height: isPrimary ? 70 : 60,
                  decoration: BoxDecoration(
                    color: isPrimary ? color : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: isPrimary ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : color,
                    size: isPrimary ? 36 : 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isPrimary ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: isPrimary ? color : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: isPrimary ? 15 : 14,
                          color: isPrimary ? color.withOpacity(0.8) : Colors.grey[700],
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'RECOMENDADO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isPrimary ? color : Colors.grey,
                  size: isPrimary ? 20 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
