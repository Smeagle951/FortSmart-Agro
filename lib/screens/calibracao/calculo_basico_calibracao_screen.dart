import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calculo_basico_calibracao_model.dart';
import '../../services/calculo_basico_calibracao_service.dart';
import '../../services/universal_calibration_service.dart';
import '../../routes.dart';

/// Tela de Cálculo Básico de Calibração
/// Seguindo o padrão especificado no documento MD
class CalculoBasicoCalibracaoScreen extends StatefulWidget {
  const CalculoBasicoCalibracaoScreen({super.key});

  @override
  State<CalculoBasicoCalibracaoScreen> createState() => _CalculoBasicoCalibracaoScreenState();
}

class _CalculoBasicoCalibracaoScreenState extends State<CalculoBasicoCalibracaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CalculoBasicoCalibracaoService();
  
  // Controladores para entradas obrigatórias
  final _tempoController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _larguraFaixaController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _valorColetadoController = TextEditingController();
  final _taxaDesejadaController = TextEditingController();
  
  // Controladores para campos de registro (opcionais)
  final _operadorController = TextEditingController();
  final _maquinaController = TextEditingController();
  final _comportaController = TextEditingController();
  final _fertilizanteController = TextEditingController();
  final _nomeCalibracaoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Estado
  InputMode _modoColeta = InputMode.time;
  bool _usarGPS = false;
  bool _isLoading = false;
  bool _showResults = false;
  CalculoBasicoCalibracaoModel? _resultado;
  
  // Sistema Universal de Calibração
  String _tipoMaquinaSelecionada = 'personalizada';
  UniversalCalibrationResult? _resultadoUniversal;
  Map<String, dynamic>? _validacaoUniversal;
  
  // Valores GPS
  double _velocidadeGPS = 0.0;
  bool _isGpsActive = false;

  @override
  void initState() {
    super.initState();
    _larguraFaixaController.text = '27.0';
    _taxaDesejadaController.text = '2.00';
  }

  @override
  void dispose() {
    _tempoController.dispose();
    _distanciaController.dispose();
    _larguraFaixaController.dispose();
    _velocidadeController.dispose();
    _valorColetadoController.dispose();
    _taxaDesejadaController.dispose();
    _operadorController.dispose();
    _maquinaController.dispose();
    _comportaController.dispose();
    _fertilizanteController.dispose();
    _nomeCalibracaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _toggleModoColeta(InputMode modo) {
    setState(() {
      _modoColeta = modo;
      _showResults = false;
      _resultado = null;
    });
  }

  void _toggleGPS() {
    setState(() {
      _usarGPS = !_usarGPS;
      if (_usarGPS) {
        _startGPS();
      } else {
        _stopGPS();
      }
    });
  }

  void _startGPS() {
    setState(() {
      _isGpsActive = true;
      _velocidadeGPS = 6.0; // Simular GPS - em implementação real usar geolocator
    });
    
    // Simular atualização da velocidade GPS
    _updateGPSVelocity();
  }

  void _updateGPSVelocity() {
    if (_isGpsActive) {
      setState(() {
        _velocidadeGPS = 6.0 + (DateTime.now().millisecond % 100) / 100; // Simular variação
      });
      Future.delayed(const Duration(seconds: 1), _updateGPSVelocity);
    }
  }

  void _stopGPS() {
    setState(() {
      _isGpsActive = false;
      if (_usarGPS) {
        _velocidadeController.text = _velocidadeGPS.toStringAsFixed(1);
      }
    });
  }

  void _calcular() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Validar entradas obrigatórias
      final tempo = _modoColeta == InputMode.time ? double.parse(_tempoController.text) : 0;
      final distancia = _modoColeta == InputMode.distance ? double.parse(_distanciaController.text) : null;
      final largura = double.parse(_larguraFaixaController.text);
      final velocidade = double.parse(_velocidadeController.text);
      final coletado = double.parse(_valorColetadoController.text);
      final desejada = double.parse(_taxaDesejadaController.text);

      // Validações específicas
      if (_modoColeta == InputMode.time && tempo <= 0) {
        throw ArgumentError('Tempo deve ser maior que zero');
      }
      if (_modoColeta == InputMode.distance && (distancia == null || distancia <= 0)) {
        throw ArgumentError('Distância deve ser maior que zero');
      }
      if (largura <= 0) {
        throw ArgumentError('Largura da faixa deve ser maior que zero');
      }
      if (velocidade <= 0) {
        throw ArgumentError('Velocidade deve ser maior que zero');
      }
      if (coletado <= 0) {
        throw ArgumentError('Valor coletado deve ser maior que zero');
      }
      if (desejada <= 0) {
        throw ArgumentError('Taxa desejada deve ser maior que zero');
      }

      // Criar entrada
      final input = BasicInput(
        mode: _modoColeta,
        timeSeconds: tempo.toDouble(),
        distanceMeters: distancia,
        widthMeters: largura,
        speedKmh: velocidade,
        collectedKg: coletado,
        desiredKgHa: desejada,
      );

      // Calcular resultado com sistema original
      final resultado = CalculoBasicoCalibracaoModel.calcular(
        inputs: input,
        operador: _operadorController.text.trim().isEmpty ? null : _operadorController.text.trim(),
        maquina: _maquinaController.text.trim().isEmpty ? null : _maquinaController.text.trim(),
        comporta: _comportaController.text.trim().isEmpty ? null : _comportaController.text.trim(),
        fertilizante: _fertilizanteController.text.trim().isEmpty ? null : _fertilizanteController.text.trim(),
        nomeCalibracao: _nomeCalibracaoController.text.trim().isEmpty ? null : _nomeCalibracaoController.text.trim(),
        observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
      );

      // Calcular também com sistema universal
      await _calcularComSistemaUniversal(tempo.toDouble(), largura, velocidade, coletado, desejada);

      setState(() {
        _resultado = resultado;
        _showResults = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no cálculo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _calcularComSistemaUniversal(double tempo, double largura, double velocidade, double coletado, double desejada) async {
    try {
      // Validar dados primeiro
      final validacao = UniversalCalibrationService.validarDados(
        tipoMaquina: _tipoMaquinaSelecionada,
        tempoSegundos: tempo,
        larguraFaixa: largura,
        velocidadeKmh: velocidade,
        valorColetadoKg: coletado,
        taxaDesejadaKgHa: desejada,
      );

      setState(() {
        _validacaoUniversal = validacao;
      });

      if (!validacao['valido']) {
        return;
      }

      // Calcular resultado universal
      final resultado = UniversalCalibrationService.calcularCalibracao(
        tipoMaquina: _tipoMaquinaSelecionada,
        tempoSegundos: tempo,
        larguraFaixa: largura,
        velocidadeKmh: velocidade,
        valorColetadoKg: coletado,
        taxaDesejadaKgHa: desejada,
        aberturaAtual: double.tryParse(_comportaController.text),
      );

      setState(() {
        _resultadoUniversal = resultado;
      });
    } catch (e) {
      print('Erro no sistema universal: $e');
    }
  }

  Future<void> _salvar() async {
    if (_resultado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calcule a calibração antes de salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.salvar(_resultado!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calibração salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarHistorico() {
    Navigator.pushNamed(context, AppRoutes.historicoCalibracoes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo Básico de Calibração'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _mostrarHistorico,
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1 - Modo e entradas principais
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Modo e Entradas Principais',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Seleção de Máquina
                            Text(
                              'Tipo de Máquina',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _tipoMaquinaSelecionada,
                              decoration: const InputDecoration(
                                labelText: 'Selecione a máquina',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.agriculture),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: UniversalCalibrationService.obterTiposMaquinas().map((tipo) {
                                final info = UniversalCalibrationService.obterInfoTecnica(tipo);
                                return DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Container(
                                    width: double.infinity,
                                    child: Text(
                                      '${info['modelo']} - ${info['sistema']}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _tipoMaquinaSelecionada = value!;
                                  _showResults = false;
                                  _resultadoUniversal = null;
                                  _validacaoUniversal = null;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Modo de Coleta
                            Text(
                              'Modo de Coleta',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _toggleModoColeta(InputMode.time),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _modoColeta == InputMode.time 
                                              ? Theme.of(context).primaryColor 
                                              : Colors.transparent,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Por Tempo',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _modoColeta == InputMode.time 
                                                ? Colors.white 
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _toggleModoColeta(InputMode.distance),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _modoColeta == InputMode.distance 
                                              ? Theme.of(context).primaryColor 
                                              : Colors.transparent,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Por Distância',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _modoColeta == InputMode.distance 
                                                ? Colors.white 
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Linha 1: Tempo ou Distância
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _modoColeta == InputMode.time 
                                        ? _tempoController 
                                        : _distanciaController,
                                    enabled: true,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: _modoColeta == InputMode.time 
                                          ? 'Tempo (s) *' 
                                          : 'Distância (m) *',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      hintText: _modoColeta == InputMode.time 
                                          ? 'Ex: 10' 
                                          : 'Ex: 20.0',
                                      border: const OutlineInputBorder(),
                                      suffixIcon: Icon(
                                        _modoColeta == InputMode.time 
                                            ? Icons.timer 
                                            : Icons.straighten,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Campo obrigatório';
                                      }
                                      final num = double.tryParse(value!);
                                      if (num == null || num <= 0) {
                                        return 'Valor deve ser > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Linha 2: Largura e Velocidade
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _larguraFaixaController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Largura da Faixa (m) *',
                                      hintText: 'Ex: 27.0',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: Icon(Icons.straighten),
                                    ),
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Campo obrigatório';
                                      }
                                      final num = double.tryParse(value!);
                                      if (num == null || num <= 0) {
                                        return 'Valor deve ser > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _velocidadeController,
                                          enabled: !_usarGPS,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                          ],
                                          decoration: InputDecoration(
                                            labelText: 'Velocidade (km/h) *',
                                            hintText: 'Ex: 6.0',
                                            border: const OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            suffixIcon: _usarGPS 
                                                ? const Icon(Icons.gps_fixed, color: Colors.green)
                                                : const Icon(Icons.speed),
                                          ),
                                          validator: (value) {
                                            if (_usarGPS) return null;
                                            if (value?.trim().isEmpty ?? true) {
                                              return 'Campo obrigatório';
                                            }
                                            final num = double.tryParse(value!);
                                            if (num == null || num <= 0) {
                                              return 'Valor deve ser > 0';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: _toggleGPS,
                                        icon: Icon(
                                          _usarGPS ? Icons.gps_fixed : Icons.gps_off,
                                          color: _usarGPS ? Colors.green : Colors.grey,
                                        ),
                                        tooltip: _usarGPS ? 'Parar GPS' : 'Usar GPS',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Linha 3: Valor coletado e Taxa desejada
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _valorColetadoController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Valor coletado (kg) *',
                                      hintText: 'Ex: 0.080',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: Icon(Icons.scale),
                                    ),
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Campo obrigatório';
                                      }
                                      final num = double.tryParse(value!);
                                      if (num == null || num <= 0) {
                                        return 'Valor deve ser > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _taxaDesejadaController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Taxa desejada (kg/ha) *',
                                      hintText: 'Ex: 2.00',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: Icon(Icons.flag),
                                    ),
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Campo obrigatório';
                                      }
                                      final num = double.tryParse(value!);
                                      if (num == null || num <= 0) {
                                        return 'Valor deve ser > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Botões grandes
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _calcular,
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
                                    onPressed: _resultado == null || _isLoading 
                                        ? null 
                                        : _salvar,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Salvar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Card 2.5 - Resultados do Sistema Universal
                    if (_showResults && _resultadoUniversal != null) ...[
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.precision_manufacturing, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resultados Sistema Universal - ${_resultadoUniversal!.modeloMaquina}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Informações da máquina
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Informações da Máquina:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Sistema: ${_resultadoUniversal!.infoMaquina['sistema']}'),
                                    Text('Largura padrão: ${_resultadoUniversal!.infoMaquina['largura_padrao']}m'),
                                    Text('Fator de correção: ${_resultadoUniversal!.infoMaquina['fator_correcao']}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Resultados principais
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _getUniversalTaxaColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _getUniversalTaxaColor()),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Taxa Real Aplicada (kg/ha)',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_resultadoUniversal!.taxaRealAplicada.toStringAsFixed(2)} kg/ha',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getUniversalTaxaColor(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getUniversalErroIcon(),
                                          color: _getUniversalErroColor(),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _resultadoUniversal!.statusTolerancia,
                                          style: TextStyle(
                                            color: _getUniversalErroColor(),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Detalhes técnicos
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detalhes Técnicos:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Distância percorrida:'),
                                        Text('${_resultadoUniversal!.distanciaPercorrida.toStringAsFixed(2)} m'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Área coberta:'),
                                        Text('${_resultadoUniversal!.areaCoberta.toStringAsFixed(2)} m²'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Área em hectares:'),
                                        Text('${_resultadoUniversal!.areaHectares.toStringAsFixed(4)} ha'),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Erro percentual:'),
                                        Text(
                                          '${_resultadoUniversal!.erroPercentual.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: _getUniversalErroColor(),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Fator de ajuste:'),
                                        Text('${_resultadoUniversal!.fatorAjuste.toStringAsFixed(3)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Recomendações
                              if (_resultadoUniversal!.recomendacaoAjuste.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.lightbulb, color: Colors.orange),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Recomendação:',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(_resultadoUniversal!.recomendacaoAjuste),
                                      if (_resultadoUniversal!.aberturaSugerida > 0) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Abertura sugerida: ${_resultadoUniversal!.aberturaSugerida.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
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
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Card 2 - Resultados da Calibração
                    if (_showResults && _resultado != null) ...[
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resultados da Calibração',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Linha de resumo
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildResumoItem(
                                      Icons.straighten,
                                      'Distância',
                                      '${_resultado!.computedResults.distanceMeters.toStringAsFixed(2)} m',
                                    ),
                                    _buildResumoItem(
                                      Icons.area_chart,
                                      'Área',
                                      '${_resultado!.computedResults.areaM2.toStringAsFixed(2)} m²',
                                    ),
                                    _buildResumoItem(
                                      Icons.crop_free,
                                      'Área',
                                      '${_resultado!.computedResults.areaHa.toStringAsFixed(4)} ha',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Resultados principais
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _getTaxaColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _getTaxaColor()),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Taxa aplicada (kg/ha)',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_resultado!.computedResults.taxaKgHa.toStringAsFixed(2)} kg/ha',
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getTaxaColor(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getErroIcon(),
                                          color: _getErroColor(),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getErroText(),
                                          style: TextStyle(
                                            color: _getErroColor(),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Sugestão de Ajuste',
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getSugestaoTexto(),
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _getErroColor(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Campos adicionais para registro (colapsáveis)
                    ExpansionTile(
                      title: const Text('Campos Adicionais para Registro'),
                      subtitle: const Text('Informações opcionais para histórico'),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _operadorController,
                                        decoration: const InputDecoration(
                                          labelText: 'Operador',
                                          hintText: 'Nome do operador',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _maquinaController,
                                        decoration: const InputDecoration(
                                          labelText: 'Máquina',
                                          hintText: 'Equipamento',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _comportaController,
                                        decoration: const InputDecoration(
                                          labelText: 'Comporta / Tamanho',
                                          hintText: 'Ex: Abertura 3',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _fertilizanteController,
                                        decoration: const InputDecoration(
                                          labelText: 'Fertilizante',
                                          hintText: 'Ex: NPK',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nomeCalibracaoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome da Calibração',
                                    hintText: 'Ex: teste',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _observacoesController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Observações',
                                    hintText: 'Observações adicionais...',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildResumoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTaxaColor() {
    final erro = _resultado!.computedResults.erroPercent.abs();
    if (erro <= 2) return Colors.green;
    if (erro <= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getErroColor() {
    final erro = _resultado!.computedResults.erroPercent;
    if (erro.abs() <= 2) return Colors.green;
    if (erro < -2) return Colors.red;
    if (erro > 2) return Colors.orange;
    return Colors.grey;
  }

  IconData _getErroIcon() {
    final erro = _resultado!.computedResults.erroPercent;
    if (erro.abs() <= 2) return Icons.check_circle;
    if (erro < -2) return Icons.trending_down;
    if (erro > 2) return Icons.trending_up;
    return Icons.info;
  }

  String _getErroText() {
    final erro = _resultado!.computedResults.erroPercent;
    if (erro.abs() <= 2) return 'Dentro da tolerância';
    if (erro < -2) return 'Abaixo da meta';
    if (erro > 2) return 'Acima da meta';
    return 'Verificar';
  }

  String _getSugestaoTexto() {
    final ajuste = _resultado!.computedResults.ajustePercent;
    if (ajuste > 0) {
      return 'Aumentar dosador ≈ ${ajuste.toStringAsFixed(1)}%';
    } else if (ajuste < 0) {
      return 'Reduzir dosador ≈ ${ajuste.abs().toStringAsFixed(1)}%';
    } else {
      return 'Sem ajuste necessário';
    }
  }

  // Métodos auxiliares para o sistema universal
  Color _getUniversalTaxaColor() {
    if (_resultadoUniversal == null) return Colors.grey;
    final erro = _resultadoUniversal!.erroPercentual.abs();
    if (erro <= 5) return Colors.green;
    if (erro <= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getUniversalErroColor() {
    if (_resultadoUniversal == null) return Colors.grey;
    final erro = _resultadoUniversal!.erroPercentual;
    if (erro.abs() <= 5) return Colors.green;
    if (erro < -5) return Colors.red;
    if (erro > 5) return Colors.orange;
    return Colors.grey;
  }

  IconData _getUniversalErroIcon() {
    if (_resultadoUniversal == null) return Icons.info;
    final erro = _resultadoUniversal!.erroPercentual;
    if (erro.abs() <= 5) return Icons.check_circle;
    if (erro < -5) return Icons.trending_down;
    if (erro > 5) return Icons.trending_up;
    return Icons.info;
  }
}
