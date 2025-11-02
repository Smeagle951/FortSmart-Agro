import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/fertilizer_calibration.dart';
import '../../repositories/fertilizer_calibration_repository.dart';
import '../../widgets/fertilizer_distribution_chart.dart';

/// Tela de histórico de calibrações de fertilizantes
class FertilizerCalibrationHistoryScreen extends StatefulWidget {
  const FertilizerCalibrationHistoryScreen({super.key});

  @override
  State<FertilizerCalibrationHistoryScreen> createState() => _FertilizerCalibrationHistoryScreenState();
}

class _FertilizerCalibrationHistoryScreenState extends State<FertilizerCalibrationHistoryScreen> {
  final _repository = FertilizerCalibrationRepository();
  
  // Estados
  bool _isLoading = true;
  List<FertilizerCalibration> _calibrations = [];
  List<FertilizerCalibration> _filteredCalibrations = [];
  Map<String, dynamic> _statistics = {};
  
  // Filtros
  String _selectedFertilizer = 'Todos';
  String _selectedCVStatus = 'Todos';
  String _searchQuery = '';
  
  // Fertilizantes únicos
  List<String> _fertilizers = ['Todos'];
  List<String> _cvStatuses = ['Todos', 'Bom', 'Moderado', 'Crítico'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carrega os dados
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await _repository.initialize();
      final calibrations = await _repository.getAll();
      final statistics = await _repository.getStatistics();
      
      setState(() {
        _calibrations = calibrations;
        _filteredCalibrations = calibrations;
        _statistics = statistics;
        _fertilizers = ['Todos', ...calibrations.map((c) => c.fertilizerName).toSet().toList()];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  /// Aplica os filtros
  void _applyFilters() {
    setState(() {
      _filteredCalibrations = _calibrations.where((calibration) {
        // Filtro por fertilizante
        if (_selectedFertilizer != 'Todos' && 
            calibration.fertilizerName != _selectedFertilizer) {
          return false;
        }
        
        // Filtro por status do CV
        if (_selectedCVStatus != 'Todos' && 
            calibration.cvStatus != _selectedCVStatus) {
          return false;
        }
        
        // Filtro por busca
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return calibration.fertilizerName.toLowerCase().contains(query) ||
                 calibration.operator.toLowerCase().contains(query) ||
                 (calibration.machine?.toLowerCase().contains(query) ?? false);
        }
        
        return true;
      }).toList();
    });
  }

  /// Obtém a cor do status do CV
  Color _getCVStatusColor(String status) {
    switch (status) {
      case 'Bom':
        return Colors.green;
      case 'Moderado':
        return Colors.orange;
      case 'Crítico':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtém o ícone do status do CV
  IconData _getCVStatusIcon(String status) {
    switch (status) {
      case 'Bom':
        return Icons.check_circle;
      case 'Moderado':
        return Icons.warning;
      case 'Crítico':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Exibe detalhes da calibração
  void _showCalibrationDetails(FertilizerCalibration calibration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: Color(0xFF0057A3)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            calibration.fertilizerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(calibration.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações básicas
                      _buildInfoCard(calibration),
                      const SizedBox(height: 16),
                      
                      // Resultados
                      _buildResultsCard(calibration),
                      const SizedBox(height: 16),
                      
                      // Gráfico
                      _buildChartCard(calibration),
                      const SizedBox(height: 16),
                      
                      // Ações
                      _buildActionsCard(calibration),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói card de informações básicas
  Widget _buildInfoCard(FertilizerCalibration calibration) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações da Calibração',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Operador', calibration.operator),
            if (calibration.machine != null)
              _buildInfoRow('Máquina', calibration.machine!),
            _buildInfoRow('Granulometria', '${calibration.granulometry.toStringAsFixed(0)} g/L'),
            _buildInfoRow('Faixa Esperada', '${calibration.expectedWidth?.toStringAsFixed(1) ?? 'N/A'} m'),
            _buildInfoRow('Espaçamento', '${calibration.spacing.toStringAsFixed(1)} m'),
            _buildInfoRow('Bandejas', '${calibration.weights.length}'),
          ],
        ),
      ),
    );
  }

  /// Constrói card de resultados
  Widget _buildResultsCard(FertilizerCalibration calibration) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            // CV
            Row(
              children: [
                Icon(
                  _getCVStatusIcon(calibration.cvStatus),
                  color: _getCVStatusColor(calibration.cvStatus),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CV: ${calibration.coefficientOfVariation.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getCVStatusColor(calibration.cvStatus),
                        ),
                      ),
                      Text(
                        'Status: ${calibration.cvStatus}',
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
            const SizedBox(height: 12),
            
            // Faixa efetiva
            Row(
              children: [
                Icon(
                  calibration.widthStatus == 'OK' ? Icons.check_circle : Icons.warning,
                  color: calibration.widthStatus == 'OK' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faixa: ${calibration.realWidth.toStringAsFixed(1)}m / ${calibration.expectedWidth?.toStringAsFixed(1) ?? 'N/A'}m',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: calibration.widthStatus == 'OK' ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        'Status: ${calibration.widthStatus}',
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
            const SizedBox(height: 12),
            
            // Estatísticas
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Média', '${calibration.averageWeight.toStringAsFixed(1)}g'),
                ),
                Expanded(
                  child: _buildStatItem('Desvio', '${calibration.standardDeviation.toStringAsFixed(1)}g'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card do gráfico
  Widget _buildChartCard(FertilizerCalibration calibration) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: FertilizerDistributionChart(
                calibration: calibration,
                height: 230,
                showLegend: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói card de ações
  Widget _buildActionsCard(FertilizerCalibration calibration) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar exportação PDF
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar compartilhamento
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma linha de informação
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item de estatística
  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Calibrações',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0057A3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                _buildStatistics(),
                Expanded(child: _buildCalibrationsList()),
              ],
            ),
    );
  }

  /// Constrói os filtros
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Busca
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          
          // Filtros dropdown
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFertilizer,
                  decoration: const InputDecoration(
                    labelText: 'Fertilizante',
                    border: OutlineInputBorder(),
                  ),
                  items: _fertilizers.map((fertilizer) {
                    return DropdownMenuItem(
                      value: fertilizer,
                      child: Text(fertilizer),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFertilizer = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCVStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status CV',
                    border: OutlineInputBorder(),
                  ),
                  items: _cvStatuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCVStatus = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói as estatísticas
  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              '${_statistics['total'] ?? 0}',
              Icons.list,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'CV Médio',
              '${(_statistics['averageCV'] ?? 0.0).toStringAsFixed(1)}%',
              Icons.analytics,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Filtrados',
              '${_filteredCalibrations.length}',
              Icons.filter_list,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um card de estatística
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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

  /// Constrói a lista de calibrações
  Widget _buildCalibrationsList() {
    if (_filteredCalibrations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma calibração encontrada',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCalibrations.length,
      itemBuilder: (context, index) {
        final calibration = _filteredCalibrations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCVStatusColor(calibration.cvStatus).withOpacity(0.2),
              child: Icon(
                _getCVStatusIcon(calibration.cvStatus),
                color: _getCVStatusColor(calibration.cvStatus),
              ),
            ),
            title: Text(
              calibration.fertilizerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${DateFormat('dd/MM/yyyy HH:mm').format(calibration.date)} • ${calibration.operator}'),
                Row(
                  children: [
                    Text(
                      'CV: ${calibration.coefficientOfVariation.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getCVStatusColor(calibration.cvStatus),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Faixa: ${calibration.realWidth.toStringAsFixed(1)}m',
                      style: TextStyle(
                        color: calibration.widthStatus == 'OK' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCalibrationDetails(calibration),
          ),
        );
      },
    );
  }
} 