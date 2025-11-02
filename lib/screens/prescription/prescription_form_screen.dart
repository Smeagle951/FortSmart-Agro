import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../repositories/prescription_repository.dart';
import '../../repositories/farm_repository.dart';
import '../../repositories/plot_repository.dart';
import '../../repositories/crop_repository.dart';
import '../../repositories/agricultural_product_repository.dart';
import '../../models/farm.dart';
import '../../models/plot.dart';
import '../../models/crop.dart';
import '../../models/agricultural_product.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final Prescription? prescription;

  const PrescriptionFormScreen({Key? key, this.prescription}) : super(key: key);

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prescriptionRepository = PrescriptionRepository();
  final _farmRepository = FarmRepository();
  final _plotRepository = PlotRepository();
  final _cropRepository = CropRepository();
  final _productRepository = AgriculturalProductRepository();

  final _titleController = TextEditingController();
  final _agronomistNameController = TextEditingController();
  final _agronomistRegistrationController = TextEditingController();
  final _observationsController = TextEditingController();
  final _applicationConditionsController = TextEditingController();
  final _safetyInstructionsController = TextEditingController();
  final _targetPestController = TextEditingController();
  final _targetDiseaseController = TextEditingController();
  final _targetWeedController = TextEditingController();

  DateTime _issueDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'Pendente';
  
  Farm? _selectedFarm;
  Plot? _selectedPlot;
  Crop? _selectedCrop;
  
  List<Farm> _farms = [];
  List<Plot> _plots = [];
  List<Crop> _crops = [];
  List<AgriculturalProduct> _availableProducts = [];
  List<PrescriptionProduct> _selectedProducts = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.prescription != null;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar fazendas
      _farms = await _farmRepository.getAllFarms();
      
      // Carregar produtos disponíveis
      _availableProducts = await _productRepository.getAllProducts();
      
      // Se estiver editando, preencher o formulário com os dados da prescrição
      if (_isEditing) {
        final prescription = widget.prescription!;
        
        _titleController.text = prescription.title;
        _agronomistNameController.text = prescription.agronomistName;
        _agronomistRegistrationController.text = prescription.agronomistRegistration;
        _observationsController.text = prescription.observations ?? '';
        _applicationConditionsController.text = prescription.applicationConditions ?? '';
        _safetyInstructionsController.text = prescription.safetyInstructions ?? '';
        _targetPestController.text = prescription.targetPest ?? '';
        _targetDiseaseController.text = prescription.targetDisease ?? '';
        _targetWeedController.text = prescription.targetWeed ?? '';
        
        _issueDate = prescription.issueDate;
        _expiryDate = prescription.expiryDate;
        _status = prescription.status;
        _selectedProducts = List.from(prescription.products);
        
        // Selecionar fazenda
        _selectedFarm = _farms.firstWhere(
          (farm) => farm.id == prescription.farmId,
          orElse: () => _farms.isNotEmpty ? _farms.first : null,
        );
        
        if (_selectedFarm != null) {
          // Carregar talhões da fazenda selecionada
          _plots = await _plotRepository.getPlotsByFarm(_selectedFarm!.id);
          
          // Selecionar talhão
          _selectedPlot = _plots.firstWhere(
            (plot) => plot.id == prescription.plotId,
            orElse: () => _plots.isNotEmpty ? _plots.first : null,
          );
          
          if (_selectedPlot != null) {
            // Carregar culturas do talhão selecionado
            _crops = await _cropRepository.getCropsByPlot(_selectedPlot!.id);
            
            // Selecionar cultura
            _selectedCrop = _crops.firstWhere(
              (crop) => crop.id == prescription.cropId,
              orElse: () => _crops.isNotEmpty ? _crops.first : null,
            );
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onFarmChanged(Farm? farm) async {
    if (farm == null) return;
    
    setState(() {
      _isLoading = true;
      _selectedFarm = farm;
      _selectedPlot = null;
      _selectedCrop = null;
    });
    
    try {
      _plots = await _plotRepository.getPlotsByFarm(farm.id);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar talhões: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onPlotChanged(Plot? plot) async {
    if (plot == null) return;
    
    setState(() {
      _isLoading = true;
      _selectedPlot = plot;
      _selectedCrop = null;
    });
    
    try {
      _crops = await _cropRepository.getCropsByPlot(plot.id);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar culturas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCropChanged(Crop? crop) {
    setState(() {
      _selectedCrop = crop;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime initialDate = isIssueDate ? _issueDate : _expiryDate;
    final DateTime firstDate = isIssueDate 
        ? DateTime.now().subtract(const Duration(days: 30)) 
        : _issueDate;
    final DateTime lastDate = isIssueDate 
        ? DateTime.now().add(const Duration(days: 30)) 
        : _issueDate.add(const Duration(days: 365));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          // Ajustar a data de validade se necessário
          if (_expiryDate.isBefore(_issueDate)) {
            _expiryDate = _issueDate.add(const Duration(days: 30));
          }
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  void _showAddProductDialog() {
    AgriculturalProduct? selectedProduct;
    final dosageController = TextEditingController();
    final dosageUnitController = TextEditingController(text: 'L/ha');
    final applicationMethodController = TextEditingController();
    final observationsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<AgriculturalProduct>(
                decoration: const InputDecoration(
                  labelText: 'Produto',
                  border: OutlineInputBorder(),
                ),
                value: null,
                items: _availableProducts
                    .map((product) => DropdownMenuItem(
                          value: product,
                          child: Text(product.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedProduct = value;
                },
                validator: (value) {
                  if (value == null) return 'Selecione um produto';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosagem',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a dosagem';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dosageUnitController,
                decoration: const InputDecoration(
                  labelText: 'Unidade de Dosagem',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a unidade';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: applicationMethodController,
                decoration: const InputDecoration(
                  labelText: 'Método de Aplicação',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o método';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: observationsController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedProduct != null &&
                  dosageController.text.isNotEmpty &&
                  dosageUnitController.text.isNotEmpty &&
                  applicationMethodController.text.isNotEmpty) {
                final newProduct = PrescriptionProduct(
                  productId: selectedProduct!.id,
                  productName: selectedProduct!.name,
                  dosage: dosageController.text,
                  dosageUnit: dosageUnitController.text,
                  applicationMethod: applicationMethodController.text,
                  observations: observationsController.text.isEmpty
                      ? null
                      : observationsController.text,
                );
                
                setState(() {
                  _selectedProducts.add(newProduct);
                });
                
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha todos os campos obrigatórios'),
                    // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProducts.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFarm == null || _selectedPlot == null || _selectedCrop == null) {
      _showErrorSnackBar('Selecione fazenda, talhão e cultura');
      return;
    }
    
    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar('Adicione pelo menos um produto à prescrição');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final prescription = Prescription(
        id: _isEditing ? widget.prescription!.id : null,
        title: _titleController.text,
        farmId: _selectedFarm!.id,
        farmName: _selectedFarm!.name,
        plotId: _selectedPlot!.id,
        plotName: _selectedPlot!.name,
        cropId: _selectedCrop!.id,
        cropName: _selectedCrop!.name,
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        agronomistName: _agronomistNameController.text,
        agronomistRegistration: _agronomistRegistrationController.text,
        status: _status,
        products: _selectedProducts,
        targetPest: _targetPestController.text.isEmpty ? null : _targetPestController.text,
        targetDisease: _targetDiseaseController.text.isEmpty ? null : _targetDiseaseController.text,
        targetWeed: _targetWeedController.text.isEmpty ? null : _targetWeedController.text,
        observations: _observationsController.text.isEmpty ? null : _observationsController.text,
        applicationConditions: _applicationConditionsController.text.isEmpty ? null : _applicationConditionsController.text,
        safetyInstructions: _safetyInstructionsController.text.isEmpty ? null : _safetyInstructionsController.text,
        createdAt: _isEditing ? widget.prescription!.createdAt : null,
        deviceId: _isEditing ? widget.prescription!.deviceId : null,
      );
      
      if (_isEditing) {
        await _prescriptionRepository.updatePrescription(prescription);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescrição atualizada com sucesso'),
              // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
            ),
          );
        }
      } else {
        await _prescriptionRepository.insertPrescription(prescription);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescrição criada com sucesso'),
              // backgroundColor: Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar prescrição: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          // backgroundColor: Colors.red, // backgroundColor não é suportado em flutter_map 5.0.0
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _agronomistNameController.dispose();
    _agronomistRegistrationController.dispose();
    _observationsController.dispose();
    _applicationConditionsController.dispose();
    _safetyInstructionsController.dispose();
    _targetPestController.dispose();
    _targetDiseaseController.dispose();
    _targetWeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Editar Prescrição' : 'Nova Prescrição',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título da Prescrição',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe um título para a prescrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Seção de Localização
                    const Text(
                      'Localização',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Farm>(
                      decoration: const InputDecoration(
                        labelText: 'Fazenda',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedFarm,
                      items: _farms
                          .map((farm) => DropdownMenuItem(
                                value: farm,
                                child: Text(farm.name),
                              ))
                          .toList(),
                      onChanged: _onFarmChanged,
                      validator: (value) {
                        if (value == null) return 'Selecione uma fazenda';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Plot>(
                      decoration: const InputDecoration(
                        labelText: 'Talhão',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedPlot,
                      items: _plots
                          .map((plot) => DropdownMenuItem(
                                value: plot,
                                child: Text(plot.name),
                              ))
                          .toList(),
                      onChanged: _onPlotChanged,
                      validator: (value) {
                        if (value == null) return 'Selecione um talhão';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Crop>(
                      decoration: const InputDecoration(
                        labelText: 'Cultura',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCrop,
                      items: _crops
                          .map((crop) => DropdownMenuItem(
                                value: crop,
                                child: Text(crop.name),
                              ))
                          .toList(),
                      onChanged: _onCropChanged,
                      validator: (value) {
                        if (value == null) return 'Selecione uma cultura';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Seção de Datas e Status
                    const Text(
                      'Datas e Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            // onTap: () => _selectDate(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data de Emissão',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(DateFormatter.format(_issueDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            // onTap: () => _selectDate(context, // onTap não é suportado em Polygon no flutter_map 5.0.0 false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data de Validade',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(DateFormatter.format(_expiryDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      value: _status,
                      items: ['Pendente', 'Aprovada', 'Aplicada', 'Cancelada']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Seção de Responsável Técnico
                    const Text(
                      'Responsável Técnico',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _agronomistNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Agrônomo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o nome do agrônomo responsável';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _agronomistRegistrationController,
                      decoration: const InputDecoration(
                        labelText: 'Registro Profissional (CREA)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o registro profissional';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Seção de Alvos
                    const Text(
                      'Alvos (opcional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetPestController,
                      decoration: const InputDecoration(
                        labelText: 'Praga Alvo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetDiseaseController,
                      decoration: const InputDecoration(
                        labelText: 'Doença Alvo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetWeedController,
                      decoration: const InputDecoration(
                        labelText: 'Planta Daninha Alvo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Seção de Produtos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produtos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddProductDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Produto'),
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Nenhum produto adicionado',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _selectedProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product.productName),
                              subtitle: Text(
                                  'Dosagem: ${product.dosage} ${product.dosageUnit}\nMétodo: ${product.applicationMethod}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeProduct(index),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    
                    // Seção de Informações Adicionais
                    const Text(
                      'Informações Adicionais (opcional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observationsController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _applicationConditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Condições de Aplicação',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _safetyInstructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instruções de Segurança',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Botão de Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePrescription,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isEditing ? 'Atualizar Prescrição' : 'Salvar Prescrição'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
