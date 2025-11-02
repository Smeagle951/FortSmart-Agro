import 'package:flutter/material.dart';
import '../../models/fertilizer_calibration.dart';
import '../../repositories/fertilizer_calibration_repository.dart';
import '../../widgets/fertilizer_trend_chart.dart';
import '../../widgets/professional_result_card.dart';

/// Tela para visualizar tendências temporais de calibrações
class FertilizerTrendScreen extends StatefulWidget {
  const FertilizerTrendScreen({super.key});

  @override
  State<FertilizerTrendScreen> createState() => _FertizerTrendScreenState();
}

class _FertizerTrendScreenState extends State<FertilizerTrendScreen>
    with TickerProviderStateMixin {
  final FertilizerCalibrationRepository _repository = FertilizerCalibrationRepository();
  
  List<FertilizerCalibration> _calibrations = [];
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;
  
  // Filtros
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedMachine;
  List<String> _availableMachines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final calibrations = await _repository.getAll();
      
      // Extrair máquinas únicas
      final machines = calibrations.map((c) => c.machine).toSet().toList();
      machines.sort();
      
      setState(() {
        _calibrations = calibrations;
        _availableMachines = machines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<FertilizerCalibration> get _filteredCalibrations {
    var filtered = _calibrations;
    
    // Filtrar por data
    if (_startDate != null) {
      filtered = filtered.where((c) => c.date.isAfter(_startDate!) || c.date.isAtSameMomentAs(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((c) => c.date.isBefore(_endDate!) || c.date.isAtSameMomentAs(_endDate!)).toList();
    }
    
    // Filtrar por máquina
    if (_selectedMachine != null && _selectedMachine!.isNotEmpty) {
      filtered = filtered.where((c) => c.machine == _selectedMachine).toList();
    }
    
    // Ordenar por data
    filtered.sort((a, b) => a.date.compareTo(b.date));
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tendências de Calibração',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0057A3),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Taxa Real', icon: Icon(Icons.trending_up)),
            Tab(text: 'CV%', icon: Icon(Icons.analytics)),
            Tab(text: 'Multimétrica', icon: Icon(Icons.multiline_chart)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando histórico...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_filteredCalibrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma calibração encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Realize calibrações para ver as tendências',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCards(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRateTrendTab(),
              _buildCVTrendTab(),
              _buildMultiMetricTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final filtered = _filteredCalibrations;
    if (filtered.isEmpty) return const SizedBox.shrink();

    final latest = filtered.last;
    final avgRate = filtered.map((c) => c.realApplicationRate).reduce((a, b) => a + b) / filtered.length;
    final avgCV = filtered.map((c) => c.coefficientOfVariation).reduce((a, b) => a + b) / filtered.length;
    final avgError = filtered.map((c) => c.errorPercentage.abs()).reduce((a, b) => a + b) / filtered.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ProfessionalResultCard(
              title: 'Última Taxa',
              value: '${latest.realApplicationRate.toStringAsFixed(1)} kg/ha',
              subtitle: 'Mais recente',
              icon: Icons.trending_up,
              primaryColor: const Color(0xFF1976D2),
              tooltip: 'Taxa real da última calibração',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfessionalResultCard(
              title: 'Média CV%',
              value: '${avgCV.toStringAsFixed(1)}%',
              subtitle: '${filtered.length} calibrações',
              icon: Icons.analytics,
              primaryColor: const Color(0xFF4CAF50),
              tooltip: 'Média do coeficiente de variação',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfessionalResultCard(
              title: 'Erro Médio',
              value: '${avgError.toStringAsFixed(1)}%',
              subtitle: 'Precisão',
              icon: Icons.warning,
              primaryColor: avgError < 5 ? Colors.green : avgError < 10 ? Colors.orange : Colors.red,
              tooltip: 'Erro médio em relação à taxa desejada',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateTrendTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Evolução da Taxa Real',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FertilizerTrendChart(
              calibrations: _filteredCalibrations,
              showRateTrend: true,
              showCVTrend: false,
              height: 300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCVTrendTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Evolução do Coeficiente de Variação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FertilizerTrendChart(
              calibrations: _filteredCalibrations,
              showRateTrend: false,
              showCVTrend: true,
              height: 300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiMetricTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Análise Multimétrica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: MultiMetricTrendChart(
              calibrations: _filteredCalibrations,
              metrics: [
                TrendMetrics.realRate,
                TrendMetrics.cv,
                TrendMetrics.error,
              ],
              height: 300,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFiltersSheet(),
    );
  }

  Widget _buildFiltersSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedMachine = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Filtro de máquina
          DropdownButtonFormField<String>(
            value: _selectedMachine,
            decoration: const InputDecoration(
              labelText: 'Máquina',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todas as máquinas'),
              ),
              ..._availableMachines.map((machine) => DropdownMenuItem<String>(
                value: machine,
                child: Text(machine),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMachine = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Filtro de data
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Data Inicial'),
                  subtitle: Text(_startDate?.toString().split(' ')[0] ?? 'Não definida'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Data Final'),
                  subtitle: Text(_endDate?.toString().split(' ')[0] ?? 'Não definida'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Botão aplicar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0057A3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Aplicar Filtros',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
