import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/soil_analysis_repository.dart';
import '../../database/models/soil_analysis.dart';
import '../../services/agricultural_calculator.dart';
import 'add_soil_analysis_screen.dart';
import 'soil_analysis_details_screen.dart';

class SoilAnalysesScreen extends StatefulWidget {
  final int? monitoringId;
  
  const SoilAnalysesScreen({Key? key, this.monitoringId}) : super(key: key);

  @override
  _SoilAnalysesScreenState createState() => _SoilAnalysesScreenState();
}

class _SoilAnalysesScreenState extends State<SoilAnalysesScreen> {
  final SoilAnalysisRepository _repository = SoilAnalysisRepository();
  final AgriculturalCalculator _calculator = AgriculturalCalculator();
  List<SoilAnalysis> _analyses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.monitoringId != null) {
        _analyses = await _repository.getAnalysesByMonitoringId(widget.monitoringId!);
      } else {
        _analyses = await _repository.getAllSoilAnalyses();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar análises: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análises de Solo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyses.isEmpty
              ? _buildEmptyState()
              : _buildAnalysesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAnalysis(),
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Análise',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.science_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma análise de solo encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione sua primeira análise de solo',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddAnalysis(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Análise'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysesList() {
    return ListView.builder(
      itemCount: _analyses.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final analysis = _analyses[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            // onTap: () => _navigateToAnalysisDetails(analysis), // onTap não é suportado em Polygon no flutter_map 5.0.0
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Análise #${analysis.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(analysis.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAnalysisProperty(
                    'pH',
                    analysis.ph?.toStringAsFixed(2) ?? 'N/A',
                    _getPhColor(analysis.ph),
                  ),
                  _buildAnalysisProperty(
                    'Matéria Orgânica',
                    analysis.organicMatter != null
                        ? '${analysis.organicMatter!.toStringAsFixed(2)}%'
                        : 'N/A',
                    null,
                  ),
                  _buildAnalysisProperty(
                    'Fósforo',
                    analysis.phosphorus != null
                        ? '${analysis.phosphorus!.toStringAsFixed(2)} mg/dm³'
                        : 'N/A',
                    null,
                  ),
                  _buildAnalysisProperty(
                    'Potássio',
                    analysis.potassium != null
                        ? '${analysis.potassium!.toStringAsFixed(2)} mmolc/dm³'
                        : 'N/A',
                    null,
                  ),
                  const SizedBox(height: 8),
                  if (analysis.ph != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _calculator.interpretSoilPh(analysis.ph!),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisProperty(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhColor(double? ph) {
    if (ph == null) return Colors.grey;
    
    if (ph < 5.0) return Colors.red;
    if (ph < 5.5) return Colors.orange;
    if (ph < 6.5) return Colors.green;
    if (ph < 7.5) return Colors.blue;
    return Colors.purple;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Data desconhecida';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Data inválida';
    }
  }

  void _navigateToAddAnalysis() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSoilAnalysisScreen(
          monitoringId: widget.monitoringId,
        ),
      ),
    );

    if (result == true) {
      _loadAnalyses();
    }
  }

  void _navigateToAnalysisDetails(SoilAnalysis analysis) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoilAnalysisDetailsScreen(
          analysisId: analysis.id!,
        ),
      ),
    );

    if (result == true) {
      _loadAnalyses();
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Filtrar por período'),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangeFilter();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Ordenar por pH'),
                onTap: () {
                  Navigator.pop(context);
                  _sortByPh();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Limpar filtros'),
                onTap: () {
                  Navigator.pop(context);
                  _loadAnalyses();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDateRangeFilter() async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );

    if (dateRange != null) {
      _filterByDateRange(dateRange.start, dateRange.end);
    }
  }

  void _filterByDateRange(DateTime start, DateTime end) async {
    setState(() {
      _isLoading = true;
    });

    try {
      _analyses = await _repository.getAnalysesByDateRange(start, end);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao filtrar análises: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortByPh() {
    setState(() {
      _analyses.sort((a, b) {
        if (a.ph == null && b.ph == null) return 0;
        if (a.ph == null) return 1;
        if (b.ph == null) return -1;
        return a.ph!.compareTo(b.ph!);
      });
    });
  }
}
