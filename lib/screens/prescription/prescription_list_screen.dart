import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../repositories/prescription_repository.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../screens/aplicacao/aplicacao_home_screen.dart';

class PrescriptionListScreen extends StatefulWidget {
  const PrescriptionListScreen({Key? key}) : super(key: key);

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  final PrescriptionRepository _repository = PrescriptionRepository();
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;
  bool _isFiltering = false;
  String _filterStatus = 'Todas';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prescriptions = await _repository.getAllPrescriptions();
      
      // Aplicar filtros se necessário
      List<Prescription> filteredList = prescriptions;
      
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar prescrições: $e')),
        );
      }
    }
  }

  Future<void> _showFilterDialog() async {
    final initialStatus = _filterStatus;
    final initialStartDate = _filterStartDate;
    final initialEndDate = _filterEndDate;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtrar Prescrições'),
          content: SingleChildScrollView(
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
                          ? DateFormatter.format(_filterStartDate!)
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
                          ? DateFormatter.format(_filterEndDate!)
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
          ),
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
                setState(() {
                  _isFiltering = _filterStatus != 'Todas' || 
                                _filterStartDate != null || 
                                _filterEndDate != null;
                });
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

  Future<void> _deletePrescription(Prescription prescription) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir esta prescrição? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _repository.deletePrescription(prescription.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescrição excluída com sucesso')),
        );
        _loadPrescriptions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir prescrição: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Prescrições Agronômicas',
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
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _prescriptions.isEmpty
              ? EmptyState(
                  icon: Icons.description,
                  title: 'Nenhuma prescrição encontrada',
                  message: _isFiltering
                      ? 'Nenhuma prescrição corresponde aos filtros aplicados. Tente ajustar os filtros ou criar uma nova prescrição.'
                      : 'Crie prescrições agronômicas para recomendar aplicações de produtos em suas lavouras.',
                  buttonText: 'Nova Prescrição',
                  onButtonPressed: () => _navigateToPrescriptionForm(context),
                )
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToPrescriptionForm(context),
        backgroundColor: const Color(0xFF2A4F3D),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPrescriptionDetails(context, prescription),
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
              Text(
                'Emissão: ${DateFormatter.format(prescription.issueDate)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Validade: ${DateFormatter.format(prescription.expiryDate)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Responsável: ${prescription.agronomistName}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Cultura: ${prescription.cropName}',
                style: const TextStyle(fontSize: 14),
              ),
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
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        onPressed: () => _generatePdf(prescription),
                        color: Colors.red.shade700,
                        tooltip: 'Gerar PDF',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _navigateToPrescriptionEdit(context, prescription),
                        color: Colors.blue,
                        tooltip: 'Editar',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deletePrescription(prescription),
                        color: Colors.red,
                        tooltip: 'Excluir',
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

  void _navigateToPrescriptionForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AplicacaoHomeScreen(),
      ),
    );
  }

  void _navigateToPrescriptionDetails(BuildContext context, Prescription prescription) {
    // Implementar navegação para os detalhes da prescrição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detalhes da prescrição serão implementados em breve'),
        // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }

  void _navigateToPrescriptionEdit(BuildContext context, Prescription prescription) {
    // Implementar navegação para a edição da prescrição
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edição de prescrição será implementada em breve'),
        // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
      ),
    );
  }
  
  Future<void> _generatePdf(Prescription prescription) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gerando PDF da prescrição...'),
          // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      // Aqui seria implementada a geração do PDF
      await Future.delayed(const Duration(seconds: 2)); // Simulação
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF gerado com sucesso!'),
          // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }
}
