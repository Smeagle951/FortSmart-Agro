import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planter_calibration.dart';
import '../../repositories/planter_calibration_repository.dart';
import '../../widgets/crop_selector.dart';
import '../../widgets/machine_selector.dart';
import '../../widgets/plot_selector.dart';
import '../../models/machine.dart';

class PlanterCalibrationFormScreen extends StatefulWidget {
  final String? calibrationId;
  final bool viewOnly;

  const PlanterCalibrationFormScreen({
    Key? key,
    this.calibrationId,
    this.viewOnly = false,
  }) : super(key: key);

  @override
  State<PlanterCalibrationFormScreen> createState() => _PlanterCalibrationFormScreenState();
}

class _PlanterCalibrationFormScreenState extends State<PlanterCalibrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PlanterCalibrationRepository();
  
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // Form fields
  String? _cropId;
  String? _plotId;
  String? _planterId;
  final _seedRateController = TextEditingController();
  final _distanceController = TextEditingController();
  final _seedsCountController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Loaded data
  PlanterCalibration? _calibration;

  @override
  void initState() {
    super.initState();
    if (widget.calibrationId != null) {
      _loadCalibration();
    } else {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _seedRateController.dispose();
    _distanceController.dispose();
    _seedsCountController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCalibration() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final calibration = await _repository.getById(widget.calibrationId!);
      setState(() {
        _calibration = calibration;
        if (calibration != null) {
          _cropId = calibration?.cropId;
          _plotId = calibration?.plotId;
          _planterId = calibration?.machineId;
          _seedRateController.text = calibration?.targetPopulation?.toString() ?? '';
          _distanceController.text = calibration?.rowSpacing?.toString() ?? '';
          _seedsCountController.text = calibration?.seedDiscHoles?.toString() ?? '';
          _notesController.text = calibration?.observations ?? '';
          _nameController.text = calibration?.name ?? '';
        }
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar calibragem: $e')),
        );
      }
    }
  }

  Future<void> _saveCalibration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final calibration = PlanterCalibration(
        id: widget.calibrationId,
        name: _nameController.text,
        cropId: _cropId!,
        plotId: _plotId!,
        machineId: _planterId!,
        targetPopulation: double.parse(_seedRateController.text),
        rowSpacing: double.parse(_distanceController.text),
        planterRows: 1, // Valor padrão para número de linhas da plantadeira
        workSpeed: 5.0, // Valor padrão para velocidade de trabalho em km/h
        tipo: 'semente', // Tipo padrão
        seedDiscHoles: int.parse(_seedsCountController.text),
        observations: _notesController.text,
        isAdvanced: false,
        responsiblePerson: 'Usuário',
      );

      if (_calibration == null) {
        await _repository.insert(calibration);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibragem registrada com sucesso')),
          );
        }
      } else {
        await _repository.update(calibration);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calibragem atualizada com sucesso')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar calibragem: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.viewOnly 
            ? 'Detalhes da Calibragem' 
            : (widget.calibrationId == null ? 'Nova Calibragem' : 'Editar Calibragem')),
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
                    // Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Calibragem',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !widget.viewOnly,
                    ),
                    const SizedBox(height: 16),
                    
                    // Cultura
                    CropSelector(
                      initialValue: _cropId,
                      onChanged: (value) {
                        setState(() {
                          _cropId = value as String?;
                        });
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Talhão
                    PlotSelector(
                      initialValue: _plotId,
                      onChanged: (value) {
                        setState(() {
                          _plotId = value;
                        });
                      },
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Plantadeira
                    MachineSelector(
                      initialValue: _planterId,
                      onChanged: (value) {
                        setState(() {
                          _planterId = value;
                        });
                      },
                      required: true,
                      label: 'Plantadeira *',
                      filterByType: MachineType.planter,
                    ),
                    const SizedBox(height: 16),
                    
                    // População alvo
                    TextFormField(
                      controller: _seedRateController,
                      decoration: const InputDecoration(
                        labelText: 'População Alvo (sementes/ha) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe a população alvo';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, informe um valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Espaçamento entre linhas
                    TextFormField(
                      controller: _distanceController,
                      decoration: const InputDecoration(
                        labelText: 'Espaçamento entre Linhas (metros) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o espaçamento entre linhas';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Por favor, informe um valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Número de furos do disco
                    TextFormField(
                      controller: _seedsCountController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Furos do Disco *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !widget.viewOnly,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o número de furos do disco';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor, informe um valor inteiro válido';
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
                        onPressed: _isLoading ? null : _saveCalibration,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'SALVAR',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
