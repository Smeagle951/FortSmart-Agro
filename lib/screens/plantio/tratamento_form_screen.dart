import 'package:flutter/material.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/fortsmart_theme.dart';
import '../../database/models/experimento_model.dart';
import '../../database/models/tratamento_model.dart';

/// Tela de formulário para criar/editar tratamentos
class TratamentoFormScreen extends StatefulWidget {
  final ExperimentoModel experimento;
  final TratamentoModel? tratamento;

  const TratamentoFormScreen({
    Key? key,
    required this.experimento,
    this.tratamento,
  }) : super(key: key);

  @override
  State<TratamentoFormScreen> createState() => _TratamentoFormScreenState();
}

class _TratamentoFormScreenState extends State<TratamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // Parâmetros dinâmicos
  final Map<String, TextEditingController> _parametrosControllers = {};

  // Variáveis de estado
  String _tipo = 'fertilizante';
  int _numeroRepeticao = 1;

  // Opções para dropdowns
  final List<String> _tiposTratamento = [
    'testemunha',
    'fertilizante',
    'defensivo',
    'semente',
    'corretivo',
    'outros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tratamento != null) {
      _loadTratamentoData();
    } else {
      _loadDefaultData();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _codigoController.dispose();
    _observacoesController.dispose();
    for (final controller in _parametrosControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadTratamentoData() {
    final tratamento = widget.tratamento!;
    _nomeController.text = tratamento.nome;
    _descricaoController.text = tratamento.descricao;
    _codigoController.text = tratamento.codigo;
    _observacoesController.text = tratamento.observacoes;
    
    setState(() {
      _tipo = tratamento.tipo;
      _numeroRepeticao = tratamento.numeroRepeticao;
    });

    // Carregar parâmetros
    for (final entry in tratamento.parametros.entries) {
      _parametrosControllers[entry.key] = TextEditingController(text: entry.value.toString());
    }
  }

  void _loadDefaultData() {
    _codigoController.text = '';
    _numeroRepeticao = 1;
    
    // Adicionar parâmetros padrão baseados no tipo
    _addParametroPadrao();
  }

  void _addParametroPadrao() {
    switch (_tipo) {
      case 'fertilizante':
        _parametrosControllers['dose'] = TextEditingController();
        _parametrosControllers['unidade'] = TextEditingController();
        _parametrosControllers['formulacao'] = TextEditingController();
        break;
      case 'defensivo':
        _parametrosControllers['dose'] = TextEditingController();
        _parametrosControllers['unidade'] = TextEditingController();
        _parametrosControllers['principio_ativo'] = TextEditingController();
        break;
      case 'semente':
        _parametrosControllers['densidade'] = TextEditingController();
        _parametrosControllers['unidade'] = TextEditingController();
        _parametrosControllers['tratamento'] = TextEditingController();
        break;
      case 'testemunha':
        _parametrosControllers['descricao'] = TextEditingController();
        break;
    }
  }

  void _onTipoChanged(String? newTipo) {
    setState(() {
      _tipo = newTipo!;
      
      // Limpar parâmetros existentes
      for (final controller in _parametrosControllers.values) {
        controller.dispose();
      }
      _parametrosControllers.clear();
      
      // Adicionar parâmetros padrão para o novo tipo
      _addParametroPadrao();
    });
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

  Widget _buildParametrosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parâmetros do Tratamento',
          style: FortSmartTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        ..._parametrosControllers.entries.map((entry) {
          String hintText = '';
          switch (entry.key) {
            case 'dose':
              hintText = 'Ex: 100';
              break;
            case 'unidade':
              hintText = 'Ex: kg/ha, L/ha';
              break;
            case 'formulacao':
              hintText = 'Ex: NPK 20-10-10';
              break;
            case 'principio_ativo':
              hintText = 'Ex: Glifosato';
              break;
            case 'densidade':
              hintText = 'Ex: 250000';
              break;
            case 'tratamento':
              hintText = 'Ex: Fungicida, Inseticida';
              break;
            case 'descricao':
              hintText = 'Ex: Sem aplicação';
              break;
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTextField(
              label: entry.key.replaceAll('_', ' ').toUpperCase(),
              controller: entry.value,
              hintText: hintText,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '${entry.key} é obrigatório';
                }
                return null;
              },
            ),
          );
        }).toList(),
        
        // Botão para adicionar parâmetro personalizado
        OutlinedButton.icon(
          onPressed: _addParametroPersonalizado,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Parâmetro'),
          style: OutlinedButton.styleFrom(
            foregroundColor: FortSmartTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  void _addParametroPersonalizado() {
    final controller = TextEditingController();
    String nomeParametro = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Parâmetro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome do Parâmetro',
                hintText: 'Ex: volume, concentração, etc.',
              ),
              onChanged: (value) => nomeParametro = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Valor',
                hintText: 'Ex: 100, 2.5, etc.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (nomeParametro.isNotEmpty && controller.text.isNotEmpty) {
                setState(() {
                  _parametrosControllers[nomeParametro] = controller;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTratamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Coletar parâmetros
      final parametros = <String, dynamic>{};
      for (final entry in _parametrosControllers.entries) {
        if (entry.value.text.isNotEmpty) {
          parametros[entry.key] = entry.value.text;
        }
      }

      final tratamento = widget.tratamento != null
          ? widget.tratamento!.copyWith(
              nome: _nomeController.text,
              descricao: _descricaoController.text,
              tipo: _tipo,
              parametros: parametros,
              numeroRepeticao: _numeroRepeticao,
              codigo: _codigoController.text,
              observacoes: _observacoesController.text,
              updatedAt: DateTime.now(),
            )
          : TratamentoModel.create(
              experimentoId: widget.experimento.id,
              nome: _nomeController.text,
              descricao: _descricaoController.text,
              tipo: _tipo,
              parametros: parametros,
              numeroRepeticao: _numeroRepeticao,
              codigo: _codigoController.text,
              observacoes: _observacoesController.text,
            );

      // TODO: Implementar salvamento real no banco
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });

      SnackbarUtils.showSuccessSnackBar(
        context,
        widget.tratamento != null ? 'Tratamento atualizado!' : 'Tratamento criado!',
      );

      Navigator.pop(context, tratamento);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar tratamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tratamento != null ? 'Editar Tratamento' : 'Novo Tratamento'),
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
              onPressed: _saveTratamento,
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
                    Text('Tratamentos: ${widget.experimento.numeroTratamentos} | Repetições: ${widget.experimento.numeroRepeticoes}'),
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
                label: 'Nome do Tratamento',
                controller: _nomeController,
                icon: Icons.science,
                hintText: 'Ex: NPK 100%',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Código',
                controller: _codigoController,
                icon: Icons.tag,
                hintText: 'Ex: T1, T2, T3...',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Código é obrigatório';
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
                hintText: 'Ex: Dose recomendada de fertilizante NPK 20-10-10',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildDropdownField(
                label: 'Tipo de Tratamento',
                value: _tipo,
                items: _tiposTratamento,
                onChanged: _onTipoChanged,
                icon: Icons.category,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                decoration: FortSmartTheme.createInputDecoration(
                  'Número da Repetição',
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
              const SizedBox(height: 24),

              // Parâmetros do tratamento
              _buildParametrosSection(),
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
                  onPressed: _isLoading ? null : _saveTratamento,
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
                          widget.tratamento != null ? 'ATUALIZAR TRATAMENTO' : 'CRIAR TRATAMENTO',
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
