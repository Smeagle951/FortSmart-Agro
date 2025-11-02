import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/experiment.dart';
import '../../services/experiment_service.dart';
import '../../widgets/fortsmart_app_bar.dart';
import '../../widgets/fortsmart_button.dart';
import '../../widgets/fortsmart_card.dart';
import '../../widgets/fortsmart_loading.dart';
import '../../utils/fortsmart_theme.dart';
import '../../utils/snackbar_utils.dart';

/// Tela para editar experimento existente
/// Segue o padrão visual do FortSmart Agro
class EditarExperimentoScreen extends StatefulWidget {
  final Experiment experimento;

  const EditarExperimentoScreen({
    super.key,
    required this.experimento,
  });

  @override
  State<EditarExperimentoScreen> createState() => _EditarExperimentoScreenState();
}

class _EditarExperimentoScreenState extends State<EditarExperimentoScreen> {
  
  // Constantes
  static const Duration _snackBarDuration = Duration(seconds: 3);
  
  // Serviços
  final ExperimentService _experimentService = ExperimentService();
  
  // Estados
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _varietyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _plotNameController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _daeController = TextEditingController();
  
  // Valores
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _status = 'active';
  
  // Opções
  final List<String> _statusOptions = ['active', 'completed', 'canceled'];
  final List<String> _cropTypes = [
    'Soja',
    'Milho',
    'Algodão',
    'Café',
    'Cana-de-açúcar',
    'Trigo',
    'Arroz',
    'Feijão',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();
    _preencherCampos();
  }

  @override
  void dispose() {
    _varietyController.dispose();
    _descriptionController.dispose();
    _plotNameController.dispose();
    _cropTypeController.dispose();
    _daeController.dispose();
    super.dispose();
  }

  /// Preenche os campos com os dados do experimento
  void _preencherCampos() {
    _varietyController.text = widget.experimento.variety;
    _descriptionController.text = widget.experimento.description;
    _plotNameController.text = widget.experimento.plotName;
    _cropTypeController.text = widget.experimento.cropType;
    _daeController.text = widget.experimento.dae.toString();
    _startDate = widget.experimento.startDate;
    _endDate = widget.experimento.endDate;
    _status = widget.experimento.status;
  }

  /// Salva as alterações do experimento
  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _experimentService.initialize();
      
      final experimentoAtualizado = widget.experimento.copyWith(
        plotName: _plotNameController.text.trim(),
        cropType: _cropTypeController.text.trim(),
        variety: _varietyController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        dae: int.tryParse(_daeController.text) ?? 0,
        status: _status,
      );

      await _experimentService.updateExperiment(experimentoAtualizado);
      
      if (mounted) {
        Navigator.pop(context, true);
        SnackbarUtils.showSuccessSnackBar(context, 'Experimento atualizado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao atualizar experimento: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Seleciona data de início
  Future<void> _selecionarDataInicio() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  /// Seleciona data de fim
  Future<void> _selecionarDataFim() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  /// Remove data de fim
  void _removerDataFim() {
    setState(() {
      _endDate = null;
    });
  }

  /// Constrói cabeçalho
  Widget _buildHeader() {
    return FortsmartCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: FortsmartTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Editar Experimento',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Modifique as informações do experimento conforme necessário',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói formulário
  Widget _buildForm() {
    return FortsmartCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Variedade
              TextFormField(
                controller: _varietyController,
                decoration: const InputDecoration(
                  labelText: 'Variedade *',
                  hintText: 'Ex: BRS 284',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.eco),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Variedade é obrigatória';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Nome do talhão
              TextFormField(
                controller: _plotNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Talhão *',
                  hintText: 'Ex: Pivô 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome do talhão é obrigatório';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Cultura
              DropdownButtonFormField<String>(
                value: _cropTypeController.text.isNotEmpty ? _cropTypeController.text : null,
                decoration: const InputDecoration(
                  labelText: 'Cultura *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                items: _cropTypes.map((crop) => 
                  DropdownMenuItem(value: crop, child: Text(crop))
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _cropTypeController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cultura é obrigatória';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // DAE
              TextFormField(
                controller: _daeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'DAE (Dias Após Emergência)',
                  hintText: 'Ex: 45',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final dae = int.tryParse(value);
                    if (dae == null || dae < 0) {
                      return 'DAE deve ser um número positivo';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: _statusOptions.map((status) => 
                  DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusText(status)),
                  )
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Data de início
              InkWell(
                onTap: _selecionarDataInicio,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de Início *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Data de fim
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selecionarDataFim,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data de Fim (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          _endDate != null 
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : 'Selecionar data',
                        ),
                      ),
                    ),
                  ),
                  if (_endDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _removerDataFim,
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Remover data de fim',
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Descrição
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva o experimento...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói botões de ação
  Widget _buildActions() {
    return FortsmartCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: FortsmartButton(
                text: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                variant: FortsmartButtonVariant.outline,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FortsmartButton(
                text: _isSaving ? 'Salvando...' : 'Salvar Alterações',
                onPressed: _isSaving ? null : _salvarAlteracoes,
                icon: _isSaving ? null : Icons.save,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtém texto do status
  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'completed':
        return 'Concluído';
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FortsmartAppBar(
        title: 'Editar Experimento',
      ),
      body: _isLoading
          ? const FortsmartLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildForm(),
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              ),
            ),
    );
  }
}
