import 'package:flutter/material.dart';
import '../../../models/planting_cv_model.dart';
import '../../../services/planting_cv_calculation_service.dart';
import '../../../utils/fortsmart_theme.dart';

/// Tela para cálculo de CV% do plantio
class PlantingCvCalculationScreen extends StatefulWidget {
  final String fieldId;
  final String cropId;

  const PlantingCvCalculationScreen({
    Key? key,
    required this.fieldId,
    required this.cropId,
  }) : super(key: key);

  @override
  _PlantingCvCalculationScreenState createState() => _PlantingCvCalculationScreenState();
}

class _PlantingCvCalculationScreenState extends State<PlantingCvCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calculationService = PlantingCVCalculationService();
  
  final _comprimentoController = TextEditingController();
  final _espacamentoController = TextEditingController();
  
  // Lista de controladores para as distâncias (até 100)
  final List<TextEditingController> _distanciaControllers = [];
  
  PlantingCVModel? _result;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    // Inicializar com 5 caixas de distância
    _initializeDistanceControllers(5);
  }

  @override
  void dispose() {
    _comprimentoController.dispose();
    _espacamentoController.dispose();
    // Dispose de todos os controladores de distância
    for (var controller in _distanciaControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeDistanceControllers(int count) {
    // Limpar controladores existentes
    for (var controller in _distanciaControllers) {
      controller.dispose();
    }
    _distanciaControllers.clear();
    
    // Criar novos controladores
    for (int i = 0; i < count; i++) {
      _distanciaControllers.add(TextEditingController());
    }
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      final comprimento = double.parse(_comprimentoController.text);
      final espacamento = double.parse(_espacamentoController.text);
      
      // Coletar distâncias das caixas separadas
      final distancias = <double>[];
      for (var controller in _distanciaControllers) {
        if (controller.text.isNotEmpty) {
          final value = int.tryParse(controller.text);
          if (value != null && value > 0) {
            // Converter de centímetros para metros (dividir por 100)
            distancias.add(value / 100.0);
          }
        }
      }

      if (distancias.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite pelo menos uma distância válida')),
        );
        return;
      }

      final result = _calculationService.calcularCV(
        talhaoId: widget.fieldId,
        talhaoNome: 'Talhão ${widget.fieldId}', // Nome padrão
        culturaId: widget.cropId,
        culturaNome: 'Cultura ${widget.cropId}', // Nome padrão
        dataPlantio: DateTime.now(),
        comprimentoLinhaAmostrada: comprimento,
        espacamentoEntreLinhas: espacamento,
        distanciasEntreSementes: distancias,
      );

      setState(() {
        _result = result;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no cálculo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de CV% do Plantio'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campos de entrada
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dados do Plantio',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _comprimentoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Comprimento da linha amostrada (m)',
                          hintText: 'Ex: 3.0',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite o comprimento da linha';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Digite um valor válido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _espacamentoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Espaçamento entre linhas (m)',
                          hintText: 'Ex: 0.45',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite o espaçamento entre linhas';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Digite um valor válido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Widget personalizado para distâncias
                      _buildDistanceInputs(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botão de cálculo
              ElevatedButton(
                onPressed: _isCalculating ? null : _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FortSmartTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCalculating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Calculando...'),
                        ],
                      )
                    : const Text('Calcular CV%'),
              ),
              
              const SizedBox(height: 16),
              
              // Resultados
              if (_result != null) _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Distâncias entre sementes (cm)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _distanciaControllers.length > 1 
                      ? () => _removeDistanceBox() 
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remover caixa',
                ),
                IconButton(
                  onPressed: _distanciaControllers.length < 100 
                      ? () => _addDistanceBox() 
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Adicionar caixa',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Digite valores em centímetros (ex: 222 para 2.22m)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _distanciaControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return SizedBox(
              width: 80,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'cm',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final intValue = int.tryParse(value);
                    if (intValue == null || intValue <= 0) {
                      return 'Inválido';
                    }
                  }
                  return null;
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Caixas preenchidas: ${_distanciaControllers.where((c) => c.text.isNotEmpty).length}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _addDistanceBox() {
    setState(() {
      _distanciaControllers.add(TextEditingController());
    });
  }

  void _removeDistanceBox() {
    if (_distanciaControllers.isNotEmpty) {
      setState(() {
        _distanciaControllers.last.dispose();
        _distanciaControllers.removeLast();
      });
    }
  }

  Widget _buildResultsCard() {
    return Card(
      color: _getCvColor(_result!.classificacao).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCvIcon(_result!.classificacao),
                  color: _getCvColor(_result!.classificacao),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resultados do CV%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getCvColor(_result!.classificacao),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildResultRow('CV%', '${_result!.coeficienteVariacao.toStringAsFixed(1)}%'),
            _buildResultRow('Classificação', _result!.classificacaoTexto),
            _buildResultRow('Plantas por Metro', '${_result!.plantasPorMetro.toStringAsFixed(1)}'),
            _buildResultRow('População Estimada', '${_result!.populacaoEstimadaPorHectare.toStringAsFixed(0)} plantas/ha'),
            _buildResultRow('Média do Espaçamento', '${_result!.mediaEspacamento.toStringAsFixed(1)} cm'),
            _buildResultRow('Desvio Padrão', '${_result!.desvioPadrao.toStringAsFixed(1)} cm'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getCvColor(CVClassification classification) {
    switch (classification) {
      case CVClassification.excelente:
        return Colors.green;
      case CVClassification.bom:
        return Colors.orange;
      case CVClassification.moderado:
        return Colors.yellow;
      case CVClassification.ruim:
        return Colors.red;
    }
  }

  IconData _getCvIcon(CVClassification classification) {
    switch (classification) {
      case CVClassification.excelente:
        return Icons.check_circle;
      case CVClassification.bom:
        return Icons.warning;
      case CVClassification.moderado:
        return Icons.info;
      case CVClassification.ruim:
        return Icons.error;
    }
  }
}
