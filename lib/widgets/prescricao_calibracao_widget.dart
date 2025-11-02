import 'package:flutter/material.dart';
import '../models/prescricao_model.dart';


import '../utils/app_colors.dart';

/// Widget para configuração de calibração do equipamento
/// Permite configurar parâmetros de aplicação terrestre, aérea ou drone
class PrescricaoCalibracaoWidget extends StatefulWidget {
  final CalibracaoModel? calibracao;
  final Function(CalibracaoModel) onCalibracaoChanged;
  final String tipoAplicacao;

  const PrescricaoCalibracaoWidget({
    super.key,
    this.calibracao,
    required this.onCalibracaoChanged,
    required this.tipoAplicacao,
  });

  @override
  State<PrescricaoCalibracaoWidget> createState() => _PrescricaoCalibracaoWidgetState();
}

class _PrescricaoCalibracaoWidgetState extends State<PrescricaoCalibracaoWidget> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para campos de entrada
  final _bicosAtivosController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _larguraController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _pressaoController = TextEditingController();
  final _vazaoBicoController = TextEditingController();
  final _vazaoTotalController = TextEditingController();
  final _faixaController = TextEditingController();
  final _alturaController = TextEditingController();
  final _larguraEfetivaController = TextEditingController();
  final _eficienciaController = TextEditingController();

  // Estados
  String _modoCalculo = 'vazao_bico'; // 'vazao_bico' ou 'volume_alvo'
  double? _volumeCalculado;
  double? _vazaoBicoNecessaria;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _populateControllers();
  }

  @override
  void dispose() {
    _bicosAtivosController.dispose();
    _espacamentoController.dispose();
    _larguraController.dispose();
    _velocidadeController.dispose();
    _pressaoController.dispose();
    _vazaoBicoController.dispose();
    _vazaoTotalController.dispose();
    _faixaController.dispose();
    _alturaController.dispose();
    _larguraEfetivaController.dispose();
    _eficienciaController.dispose();
    super.dispose();
  }

  /// Popula os controladores com dados existentes
  void _populateControllers() {
    if (widget.calibracao != null) {
      final cal = widget.calibracao!;
      _modoCalculo = cal.modoCalculo;
      _bicosAtivosController.text = cal.bicosAtivos.toString();
      _espacamentoController.text = cal.espacamentoM.toString();
      _larguraController.text = cal.larguraM.toString();
      _velocidadeController.text = cal.velocidadeKmh.toString();
      _pressaoController.text = cal.pressao?.toString() ?? '';
      _vazaoBicoController.text = cal.vazaoBicoLMin?.toString() ?? '';
      _vazaoTotalController.text = cal.vazaoTotalLMin?.toString() ?? '';
      _eficienciaController.text = (cal.eficienciaCampo * 100).toString();
    } else {
      // Valores padrão
      _eficienciaController.text = '85';
    }
  }

  /// Calcula a calibração baseada nos parâmetros informados
  void _calcularCalibracao() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    try {
      if (widget.tipoAplicacao == 'Terrestre') {
        _calcularCalibracaoTerrestre();
      } else if (widget.tipoAplicacao == 'Aérea') {
        _calcularCalibracaoAerea();
      } else if (widget.tipoAplicacao == 'Drone') {
        _calcularCalibracaoDrone();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no cálculo: $e')),
      );
    } finally {
      setState(() => _isCalculating = false);
    }
  }

  /// Calcula calibração para aplicação terrestre
  void _calcularCalibracaoTerrestre() {
    final bicos = int.tryParse(_bicosAtivosController.text) ?? 0;
    final espacamento = double.tryParse(_espacamentoController.text) ?? 0;
    final velocidade = double.tryParse(_velocidadeController.text) ?? 0;
    final eficiencia = double.tryParse(_eficienciaController.text) ?? 85;

    // Calcula largura se não informada
    double largura = double.tryParse(_larguraController.text) ?? 0;
    if (largura == 0 && bicos > 0 && espacamento > 0) {
      largura = bicos * espacamento;
      _larguraController.text = largura.toStringAsFixed(2);
    }

    if (_modoCalculo == 'vazao_bico') {
      // Modo 1: Informar vazão por bico
      final vazaoBico = double.tryParse(_vazaoBicoController.text) ?? 0;
      if (vazaoBico > 0 && largura > 0 && velocidade > 0) {
        final vazaoTotal = bicos * vazaoBico;
        _vazaoTotalController.text = vazaoTotal.toStringAsFixed(2);
        
        final novaCalibr = CalibracaoModel(
          modoCalculo: _modoCalculo,
          bicosAtivos: bicos,
          espacamentoM: espacamento,
          larguraM: largura,
          velocidadeKmh: velocidade,
          vazaoBicoLMin: vazaoBico,
          vazaoTotalLMin: vazaoTotal,
          eficienciaCampo: eficiencia / 100,
        );
        _volumeCalculado = novaCalibr.calcularVolumeTeoricoLHa();
      }
    } else {
      // Modo 2: Informar volume alvo
      // Este cálculo seria feito quando o usuário informar o volume desejado
      // Por enquanto, apenas mostra o campo para vazão necessária
    }

    _salvarCalibracao();
  }

  /// Calcula calibração para aplicação aérea
  void _calcularCalibracaoAerea() {
    final faixa = double.tryParse(_faixaController.text) ?? 0;
    final velocidade = double.tryParse(_velocidadeController.text) ?? 0;
    final vazaoTotal = double.tryParse(_vazaoTotalController.text) ?? 0;
    final eficiencia = double.tryParse(_eficienciaController.text) ?? 85;

    if (faixa > 0 && velocidade > 0 && vazaoTotal > 0) {
      final novaCalibr = CalibracaoModel(
        modoCalculo: _modoCalculo,
        bicosAtivos: 1,
        espacamentoM: faixa,
        larguraM: faixa,
        velocidadeKmh: velocidade,
        vazaoTotalLMin: vazaoTotal,
        eficienciaCampo: eficiencia / 100,
      );
      _volumeCalculado = novaCalibr.calcularVolumeTeoricoLHa();
    }

    _salvarCalibracao();
  }

  /// Calcula calibração para aplicação com drone
  void _calcularCalibracaoDrone() {
    final larguraEfetiva = double.tryParse(_larguraEfetivaController.text) ?? 0;
    final velocidade = double.tryParse(_velocidadeController.text) ?? 0;
    final vazaoTotal = double.tryParse(_vazaoTotalController.text) ?? 0;
    final eficiencia = double.tryParse(_eficienciaController.text) ?? 85;

    if (larguraEfetiva > 0 && velocidade > 0 && vazaoTotal > 0) {
      final novaCalibr = CalibracaoModel(
        modoCalculo: _modoCalculo,
        bicosAtivos: 1,
        espacamentoM: larguraEfetiva,
        larguraM: larguraEfetiva,
        velocidadeKmh: velocidade,
        vazaoTotalLMin: vazaoTotal,
        eficienciaCampo: eficiencia / 100,
      );
      _volumeCalculado = novaCalibr.calcularVolumeTeoricoLHa();
    }

    _salvarCalibracao();
  }

  /// Salva a calibração atual
  void _salvarCalibracao() {
    final calibracao = CalibracaoModel(
      modoCalculo: _modoCalculo,
      bicosAtivos: int.tryParse(_bicosAtivosController.text) ?? 0,
      espacamentoM: double.tryParse(_espacamentoController.text) ?? 0,
      larguraM: double.tryParse(_larguraController.text) ?? 0,
      velocidadeKmh: double.tryParse(_velocidadeController.text) ?? 0,
      pressao: double.tryParse(_pressaoController.text),
      vazaoBicoLMin: double.tryParse(_vazaoBicoController.text),
      vazaoTotalLMin: double.tryParse(_vazaoTotalController.text),
      eficienciaCampo: (double.tryParse(_eficienciaController.text) ?? 85) / 100,
    );

    widget.onCalibracaoChanged(calibracao);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção
          _buildSectionTitle('Calibração do Equipamento'),
          
          const SizedBox(height: 16),

          // Tipo de aplicação
          _buildTipoAplicacaoCard(),
          
          const SizedBox(height: 16),

          // Parâmetros específicos por tipo
          if (widget.tipoAplicacao == 'Terrestre') ...[
            _buildParametrosTerrestre(),
          ] else if (widget.tipoAplicacao == 'Aérea') ...[
            _buildParametrosAerea(),
          ] else if (widget.tipoAplicacao == 'Drone') ...[
            _buildParametrosDrone(),
          ],

          const SizedBox(height: 16),

          // Resultados do cálculo
          if (_volumeCalculado != null) ...[
            _buildResultadosCalculo(),
          ],

          const SizedBox(height: 16),

          // Botão de cálculo
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCalculating ? null : _calcularCalibracao,
              icon: _isCalculating 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate),
              label: Text(_isCalculating ? 'Calculando...' : 'Calcular Calibração'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o título da seção
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói card do tipo de aplicação
  Widget _buildTipoAplicacaoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Aplicação',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTipoOption('Terrestre', Icons.directions_car),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTipoOption('Aérea', Icons.flight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTipoOption('Drone', Icons.flight_takeoff),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói opção de tipo de aplicação
  Widget _buildTipoOption(String tipo, IconData icon) {
    final isSelected = widget.tipoAplicacao == tipo;
    
    return InkWell(
      onTap: () {
        // Nota: O tipo de aplicação é controlado pela tela pai
        // Aqui apenas mostramos visualmente qual está selecionado
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              tipo,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói parâmetros para aplicação terrestre
  Widget _buildParametrosTerrestre() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parâmetros Terrestres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Modo de cálculo
            _buildModoCalculoSelector(),
            
            const SizedBox(height: 16),

            // Parâmetros básicos
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bicosAtivosController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nº Bicos Ativos',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (int.tryParse(value) == null) return 'Digite um número válido';
                      if (int.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _espacamentoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Espaçamento (m)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _larguraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Largura da Barra (m)',
                      border: OutlineInputBorder(),
                      helperText: 'Auto = Nº bicos × espaçamento',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _velocidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Velocidade (km/h)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pressaoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pressão (bar)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _eficienciaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Eficiência (%)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      final val = double.parse(value);
                      if (val <= 0 || val > 100) return 'Deve estar entre 1 e 100';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vazão
            if (_modoCalculo == 'vazao_bico') ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vazaoBicoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vazão por Bico (L/min)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null) return 'Digite um número válido';
                        if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vazaoTotalController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Vazão Total (L/min)',
                        border: OutlineInputBorder(),
                        filled: true,

                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vazaoTotalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vazão Total (L/min)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null) return 'Digite um número válido';
                        if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vazaoBicoController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Vazão por Bico (L/min)',
                        border: OutlineInputBorder(),
                        filled: true,

                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Constrói parâmetros para aplicação aérea
  Widget _buildParametrosAerea() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parâmetros Aéreos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _faixaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Faixa (m)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _velocidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Velocidade (km/h)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _alturaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altura (m)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _vazaoTotalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Vazão Total (L/min)',
                      border: OutlineInputBorder(),
                    ),
                                          validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null) return 'Digite um número válido';
                        if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                        return null;
                      },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _eficienciaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Eficiência (%)',
                border: OutlineInputBorder(),
              ),
                                  validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      final val = double.parse(value);
                      if (val <= 0 || val > 100) return 'Deve estar entre 1 e 100';
                      return null;
                    },
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói parâmetros para aplicação com drone
  Widget _buildParametrosDrone() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parâmetros Drone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _larguraEfetivaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Largura Efetiva (m)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _velocidadeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Velocidade (km/h)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vazaoTotalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Vazão Total (L/min)',
                      border: OutlineInputBorder(),
                    ),
                                          validator: (value) {
                        if (value == null || value.isEmpty) return 'Campo obrigatório';
                        if (double.tryParse(value) == null) return 'Digite um número válido';
                        if (double.parse(value) <= 0) return 'Deve ser maior que zero';
                        return null;
                      },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _eficienciaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Eficiência (%)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null) return 'Digite um número válido';
                      final val = double.parse(value);
                      if (val <= 0 || val > 100) return 'Deve estar entre 1 e 100';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói seletor de modo de cálculo
  Widget _buildModoCalculoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modo de Cálculo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Informar vazão por bico'),
                subtitle: const Text('Calcula volume teórico'),
                value: 'vazao_bico',
                groupValue: _modoCalculo,
                onChanged: (value) {
                  setState(() {
                    _modoCalculo = value!;
                    _volumeCalculado = null;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Informar volume alvo'),
                subtitle: const Text('Calcula vazão necessária'),
                value: 'volume_alvo',
                groupValue: _modoCalculo,
                onChanged: (value) {
                  setState(() {
                    _modoCalculo = value!;
                    _volumeCalculado = null;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói resultados do cálculo
  Widget _buildResultadosCalculo() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Resultados da Calibração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  _buildResultRow('Volume Calculado', '${_volumeCalculado!.toStringAsFixed(1)} L/ha'),
                  if (_vazaoBicoNecessaria != null)
                    _buildResultRow('Vazão por Bico Necessária', '${_vazaoBicoNecessaria!.toStringAsFixed(2)} L/min'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói linha de resultado
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
