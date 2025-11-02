import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../models/farm.dart';
import '../../models/talhao_model.dart';
import '../../models/planting.dart';
import '../../models/monitoring.dart';
import '../../database/models/inventory.dart';
import '../../services/farm_service.dart';
import '../../services/talhao_service.dart';
import '../../services/planting_service.dart';
import '../../services/monitoring_service.dart';
import '../../services/inventory_service.dart';
import '../../theme/premium_theme.dart' as theme;
import '../../utils/date_formatter.dart';
import '../../routes.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  final FarmService _farmService = FarmService();
  final TalhaoService _talhaoService = TalhaoService();
  final PlantingService _plantingService = PlantingService();
  final MonitoringService _monitoringService = MonitoringService();
  final InventoryService _inventoryService = InventoryService();

  bool _isLoading = true;
  bool _showWelcomeMessage = true;
  
  // Dados do dashboard
  List<Farm> _farms = [];
  List<TalhaoModel> _talhoes = [];
  List<Planting> _activePlantings = [];
  List<Monitoring> _monitorings = [];
  List<InventoryItem> _inventoryItems = [];
  
  // Estatísticas
  int _totalFarms = 0;
  int _totalTalhoes = 0;
  double _totalArea = 0.0;
  int _pendingMonitorings = 0;
  int _completedMonitorings = 0;
  int _highInfestationAlerts = 0;
  
  // Dados para gráficos
  List<FlSpot> _soyData = [];
  List<FlSpot> _cornData = [];
  List<BarChartGroupData> _rainfallData = [];

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
      // Carregar dados em paralelo
      await Future.wait([
        _loadFarms(),
        _loadTalhoes(),
        _loadPlantings(),
        _loadMonitorings(),
        _loadInventory(),
      ]);

      _calculateStatistics();
      _prepareChartData();

      setState(() {
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFarms() async {
    _farms = await _farmService.getAllFarms();
  }

  Future<void> _loadTalhoes() async {
    _talhoes = await _talhaoService.getAllTalhoes();
  }

  Future<void> _loadPlantings() async {
    _activePlantings = await _plantingService.getAllPlantings();
  }

  Future<void> _loadMonitorings() async {
    _monitorings = await _monitoringService.getAllMonitorings();
  }

  Future<void> _loadInventory() async {
    _inventoryItems = await _inventoryService.getAllItems();
  }

  void _calculateStatistics() {
    _totalFarms = _farms.length;
    _totalTalhoes = _talhoes.length;
    _totalArea = _talhoes.fold(0.0, (sum, talhao) => sum + (talhao.area ?? 0.0));
    
    _pendingMonitorings = _monitorings.where((m) => !m.isCompleted).length;
    _completedMonitorings = _monitorings.where((m) => m.isCompleted).length;
    _highInfestationAlerts = _monitorings.where((m) => m.points.any((p) => p.occurrences.any((o) => o.infestationIndex > 0.7))).length;
  }

  void _prepareChartData() {
    // Dados simulados para o gráfico de evolução da área plantada
    _soyData = [
      FlSpot(0, 0),
      FlSpot(1, 20),
      FlSpot(2, 35),
      FlSpot(3, 45),
      FlSpot(4, 50),
      FlSpot(5, 55),
    ];
    
    _cornData = [
      FlSpot(0, 0),
      FlSpot(1, 15),
      FlSpot(2, 25),
      FlSpot(3, 30),
      FlSpot(4, 35),
      FlSpot(5, 40),
    ];

    // Dados simulados para o gráfico de chuvas
    _rainfallData = [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15, color: Colors.blue)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 25, color: Colors.blue)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 30, color: Colors.blue)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 20, color: Colors.blue)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 35, color: Colors.blue)]),
      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 64, color: Colors.blue)]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
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
                    _buildIndicatorCards(),
                    const SizedBox(height: 24),
                    _buildAlertsSection(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
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
      backgroundColor: theme.PremiumTheme.primary,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/FortSmart.png',
            height: 32,
            width: 32,
          ),
          const SizedBox(width: 12),
          const Text(
            'Dashboard FortSmart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        Text(
          DateFormatter.formatDate(DateTime.now()),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadDashboardData,
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bem-vindo ao FortSmart! Os dados de exemplo serão substituídos pelos dados reais conforme você usar o aplicativo.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard FortSmart',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2A4F3D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Visão estratégica das operações da fazenda',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildFarmCard(),
        _buildTalhoesCard(),
        _buildPlantingsCard(),
        _buildMonitoringCard(),
        _buildRainCard(),
        _buildInventoryCard(),
      ],
    );
  }

  Widget _buildFarmCard() {
    return _buildIndicatorCard(
      icon: Icons.agriculture,
      title: 'Fazendas Cadastradas',
      value: _totalFarms.toString(),
      subtitle: 'Ativa',
      status: 'active',
      backgroundColor: Colors.green.shade50,
      iconColor: Colors.green,
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.farmList);
      },
    );
  }

  Widget _buildTalhoesCard() {
    return _buildIndicatorCard(
      icon: Icons.map,
      title: 'Talhões',
      value: _totalTalhoes.toString(),
      subtitle: '${_totalArea.toStringAsFixed(1)} ha',
      status: 'info',
      backgroundColor: Colors.blue.shade50,
      iconColor: Colors.blue,
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.talhoesSafra);
      },
    );
  }

  Widget _buildPlantingsCard() {
    final soyArea = _activePlantings
        .where((p) => p.cropName?.toLowerCase().contains('soja') == true)
        .fold(0.0, (sum, p) => sum + (p.area ?? 0.0));
    
    final cornArea = _activePlantings
        .where((p) => p.cropName?.toLowerCase().contains('milho') == true)
        .fold(0.0, (sum, p) => sum + (p.area ?? 0.0));

    return _buildIndicatorCard(
      icon: Icons.local_florist,
      title: 'Plantios Ativos',
      value: _activePlantings.length.toString(),
      subtitle: 'Soja (${soyArea.toStringAsFixed(1)} ha), Milho (${cornArea.toStringAsFixed(1)} ha)',
      status: 'active',
      backgroundColor: Colors.green.shade50,
      iconColor: Colors.green,
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.plantioHome);
      },
    );
  }

  Widget _buildMonitoringCard() {
    return _buildIndicatorCard(
      icon: Icons.bug_report,
      title: 'Monitoramentos',
      value: '$_pendingMonitorings Pendentes',
      subtitle: '$_completedMonitorings Realizados',
      status: _highInfestationAlerts > 0 ? 'warning' : 'info',
      backgroundColor: _highInfestationAlerts > 0 ? Colors.orange.shade50 : Colors.blue.shade50,
      iconColor: _highInfestationAlerts > 0 ? Colors.orange : Colors.blue,
      alert: _highInfestationAlerts > 0 ? '$_highInfestationAlerts talhões com infestação alta' : null,
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.advancedMonitoring);
      },
    );
  }

  Widget _buildRainCard() {
    return _buildIndicatorCard(
      icon: Icons.cloud,
      title: 'Chuvas',
      value: '21 mm',
      subtitle: '21/07/2025',
      status: 'info',
      backgroundColor: Colors.blue.shade50,
      iconColor: Colors.blue,
      chart: _buildRainfallChart(),
    );
  }

  Widget _buildInventoryCard() {
    final fertilizers = _inventoryItems.where((item) => item?.type == 'fertilizer').length;
    final pesticides = _inventoryItems.where((item) => item?.type == 'pesticide').length;
    final seeds = _inventoryItems.where((item) => item?.type == 'seed').length;

    return _buildIndicatorCard(
      icon: Icons.inventory,
      title: 'Estoque',
      value: '$fertilizers Fertilizantes',
      subtitle: '$pesticides Defensivos, $seeds Sementes',
      status: 'info',
      backgroundColor: Colors.yellow.shade50,
      iconColor: Colors.orange,
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.inventory);
      },
    );
  }

  Widget _buildIndicatorCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required String status,
    required Color backgroundColor,
    required Color iconColor,
    String? alert,
    Widget? chart,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Spacer(),
                  if (status == 'active')
                    const Icon(Icons.check_circle, color: Colors.green, size: 16)
                  else if (status == 'warning')
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A4F3D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (alert != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alert,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (chart != null) ...[
                const SizedBox(height: 8),
                SizedBox(height: 40, child: chart),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRainfallChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 70,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul'];
                if (value.toInt() < titles.length) {
                  return Text(
                    titles[value.toInt()],
                    style: const TextStyle(fontSize: 8),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _rainfallData,
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text(
                'Alertas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A4F3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_highInfestationAlerts > 0)
            _buildAlertItem(
              icon: Icons.bug_report,
              message: 'Talhão 02 com infestação acima do nível crítico',
              color: Colors.red,
              crop: 'Soja',
            )
          else
            _buildAlertItem(
              icon: Icons.check_circle,
              message: 'Nenhum alerta crítico no momento',
              color: Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required String message,
    required Color color,
    String? crop,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (crop != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                crop,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução da Área Plantada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A4F3D),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul'];
                        if (value.toInt() < titles.length) {
                          return Text(
                            titles[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()} ha',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 60,
                lineBarsData: [
                  LineChartBarData(
                    spots: _soyData,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: _cornData,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Soja', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('Milho', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                'Atividade Recente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A4F3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.add_location,
            title: 'Novo Talhão cadastrado',
            subtitle: '13,5 ha - 21/07',
            color: Colors.green,
          ),
          _buildActivityItem(
            icon: Icons.water_drop,
            title: 'Aplicação realizada',
            subtitle: 'Talhão 03 - 20/07',
            color: Colors.blue,
          ),
          _buildActivityItem(
            icon: Icons.local_florist,
            title: 'Plantio de Milho finalizado',
            subtitle: '18/07',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showQuickActions(context);
      },
      backgroundColor: theme.PremiumTheme.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Ações Rápidas',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ações Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.local_florist,
                    label: 'Novo Plantio',
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar para tela de novo plantio
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.bug_report,
                    label: 'Monitoramento',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed(AppRoutes.advancedMonitoring);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.camera_alt,
                    label: 'Foto Georref.',
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar para tela de foto georreferenciada
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.analytics,
                    label: 'Relatório Premium',
                    onTap: () {
                      Navigator.pop(context);
                      // Navegar para tela de relatórios
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.PremiumTheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Object? {
  get type => null;
}
