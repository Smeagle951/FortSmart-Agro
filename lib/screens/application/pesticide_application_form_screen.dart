import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/crop.dart';
import '../../models/pesticide_application.dart';
import '../../repositories/crop_repository.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../utils/wrappers/file_picker_wrapper.dart';
import '../../widgets/loading_indicator.dart';

class PesticideApplicationFormScreen extends StatefulWidget {
  final String? applicationId;
  final String? plotId;
  final String? productId;

  const PesticideApplicationFormScreen({Key? key, this.applicationId, this.plotId, this.productId}) : super(key: key);

  @override
  _PesticideApplicationFormScreenState createState() => _PesticideApplicationFormScreenState();
}

class _PesticideApplicationFormScreenState extends State<PesticideApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PesticideApplicationRepository _repository = PesticideApplicationRepository();
  final CropRepository _cropRepository = CropRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  List<Crop> _crops = [];
  Crop? _selectedCrop;

  // Controladores para os campos do formulário
  final _productNameController = TextEditingController();
  final _dosePerHaController = TextEditingController();
  final _caldaVolumeController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _observationsController = TextEditingController();
  
  // Valores calculados
  double _totalCaldaVolume = 0.0;
  double _totalProductAmount = 0.0;
  
  // Dados do registro existente
  PesticideApplication? _existingApplication;
  DateTime _selectedDate = DateTime.now();
  List<String> _imageUrls = [];
  String _doseUnit = 'L';
  String _applicationType = 'Terrestre';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _dosePerHaController.dispose();
    _caldaVolumeController.dispose();
    _totalAreaController.dispose();
    _responsibleController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Carregar culturas
      final crops = await _cropRepository.getAllCrops();
      
      // Carregar registro existente, se for edição
      PesticideApplication? existingApplication;
      if (widget.applicationId != null) {
        existingApplication = await _repository.getPesticideApplicationById(widget.applicationId!);
      }

      setState(() {
        // Converter os objetos Crop do banco de dados para o modelo Crop usado pelo widget
        _crops = crops.map((dbCrop) => Crop(
          id: dbCrop.id != null ? dbCrop.id : 0,
          name: dbCrop.name,
          description: dbCrop.description ?? '',
        )).toList();
        
        if (existingApplication != null) {
          _existingApplication = existingApplication;
          _selectedCrop = _crops.firstWhere(
            (crop) => crop.id == existingApplication?.cropId,
            orElse: () => _crops.isNotEmpty ? _crops.first : Crop(id: 0, name: 'Sem cultura', description: ''),
          );
          _productNameController.text = existingApplication.productName ?? '';
          _dosePerHaController.text = existingApplication.dosePerHa.toString();
          _doseUnit = existingApplication.doseUnit ?? 'L/ha';
          _caldaVolumeController.text = existingApplication.caldaVolumePerHa.toString();
          _totalAreaController.text = existingApplication.totalArea.toString();
          _responsibleController.text = existingApplication.responsible;
          _applicationType = existingApplication.applicationType == ApplicationType.ground ? 'Terrestre' : 'Aérea';
          _temperatureController.text = existingApplication.temperature?.toString() ?? '';
          _humidityController.text = existingApplication.humidity?.toString() ?? '';
          _observationsController.text = existingApplication.observations ?? '';
          _selectedDate = existingApplication.date;
          _imageUrls = existingApplication.imageUrls ?? [];
          _totalCaldaVolume = existingApplication.totalCaldaVolume;
          _totalProductAmount = existingApplication.totalProductAmount;
        } else if (_crops.isNotEmpty) {
          _selectedCrop = _crops.first;
        }
        
        _isLoading = false;
      });
      
      // Calcular valores iniciais
      _calculateTotals();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  void _calculateTotals() {
    if (_caldaVolumeController.text.isEmpty || _totalAreaController.text.isEmpty || _dosePerHaController.text.isEmpty) {
      return;
    }

    try {
      final caldaVolumePerHa = double.parse(_caldaVolumeController.text);
      final totalArea = double.parse(_totalAreaController.text);
      final dosePerHa = double.parse(_dosePerHaController.text);
      
      final totalCaldaVolume = caldaVolumePerHa * totalArea;
      final totalProductAmount = dosePerHa * totalArea;
      
      setState(() {
        _totalCaldaVolume = totalCaldaVolume;
        _totalProductAmount = totalProductAmount;
      });
    } catch (e) {
      print('Erro no cálculo: $e');
    }
  }

  Future<void> _savePesticideApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final application = PesticideApplication(
        id: _existingApplication?.id ?? '',
        plotId: widget.plotId ?? '',
        cropId: _selectedCrop!.id.toString(),
        productId: widget.productId ?? '',
        dose: double.parse(_dosePerHaController.text),
        doseUnit: _doseUnit,
        mixtureVolume: double.parse(_caldaVolumeController.text),
        totalArea: double.parse(_totalAreaController.text),
        date: _selectedDate,
        responsiblePerson: _responsibleController.text,
        applicationType: _applicationType == 'Terrestre' ? ApplicationType.ground : ApplicationType.aerial,
        temperature: _temperatureController.text.isNotEmpty ? double.parse(_temperatureController.text) : null,
        humidity: _humidityController.text.isNotEmpty ? double.parse(_humidityController.text) : null,
        observations: _observationsController.text,
        productName: _productNameController.text,
        cropName: _selectedCrop!.name,
      );

      if (_existingApplication != null) {
        await _repository.updatePesticideApplication(application);
      } else {
        await _repository.insertPesticideApplication(application);
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro salvo com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar registro: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await FilePickerWrapper.pickImage();
      if (image != null) {
        setState(() {
          _imageUrls.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }
  
  Widget _buildImageWidget(String path) {
    // Verifica se o caminho é uma URL ou um caminho de arquivo local
    bool isNetworkImage = path.startsWith('http://') || path.startsWith('https://');
    
    if (isNetworkImage) {
      // Se for uma URL, usa Image.network
      return Image.network(
        path,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Se for um caminho local, usa Image.file
      try {
        return Image.file(
          File(path),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
              ),
            );
          },
        );
      } catch (e) {
        // Em caso de erro ao carregar a imagem local
        return Container(
          width: 100,
          height: 100,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.red,
            ),
          ),
        );
      }
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.applicationId != null ? 'Editar Aplicação' : 'Nova Aplicação'),
        // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com título
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF90CAF9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💧 Aplicação de Defensivos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Registre os detalhes da aplicação de defensivos agrícolas.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informações básicas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações Básicas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Seleção de cultura
                          DropdownButtonFormField<Crop>(
                            decoration: const InputDecoration(
                              labelText: 'Cultura *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.grass),
                            ),
                            value: _selectedCrop,
                            items: _crops.map((crop) {
                              return DropdownMenuItem<Crop>(
                                value: crop,
                                child: Text(crop.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCrop = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Selecione uma cultura';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Data da aplicação
                          InkWell(
                            // onTap: () => _selectDate(context), // onTap não é suportado em Polygon no flutter_map 5.0.0
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data da Aplicação *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Nome do produto
                          TextFormField(
                            controller: _productNameController,
                            decoration: const InputDecoration(
                              labelText: 'Produto Aplicado *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_drink_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o nome do produto';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Dose por hectare
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: TextFormField(
                                  controller: _dosePerHaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dose por Hectare *',
                                    border: OutlineInputBorder(),
                                    helperText: 'Quantidade do produto por hectare',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe a dose';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _calculateTotals(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Unidade',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                                  ),
                                  value: _doseUnit,
                                  isExpanded: true,
                                  isDense: true,
                                  items: const [
                                    DropdownMenuItem(value: 'L', child: Text('L/ha')),
                                    DropdownMenuItem(value: 'mL', child: Text('mL/ha')),
                                    DropdownMenuItem(value: 'kg', child: Text('kg/ha')),
                                    DropdownMenuItem(value: 'g', child: Text('g/ha')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _doseUnit = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Responsável
                          TextFormField(
                            controller: _responsibleController,
                            decoration: const InputDecoration(
                              labelText: 'Responsável *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o responsável';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Tipo de aplicação
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Aplicação *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.agriculture),
                            ),
                            value: _applicationType,
                            items: const [
                              DropdownMenuItem(value: 'Terrestre', child: Text('Terrestre')),
                              DropdownMenuItem(value: 'Aérea', child: Text('Aérea')),
                              DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _applicationType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Detalhes da aplicação
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalhes da Aplicação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Volume de calda por hectare
                          TextFormField(
                            controller: _caldaVolumeController,
                            decoration: const InputDecoration(
                              labelText: 'Volume de Calda (L/ha) *',
                              border: OutlineInputBorder(),
                              helperText: 'Volume de calda por hectare',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o volume de calda';
                              }
                              return null;
                            },
                            onChanged: (_) => _calculateTotals(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Área total
                          TextFormField(
                            controller: _totalAreaController,
                            decoration: const InputDecoration(
                              labelText: 'Área Total (ha) *',
                              border: OutlineInputBorder(),
                              helperText: 'Área total a ser aplicada',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a área total';
                              }
                              return null;
                            },
                            onChanged: (_) => _calculateTotals(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Temperatura e umidade
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _temperatureController,
                                  decoration: const InputDecoration(
                                    labelText: 'Temperatura (°C)',
                                    border: OutlineInputBorder(),
                                    helperText: 'Opcional',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _humidityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Umidade (%)',
                                    border: OutlineInputBorder(),
                                    helperText: 'Opcional',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Resultado do cálculo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF90CAF9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cálculos da Aplicação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Volume total de calda:',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_totalCaldaVolume.toStringAsFixed(2)} L',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantidade total de produto:',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_totalProductAmount.toStringAsFixed(2)} $_doseUnit',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Observações
                    TextFormField(
                      controller: _observationsController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        helperText: 'Condições climáticas, ajustes, EPIs utilizados, etc.',
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    // Seção de imagens
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Imagens',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.add_a_photo),
                                label: const Text('Adicionar Imagem'),
                                style: ElevatedButton.styleFrom(
                                  // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_imageUrls.isNotEmpty)
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: _buildImageWidget(_imageUrls[index]),
                                          
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              iconSize: 20,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 30,
                                                minHeight: 30,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _imageUrls.removeAt(index);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Informações de segurança
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                       child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '⚠️ Informações de Segurança',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Lembre-se de utilizar os Equipamentos de Proteção Individual (EPIs) adequados durante a aplicação de defensivos agrícolas. Siga sempre as recomendações do fabricante e a legislação vigente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF795548),
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Botão de salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePesticideApplication,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: const Color(0xFF2196F3), // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'SALVAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
