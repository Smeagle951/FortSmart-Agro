import 'package:flutter/material.dart';
import '../services/universal_calibration_service.dart';

/// Widget universal para calibração de qualquer máquina agrícola
class UniversalCalibrationWidget extends StatefulWidget {
  const UniversalCalibrationWidget({Key? key}) : super(key: key);

  @override
  _UniversalCalibrationWidgetState createState() => _UniversalCalibrationWidgetState();
}

class _UniversalCalibrationWidgetState extends State<UniversalCalibrationWidget> {
  final _formKey = GlobalKey<FormState>();
  final _tempoController = TextEditingController();
  final _larguraController = TextEditingController();
  final _velocidadeController = TextEditingController();
  final _valorColetadoController = TextEditingController();
  final _taxaDesejadaController = TextEditingController();
  final _aberturaAtualController = TextEditingController();

  String _tipoMaquinaSelecionada = 'personalizada';
  bool _isCalculando = false;
  UniversalCalibrationResult? _resultado;
  Map<String, dynamic>? _validacao;

  @override
  void dispose() {
    _tempoController.dispose();
    _larguraController.dispose();
    _velocidadeController.dispose();
    _valorColetadoController.dispose();
    _taxaDesejadaController.dispose();
    _aberturaAtualController.dispose();
    super.dispose();
  }

