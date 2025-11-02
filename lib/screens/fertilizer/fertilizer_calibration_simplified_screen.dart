import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/fertilizer_calibration.dart';
import '../../models/calibration_result.dart';
import '../../repositories/fertilizer_calibration_repository.dart';
import '../../models/agricultural_product.dart';
import '../../repositories/agricultural_product_repository.dart';
import '../../widgets/fertilizer_distribution_chart.dart';
import '../../widgets/professional_result_card.dart';
import '../../widgets/advanced_statistics_widget.dart';
import '../../widgets/fortsmart_card.dart';
import '../../utils/area_formatter.dart';

/// Tela padrão de calibração de fertilizantes - FortSmart
class FertilizerCalibrationSimplifiedScreen extends StatefulWidget {
  const FertilizerCalibrationSimplifiedScreen({super.key});

  @override
  State<FertilizerCalibrationSimplifiedScreen> createState() => _FertilizerCalibrationSimplifiedScreenState();
}

class _FertilizerCalibrationSimplifiedScreenState extends State<FertilizerCalibrationSimplifiedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = FertilizerCalibrationRepository();
  final _productRepository = AgriculturalProductRepository();
  
  // Controladores simplificados
  final _fertilizerController = TextEditingController();
  final _distanceController = TextEditingController();
  final _applicationWidthController = TextEditingController();
  final _desiredRateController = TextEditingController();
  final _granulometriaController = TextEditingController();
  final _densidadeController = TextEditingController();
  
  
  // Campos adicionais para reutilização (não influenciam no cálculo)
  final _machineController = TextEditingController();
  final _operatorController = TextEditingController();
  final _smallPaddleController = TextEditingController();
  final _largePaddleController = TextEditingController();
  final _rpmController = TextEditingController();
  final _speedController = TextEditingController();
  
  // Lista de pesos coletados
  final List<TextEditingController> _weightControllers = [];
  
  // Estados
  bool _isLoading = false;
  bool _showResults = false;
  FertilizerCalibration? _currentCalibration;
  CalibrationResult? _calibrationResult;
  
  
  
  @override
  void initState() {
    super.initState();
    _addWeightField(); // Adicionar primeiro campo de peso
  }
  
  @override
  void dispose() {
    _fertilizerController.dispose();
    _distanceController.dispose();
    _applicationWidthController.dispose();
    _desiredRateController.dispose();
    _granulometriaController.dispose();
    _densidadeController.dispose();
    _machineController.dispose();
    _operatorController.dispose();
    _smallPaddleController.dispose();
    _largePaddleController.dispose();
    _rpmController.dispose();
    _speedController.dispose();
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  
  /// Adiciona um novo campo de peso
  void _addWeightField() {
    final controller = TextEditingController();
    _weightControllers.add(controller);
    setState(() {});
  }
  
  /// Remove um campo de peso
  void _removeWeightField(int index) {
    if (_weightControllers.length > 1) {
      _weightControllers[index].dispose();
      _weightControllers.removeAt(index);
      setState(() {});
    }
  }
  
  
  /// Calcula os resultados da calibração usando as regras práticas de campo
  void _calculateResults() {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      // Coletar dados dos campos
      final weights = _weightControllers
          .map((controller) => double.tryParse(controller.text) ?? 0.0)
          .where((weight) => weight > 0)
          .toList();
      
      if (weights.isEmpty) {
        _showErrorSnackBar('Informe pelo menos um peso coletado');
        return;
      }
      
      // Usar distância padrão de 100 metros
      const double distance = 100.0;
      
      final applicationWidth = double.parse(_applicationWidthController.text);
      final desiredRate = double.tryParse(_desiredRateController.text) ?? 0.0;
      
      // Validar entrada
      final validationError = CalibrationCalculator.validateInput(
        weights: weights,
        distance: distance,
        width: applicationWidth,
      );
      
      if (validationError != null) {
        _showErrorSnackBar(validationError);
        return;
      }
      
      // Calcular usando as regras práticas de campo
      final result = CalibrationCalculator.calculateCalibration(
        weightsGrams: weights,
        distanceM: distance,
        widthM: applicationWidth,
        desiredKgHa: desiredRate > 0 ? desiredRate : null,
      );
      
      // Criar calibração para salvamento
      final calibration = FertilizerCalibration(
        fertilizerName: _fertilizerController.text.isNotEmpty ? _fertilizerController.text : 'Fertilizante',
        granulometry: double.tryParse(_granulometriaController.text) ?? 0.0,
        expectedWidth: applicationWidth,
        spacing: 0.0, // Não usado na versão simplificada
        weights: weights,
        operator: _operatorController.text.isNotEmpty ? _operatorController.text : 'Usuário',
        machine: _machineController.text.isNotEmpty ? _machineController.text : 'Máquina',
        distributionSystem: 'Sistema', // Valor padrão
        collectionType: 'distance', // Tipo de coleta baseado em distância padrão
        smallPaddleValue: double.tryParse(_smallPaddleController.text) ?? 0.0,
        largePaddleValue: double.tryParse(_largePaddleController.text) ?? 0.0,
        rpm: double.tryParse(_rpmController.text) ?? 0.0,
        speed: double.tryParse(_speedController.text) ?? 0.0,
        density: double.tryParse(_densidadeController.text) ?? 0.0,
        distanceTraveled: distance,
        desiredRate: desiredRate,
        // Usar valores calculados pelo CalibrationCalculator
        coefficientOfVariation: result.cvPercent,
        averageWeight: result.mean,
        standardDeviation: result.std,
        realApplicationRate: result.rateKgHa,
        errorPercentage: result.errorPercent,
      );
      
      setState(() {
        _currentCalibration = calibration;
        _calibrationResult = result;
        _showResults = true;
      });
      
    } catch (e) {
      _showErrorSnackBar('Erro ao calcular resultados: $e');
    }
  }
  
  /// Salva a calibração no banco de dados
  Future<void> _saveCalibration() async {
    if (_currentCalibration == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _repository.save(_currentCalibration!);
      _showSuccessSnackBar('Calibração salva com sucesso!');
    } catch (e) {
      _showErrorSnackBar('Erro ao salvar calibração: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Volta para o formulário
  void _backToForm() {
    setState(() {
      _showResults = false;
      _currentCalibration = null;
      _calibrationResult = null;
    });
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibração de Fertilizantes'),
        backgroundColor: const Color(0xFF0057A3),
        foregroundColor: Colors.white,
        actions: [
          if (_showResults)
            IconButton(
              onPressed: _saveCalibration,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
              tooltip: 'Salvar calibração',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!_showResults) _buildSimplifiedForm(),
                  if (_showResults) _buildResults(),
                ],
              ),
            ),
    );
  }
  
  /// Constrói o formulário simplificado
  Widget _buildSimplifiedForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seleção do fertilizante - LIBERADO PARA ENTRADA MANUAL
          FortSmartCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌱 Fertilizante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fertilizerController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Fertilizante',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.eco),
                    helperText: 'Digite o nome do fertilizante manualmente',
                    hintText: 'Ex: NPK 20-10-10, Ureia, Superfosfato...',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o nome do fertilizante';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _granulometriaController,
                        decoration: const InputDecoration(
                          labelText: 'Granulometria (g/L)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                          helperText: 'Peso de 1 litro (opcional)',
                          hintText: 'Ex: 1000',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _densidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Densidade (kg/m³)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.density_medium),
                          helperText: 'Densidade do produto (opcional)',
                          hintText: 'Ex: 1.2',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          
          // Configuração Básica
          FortSmartCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📏 Configuração Básica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _applicationWidthController,
                  decoration: const InputDecoration(
                    labelText: 'Faixa de aplicação (m)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.width_wide),
                    helperText: 'Largura efetiva de trabalho (obrigatório)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a faixa de aplicação';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Faixa deve ser maior que zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _desiredRateController,
                  decoration: const InputDecoration(
                    labelText: 'Taxa desejada (kg/ha) - (obrigatório)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                    helperText: 'Meta de comparação - (obrigatório)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Digite um número válido';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Taxa deve ser maior que zero';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
           ),
           const SizedBox(height: 16),
           
           // Informações adicionais para reutilização
           FortSmartCard(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(
                   '🔧 Informações Adicionais (Para Reutilização)',
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
                 const SizedBox(height: 8),
                 const Text(
                   'Estes dados são salvos para reutilização futura, mas não influenciam nos cálculos',
                   style: TextStyle(
                     color: Colors.grey,
                     fontSize: 12,
                   ),
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: TextFormField(
                         controller: _machineController,
                         decoration: const InputDecoration(
                           labelText: 'Máquina',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.agriculture),
                           helperText: 'Ex: Hércules 6.0',
                         ),
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: TextFormField(
                         controller: _operatorController,
                         decoration: const InputDecoration(
                           labelText: 'Operador',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.person),
                           helperText: 'Nome do operador',
                         ),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: TextFormField(
                         controller: _smallPaddleController,
                         decoration: const InputDecoration(
                           labelText: 'Paleta Pequena (mm)',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.settings),
                           helperText: 'Abertura da paleta pequena',
                         ),
                         keyboardType: TextInputType.number,
                         inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                         ],
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: TextFormField(
                         controller: _largePaddleController,
                         decoration: const InputDecoration(
                           labelText: 'Paleta Grande (mm)',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.settings),
                           helperText: 'Abertura da paleta grande',
                         ),
                         keyboardType: TextInputType.number,
                         inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                         ],
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: TextFormField(
                         controller: _rpmController,
                         decoration: const InputDecoration(
                           labelText: 'RPM',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.speed),
                           helperText: 'Rotação dos discos',
                         ),
                         keyboardType: TextInputType.number,
                         inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                         ],
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: TextFormField(
                         controller: _speedController,
                         decoration: const InputDecoration(
                           labelText: 'Velocidade (km/h)',
                           border: OutlineInputBorder(),
                           prefixIcon: Icon(Icons.speed),
                           helperText: 'Velocidade de trabalho',
                         ),
                         keyboardType: TextInputType.number,
                         inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                         ],
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
           const SizedBox(height: 16),
           
          // Entrada de Coletas (Bandejas/Pontos)
          FortSmartCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '⚖️ Entrada de Coletas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addWeightField,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Adicionar Bandeja'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0057A3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lista dinâmica: usuário adiciona valores de peso coletado em cada bandeja (g). Mínimo recomendado: 6 bandejas.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_weightControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightControllers[index],
                            decoration: InputDecoration(
                              labelText: 'B${index + 1} (g)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.scale),
                              helperText: 'Peso coletado na bandeja ${index + 1}',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe o peso';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Digite um número válido';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_weightControllers.length > 1)
                          IconButton(
                            onPressed: () => _removeWeightField(index),
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            tooltip: 'Remover bandeja',
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Botão calcular
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculateResults,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular Resultados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0057A3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói os resultados
  Widget _buildResults() {
    if (_currentCalibration == null || _calibrationResult == null) return const SizedBox();
    
    return Column(
      children: [
        // Botão voltar
        Row(
          children: [
            IconButton(
              onPressed: _backToForm,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar ao formulário',
            ),
            const Text(
              'Resultados da Calibração',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Resumo dos resultados
        _buildResultsSummary(),
        const SizedBox(height: 16),
        
        // Gráfico de distribuição
        _buildDistributionChart(),
        const SizedBox(height: 16),
        
        // Análise estatística avançada
        if (_currentCalibration != null) ...[
          AdvancedStatisticsWidget(calibration: _currentCalibration!),
          const SizedBox(height: 16),
        ],
        
        // Análise detalhada
        _buildDetailedAnalysis(),
        const SizedBox(height: 16),
        
        // Recomendações
        _buildRecommendations(),
      ],
    );
  }
  
  /// Constrói o resumo dos resultados com cards profissionais
  Widget _buildResultsSummary() {
    final result = _calibrationResult!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0057A3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'RESULTADOS DA CALIBRAÇÃO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Cards profissionais - Primeira linha
        Row(
          children: [
            Expanded(
              child: ProfessionalResultCard(
                title: 'Taxa Real',
                value: '${result.rateKgHa.toStringAsFixed(1)} kg/ha',
                subtitle: 'Taxa aplicada',
                icon: Icons.trending_up,
                primaryColor: const Color(0xFF1976D2),
                tooltip: 'Taxa real de aplicação calculada com base nos pesos coletados',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfessionalResultCard(
                title: 'CV%',
                value: '${result.cvPercent.toStringAsFixed(1)}%',
                subtitle: 'Uniformidade',
                icon: Icons.analytics,
                primaryColor: _getCVColor(result.cvPercent),
                tooltip: 'Coeficiente de variação - indica a uniformidade da distribuição',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Cards profissionais - Segunda linha
        Row(
          children: [
            Expanded(
              child: ProfessionalResultCard(
                title: 'Área Percorrida',
                value: '${result.areaHa.toStringAsFixed(3)} ha',
                subtitle: 'Área coletada',
                icon: Icons.landscape,
                primaryColor: const Color(0xFF4CAF50),
                tooltip: 'Área total percorrida durante a coleta',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfessionalResultCard(
                title: 'Peso Total',
                value: '${result.totalKg.toStringAsFixed(2)} kg',
                subtitle: 'Massa coletada',
                icon: Icons.scale,
                primaryColor: const Color(0xFFFF9800),
                tooltip: 'Peso total coletado em todas as bandejas',
              ),
            ),
          ],
        ),
        
        // Taxa desejada e diferença se informada
        if (_currentCalibration!.desiredRate > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProfessionalResultCard(
                  title: 'Taxa Desejada',
                  value: '${_currentCalibration!.desiredRate.toStringAsFixed(1)} kg/ha',
                  subtitle: 'Meta estabelecida',
                  icon: Icons.flag,
                  primaryColor: const Color(0xFF9C27B0),
                  tooltip: 'Taxa de aplicação desejada estabelecida',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfessionalResultCard(
                  title: 'Diferença',
                  value: '${result.errorPercent.abs().toStringAsFixed(1)}%',
                  subtitle: 'Desvio da meta',
                  icon: result.errorPercent.abs() < 5 ? Icons.check_circle : Icons.warning,
                  primaryColor: result.errorPercent.abs() < 5 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  tooltip: 'Diferença percentual entre taxa real e desejada',
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        _buildStatusCard(),
      ],
    );
  }
  
  /// Constrói um card de métrica
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói o card de status
  Widget _buildStatusCard() {
    final result = _calibrationResult!;
    final cvColor = _getCVColor(result.cvPercent);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cvColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cvColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCVIcon(result.cvPercent),
                color: cvColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status da Distribuição',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cvColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.qualityStatus,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cvColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getAlertMessage(result.cvPercent),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cvColor,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Gera mensagem de alerta baseada no CV%
  String _getAlertMessage(double cv) {
    if (cv <= 10) {
      return '✅ Distribuição excelente - Calibração adequada';
    } else if (cv <= 15) {
      return '⚠️ Atenção: distribuição aceitável, mas pode melhorar';
    } else {
      return '🚨 Distribuição irregular — ajuste regulagem necessário';
    }
  }
  
  /// Constrói o gráfico de distribuição profissional
  Widget _buildDistributionChart() {
    if (_currentCalibration == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gráfico de Distribuição',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: FertilizerDistributionChart(
                calibration: _currentCalibration!,
                height: 300,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Constrói a análise detalhada
  Widget _buildDetailedAnalysis() {
    final result = _calibrationResult!;
    
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Análise Detalhada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildAnalysisRow('Média das taxas', '${result.mean.toStringAsFixed(1)} kg/ha'),
          _buildAnalysisRow('Desvio padrão', '${result.std.toStringAsFixed(1)} kg/ha'),
          _buildAnalysisRow('Número de bandejas', '${result.numberOfTrays}'),
          _buildAnalysisRow('Área por bandeja', '${result.areaPerTray.toStringAsFixed(4)} ha'),
          
          // Informações de coleta
          const Divider(),
          _buildAnalysisRow('Distância padrão de coleta', '100 metros'),
          
          if (result.errorPercent != 0) ...[
            const Divider(),
            _buildAnalysisRow('Taxa desejada', '${_currentCalibration!.desiredRate.toStringAsFixed(1)} kg/ha'),
            _buildAnalysisRow('Erro percentual', '${result.errorPercent.toStringAsFixed(1)}%'),
            _buildAnalysisRow('Fator de ajuste', '${result.adjustmentFactor.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }
  
  /// Constrói uma linha de análise
  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Constrói as recomendações
  Widget _buildRecommendations() {
    final result = _calibrationResult!;
    final recommendations = CalibrationCalculator.generateRecommendations(result);
    
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Recomendações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Recomendação principal de ajuste
          if (result.adjustmentRecommendation.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.adjustmentRecommendation,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Lista de recomendações
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  
  /// Obtém a cor baseada no CV%
  Color _getCVColor(double cv) {
    if (cv <= 10) return Colors.green;
    if (cv <= 15) return Colors.orange;
    return Colors.red;
  }
  
  /// Obtém o ícone baseado no CV%
  IconData _getCVIcon(double cv) {
    if (cv <= 10) return Icons.check_circle;
    if (cv <= 15) return Icons.warning;
    return Icons.error;
  }
}
