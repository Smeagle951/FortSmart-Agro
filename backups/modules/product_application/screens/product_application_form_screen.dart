import 'package:flutter/material.dart';
import '../models/product_application_model.dart';
import '../models/application_target_model.dart';
import '../services/product_application_service.dart';
import '../widgets/general_info_section.dart';
import '../widgets/application_area_section.dart';
import '../widgets/application_targets_section.dart';
import '../widgets/application_products_section.dart';
import '../widgets/equipment_calculations_section.dart';
import '../widgets/observations_section.dart';
import '../widgets/product_selection_dialog.dart';
import '../../../models/agricultural_product.dart';
import '../../../services/data_cache_service.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/error_widget.dart' as app_error;
import '../../../utils/app_colors.dart';

class ProductApplicationFormScreen extends StatefulWidget {
  final ProductApplicationModel? application;
  
  const ProductApplicationFormScreen({
    Key? key,
    this.application,
  }) : super(key: key);

  @override
  _ProductApplicationFormScreenState createState() => _ProductApplicationFormScreenState();
}

class _ProductApplicationFormScreenState extends State<ProductApplicationFormScreen> {
  final ProductApplicationService _applicationService = ProductApplicationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Controladores para os campos do formulário
  final _responsibleNameController = TextEditingController();
  final _equipmentTypeController = TextEditingController();
  final _syrupVolumePerHectareController = TextEditingController();
  final _equipmentCapacityController = TextEditingController();
  final _nozzleTypeController = TextEditingController();
  final _technicalJustificationController = TextEditingController();
  
  // Valores do formulário
  ApplicationType _applicationType = ApplicationType.terrestrial;
  DateTime _applicationDate = DateTime.now();
  String _cropId = '';
  String _cropName = '';
  String _plotId = '';
  String _plotName = '';
  double _area = 0.0;
  List<String> _targetIds = [];
  List<ApplicationProductModel> _products = [];
  double _totalSyrupVolume = 0.0;
  int _numberOfTanks = 0;
  bool _deductFromStock = false;
  ApplicationControlType _controlType = const ApplicationControlType();
  
  // Listas para seleção
  List<Map<String, dynamic>> _availablePlots = [];
  List<Map<String, dynamic>> _availableCrops = [];
  List<ApplicationTargetModel> _availableTargets = [];
  List<AgriculturalProduct> _availableProducts = [];
  
  @override
  void initState() {
    super.initState();
    _initializeForm();
  }
  
