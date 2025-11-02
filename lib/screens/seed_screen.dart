import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/seed_calculation.dart';
import '../repositories/seed_calculation_repository.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/crop_selector.dart';
import '../widgets/plot_selector.dart';
import '../widgets/variety_selector.dart';
import '../widgets/optimized_image_upload.dart';
import '../utils/logger.dart';

class SeedCalculationScreen extends StatefulWidget {
  final int? calculationId;
  final bool viewOnly;

  const SeedCalculationScreen({
    Key? key,
    this.calculationId,
    this.viewOnly = false,
  }) : super(key: key);

  @override
  State<SeedCalculationScreen> createState() => _SeedCalculationScreenState();
}

class _SeedCalculationScreenState extends State<SeedCalculationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _repository = SeedCalculationRepository();
  
  bool _isLoading = false;
  bool _isInitializing = true;
  
  // Campos do formulário
  int? _selectedPlotId;
  int? _selectedCropId;
  int? _selectedVarietyId;
  final _populationController = TextEditingController();
  final _weightController = TextEditingController();
  final _germinationController = TextEditingController();
  final _purityController = TextEditingController();
  final _notesController = TextEditingController();
  String _calculationType = 'hectare'; // 'hectare' ou 'metro'
  
  // Resultados
  double _resultKgPerHectare = 0.0;
  double _resultSeedsPerMeter = 0.0;
  
  // Imagens
  List<String> _imageUrls = [];
  
  // Cálculo existente (para edição)
  SeedCalculation? _calculation;

  @override
  void initState() {
    super.initState();
    _germinationController.text = '95'; // Valor padrão para germinação
    _purityController.text = '99'; // Valor padrão para pureza
    
    if (widget.calculationId != null) {
      _loadCalculation(widget.calculationId!);
    } else {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _populationController.dispose();
    _weightController.dispose();
    _germinationController.dispose();
    _purityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCalculation(int id) async {
    try {
      final calculation = await _repository.getById(id);
      if (calculation != null) {
        setState(() {
          _calculation = calculation;
          _selectedPlotId = calculation.talhaoId;
          _selectedCropId = calculation.culturaId;
          _selectedVarietyId = calculation.variedadeId;
          _populationController.text = calculation.populacao.toString();
          _weightController.text = calculation.pesoMilSementes.toString();
          _germinationController.text = calculation.germinacao.toString();
          _purityController.text = calculation.pureza.toString();
          _notesController.text = calculation.observacoes ?? '';
          _calculationType = calculation.tipoCalculo;
          _resultKgPerHectare = calculation.resultadoKgHectare;
          _resultSeedsPerMeter = calculation.resultadoSementeMetro;
          
          // Extrair URLs das imagens
          if (calculation.fotos != null && calculation.fotos!.isNotEmpty) {
            _imageUrls = calculation.fotos!.split(',');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao carregar cálculo: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _calculateAndSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_selectedPlotId == null) {
      SnackbarHelper.showError(context, 'Selecione um talhão');
      return;
    }
    
    if (_selectedCropId == null) {
      SnackbarHelper.showError(context, 'Selecione uma cultura');
      return;
    }
    
    if (_selectedVarietyId == null) {
      SnackbarHelper.showError(context, 'Selecione uma variedade');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse inputs
      final population = double.parse(_populationController.text);
      final weight = double.parse(_weightController.text);
      final germination = double.parse(_germinationController.text);
      final purity = double.parse(_purityController.text);
      
      // Calculate results
      final results = SeedCalculation.calcular(
        populacao: population,
        pesoMilSementes: weight,
        germinacao: germination,
        pureza: purity,
      );
      
      setState(() {
        _resultKgPerHectare = results['kg_por_hectare']!;
        _resultSeedsPerMeter = results['sementes_por_metro']!;
      });
      
      // Processar imagens
      String processedImages = _imageUrls.join(',');
      
      // Create or update calculation
      final calculation = SeedCalculation(
        id: _calculation?.id,
        talhaoId: _selectedPlotId!,
        culturaId: _selectedCropId!,
        variedadeId: _selectedVarietyId!,
        populacao: population,
        pesoMilSementes: weight,
        germinacao: germination,
        pureza: purity,
        tipoCalculo: _calculationType,
        resultadoKgHectare: _resultKgPerHectare,
        resultadoSementeMetro: _resultSeedsPerMeter,
        observacoes: _notesController.text,
        fotos: processedImages.isNotEmpty ? processedImages : null,
        dataCalculo: DateTime.now().toIso8601String(),
      );
      
      if (_calculation == null) {
        await _repository.insert(calculation);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Cálculo de sementes salvo com sucesso');
        }
      } else {
        await _repository.update(calculation);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Cálculo de sementes atualizado com sucesso');
        }
      }
      
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Erro ao salvar cálculo: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateOnly() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    try {
      // Parse inputs
      final population = double.parse(_populationController.text);
      final weight = double.parse(_weightController.text);
      final germination = double.parse(_germinationController.text);
      final purity = double.parse(_purityController.text);
      
      // Calculate results
      final results = SeedCalculation.calcular(
        populacao: population,
        pesoMilSementes: weight,
        germinacao: germination,
        pureza: purity,
      );
      
      setState(() {
        _resultKgPerHectare = results['kg_por_hectare']!;
        _resultSeedsPerMeter = results['sementes_por_metro']!;
      });
      
      // Mostrar o resultado
      _showResultDialog();
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao calcular: $e');
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resultado do Cálculo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo de cálculo: ${_calculationType == 'hectare' ? 'Por Hectare' : 'Por Metro Linear'}'),
            const SizedBox(height: 8),
            Text(
              'Quantidade de sementes: ${_resultKgPerHectare.toStringAsFixed(2)} kg/ha',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Sementes por metro linear: ${_resultSeedsPerMeter.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _calculateAndSave();
            },
            style: ElevatedButton.styleFrom(
              // backgroundColor: const Color(0xFF00FF7F), // backgroundColor não é suportado em flutter_map 5.0.0
              foregroundColor: Colors.black,
            ),
            child: const Text('Salvar Cálculo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calculationId == null 
            ? 'Novo Cálculo de Sementes' 
            : widget.viewOnly 
                ? 'Visualizar Cálculo de Sementes'
                : 'Editar Cálculo de Sementes'),
        actions: [
          if (!widget.viewOnly && !_isInitializing)
            IconButton(
              icon: const Icon(Icons.calculate),
              onPressed: _calculateOnly,
              tooltip: 'Calcular sem salvar',
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
      bottomNavigationBar: _isInitializing
          ? null
          : _buildBottomBar(),
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
            // Seleção de talhão
            PlotSelector(
              initialValue: _selectedPlotId?.toString(),
              onChanged: (value) {
                setState(() {
                  _selectedPlotId = int.tryParse(value);
                });
              },
              isRequired: true,
              label: 'Talhão',
            ),
            const SizedBox(height: 16),
            
            // Seleção de cultura
            CropSelector(
              initialValue: _selectedCropId,
              onChanged: (value) {
                setState(() {
                  _selectedCropId = value as int?;
                  // Resetar a variedade quando a cultura muda
                  _selectedVarietyId = null;
                });
              },
              isRequired: true,
              label: 'Cultura',
            ),
            const SizedBox(height: 16),
            
            // Seleção de variedade
            VarietySelector(
              initialValue: _selectedVarietyId,
              onChanged: (value) {
                setState(() {
                  _selectedVarietyId = value;
                });
              },
              isRequired: true,
              label: 'Variedade',
              culturaId: _selectedCropId,
            ),
            const SizedBox(height: 16),
            
            // Tipo de cálculo (Hectare/Metro)
            const Text(
              'Tipo de Cálculo',
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Por Hectare'),
                        value: 'hectare',
                        groupValue: _calculationType,
                        onChanged: widget.viewOnly 
                            ? null 
                            : (value) {
                                setState(() {
                                  _calculationType = value!;
                                });
                              },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Por Metro'),
                        value: 'metro',
                        groupValue: _calculationType,
                        onChanged: widget.viewOnly 
                            ? null 
                            : (value) {
                                setState(() {
                                  _calculationType = value!;
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // População desejada
            TextFormField(
              controller: _populationController,
              decoration: const InputDecoration(
                labelText: 'População desejada (plantas/ha) *',
                border: OutlineInputBorder(),
                suffixText: 'plantas/ha',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (double.tryParse(value) == null) {
                  return 'Informe um número válido';
                }
                return null;
              },
              enabled: !widget.viewOnly,
            ),
            const SizedBox(height: 16),
            
            // Peso de mil sementes
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso de mil sementes (g) *',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (double.tryParse(value) == null) {
                  return 'Informe um número válido';
                }
                return null;
              },
              enabled: !widget.viewOnly,
            ),
            const SizedBox(height: 16),
            
            // Linha de germinação e pureza
            Row(
              children: [
                // Germinação
                Expanded(
                  child: TextFormField(
                    controller: _germinationController,
                    decoration: const InputDecoration(
                      labelText: 'Germinação (%) *',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final germination = double.tryParse(value);
                      if (germination == null) {
                        return 'Número inválido';
                      }
                      if (germination <= 0 || germination > 100) {
                        return 'Entre 1 e 100%';
                      }
                      return null;
                    },
                    enabled: !widget.viewOnly,
                  ),
                ),
                const SizedBox(width: 16),
                // Pureza
                Expanded(
                  child: TextFormField(
                    controller: _purityController,
                    decoration: const InputDecoration(
                      labelText: 'Pureza (%) *',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final purity = double.tryParse(value);
                      if (purity == null) {
                        return 'Número inválido';
                      }
                      if (purity <= 0 || purity > 100) {
                        return 'Entre 1 e 100%';
                      }
                      return null;
                    },
                    enabled: !widget.viewOnly,
                  ),
                ),
              ],
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
            
            // Upload de imagens
            OptimizedImageUpload(
              initialImages: _imageUrls,
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
              enabled: !widget.viewOnly,
              title: 'Fotos do Cálculo',
              imageQuality: 85,
              maxWidth: 1200,
              maxHeight: 1200,
            ),
            const SizedBox(height: 24),
            
            // Resultados (se já calculados)
            if (_resultKgPerHectare > 0 || _calculation != null)
              _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultado do Cálculo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            // Tipo de cálculo
            Row(
              children: [
                const Icon(Icons.calculate, color: Color(0xFF00FF7F)),
                const SizedBox(width: 8),
                Text(
                  'Tipo de cálculo: ${_calculationType == 'hectare' ? 'Por Hectare' : 'Por Metro Linear'}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Kg por hectare
            Row(
              children: [
                const Icon(Icons.grass, color: Color(0xFF00FF7F)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantidade de sementes:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${_resultKgPerHectare.toStringAsFixed(2)} kg/ha',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sementes por metro
            Row(
              children: [
                const Icon(Icons.straighten, color: Color(0xFF00FF7F)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sementes por metro linear:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      _resultSeedsPerMeter.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_calculation != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Calculado em: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_calculation!.dataCalculo))}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (widget.viewOnly) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              // backgroundColor: const Color(0xFF00FF7F), // backgroundColor não é suportado em flutter_map 5.0.0
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('VOLTAR'),
          ),
        ),
      );
    }
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _calculateOnly,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: const Color(0xFFFF851B), // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('CALCULAR'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _calculateAndSave,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: const Color(0xFF00FF7F), // backgroundColor não é suportado em flutter_map 5.0.0
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('SALVAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
