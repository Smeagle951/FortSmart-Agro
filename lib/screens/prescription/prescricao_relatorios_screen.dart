import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../repositories/prescription_repository.dart';

/// Tela de Relatórios de Prescrições Agronômicas
class PrescricaoRelatoriosScreen extends StatefulWidget {
  const PrescricaoRelatoriosScreen({Key? key}) : super(key: key);

  @override
  State<PrescricaoRelatoriosScreen> createState() => _PrescricaoRelatoriosScreenState();
}

class _PrescricaoRelatoriosScreenState extends State<PrescricaoRelatoriosScreen> 
    with SingleTickerProviderStateMixin {
  
  final PrescriptionRepository _repository = PrescriptionRepository();
  late TabController _tabController;
  
  // Dados do relatório
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  
  // Filtros
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _filterStatus = 'Todas';
  String _filterCrop = 'Todas';
  
  // Estatísticas
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega dados para o relatório
  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prescriptions = await _repository.getAllPrescriptions();
      _applyFilters(prescriptions);
      _calculateStatistics();
    } catch (e) {
      _showErrorMessage('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Aplica filtros aos dados
  void _applyFilters(List<Prescription> allPrescriptions) {
    List<Prescription> filteredList = allPrescriptions;
    
    if (_filterStatus != 'Todas') {
      filteredList = filteredList.where((p) => p.status == _filterStatus).toList();
    }
    
    if (_filterCrop != 'Todas') {
      filteredList = filteredList.where((p) => p.cropName == _filterCrop).toList();
    }
    
    if (_filterStartDate != null) {
      filteredList = filteredList.where((p) => p.issueDate.isAfter(_filterStartDate!)).toList();
    }
    
    if (_filterEndDate != null) {
      filteredList = filteredList.where((p) => p.issueDate.isBefore(_filterEndDate!.add(const Duration(days: 1)))).toList();
    }
    
    setState(() {
      _prescriptions = filteredList;
    });
  }

  /// Calcula estatísticas
  void _calculateStatistics() {
    final total = _prescriptions.length;
    final porStatus = <String, int>{};
    final porCultura = <String, int>{};
    final porMes = <String, int>{};
    
    for (final prescription in _prescriptions) {
      // Por status
      porStatus[prescription.status] = (porStatus[prescription.status] ?? 0) + 1;
      
      // Por cultura
      porCultura[prescription.cropName] = (porCultura[prescription.cropName] ?? 0) + 1;
      
      // Por mês
      final mes = DateFormat('MM/yyyy').format(prescription.issueDate);
      porMes[mes] = (porMes[mes] ?? 0) + 1;
    }
    
    setState(() {
      _statistics = {
        'total': total,
        'porStatus': porStatus,
        'porCultura': porCultura,
        'porMes': porMes,
      };
    });
  }

  /// Mostra diálogo de filtros
  Future<void> _showFilterDialog() async {
    final initialStartDate = _filterStartDate;
    final initialEndDate = _filterEndDate;
    final initialStatus = _filterStatus;
    final initialCrop = _filterCrop;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar Relatório'),
          content: _buildFilterContent(setDialogState),
          actions: [
            TextButton(
              onPressed: () {
                // Restaurar valores originais
                _filterStartDate = initialStartDate;
                _filterEndDate = initialEndDate;
                _filterStatus = initialStatus;
                _filterCrop = initialCrop;
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadReportData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A4F3D),
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói conteúdo do filtro
  Widget _buildFilterContent(StateSetter setDialogState) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Período:'),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        _filterStartDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Text(
                      _filterStartDate != null
                          ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
                          : 'Data início',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        _filterEndDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Text(
                      _filterEndDate != null
                          ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
                          : 'Data fim',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Status:'),
          DropdownButton<String>(
            isExpanded: true,
            value: _filterStatus,
            items: ['Todas', 'Pendente', 'Aprovada', 'Aplicada', 'Cancelada']
                .map<DropdownMenuItem<String>>((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() {
                  _filterStatus = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Cultura:'),
          DropdownButton<String>(
            isExpanded: true,
            value: _filterCrop,
            items: ['Todas', ..._statistics['porCultura']?.keys.toList() ?? []]
                .map<DropdownMenuItem<String>>((crop) => DropdownMenuItem<String>(
                      value: crop,
                      child: Text(crop),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() {
                  _filterCrop = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// Mostra mensagem de erro
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Prescrições'),
        backgroundColor: const Color(0xFF2A4F3D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar relatório',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Atualizar dados',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Resumo',
            ),
            Tab(
              icon: Icon(Icons.bar_chart),
              text: 'Gráficos',
            ),
            Tab(
              icon: Icon(Icons.table_chart),
              text: 'Detalhado',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildChartsTab(),
                _buildDetailedTab(),
              ],
            ),
    );
  }

  /// Constrói aba de resumo
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de estatísticas principais
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Prescrições',
                  _statistics['total']?.toString() ?? '0',
                  Colors.blue,
                  Icons.description,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pendentes',
                  _statistics['porStatus']?['Pendente']?.toString() ?? '0',
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Aprovadas',
                  _statistics['porStatus']?['Aprovada']?.toString() ?? '0',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Aplicadas',
                  _statistics['porStatus']?['Aplicada']?.toString() ?? '0',
                  Colors.cyan,
                  Icons.done_all,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Distribuição por status
          _buildSectionTitle('Distribuição por Status'),
          const SizedBox(height: 12),
          ...(_statistics['porStatus'] as Map<String, int>? ?? {}).entries.map((entry) {
            final total = _statistics['total'] as int? ?? 1;
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return _buildProgressItem(entry.key, entry.value, percentage);
          }).toList(),
          
          const SizedBox(height: 24),
          
          // Distribuição por cultura
          _buildSectionTitle('Distribuição por Cultura'),
          const SizedBox(height: 12),
          ...(_statistics['porCultura'] as Map<String, int>? ?? {}).entries.map((entry) {
            final total = _statistics['total'] as int? ?? 1;
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return _buildProgressItem(entry.key, entry.value, percentage);
          }).toList(),
        ],
      ),
    );
  }

  /// Constrói aba de gráficos
  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gráfico de pizza por status
          _buildSectionTitle('Prescrições por Status'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Gráfico de Pizza\n(Em desenvolvimento)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Gráfico de barras por cultura
          _buildSectionTitle('Prescrições por Cultura'),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Gráfico de Barras\n(Em desenvolvimento)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói aba detalhada
  Widget _buildDetailedTab() {
    return Column(
      children: [
        // Cabeçalho com informações do filtro
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mostrando ${_prescriptions.length} prescrições',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _exportReport,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exportar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2A4F3D),
                ),
              ),
            ],
          ),
        ),
        
        // Lista detalhada
        Expanded(
          child: _prescriptions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _prescriptions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final prescription = _prescriptions[index];
                    return _buildDetailedCard(prescription);
                  },
                ),
        ),
      ],
    );
  }

  /// Constrói card de estatística
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói item de progresso
  Widget _buildProgressItem(String label, int value, String percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$value ($percentage%)',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói título de seção
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2A4F3D),
      ),
    );
  }

  /// Constrói estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum dado encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste os filtros ou verifique se há prescrições cadastradas.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói card detalhado
  Widget _buildDetailedCard(Prescription prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    prescription.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(prescription.status),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Emissão', DateFormat('dd/MM/yyyy').format(prescription.issueDate)),
            _buildInfoRow(Icons.event_available, 'Validade', DateFormat('dd/MM/yyyy').format(prescription.expiryDate)),
            _buildInfoRow(Icons.person, 'Responsável', prescription.agronomistName),
            _buildInfoRow(Icons.agriculture, 'Cultura', prescription.cropName),
            _buildInfoRow(Icons.inventory, 'Produtos', '${prescription.products.length} produto(s)'),
          ],
        ),
      ),
    );
  }

  /// Constrói linha de informação
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói chip de status
  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'aprovada':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pendente':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'aplicada':
        color = Colors.blue;
        icon = Icons.done_all;
        break;
      case 'cancelada':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Exporta relatório
  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de exportação em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
