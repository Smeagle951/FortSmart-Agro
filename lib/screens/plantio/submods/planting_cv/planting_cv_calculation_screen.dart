import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../models/planting_cv_model.dart';
import '../../../../services/planting_cv_calculation_service.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/custom_app_bar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/loading_widget.dart';
import 'widgets/cv_result_card.dart';
import 'widgets/distance_input_widget.dart';

/// Tela para cálculo de Coeficiente de Variação do Plantio (CV%)
class PlantingCVCalculationScreen extends StatefulWidget {
  final String talhaoId;
  final String talhaoNome;
  final String culturaId;
  final String culturaNome;

  const PlantingCVCalculationScreen({
    Key? key,
    required this.talhaoId,
    required this.talhaoNome,
    required this.culturaId,
    required this.culturaNome,
  }) : super(key: key);

  @override
  State<PlantingCVCalculationScreen> createState() => _PlantingCVCalculationScreenState();
}

class _PlantingCVCalculationScreenState extends State<PlantingCVCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calculationService = PlantingCVCalculationService();
  
  // Controllers para os campos
  final _comprimentoController = TextEditingController();
  final _espacamentoController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Controllers para metas (opcionais)
  final _metaPopulacaoController = TextEditingController();
  final _metaPlantasPorMetroController = TextEditingController();
  
  // Estado da tela
  bool _isLoading = false;
  PlantingCVModel? _resultadoCV;
  List<double> _distanciasEntreSementes = [];
  DateTime _dataPlantio = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _comprimentoController.dispose();
    _espacamentoController.dispose();
    _observacoesController.dispose();
    _metaPopulacaoController.dispose();
    _metaPlantasPorMetroController.dispose();
    super.dispose();
  }

  /// Carrega dados iniciais baseados na cultura
  void _carregarDadosIniciais() {
    final infoCultura = _calculationService.obterInfoCVIdeal(widget.culturaNome);
    
    // Definir valores padrão baseados na cultura
    switch (widget.culturaNome.toLowerCase()) {
      case 'soja':
        _espacamentoController.text = '0,45';
        break;
      case 'milho':
        _espacamentoController.text = '0,80';
        break;
      case 'algodão':
        _espacamentoController.text = '0,90';
        break;
      case 'feijão':
        _espacamentoController.text = '0,50';
        break;
      default:
        _espacamentoController.text = '0,50';
    }
  }


  /// Calcula o CV% com os dados inseridos
  Future<void> _calcularCV() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_distanciasEntreSementes.isEmpty) {
      _mostrarErro('Adicione pelo menos uma distância entre sementes');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Logger.info('🌱 Iniciando cálculo de CV% para ${widget.talhaoNome}');

      // Obter metas se fornecidas
      double? metaPopulacao;
      double? metaPlantasPorMetro;
      
      if (_metaPopulacaoController.text.isNotEmpty) {
        metaPopulacao = double.tryParse(_metaPopulacaoController.text.replaceAll(',', '.'));
      }
      
      if (_metaPlantasPorMetroController.text.isNotEmpty) {
        metaPlantasPorMetro = double.tryParse(_metaPlantasPorMetroController.text.replaceAll(',', '.'));
      }

      final resultado = _calculationService.calcularCV(
        distanciasEntreSementes: _distanciasEntreSementes,
        comprimentoLinhaAmostrada: double.parse(_comprimentoController.text.replaceAll(',', '.')),
        espacamentoEntreLinhas: double.parse(_espacamentoController.text.replaceAll(',', '.')),
        talhaoId: widget.talhaoId,
        talhaoNome: widget.talhaoNome,
        culturaId: widget.culturaId,
        culturaNome: widget.culturaNome,
        dataPlantio: _dataPlantio,
        observacoes: _observacoesController.text,
        metaPopulacaoPorHectare: metaPopulacao,
        metaPlantasPorMetro: metaPlantasPorMetro,
      );

      setState(() {
        _resultadoCV = resultado;
        _isLoading = false;
      });

      Logger.info('✅ Cálculo de CV% concluído: ${resultado.coeficienteVariacao.toStringAsFixed(2)}%');
      
      // Mostrar resultado com sugestões
      _mostrarResultado(resultado);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Logger.error('❌ Erro no cálculo de CV%: $e');
      _mostrarErro('Erro no cálculo: ${e.toString()}');
    }
  }

  /// Mostra o resultado do cálculo com sugestões
  void _mostrarResultado(PlantingCVModel resultado) {
    final sugestoes = _calculationService.obterSugestoesMelhoria(resultado.coeficienteVariacao);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              resultado.classificacao == CVClassification.excelente
                  ? Icons.check_circle
                  : resultado.classificacao == CVClassification.bom
                      ? Icons.warning
                      : Icons.error,
              color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
            ),
            const SizedBox(width: 8),
            Text('Resultado do CV%'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CV%: ${resultado.coeficienteVariacao.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(resultado.corIndicador.replaceAll('#', '0xFF'))),
                ),
              ),
              const SizedBox(height: 8),
              Text('Classificação: ${resultado.classificacaoTexto}'),
              Text('Plantas/m: ${resultado.plantasPorMetro.toStringAsFixed(2)}'),
              Text('População/ha: ${resultado.populacaoEstimadaPorHectare.toStringAsFixed(0)}'),
              
              // Mostrar comparação com metas se disponível
              if (resultado.temMetasDefinidas) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Comparação com Metas:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Comparação de população
                if (resultado.metaPopulacaoPorHectare != null) ...[
                  Row(
                    children: [
                      Icon(
                        resultado.statusComparacaoPopulacao == 'Dentro da meta' ? Icons.check_circle :
                        resultado.statusComparacaoPopulacao == 'Próximo da meta' ? Icons.warning :
                        Icons.error,
                        color: Color(int.parse(resultado.corComparacaoPopulacao.replaceAll('#', '0xFF'))),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'População: ${resultado.statusPopulacaoTexto}',
                          style: TextStyle(
                            color: Color(int.parse(resultado.corComparacaoPopulacao.replaceAll('#', '0xFF'))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (resultado.diferencaPopulacaoPercentual != null)
                    Text(
                      'Diferença: ${resultado.diferencaPopulacaoPercentual!.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 8),
                ],
                
                // Comparação de plantas por metro
                if (resultado.metaPlantasPorMetro != null) ...[
                  Row(
                    children: [
                      Icon(
                        resultado.statusComparacaoPlantasPorMetro == 'Dentro da meta' ? Icons.check_circle :
                        resultado.statusComparacaoPlantasPorMetro == 'Próximo da meta' ? Icons.warning :
                        Icons.error,
                        color: Color(int.parse(resultado.corComparacaoPlantasPorMetro.replaceAll('#', '0xFF'))),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Plantas/m: ${resultado.statusPlantasPorMetroTexto}',
                          style: TextStyle(
                            color: Color(int.parse(resultado.corComparacaoPlantasPorMetro.replaceAll('#', '0xFF'))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (resultado.diferencaPlantasPorMetroPercentual != null)
                    Text(
                      'Diferença: ${resultado.diferencaPlantasPorMetroPercentual!.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ],
              
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
    if (_resultadoCV == null) return;

    try {
      Logger.info('💾 Salvando resultado de CV%: ${_resultadoCV!.id}');
      
      // Salvar no banco de dados usando o serviço
      await _calculationService.salvarCV(_resultadoCV!);
      
      _mostrarSucesso('Resultado salvo com sucesso!');
      
      // Voltar para a tela anterior
      Navigator.of(context).pop(_resultadoCV);
      
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
        title: 'Cálculo de CV% - ${widget.talhaoNome}',
        // subtitle: widget.culturaNome, // Parâmetro não existe
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
                              'Informações do Plantio',
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
                                Text('Data: ${_dataPlantio.day}/${_dataPlantio.month}/${_dataPlantio.year}'),
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
                              'Dados da Amostragem',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _comprimentoController,
                              label: 'Comprimento da linha amostrada (m)',
                              hint: 'Ex: 3,0',
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
                              controller: _observacoesController,
                              label: 'Observações (opcional)',
                              hint: 'Ex: Plantio realizado em condições de solo úmido',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campos de metas (opcionais)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.flag, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Metas para Comparação (Opcional)',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Informe as metas desejadas para comparar com os resultados calculados',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _metaPopulacaoController,
                              label: 'Meta de População (plantas/ha)',
                              hint: 'Ex: 277000',
                              keyboardType: TextInputType.numberWithOptions(decimal: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final valor = double.tryParse(value);
                                  if (valor == null || valor <= 0) {
                                    return 'Valor inválido';
                                  }
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _metaPlantasPorMetroController,
                              label: 'Meta de Plantas por Metro',
                              hint: 'Ex: 12,7',
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final valor = double.tryParse(value.replaceAll(',', '.'));
                                  if (valor == null || valor <= 0) {
                                    return 'Valor inválido';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Widget para entrada de distâncias
                    DistanceInputWidget(
                      distancias: _distanciasEntreSementes,
                      onDistanciasChanged: (distancias) {
                        setState(() {
                          _distanciasEntreSementes = distancias;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão de cálculo
                    CustomButton(
                      label: 'Calcular CV%',
                      onPressed: _calcularCV,
                      icon: Icons.calculate,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resultado se disponível
                    if (_resultadoCV != null) ...[
                      CVResultCard(resultado: _resultadoCV!),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Salvar Resultado',
                        onPressed: _salvarResultado,
                        icon: Icons.save,
                        isOutlined: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
