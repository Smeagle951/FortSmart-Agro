import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/planting_stand_model.dart';
import '../../../../services/planting_stand_calculation_service.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/loading_widget.dart';
import 'widgets/stand_result_card.dart';

/// Tela para registro de Estande de Plantas (emergência)
class PlantingStandRegistrationScreen extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;

  const PlantingStandRegistrationScreen({
    Key? key,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
  }) : super(key: key);

  @override
  State<PlantingStandRegistrationScreen> createState() => _PlantingStandRegistrationScreenState();
}

class _PlantingStandRegistrationScreenState extends State<PlantingStandRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calculationService = PlantingStandCalculationService();
  
  // Controllers para os campos
  final _comprimentoController = TextEditingController();
  final _numeroLinhasController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _plantasContadasController = TextEditingController();
  final _germinacaoTeoricaController = TextEditingController();
  final _populacaoAlvoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Estado da tela
  bool _isLoading = false;
  PlantingStandModel? _resultadoEstande;
  DateTime _dataAvaliacao = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _comprimentoController.dispose();
    _numeroLinhasController.dispose();
    _espacamentoController.dispose();
    _plantasContadasController.dispose();
    _germinacaoTeoricaController.dispose();
    _populacaoAlvoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Carrega dados iniciais baseados na cultura
  void _carregarDadosIniciais() {
    final infoCultura = _calculationService.obterInfoPopulacaoIdeal(widget.culturaNome);
    
    // Definir valores padrão baseados na cultura
    switch (widget.culturaNome.toLowerCase()) {
      case 'soja':
        _espacamentoController.text = '0,45';
        _populacaoAlvoController.text = '300000';
        break;
      case 'milho':
        _espacamentoController.text = '0,80';
        _populacaoAlvoController.text = '60000';
        break;
      case 'algodão':
        _espacamentoController.text = '0,90';
        _populacaoAlvoController.text = '100000';
        break;
      case 'feijão':
        _espacamentoController.text = '0,50';
        _populacaoAlvoController.text = '250000';
        break;
      default:
        _espacamentoController.text = '0,50';
        _populacaoAlvoController.text = '200000';
    }
  }

  /// Calcula o estande com os dados inseridos
  Future<void> _calcularEstande() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('🌱 Iniciando cálculo de estande para ${widget.talhaoNome}');

      final resultado = _calculationService.calcularEstande(
        plantasContadas: int.parse(_plantasContadasController.text),
        comprimentoLinhaAvaliado: double.parse(_comprimentoController.text.replaceAll(',', '.')),
        numeroLinhasAvaliadas: int.parse(_numeroLinhasController.text),
        espacamentoEntreLinhas: double.parse(_espacamentoController.text.replaceAll(',', '.')),
        talhaoId: widget.talhaoId,
        talhaoNome: widget.talhaoNome,
        culturaId: widget.culturaId,
        culturaNome: widget.culturaNome,
        dataAvaliacao: _dataAvaliacao,
        percentualGerminacaoTeorica: _germinacaoTeoricaController.text.isNotEmpty
            ? double.tryParse(_germinacaoTeoricaController.text.replaceAll(',', '.'))
            : null,
        populacaoAlvo: _populacaoAlvoController.text.isNotEmpty
            ? double.tryParse(_populacaoAlvoController.text.replaceAll(',', '.'))
            : null,
        observacoes: _observacoesController.text,
      );

      setState(() {
        _resultadoEstande = resultado;
        _isLoading = false;
      });

      Logger.info('✅ Cálculo de estande concluído: ${resultado.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha');
      
      // Mostrar resultado com sugestões
      _mostrarResultado(resultado);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Logger.error('❌ Erro no cálculo de estande: $e');
      _mostrarErro('Erro no cálculo: ${e.toString()}');
    }
  }

  /// Mostra o resultado do cálculo com sugestões
  void _mostrarResultado(PlantingStandModel resultado) {
    final sugestoes = _calculationService.obterSugestoesMelhoria(resultado);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              resultado.classificacao == StandClassification.excelente
                  ? Icons.check_circle
                  : resultado.classificacao == StandClassification.bom
                      ? Icons.warning
                      : resultado.classificacao == StandClassification.regular
                          ? Icons.warning_amber
                          : Icons.error,
              color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
            ),
            const SizedBox(width: 8),
            Text('Resultado do Estande'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'População: ${resultado.populacaoRealPorHectare.toStringAsFixed(0)} plantas/ha',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                ),
              ),
              const SizedBox(height: 8),
              Text('Classificação: ${resultado.classificacaoTexto}'),
              Text('Plantas/m: ${resultado.plantasPorMetro.toStringAsFixed(2)}'),
              if (resultado.percentualAtingidoPopulacaoAlvo != null)
                Text('Atingido: ${resultado.percentualAtingidoPopulacaoAlvo!.toStringAsFixed(1)}% do alvo'),
              const SizedBox(height: 16),
              if (sugestoes.isNotEmpty) ...[
                Text(
                  'Sugestões:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...sugestoes.map((sugestao) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(sugestao)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _salvarResultado();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  /// Salva o resultado do cálculo
  Future<void> _salvarResultado() async {
    if (_resultadoEstande == null) return;

    try {
      // TODO: Implementar salvamento no banco de dados
      Logger.info('💾 Salvando resultado de estande: ${_resultadoEstande!.id}');
      
      _mostrarSucesso('Resultado salvo com sucesso!');
      
      // Voltar para a tela anterior
      Navigator.of(context).pop(_resultadoEstande);
      
    } catch (e) {
      Logger.error('❌ Erro ao salvar resultado: $e');
      _mostrarErro('Erro ao salvar: ${e.toString()}');
    }
  }

  /// Mostra mensagem de erro
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mostra mensagem de sucesso
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Registro de Estande - ${widget.talhaoNome}',
        subtitle: widget.culturaNome,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do talhão
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações da Avaliação',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text('Talhão: ${widget.talhaoNome}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.eco, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text('Cultura: ${widget.culturaNome}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text('Data: ${_dataAvaliacao.day}/${_dataAvaliacao.month}/${_dataAvaliacao.year}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campos de entrada
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dados da Contagem',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _comprimentoController,
                              label: 'Comprimento da linha avaliado (m)',
                              hint: 'Ex: 5,0',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o comprimento da linha';
                                }
                                final valor = double.tryParse(value.replaceAll(',', '.'));
                                if (valor == null || valor <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _numeroLinhasController,
                              label: 'Número de linhas avaliadas',
                              hint: 'Ex: 3',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o número de linhas';
                                }
                                final valor = int.tryParse(value);
                                if (valor == null || valor <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _espacamentoController,
                              label: 'Espaçamento entre linhas (m)',
                              hint: 'Ex: 0,45',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o espaçamento entre linhas';
                                }
                                final valor = double.tryParse(value.replaceAll(',', '.'));
                                if (valor == null || valor <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _plantasContadasController,
                              label: 'Plantas contadas',
                              hint: 'Ex: 45',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe o número de plantas contadas';
                                }
                                final valor = int.tryParse(value);
                                if (valor == null || valor < 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campos opcionais
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dados Opcionais',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _germinacaoTeoricaController,
                              label: '% de germinação teórica (opcional)',
                              hint: 'Ex: 95',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _populacaoAlvoController,
                              label: 'População alvo por hectare (opcional)',
                              hint: 'Ex: 300000',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _observacoesController,
                              label: 'Observações (opcional)',
                              hint: 'Ex: Plantas com bom desenvolvimento, sem pragas visíveis',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão de cálculo
                    CustomButton(
                      text: 'Calcular Estande',
                      onPressed: _calcularEstande,
                      icon: Icons.calculate,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resultado se disponível
                    if (_resultadoEstande != null) ...[
                      StandResultCard(resultado: _resultadoEstande!),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Salvar Resultado',
                        onPressed: _salvarResultado,
                        icon: Icons.save,
                        variant: ButtonVariant.secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
