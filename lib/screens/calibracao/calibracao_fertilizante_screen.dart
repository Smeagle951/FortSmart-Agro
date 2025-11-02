import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/calibracao_fertilizante_model.dart';
import '../../services/calibracao_fertilizante_service.dart';
import '../../database/repositories/calibracao_fertilizante_repository.dart';
import '../../utils/logger.dart';
import '../../widgets/calibracao_fertilizante_form.dart';
import '../../widgets/calibracao_fertilizante_resultado.dart';
import '../../widgets/calibracao_fertilizante_grafico.dart';

/// Tela principal de calibração de fertilizantes
class CalibracaoFertilizanteScreen extends StatefulWidget {
  final CalibracaoFertilizanteModel? calibracaoParaEditar;
  
  const CalibracaoFertilizanteScreen({
    Key? key, 
    this.calibracaoParaEditar,
  }) : super(key: key);

  @override
  State<CalibracaoFertilizanteScreen> createState() => _CalibracaoFertilizanteScreenState();
}

class _CalibracaoFertilizanteScreenState extends State<CalibracaoFertilizanteScreen> {
  final CalibracaoFertilizanteRepository _repository = CalibracaoFertilizanteRepository();
  
  // Dados de entrada
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _distanciaController = TextEditingController();
  final TextEditingController _espacamentoController = TextEditingController();
  final TextEditingController _faixaEsperadaController = TextEditingController();
  final TextEditingController _granulometriaController = TextEditingController();
  final TextEditingController _taxaDesejadaController = TextEditingController();
  final TextEditingController _diametroPratoController = TextEditingController();
  final TextEditingController _rpmController = TextEditingController();
  final TextEditingController _velocidadeController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  
  // Controllers para pesos das bandejas
  final List<TextEditingController> _pesoControllers = [];
  
  // Estado
  String _tipoPaleta = 'pequena';
  DateTime _dataCalibracao = DateTime.now();
  bool _isLoading = false;
  bool _isCalculando = false;
  CalibracaoFertilizanteModel? _resultadoCalibracao;
  List<String> _erros = [];
  
  // Configuração
  int _numBandejas = 5;
  static const int _maxBandejas = 21;
  static const int _minBandejas = 5;

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _carregarDadosParaEdicao();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _inicializarControllers() {
    // Inicializar controllers de peso
    for (int i = 0; i < _maxBandejas; i++) {
      _pesoControllers.add(TextEditingController());
    }
    
    // Definir valores padrão
    _distanciaController.text = '50.0';
    _espacamentoController.text = '1.0';
  }

  void _disposeControllers() {
    _nomeController.dispose();
    _responsavelController.dispose();
    _distanciaController.dispose();
    _espacamentoController.dispose();
    _faixaEsperadaController.dispose();
    _granulometriaController.dispose();
    _taxaDesejadaController.dispose();
    _diametroPratoController.dispose();
    _rpmController.dispose();
    _velocidadeController.dispose();
    _observacoesController.dispose();
    
    for (final controller in _pesoControllers) {
      controller.dispose();
    }
  }

  void _carregarDadosParaEdicao() {
    if (widget.calibracaoParaEditar != null) {
      final calibracao = widget.calibracaoParaEditar!;
      
      _nomeController.text = calibracao.nome;
      _responsavelController.text = calibracao.responsavel;
      _dataCalibracao = calibracao.dataCalibracao;
      _distanciaController.text = calibracao.distanciaColeta.toString();
      _espacamentoController.text = calibracao.espacamento.toString();
      _tipoPaleta = calibracao.tipoPaleta;
      
      if (calibracao.faixaEsperada != null) {
        _faixaEsperadaController.text = calibracao.faixaEsperada.toString();
      }
      if (calibracao.granulometria != null) {
        _granulometriaController.text = calibracao.granulometria.toString();
      }
      if (calibracao.taxaDesejada != null) {
        _taxaDesejadaController.text = calibracao.taxaDesejada.toString();
      }
      if (calibracao.diametroPratoMm != null) {
        _diametroPratoController.text = calibracao.diametroPratoMm.toString();
      }
      if (calibracao.rpm != null) {
        _rpmController.text = calibracao.rpm.toString();
      }
      if (calibracao.velocidade != null) {
        _velocidadeController.text = calibracao.velocidade.toString();
      }
      if (calibracao.observacoes != null) {
        _observacoesController.text = calibracao.observacoes!;
      }
      
      // Carregar pesos
      _numBandejas = calibracao.pesos.length;
      for (int i = 0; i < calibracao.pesos.length; i++) {
        _pesoControllers[i].text = calibracao.pesos[i].toString();
      }
    }
  }

  void _alterarNumBandejas(int novoNum) {
    if (novoNum >= _minBandejas && novoNum <= _maxBandejas) {
      setState(() {
        _numBandejas = novoNum;
      });
    }
  }

  List<double> _obterPesos() {
    final pesos = <double>[];
    for (int i = 0; i < _numBandejas; i++) {
      final texto = _pesoControllers[i].text.trim();
      if (texto.isNotEmpty) {
        try {
          final peso = double.parse(texto);
          pesos.add(peso);
        } catch (e) {
          pesos.add(0.0);
        }
      } else {
        pesos.add(0.0);
      }
    }
    return pesos;
  }

