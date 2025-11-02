import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/app_colors.dart';
import '../../../widgets/fortsmart_card.dart';
import '../widgets/custom_text_form_field.dart';
import '../../../models/talhao_model.dart';
import '../../../services/talhao_unified_loader_service.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/fortsmart_theme.dart';

/// Tela de Cálculo IRP (Índice de Resistência do Solo) Avançado
/// Seguindo o padrão FortSmart com design elegante e funcional
class IrpCompactionScreen extends StatefulWidget {
  const IrpCompactionScreen({Key? key}) : super(key: key);

  @override
  State<IrpCompactionScreen> createState() => _IrpCompactionScreenState();
}

class _IrpCompactionScreenState extends State<IrpCompactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _talhaoLoader = TalhaoUnifiedLoaderService();
  
  // Controllers
  final _pesoMarteloController = TextEditingController();
  final _alturaQuedaController = TextEditingController();
  final _diametroPonteiraController = TextEditingController();
  final _anguloPonteiraController = TextEditingController();
  final _profundidadeController = TextEditingController();
  final _numeroGolpesController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  String? _errorMessage;
  TalhaoModel? _selectedPlot;
  List<TalhaoModel> _talhoes = [];
  
  // Dados calculados
  double _resultadoIrp = 0.0;
  String _interpretacao = '';
  List<Map<String, dynamic>> _medicoesIrp = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _pesoMarteloController.dispose();
    _alturaQuedaController.dispose();
    _diametroPonteiraController.dispose();
    _anguloPonteiraController.dispose();
    _profundidadeController.dispose();
    _numeroGolpesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Carregar talhões
      _talhoes = await _talhaoLoader.carregarTalhoes();
      
      
      if (mounted) {
      setState(() {
          _isLoading = false;
      });
      }
    } catch (e) {
      if (mounted) {
      setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: ${e.toString()}';
        });
        SnackbarUtils.showErrorSnackBar(context, _errorMessage!);
      }
    }
  }
  
  void _adicionarMedicao() {
    if (_profundidadeController.text.isEmpty || _numeroGolpesController.text.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Preencha a profundidade e o número de golpes');
      return;
    }
    
    final profundidade = double.tryParse(_profundidadeController.text);
    final numeroGolpes = int.tryParse(_numeroGolpesController.text);
    
    if (profundidade == null || numeroGolpes == null || profundidade <= 0 || numeroGolpes <= 0) {
      SnackbarUtils.showErrorSnackBar(context, 'Os valores devem ser maiores que zero');
      return;
    }
    
    // Calcular IRP para esta medição
    final irp = _calcularIrp(profundidade, numeroGolpes);
    
    setState(() {
      _medicoesIrp.add({
        'profundidade': profundidade,
        'numeroGolpes': numeroGolpes,
        'irp': irp,
        'data': DateTime.now(),
      });
      });
      
      // Limpar campos
      _profundidadeController.clear();
      _numeroGolpesController.clear();
    
    // Calcular resultado final
    _calcularResultadoFinal();
    
    SnackbarUtils.showSuccessSnackBar(context, 'Medição adicionada com sucesso!');
  }
  
  double _calcularIrp(double profundidade, int numeroGolpes) {
    final pesoMartelo = double.tryParse(_pesoMarteloController.text) ?? 0.0;
    final alturaQueda = double.tryParse(_alturaQuedaController.text) ?? 0.0;
    final diametroPonteira = double.tryParse(_diametroPonteiraController.text) ?? 0.0;
    
    if (pesoMartelo <= 0 || alturaQueda <= 0 || diametroPonteira <= 0) {
      SnackbarUtils.showErrorSnackBar(context, 'Preencha todos os campos com valores válidos');
      return 0.0;
    }
    
    // Fórmula do IRP: IRP = (P × H × N) / (π × D² × P)
    // Onde: P = peso do martelo, H = altura da queda, N = número de golpes
    // D = diâmetro da ponteira, P = profundidade
    
    final areaPonteira = 3.14159 * (diametroPonteira / 2) * (diametroPonteira / 2);
    final energiaTotal = pesoMartelo * alturaQueda * numeroGolpes;
    final irp = energiaTotal / (areaPonteira * profundidade);
    
    return irp;
  }
  
  void _calcularResultadoFinal() {
    if (_medicoesIrp.isEmpty) return;
    
    // Calcular média do IRP
    final somaIrp = _medicoesIrp.fold<double>(0.0, (sum, medicao) => sum + medicao['irp']);
    _resultadoIrp = somaIrp / _medicoesIrp.length;
    
    // Determinar interpretação
    if (_resultadoIrp < 1.0) {
      _interpretacao = 'Solo muito solto - Risco de compactação baixo';
    } else if (_resultadoIrp < 2.0) {
      _interpretacao = 'Solo solto - Risco de compactação moderado';
    } else if (_resultadoIrp < 3.0) {
      _interpretacao = 'Solo moderadamente compactado - Risco de compactação alto';
    } else {
      _interpretacao = 'Solo muito compactado - Risco de compactação muito alto';
    }
    
    setState(() {});
  }
  
  Future<void> _salvarDados() async {
    if (_medicoesIrp.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Adicione pelo menos uma medição');
      return;
    }
    
    if (_selectedPlot == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão');
      return;
    }
    
    try {
      // Aqui você pode implementar a lógica de salvamento
      // Por exemplo, salvar no banco de dados
      
      SnackbarUtils.showSuccessSnackBar(context, 'Dados salvos com sucesso!');
      Navigator.of(context).pop();
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar dados: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FortSmartTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cálculo IRP Avançado',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : Form(
          key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                        _buildSelecaoTalhaoCultura(),
                        const SizedBox(height: 16),
                        _buildParametrosPenetrometro(),
                        const SizedBox(height: 16),
                        _buildMedicoesProfundidade(),
                        const SizedBox(height: 16),
                        if (_medicoesIrp.isNotEmpty) _buildResultados(),
                        const SizedBox(height: 24),
                        _buildBotoes(),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
                child: Padding(
        padding: const EdgeInsets.all(16.0),
                  child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                    children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
      ),
    );
  }
  
  Widget _buildSelecaoTalhaoCultura() {
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      Row(
                        children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Informações do Talhão',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Seleção de Talhão
          CustomTextFormField(
            label: 'Talhão',
            readOnly: true,
            controller: TextEditingController(
              text: _selectedPlot?.name ?? 'Selecione um talhão',
            ),
            suffixIcon: Icon(Icons.arrow_drop_down),
            onTap: _showTalhaoSelector,
            validator: (value) {
              if (_selectedPlot == null) {
                return 'Selecione um talhão';
              }
              return null;
            },
          ),
          
        ],
      ),
    );
  }
  
  Widget _buildParametrosPenetrometro() {
    return FortSmartCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.primary),
              const SizedBox(width: 8),
                      const Text(
                        'Parâmetros do Penetrômetro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
              ),
            ],
                      ),
                      const SizedBox(height: 16),
          
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              label: 'Peso do Martelo (kg)',
                              controller: _pesoMarteloController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo obrigatório';
                                }
                    final peso = double.tryParse(value);
                    if (peso == null || peso <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextFormField(
                              label: 'Altura da Queda (m)',
                              controller: _alturaQuedaController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo obrigatório';
                                }
                    final altura = double.tryParse(value);
                    if (altura == null || altura <= 0) {
                                  return 'Valor inválido';
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
                            child: CustomTextFormField(
                              label: 'Diâmetro da Ponteira (cm)',
                              controller: _diametroPonteiraController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo obrigatório';
                                }
                    final diametro = double.tryParse(value);
                    if (diametro == null || diametro <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextFormField(
                              label: 'Ângulo da Ponteira (graus)',
                              controller: _anguloPonteiraController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                              ],
                              helperText: 'Opcional',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
    );
  }
  
  Widget _buildMedicoesProfundidade() {
    return FortSmartCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Row(
            children: [
              Icon(Icons.straighten, color: AppColors.primary),
              const SizedBox(width: 8),
                      const Text(
                        'Medições de Profundidade',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
              ),
            ],
                      ),
                      const SizedBox(height: 16),
          
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              label: 'Profundidade (cm)',
                              controller: _profundidadeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                child: CustomTextFormField(
                  label: 'Número de Golpes',
                                                          controller: _numeroGolpesController,
                                                          keyboardType: TextInputType.number,
                                                          inputFormatters: [
                                                            FilteringTextInputFormatter.digitsOnly,
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
          
                                                  const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                                                    onPressed: _adicionarMedicao,
                                                    icon: const Icon(Icons.add),
                                                    label: const Text('Adicionar Medição'),
                                                    style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                                                      foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
                                                    ),
                                                  ),
                                                  
                                                  if (_medicoesIrp.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Medições Realizadas (${_medicoesIrp.length})',
              style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
            ..._medicoesIrp.asMap().entries.map((entry) {
              final index = entry.key;
              final medicao = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                                                          title: Text('Profundidade: ${medicao['profundidade']} cm'),
                  subtitle: Text('Golpes: ${medicao['numeroGolpes']} | IRP: ${medicao['irp'].toStringAsFixed(2)} MPa'),
                                                          trailing: IconButton(
                                                            icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _medicoesIrp.removeAt(index);
                        _calcularResultadoFinal();
                      });
                    },
                  ),
                ),
              );
            }).toList(),
                                                  ],
                                                ],
                                              ),
    );
  }
  
  Widget _buildResultados() {
    return FortSmartCard(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary),
              const SizedBox(width: 8),
                                                    const Text(
                                                      'Resultados',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
              ),
            ],
                                                    ),
                                                    const SizedBox(height: 16),
          
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                'Índice de Resistência do Solo (IRP):',
                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                    const SizedBox(height: 8),
                                                              Text(
                                                                '${_resultadoIrp.toStringAsFixed(2)} MPa',
                                                                style: TextStyle(
                                                                  fontSize: 24,
                                                                  fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                'Interpretação:',
                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                    const SizedBox(height: 8),
                                                              Text(
                                                                _interpretacao,
                                                                style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
        ],
      ),
    );
  }
  
  Widget _buildBotoes() {
    return Row(
                                            children: [
                                              Expanded(
          child: OutlinedButton(
                                                  onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.primary),
            ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _salvarDados,
                                                  style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
                                                    foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
                                                  ),
                                                  child: const Text('Salvar'),
                                                ),
                                              ),
                                            ],
    );
  }
  
  void _showTalhaoSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Talhão'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _talhoes.length,
            itemBuilder: (context, index) {
              final talhao = _talhoes[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    talhao.name.isNotEmpty ? talhao.name[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(talhao.name),
                subtitle: Text('${talhao.area.toStringAsFixed(2)} ha'),
                onTap: () {
                  setState(() {
                    _selectedPlot = talhao;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
}