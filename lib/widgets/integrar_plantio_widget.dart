import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/experimento_completo_model.dart';
import '../services/experimento_plantio_integration_service.dart';
import '../utils/snackbar_utils.dart';

/// Widget para integrar subárea com módulo de plantio
class IntegrarPlantioWidget extends StatefulWidget {
  final SubareaCompleta subarea;

  const IntegrarPlantioWidget({
    Key? key,
    required this.subarea,
  }) : super(key: key);

  @override
  State<IntegrarPlantioWidget> createState() => _IntegrarPlantioWidgetState();
}

class _IntegrarPlantioWidgetState extends State<IntegrarPlantioWidget> {
  final ExperimentoPlantioIntegrationService _integrationService = 
      ExperimentoPlantioIntegrationService();
  
  final _formKey = GlobalKey<FormState>();
  final _culturaController = TextEditingController();
  final _variedadeController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _espacamentoController = TextEditingController(text: '45.0');
  final _populacaoController = TextEditingController(text: '12.0');

  DateTime _dataPlantio = DateTime.now();
  String? _variedadeTipo;
  String? _cicloNome;
  int? _cicloDias;
  String? _cicloDescricao;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosExistentes();
  }

  @override
  void dispose() {
    _culturaController.dispose();
    _variedadeController.dispose();
    _observacoesController.dispose();
    _espacamentoController.dispose();
    _populacaoController.dispose();
    super.dispose();
  }

  void _carregarDadosExistentes() {
    if (widget.subarea.cultura != null) {
      _culturaController.text = widget.subarea.cultura!;
    }
    if (widget.subarea.variedade != null) {
      _variedadeController.text = widget.subarea.variedade!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Integrar com Plantio'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card da Subárea
              _buildSubareaCard(),
              
              const SizedBox(height: 20),
              
              // Card de Informações do Plantio
              _buildPlantioCard(),
              
              const SizedBox(height: 20),
              
              // Card de Variedade e Ciclo
              _buildVariedadeCicloCard(),
              
              const SizedBox(height: 20),
              
              // Botões de Ação
              _buildActionButtons(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubareaCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.subarea.cor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subarea.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.subarea.tipo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.subarea.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.subarea.statusText,
                    style: TextStyle(
                      color: widget.subarea.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Área',
                    widget.subarea.areaFormatada,
                    Icons.crop_square,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Perímetro',
                    '${widget.subarea.perimetro.toStringAsFixed(0)}m',
                    Icons.straighten,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantioCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'Informações do Plantio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Cultura
            TextFormField(
              controller: _culturaController,
              decoration: const InputDecoration(
                labelText: 'Cultura *',
                hintText: 'Ex: Soja',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Cultura é obrigatória';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Variedade
            TextFormField(
              controller: _variedadeController,
              decoration: const InputDecoration(
                labelText: 'Variedade *',
                hintText: 'Ex: RR 60.51',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Variedade é obrigatória';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Data de Plantio
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.orange[700]),
              title: const Text('Data de Plantio'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dataPlantio)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selecionarDataPlantio,
            ),
            
            const SizedBox(height: 16),
            
            // Espacamento e População
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _espacamentoController,
                    decoration: const InputDecoration(
                      labelText: 'Espaçamento (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obrigatório';
                      }
                      final valor = double.tryParse(value);
                      if (valor == null || valor <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _populacaoController,
                    decoration: const InputDecoration(
                      labelText: 'População/m',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obrigatório';
                      }
                      final valor = double.tryParse(value);
                      if (valor == null || valor <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Observações
            TextFormField(
              controller: _observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Observações adicionais sobre o plantio...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariedadeCicloCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  'Variedade e Ciclo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tipo de Variedade
            DropdownButtonFormField<String>(
              value: _variedadeTipo,
              decoration: const InputDecoration(
                labelText: 'Tipo da Variedade',
                hintText: 'Ex: RR, Intacta, etc.',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'RR', child: Text('RR')),
                DropdownMenuItem(value: 'Intacta', child: Text('Intacta')),
                DropdownMenuItem(value: 'Convencional', child: Text('Convencional')),
                DropdownMenuItem(value: 'Outros', child: Text('Outros')),
              ],
              onChanged: (value) {
                setState(() {
                  _variedadeTipo = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Ciclo
            DropdownButtonFormField<String>(
              value: _cicloNome,
              decoration: const InputDecoration(
                labelText: 'Ciclo',
                hintText: 'Ex: Precoce, Médio, etc.',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Precoce', child: Text('Precoce (90-105 dias)')),
                DropdownMenuItem(value: 'Médio Precoce', child: Text('Médio Precoce (105-120 dias)')),
                DropdownMenuItem(value: 'Médio', child: Text('Médio (120-135 dias)')),
                DropdownMenuItem(value: 'Médio Tardio', child: Text('Médio Tardio (135-150 dias)')),
                DropdownMenuItem(value: 'Tardio', child: Text('Tardio (150+ dias)')),
              ],
              onChanged: (value) {
                setState(() {
                  _cicloNome = value;
                  // Definir dias automaticamente
                  switch (value) {
                    case 'Precoce':
                      _cicloDias = 105;
                      _cicloDescricao = 'Variedade de ciclo precoce, ideal para escape de pragas e doenças';
                      break;
                    case 'Médio Precoce':
                      _cicloDias = 120;
                      _cicloDescricao = 'Variedade de ciclo médio precoce, boa produtividade com menor risco';
                      break;
                    case 'Médio':
                      _cicloDias = 135;
                      _cicloDescricao = 'Variedade de ciclo médio, alta produtividade potencial';
                      break;
                    case 'Médio Tardio':
                      _cicloDias = 145;
                      _cicloDescricao = 'Variedade de ciclo médio tardio, máxima produtividade';
                      break;
                    case 'Tardio':
                      _cicloDias = 160;
                      _cicloDescricao = 'Variedade de ciclo tardio, máxima produtividade e qualidade';
                      break;
                  }
                });
              },
            ),
            
            if (_cicloDias != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_cicloDias dias de ciclo',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_cicloDescricao != null)
                            Text(
                              _cicloDescricao!,
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _integrarComPlantio,
            icon: _isLoading 
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.agriculture, size: 18),
            label: Text(_isLoading ? 'Integrando...' : 'Integrar Plantio'),
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

  Future<void> _selecionarDataPlantio() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dataPlantio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (result != null) {
      setState(() {
        _dataPlantio = result;
      });
    }
  }

  Future<void> _integrarComPlantio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _integrationService.integrarSubareaComPlantio(
        subareaId: widget.subarea.id,
        cultura: _culturaController.text.trim(),
        variedade: _variedadeController.text.trim(),
        dataPlantio: _dataPlantio,
        espacamentoCm: double.parse(_espacamentoController.text),
        populacaoPorM: double.parse(_populacaoController.text),
        observacoes: _observacoesController.text.trim().isEmpty 
            ? null 
            : _observacoesController.text.trim(),
        variedadeTipo: _variedadeTipo,
        cicloNome: _cicloNome,
        cicloDias: _cicloDias,
        cicloDescricao: _cicloDescricao,
      );

      SnackbarUtils.showSuccessSnackBar(
        context, 
        'Subárea integrada com plantio com sucesso!'
      );
      
      Navigator.of(context).pop(true);
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao integrar com plantio: $e'
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