  void _validarDados() {
    _erros.clear();
    
    // Validações básicas
    if (_nomeController.text.trim().isEmpty) {
      _erros.add('Nome da calibração é obrigatório');
    }
    
    if (_responsavelController.text.trim().isEmpty) {
      _erros.add('Responsável é obrigatório');
    }
    
    // Validar pesos
    final pesos = _obterPesos();
    if (pesos.length < _minBandejas) {
      _erros.add('Mínimo de $_minBandejas pesos é obrigatório');
    }
    
    for (int i = 0; i < pesos.length; i++) {
      if (pesos[i] <= 0) {
        _erros.add('Peso da bandeja ${i + 1} deve ser maior que zero');
      }
    }
    
    // Validar outros campos
    try {
      final distancia = double.parse(_distanciaController.text);
      if (distancia <= 0) {
        _erros.add('Distância de coleta deve ser maior que zero');
      }
    } catch (e) {
      _erros.add('Distância de coleta deve ser um número válido');
    }
    
    try {
      final espacamento = double.parse(_espacamentoController.text);
      if (espacamento <= 0) {
        _erros.add('Espaçamento deve ser maior que zero');
      }
    } catch (e) {
      _erros.add('Espaçamento deve ser um número válido');
    }
  }

  Future<void> _calcular() async {
    setState(() {
      _isCalculando = true;
      _erros.clear();
    });
    
    try {
      _validarDados();
      
      if (_erros.isNotEmpty) {
        setState(() {
          _isCalculando = false;
        });
        return;
      }
      
      final pesos = _obterPesos();
      
      // Criar modelo com cálculos automáticos
      final calibracao = CalibracaoFertilizanteModel.calcular(
        id: widget.calibracaoParaEditar?.id,
        nome: _nomeController.text.trim(),
        dataCalibracao: _dataCalibracao,
        responsavel: _responsavelController.text.trim(),
        pesos: pesos,
        distanciaColeta: double.parse(_distanciaController.text),
        espacamento: double.parse(_espacamentoController.text),
        faixaEsperada: _faixaEsperadaController.text.isNotEmpty 
            ? double.parse(_faixaEsperadaController.text) 
            : null,
        granulometria: _granulometriaController.text.isNotEmpty 
            ? double.parse(_granulometriaController.text) 
            : null,
        taxaDesejada: _taxaDesejadaController.text.isNotEmpty 
            ? double.parse(_taxaDesejadaController.text) 
            : null,
        tipoPaleta: _tipoPaleta,
        diametroPratoMm: _diametroPratoController.text.isNotEmpty 
            ? double.parse(_diametroPratoController.text) 
            : null,
        rpm: _rpmController.text.isNotEmpty 
            ? double.parse(_rpmController.text) 
            : null,
        velocidade: _velocidadeController.text.isNotEmpty 
            ? double.parse(_velocidadeController.text) 
            : null,
        observacoes: _observacoesController.text.trim().isNotEmpty 
            ? _observacoesController.text.trim() 
            : null,
      );
      
      setState(() {
        _resultadoCalibracao = calibracao;
        _isCalculando = false;
      });
      
    } catch (e) {
      Logger.error('Erro ao calcular calibração: $e');
      setState(() {
        _erros.add('Erro ao calcular: $e');
        _isCalculando = false;
      });
    }
  }

  Future<void> _salvar() async {
    if (_resultadoCalibracao == null) {
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
      final id = await _repository.save(_resultadoCalibracao!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calibração salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      Logger.error('Erro ao salvar calibração: $e');
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

  void _mostrarRelatorio() {
    if (_resultadoCalibracao == null) return;
    
    final relatorio = CalibracaoFertilizanteService.gerarRelatorio(_resultadoCalibracao!);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relatório de Calibração'),
        content: SingleChildScrollView(
          child: SelectableText(relatorio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar exportação do relatório
              Navigator.pop(context);
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.calibracaoParaEditar != null 
            ? 'Editar Calibração' 
            : 'Nova Calibração de Fertilizantes'),
        actions: [
          if (_resultadoCalibracao != null)
            IconButton(
              icon: const Icon(Icons.description),
              onPressed: _mostrarRelatorio,
              tooltip: 'Relatório',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Formulário de entrada
                  CalibracaoFertilizanteForm(
                    nomeController: _nomeController,
                    responsavelController: _responsavelController,
                    distanciaController: _distanciaController,
                    espacamentoController: _espacamentoController,
                    faixaEsperadaController: _faixaEsperadaController,
                    granulometriaController: _granulometriaController,
                    taxaDesejadaController: _taxaDesejadaController,
                    diametroPratoController: _diametroPratoController,
                    rpmController: _rpmController,
                    velocidadeController: _velocidadeController,
                    observacoesController: _observacoesController,
                    tipoPaleta: _tipoPaleta,
                    dataCalibracao: _dataCalibracao,
                    numBandejas: _numBandejas,
                    pesoControllers: _pesoControllers,
                    onTipoPaletaChanged: (value) {
                      setState(() {
                        _tipoPaleta = value;
                      });
                    },
                    onDataChanged: (date) {
                      setState(() {
                        _dataCalibracao = date;
                      });
                    },
                    onNumBandejasChanged: _alterarNumBandejas,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCalculando ? null : _calcular,
                          icon: _isCalculando 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.calculate),
                          label: Text(_isCalculando ? 'Calculando...' : 'Calcular'),
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
                          onPressed: _resultadoCalibracao == null || _isLoading 
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
                  
                  const SizedBox(height: 24),
                  
                  // Exibir erros
                  if (_erros.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Erros encontrados:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_erros.map((erro) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $erro',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Resultados
                  if (_resultadoCalibracao != null) ...[
                    CalibracaoFertilizanteResultado(
                      calibracao: _resultadoCalibracao!,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    CalibracaoFertilizanteGrafico(
                      pesos: _resultadoCalibracao!.pesos,
                      espacamento: _resultadoCalibracao!.espacamento,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