  void _calcular() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculando = true;
      _resultado = null;
      _validacao = null;
    });

    try {
      // Validar dados primeiro
      final validacao = UniversalCalibrationService.validarDados(
        tipoMaquina: _tipoMaquinaSelecionada,
        tempoSegundos: double.parse(_tempoController.text),
        larguraFaixa: double.parse(_larguraController.text),
        velocidadeKmh: double.parse(_velocidadeController.text),
        valorColetadoKg: double.parse(_valorColetadoController.text),
        taxaDesejadaKgHa: double.parse(_taxaDesejadaController.text),
      );

      if (!validacao['valido']) {
        setState(() {
          _validacao = validacao;
          _isCalculando = false;
        });
        return;
      }

      // Calcular resultado
      final resultado = UniversalCalibrationService.calcularCalibracao(
        tipoMaquina: _tipoMaquinaSelecionada,
        tempoSegundos: double.parse(_tempoController.text),
        larguraFaixa: double.parse(_larguraController.text),
        velocidadeKmh: double.parse(_velocidadeController.text),
        valorColetadoKg: double.parse(_valorColetadoController.text),
        taxaDesejadaKgHa: double.parse(_taxaDesejadaController.text),
        aberturaAtual: double.tryParse(_aberturaAtualController.text),
      );

      setState(() {
        _resultado = resultado;
        _isCalculando = false;
      });

    } catch (e) {
      setState(() {
        _isCalculando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no cálculo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limparDados() {
    setState(() {
      _tempoController.clear();
      _larguraController.clear();
      _velocidadeController.clear();
      _valorColetadoController.clear();
      _taxaDesejadaController.clear();
      _aberturaAtualController.clear();
      _resultado = null;
      _validacao = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibração Universal'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _limparDados,
            tooltip: 'Limpar dados',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção da máquina
              _buildMachineSelectionCard(),
              const SizedBox(height: 16),
              
              // Entradas principais
              _buildInputsCard(),
              const SizedBox(height: 16),
              
              // Botões de ação
              _buildActionButtons(),
              const SizedBox(height: 16),
              
              // Validação
              if (_validacao != null) _buildValidationCard(),
              
              // Resultados
              if (_resultado != null) _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineSelectionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Seleção da Máquina',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _tipoMaquinaSelecionada,
              decoration: const InputDecoration(
                labelText: 'Tipo de Máquina',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.build),
              ),
              items: UniversalCalibrationService.listarMaquinasDisponiveis().map((maquina) {
                return DropdownMenuItem<String>(
                  value: maquina['tipo'],
                  child: Text(maquina['modelo']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipoMaquinaSelecionada = value!;
                  _preencherDadosPadrao();
                });
              },
            ),
            
            if (_tipoMaquinaSelecionada != 'personalizada') ...[
              const SizedBox(height: 8),
              Text(
                'Dados padrão serão preenchidos automaticamente',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _preencherDadosPadrao() {
    if (_tipoMaquinaSelecionada == 'personalizada') return;
    
    final specs = UniversalCalibrationService.obterInfoTecnica(_tipoMaquinaSelecionada);
    final larguraPadrao = specs['largura_padrao'] as double;
    
    if (larguraPadrao > 0) {
      _larguraController.text = larguraPadrao.toString();
    }
  }

  Widget _buildInputsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Dados da Calibração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tempo
            TextFormField(
              controller: _tempoController,
              decoration: const InputDecoration(
                labelText: 'Tempo (s) *',
                suffixIcon: Icon(Icons.timer),
                border: OutlineInputBorder(),
                helperText: 'Tempo de coleta em segundos',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Tempo obrigatório';
                final tempo = double.tryParse(value);
                if (tempo == null || tempo <= 0) return 'Tempo deve ser > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Largura da faixa
            TextFormField(
              controller: _larguraController,
              decoration: const InputDecoration(
                labelText: 'Largura da Faixa (m) *',
                suffixIcon: Icon(Icons.straighten),
                border: OutlineInputBorder(),
                helperText: 'Largura de trabalho da máquina',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Largura obrigatória';
                final largura = double.tryParse(value);
                if (largura == null || largura <= 0) return 'Largura deve ser > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Velocidade
            TextFormField(
              controller: _velocidadeController,
              decoration: const InputDecoration(
                labelText: 'Velocidade (km/h) *',
                suffixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
                helperText: 'Velocidade de trabalho',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Velocidade obrigatória';
                final velocidade = double.tryParse(value);
                if (velocidade == null || velocidade <= 0) return 'Velocidade deve ser > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Valor coletado
            TextFormField(
              controller: _valorColetadoController,
              decoration: const InputDecoration(
                labelText: 'Valor coletado (kg) *',
                suffixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
                helperText: 'Peso real coletado durante o teste',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Valor coletado obrigatório';
                final valor = double.tryParse(value);
                if (valor == null || valor <= 0) return 'Valor deve ser > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Taxa desejada
            TextFormField(
              controller: _taxaDesejadaController,
              decoration: const InputDecoration(
                labelText: 'Taxa desejada (kg/ha) *',
                suffixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
                helperText: 'Taxa de aplicação desejada',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Taxa desejada obrigatória';
                final taxa = double.tryParse(value);
                if (taxa == null || taxa <= 0) return 'Taxa deve ser > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Abertura atual (opcional)
            TextFormField(
              controller: _aberturaAtualController,
              decoration: const InputDecoration(
                labelText: 'Abertura atual (%)',
                suffixIcon: Icon(Icons.tune),
                border: OutlineInputBorder(),
                helperText: 'Opcional - para cálculo de ajuste',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resultado != null ? _salvar : null,
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValidationCard() {
    final alertas = _validacao!['alertas'] as List<String>;
    final avisos = _validacao!['avisos'] as List<String>;
    
    return Card(
      color: alertas.isNotEmpty ? Colors.red[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alertas.isNotEmpty ? Icons.error : Icons.warning,
                  color: alertas.isNotEmpty ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  alertas.isNotEmpty ? 'Dados Inválidos' : 'Avisos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: alertas.isNotEmpty ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (alertas.isNotEmpty) ...[
              ...alertas.map((alerta) => Text('• $alerta', style: const TextStyle(color: Colors.red))),
            ],
            if (avisos.isNotEmpty) ...[
              ...avisos.map((aviso) => Text('• $aviso', style: const TextStyle(color: Colors.orange))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    if (_resultado == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Resultados da Calibração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Máquina: ${_resultado!.modeloMaquina}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            
            // Métricas calculadas
            _buildMetricRow('Distância', '${_resultado!.distanciaPercorrida} m', Icons.straighten),
            _buildMetricRow('Área', '${_resultado!.areaCoberta} m²', Icons.crop_square),
            _buildMetricRow('Área', '${_resultado!.areaHectares} ha', Icons.crop_square),
            
            const SizedBox(height: 16),
            
            // Taxa aplicada
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _resultado!.precisaRecalibrar ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _resultado!.precisaRecalibrar ? Colors.red : Colors.green,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Taxa aplicada (kg/ha)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _resultado!.precisaRecalibrar ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_resultado!.taxaRealAplicada} kg/ha',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _resultado!.precisaRecalibrar ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _resultado!.precisaRecalibrar ? Icons.error : Icons.check_circle,
                        color: _resultado!.precisaRecalibrar ? Colors.red : Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _resultado!.statusTolerancia,
                        style: TextStyle(
                          color: _resultado!.precisaRecalibrar ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recomendação de ajuste
            if (_resultado!.precisaRecalibrar) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recomendação de Ajuste',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_resultado!.recomendacaoAjuste),
                    const SizedBox(height: 4),
                    Text(
                      'Abertura sugerida: ${_resultado!.aberturaSugerida}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: '),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _salvar() {
    // Implementar salvamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calibração salva com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
