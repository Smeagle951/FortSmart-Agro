import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/experimento_model.dart';
import '../../database/repositories/experimento_repository.dart';

/// Tela de formulário para criar/editar experimentos
class ExperimentoFormScreen extends StatefulWidget {
  final ExperimentoModel? experimento;

  const ExperimentoFormScreen({
    Key? key,
    this.experimento,
  }) : super(key: key);

  @override
  State<ExperimentoFormScreen> createState() => _ExperimentoFormScreenState();
}

class _ExperimentoFormScreenState extends State<ExperimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ExperimentoRepository _repository = ExperimentoRepository();

  // Controllers
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _objetivoController = TextEditingController();
  final TextEditingController _culturaController = TextEditingController();
  final TextEditingController _variedadeController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _crmController = TextEditingController();
  final TextEditingController _instituicaoController = TextEditingController();
  final TextEditingController _protocoloController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  final TextEditingController _repeticoesController = TextEditingController();
  final TextEditingController _tratamentosController = TextEditingController();

  // Variáveis de estado
  DateTime _dataInicio = DateTime.now();
  String _delineamento = 'blocos_casualizados';
  String _status = 'planejado';
  List<String> _variaveisResposta = ['produtividade'];
  List<String> _variaveisAmbientais = ['temperatura', 'umidade'];

  // Opções para dropdowns
  final List<String> _delineamentos = [
    'blocos_casualizados',
    'parcelas_subdivididas',
    'fatorial',
    'completamente_casualizado',
    'quadrado_latino',
    'outros',
  ];

  final List<String> _statusOptions = [
    'planejado',
    'em_andamento',
    'finalizado',
    'cancelado',
  ];

  final List<String> _variaveisRespostaOptions = [
    'produtividade',
    'qualidade',
    'incidencia_doencas',
    'incidencia_pragas',
    'altura_plantas',
    'diametro_caule',
    'peso_sementes',
    'germinacao',
    'vigor',
  ];

  final List<String> _variaveisAmbientaisOptions = [
    'temperatura',
    'umidade',
    'precipitacao',
    'vento',
    'radiacao_solar',
    'ph_solo',
    'materia_organica',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.experimento != null) {
      _loadExperimentoData();
    } else {
      _loadDefaultData();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _objetivoController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _responsavelController.dispose();
    _crmController.dispose();
    _instituicaoController.dispose();
    _protocoloController.dispose();
    _observacoesController.dispose();
    _repeticoesController.dispose();
    _tratamentosController.dispose();
    super.dispose();
  }

  void _loadExperimentoData() {
    final experimento = widget.experimento!;
    _nomeController.text = experimento.nome;
    _descricaoController.text = experimento.descricao;
    _objetivoController.text = experimento.objetivo;
    _culturaController.text = experimento.cultura;
    _variedadeController.text = experimento.variedade;
    _responsavelController.text = experimento.responsavelTecnico;
    _crmController.text = experimento.crmResponsavel;
    _instituicaoController.text = experimento.instituicao;
    _protocoloController.text = experimento.protocolo;
    _observacoesController.text = experimento.observacoes;
    _repeticoesController.text = experimento.numeroRepeticoes.toString();
    _tratamentosController.text = experimento.numeroTratamentos.toString();
    
    setState(() {
      _dataInicio = experimento.dataInicio;
      _delineamento = experimento.delineamento;
      _status = experimento.status;
      _variaveisResposta = List.from(experimento.variaveisResposta);
      _variaveisAmbientais = List.from(experimento.variaveisAmbientais);
    });
  }

  void _loadDefaultData() {
    // Campos limpos para dados reais
    _repeticoesController.text = '';
    _tratamentosController.text = '';
  }

  Future<void> _selectDataInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dataInicio = picked;
      });
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
        child: Text(item.replaceAll('_', ' ').toUpperCase()),
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

  Widget _buildMultiSelectField({
    required String label,
    required List<String> selected,
    required List<String> options,
    required Function(List<String>) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selected.remove(option);
                    } else {
                      selected.add(option);
                    }
                  });
                  onChanged(selected);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? FortSmartTheme.primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? FortSmartTheme.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    option.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _saveExperimento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final experimento = widget.experimento != null
          ? widget.experimento!.copyWith(
              nome: _nomeController.text,
              descricao: _descricaoController.text,
              objetivo: _objetivoController.text,
              dataInicio: _dataInicio,
              status: _status,
              delineamento: _delineamento,
              numeroRepeticoes: int.tryParse(_repeticoesController.text) ?? 0,
              numeroTratamentos: int.tryParse(_tratamentosController.text) ?? 0,
              cultura: _culturaController.text,
              variedade: _variedadeController.text,
              responsavelTecnico: _responsavelController.text,
              crmResponsavel: _crmController.text,
              instituicao: _instituicaoController.text,
              protocolo: _protocoloController.text,
              variaveisResposta: _variaveisResposta,
              variaveisAmbientais: _variaveisAmbientais,
              observacoes: _observacoesController.text,
              updatedAt: DateTime.now(),
            )
          : ExperimentoModel.create(
              nome: _nomeController.text,
              descricao: _descricaoController.text,
              objetivo: _objetivoController.text,
              talhaoId: 'talhao_001', // TODO: Implementar seleção de talhão
              dataInicio: _dataInicio,
              delineamento: _delineamento,
              numeroRepeticoes: int.tryParse(_repeticoesController.text) ?? 0,
              numeroTratamentos: int.tryParse(_tratamentosController.text) ?? 0,
              cultura: _culturaController.text,
              variedade: _variedadeController.text,
              responsavelTecnico: _responsavelController.text,
              crmResponsavel: _crmController.text,
              instituicao: _instituicaoController.text,
              protocolo: _protocoloController.text,
              variaveisResposta: _variaveisResposta,
              variaveisAmbientais: _variaveisAmbientais,
              observacoes: _observacoesController.text,
              status: _status,
            );

      // Salvar no banco de dados
      if (widget.experimento != null) {
        await _repository.update(experimento);
      } else {
        await _repository.insert(experimento);
      }

      setState(() {
        _isLoading = false;
      });

      SnackbarUtils.showSuccessSnackBar(
        context,
        widget.experimento != null ? 'Experimento atualizado!' : 'Experimento criado!',
      );

      Navigator.pop(context, experimento);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar experimento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.experimento != null ? 'Editar Experimento' : 'Novo Experimento'),
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
              onPressed: _saveExperimento,
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
              // Informações básicas
              Text(
                'Informações Básicas',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Nome do Experimento',
                controller: _nomeController,
                icon: Icons.science,
                hintText: 'Ex: Avaliação de Doses de NPK na Soja',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Descrição',
                controller: _descricaoController,
                icon: Icons.description,
                maxLines: 3,
                hintText: 'Ex: Avaliação de diferentes doses de fertilizante NPK na produtividade da cultura',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Objetivo',
                controller: _objetivoController,
                icon: Icons.flag,
                maxLines: 2,
                hintText: 'Ex: Determinar a dose ótima de NPK para maximizar a produtividade',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Objetivo é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Data de início
              Text(
                'Data de Início',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDataInicio,
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
                        DateFormat('dd/MM/yyyy').format(_dataInicio),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Delineamento experimental
              Text(
                'Delineamento Experimental',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Tipo de Delineamento',
                value: _delineamento,
                items: _delineamentos,
                onChanged: (value) => setState(() => _delineamento = value!),
                icon: Icons.grid_view,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Número de Repetições',
                      controller: _repeticoesController,
                      icon: Icons.repeat,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Número de repetições é obrigatório';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 2) {
                          return 'Mínimo 2 repetições';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Número de Tratamentos',
                      controller: _tratamentosController,
                      icon: Icons.layers,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Número de tratamentos é obrigatório';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 2) {
                          return 'Mínimo 2 tratamentos';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Cultura e variedade
              Text(
                'Cultura e Variedade',
                style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Cultura',
                      controller: _culturaController,
                      icon: Icons.eco,
                      hintText: 'Ex: Soja',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Cultura é obrigatória';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Variedade',
                      controller: _variedadeController,
                      icon: Icons.category,
                      hintText: 'Ex: BMX Potência RR',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Variedade é obrigatória';
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
                      hintText: 'Ex: Dr. João Silva',
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
                      hintText: 'Ex: SP-12345',
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

              _buildTextField(
                label: 'Instituição',
                controller: _instituicaoController,
                icon: Icons.business,
                hintText: 'Ex: Embrapa Soja',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Instituição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Protocolo',
                controller: _protocoloController,
                icon: Icons.description,
                hintText: 'Ex: PROT-2024-001',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Protocolo é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Variáveis de resposta
              _buildMultiSelectField(
                label: 'Variáveis de Resposta',
                selected: _variaveisResposta,
                options: _variaveisRespostaOptions,
                onChanged: (value) => setState(() => _variaveisResposta = value),
                icon: Icons.analytics,
              ),
              const SizedBox(height: 24),

              // Variáveis ambientais
              _buildMultiSelectField(
                label: 'Variáveis Ambientais',
                selected: _variaveisAmbientais,
                options: _variaveisAmbientaisOptions,
                onChanged: (value) => setState(() => _variaveisAmbientais = value),
                icon: Icons.wb_sunny,
              ),
              const SizedBox(height: 24),

              // Status
              _buildDropdownField(
                label: 'Status do Experimento',
                value: _status,
                items: _statusOptions,
                onChanged: (value) => setState(() => _status = value!),
                icon: Icons.info,
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
                  onPressed: _isLoading ? null : _saveExperimento,
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
                          widget.experimento != null ? 'ATUALIZAR EXPERIMENTO' : 'CRIAR EXPERIMENTO',
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
