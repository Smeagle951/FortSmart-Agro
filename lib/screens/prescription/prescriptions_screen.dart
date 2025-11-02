import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/prescription_repository.dart';
import '../../models/prescription.dart';
import 'add_prescription_screen.dart';
import 'prescription_details_screen.dart';

class PrescriptionsScreen extends StatefulWidget {
  final int? soilAnalysisId;
  
  const PrescriptionsScreen({Key? key, this.soilAnalysisId}) : super(key: key);

  @override
  _PrescriptionsScreenState createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final PrescriptionRepository _repository = PrescriptionRepository();
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

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
      if (widget.soilAnalysisId != null) {
        _prescriptions = await _repository.getPrescriptionsBySoilAnalysisId(widget.soilAnalysisId!);
      } else {
        _prescriptions = await _repository.getAllPrescriptions();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar prescrições: $e')),
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
        title: const Text('Prescrições'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? _buildEmptyState()
              : _buildPrescriptionsList(),
      floatingActionButton: widget.soilAnalysisId != null
          ? FloatingActionButton(
              onPressed: () => _navigateToAddPrescription(),
              child: const Icon(Icons.add),
              tooltip: 'Adicionar Prescrição',
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma prescrição encontrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'As prescrições são geradas a partir de análises de solo',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (widget.soilAnalysisId != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddPrescription(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Prescrição'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    return ListView.builder(
      itemCount: _prescriptions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final prescription = _prescriptions[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _navigateToPrescriptionDetails(prescription),
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
                          prescription.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(prescription.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (prescription.description != null &&
                      prescription.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        prescription.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      _buildInfoChip(
                        'ID Análise: ${prescription.soilAnalysisId}',
                        Icons.science,
                      ),
                      const SizedBox(width: 8),
                      if (prescription.targetCrop != null &&
                          prescription.targetCrop!.isNotEmpty)
                        _buildInfoChip(
                          prescription.targetCrop!,
                          Icons.grass,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (prescription.area != null)
                        _buildInfoText('Área: ${prescription.area!.toStringAsFixed(2)} ha'),
                      if (prescription.expectedYield != null)
                        _buildInfoText(
                            'Produtividade: ${prescription.expectedYield!.toStringAsFixed(2)} t/ha'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: const EdgeInsets.all(4),
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    );
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

  void _navigateToAddPrescription() async {
    if (widget.soilAnalysisId == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPrescriptionScreen(
          soilAnalysisId: widget.soilAnalysisId!,
        ),
      ),
    );

    if (result == true) {
      _loadPrescriptions();
    }
  }

  void _navigateToPrescriptionDetails(Prescription prescription) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionDetailsScreen(
          prescriptionId: prescription.id!,
        ),
      ),
    );

    if (result == true) {
      _loadPrescriptions();
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
                leading: const Icon(Icons.grass),
                title: const Text('Filtrar por cultura'),
                onTap: () {
                  Navigator.pop(context);
                  _showCropFilter();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Limpar filtros'),
                onTap: () {
                  Navigator.pop(context);
                  _loadPrescriptions();
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
      _prescriptions = await _repository.getPrescriptionsByDateRange(start, end);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao filtrar prescrições: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCropFilter() async {
    // Obter lista de culturas únicas
    final crops = <String>{};
    for (var prescription in _prescriptions) {
      if (prescription.targetCrop != null && prescription.targetCrop!.isNotEmpty) {
        crops.add(prescription.targetCrop!);
      }
    }

    if (crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma cultura encontrada')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione a Cultura'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: crops.map((crop) {
              return ListTile(
                title: Text(crop),
                onTap: () {
                  Navigator.pop(context);
                  _filterByCrop(crop);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _filterByCrop(String crop) {
    setState(() {
      _prescriptions = _prescriptions
          .where((p) => p.targetCrop == crop)
          .toList();
    });
  }
}
