import 'package:flutter/material.dart';
import '../../models/fertilizer_calibration.dart';
import '../../repositories/fertilizer_calibration_repository.dart';
import '../../widgets/fertilizer_distribution_chart.dart';
import '../../widgets/professional_result_card.dart';
import '../../widgets/advanced_statistics_widget.dart';
// import '../../models/machine.dart'; // Removido - módulo de máquinas removido
import '../../models/agricultural_product.dart';
// import '../../repositories/machine_repository.dart'; // Removido - módulo de máquinas removido
import '../../repositories/agricultural_product_repository.dart';
import '../../models/agricultural_product.dart' show ProductType;

/// Tela principal de calibração de fertilizantes - Guia Técnico FortSmart
class FertilizerCalibrationScreen extends StatefulWidget {
  const FertilizerCalibrationScreen({super.key});

  @override
  State<FertilizerCalibrationScreen> createState() => _FertilizerCalibrationScreenState();
}

class _FertilizerCalibrationScreenState extends State<FertilizerCalibrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = FertilizerCalibrationRepository();
  // Repositório de máquinas removido - usando entrada manual
  final _productRepository = AgriculturalProductRepository();
  
  // Controladores - Guia Técnico FortSmart
  final _fertilizerController = TextEditingController();
  final _granulometryController = TextEditingController();
  final _expectedWidthController = TextEditingController();
  final _spacingController = TextEditingController();
  final _operatorController = TextEditingController();
  final _machineController = TextEditingController();
  final _rpmController = TextEditingController();
  final _speedController = TextEditingController();
  final _desiredRateController = TextEditingController();
  final _smallPaddleValueController = TextEditingController();
  final _largePaddleValueController = TextEditingController();
  final _distanceTraveledController = TextEditingController();
  final _densityController = TextEditingController(); // g/L - Densidade (Granulometria)
  
  // Estados
  bool _isLoading = false;
  bool _showResults = false;
  FertilizerCalibration? _currentCalibration;
  
  // Lista de pesos
  final List<TextEditingController> _weightControllers = [];
  
  // Dados dinâmicos
  // Lista de máquinas removida - usando entrada manual
  bool _isLoadingMachines = false;
  
  // Sistemas de distribuição
  final List<String> _availableDistributionSystems = [
    'Paletas rotativas',
    'Z-atirador',
    'Pneumático',
    'Centrífugo',
    'Outro',
  ];
  
  // Estados dos dropdowns
  String? _selectedMachine;
  String? _selectedDistributionSystem;
  

  @override
  void initState() {
    super.initState();
    
    // Definir valores padrão para facilitar o uso
    _spacingController.text = '1.0'; // Espaçamento padrão de 1m
    _operatorController.text = 'Operador'; // Valor padrão
    _rpmController.text = '540'; // RPM padrão para tratores
    _speedController.text = '8.0'; // Velocidade padrão de 8 km/h
    _distanceTraveledController.text = '50.0'; // Distância padrão de 50m
    _densityController.text = '1000'; // Densidade padrão de 1000 g/L
    _desiredRateController.text = '140.0'; // Taxa desejada padrão de 140 kg/ha
    
    _loadData();
  }

  /// Carrega dados iniciais
  Future<void> _loadData() async {
    await _initializeRepository();
    
    // Adicionar 5 bandejas padrão com valores de exemplo
    for (int i = 0; i < 5; i++) {
      _addWeightController();
      // Valores de exemplo para demonstração (pesos realistas em gramas)
      _weightControllers[i].text = '${150 + (i * 2)}'; // 150, 152, 154, 156, 158
    }
    
    await _carregarMaquinas();
  }

  @override
  void dispose() {
    _fertilizerController.dispose();
    _granulometryController.dispose();
    _expectedWidthController.dispose();
    _spacingController.dispose();
    _operatorController.dispose();
    _machineController.dispose();
    _rpmController.dispose();
    _speedController.dispose();
    _desiredRateController.dispose();
    _smallPaddleValueController.dispose();
    _largePaddleValueController.dispose();
    _distanceTraveledController.dispose();
    _densityController.dispose();
    for (final controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Inicializa o repositório com tratamento robusto de erros
  Future<void> _initializeRepository() async {
    try {
      print('🔧 Inicializando repositórios...');
      await _repository.initialize();
      // Repositórios de produtos e máquinas não precisam de inicialização
      print('✅ Repositórios inicializados com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar repositórios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao inicializar banco de dados: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              onPressed: () => _initializeRepository(),
            ),
          ),
        );
      }
    }
  }

  /// Adiciona um controlador de peso
  void _addWeightController() {
    setState(() {
      _weightControllers.add(TextEditingController());
    });
  }

  /// Remove um controlador de peso
  void _removeWeightController() {
    if (_weightControllers.length > 1) {
      setState(() {
        final controller = _weightControllers.removeLast();
        controller.dispose();
      });
    }
  }

  /// Calcula a calibração seguindo o Guia Técnico FortSmart
  Future<void> _calculateCalibration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Coleta os pesos das bandejas
      final weights = <double>[];
      for (final controller in _weightControllers) {
        final weight = double.tryParse(controller.text);
        if (weight != null && weight >= 0) { // Aceitar peso zero também
          weights.add(weight);
        }
      }
      
      if (weights.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mínimo de 5 bandejas é necessário para o cálculo'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação dos campos obrigatórios do Guia Técnico
      if (_selectedMachine == null || _selectedMachine!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione uma máquina'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      if (_selectedDistributionSystem == null || _selectedDistributionSystem!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione o sistema de distribuição'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação das paletas (mais flexível)
      if (_smallPaddleValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite o valor da paleta pequena (mm) - Campo obrigatório para análise técnica'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      if (_largePaddleValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite o valor da paleta grande (mm) - Campo obrigatório para análise técnica'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final smallPaddleValue = double.tryParse(_smallPaddleValueController.text);
      if (smallPaddleValue == null || smallPaddleValue < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valor da paleta pequena deve ser um número válido maior ou igual a zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final largePaddleValue = double.tryParse(_largePaddleValueController.text);
      if (largePaddleValue == null || largePaddleValue < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valor da paleta grande deve ser um número válido maior ou igual a zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação do RPM
      if (_rpmController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite o RPM dos pratos - Campo obrigatório para análise técnica'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final rpm = double.tryParse(_rpmController.text);
      if (rpm == null || rpm <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('RPM deve ser um número válido maior que zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação da velocidade
      if (_speedController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite a velocidade (km/h) - Campo obrigatório para análise técnica'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final speed = double.tryParse(_speedController.text);
      if (speed == null || speed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Velocidade deve ser um número válido maior que zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação da densidade (granulometria)
      if (_densityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite a densidade (g/L) - Campo obrigatório para análise técnica'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final density = double.tryParse(_densityController.text);
      if (density == null || density <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Densidade deve ser um número válido maior que zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação da taxa desejada
      if (_desiredRateController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite a taxa desejada (kg/ha) - Campo obrigatório'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final desiredRate = double.tryParse(_desiredRateController.text);
      if (desiredRate == null || desiredRate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taxa desejada deve ser um número válido maior que zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Validação da distância percorrida
      if (_distanceTraveledController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Digite a distância percorrida (m)'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final distanceTraveled = double.tryParse(_distanceTraveledController.text);
      if (distanceTraveled == null || distanceTraveled <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Distância percorrida deve ser um número válido maior que zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      // Cria a calibração com fórmulas científicas do Guia Técnico FortSmart
      final calibration = FertilizerCalibration(
        fertilizerName: _fertilizerController.text,
        granulometry: double.parse(_granulometryController.text),
        expectedWidth: _expectedWidthController.text.isNotEmpty 
            ? double.parse(_expectedWidthController.text) 
            : null,
        spacing: double.parse(_spacingController.text),
        weights: weights,
        operator: _operatorController.text,
        machine: _selectedMachine!,
        distributionSystem: _selectedDistributionSystem!,
        smallPaddleValue: smallPaddleValue,
        largePaddleValue: largePaddleValue,
        rpm: rpm,
        speed: speed,
        density: density,
        distanceTraveled: double.parse(_distanceTraveledController.text),
        collectionType: 'distance',
        desiredRate: desiredRate,
      ).withCalculations();
      
      setState(() {
        _currentCalibration = calibration;
        _showResults = true;
        _isLoading = false;
      });
      
      // Mostrar feedback detalhado dos resultados
      _showDetailedResults(calibration);
      
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao calcular calibração: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Ver Detalhes',
            onPressed: () => _showErrorDetails(e.toString()),
          ),
        ),
      );
    }
  }

  /// Salva a calibração com tratamento robusto de erros
  Future<void> _saveCalibration() async {
    if (_currentCalibration == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('💾 Salvando calibração...');
      await _repository.save(_currentCalibration!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Calibração salva com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        print('✅ Calibração salva com sucesso');
      }
    } catch (e) {
      print('❌ Erro ao salvar calibração: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              onPressed: () => _saveCalibration(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              icon: const Icon(Icons.save),
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
                  if (!_showResults) _buildForm(),
                  if (_showResults) _buildResults(),
                ],
              ),
            ),
    );
  }

  /// Constrói o formulário de entrada
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informações da Máquina'),
          const SizedBox(height: 16),
          
          // Máquina
          Row(
            children: [
              Expanded(
                child: _isLoadingMachines
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedMachine,
                        decoration: const InputDecoration(
                          labelText: 'Máquina',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.agriculture),
                        ),
                        items: [
                          // ..._availableMachines.map((machine) { // Módulo removido
                          //   return DropdownMenuItem(
                          //     value: machine.name,
                          //     child: Text(
                          //       machine.name,
                          //       overflow: TextOverflow.ellipsis,
                          //       maxLines: 1,
                          //     ),
                          //   );
                          // }),
                          const DropdownMenuItem(
                            value: 'add_new',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Adicionar Nova',
                                    style: TextStyle(color: Colors.blue, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == 'add_new') {
                            _showAddMachineDialog();
                          } else {
                            setState(() {
                              _selectedMachine = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          return null;
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sistema de distribuição
          DropdownButtonFormField<String>(
            value: _selectedDistributionSystem,
            decoration: const InputDecoration(
              labelText: 'Sistema de Distribuição',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.settings),
            ),
            items: _availableDistributionSystems.map((system) {
              return DropdownMenuItem(
                value: system,
                child: Text(system),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistributionSystem = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Paletas (ambas obrigatórias) - Guia Técnico FortSmart
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configuração das Paletas (mm)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _smallPaddleValueController,
                      decoration: const InputDecoration(
                        labelText: 'Paleta Pequena (mm)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings),
                        helperText: 'Valor da paleta pequena',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Digite um número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _largePaddleValueController,
                      decoration: const InputDecoration(
                        labelText: 'Paleta Grande (mm)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings),
                        helperText: 'Valor da paleta grande',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Digite um número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Densidade (Granulometria) - Guia Técnico FortSmart
          TextFormField(
            controller: _densityController,
            decoration: const InputDecoration(
              labelText: 'Densidade (Granulometria) (g/L)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              helperText: 'Densidade do fertilizante em gramas por litro',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              if (double.tryParse(value) == null) {
                return 'Digite um número válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // RPM e Velocidade
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rpmController,
                  decoration: const InputDecoration(
                    labelText: 'Giro dos Pratos (RPM)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.rotate_right),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _speedController,
                  decoration: const InputDecoration(
                    labelText: 'Velocidade (km/h)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.speed),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Configuração da Calibração'),
          const SizedBox(height: 16),
          
          // Fertilizante - Campo de texto livre
          TextFormField(
            controller: _fertilizerController,
            decoration: const InputDecoration(
              labelText: 'Fertilizante',
              hintText: 'Digite o nome do fertilizante (ex: Ureia, NPK 20-20-20)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.eco),
              helperText: 'Digite manualmente o nome do fertilizante que você está utilizando',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório - digite o nome do fertilizante';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Granulometria e Taxa Desejada
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _granulometryController,
                  decoration: const InputDecoration(
                    labelText: 'Granulometria (g/L)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grain),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _desiredRateController,
                  decoration: const InputDecoration(
                    labelText: 'Taxa Desejada (kg/ha)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Distância percorrida
          TextFormField(
            controller: _distanceTraveledController,
            decoration: const InputDecoration(
              labelText: 'Distância Percorrida (m)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.straighten),
              helperText: 'Distância percorrida durante a coleta (ex: 50, 100)',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              if (double.tryParse(value) == null) {
                return 'Digite um número válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Faixa esperada (opcional)
          TextFormField(
            controller: _expectedWidthController,
            decoration: const InputDecoration(
              labelText: 'Faixa Esperada (m) - Opcional',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.width_normal),
              helperText: 'Faixa esperada de distribuição (opcional)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Espaçamento
          TextFormField(
            controller: _spacingController,
            decoration: const InputDecoration(
              labelText: 'Espaçamento (m)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.grid_on),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo obrigatório';
              }
              if (double.tryParse(value) == null) {
                return 'Digite um número válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Operador
          TextFormField(
            controller: _operatorController,
            decoration: const InputDecoration(
              labelText: 'Operador',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o operador';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Pesos coletados
          _buildWeightsSection(),
          const SizedBox(height: 24),
          
          // Botão calcular
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculateCalibration,
              icon: const Icon(Icons.calculate),
              label: const Text(
                'CALCULAR 📊',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0057A3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói título de seção
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  /// Constrói a seção de pesos
  Widget _buildWeightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesos Coletados (g)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _addWeightController,
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  tooltip: 'Adicionar bandeja',
                ),
                IconButton(
                  onPressed: _removeWeightController,
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  tooltip: 'Remover bandeja',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Mínimo: 5 bandejas (atual: ${_weightControllers.length})',
          style: TextStyle(
            fontSize: 12,
            color: _weightControllers.length >= 5 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weightControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            
            return SizedBox(
              width: 80,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'B${index + 1}',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Constrói os resultados
  Widget _buildResults() {
    if (_currentCalibration == null) return const SizedBox.shrink();

    final calibration = _currentCalibration!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho dos resultados
        Card(
          color: const Color(0xFF0057A3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RESULTADOS DA CALIBRAÇÃO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showResults = false;
                          _currentCalibration = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '⚙️ Máquina: ${calibration.machine}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '🔄 RPM: ${calibration.rpm.toStringAsFixed(0)} | Paleta P: ${calibration.smallPaddleValue.toStringAsFixed(1)}mm | Paleta G: ${calibration.largePaddleValue.toStringAsFixed(1)}mm',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '📏 Densidade: ${calibration.density.toStringAsFixed(0)} g/L | Velocidade: ${calibration.speed.toStringAsFixed(1)} km/h',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Resultados principais com cards profissionais
        Row(
          children: [
            Expanded(
              child: ProfessionalResultCard(
                title: 'Taxa Real',
                value: '${calibration.realApplicationRate.toStringAsFixed(1)} kg/ha',
                subtitle: 'Taxa aplicada',
                icon: Icons.trending_up,
                primaryColor: _getRateStatusColor(calibration.rateStatus),
                tooltip: 'Taxa real de aplicação calculada com base nos pesos coletados',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfessionalResultCard(
                title: 'Erro',
                value: '${calibration.errorPercentage.toStringAsFixed(1)}%',
                subtitle: 'Desvio da meta',
                icon: Icons.warning,
                primaryColor: _getErrorStatusColor(calibration.errorStatus),
                tooltip: 'Diferença percentual entre taxa real e desejada',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ProfessionalResultCard(
                title: 'CV%',
                value: '${calibration.coefficientOfVariation.toStringAsFixed(1)}%',
                subtitle: 'Uniformidade',
                icon: Icons.analytics,
                primaryColor: _getCVStatusColor(calibration.cvStatus),
                tooltip: 'Coeficiente de variação - indica a uniformidade da distribuição',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfessionalResultCard(
                title: 'Faixa Efetiva',
                value: '${calibration.realWidth.toStringAsFixed(1)}m',
                subtitle: 'Largura real',
                icon: Icons.width_normal,
                primaryColor: Colors.blue,
                tooltip: 'Largura efetiva de aplicação calculada',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Gráfico de distribuição
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribuição por Bandejas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: FertilizerDistributionChart(
                    calibration: calibration,
                    height: 200,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Análise estatística avançada
        AdvancedStatisticsWidget(calibration: calibration),
        const SizedBox(height: 16),
        
        // Recomendações
        _buildRecommendations(calibration),
      ],
    );
  }

  /// Constrói um card de resultado
  Widget _buildResultCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói as recomendações
  Widget _buildRecommendations(FertilizerCalibration calibration) {
    final List<String> recommendations = [];
    
    // Recomendações baseadas no CV
    if (calibration.cvStatus == 'Ruim') {
      recommendations.add('• CV muito alto (${calibration.coefficientOfVariation.toStringAsFixed(1)}%). Verificar distribuição da máquina');
    } else if (calibration.cvStatus == 'Moderado') {
      recommendations.add('• CV moderado. Considerar ajustes na máquina');
    } else {
      recommendations.add('• CV excelente! Distribuição uniforme');
    }
    
    // Recomendações baseadas no erro
    if (calibration.errorStatus == 'Recalibrar') {
      recommendations.add('• Erro alto (${calibration.errorPercentage.toStringAsFixed(1)}%). Recalibrar máquina');
    } else {
      recommendations.add('• Erro aceitável. Calibração adequada');
    }
    
    // Recomendações baseadas na faixa
    if (calibration.expectedWidth != null) {
      final ratio = calibration.realWidth / calibration.expectedWidth!;
      if (ratio < 0.8 || ratio > 1.2) {
        recommendations.add('• Faixa efetiva diferente da esperada. Verificar configuração');
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recomendações',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(rec),
            )),
          ],
        ),
      ),
    );
  }

  /// Retorna a cor do status da taxa
  Color _getRateStatusColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'Alerta':
        return Colors.orange;
      case 'Recalibrar':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Retorna a cor do status do erro
  Color _getErrorStatusColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'Recalibrar':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Retorna a cor do status do CV
  Color _getCVStatusColor(String status) {
    switch (status) {
      case 'Excelente':
        return Colors.green;
      case 'Moderado':
        return Colors.orange;
      case 'Ruim':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  /// Carrega máquinas disponíveis
  Future<void> _carregarMaquinas() async {
    // Módulo de máquinas removido - usando entrada manual
    if (mounted) {
      setState(() {
        _isLoadingMachines = false;
      });
    }
    print('✅ Calibração de fertilizantes pronta para entrada manual de dados');
  }

  /// Mostra diálogo para adicionar máquina
  void _showAddMachineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Nova Máquina'),
        content: TextField(
          controller: _machineController,
          decoration: const InputDecoration(
            labelText: 'Nome da Máquina',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _machineController.text.trim();
              if (name.isNotEmpty) {
                final newMachineName = name;
                setState(() {
                  _selectedMachine = newMachineName;
                  // _availableMachines.add(Machine( // Módulo removido
                  //   name: newMachineName,
                  //   type: MachineType.other,
                  //   brand: '',
                  //   model: '',
                  //   year: 2024,
                  //   status: MachineStatus.operational,
                  // ));
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }


  /// Mostra resultados detalhados da calibração
  void _showDetailedResults(FertilizerCalibration calibration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Resultados da Calibração'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('Taxa Real', '${calibration.realApplicationRate.toStringAsFixed(1)} kg/ha'),
              _buildResultRow('Taxa Desejada', '${calibration.desiredRate.toStringAsFixed(1)} kg/ha'),
              _buildResultRow('Erro', '${calibration.errorPercentage.toStringAsFixed(1)}%'),
              _buildResultRow('Status do Erro', _getStatusText(calibration.errorStatus)),
              const Divider(),
              _buildResultRow('CV%', '${calibration.coefficientOfVariation.toStringAsFixed(1)}%'),
              _buildResultRow('Status do CV', _getCVStatusText(calibration.cvStatus)),
              _buildResultRow('Faixa Efetiva', '${calibration.realWidth.toStringAsFixed(1)} m'),
              _buildResultRow('Status da Faixa', _getWidthStatusText(calibration.widthStatus)),
              const Divider(),
              _buildResultRow('Média dos Pesos', '${calibration.averageWeight.toStringAsFixed(1)} g'),
              _buildResultRow('Desvio Padrão', '${calibration.standardDeviation.toStringAsFixed(1)} g'),
              _buildResultRow('Bandejas Válidas', '${calibration.effectiveRangeIndices.length}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveCalibration();
            },
            child: const Text('Salvar Calibração'),
          ),
        ],
      ),
    );
  }

  /// Constrói uma linha de resultado
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  /// Retorna texto formatado para status
  String _getStatusText(String status) {
    switch (status) {
      case 'OK':
        return '✅ OK';
      case 'Recalibrar':
        return '❌ Recalibrar';
      case 'Alerta':
        return '⚠️ Alerta';
      default:
        return status;
    }
  }

  /// Retorna texto formatado para status do CV
  String _getCVStatusText(String status) {
    switch (status) {
      case 'Excelente':
        return '✅ Excelente';
      case 'Moderado':
        return '⚠️ Moderado';
      case 'Ruim':
        return '❌ Ruim';
      default:
        return status;
    }
  }

  /// Retorna texto formatado para status da faixa
  String _getWidthStatusText(String status) {
    switch (status) {
      case 'OK':
        return '✅ OK';
      case 'Incompleta':
        return '⚠️ Incompleta';
      default:
        return status;
    }
  }

  /// Mostra detalhes do erro
  void _showErrorDetails(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Erro na Calibração'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalhes do erro:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sugestões:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Verifique se todos os campos obrigatórios estão preenchidos'),
            const Text('• Certifique-se de que os valores numéricos são válidos'),
            const Text('• Verifique se há pelo menos 5 bandejas com peso > 0'),
            const Text('• Confirme se a distância percorrida é > 0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


} 