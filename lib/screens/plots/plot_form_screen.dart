import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/plot.dart';
import '../../repositories/plot_repository.dart';
import '../../models/farm.dart';
import '../../repositories/farm_repository.dart';

class PlotFormScreen extends StatefulWidget {
  final String? plotId;
  final String? farmId;
  final bool viewOnly;

  const PlotFormScreen({
    Key? key,
    this.plotId,
    this.farmId,
    this.viewOnly = false,
  }) : super(key: key);

  @override
  State<PlotFormScreen> createState() => _PlotFormScreenState();
}

class _PlotFormScreenState extends State<PlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plotRepository = PlotRepository();
  final _farmRepository = FarmRepository();
  
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // Form fields
  int? _farmId;
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Loaded data
  Plot? _plot;
  List<Farm> _farms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Carregar fazendas
      _farms = await _farmRepository.getAllFarms();
      
      // Se foi fornecido um ID de fazenda, usar como padrão
      if (widget.farmId != null) {
        _farmId = int.parse(widget.farmId!);
      }
      
      // Se foi fornecido um ID de talhão, carregar os dados
      if (widget.plotId != null) {
        _plot = await _plotRepository.getPlotById(widget.plotId!);
        if (_plot != null) {
          _farmId = _plot!.farmId;
          _nameController.text = _plot!.name;
          _areaController.text = _plot!.area?.toString() ?? '';
          _notesController.text = _plot!.notes ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _savePlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_farmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma fazenda')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final area = _areaController.text.isNotEmpty 
          ? double.tryParse(_areaController.text) 
          : null;
          
      final plot = Plot(
        id: _plot?.id ?? const Uuid().v4(),
        farmId: _farmId!,
        propertyId: _farms.firstWhere((farm) => farm.id == _farmId).propertyId,
        name: _nameController.text,
        area: area,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: _plot?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      if (_plot == null) {
        await _plotRepository.insertPlot(plot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Talhão cadastrado com sucesso')),
          );
        }
      } else {
        await _plotRepository.updatePlot(plot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Talhão atualizado com sucesso')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar talhão: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewOnly 
            ? 'Detalhes do Talhão' 
            : (widget.plotId == null ? 'Novo Talhão' : 'Editar Talhão')),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fazenda
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fazenda *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _farmId != null ? _farmId.toString() : null,
                              isExpanded: true,
                              hint: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Selecione uma fazenda'),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              onChanged: widget.viewOnly 
                                  ? null 
                                  : (String? newValue) {
                                      setState(() {
                                        _farmId = int.tryParse(newValue ?? '');
                                      });
                                    },
                              items: _farms.map<DropdownMenuItem<String>>((Farm farm) {
                                return DropdownMenuItem<String>(
                                  value: farm.id.toString(),
                                  child: Text(farm.name),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Talhão *',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o nome do talhão';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Área
                    TextFormField(
                      controller: _areaController,
                      decoration: const InputDecoration(
                        labelText: 'Área (ha)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Por favor, informe um valor numérico válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Observações
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: !widget.viewOnly,
                    ),
                    const SizedBox(height: 24),
                    
                    if (!widget.viewOnly)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _savePlot,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: Theme.of(context).primaryColor, // backgroundColor não é suportado em flutter_map 5.0.0
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('SALVAR'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
