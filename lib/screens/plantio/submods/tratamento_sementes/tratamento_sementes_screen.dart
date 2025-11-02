import 'package:flutter/material.dart';
import '../../../../../utils/fortsmart_theme.dart';
import '../../../../../utils/snackbar_utils.dart';
import '../../../../../models/seed_calc_result.dart';
import '../../../../../modules/tratamento_sementes/repositories/dose_ts_repository.dart';
import 'models/tratamento_sementes_state.dart';
import 'services/tratamento_sementes_service.dart';
import 'widgets/dados_basicos_section.dart';
import 'widgets/selecao_dose_section.dart';
import 'widgets/produtos_section.dart';

/// Tela de tratamento de sementes refatorada
class TratamentoSementesScreen extends StatefulWidget {
  final SeedCalcResult? resultadoCalculo;
  final double pesoBag;
  final int numeroBags;
  final double sementesPorBag;
  final double germinacao;
  final double vigor;

  const TratamentoSementesScreen({
    Key? key,
    this.resultadoCalculo,
    required this.pesoBag,
    required this.numeroBags,
    required this.sementesPorBag,
    required this.germinacao,
    required this.vigor,
  }) : super(key: key);

  @override
  State<TratamentoSementesScreen> createState() => _TratamentoSementesScreenState();
}

class _TratamentoSementesScreenState extends State<TratamentoSementesScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoseTSRepository _doseRepository = DoseTSRepository();
  
  // Estado da aplicação
  late TratamentoSementesState _state;

  @override
  void initState() {
    super.initState();
    _state = TratamentoSementesState(
      resultadoCalculo: widget.resultadoCalculo,
      pesoBag: widget.pesoBag,
      numeroBags: widget.numeroBags,
      sementesPorBag: widget.sementesPorBag,
      germinacao: widget.germinacao,
      vigor: widget.vigor,
      pesoBagEditavel: widget.pesoBag,
      numeroBagsEditavel: widget.numeroBags,
    );
    _carregarDoses();
  }

  Future<void> _carregarDoses() async {
    setState(() {
      _state = _state.copyWith(isLoading: true);
    });

    try {
      final doses = await _doseRepository.getAll(orderBy: 'nome ASC');
      setState(() {
        _state = _state.copyWith(
          dosesDisponiveis: doses,
          isLoading: false,
        );
      });
    } catch (e) {
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar doses: $e');
    }
  }

  void _calcularProdutos() {
    if (_state.doseSelecionada == null) return;

    setState(() {
      _state = _state.copyWith(isCalculando: true);
    });

    try {
      final produtos = TratamentoSementesService.simularProdutos(_state);
      
      setState(() {
        _state = _state.copyWith(
          produtosDose: produtos,
          isCalculando: false,
        );
      });
    } catch (e) {
      setState(() {
        _state = _state.copyWith(
          isCalculando: false,
          error: e.toString(),
        );
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao calcular produtos: $e');
    }
  }

  void _salvarTratamento() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_state.doseSelecionada == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma dose antes de salvar');
      return;
    }

    // TODO: Implementar salvamento
    SnackbarUtils.showSuccessSnackBar(context, 'Tratamento salvo com sucesso!');
  }

  void _compartilharResultado() {
    if (_state.doseSelecionada == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma dose antes de compartilhar');
      return;
    }

    // TODO: Implementar compartilhamento
    SnackbarUtils.showSuccessSnackBar(context, 'Resultado compartilhado!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FortSmartTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('🌱 Tratamento de Sementes'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DadosBasicosSection(
                state: _state,
                onStateChanged: (newState) {
                  setState(() {
                    _state = newState;
                  });
                  // Recalcular produtos se houver dose selecionada
                  if (_state.doseSelecionada != null) {
                    _calcularProdutos();
                  }
                },
              ),
              const SizedBox(height: 16),
              SelecaoDoseSection(
                state: _state,
                onStateChanged: (newState) {
                  setState(() {
                    _state = newState;
                  });
                  if (newState.doseSelecionada != null) {
                    _calcularProdutos();
                  }
                },
              ),
              const SizedBox(height: 16),
              ProdutosSection(
                state: _state,
                onStateChanged: (newState) {
                  setState(() {
                    _state = newState;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildBotoes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotoes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
            onPressed: _salvarTratamento,
            style: ElevatedButton.styleFrom(
              backgroundColor: FortSmartTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            onPressed: _compartilharResultado,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
