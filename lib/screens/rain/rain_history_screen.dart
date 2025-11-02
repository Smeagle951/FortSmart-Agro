import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/logger.dart';
import '../../models/rain_data_model.dart';
import '../../repositories/rain_data_repository.dart';

/// Tela de histórico de chuva com relatórios
/// Mostra dados de precipitação em diferentes períodos
class RainHistoryScreen extends StatefulWidget {
  final String? stationId;
  final String? stationName;

  const RainHistoryScreen({
    Key? key,
    this.stationId,
    this.stationName,
  }) : super(key: key);

  @override
  State<RainHistoryScreen> createState() => _RainHistoryScreenState();
}

class _RainHistoryScreenState extends State<RainHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Mensal';
  List<String> _periods = ['Semanal', 'Mensal', 'Trimestral', 'Anual'];
  
  // Dados reais de chuva
  List<RainDataModel> _rainData = [];
  bool _isLoading = false;
  final RainDataRepository _repository = RainDataRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRainData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRainData() async {
    setState(() => _isLoading = true);
    
    try {
      final stationId = widget.stationId ?? 'CHUVA_001';
      final now = DateTime.now();
      
      DateTime startDate;
      DateTime endDate = now;
      
      switch (_selectedPeriod) {
        case 'Semanal':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Mensal':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'Trimestral':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case 'Anual':
          startDate = now.subtract(const Duration(days: 365));
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }
      
      // Carregar dados reais do repositório
      _rainData = await _repository.getRainDataByPeriod(stationId, startDate, endDate);
      
      // Se não houver dados, gerar dados simulados para demonstração
      if (_rainData.isEmpty) {
        Logger.info('📊 Nenhum dado encontrado, gerando dados simulados...');
        await _repository.generateSimulatedDataForOneYear();
        _rainData = await _repository.getRainDataByPeriod(stationId, startDate, endDate);
      }
      
      Logger.info('📊 Dados de chuva carregados: ${_rainData.length} registros');
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de chuva: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateSimulatedData() {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];
    
    // Dados semanais (últimas 4 semanas)
    for (int i = 0; i < 4; i++) {
      final week = now.subtract(Duration(days: i * 7));
      data.add({
        'period': 'Semanal',
        'date': week,
        'rainfall': 15.0 + (i * 5.0),
        'days': 7,
        'average': (15.0 + (i * 5.0)) / 7,
      });
    }
    
    // Dados mensais (últimos 12 meses)
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      data.add({
        'period': 'Mensal',
        'date': month,
        'rainfall': 80.0 + (i * 10.0),
        'days': 30,
        'average': (80.0 + (i * 10.0)) / 30,
      });
    }
    
    // Dados trimestrais (últimos 4 trimestres)
    for (int i = 0; i < 4; i++) {
      final quarter = DateTime(now.year, now.month - (i * 3), 1);
      data.add({
        'period': 'Trimestral',
        'date': quarter,
        'rainfall': 200.0 + (i * 50.0),
        'days': 90,
        'average': (200.0 + (i * 50.0)) / 90,
      });
    }
    
    // Dados anuais (últimos 5 anos)
    for (int i = 0; i < 5; i++) {
      final year = DateTime(now.year - i, 1, 1);
      data.add({
        'period': 'Anual',
        'date': year,
        'rainfall': 1200.0 + (i * 100.0),
        'days': 365,
        'average': (1200.0 + (i * 100.0)) / 365,
      });
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.stationName ?? 'Histórico de Chuva',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2D9CDB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Semanal', icon: Icon(Icons.calendar_view_week)),
            Tab(text: 'Mensal', icon: Icon(Icons.calendar_view_month)),
            Tab(text: 'Trimestral', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Anual', icon: Icon(Icons.calendar_view_year)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyReport(),
                _buildMonthlyReport(),
                _buildQuarterlyReport(),
                _buildYearlyReport(),
              ],
            ),
    );
  }

  Widget _buildWeeklyReport() {
    final weeklyData = _rainData;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard('Semanal', weeklyData),
          const SizedBox(height: 20),
          _buildChart(weeklyData, 'Últimas 4 Semanas'),
          const SizedBox(height: 20),
          _buildDataTable(weeklyData),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    final monthlyData = _rainData;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard('Mensal', monthlyData),
          const SizedBox(height: 20),
          _buildChart(monthlyData, 'Últimos 12 Meses'),
          const SizedBox(height: 20),
          _buildDataTable(monthlyData),
        ],
      ),
    );
  }

  Widget _buildQuarterlyReport() {
    final quarterlyData = _rainData;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard('Trimestral', quarterlyData),
          const SizedBox(height: 20),
          _buildChart(quarterlyData, 'Últimos 4 Trimestres'),
          const SizedBox(height: 20),
          _buildDataTable(quarterlyData),
        ],
      ),
    );
  }

  Widget _buildYearlyReport() {
    final yearlyData = _rainData;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard('Anual', yearlyData),
          const SizedBox(height: 20),
          _buildChart(yearlyData, 'Últimos 5 Anos'),
          const SizedBox(height: 20),
          _buildDataTable(yearlyData),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String period, List<RainDataModel> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    
    final totalRainfall = data.fold<double>(0, (sum, item) => sum + item.rainfall);
    final averageRainfall = totalRainfall / data.length;
    final maxRainfall = data.map((d) => d.rainfall).reduce((a, b) => a > b ? a : b);
    final minRainfall = data.map((d) => d.rainfall).reduce((a, b) => a < b ? a : b);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatório $period',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${data.length} períodos analisados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${totalRainfall.toStringAsFixed(1)}mm',
                  Colors.blue,
                  Icons.water_drop,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Média',
                  '${averageRainfall.toStringAsFixed(1)}mm',
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Máximo',
                  '${maxRainfall.toStringAsFixed(1)}mm',
                  Colors.orange,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Mínimo',
                  '${minRainfall.toStringAsFixed(1)}mm',
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<RainDataModel> data, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.rainfall);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<RainDataModel> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados Detalhados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.grey[300]!),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[100]),
                children: [
                  _buildTableCell('Data', isHeader: true),
                  _buildTableCell('Chuva (mm)', isHeader: true),
                  _buildTableCell('Tipo', isHeader: true),
                ],
              ),
              ...data.map((item) => TableRow(
                children: [
                  _buildTableCell(_formatDate(item.dateTime)),
                  _buildTableCell('${item.rainfall.toStringAsFixed(1)}'),
                  _buildTableCell('${item.rainType}'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (date.year == DateTime.now().year) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