  @override
  void dispose() {
    _responsibleNameController.dispose();
    _equipmentTypeController.dispose();
    _syrupVolumePerHectareController.dispose();
    _equipmentCapacityController.dispose();
    _nozzleTypeController.dispose();
    _technicalJustificationController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeForm() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar dados iniciais
      await _loadInitialData();
      
      // Preencher formulário se for edição
      if (widget.application != null) {
        _populateForm(widget.application!);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }
  
  Future<void> _loadInitialData() async {
    try {
      // Inicializar serviço de aplicação
      await _applicationService.init();
      
      // Carregar talhões
      final dataCacheService = DataCacheService();
      final talhoes = await dataCacheService.getTalhoes();
      _availablePlots = talhoes.map((talhao) => {
        'id': talhao.id,
        'name': talhao.nome,
        'area': talhao.area,
        'cropId': talhao.culturaId,
        'cropName': talhao.cultura,
      }).toList();
      
      // Carregar culturas
      final culturas = await dataCacheService.getCulturas();
      _availableCrops = culturas.map((cultura) => {
        'id': cultura.id,
        'name': cultura.name,
        'type': cultura.description.toString(),
      }).toList();
      
      // Carregar alvos
      _availableTargets = await _applicationService.getAllTargets();
      
      // Carregar produtos
      final products = await dataCacheService.getAgriculturalProducts();
      _availableProducts = products;
      
    } catch (e) {
      print('Erro ao carregar dados iniciais: $e');
      throw Exception('Falha ao carregar dados iniciais: $e');
    }
  }
  
  void _populateForm(ProductApplicationModel application) {
    setState(() {
      _applicationType = application.applicationType;
      _applicationDate = application.applicationDate;
      _responsibleNameController.text = application.responsibleName;
      _equipmentTypeController.text = application.equipmentType;
      _syrupVolumePerHectareController.text = application.syrupVolumePerHectare.toString();
      _cropId = application.cropId;
      _cropName = application.cropName;
      _plotId = application.plotId;
      _plotName = application.plotName;
      _area = application.area;
      _targetIds = List.from(application.targetIds);
      _products = List.from(application.products);
      _totalSyrupVolume = application.totalSyrupVolume;
      _equipmentCapacityController.text = application.equipmentCapacity.toString();
      _numberOfTanks = application.numberOfTanks;
      _nozzleTypeController.text = application.nozzleType;
      _technicalJustificationController.text = application.technicalJustification ?? '';
      _deductFromStock = application.deductFromStock;
      _controlType = application.controlType;
    });
  }
  
  Future<void> _saveApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Criar modelo de aplicação
      final application = ProductApplicationModel(
        id: widget.application?.id ?? '',
        applicationType: _applicationType,
        applicationDate: _applicationDate,
        responsibleName: _responsibleNameController.text,
        equipmentType: _equipmentTypeController.text,
        syrupVolumePerHectare: double.parse(_syrupVolumePerHectareController.text),
        cropId: _cropId,
        cropName: _cropName,
        plotId: _plotId,
        plotName: _plotName,
        area: _area,
        targetIds: _targetIds,
        controlType: _controlType,
        products: _products,
        totalSyrupVolume: _totalSyrupVolume,
        equipmentCapacity: double.parse(_equipmentCapacityController.text),
        numberOfTanks: _numberOfTanks,
        nozzleType: _nozzleTypeController.text,
        technicalJustification: _technicalJustificationController.text.isEmpty 
            ? null 
            : _technicalJustificationController.text,
        deductFromStock: _deductFromStock,
      );
      
      // Salvar aplicação
      await _applicationService.saveApplication(application, deductFromStock: _deductFromStock);
      
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplicação salva com sucesso')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar aplicação: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.application == null ? 'Nova Aplicação' : 'Editar Aplicação'),
        actions: [
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveApplication,
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Carregando dados...')
          : _hasError
              ? app_error.AppErrorWidget(
                  message: 'Erro ao carregar dados: $_errorMessage',
                  onRetry: _initializeForm,
                )
              : _buildForm(),
    );
  }
  
  // Métodos para atualizar valores do formulário
  void _updateApplicationType(ApplicationType type) {
    setState(() {
      _applicationType = type;
    });
  }
  
  void _updateApplicationDate(DateTime date) {
    setState(() {
      _applicationDate = date;
    });
  }
  
  void _updateCrop(String id, String name) {
    setState(() {
      _cropId = id;
      _cropName = name;
      // Resetar talhão se mudar a cultura
      if (_plotId.isNotEmpty) {
        _plotId = '';
        _plotName = '';
        _area = 0.0;
        _recalculateValues();
      }
    });
  }
  
  void _updatePlot(String id, String name, double area) {
    setState(() {
      _plotId = id;
      _plotName = name;
      _area = area;
      _recalculateValues();
    });
  }
  
  void _updateTargets(List<String> targetIds) {
    setState(() {
      _targetIds = targetIds;
    });
  }
  
  void _updateControlType(ApplicationControlType controlType) {
    setState(() {
      _controlType = controlType;
    });
  }
  
  void _updateProducts(List<ApplicationProductModel> products) {
    setState(() {
      _products = products;
    });
  }
  
  void _updateSyrupVolumePerHectare(double volume) {
    setState(() {
      _recalculateValues();
    });
  }
  
  void _updateEquipmentCapacity(double capacity) {
    setState(() {
      _recalculateValues();
    });
  }
  
