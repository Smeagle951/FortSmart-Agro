import 'package:flutter/material.dart';
import 'package:fortsmart_agro/models/farm.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Tela de edição do perfil da fazenda
class FarmEditScreen extends StatefulWidget {
  final Farm farm;
  final Function(Farm) onSave;

  const FarmEditScreen({
    Key? key,
    required this.farm,
    required this.onSave,
  }) : super(key: key);

  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _responsiblePersonController;
  late TextEditingController _documentNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _totalAreaController;
  late TextEditingController _plotsCountController;
  late TextEditingController _cultivationSystemController;
  late TextEditingController _irrigationTypeController;
  late TextEditingController _mechanizationLevelController;
  late TextEditingController _technicalResponsibleNameController;
  late TextEditingController _technicalResponsibleIdController;
  
  List<String> _crops = [];
  bool _hasIrrigation = false;
  File? _logoFile;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  /// Inicializa os controladores com os valores da fazenda
  void _initializeControllers() {
    final farm = widget.farm;
    _nameController = TextEditingController(text: farm.name);
    _responsiblePersonController = TextEditingController(text: farm.responsiblePerson);
    _documentNumberController = TextEditingController(text: farm.documentNumber);
    _phoneController = TextEditingController(text: farm.phone);
    _emailController = TextEditingController(text: farm.email);
    _addressController = TextEditingController(text: farm.address);
    _totalAreaController = TextEditingController(text: farm.totalArea.toString());
    _plotsCountController = TextEditingController(text: farm.plotsCount.toString());
    _cultivationSystemController = TextEditingController(text: farm.cultivationSystem);
    _irrigationTypeController = TextEditingController(text: farm.irrigationType);
    _mechanizationLevelController = TextEditingController(text: farm.mechanizationLevel);
    _technicalResponsibleNameController = TextEditingController(text: farm.technicalResponsibleName);
    _technicalResponsibleIdController = TextEditingController(text: farm.technicalResponsibleId);
    
    _crops = List.from(farm.crops);
    _hasIrrigation = farm.hasIrrigation;
    _logoUrl = farm.logoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _responsiblePersonController.dispose();
    _documentNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _totalAreaController.dispose();
    _plotsCountController.dispose();
    _cultivationSystemController.dispose();
    _irrigationTypeController.dispose();
    _mechanizationLevelController.dispose();
    _technicalResponsibleNameController.dispose();
    _technicalResponsibleIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F5F5), // backgroundColor não é suportado em flutter_map 5.0.0
      appBar: AppBar(
        // backgroundColor: const Color(0xFF2A4F3D), // backgroundColor não é suportado em flutter_map 5.0.0
        elevation: 0,
        title: const Text(
          'Editar Perfil da Fazenda',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveFarm,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Salvar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLogoSection(),
              const SizedBox(height: 24),
              _buildSection(
                title: '1. Informações Básicas',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nome da Fazenda',
                    icon: Icons.business,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  _buildTextField(
                    controller: _responsiblePersonController,
                    label: 'Responsável',
                    icon: Icons.person,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  _buildTextField(
                    controller: _documentNumberController,
                    label: 'CNPJ/CPF',
                    icon: Icons.badge,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    label: 'E-mail',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value!.isEmpty || !value.contains('@') 
                        ? 'E-mail inválido' 
                        : null,
                  ),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Endereço',
                    icon: Icons.location_on,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: '2. Dados Operacionais',
                icon: Icons.agriculture,
                children: [
                  _buildTextField(
                    controller: _totalAreaController,
                    label: 'Tamanho Total (ha)',
                    icon: Icons.straighten,
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty || double.tryParse(value) == null 
                        ? 'Valor inválido' 
                        : null,
                  ),
                  _buildTextField(
                    controller: _plotsCountController,
                    label: 'Talhões Cadastrados',
                    icon: Icons.dashboard,
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty || int.tryParse(value) == null 
                        ? 'Valor inválido' 
                        : null,
                  ),
                  _buildCropsSelector(),
                  _buildTextField(
                    controller: _cultivationSystemController,
                    label: 'Sistema de Cultivo',
                    icon: Icons.agriculture,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  _buildIrrigationSelector(),
                  if (_hasIrrigation)
                    _buildTextField(
                      controller: _irrigationTypeController,
                      label: 'Tipo de Irrigação',
                      icon: Icons.water_drop,
                      validator: (value) => _hasIrrigation && value!.isEmpty 
                          ? 'Campo obrigatório' 
                          : null,
                    ),
                  _buildTextField(
                    controller: _mechanizationLevelController,
                    label: 'Grau de Mecanização',
                    icon: Icons.settings,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: '3. Técnico Responsável',
                icon: Icons.person,
                children: [
                  _buildTextField(
                    controller: _technicalResponsibleNameController,
                    label: 'Nome',
                    icon: Icons.person,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  _buildTextField(
                    controller: _technicalResponsibleIdController,
                    label: 'CREA',
                    icon: Icons.badge,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: '4. Documentos e Mídias',
                icon: Icons.folder_outlined,
                children: [
                  _buildDocumentsList(),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói a seção de logo
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            // onTap: _pickImage, // onTap não é suportado em Polygon no flutter_map 5.0.0
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildLogoWidget(),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Alterar Logo'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2A4F3D),
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o widget do logo
  Widget _buildLogoWidget() {
    if (_logoFile != null) {
      return ClipOval(
        child: Image.file(
          _logoFile!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_logoUrl != null) {
      return ClipOval(
        child: Image.network(
          _logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.agriculture,
            size: 50,
            color: Color(0xFF2A4F3D),
          ),
        ),
      );
    } else {
      return const Icon(
        Icons.agriculture,
        size: 50,
        color: Color(0xFF2A4F3D),
      );
    }
  }

  /// Seleciona uma imagem da galeria ou câmera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _logoFile = File(pickedFile.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _logoFile = File(pickedFile.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói uma seção com título e conteúdo
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2A4F3D)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A4F3D),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um campo de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2A4F3D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2A4F3D), width: 2),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  /// Constrói o seletor de culturas
  Widget _buildCropsSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco, color: Color(0xFF2A4F3D)),
              const SizedBox(width: 12),
              const Text(
                'Culturas',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showCropDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2A4F3D),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _crops.map((crop) => _buildCropChip(crop)).toList(),
          ),
          if (_crops.isEmpty)
            const Text(
              'Nenhuma cultura cadastrada',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói um chip de cultura
  Widget _buildCropChip(String crop) {
    return Chip(
      backgroundColor: const Color(0xFFE8F5E9),
      label: Text(
        crop,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Color(0xFF2A4F3D),
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          _crops.remove(crop);
        });
      },
    );
  }

  /// Mostra o diálogo para adicionar cultura
  void _showCropDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Cultura'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da Cultura',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _crops.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A4F3D),
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  /// Constrói o seletor de irrigação
  Widget _buildIrrigationSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Color(0xFF2A4F3D)),
          const SizedBox(width: 12),
          const Text(
            'Irrigação',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Switch(
            value: _hasIrrigation,
            onChanged: (value) {
              setState(() {
                _hasIrrigation = value;
              });
            },
            activeColor: const Color(0xFF2A4F3D),
          ),
        ],
      ),
    );
  }

