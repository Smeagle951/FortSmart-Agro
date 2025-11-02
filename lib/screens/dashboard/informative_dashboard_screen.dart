import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/dashboard/dashboard_data.dart';
import '../../services/dashboard_data_service.dart';
import '../../widgets/dashboard/informative_dashboard_cards.dart';
import '../../widgets/app_drawer.dart';
import '../../routes.dart';
import '../../utils/logger.dart';

/// Dashboard moderna com cards informativos baseados em dados reais
class InformativeDashboardScreen extends StatefulWidget {
  const InformativeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InformativeDashboardScreen> createState() => _InformativeDashboardScreenState();
}

class _InformativeDashboardScreenState extends State<InformativeDashboardScreen> {
  final DashboardDataService _dashboardDataService = DashboardDataService();
  
  bool _isLoading = true;
  bool _showWelcomeMessage = true;
  DashboardData _dashboardData = DashboardData.create();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    
    // Timer para atualização automática
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadDashboardData();
      } else {
        timer.cancel();
      }
    });
    
    // Ocultar mensagem de boas-vindas após 5 segundos
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar dados completos do dashboard
      final dashboardData = await _dashboardDataService.loadDashboardData();
      
      setState(() {
        _dashboardData = dashboardData;
        _isLoading = false;
      });
      
      Logger.info('✅ Dashboard carregada com sucesso');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Logger.error('❌ Erro ao carregar dashboard: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showWelcomeMessage) _buildWelcomeMessage(),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildInformativeCards(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildActivityDistribution(),
                    const SizedBox(height: 100), // Espaço para FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'FortSmart Agro',
        style: TextStyle(
          color: Color(0xFF2A4F3D),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      iconTheme: const IconThemeData(color: Color(0xFF2A4F3D)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF2A4F3D)),
          onPressed: _loadDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF2A4F3D)),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.waving_hand, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo ao FortSmart Agro!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seu sistema de gestão agrícola está funcionando perfeitamente.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final farm = _dashboardData.farmProfile;
    final isConfigured = farm.nome != 'Fazenda não configurada';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConfigured 
              ? [const Color(0xFF2A4F3D), const Color(0xFF1E3A2A)]
              : [Colors.grey.shade600, Colors.grey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? farm.nome : 'Fazenda não configurada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConfigured ? '${farm.proprietario} / ${farm.localizacao}' : 'Não informado / N/A',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Atualizar dados',
              ),
               IconButton(
                 onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                 icon: const Icon(Icons.settings, color: Colors.white),
                 tooltip: 'Configurações',
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformativeCards() {
    return InformativeDashboardCards(
      dashboardData: _dashboardData,
      onFarmTap: () => Navigator.pushNamed(context, AppRoutes.farmProfile),
      onAlertsTap: () => Navigator.pushNamed(context, AppRoutes.reports),
      onTalhoesTap: () => Navigator.pushNamed(context, AppRoutes.talhoesSafra),
      onPlantiosTap: () => Navigator.pushNamed(context, AppRoutes.plantioHome),
      onMonitoramentosTap: () => Navigator.pushNamed(context, AppRoutes.monitoringMain),
      onEstoqueTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
    );
  }

  Widget _buildQuickActions() {
    return Column(
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
          childAspectRatio: 1.8,
          children: [
            _buildQuickActionCard(
              'Novo Monitoramento',
              Icons.bug_report,
              Colors.purple,
              () => Navigator.pushNamed(context, AppRoutes.advancedMonitoring),
            ),
            _buildQuickActionCard(
              'Cadastrar Talhão',
              Icons.grid_view,
              Colors.blue,
              () => Navigator.pushNamed(context, AppRoutes.talhoesSafra),
            ),
             _buildQuickActionCard(
               'Registrar Plantio',
               Icons.eco,
               Colors.green,
               () => Navigator.pushNamed(context, AppRoutes.plantioRegistro),
             ),
            _buildQuickActionCard(
              'Adicionar Estoque',
              Icons.inventory,
              Colors.orange,
              () => Navigator.pushNamed(context, AppRoutes.inventory),
            ),
            _buildQuickActionCard(
              'Relatórios Agronômicos',
              Icons.analytics,
              Colors.purple,
              () => Navigator.pushNamed(context, AppRoutes.agronomistReports),
            ),
            _buildQuickActionCard(
              'IA Agronômica',
              Icons.psychology,
              Colors.indigo,
              () => Navigator.pushNamed(context, AppRoutes.aiDashboard),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribuição de Atividades',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A4F3D),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Gráfico simples de atividades
              Container(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_dashboardData.talhoesSummary.totalTalhoes + _dashboardData.plantiosAtivos.totalPlantios + _dashboardData.monitoramentosSummary.realizados}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total de Atividades',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legenda
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Talhões', _dashboardData.talhoesSummary.totalTalhoes, Colors.blue),
                  _buildLegendItem('Plantios', _dashboardData.plantiosAtivos.totalPlantios, Colors.green),
                  _buildLegendItem('Monitoramentos', _dashboardData.monitoramentosSummary.realizados, Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showQuickActionMenu(),
      backgroundColor: const Color(0xFF2A4F3D),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showQuickActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A4F3D),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActionTile(
              'Novo Monitoramento',
              Icons.bug_report,
              Colors.purple,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.advancedMonitoring);
              },
            ),
            _buildQuickActionTile(
              'Cadastrar Talhão',
              Icons.grid_view,
              Colors.blue,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.talhoesSafra);
              },
            ),
             _buildQuickActionTile(
               'Registrar Plantio',
               Icons.eco,
               Colors.green,
               () {
                 Navigator.pop(context);
                 Navigator.pushNamed(context, AppRoutes.plantioRegistro);
               },
             ),
            _buildQuickActionTile(
              'Adicionar Estoque',
              Icons.inventory,
              Colors.orange,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.inventory);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
