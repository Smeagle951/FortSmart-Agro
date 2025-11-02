import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/calculo_basico_model.dart';
import '../repositories/calculo_basico_repository.dart';
import '../../../utils/snackbar_helper.dart';

/// Tela de Cálculo Básico para Calibração de Fertilizantes
class CalculoBasicoScreen extends StatefulWidget {
  const CalculoBasicoScreen({super.key});

  @override
  State<CalculoBasicoScreen> createState() => _CalculoBasicoScreenState();
}

class _CalculoBasicoScreenState extends State<CalculoBasicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CalculoBasicoRepository();
  
  // Controllers
  final _nomeController = TextEditingController();
  final _equipamentoController = TextEditingController();
  final _operadorController = TextEditingController();
  final _fertilizanteController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _larguraTrabalhoController = TextEditingController();
  final _aberturaComportaController = TextEditingController();
  final _tempoController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _volumeController = TextEditingController();
  final _metaController = TextEditingController();
  final _densidadeController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Estado
  DateTime _dataCalibragem = DateTime.now();
  String _unidadeVolume = 'L';
  TipoColeta _tipoColeta = TipoColeta.distancia;
  bool _isLoading = false;
  CalculoBasicoModel? _resultadoCalculo;

  @override
  void dispose() {
    _nomeController.dispose();
    _equipamentoController.dispose();
    _operadorController.dispose();
    _fertilizanteController.dispose();
    _velocidadeController.dispose();
    _larguraTrabalhoController.dispose();
    _aberturaComportaController.dispose();
    _tempoController.dispose();
    _distanciaController.dispose();
    _volumeController.dispose();
    _metaController.dispose();
    _densidadeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Calcula a calibração
  void _calcularCalibracao() {
    if (!_formKey.currentState!.validate()) return;

    try {
      final calculo = CalculoBasicoModel.comCalculos(
        nome: _nomeController.text.trim(),
        dataCalibragem: _dataCalibragem,
        equipamento: _equipamentoController.text.trim(),
        operador: _operadorController.text.trim(),
        fertilizante: _fertilizanteController.text.trim(),
        velocidadeTrator: double.parse(_velocidadeController.text),
        larguraTrabalho: double.parse(_larguraTrabalhoController.text),
        aberturaComporta: double.parse(_aberturaComportaController.text),
        tipoColeta: _tipoColeta,
        tempoColetado: _tipoColeta == TipoColeta.tempo && _tempoController.text.isNotEmpty
            ? double.parse(_tempoController.text)
            : null,
        distanciaPercorrida: _tipoColeta == TipoColeta.distancia && _distanciaController.text.isNotEmpty
            ? double.parse(_distanciaController.text)
            : null,
        volumeColetado: double.parse(_volumeController.text),
        unidadeVolume: _unidadeVolume,
        metaAplicacao: _metaController.text.isNotEmpty 
            ? double.parse(_metaController.text) 
            : null,
        densidade: _densidadeController.text.isNotEmpty 
            ? double.parse(_densidadeController.text) 
            : null,
        observacoes: _observacoesController.text.trim().isNotEmpty 
            ? _observacoesController.text.trim() 
            : null,
      );

      setState(() {
        _resultadoCalculo = calculo;
      });

      SnackbarHelper.showSuccess(context, 'Cálculo realizado com sucesso!');
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao calcular: $e');
    }
  }

  /// Salva a calibração
  Future<void> _salvarCalibracao() async {
    if (_resultadoCalculo == null) {
      SnackbarHelper.showError(context, 'Realize o cálculo primeiro');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _repository.salvarCalibracao(_resultadoCalculo!);
      SnackbarHelper.showSuccess(context, 'Calibração salva com sucesso!');
      
      // Limpar formulário
      _limparFormulario();
    } catch (e) {
      SnackbarHelper.showError(context, 'Erro ao salvar: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Limpa o formulário
  void _limparFormulario() {
    _formKey.currentState?.reset();
    _nomeController.clear();
    _equipamentoController.clear();
    _operadorController.clear();
    _fertilizanteController.clear();
    _velocidadeController.clear();
    _larguraTrabalhoController.clear();
    _aberturaComportaController.clear();
    _tempoController.clear();
    _distanciaController.clear();
    _volumeController.clear();
    _metaController.clear();
    _densidadeController.clear();
    _observacoesController.clear();
    setState(() {
      _dataCalibragem = DateTime.now();
      _unidadeVolume = 'L';
      _tipoColeta = TipoColeta.distancia;
      _resultadoCalculo = null;
    });
  }

  /// Seleciona data
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataCalibragem,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (data != null) {
      setState(() {
        _dataCalibragem = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo Básico de Calibração'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navegar para histórico
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDadosBasicos(),
              const SizedBox(height: 24),
              _buildDadosTecnicos(),
              const SizedBox(height: 24),
              _buildDadosColeta(),
              const SizedBox(height: 24),
              _buildBotoes(),
              if (_resultadoCalculo != null) ...[
                const SizedBox(height: 24),
                _buildResultados(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDadosBasicos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados Básicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Calibração',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _equipamentoController,
                    decoration: const InputDecoration(
                      labelText: 'Equipamento',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.agriculture),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Equipamento é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _operadorController,
                    decoration: const InputDecoration(
                      labelText: 'Operador',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Operador é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fertilizanteController,
              decoration: const InputDecoration(
                labelText: 'Fertilizante',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grass),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Fertilizante é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selecionarData,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data da Calibração',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_dataCalibragem)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosTecnicos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados Técnicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _velocidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Velocidade (km/h)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Velocidade é obrigatória';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Velocidade deve ser um número positivo';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _larguraTrabalhoController,
                    decoration: const InputDecoration(
                      labelText: 'Largura de Trabalho (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Largura é obrigatória';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Largura deve ser um número positivo';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aberturaComportaController,
              decoration: const InputDecoration(
                labelText: 'Abertura da Comporta (mm)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings),
                hintText: 'Para reutilização da calibração',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Abertura da comporta é obrigatória';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Abertura deve ser um número positivo';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosColeta() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados de Coleta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tipo de coleta
            DropdownButtonFormField<TipoColeta>(
              value: _tipoColeta,
              decoration: const InputDecoration(
                labelText: 'Tipo de Coleta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              items: const [
                DropdownMenuItem(value: TipoColeta.distancia, child: Text('Por Distância')),
                DropdownMenuItem(value: TipoColeta.tempo, child: Text('Por Tempo')),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoColeta = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Campo de entrada baseado no tipo de coleta
            if (_tipoColeta == TipoColeta.distancia)
              TextFormField(
                controller: _distanciaController,
                decoration: const InputDecoration(
                  labelText: 'Distância Percorrida (m)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.route),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Distância é obrigatória';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Distância deve ser um número positivo';
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: _tempoController,
                decoration: const InputDecoration(
                  labelText: 'Tempo de Coleta (segundos)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tempo é obrigatório';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Tempo deve ser um número positivo';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            
            // Volume coletado
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    decoration: const InputDecoration(
                      labelText: 'Volume Coletado',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_drink),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Volume é obrigatório';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Volume deve ser um número positivo';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unidadeVolume,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Litros (L)')),
                      DropdownMenuItem(value: 'kg', child: Text('Quilogramas (kg)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _unidadeVolume = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _metaController,
                    decoration: const InputDecoration(
                      labelText: 'Meta de Aplicação (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                      hintText: 'Ex: 300 kg/ha',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _densidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Densidade (kg/L)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      hintText: 'Ex: 1.2',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoes() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _calcularCalibracao,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _salvarCalibracao,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultados() {
    if (_resultadoCalculo == null) return const SizedBox.shrink();

    final calculo = _resultadoCalculo!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultados da Calibração',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Área percorrida
            _buildResultadoItem(
              'Área Percorrida',
              '${calculo.areaPercorrida?.toStringAsFixed(2) ?? '0.00'} m²',
              Icons.area_chart,
              Colors.blue,
            ),
            
            _buildResultadoItem(
              'Área em Hectares',
              '${calculo.areaHectares?.toStringAsFixed(4) ?? '0.0000'} ha',
              Icons.landscape,
              Colors.green,
            ),
            
            // Taxa de aplicação
            if (calculo.taxaAplicadaL != null && calculo.taxaAplicadaL! > 0)
              _buildResultadoItem(
                'Taxa de Aplicação (L/ha)',
                '${calculo.taxaAplicadaL!.toStringAsFixed(2)} L/ha',
                Icons.local_drink,
                Colors.orange,
              ),
            
            if (calculo.taxaAplicadaKg != null && calculo.taxaAplicadaKg! > 0)
              _buildResultadoItem(
                'Taxa de Aplicação (kg/ha)',
                '${calculo.taxaAplicadaKg!.toStringAsFixed(2)} kg/ha',
                Icons.scale,
                Colors.purple,
              ),
            
            if (calculo.sacasHa != null && calculo.sacasHa! > 0)
              _buildResultadoItem(
                'Sacas por Hectare',
                '${calculo.sacasHa!.toStringAsFixed(2)} sacas/ha',
                Icons.inventory,
                Colors.brown,
              ),
            
            // Status da calibração
            if (calculo.statusCalibragem != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(calculo.statusCalibragem!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(calculo.statusCalibragem!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(calculo.statusCalibragem!),
                          color: _getStatusColor(calculo.statusCalibragem!),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${calculo.statusCalibragem}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(calculo.statusCalibragem!),
                          ),
                        ),
                      ],
                    ),
                    if (calculo.erroPorcentagem != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Erro: ${calculo.erroPorcentagem!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getStatusColor(calculo.statusCalibragem!),
                        ),
                      ),
                    ],
                    if (calculo.sugestaoAjuste != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        calculo.sugestaoAjuste!,
                        style: TextStyle(
                          color: _getStatusColor(calculo.statusCalibragem!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Dentro da meta':
        return Colors.green;
      case 'Acima da meta':
        return Colors.orange;
      case 'Abaixo da meta':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Dentro da meta':
        return Icons.check_circle;
      case 'Acima da meta':
        return Icons.trending_up;
      case 'Abaixo da meta':
        return Icons.trending_down;
      default:
        return Icons.help;
    }
  }
}
