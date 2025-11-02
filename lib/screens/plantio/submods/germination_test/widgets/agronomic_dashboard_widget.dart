/// 📊 DASHBOARD AGRONÔMICO - VERSÃO SIMPLIFICADA
/// 
/// Dashboard que exibe resultados agronômicos calculados
/// Foco em relatórios profissionais sem componentes de IA

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../services/agronomic_calculation_engine.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';

/// 📊 Dashboard Principal de Análise Agronômica
class AgronomicDashboardWidget extends StatefulWidget {
  final int testId;
  final GerminationTest test;
  
  const AgronomicDashboardWidget({
    Key? key,
    required this.testId,
    required this.test,
  }) : super(key: key);

  @override
  State<AgronomicDashboardWidget> createState() => _AgronomicDashboardWidgetState();
}

class _AgronomicDashboardWidgetState extends State<AgronomicDashboardWidget> {
  
  // Dados
  AgronomicResults? _agronomicResults;
  List<GerminationDailyRecord> _dailyRecords = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      // Carregar registros diários
      // _dailyRecords = await provider.getDailyRecords(widget.testId);
      
      _calculateResults();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _calculateResults() {
    if (_dailyRecords.isEmpty) return;
    
    final results = AgronomicCalculationEngine.calculateCompleteResults(
      dailyRecords: _dailyRecords,
      totalSeeds: widget.test.totalSeeds,
      culture: widget.test.culture,
      variety: widget.test.variety,
      testStartDate: widget.test.startDate,
    );
    
    setState(() {
      _agronomicResults = results;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Agronômico'),
        backgroundColor: Colors.green.shade600,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_agronomicResults != null) ...[
                    _buildResultsCards(),
                    const SizedBox(height: 24),
                    _buildClassificationCard(),
                  ] else
                    _buildNoDataCard(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.test.culture,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Variedade: ${widget.test.variety}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Lote: ${widget.test.seedLot}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Germinação',
                '${(_agronomicResults!.germinationPercentage ?? 0.0).toStringAsFixed(1)}%',
                Icons.grass,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Vigor',
                '${(_agronomicResults!.vigorIndex ?? 0.0).toStringAsFixed(1)}%',
                Icons.energy_savings_leaf,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Pureza',
                '${_agronomicResults!.purityPercentage.toStringAsFixed(1)}%',
                Icons.check_circle,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Contaminação',
                '${_agronomicResults!.contaminationPercentage.toStringAsFixed(1)}%',
                Icons.warning,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildClassificationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Classificação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _getClassificationIcon(_agronomicResults!.classification),
                  color: _getClassificationColor(_agronomicResults!.classification),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  _agronomicResults!.classification,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getClassificationColor(_agronomicResults!.classification),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoDataCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhum registro diário encontrado',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getClassificationIcon(String classification) {
    switch (classification) {
      case 'EXCELENTE': return Icons.star;
      case 'APROVADO': return Icons.check_circle;
      case 'CONDICIONAL': return Icons.warning;
      default: return Icons.cancel;
    }
  }
  
  Color _getClassificationColor(String classification) {
    switch (classification) {
      case 'EXCELENTE': return Colors.green;
      case 'APROVADO': return Colors.blue;
      case 'CONDICIONAL': return Colors.orange;
      default: return Colors.red;
    }
  }
}

