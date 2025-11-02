import 'package:flutter/material.dart';
import '../services/monitoring_service.dart';
import '../services/inventory_service.dart';
// Módulo de atividades removido
import '../widgets/dashboard_stats.dart';
import '../widgets/database_maintenance_menu.dart';

/// Tela de conteúdo principal da home
class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final MonitoringService _monitoringService = MonitoringService();
  final InventoryService _inventoryService = InventoryService();
  // Módulo de atividades removido
  
  bool _isLoading = true;
  int _monitoringCount = 0;
  int _lowStockItemsCount = 0;
  // Módulo de atividades removido
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final monitoringCount = await _monitoringService.getMonitoringCount();
      final lowStockItemsCount = await _inventoryService.getLowStockItemsCount();
      // Módulo de atividades removido
      
      setState(() {
        _monitoringCount = monitoringCount;
        _lowStockItemsCount = lowStockItemsCount;
        // Módulo de atividades removido
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Estatísticas do dashboard
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DashboardStats(
                      monitoringCount: _monitoringCount,
                      lowStockItemsCount: _lowStockItemsCount,
                      // Módulo de atividades removido
                    ),
              
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildMaintenanceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bem-vindo ao FortSmart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A4F3D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Seu assistente completo para agricultura de precisão',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acesso Rápido',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A4F3D),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Monitoramento',
              Icons.bug_report,
              Colors.orange,
              () => Navigator.pushNamed(context, '/monitorings'),
            ),
            _buildActionCard(
              'Fazendas',
              Icons.landscape,
              Colors.green,
              () => Navigator.pushNamed(context, '/farms'),
            ),
            _buildActionCard(
              'Estoque',
              Icons.inventory,
              Colors.blue,
              () => Navigator.pushNamed(context, '/inventory'),
            ),
            _buildActionCard(
              'Relatórios',
              Icons.assessment,
              Colors.purple,
              () => Navigator.pushNamed(context, '/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        // onTap: onTap, // onTap não é suportado em Polygon no flutter_map 5.0.0
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manutenção',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A4F3D),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: DatabaseMaintenanceMenu(),
          ),
        ),
      ],
    );
  }
}
