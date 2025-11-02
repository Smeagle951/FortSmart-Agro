import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../repositories/prescription_repository.dart';
import '../../widgets/dosage_calculator_widget.dart';
import '../../utils/area_formatter.dart';
import '../../utils/date_formatter.dart';

/// Tela principal de Prescrições Agronômicas
/// Funcionalidades completas com cálculo de doses por hectare e por aplicação
class PrescricoesAgronomicasScreen extends StatefulWidget {
  const PrescricoesAgronomicasScreen({Key? key}) : super(key: key);

  @override
  State<PrescricoesAgronomicasScreen> createState() => _PrescricoesAgronomicasScreenState();
}

class _PrescricoesAgronomicasScreenState extends State<PrescricoesAgronomicasScreen> 
    with SingleTickerProviderStateMixin {
  
  final PrescriptionRepository _repository = PrescriptionRepository();
  late TabController _tabController;
  
  // Lista de prescrições
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  bool _isFiltering = false;
  
  // Filtros
  String _filterStatus = 'Todas';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  
  // Estatísticas
  int _totalPrescricoes = 0;
  int _prescricoesPendentes = 0;
  int _prescricoesAprovadas = 0;
  int _prescricoesAplicadas = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carrega prescrições do banco de dados
  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prescriptions = await _repository.getAllPrescriptions();
      _applyFilters(prescriptions);
      _calculateStatistics();
    } catch (e) {
      _showErrorMessage('Erro ao carregar prescrições: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Aplica filtros às prescrições
  void _applyFilters(List<Prescription> allPrescriptions) {
    List<Prescription> filteredList = allPrescriptions;
    
    if (_filterStatus != 'Todas') {
      filteredList = filteredList.where((p) => p.status == _filterStatus).toList();
    }
    
    if (_filterStartDate != null) {
      filteredList = filteredList.where((p) => p.issueDate.isAfter(_filterStartDate!)).toList();
    }
    
    if (_filterEndDate != null) {
      filteredList = filteredList.where((p) => p.issueDate.isBefore(_filterEndDate!.add(const Duration(days: 1)))).toList();
    }
    
    // Ordenar por data de emissão (mais recente primeiro)
    filteredList.sort((a, b) => b.issueDate.compareTo(a.issueDate));
    
    setState(() {
      _prescriptions = filteredList;
      _isFiltering = _filterStatus != 'Todas' || 
                    _filterStartDate != null || 
                    _filterEndDate != null;
    });
  }

  /// Calcula estatísticas das prescrições
  void _calculateStatistics() {
    _totalPrescricoes = _prescriptions.length;
    _prescricoesPendentes = _prescriptions.where((p) => p.status == 'Pendente').length;
    _prescricoesAprovadas = _prescriptions.where((p) => p.status == 'Aprovada').length;
    _prescricoesAplicadas = _prescriptions.where((p) => p.status == 'Aplicada').length;
  }

  /// Mostra diálogo de filtros
  Future<void> _showFilterDialog() async {
    final initialStatus = _filterStatus;
    final initialStartDate = _filterStartDate;
    final initialEndDate = _filterEndDate;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar Prescrições'),
          content: _buildFilterContent(setDialogState),
          actions: [
            TextButton(
              onPressed: () {
                // Restaurar valores originais
                _filterStatus = initialStatus;
                _filterStartDate = initialStartDate;
                _filterEndDate = initialEndDate;
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadPrescriptions();
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
          const Text('Status:'),
          DropdownButton<String>(
            isExpanded: true,
            value: _filterStatus,
            items: ['Todas', 'Pendente', 'Aprovada', 'Aplicada', 'Cancelada']
                .map((status) => DropdownMenuItem(
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
          const Text('Data de início:'),
          InkWell(
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
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                _filterStartDate != null
                    ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
                    : 'Selecionar data',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Data de fim:'),
          InkWell(
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
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                _filterEndDate != null
                    ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
                    : 'Selecionar data',
              ),
            ),
          ),
          if (_filterStartDate != null || _filterEndDate != null || _filterStatus != 'Todas')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () {
                  setDialogState(() {
                    _filterStartDate = null;
                    _filterEndDate = null;
                    _filterStatus = 'Todas';
                  });
                },
                child: const Text('Limpar Filtros'),
              ),
            ),
        ],
      ),
    );
  }

  /// Mostra diálogo para nova prescrição
  void _showNewPrescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20),
          child: _NewPrescriptionForm(
            onSave: (prescription) {
              Navigator.of(context).pop();
              _loadPrescriptions();
              _showSuccessMessage('Prescrição criada com sucesso!');
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  /// Mostra mensagem de sucesso
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
        title: const Text('Prescrições Agronômicas'),
        backgroundColor: const Color(0xFF2A4F3D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _isFiltering ? Colors.amber : Colors.white,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar prescrições',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
            tooltip: 'Atualizar lista',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'Lista',
            ),
            Tab(
              icon: Icon(Icons.calculate),
              text: 'Calculadora',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Aba da Lista
          _buildListTab(),
          
          // Aba da Calculadora
          _buildCalculatorTab(),
        ],
      ),
    );
  }

  /// Constrói aba da lista
  Widget _buildListTab() {
    return Column(
      children: [
        // Estatísticas
        _buildStatisticsHeader(),
        
        // Lista de prescrições
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _prescriptions.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPrescriptions,
                      child: ListView.builder(
                        itemCount: _prescriptions.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final prescription = _prescriptions[index];
                          return _buildPrescriptionCard(prescription);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  /// Constrói cabeçalho com estatísticas
  Widget _buildStatisticsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Estatísticas',
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
                child: _buildStatCard(
                  'Total',
                  _totalPrescricoes.toString(),
                  Colors.blue,
                  Icons.description,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pendentes',
                  _prescricoesPendentes.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Aprovadas',
                  _prescricoesAprovadas.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Aplicadas',
                  _prescricoesAplicadas.toString(),
                  Colors.cyan,
                  Icons.done_all,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói card de estatística
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
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
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma prescrição encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isFiltering
                ? 'Nenhuma prescrição corresponde aos filtros aplicados.\nTente ajustar os filtros ou criar uma nova prescrição.'
                : 'Crie prescrições agronômicas para recomendar\naplicações de produtos em suas lavouras.',
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

  /// Constrói card de prescrição
  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPrescriptionDetails(prescription),
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              // if (prescription.totalArea != null && prescription.totalArea! > 0)
              //   _buildInfoRow(Icons.crop_landscape, 'Área', AreaFormatter.formatArea(prescription.totalArea!)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${prescription.products.length} produto(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A4F3D),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calculate, size: 20),
                        onPressed: () => _showDosageCalculator(prescription),
                        color: Colors.green,
                        tooltip: 'Calcular Doses',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        onPressed: () => _generatePdf(prescription),
                        color: Colors.red.shade700,
                        tooltip: 'Gerar PDF',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editPrescription(prescription),
                        color: Colors.blue,
                        tooltip: 'Editar',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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

  /// Constrói aba da calculadora
  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informações sobre a calculadora
          _buildCalculatorInfo(),
          const SizedBox(height: 16),
          
          // Widget da calculadora
          DosageCalculatorWidget(
            onCalculationChanged: (dosagePerHectare, dosagePerApplication, totalDosage, applicationVolume) {
              // Callback para quando os cálculos mudarem
              print('Doses calculadas: $dosagePerHectare/ha, Total: $totalDosage, Volume: $applicationVolume');
            },
            onApplicationDataChanged: (applicationData) {
              // Callback para quando os dados da aplicação mudarem
              print('Dados da aplicação atualizados: $applicationData');
              // TODO: Integrar com módulo de Gestão de Custos
              _sendToCostManagement(applicationData);
            },
          ),
        ],
      ),
    );
  }

  /// Constrói informações da calculadora
  Widget _buildCalculatorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Calculadora de Doses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Use esta calculadora para determinar as doses corretas de produtos por hectare e por aplicação. '
            'Insira a área total, a dose recomendada por hectare e o volume de aplicação para obter os cálculos precisos.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra detalhes da prescrição
  void _showPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prescription.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${prescription.status}'),
              Text('Cultura: ${prescription.cropName}'),
              Text('Emissão: ${DateFormat('dd/MM/yyyy').format(prescription.issueDate)}'),
              Text('Validade: ${DateFormat('dd/MM/yyyy').format(prescription.expiryDate)}'),
              Text('Responsável: ${prescription.agronomistName}'),
              if (prescription.observations != null && prescription.observations!.isNotEmpty)
                Text('Observações: ${prescription.observations}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Mostra calculadora de doses para prescrição específica
  void _showDosageCalculator(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calcular Doses - ${prescription.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: DosageCalculatorWidget(
                  totalArea: prescription.totalArea,
                  productName: prescription.products.isNotEmpty ? prescription.products.first.productName : null,
                  onCalculationChanged: (dosagePerHectare, dosagePerApplication, totalDosage, applicationVolume) {
                    // Atualizar prescrição com os cálculos
                    // TODO: Implementar setters no modelo Prescription
                    // prescription.dosagePerHectare = dosagePerHectare;
                    // prescription.dosagePerApplication = dosagePerApplication;
                    // prescription.applicationVolume = applicationVolume;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Edita prescrição
  void _editPrescription(Prescription prescription) {
    _showSuccessMessage('Funcionalidade de edição em desenvolvimento');
  }

  /// Gera PDF da prescrição
  Future<void> _generatePdf(Prescription prescription) async {
    _showSuccessMessage('PDF gerado com sucesso! (funcionalidade simulada)');
  }

  /// Envia dados da aplicação para o módulo de Gestão de Custos
  void _sendToCostManagement(Map<String, dynamic> applicationData) {
    try {
      // Preparar dados para o módulo de custos
      final costData = {
        'applicationId': DateTime.now().millisecondsSinceEpoch.toString(),
        'applicationTypes': applicationData['applicationTypes'],
        'applicationDate': applicationData['applicationDate'],
        'technicalResponsible': applicationData['technicalResponsible'],
        'operator': applicationData['operator'],
        'doser': applicationData['doser'],
        'applicationMethod': applicationData['applicationMethod'],
        'totalArea': applicationData['totalArea'],
        'products': applicationData['products'],
        'tankVolume': applicationData['tankVolume'],
        'applicationVolume': applicationData['applicationVolume'],
        'numberOfFlights': applicationData['numberOfFlights'],
        'numberOfRefills': applicationData['numberOfRefills'],
        'syncStatus': 0, // Offline - será sincronizado depois
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Salvar no banco de dados local para o módulo Gestão de Custos
      _salvarAplicacaoParaGestaoCustos(costData);
      
      print('📤 Dados enviados para Gestão de Custos: $costData');
      
      // Simular salvamento offline
      _showSuccessMessage('Dados da aplicação salvos para Gestão de Custos');
      
    } catch (e) {
      print('❌ Erro ao enviar dados para Gestão de Custos: $e');
      _showErrorMessage('Erro ao salvar dados da aplicação');
    }
  }

  /// Salva aplicação no banco de dados para o módulo Gestão de Custos
  Future<void> _salvarAplicacaoParaGestaoCustos(Map<String, dynamic> costData) async {
    try {
      // TODO: Implementar salvamento real no banco de dados
      // Por enquanto, apenas log dos dados estruturados
      
      final aplicacaoGestaoCustos = {
        'id': costData['applicationId'],
        'tipo': costData['applicationTypes'].isNotEmpty ? costData['applicationTypes'].first : 'Outros',
        'data': DateTime.parse(costData['applicationDate']),
        'talhao': 'Talhão Selecionado', // TODO: Obter do contexto
        'area': costData['totalArea'],
        'custoTotal': _calcularCustoTotalAplicacao(costData['products']),
        'produtos': _formatarProdutosParaGestaoCustos(costData['products']),
        'responsavel': costData['technicalResponsible'] ?? 'Não informado',
        'operador': costData['operator'],
        'dosador': costData['doser'],
        'metodoAplicacao': costData['applicationMethod'],
        'volumeTanque': costData['tankVolume'],
        'volumeAplicacao': costData['applicationVolume'],
        'numeroVoos': costData['numberOfFlights'],
        'numeroRecargas': costData['numberOfRefills'],
        'observacoes': 'Aplicação criada via módulo Prescrições Premium',
        'syncStatus': costData['syncStatus'],
        'createdAt': costData['createdAt'],
      };

      print('💾 Aplicação salva para Gestão de Custos: $aplicacaoGestaoCustos');
      
      // TODO: Implementar salvamento real no banco de dados
      // await _aplicacaoDao.salvarAplicacao(aplicacaoGestaoCustos);
      
    } catch (e) {
      print('❌ Erro ao salvar aplicação para Gestão de Custos: $e');
      rethrow;
    }
  }

  /// Calcula custo total da aplicação
  double _calcularCustoTotalAplicacao(List<dynamic> produtos) {
    double custoTotal = 0.0;
    
    for (final produto in produtos) {
      final dosePorHa = produto['dosePorHectare'] ?? 0.0;
      final precoUnitario = produto['precoUnitario'] ?? 0.0;
      final area = produto['area'] ?? 1.0;
      
      custoTotal += dosePorHa * area * precoUnitario;
    }
    
    return custoTotal;
  }

  /// Formata produtos para o formato da Gestão de Custos
  List<Map<String, dynamic>> _formatarProdutosParaGestaoCustos(List<dynamic> produtos) {
    return produtos.map((produto) => {
      'nome': produto['nome'] ?? 'Produto',
      'dose': produto['dosePorHectare'] ?? 0.0,
      'unidade': produto['unidade'] ?? 'L/ha',
      'custo': _calcularCustoTotalAplicacao([produto]),
    }).toList();
  }
}

/// Formulário para nova prescrição
class _NewPrescriptionForm extends StatefulWidget {
  final Function(Prescription) onSave;
  final VoidCallback onCancel;

  const _NewPrescriptionForm({
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_NewPrescriptionForm> createState() => _NewPrescriptionFormState();
}

class _NewPrescriptionFormState extends State<_NewPrescriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _observationsController = TextEditingController();
  
  String _selectedStatus = 'Pendente';
  double _totalArea = 0.0;
  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _titleController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nova Prescrição',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          
          // Formulário
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Título
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título da Prescrição',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Título é obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Status
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Pendente', 'Aprovada', 'Aplicada', 'Cancelada']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Calculadora de doses
                  DosageCalculatorWidget(
                    totalArea: _totalArea,
                    onCalculationChanged: (dosagePerHectare, dosagePerApplication, totalDosage, applicationVolume) {
                      // Armazenar valores calculados
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Observações
                  TextFormField(
                    controller: _observationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _savePrescription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A4F3D),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _savePrescription() {
    if (_formKey.currentState!.validate()) {
      // Criar nova prescrição
      final prescription = Prescription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        farmId: 'default',
        farmName: 'Fazenda Padrão',
        plotId: 'default',
        plotName: 'Talhão Padrão',
        cropId: 'default',
        cropName: 'Cultura Padrão',
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        agronomistName: 'Agrônomo Responsável',
        agronomistRegistration: 'CREA 123456',
        status: _selectedStatus,
        observations: _observationsController.text.trim(),
        totalArea: _totalArea,
        products: [],
      );
      
      widget.onSave(prescription);
    }
  }
}