  /// Constrói a lista de documentos
  Widget _buildDocumentsList() {
    final documents = widget.farm.documents;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Color(0xFF2A4F3D)),
            const SizedBox(width: 12),
            const Text(
              'Documentos Oficiais',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showDocumentDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2A4F3D),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...documents.map((doc) => _buildDocumentItem(doc)).toList(),
        if (documents.isEmpty)
          const Text(
            'Nenhum documento cadastrado',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  /// Constrói um item de documento
  Widget _buildDocumentItem(FarmDocument document) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file, color: Color(0xFF2A4F3D)),
      title: Text(
        document.name,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        document.type,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () {
          // Implementar exclusão do documento
        },
      ),
    );
  }

  /// Mostra o diálogo para adicionar documento
  void _showDocumentDialog() {
    // Implementar adição de documento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de adição de documento em desenvolvimento'),
        backgroundColor: Color(0xFF2A4F3D),
      ),
    );
  }

  /// Salva as alterações da fazenda
  void _saveFarm() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Validação do formulário falhou');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija os erros no formulário'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('🔄 Iniciando salvamento da fazenda...');
      print('📊 Dados do formulário:');
      print('  - Nome: ${_nameController.text}');
      print('  - Responsável: ${_responsiblePersonController.text}');
      print('  - Documento: ${_documentNumberController.text}');
      print('  - Telefone: ${_phoneController.text}');
      print('  - Email: ${_emailController.text}');
      print('  - Endereço: ${_addressController.text}');
      print('  - Área Total: ${_totalAreaController.text}');
      print('  - Número de Talhões: ${_plotsCountController.text}');
      print('  - Sistema de Cultivo: ${_cultivationSystemController.text}');
      print('  - Tipo de Irrigação: ${_irrigationTypeController.text}');
      print('  - Nível de Mecanização: ${_mechanizationLevelController.text}');
      print('  - Responsável Técnico: ${_technicalResponsibleNameController.text}');
      print('  - ID Técnico: ${_technicalResponsibleIdController.text}');
      print('  - Culturas: $_crops');
      print('  - Tem Irrigação: $_hasIrrigation');

      // Validar dados obrigatórios
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Nome da fazenda é obrigatório');
      }

      if (_addressController.text.trim().isEmpty) {
        throw Exception('Endereço da fazenda é obrigatório');
      }

      final totalArea = double.tryParse(_totalAreaController.text);
      if (totalArea == null || totalArea <= 0) {
        throw Exception('Área total deve ser um número válido maior que zero');
      }

      final plotsCount = int.tryParse(_plotsCountController.text);
      if (plotsCount == null || plotsCount < 0) {
        throw Exception('Número de talhões deve ser um número válido maior ou igual a zero');
      }

      final updatedFarm = widget.farm.copyWith(
        name: _nameController.text.trim(),
        logoUrl: _logoUrl,
        responsiblePerson: _responsiblePersonController.text.trim().isEmpty ? null : _responsiblePersonController.text.trim(),
        documentNumber: _documentNumberController.text.trim().isEmpty ? null : _documentNumberController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim(),
        totalArea: totalArea,
        plotsCount: plotsCount,
        crops: _crops.isNotEmpty ? _crops : ['Soja'],
        cultivationSystem: _cultivationSystemController.text.trim().isEmpty ? null : _cultivationSystemController.text.trim(),
        hasIrrigation: _hasIrrigation,
        irrigationType: _irrigationTypeController.text.trim().isEmpty ? null : _irrigationTypeController.text.trim(),
        mechanizationLevel: _mechanizationLevelController.text.trim().isEmpty ? null : _mechanizationLevelController.text.trim(),
        technicalResponsibleName: _technicalResponsibleNameController.text.trim().isEmpty ? null : _technicalResponsibleNameController.text.trim(),
        technicalResponsibleId: _technicalResponsibleIdController.text.trim().isEmpty ? null : _technicalResponsibleIdController.text.trim(),
        isVerified: true,
        updatedAt: DateTime.now(),
      );

      print('✅ Fazenda criada com sucesso: ${updatedFarm.id}');
      
      // Chamar o callback de salvamento
      widget.onSave(updatedFarm);
      
      print('✅ Callback executado com sucesso');
      
      // Fechar a tela
      Navigator.pop(context);
      
      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Fazenda "${updatedFarm.name}" salva com sucesso!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      print('❌ Erro ao salvar fazenda: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      String errorMessage = 'Erro ao salvar dados da fazenda';
      
      // Mensagens de erro mais específicas
      if (e.toString().contains('Nome da fazenda é obrigatório')) {
        errorMessage = 'Nome da fazenda é obrigatório';
      } else if (e.toString().contains('Endereço da fazenda é obrigatório')) {
        errorMessage = 'Endereço da fazenda é obrigatório';
      } else if (e.toString().contains('Área total deve ser')) {
        errorMessage = 'Área total deve ser um número válido maior que zero';
      } else if (e.toString().contains('Número de talhões deve ser')) {
        errorMessage = 'Número de talhões deve ser um número válido maior ou igual a zero';
      } else if (e.toString().contains('Falha ao atualizar fazenda')) {
        errorMessage = 'Erro ao salvar no banco de dados. Tente novamente.';
      } else {
        errorMessage = 'Erro inesperado: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