  void _updateNozzleType(String type) {
    // Nada a recalcular
  }
  
  void _updateDeductFromStock(bool value) {
    setState(() {
      _deductFromStock = value;
    });
  }
  
  void _recalculateValues() {
    if (_area <= 0 || _syrupVolumePerHectareController.text.isEmpty) {
      _totalSyrupVolume = 0.0;
      _numberOfTanks = 0;
      return;
    }
    
    final syrupVolumePerHectare = double.tryParse(_syrupVolumePerHectareController.text) ?? 0.0;
    _totalSyrupVolume = _applicationService.calculateTotalSyrupVolume(_area, syrupVolumePerHectare);
    
    if (_equipmentCapacityController.text.isEmpty) {
      _numberOfTanks = 0;
      return;
    }
    
    final equipmentCapacity = double.tryParse(_equipmentCapacityController.text) ?? 0.0;
    _numberOfTanks = _applicationService.calculateNumberOfTanks(_totalSyrupVolume, equipmentCapacity);
    
    // Recalcular doses totais dos produtos
    if (_products.isNotEmpty) {
      final updatedProducts = _products.map((product) {
        return product.copyWith(
          totalDose: _applicationService.calculateTotalDose(product.dosePerHectare, _area),
        );
      }).toList();
      
      _products = updatedProducts;
    }
  }
  
  void _showAddProductDialog() {
    // Obter IDs dos produtos já selecionados
    final selectedProductIds = _products.map((p) => p.productId).toList();
    
    showDialog(
      context: context,
      builder: (context) => ProductSelectionDialog(
        availableProducts: _availableProducts,
        area: _area,
        alreadySelectedProductIds: selectedProductIds,
        onProductSelected: (product) {
          setState(() {
            _products.add(product);
          });
        },
      ),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de informações gerais
            GeneralInfoSection(
              applicationType: _applicationType,
              applicationDate: _applicationDate,
              responsibleNameController: _responsibleNameController,
              equipmentTypeController: _equipmentTypeController,
              onApplicationTypeChanged: _updateApplicationType,
              onApplicationDateChanged: _updateApplicationDate,
            ),
            
            // Seção de área de aplicação
            ApplicationAreaSection(
              cropId: _cropId,
              cropName: _cropName,
              plotId: _plotId,
              plotName: _plotName,
              area: _area,
              availablePlots: _availablePlots,
              availableCrops: _availableCrops,
              onCropSelected: _updateCrop,
              onPlotSelected: _updatePlot,
            ),
            
            // Seção de controle e alvos
            ApplicationTargetsSection(
              selectedTargetIds: _targetIds,
              availableTargets: _availableTargets,
              controlType: _controlType,
              onTargetsChanged: _updateTargets,
              onControlTypeChanged: _updateControlType,
            ),
            
            // Seção de produtos
            ApplicationProductsSection(
              products: _products,
              area: _area,
              onProductsChanged: _updateProducts,
              onAddProduct: _showAddProductDialog,
            ),
            
            // Seção de equipamento e cálculos
            EquipmentCalculationsSection(
              syrupVolumePerHectareController: _syrupVolumePerHectareController,
              equipmentCapacityController: _equipmentCapacityController,
              nozzleTypeController: _nozzleTypeController,
              area: _area,
              totalSyrupVolume: _totalSyrupVolume,
              numberOfTanks: _numberOfTanks,
              onSyrupVolumePerHectareChanged: _updateSyrupVolumePerHectare,
              onEquipmentCapacityChanged: _updateEquipmentCapacity,
              onNozzleTypeChanged: _updateNozzleType,
            ),
            
            // Seção de observações e ajustes técnicos
            ObservationsSection(
              technicalJustificationController: _technicalJustificationController,
              deductFromStock: _deductFromStock,
              onDeductFromStockChanged: _updateDeductFromStock,
            ),
            
            const SizedBox(height: 32),
            
            // Botão de salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SALVAR APLICAÇÃO',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
