import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pesticide_application.dart';
import '../../models/plot.dart';
import '../../repositories/pesticide_application_repository.dart';
import '../../repositories/plot_repository.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';

class PesticideApplicationFormScreen extends StatefulWidget {
  final String? applicationId;

  const PesticideApplicationFormScreen({Key? key, this.applicationId}) : super(key: key);

  @override
  State<PesticideApplicationFormScreen> createState() => _PesticideApplicationFormScreenState();
}

class _PesticideApplicationFormScreenState extends State<PesticideApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _responsiblePersonController = TextEditingController();
  final _notesController = TextEditingController();
  
  final PesticideApplicationRepository _applicationRepository = PesticideApplicationRepository();
  final PlotRepository _plotRepository = PlotRepository();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedPlotId;
  String? _selectedStatus = 'Planejada';
  List<Plot> _plots = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Carregar talhões
      final plots = await _plotRepository.getAll();
      setState(() {
        _plots = plots;
        if (plots.isNotEmpty && _selectedPlotId == null) {
          _selectedPlotId = plots.first.id;
        }
      });
      
      // Se for edição, carregar dados da aplicação
      if (widget.applicationId != null) {
        final application = await _applicationRepository.getById(widget.applicationId!);
        if (application != null) {
          _purposeController.text = application.purpose ?? '';
          _responsiblePersonController.text = application.responsiblePerson ?? '';
          _notesController.text = application.notes ?? '';
          _selectedDate = application.date;
          _selectedPlotId = application.plotId;
          _selectedStatus = application.status;
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
  
  Future<void> _saveApplication() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final selectedPlot = _plots.firstWhere((plot) => plot.id == _selectedPlotId);
      
      final application = PesticideApplication(
        id: widget.applicationId,
        plotId: _selectedPlotId!,
        plotName: selectedPlot.name,
        date: _selectedDate,
        purpose: _purposeController.text,
        responsiblePerson: _responsiblePersonController.text,
        notes: _notesController.text,
        status: _selectedStatus,
        products: [],
      );
      
      if (widget.applicationId == null) {
        await _applicationRepository.addApplication(application);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aplicação registrada com sucesso')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _applicationRepository.updateApplication(application);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aplicação atualizada com sucesso')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar aplicação: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.applicationId == null ? 'Nova Aplicação' : 'Editar Aplicação',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações Básicas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Seleção de talhão
                    CustomDropdown<String>(
                      label: 'Talhão',
                      value: _selectedPlotId,
                      items: _plots.map((plot) => DropdownMenuItem(
                        value: plot.id,
                        child: Text(plot.name),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPlotId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione um talhão';
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
                          labelText: 'Data da Aplicação',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormatter.format(_selectedDate)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Finalidade
                    CustomTextField(
                      controller: _purposeController,
                      label: 'Finalidade',
                      hint: 'Ex: Controle de pragas, doenças...',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a finalidade da aplicação';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Responsável
                    CustomTextField(
                      controller: _responsiblePersonController,
                      label: 'Responsável',
                      hint: 'Nome do responsável pela aplicação',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o responsável pela aplicação';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Status
                    CustomDropdown<String>(
                      label: 'Status',
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'Planejada', child: Text('Planejada')),
                        DropdownMenuItem(value: 'Em andamento', child: Text('Em andamento')),
                        DropdownMenuItem(value: 'Concluída', child: Text('Concluída')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Observações
                    CustomTextField(
                      controller: _notesController,
                      label: 'Observações',
                      hint: 'Observações adicionais',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    // Botão de salvar
                    CustomButton(
                      onPressed: _isSaving ? null : _saveApplication,
                      label: _isSaving 
                          ? 'Salvando...' 
                          : (widget.applicationId == null ? 'Registrar Aplicação' : 'Atualizar Aplicação'),
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _purposeController.dispose();
    _responsiblePersonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
