import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../repositories/soil_analysis_repository.dart';
import '../../repositories/prescription_repository.dart';
import '../../database/models/soil_analysis.dart';
import '../../database/models/prescription.dart';
import '../../database/models/prescription_item.dart';
import '../../services/agricultural_calculator.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final int? soilAnalysisId;
  final int? prescriptionId; // Se fornecido, estamos editando uma prescrição existente

  const AddPrescriptionScreen({
    Key? key,
    this.soilAnalysisId,
    this.prescriptionId,
  }) : super(key: key);

  @override
  _AddPrescriptionScreenState createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final SoilAnalysisRepository _analysisRepository = SoilAnalysisRepository();
  final PrescriptionRepository _prescriptionRepository = PrescriptionRepository();
  final AgriculturalCalculator _calculator = AgriculturalCalculator();

  bool _isLoading = true;
  bool _isEditing = false;
  SoilAnalysis? _analysis;
  List<PrescriptionItem> _prescriptionItems = [];
  
  // Controladores para os campos do formulário
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetCropController = TextEditingController();
  final _areaController = TextEditingController();
  final _expectedYieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.prescriptionId != null;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar análise de solo
      if (widget.soilAnalysisId != null) {
        _analysis = await _analysisRepository.getSoilAnalysisById(widget.soilAnalysisId!);
        
        if (_analysis == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Análise de solo não encontrada')),
          );
          Navigator.pop(context);
          return;
        }
      }

      if (_isEditing) {
        // Carregar dados da prescrição existente
        final prescription = await _prescriptionRepository.getPrescriptionById(widget.prescriptionId!);
        
        if (prescription != null) {
          _nameController.text = prescription.name;
          _descriptionController.text = prescription.description ?? '';
          _targetCropController.text = prescription.targetCrop ?? '';
          _areaController.text = prescription.area?.toString() ?? '';
          _expectedYieldController.text = prescription.expectedYield?.toString() ?? '';
          
          // Carregar itens da prescrição
          _prescriptionItems = await _prescriptionRepository.getPrescriptionItems(prescription.id!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prescrição não encontrada')),
          );
          Navigator.pop(context);
        }
      } else {
        // Gerar recomendações iniciais baseadas na análise de solo
        if (widget.soilAnalysisId != null) {
          _generateInitialRecommendations();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateInitialRecommendations() {
    if (_analysis == null) return;

    // Definir nome padrão para a prescrição
    final dateFormat = DateFormat('dd/MM/yyyy');
    final today = dateFormat.format(DateTime.now());
    _nameController.text = 'Prescrição ${today}';

    // Adicionar recomendações iniciais com base na análise
    _prescriptionItems = [];

    // Verificar necessidade de calagem (correção de pH)
    if (_analysis!.ph != null && _analysis!.ph! < 5.5) {
      final limeAmount = _calculator.calculateLimeRequirement(
        _analysis!.ph!,
        _analysis!.cationExchangeCapacity ?? 0,
        _analysis!.baseSaturation ?? 0,
      );
      
      if (limeAmount > 0) {
        _prescriptionItems.add(PrescriptionItem(
          id: 0,
          prescriptionId: 0, // Será atualizado ao salvar
          productName: 'Calcário Dolomítico',
          dosage: limeAmount,
          dosageUnit: 'ton/ha',
          category: 'Corretivo',
          notes: 'Aplicar para elevar o pH do solo',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    }

    // Verificar necessidade de fósforo
    if (_analysis!.phosphorus != null && _analysis!.phosphorus! < 10) {
      final phosphorusAmount = _calculator.calculatePhosphorusRequirement(
        _analysis!.phosphorus!,
        _analysis!.clayContent ?? 30, // valor padrão se não disponível
      );
      
      if (phosphorusAmount > 0) {
        _prescriptionItems.add(PrescriptionItem(
          id: 0,
          prescriptionId: 0, // Será atualizado ao salvar
          productName: 'Superfosfato Simples',
          dosage: phosphorusAmount,
          dosageUnit: 'kg/ha',
          category: 'Fertilizante',
          notes: 'Aplicar para corrigir deficiência de fósforo',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    }

    // Verificar necessidade de potássio
    if (_analysis!.potassium != null && _analysis!.potassium! < 1.5) {
      final potassiumAmount = _calculator.calculatePotassiumRequirement(
        _analysis!.potassium!,
        _analysis!.cationExchangeCapacity ?? 0,
      );
      
      if (potassiumAmount > 0) {
        _prescriptionItems.add(PrescriptionItem(
          id: 0,
          prescriptionId: 0, // Será atualizado ao salvar
          productName: 'Cloreto de Potássio',
          dosage: potassiumAmount,
          dosageUnit: 'kg/ha',
          category: 'Fertilizante',
          notes: 'Aplicar para corrigir deficiência de potássio',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ));
      }
    }

    // Adicionar recomendação de matéria orgânica se necessário
    if (_analysis!.organicMatter != null && _analysis!.organicMatter! < 2.0) {
      _prescriptionItems.add(PrescriptionItem(
        id: 0,
        prescriptionId: 0, // Será atualizado ao salvar
        productName: 'Composto Orgânico',
        dosage: 5.0,
        dosageUnit: 'ton/ha',
        category: 'Corretivo',
        notes: 'Aplicar para melhorar teor de matéria orgânica',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetCropController.dispose();
    _areaController.dispose();
    _expectedYieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Prescrição' : 'Nova Prescrição'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnalysisInfoCard(),
                    const SizedBox(height: 16),
                    _buildPrescriptionForm(),
                    const SizedBox(height: 16),
                    _buildPrescriptionItemsSection(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _savePrescription,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditing ? 'Atualizar Prescrição' : 'Salvar Prescrição',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAnalysisInfoCard() {
    if (_analysis == null) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análise de Solo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            _buildInfoRow('ID da Análise', '${_analysis!.id}'),
            _buildInfoRow('pH', _analysis!.ph?.toStringAsFixed(2) ?? 'N/A'),
            _buildInfoRow(
              'Fósforo',
              _analysis!.phosphorus != null
                  ? '${_analysis!.phosphorus!.toStringAsFixed(2)} mg/dm³'
                  : 'N/A',
            ),
            _buildInfoRow(
              'Potássio',
              _analysis!.potassium != null
                  ? '${_analysis!.potassium!.toStringAsFixed(2)} mmolc/dm³'
                  : 'N/A',
            ),
            _buildInfoRow(
              'Saturação por Bases',
              _analysis!.baseSaturation != null
                  ? '${_analysis!.baseSaturation!.toStringAsFixed(2)}%'
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionForm() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da Prescrição',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Prescrição *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe um nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetCropController,
              decoration: const InputDecoration(
                labelText: 'Cultura Alvo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Área (ha)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _expectedYieldController,
                    decoration: const InputDecoration(
                      labelText: 'Produtividade Esperada (t/ha)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionItemsSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itens da Prescrição',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Item'),
                ),
              ],
            ),
            const Divider(),
            _prescriptionItems.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhum item adicionado à prescrição',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prescriptionItems.length,
                    itemBuilder: (context, index) {
                      final item = _prescriptionItems[index];
                      return _buildPrescriptionItemCard(item, index);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionItemCard(PrescriptionItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          item.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoria: ${item.category}'),
            Text('Quantidade: ${item.dosage.toStringAsFixed(2)} ${item.dosageUnit}'),
            if (item.notes != null && item.notes!.isNotEmpty)
              Text('Observações: ${item.notes}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditItemDialog(item, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final unitController = TextEditingController(text: 'kg/ha');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto *',
                ),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                ),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade *',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unidade *',
                ),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Validar campos obrigatórios
              if (nameController.text.isEmpty ||
                  categoryController.text.isEmpty ||
                  amountController.text.isEmpty ||
                  unitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
                );
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantidade inválida')),
                );
                return;
              }

              // Adicionar novo item
              setState(() {
                _prescriptionItems.add(PrescriptionItem(
                  id: 0,
                  prescriptionId: 0, // Será atualizado ao salvar
                  productName: nameController.text,
                  dosage: amount,
                  dosageUnit: unitController.text,
                  category: categoryController.text,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                  createdAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                ));
              });

              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(PrescriptionItem item, int index) {
    final nameController = TextEditingController(text: item.productName);
    final categoryController = TextEditingController(text: item.category);
    final amountController = TextEditingController(text: item.dosage.toString());
    final unitController = TextEditingController(text: item.dosageUnit);
    final notesController = TextEditingController(text: item.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto *',
                ),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                ),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade *',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unidade *',
                ),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Validar campos obrigatórios
              if (nameController.text.isEmpty ||
                  categoryController.text.isEmpty ||
                  amountController.text.isEmpty ||
                  unitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
                );
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantidade inválida')),
                );
                return;
              }

              // Atualizar item
              setState(() {
                _prescriptionItems[index] = PrescriptionItem(
                  id: item.id,
                  prescriptionId: item.prescriptionId,
                  productName: nameController.text,
                  dosage: amount,
                  dosageUnit: unitController.text,
                  category: categoryController.text,
                  notes: notesController.text.isNotEmpty ? notesController.text : null,
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now().toIso8601String(),
                );
              });

              Navigator.pop(context);
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _prescriptionItems.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_prescriptionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um item à prescrição')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Converter valores dos campos para double
      final area = _areaController.text.isNotEmpty
          ? double.parse(_areaController.text)
          : null;
      final expectedYield = _expectedYieldController.text.isNotEmpty
          ? double.parse(_expectedYieldController.text)
          : null;

      int prescriptionId;
      
      if (_isEditing) {
        // Atualizar prescrição existente
        await _prescriptionRepository.updatePrescription(
          id: widget.prescriptionId!,
          title: _nameController.text,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          targetCrop: _targetCropController.text.isNotEmpty ? _targetCropController.text : null,
          area: area,
          expectedYield: expectedYield,
        );
        
        prescriptionId = widget.prescriptionId!;
        
        // Excluir itens existentes
        await _prescriptionRepository.deletePrescriptionItems(prescriptionId);
      } else {
        // Adicionar nova prescrição
        prescriptionId = await _prescriptionRepository.addPrescription(
          plotId: 1, // Valor padrão, deve ser substituído pelo valor real
          title: _nameController.text,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          prescriptionDate: DateTime.now(),
          targetCrop: _targetCropController.text.isNotEmpty ? _targetCropController.text : null,
          area: area,
          expectedYield: expectedYield,
          soilAnalysisId: widget.soilAnalysisId,
        );
      }

      // Adicionar itens da prescrição
      for (var item in _prescriptionItems) {
        await _prescriptionRepository.addPrescriptionItem(
          prescriptionId: prescriptionId,
          productName: item.productName,
          dosage: item.dosage,
          dosageUnit: item.dosageUnit,
          category: item.category,
          notes: item.notes,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Prescrição atualizada com sucesso'
              : 'Prescrição criada com sucesso'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar prescrição: $e')),
      );
    }
  }
}
