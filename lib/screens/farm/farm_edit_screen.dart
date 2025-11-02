import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/farm.dart';
import '../../services/farm_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/notifications_wrapper.dart';

class FarmEditScreen extends StatefulWidget {
  final String farmId;

  const FarmEditScreen({
    Key? key,
    required this.farmId,
  }) : super(key: key);

  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  final FarmService _farmService = FarmService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isNew = false;
  
  // Controladores para os campos do formulário
  final _nameController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _cropsController = TextEditingController();
  final _cultivationSystemController = TextEditingController();
  final _irrigationTypeController = TextEditingController();
  final _mechanizationLevelController = TextEditingController();
  final _technicalResponsibleNameController = TextEditingController();
  final _technicalResponsibleIdController = TextEditingController();
  
  bool _hasIrrigation = false;
  int _plotsCount = 0;
  String? _logoUrl;
  List<FarmDocument> _documents = [];
  DateTime _createdAt = DateTime.now();
  DateTime _updatedAt = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadFarm();
  }
  
  @override
  void dispose() {
    // Liberar os controladores
    _nameController.dispose();
    _responsiblePersonController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _totalAreaController.dispose();
    _cropsController.dispose();
    _cultivationSystemController.dispose();
    _irrigationTypeController.dispose();
    _mechanizationLevelController.dispose();
    _technicalResponsibleNameController.dispose();
    _technicalResponsibleIdController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFarm() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (widget.farmId.isEmpty) {
        // Nova fazenda
        _isNew = true;
        _setDefaultValues();
      } else {
        // Editar fazenda existente
        final farm = await _farmService.getFarmById(widget.farmId);
        
        if (farm != null) {
          _populateForm(farm);
        } else {
          // Fazenda não encontrada
          NotificationsWrapper().showNotification(
            context,
            title: 'Erro',
            message: 'Fazenda não encontrada',
            isError: true,
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      NotificationsWrapper().showNotification(
        context,
        title: 'Erro',
        message: 'Erro ao carregar dados: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _setDefaultValues() {
    _nameController.text = '';
    _responsiblePersonController.text = '';
    _documentNumberController.text = '';
    _phoneController.text = '';
    _emailController.text = '';
    _addressController.text = '';
    _totalAreaController.text = '0';
    _cropsController.text = '';
    _cultivationSystemController.text = 'Convencional';
    _hasIrrigation = false;
    _irrigationTypeController.text = '';
    _mechanizationLevelController.text = 'Médio';
    _technicalResponsibleNameController.text = '';
    _technicalResponsibleIdController.text = '';
    _plotsCount = 0;
    _logoUrl = null;
    _documents = [];
    _createdAt = DateTime.now();
    _updatedAt = DateTime.now();
  }
  
  void _populateForm(Farm farm) {
    _nameController.text = farm.name;
    _responsiblePersonController.text = farm.responsiblePerson ?? '';
    _documentNumberController.text = farm.documentNumber ?? '';
    _phoneController.text = farm.phone ?? '';
    _emailController.text = farm.email ?? '';
    _addressController.text = farm.address;
    _totalAreaController.text = farm.totalArea.toString();
    _cropsController.text = farm.crops.join(', ');
    _cultivationSystemController.text = farm.cultivationSystem ?? '';
    _hasIrrigation = farm.hasIrrigation;
    _irrigationTypeController.text = farm.irrigationType ?? '';
    _mechanizationLevelController.text = farm.mechanizationLevel ?? '';
    _technicalResponsibleNameController.text = farm.technicalResponsibleName ?? '';
    _technicalResponsibleIdController.text = farm.technicalResponsibleId ?? '';
    _plotsCount = farm.plotsCount;
    _logoUrl = farm.logoUrl;
    _documents = farm.documents;
    _createdAt = farm.createdAt;
    _updatedAt = farm.updatedAt;
  }
  
  Future<void> _saveFarm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final crops = _cropsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      final farm = Farm(
        id: _isNew ? null : widget.farmId,
        name: _nameController.text,
        logoUrl: _logoUrl,
        responsiblePerson: _responsiblePersonController.text,
        documentNumber: _documentNumberController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        totalArea: double.tryParse(_totalAreaController.text) ?? 0,
        plotsCount: _plotsCount,
        crops: crops,
        cultivationSystem: _cultivationSystemController.text,
        hasIrrigation: _hasIrrigation,
        irrigationType: _irrigationTypeController.text,
        mechanizationLevel: _mechanizationLevelController.text,
        technicalResponsibleName: _technicalResponsibleNameController.text,
        technicalResponsibleId: _technicalResponsibleIdController.text,
        documents: _documents,
        isVerified: _farmService.isFarmVerified(Farm(
          name: _nameController.text,
          responsiblePerson: _responsiblePersonController.text,
          documentNumber: _documentNumberController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          address: _addressController.text,
          totalArea: double.tryParse(_totalAreaController.text) ?? 0,
          plotsCount: _plotsCount,
          crops: crops,
          cultivationSystem: _cultivationSystemController.text,
          hasIrrigation: _hasIrrigation,
          irrigationType: _irrigationTypeController.text,
          mechanizationLevel: _mechanizationLevelController.text,
          technicalResponsibleName: _technicalResponsibleNameController.text,
          technicalResponsibleId: _technicalResponsibleIdController.text,
        )),
        createdAt: _createdAt,
        updatedAt: DateTime.now(),
      );
      
      String farmId;
      
      if (_isNew) {
        farmId = await _farmService.addFarm(farm);
        NotificationsWrapper().showNotification(
          context,
          title: 'Sucesso',
          message: 'Fazenda criada com sucesso!',
        );
      } else {
        await _farmService.updateFarm(farm);
        farmId = widget.farmId;
        NotificationsWrapper().showNotification(
          context,
          title: 'Sucesso',
          message: 'Fazenda atualizada com sucesso!',
        );
      }
      
      // Voltar para a tela anterior
      Navigator.of(context).pop(farmId);
    } catch (e) {
      NotificationsWrapper().showNotification(
        context,
        title: 'Erro',
        message: 'Erro ao salvar fazenda: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _updateLogo() async {
    try {
      // Mostrar diálogo para escolher entre câmera e galeria
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Selecionar imagem'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  GestureDetector(
                    child: const ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Galeria'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final imagePicker = ImagePicker();
                        final XFile? image = await imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        
                        if (image != null && context.mounted) {
                          // Usar o serviço para atualizar a imagem diretamente
                          final success = await _farmService.updateFarmLogo(widget.farmId, image.path);
                          
                          if (success && context.mounted) {
                            // Atualizar o estado com o novo caminho da imagem
                            final updatedFarm = await _farmService.getFarmById(widget.farmId);
                            if (updatedFarm != null) {
                              setState(() {
                                _logoUrl = updatedFarm.logoUrl;
                              });
                              
                              NotificationsWrapper().showNotification(
                                context,
                                title: 'Sucesso',
                                message: 'Logo atualizado com sucesso!',
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao selecionar imagem: $e')),
                          );
                        }
                      }
                    },
                  ),
                  GestureDetector(
                    child: const ListTile(
                      leading: Icon(Icons.photo_camera),
                      title: Text('Câmera'),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final imagePicker = ImagePicker();
                        final XFile? photo = await imagePicker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        
                        if (photo != null && context.mounted) {
                          // Usar o serviço para atualizar a imagem diretamente
                          final success = await _farmService.updateFarmLogo(widget.farmId, photo.path);
                          
                          if (success && context.mounted) {
                            // Atualizar o estado com o novo caminho da imagem
                            final updatedFarm = await _farmService.getFarmById(widget.farmId);
                            if (updatedFarm != null) {
                              setState(() {
                                _logoUrl = updatedFarm.logoUrl;
                              });
                              
                              NotificationsWrapper().showNotification(
                                context,
                                title: 'Sucesso',
                                message: 'Logo atualizado com sucesso!',
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao capturar foto: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nova Fazenda' : 'Editar Fazenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFarm,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
          
          // Loading indicator
          if (_isLoading) const LoadingIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo da fazenda
            _buildLogoSection(),
            
            const SizedBox(height: 24),
            
            // Seção 1: Informações Básicas
            _buildSectionHeader('Informações Básicas', Icons.info_outline),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Fazenda *',
                hintText: 'Ex: Fazenda São João',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o nome da fazenda';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _responsiblePersonController,
              decoration: const InputDecoration(
                labelText: 'Responsável *',
                hintText: 'Ex: João da Silva',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o responsável';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(
                labelText: 'CNPJ/CPF *',
                hintText: 'Ex: 12.345.678/0001-99',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o CNPJ/CPF';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone *',
                hintText: 'Ex: (34) 91234-5678',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o telefone';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail *',
                hintText: 'Ex: contato@fazendajoao.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o e-mail';
                }
                if (!value.contains('@')) {
                  return 'Por favor, informe um e-mail válido';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Endereço *',
                hintText: 'Ex: Estrada Rural KM 12, Zona Sul',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o endereço';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Seção 2: Dados Operacionais
            _buildSectionHeader('Dados Operacionais', Icons.agriculture),
            
            TextFormField(
              controller: _totalAreaController,
              decoration: const InputDecoration(
                labelText: 'Tamanho Total (ha) *',
                hintText: 'Ex: 540',
                suffixText: 'ha',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o tamanho total';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _cropsController,
              decoration: const InputDecoration(
                labelText: 'Culturas *',
                hintText: 'Ex: Soja, Milho, Algodão',
                helperText: 'Separe as culturas por vírgula',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe as culturas';
                }
                return null;
              },
            ),
            
            DropdownButtonFormField<String>(
              value: _cultivationSystemController.text.isNotEmpty ? _cultivationSystemController.text : 'Convencional',
              decoration: const InputDecoration(
                labelText: 'Sistema de Cultivo *',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Convencional',
                  child: Text('Convencional'),
                ),
                DropdownMenuItem(
                  value: 'Plantio Direto',
                  child: Text('Plantio Direto'),
                ),
                DropdownMenuItem(
                  value: 'Orgânico',
                  child: Text('Orgânico'),
                ),
                DropdownMenuItem(
                  value: 'Integração Lavoura-Pecuária',
                  child: Text('Integração Lavoura-Pecuária'),
                ),
                DropdownMenuItem(
                  value: 'Outro',
                  child: Text('Outro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _cultivationSystemController.text = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione o sistema de cultivo';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Possui Irrigação?'),
              value: _hasIrrigation,
              onChanged: (value) {
                setState(() {
                  _hasIrrigation = value;
                });
              },
            ),
            
            if (_hasIrrigation)
              DropdownButtonFormField<String>(
                value: _irrigationTypeController.text.isNotEmpty
                    ? _irrigationTypeController.text
                    : 'Pivô Central',
                decoration: const InputDecoration(
                  labelText: 'Tipo de Irrigação *',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Pivô Central',
                    child: Text('Pivô Central'),
                  ),
                  DropdownMenuItem(
                    value: 'Gotejamento',
                    child: Text('Gotejamento'),
                  ),
                  DropdownMenuItem(
                    value: 'Aspersão',
                    child: Text('Aspersão'),
                  ),
                  DropdownMenuItem(
                    value: 'Outro',
                    child: Text('Outro'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _irrigationTypeController.text = value!;
                  });
                },
                validator: (value) {
                  if (_hasIrrigation && (value == null || value.isEmpty)) {
                    return 'Por favor, selecione o tipo de irrigação';
                  }
                  return null;
                },
              ),
            
            DropdownButtonFormField<String>(
              value: _mechanizationLevelController.text.isNotEmpty ? _mechanizationLevelController.text : 'Médio',
              decoration: const InputDecoration(
                labelText: 'Grau de Mecanização *',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Baixo',
                  child: Text('Baixo'),
                ),
                DropdownMenuItem(
                  value: 'Médio',
                  child: Text('Médio'),
                ),
                DropdownMenuItem(
                  value: 'Alto',
                  child: Text('Alto'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _mechanizationLevelController.text = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione o grau de mecanização';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Seção 3: Técnico Responsável
            _buildSectionHeader('Técnico Responsável', Icons.engineering),
            
            TextFormField(
              controller: _technicalResponsibleNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Técnico *',
                hintText: 'Ex: Carlos Medeiros',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o nome do técnico responsável';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _technicalResponsibleIdController,
              decoration: const InputDecoration(
                labelText: 'CREA *',
                hintText: 'Ex: MG-123456/D',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o CREA do técnico responsável';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Botão de salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveFarm,
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _updateLogo, // Habilitado para permitir a seleção de imagem
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2A4F3D),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: _logoUrl != null && File(_logoUrl!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(_logoUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _logoUrl == null || !File(_logoUrl!).existsSync()
                  ? const Icon(
                      Icons.add_a_photo,
                      color: Color(0xFF2A4F3D),
                      size: 40,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Logo da Fazenda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Toque para alterar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF2A4F3D),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2A4F3D),
              ),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
}
