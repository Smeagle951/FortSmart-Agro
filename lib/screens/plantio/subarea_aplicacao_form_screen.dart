import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/subarea_model.dart';
import '../../database/models/aplicacao_model.dart';

/// Tela de formulário para criar/editar aplicações
class SubareaAplicacaoFormScreen extends StatefulWidget {
  final SubareaModel subarea;
  final AplicacaoModel? aplicacao;

  const SubareaAplicacaoFormScreen({
    Key? key,
    required this.subarea,
    this.aplicacao,
  }) : super(key: key);

  @override
  State<SubareaAplicacaoFormScreen> createState() => _SubareaAplicacaoFormScreenState();
}

class _SubareaAplicacaoFormScreenState extends State<SubareaAplicacaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _principioAtivoController = TextEditingController();
  final TextEditingController _dosagemController = TextEditingController();
  final TextEditingController _volumeCaldaController = TextEditingController();
  final TextEditingController _equipamentoController = TextEditingController();
  final TextEditingController _temperaturaController = TextEditingController();
  final TextEditingController _umidadeController = TextEditingController();
  final TextEditingController _ventoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _crmController = TextEditingController();

  // Variáveis de estado
  DateTime _dataAplicacao = DateTime.now();
  String _tipoAplicacao = 'fertilizante';
  String _unidadeDosagem = 'kg/ha';
  String _condicoesTempo = 'ensolarado';

  // Opções para dropdowns
  final List<String> _tiposAplicacao = [
    'fertilizante',
    'defensivo',
    'corretivo',
    'outros',
  ];

  final List<String> _unidadesDosagem = [
    'kg/ha',
    'L/ha',
    'mL/ha',
    'g/ha',
  ];

  final List<String> _condicoesTempoOptions = [
    'ensolarado',
    'nublado',
    'chuvoso',
    'vento',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.aplicacao != null) {
      _loadAplicacaoData();
    } else {
      _loadDefaultData();
    }
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _principioAtivoController.dispose();
    _dosagemController.dispose();
    _volumeCaldaController.dispose();
    _equipamentoController.dispose();
    _temperaturaController.dispose();
    _umidadeController.dispose();
    _ventoController.dispose();
    _observacoesController.dispose();
    _responsavelController.dispose();
    _crmController.dispose();
    super.dispose();
  }

  void _loadAplicacaoData() {
    final aplicacao = widget.aplicacao!;
    _produtoController.text = aplicacao.produto;
    _principioAtivoController.text = aplicacao.principioAtivo;
    _dosagemController.text = aplicacao.dosagem.toString();
    _volumeCaldaController.text = aplicacao.volumeCalda.toString();
    _equipamentoController.text = aplicacao.equipamento;
    _temperaturaController.text = aplicacao.temperatura.toString();
    _umidadeController.text = aplicacao.umidadeRelativa.toString();
    _ventoController.text = aplicacao.velocidadeVento.toString();
    _observacoesController.text = aplicacao.observacoes;
    _responsavelController.text = aplicacao.responsavelTecnico;
    _crmController.text = aplicacao.crmResponsavel;
    
    setState(() {
      _dataAplicacao = aplicacao.dataAplicacao;
      _tipoAplicacao = aplicacao.tipoAplicacao;
      _unidadeDosagem = aplicacao.unidadeDosagem;
      _condicoesTempo = aplicacao.condicoesTempo;
    });
  }

  void _loadDefaultData() {
    _equipamentoController.text = 'Pulverizador costal';
    _temperaturaController.text = '25';
    _umidadeController.text = '70';
    _ventoController.text = '5';
    _responsavelController.text = 'João Silva';
    _crmController.text = 'SP-12345';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataAplicacao,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataAplicacao),
      );
      
      if (time != null) {
        setState(() {
          _dataAplicacao = DateTime(
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

  Future<void> _saveAplicacao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final aplicacao = widget.aplicacao != null
          ? widget.aplicacao!.copyWith(
              dataAplicacao: _dataAplicacao,
              tipoAplicacao: _tipoAplicacao,
              produto: _produtoController.text,
              principioAtivo: _principioAtivoController.text,
              dosagem: double.tryParse(_dosagemController.text) ?? 0.0,
              unidadeDosagem: _unidadeDosagem,
              volumeCalda: double.tryParse(_volumeCaldaController.text) ?? 0.0,
              equipamento: _equipamentoController.text,
              condicoesTempo: _condicoesTempo,
              temperatura: double.tryParse(_temperaturaController.text) ?? 0.0,
              umidadeRelativa: double.tryParse(_umidadeController.text) ?? 0.0,
              velocidadeVento: double.tryParse(_ventoController.text) ?? 0.0,
              observacoes: _observacoesController.text,
              responsavelTecnico: _responsavelController.text,
              crmResponsavel: _crmController.text,
              updatedAt: DateTime.now(),
            )
          : AplicacaoModel.create(
              subareaId: widget.subarea.id,
              experimentoId: widget.subarea.experimentoId,
              dataAplicacao: _dataAplicacao,
              tipoAplicacao: _tipoAplicacao,
              produto: _produtoController.text,
              principioAtivo: _principioAtivoController.text,
              dosagem: double.tryParse(_dosagemController.text) ?? 0.0,
              unidadeDosagem: _unidadeDosagem,
              volumeCalda: double.tryParse(_volumeCaldaController.text) ?? 0.0,
              equipamento: _equipamentoController.text,
              condicoesTempo: _condicoesTempo,
              temperatura: double.tryParse(_temperaturaController.text) ?? 0.0,
              umidadeRelativa: double.tryParse(_umidadeController.text) ?? 0.0,
              velocidadeVento: double.tryParse(_ventoController.text) ?? 0.0,
              observacoes: _observacoesController.text,
              responsavelTecnico: _responsavelController.text,
              crmResponsavel: _crmController.text,
            );

      // TODO: Implementar salvamento real no banco
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      SnackbarUtils.showSuccessSnackBar(
        context,
        widget.aplicacao != null ? 'Aplicação atualizada!' : 'Aplicação criada!',
      );

      Navigator.pop(context, aplicacao);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar aplicação: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aplicacao != null ? 'Editar Aplicação' : 'Nova Aplicação'),
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
              onPressed: _saveAplicacao,
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
                    Text('Área: ${NumberFormat("#,##0.00", "pt_BR").format(widget.subarea.areaHa)} ha'),
                    Text('Cultura: ${widget.subarea.cultura ?? 'Não informado'}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data e hora da aplicação
              Text(
                'Data e Hora da Aplicação',
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
                        DateFormat('dd/MM/yyyy HH:mm').format(_dataAplicacao),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tipo de aplicação
              _buildDropdownField(
                label: 'Tipo de Aplicação',
                value: _tipoAplicacao,
                items: _tiposAplicacao,
                onChanged: (value) => setState(() => _tipoAplicacao = value!),
                icon: Icons.category,
              ),
              const SizedBox(height: 16),

              // Produto e princípio ativo
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Produto',
                      controller: _produtoController,
                      icon: Icons.agriculture,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Produto é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Princípio Ativo',
                      controller: _principioAtivoController,
                      icon: Icons.science,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Princípio ativo é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dosagem e unidade
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'Dosagem',
                      controller: _dosagemController,
                      icon: Icons.scale,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Dosagem é obrigatória';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Dosagem deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Unidade',
                      value: _unidadeDosagem,
                      items: _unidadesDosagem,
                      onChanged: (value) => setState(() => _unidadeDosagem = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Volume de calda e equipamento
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Volume de Calda (L/ha)',
                      controller: _volumeCaldaController,
                      icon: Icons.water_drop,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Volume é obrigatório';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Volume deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Equipamento',
                      controller: _equipamentoController,
                      icon: Icons.build,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Equipamento é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Condições ambientais
              Text(
                'Condições Ambientais',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Condições do Tempo',
                value: _condicoesTempo,
                items: _condicoesTempoOptions,
                onChanged: (value) => setState(() => _condicoesTempo = value!),
                icon: Icons.wb_sunny,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Temperatura (°C)',
                      controller: _temperaturaController,
                      icon: Icons.thermostat,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Temperatura é obrigatória';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Temperatura deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Umidade (%)',
                      controller: _umidadeController,
                      icon: Icons.water,
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
                      label: 'Vento (km/h)',
                      controller: _ventoController,
                      icon: Icons.air,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Velocidade do vento é obrigatória';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Velocidade deve ser um número';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Responsável técnico
              Text(
                'Responsável Técnico',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      label: 'Nome do Responsável',
                      controller: _responsavelController,
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'CRM',
                      controller: _crmController,
                      icon: Icons.badge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CRM é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
                  onPressed: _isLoading ? null : _saveAplicacao,
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
                          widget.aplicacao != null ? 'ATUALIZAR APLICAÇÃO' : 'SALVAR APLICAÇÃO',
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
