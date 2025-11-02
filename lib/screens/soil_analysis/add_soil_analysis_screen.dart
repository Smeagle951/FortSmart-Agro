import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/soil_analysis_repository.dart';
import '../../repositories/monitoring_repository.dart';

class AddSoilAnalysisScreen extends StatefulWidget {
  final int? monitoringId;
  final int? analysisId; // Se fornecido, estamos editando uma análise existente
  final String? plotId; // ID do talhão selecionado
  final String? plotName; // Nome do talhão selecionado

  const AddSoilAnalysisScreen({
    Key? key,
    this.monitoringId,
    this.analysisId,
    this.plotId,
    this.plotName,
  }) : super(key: key);

  @override
  _AddSoilAnalysisScreenState createState() => _AddSoilAnalysisScreenState();
}

class _AddSoilAnalysisScreenState extends State<AddSoilAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final SoilAnalysisRepository _repository = SoilAnalysisRepository();
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  bool _isLoading = false;
  bool _isEditing = false;
  String _pageTitle = 'Nova Análise de Solo';

  // Controladores para os campos do formulário
  final _phController = TextEditingController();
  final _organicMatterController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _calciumController = TextEditingController();
  final _magnesiumController = TextEditingController();
  final _sulfurController = TextEditingController();
  final _aluminumController = TextEditingController();
  final _cecController = TextEditingController();
  final _baseSaturationController = TextEditingController();

  // Monitoramento selecionado
  int? _selectedMonitoringId;
  List<dynamic> _monitorings = []; // Lista genérica para evitar conflitos de tipo

  @override
  void initState() {
    super.initState();
    _selectedMonitoringId = widget.monitoringId;
    _isEditing = widget.analysisId != null;

    if (_isEditing) {
      _pageTitle = 'Editar Análise de Solo';
      _loadAnalysisData();
    }

    if (_selectedMonitoringId == null) {
      _loadMonitorings();
    }
  }

  Future<void> _loadMonitorings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Comentado temporariamente até resolver dependências
      // _monitorings = await _monitoringRepository.getAllMonitorings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar monitoramentos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalysisData() async {
    if (widget.analysisId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final analysis = await _repository.getSoilAnalysisById(widget.analysisId!);

      if (analysis != null) {
        _selectedMonitoringId = analysis.monitoringId;
        
        _phController.text = analysis.ph?.toString() ?? '';
        _organicMatterController.text = analysis.organicMatter?.toString() ?? '';
        _phosphorusController.text = analysis.phosphorus?.toString() ?? '';
        _potassiumController.text = analysis.potassium?.toString() ?? '';
        _calciumController.text = analysis.calcium?.toString() ?? '';
        _magnesiumController.text = analysis.magnesium?.toString() ?? '';
        _sulfurController.text = analysis.sulfur?.toString() ?? '';
        _aluminumController.text = analysis.aluminum?.toString() ?? '';
        _cecController.text = analysis.cationExchangeCapacity?.toString() ?? '';
        _baseSaturationController.text = analysis.baseSaturation?.toString() ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Análise não encontrada')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados da análise: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phController.dispose();
    _organicMatterController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _calciumController.dispose();
    _magnesiumController.dispose();
    _sulfurController.dispose();
    _aluminumController.dispose();
    _cecController.dispose();
    _baseSaturationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
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
                    // Exibir informações do talhão selecionado, se disponível
                    if (widget.plotId != null && widget.plotName != null) ...[                      
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Talhão Selecionado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.crop_square, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.plotName!,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_selectedMonitoringId == null) ...[
                      _buildMonitoringDropdown(),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionTitle('Parâmetros Principais'),
                    _buildNumberField(
                      controller: _phController,
                      label: 'pH',
                      hint: 'Ex: 6.5',
                      icon: Icons.science,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final ph = double.tryParse(value);
                          if (ph == null) {
                            return 'Valor inválido';
                          } else if (ph < 0 || ph > 14) {
                            return 'pH deve estar entre 0 e 14';
                          }
                        }
                        return null;
                      },
                    ),
                    _buildNumberField(
                      controller: _organicMatterController,
                      label: 'Matéria Orgânica (%)',
                      hint: 'Ex: 3.2',
                      icon: Icons.compost,
                    ),
                    _buildNumberField(
                      controller: _phosphorusController,
                      label: 'Fósforo (mg/dm³)',
                      hint: 'Ex: 12.5',
                      icon: Icons.science,
                    ),
                    _buildNumberField(
                      controller: _potassiumController,
                      label: 'Potássio (mmolc/dm³)',
                      hint: 'Ex: 2.8',
                      icon: Icons.science,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Parâmetros Secundários'),
                    _buildNumberField(
                      controller: _calciumController,
                      label: 'Cálcio (mmolc/dm³)',
                      hint: 'Ex: 40.0',
                      icon: Icons.science,
                    ),
                    _buildNumberField(
                      controller: _magnesiumController,
                      label: 'Magnésio (mmolc/dm³)',
                      hint: 'Ex: 12.0',
                      icon: Icons.science,
                    ),
                    _buildNumberField(
                      controller: _sulfurController,
                      label: 'Enxofre (mg/dm³)',
                      hint: 'Ex: 10.0',
                      icon: Icons.science,
                    ),
                    _buildNumberField(
                      controller: _aluminumController,
                      label: 'Alumínio (mmolc/dm³)',
                      hint: 'Ex: 0.5',
                      icon: Icons.science,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Parâmetros Calculados'),
                    _buildNumberField(
                      controller: _cecController,
                      label: 'CTC (mmolc/dm³)',
                      hint: 'Ex: 80.0',
                      icon: Icons.calculate,
                    ),
                    _buildNumberField(
                      controller: _baseSaturationController,
                      label: 'Saturação por Bases (%)',
                      hint: 'Ex: 70.0',
                      icon: Icons.calculate,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final saturation = double.tryParse(value);
                          if (saturation == null) {
                            return 'Valor inválido';
                          } else if (saturation < 0 || saturation > 100) {
                            return 'Saturação deve estar entre 0 e 100%';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveAnalysis,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditing ? 'Atualizar Análise' : 'Salvar Análise',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
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
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        validator: validator,
      ),
    );
  }

  Widget _buildMonitoringDropdown() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Monitoramento',
        border: OutlineInputBorder(),
      ),
      value: _selectedMonitoringId,
      items: _monitorings.map((monitoring) {
        return DropdownMenuItem<int>(
          value: monitoring.id,
          child: Text('${monitoring.id} - ${monitoring.date}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMonitoringId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Selecione um monitoramento';
        }
        return null;
      },
    );
  }

  Future<void> _saveAnalysis() async {
    if (_selectedMonitoringId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um monitoramento')),
      );
      return;
    }
    
    // Verificar se temos um talhão selecionado
    if (widget.plotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum talhão selecionado')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Converter valores dos campos para double
        final ph = _phController.text.isNotEmpty
            ? double.parse(_phController.text)
            : null;
        final organicMatter = _organicMatterController.text.isNotEmpty
            ? double.parse(_organicMatterController.text)
            : null;
        final phosphorus = _phosphorusController.text.isNotEmpty
            ? double.parse(_phosphorusController.text)
            : null;
        final potassium = _potassiumController.text.isNotEmpty
            ? double.parse(_potassiumController.text)
            : null;
        final calcium = _calciumController.text.isNotEmpty
            ? double.parse(_calciumController.text)
            : null;
        final magnesium = _magnesiumController.text.isNotEmpty
            ? double.parse(_magnesiumController.text)
            : null;
        final sulfur = _sulfurController.text.isNotEmpty
            ? double.parse(_sulfurController.text)
            : null;
        final aluminum = _aluminumController.text.isNotEmpty
            ? double.parse(_aluminumController.text)
            : null;
        final cec = _cecController.text.isNotEmpty
            ? double.parse(_cecController.text)
            : null;
        final baseSaturation = _baseSaturationController.text.isNotEmpty
            ? double.parse(_baseSaturationController.text)
            : null;

        if (_isEditing) {
          // Atualizar análise existente
          await _repository.updateSoilAnalysis(
            id: widget.analysisId!,
            ph: ph,
            organicMatter: organicMatter,
            phosphorus: phosphorus,
            potassium: potassium,
            calcium: calcium,
            magnesium: magnesium,
            sulfur: sulfur,
            aluminum: aluminum,
            cationExchangeCapacity: cec,
            baseSaturation: baseSaturation,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Análise atualizada com sucesso')),
          );
        } else {
          // Adicionar nova análise
          await _repository.addSoilAnalysis(
            monitoringId: _selectedMonitoringId!,
            plotId: widget.plotId!, // Adicionar o ID do talhão selecionado
            ph: ph,
            organicMatter: organicMatter,
            phosphorus: phosphorus,
            potassium: potassium,
            calcium: calcium,
            magnesium: magnesium,
            sulfur: sulfur,
            aluminum: aluminum,
            cationExchangeCapacity: cec,
            baseSaturation: baseSaturation,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Análise adicionada com sucesso')),
          );
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar análise: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
