import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../repositories/prescription_repository.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';
import 'prescription_form_screen.dart';
import '../../utils/pdf_generator.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailsScreen({
    Key? key,
    required this.prescriptionId,
  }) : super(key: key);

  @override
  State<PrescriptionDetailsScreen> createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  final PrescriptionRepository _repository = PrescriptionRepository();

  Prescription? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _prescription = await _repository.getPrescriptionById(widget.prescriptionId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar prescrição: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePrescription() async {
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

      if (confirmed == true && _prescription != null) {
        await _repository.deletePrescription(_prescription!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescrição excluída com sucesso')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir prescrição: $e')),
        );
      }
    }
  }

  Future<void> _editPrescription() async {
    if (_prescription == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionFormScreen(prescription: _prescription),
      ),
    );
    
    if (result == true) {
      _loadPrescription();
    }
  }

  Future<void> _generatePdf() async {
    if (_prescription == null) return;
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gerando PDF da prescrição...'),
          // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
      
      final success = await PdfGenerator.generatePrescriptionPdf(_prescription!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF gerado com sucesso!'),
            // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao gerar PDF'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
          ),
        );
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Detalhes da Prescrição',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _prescription != null ? _editPrescription : null,
            tooltip: 'Editar Prescrição',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _prescription != null ? _generatePdf : null,
            tooltip: 'Gerar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _prescription != null ? _deletePrescription : null,
            tooltip: 'Excluir Prescrição',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _prescription == null
              ? const Center(child: Text('Prescrição não encontrada'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _prescription!.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(_prescription!.status),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Seção de Informações Gerais
                      _buildSectionTitle('Informações Gerais'),
                      _buildInfoCard([
                        _buildInfoRow('Data de Emissão', DateFormatter.format(_prescription!.issueDate)),
                        _buildInfoRow('Data de Validade', DateFormatter.format(_prescription!.expiryDate)),
                        _buildInfoRow('Responsável Técnico', _prescription!.agronomistName),
                        _buildInfoRow('Registro Profissional', _prescription!.agronomistRegistration),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Seção de Localização
                      _buildSectionTitle('Localização'),
                      _buildInfoCard([
                        _buildInfoRow('Fazenda', _prescription!.farmName),
                        _buildInfoRow('Talhão', _prescription!.plotName),
                        _buildInfoRow('Cultura', _prescription!.cropName),
                      ]),
                      const SizedBox(height: 24),
                      
                      // Seção de Alvos
                      if (_prescription!.targetPest != null ||
                          _prescription!.targetDisease != null ||
                          _prescription!.targetWeed != null) ...[
                        _buildSectionTitle('Alvos'),
                        _buildInfoCard([
                          if (_prescription!.targetPest != null)
                            _buildInfoRow('Praga', _prescription!.targetPest!),
                          if (_prescription!.targetDisease != null)
                            _buildInfoRow('Doença', _prescription!.targetDisease!),
                          if (_prescription!.targetWeed != null)
                            _buildInfoRow('Planta Daninha', _prescription!.targetWeed!),
                        ]),
                        const SizedBox(height: 24),
                      ],
                      
                      // Seção de Produtos
                      _buildSectionTitle('Produtos Recomendados'),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prescription!.products.length,
                        itemBuilder: (context, index) {
                          final product = _prescription!.products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.productName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Dosagem', '${product.dosage} ${product.dosageUnit}'),
                                  _buildInfoRow('Método de Aplicação', product.applicationMethod),
                                  if (product.observations != null)
                                    _buildInfoRow('Observações', product.observations!),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Seção de Informações Adicionais
                      if (_prescription!.observations != null ||
                          _prescription!.applicationConditions != null ||
                          _prescription!.safetyInstructions != null) ...[
                        _buildSectionTitle('Informações Adicionais'),
                        _buildInfoCard([
                          if (_prescription!.observations != null)
                            _buildInfoRow('Observações', _prescription!.observations!),
                          if (_prescription!.applicationConditions != null)
                            _buildInfoRow('Condições de Aplicação', _prescription!.applicationConditions!),
                          if (_prescription!.safetyInstructions != null)
                            _buildInfoRow('Instruções de Segurança', _prescription!.safetyInstructions!),
                        ]),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2A4F3D),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
