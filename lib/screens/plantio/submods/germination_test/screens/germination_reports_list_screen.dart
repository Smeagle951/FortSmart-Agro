/// 📊 Lista de Relatórios de Germinação
/// 
/// Tela para selecionar testes e gerar relatórios

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../widgets/app_bar_widget.dart';
import '../providers/germination_test_provider.dart';
import '../models/germination_test_model.dart';
import 'germination_report_screen.dart';

class GerminationReportsListScreen extends StatefulWidget {
  const GerminationReportsListScreen({super.key});

  @override
  State<GerminationReportsListScreen> createState() => _GerminationReportsListScreenState();
}

class _GerminationReportsListScreenState extends State<GerminationReportsListScreen> {
  List<GerminationTest> _tests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'todos';

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final provider = Provider.of<GerminationTestProvider>(context, listen: false);
      await provider.ensureInitialized();
      
      if (provider.isReady) {
        await provider.loadTests();
        setState(() {
          _tests = provider.tests;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erro ao carregar testes: $e');
    }
  }

  List<GerminationTest> get _filteredTests {
    return _tests.where((test) {
      final matchesSearch = _searchQuery.isEmpty ||
          test.culture.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          test.variety.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          test.seedLot.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'todos' ||
          (_selectedStatus == 'ativos' && test.status == 'active') ||
          (_selectedStatus == 'completos' && test.status == 'completed') ||
          (_selectedStatus == 'cancelados' && test.status == 'cancelled');
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBarWidget(
        title: 'Relatórios de Germinação',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _buildTestsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Campo de busca
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por cultura, variedade ou lote...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filtro por status
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'ativos', child: Text('Ativos')),
                    DropdownMenuItem(value: 'completos', child: Text('Completos')),
                    DropdownMenuItem(value: 'cancelados', child: Text('Cancelados')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestsList() {
    final filteredTests = _filteredTests;
    
    if (filteredTests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedStatus == 'todos'
                  ? 'Nenhum teste encontrado'
                  : 'Nenhum teste corresponde aos filtros',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedStatus != 'todos') ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedStatus = 'todos';
                  });
                },
                child: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTests.length,
      itemBuilder: (context, index) {
        final test = filteredTests[index];
        return _buildTestCard(test);
      },
    );
  }

  Widget _buildTestCard(GerminationTest test) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openReport(test),
        borderRadius: BorderRadius.circular(12),
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
                      color: _getStatusColor(test.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      color: _getStatusColor(test.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.culture,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${test.variety} - ${test.seedLot}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(test.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Início',
                      _formatDate(test.startDate),
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Sementes',
                      '${test.totalSeeds}',
                      Icons.eco,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Status',
                      _getStatusText(test.status),
                      Icons.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openReport(test),
                    icon: const Icon(Icons.assessment, size: 16),
                    label: const Text('Ver Relatório'),
                    style: TextButton.styleFrom(
                      foregroundColor: FortSmartTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'completed':
        return 'Completo';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}';
  }

  void _openReport(GerminationTest test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GerminationReportScreen(test: test),
      ),
    );
  }
}
