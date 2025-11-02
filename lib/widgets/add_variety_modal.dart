import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_widgets.dart';
import '../widgets/adaptive_layouts.dart';
import '../services/variety_cycle_service.dart';

/// Modal para adicionar uma nova variedade de cultura
class AddVarietyModal extends StatefulWidget {
  final String cropId;
  final String cropName;
  final Function(String varietyId) onVarietyAdded;

  const AddVarietyModal({
    Key? key,
    required this.cropId,
    required this.cropName,
    required this.onVarietyAdded,
  }) : super(key: key);

  @override
  State<AddVarietyModal> createState() => _AddVarietyModalState();
}

class _AddVarietyModalState extends State<AddVarietyModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cycleDaysController = TextEditingController();
  
  String _selectedType = 'Convencional';
  bool _isLoading = false;
  
  final VarietyCycleService _varietyService = VarietyCycleService();

  final List<String> _varietyTypes = [
    'Convencional',
    'RR',
    'Intacta',
    'Bt',
    'HT',
    'Híbrida',
    'Transgênica',
    'Outro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _cycleDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
      ),
      child: Container(
        width: ResponsiveUtils.shouldUseCompactLayout(context) 
          ? MediaQuery.of(context).size.width * 0.95
          : MediaQuery.of(context).size.width * 0.6,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            // Conteúdo
            Flexible(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.getAdaptivePadding(context),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCropInfo(),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
                      _buildNameField(),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
                      _buildTypeSelector(),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
                      _buildCompanyField(),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
                      _buildCycleDaysField(),
                      SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context)),
                      _buildDescriptionField(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botões
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsiveUtils.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.vertical(
          top: ResponsiveUtils.getAdaptiveBorderRadius(context).topLeft,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle,
            color: Colors.green.shade700,
            size: ResponsiveUtils.getAdaptiveFontSize(context, small: 20.0, compact: 24.0),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Nova Variedade',
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 16.0, compact: 18.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                ResponsiveText(
                  widget.cropName,
                  fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
                  color: Colors.green.shade600,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildCropInfo() {
    return Container(
      padding: ResponsiveUtils.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.eco, color: Colors.blue.shade700),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context)),
          Expanded(
            child: ResponsiveText(
              'Adicionando variedade para: ${widget.cropName}',
              fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 12.0, compact: 14.0),
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Nome da Variedade *',
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Ex: Soja RR 60.51',
            border: OutlineInputBorder(
              borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome da variedade é obrigatório';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Tipo da Variedade *',
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
            ),
          ),
          items: _varietyTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCompanyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Empresa/Fabricante',
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
        TextFormField(
          controller: _companyController,
          decoration: InputDecoration(
            hintText: 'Ex: Monsanto, Syngenta, Pioneer',
            border: OutlineInputBorder(
              borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleDaysField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Ciclo em Dias *',
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
        TextFormField(
          controller: _cycleDaysController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Ex: 120',
            suffixText: 'dias',
            border: OutlineInputBorder(
              borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ciclo em dias é obrigatório';
            }
            final days = int.tryParse(value);
            if (days == null || days < 60 || days > 365) {
              return 'Ciclo deve ser entre 60 e 365 dias';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Descrição',
          fontSize: ResponsiveUtils.getAdaptiveFontSize(context, small: 14.0, compact: 16.0),
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: ResponsiveUtils.getAdaptiveSpacing(context, small: 4.0, compact: 8.0)),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Características especiais, resistências, etc.',
            border: OutlineInputBorder(
              borderRadius: ResponsiveUtils.getAdaptiveBorderRadius(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: ResponsiveUtils.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.vertical(
          bottom: ResponsiveUtils.getAdaptiveBorderRadius(context).bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancelar'),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getAdaptiveSpacing(context)),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveVariety,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isLoading) const Icon(Icons.save, size: 16),
                  const SizedBox(width: 8),
                  Text(_isLoading ? 'Salvando...' : 'Salvar Variedade'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveVariety() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar se a variedade já existe
      final exists = await _varietyService.varietyExists(
        widget.cropId,
        _nameController.text.trim(),
      );

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Variedade "${_nameController.text.trim()}" já existe para esta cultura'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Criar a variedade
      final varietyId = await _varietyService.createVariety(
        cropId: widget.cropId,
        name: _nameController.text.trim(),
        type: _selectedType,
        cycleDays: int.parse(_cycleDaysController.text.trim()),
        description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
        company: _companyController.text.trim().isNotEmpty 
          ? _companyController.text.trim() 
          : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Variedade "${_nameController.text.trim()}" criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onVarietyAdded(varietyId);
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar variedade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
