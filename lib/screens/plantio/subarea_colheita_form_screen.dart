import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/subarea_model.dart';
import '../../database/models/colheita_model.dart';
import '../../database/repositories/colheita_repository.dart';

/// Tela de formulário para criar/editar colheitas
class SubareaColheitaFormScreen extends StatefulWidget {
  final SubareaModel subarea;
  final ColheitaModel? colheita;

  const SubareaColheitaFormScreen({
    Key? key,
    required this.subarea,
    this.colheita,
  }) : super(key: key);

  @override
  State<SubareaColheitaFormScreen> createState() => _SubareaColheitaFormScreenState();
}

class _SubareaColheitaFormScreenState extends State<SubareaColheitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ColheitaRepository _repository = ColheitaRepository();

  // Controllers
  final TextEditingController _areaColhidaController = TextEditingController();
  final TextEditingController _producaoTotalController = TextEditingController();
  final TextEditingController _umidadeController = TextEditingController();
  final TextEditingController _impurezasController = TextEditingController();
  final TextEditingController _danosController = TextEditingController();
  final TextEditingController _equipamentoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();

  // Variáveis de estado
  DateTime _dataColheita = DateTime.now();
  String _tipoColheita = 'mecanizada';
  String _unidadeProducao = 'kg';
  String _qualidade = 'boa';

  // Opções para dropdowns
  final List<String> _tiposColheita = [
    'manual',
    'mecanizada',
    'seletiva',
  ];

  final List<String> _unidadesProducao = [
    'kg',
    'toneladas',
  ];

  final List<String> _qualidades = [
    'excelente',
    'boa',
    'regular',
    'ruim',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.colheita != null) {
      _loadColheitaData();
    } else {
      _loadDefaultData();
    }
  }

  @override
  void dispose() {
    _areaColhidaController.dispose();
    _producaoTotalController.dispose();
    _umidadeController.dispose();
    _impurezasController.dispose();
    _danosController.dispose();
    _equipamentoController.dispose();
    _observacoesController.dispose();
    _responsavelController.dispose();
    super.dispose();
  }

  void _loadColheitaData() {
    final colheita = widget.colheita!;
    _areaColhidaController.text = colheita.areaColhida.toString();
    _producaoTotalController.text = colheita.producaoTotal.toString();
    _umidadeController.text = colheita.umidade.toString();
    _impurezasController.text = colheita.impurezas.toString();
    _danosController.text = colheita.danos.toString();
    _equipamentoController.text = colheita.equipamento;
    _observacoesController.text = colheita.observacoes;
    _responsavelController.text = colheita.responsavelColheita;
    
    setState(() {
      _dataColheita = colheita.dataColheita;
      _tipoColheita = colheita.tipoColheita;
      _unidadeProducao = colheita.unidadeProducao;
      _qualidade = colheita.qualidade;
    });
  }

  void _loadDefaultData() {
    _areaColhidaController.text = widget.subarea.areaHa.toString();
    _umidadeController.text = '14.0';
    _impurezasController.text = '2.0';
    _danosController.text = '1.5';
    _equipamentoController.text = 'Colheitadeira';
    _responsavelController.text = 'João Silva';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataColheita,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataColheita),
      );
      
      if (time != null) {
        setState(() {
          _dataColheita = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      decoration: FortSmartTheme.createInputDecoration(
        label,
        prefixIcon: icon,
      ),
      value: value,
      items: items.map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item.toUpperCase()),
      )).toList(),
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: FortSmartTheme.createInputDecoration(
        label,
        prefixIcon: icon,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  double _calculateProdutividade() {
    final area = double.tryParse(_areaColhidaController.text) ?? 0.0;
    final producao = double.tryParse(_producaoTotalController.text) ?? 0.0;
    
    if (area > 0 && producao > 0) {
      return producao / area;
    }
    return 0.0;
  }

  Future<void> _saveColheita() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final produtividade = _calculateProdutividade();
      final unidadeProdutividade = _unidadeProducao == 'kg' ? 'kg/ha' : 'toneladas/ha';
      
      final colheita = widget.colheita != null
          ? widget.colheita!.copyWith(
              dataColheita: _dataColheita,
              tipoColheita: _tipoColheita,
              areaColhida: double.tryParse(_areaColhidaController.text) ?? 0.0,
              producaoTotal: double.tryParse(_producaoTotalController.text) ?? 0.0,
              unidadeProducao: _unidadeProducao,
              produtividade: produtividade,
              unidadeProdutividade: unidadeProdutividade,
              qualidade: _qualidade,
              umidade: double.tryParse(_umidadeController.text) ?? 0.0,
              impurezas: double.tryParse(_impurezasController.text) ?? 0.0,
              danos: double.tryParse(_danosController.text) ?? 0.0,
              equipamento: _equipamentoController.text,
              observacoes: _observacoesController.text,
              responsavelColheita: _responsavelController.text,
              updatedAt: DateTime.now(),
            )
          : ColheitaModel.create(
              subareaId: widget.subarea.id,
              experimentoId: widget.subarea.experimentoId,
              dataColheita: _dataColheita,
              tipoColheita: _tipoColheita,
              areaColhida: double.tryParse(_areaColhidaController.text) ?? 0.0,
              producaoTotal: double.tryParse(_producaoTotalController.text) ?? 0.0,
              unidadeProducao: _unidadeProducao,
              produtividade: produtividade,
              unidadeProdutividade: unidadeProdutividade,
              qualidade: _qualidade,
              umidade: double.tryParse(_umidadeController.text) ?? 0.0,
              impurezas: double.tryParse(_impurezasController.text) ?? 0.0,
              danos: double.tryParse(_danosController.text) ?? 0.0,
              equipamento: _equipamentoController.text,
              observacoes: _observacoesController.text,
              responsavelColheita: _responsavelController.text,
            );

      // Salvar no banco de dados
      if (widget.colheita != null) {
        await _repository.update(colheita);
      } else {
        await _repository.insert(colheita);
      }

      setState(() {
        _isLoading = false;
      });

      SnackbarUtils.showSuccessSnackBar(
        context,
        widget.colheita != null ? 'Colheita atualizada!' : 'Colheita criada!',
      );

      Navigator.pop(context, colheita);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar colheita: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.colheita != null ? 'Editar Colheita' : 'Nova Colheita'),
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
              onPressed: _saveColheita,
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
              // Informações da subárea
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
                      'Subárea: ${widget.subarea.nome}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Área Total: ${NumberFormat("#,##0.00", "pt_BR").format(widget.subarea.areaHa)} ha'),
                    Text('Cultura: ${widget.subarea.cultura ?? 'Não informado'}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data e hora da colheita
              Text(
                'Data e Hora da Colheita',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: FortSmartTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(_dataColheita),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de colheita
              _buildDropdownField(
                label: 'Tipo de Colheita',
                value: _tipoColheita,
                items: _tiposColheita,
                onChanged: (value) => setState(() => _tipoColheita = value!),
                icon: Icons.agriculture,
              ),
              const SizedBox(height: 16),

              // Área colhida e produção
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Área Colhida (ha)',
                      controller: _areaColhidaController,
                      icon: Icons.area_chart,
                      keyboardType: TextInputType.number,
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
                    flex: 2,
                    child: _buildTextField(
                      label: 'Produção Total',
                      controller: _producaoTotalController,
                      icon: Icons.scale,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Produção é obrigatória';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Produção deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Unidade',
                      value: _unidadeProducao,
                      items: _unidadesProducao,
                      onChanged: (value) => setState(() => _unidadeProducao = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Produtividade calculada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Produtividade Calculada',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${NumberFormat("#,##0.0", "pt_BR").format(_calculateProdutividade())} ${_unidadeProducao == 'kg' ? 'kg/ha' : 'toneladas/ha'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Qualidade e análises
              Text(
                'Qualidade e Análises',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Qualidade',
                value: _qualidade,
                items: _qualidades,
                onChanged: (value) => setState(() => _qualidade = value!),
                icon: Icons.star,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Umidade (%)',
                      controller: _umidadeController,
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Umidade é obrigatória';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Umidade deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Impurezas (%)',
                      controller: _impurezasController,
                      icon: Icons.cleaning_services,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Impurezas são obrigatórias';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Impurezas devem ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Danos (%)',
                      controller: _danosController,
                      icon: Icons.warning,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Danos são obrigatórios';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Danos devem ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Equipamento e responsável
              Text(
                'Equipamento e Responsável',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Equipamento Utilizado',
                controller: _equipamentoController,
                icon: Icons.build,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Equipamento é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Responsável pela Colheita',
                controller: _responsavelController,
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Responsável é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

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
                  onPressed: _isLoading ? null : _saveColheita,
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
                          widget.colheita != null ? 'ATUALIZAR COLHEITA' : 'SALVAR COLHEITA',
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
