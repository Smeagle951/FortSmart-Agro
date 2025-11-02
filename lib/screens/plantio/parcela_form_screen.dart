import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/experimento_model.dart';
import '../../database/models/tratamento_model.dart';
import '../../database/models/parcela_model.dart';

/// Tela de formulário para criar/editar parcelas
class ParcelaFormScreen extends StatefulWidget {
  final ExperimentoModel experimento;
  final List<TratamentoModel> tratamentos;
  final ParcelaModel? parcela;

  const ParcelaFormScreen({
    Key? key,
    required this.experimento,
    required this.tratamentos,
    this.parcela,
  }) : super(key: key);

  @override
  State<ParcelaFormScreen> createState() => _ParcelaFormScreenState();
}

class _ParcelaFormScreenState extends State<ParcelaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // Variáveis de estado
  String? _tratamentoId;
  int _numeroRepeticao = 1;
  String _status = 'planejada';
  List<LatLng> _pontos = [];

  @override
  void initState() {
    super.initState();
    if (widget.parcela != null) {
      _loadParcelaData();
    } else {
      _loadDefaultData();
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _areaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _loadParcelaData() {
    final parcela = widget.parcela!;
    _codigoController.text = parcela.codigo;
    _areaController.text = parcela.area.toString();
    _observacoesController.text = parcela.observacoes;
    
    setState(() {
      _tratamentoId = parcela.tratamentoId;
      _numeroRepeticao = parcela.numeroRepeticao;
      _status = parcela.status;
      _pontos = List.from(parcela.pontos);
    });
  }

  void _loadDefaultData() {
    _codigoController.text = '';
    _areaController.text = '';
    _numeroRepeticao = 1;
    _status = 'planejada';
    _pontos = [];
  }

  List<LatLng> _generateMockPolygon() {
    // Gerar polígono mock para demonstração
    final baseLat = -20.2764 + (widget.experimento.totalParcelas * 0.001);
    final baseLng = -40.3000 + (widget.experimento.totalParcelas * 0.001);
    
    return [
      LatLng(baseLat, baseLng),
      LatLng(baseLat + 0.001, baseLng),
      LatLng(baseLat + 0.001, baseLng + 0.001),
      LatLng(baseLat, baseLng + 0.001),
    ];
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      decoration: FortSmartTheme.createInputDecoration(
        label,
        prefixIcon: icon,
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione $label';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: FortSmartTheme.createInputDecoration(
        label,
        hintText: hintText,
        prefixIcon: icon,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildPontosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordenadas da Parcela',
          style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Pontos do Polígono',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_pontos.length} pontos',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_pontos.isNotEmpty) ...[
                ...List.generate(_pontos.length, (index) {
                  final ponto = _pontos[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'P${index + 1}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text('${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}'),
                      ],
                    ),
                  );
                }),
              ] else ...[
                const Text(
                  'Nenhum ponto definido',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _adicionarPonto,
                      icon: const Icon(Icons.add_location),
                      label: const Text('Adicionar Ponto'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pontos.isNotEmpty ? _limparPontos : null,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _adicionarPonto() {
    // Simular adição de ponto (em produção, seria através de mapa)
    final novoPonto = LatLng(
      -20.2764 + (_pontos.length * 0.0001),
      -40.3000 + (_pontos.length * 0.0001),
    );
    
    setState(() {
      _pontos.add(novoPonto);
    });
    
    SnackbarUtils.showInfoSnackBar(context, 'Ponto adicionado (demo)');
  }

  void _limparPontos() {
    setState(() {
      _pontos.clear();
    });
    SnackbarUtils.showInfoSnackBar(context, 'Pontos limpos');
  }

  Future<void> _saveParcela() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pontos.length < 3) {
      SnackbarUtils.showErrorSnackBar(context, 'A parcela deve ter pelo menos 3 pontos');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tratamentoSelecionado = widget.tratamentos.firstWhere(
        (t) => t.id == _tratamentoId,
      );

      final parcela = widget.parcela != null
          ? widget.parcela!.copyWith(
              codigo: _codigoController.text,
              area: double.tryParse(_areaController.text) ?? 0.0,
              status: _status,
              numeroRepeticao: _numeroRepeticao,
              pontos: _pontos,
              observacoes: _observacoesController.text,
              updatedAt: DateTime.now(),
            )
          : ParcelaModel.create(
              experimentoId: widget.experimento.id,
              tratamentoId: tratamentoSelecionado.id,
              subareaId: 'subarea_${_codigoController.text}',
              codigo: _codigoController.text,
              numeroRepeticao: _numeroRepeticao,
              numeroTratamento: widget.tratamentos.indexOf(tratamentoSelecionado) + 1,
              area: double.tryParse(_areaController.text) ?? 0.0,
              pontos: _pontos,
              status: _status,
              observacoes: _observacoesController.text,
            );

      // TODO: Implementar salvamento real no banco
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      SnackbarUtils.showSuccessSnackBar(
        context,
        widget.parcela != null ? 'Parcela atualizada!' : 'Parcela criada!',
      );

      Navigator.pop(context, parcela);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar parcela: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parcela != null ? 'Editar Parcela' : 'Nova Parcela'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveParcela,
              child: const Text(
                'SALVAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações do experimento
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FortSmartTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FortSmartTheme.primaryColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Experimento: ${widget.experimento.nome}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Delineamento: ${widget.experimento.delineamento.replaceAll('_', ' ').toUpperCase()}'),
                    Text('Total de Parcelas: ${widget.experimento.totalParcelas}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informações básicas
              Text(
                'Informações Básicas',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Código da Parcela',
                controller: _codigoController,
                icon: Icons.tag,
                hintText: 'Ex: P1, P2, P3...',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Código é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Tratamento',
                      value: _tratamentoId,
                      items: widget.tratamentos.map((tratamento) => DropdownMenuItem<String>(
                        value: tratamento.id,
                        child: Text('${tratamento.codigo}: ${tratamento.nome}'),
                      )).toList(),
                      onChanged: (value) => setState(() => _tratamentoId = value),
                      icon: Icons.science,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: FortSmartTheme.createInputDecoration(
                        'Repetição',
                        prefixIcon: Icons.repeat,
                      ),
                      value: _numeroRepeticao,
                      items: List.generate(widget.experimento.numeroRepeticoes, (index) => index + 1)
                          .map((i) => DropdownMenuItem<int>(
                                value: i,
                                child: Text('Repetição $i'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _numeroRepeticao = value!),
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione a repetição';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Área (hectares)',
                      controller: _areaController,
                      icon: Icons.area_chart,
                      keyboardType: TextInputType.number,
                      hintText: 'Ex: 0.5',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Área é obrigatória';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Área deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Status',
                      value: _status,
                      items: ['planejada', 'plantada', 'em_avaliacao', 'colhida']
                          .map((status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(status.replaceAll('_', ' ').toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _status = value!),
                      icon: Icons.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Coordenadas da parcela
              _buildPontosSection(),
              const SizedBox(height: 24),

              // Observações
              _buildTextField(
                label: 'Observações',
                controller: _observacoesController,
                icon: Icons.note,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveParcela,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FortSmartTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.parcela != null ? 'ATUALIZAR PARCELA' : 'CRIAR PARCELA',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
