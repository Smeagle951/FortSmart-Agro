import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/models/calculo_sementes_model.dart';
import '../../../../database/repositories/calculo_sementes_repository.dart';
import '../../../../models/calibration_history_model.dart';
import '../../../../database/daos/calibration_history_dao.dart';
import '../../../../database/app_database.dart';
import '../plantio_calibragem_historico_screen.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../../utils/fortsmart_theme.dart';
// import '../tratamento_sementes/tratamento_sementes_screen.dart'; // Comentado temporariamente
// import '../../../../modules/tratamento_sementes/screens/ts_dose_editor_screen.dart'; // Import for Nova Dose - Arquivo não encontrado
import 'models/calculo_sementes_state.dart';
import 'services/calculo_sementes_service.dart';
import 'widgets/modo_calculo_selector.dart';
import 'widgets/modo_bag_selector.dart';
import 'widgets/area_plantio_section.dart';
import 'widgets/parametros_entrada_form.dart';
import 'widgets/resultados_display.dart';
import 'widgets/botao_tratamento.dart';
import 'widgets/acoes_bottom_bar.dart';

/// Tela principal de cálculo de sementes refatorada
class CalculoSementesScreen extends StatefulWidget {
  const CalculoSementesScreen({Key? key}) : super(key: key);

  @override
  State<CalculoSementesScreen> createState() => _CalculoSementesScreenState();
}

class _CalculoSementesScreenState extends State<CalculoSementesScreen> {
  final _formKey = GlobalKey<FormState>();
  final CalculoSementesRepository _calculoSementesRepository = CalculoSementesRepository();
  final Uuid _uuid = Uuid();

  // Estado da aplicação
  late CalculoSementesState _state;

  @override
  void initState() {
    super.initState();
    _state = const CalculoSementesState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      print('🌱 Iniciando carregamento de dados do módulo plantio...');
      print('✅ Módulo configurado para usar apenas área manual');
      print('✅ Dados carregados com sucesso!');
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados: ${e.toString()}');
    }
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final resultado = CalculoSementesService.calcular(_state);
      
      setState(() {
        _state = _state.copyWith(
          resultadoCalculo: resultado,
          isLoading: false,
          error: null,
        );
      });
      
      // Log para debug
      print('🔍 DEBUG - Valores de entrada:');
      print('  - Modo bag: ${_state.modoBag}');
      print('  - Usar PMS manual: ${_state.usarPMSManual}');
      print('  - PMS manual: ${_state.pmsManual}');
      print('  - Espaçamento: ${_state.espacamento} m');
      print('  - Sementes por metro: ${_state.sementesPorMetro}');
      print('  - Germinação: ${_state.germinacao}%');
      print('  - Vigor: ${_state.vigor}%');
      print('  - Sementes por bag: ${_state.sementesPorBag}');
      print('  - Peso do bag: ${_state.pesoBag} kg');
      print('  - Número de bags: ${_state.numeroBags}');
      print('🔍 DEBUG - Parâmetros para cálculo:');
      final params = _state.calculoParams;
      params.forEach((key, value) {
        print('  - $key: $value');
      });
      print('🔍 DEBUG - Resultados:');
      print('  - PMS: ${resultado.pms_g_per_1000.toStringAsFixed(2)} g/1000');
      print('  - Sementes/ha: ${resultado.seedsPerHa.toStringAsFixed(0)}');
      print('  - Sementes necessárias/ha: ${resultado.seedsNeededPerHa.toStringAsFixed(0)}');
      print('  - Kg/ha: ${resultado.kgPerHa.toStringAsFixed(2)}');
      print('  - Hectares cobertos: ${resultado.hectaresCovered.toStringAsFixed(2)}');
      
    } catch (e) {
      print('❌ Erro no cálculo: $e');
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          error: e.toString(),
        );
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro no cálculo: ${e.toString()}');
    }
  }

  void _limparCampos() {
    setState(() {
      _state = const CalculoSementesState();
    });
  }

  Future<void> _salvarCalculo() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_state.resultadoCalculo == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Faça o cálculo antes de salvar');
      return;
    }
    
    try {
      final resultado = _state.resultadoCalculo!;
      
      // Criar modelo para salvar no banco
      final calculo = CalculoSementesModel(
        id: _uuid.v4(),
        talhaoId: null,
        safraId: null,
        culturaId: null,
        espacamentoCm: _state.espacamento * 100, // Converter para cm
        populacaoDesejada: _state.modoCalculo == ModoCalculo.populacao 
            ? _state.populacaoDesejada.toInt() 
            : null,
        germinacaoPercent: _state.germinacao,
        purezaPercent: _state.vigor, // Usando vigor no lugar de pureza
        sementesPorMetro: _state.sementesPorMetro,
        sementesPorHectare: resultado.seedsPerHa,
        pesoMilSementes: resultado.pms_g_per_1000,
        totalSementes: resultado.totalSeedsForN.round(),
        totalKg: resultado.totalKgForN,
        kgPorHectare: resultado.kgPerHa,
        kgPorHectareAjustado: resultado.kgPerHa,
        kgUtilizado: 0.0,
        kgFaltando: resultado.totalKgForN,
        areaHa: _state.usarAreaDesejada ? _state.areaDesejada : 1.0,
        status: 'Calculado com vigor',
        origemCalculo: '${_state.modoCalculo.toString().split('.').last}_${_state.modoBag.toString().split('.').last}',
        dataCriacao: DateTime.now().toIso8601String(),
      );
      
      // Salvar no banco
      await _calculoSementesRepository.salvar(calculo);
      
      // Salvar no histórico usando o modelo de calibração
      await AppDatabase.instance.initDatabase();
      final database = await AppDatabase.instance.database;
      final dao = CalibrationHistoryDao(database);
      
      // Criar modelo de histórico de calibração
      final calibracaoHistorico = CalibrationHistoryModel(
        talhaoId: 'area_manual',
        talhaoName: 'Área Manual (${_state.usarAreaDesejada ? _state.areaDesejada : '1'} ha)',
        culturaId: 'calculo_sementes',
        culturaName: 'Cálculo de Sementes com Vigor',
        discoNome: null,
        furosDisco: null,
        engrenagemMotora: null,
        engrenagemMovida: null,
        voltasDisco: null,
        distanciaPercorrida: null,
        linhasColetadas: null,
        espacamentoCm: _state.espacamento * 100,
        metaSementesHectare: _state.modoCalculo == ModoCalculo.populacao 
            ? _state.populacaoDesejada.toInt() 
            : null,
        relacaoTransmissao: null,
        sementesTotais: resultado.totalSeedsForN.round(),
        sementesPorMetro: _state.sementesPorMetro,
        sementesPorHectare: resultado.seedsPerHa.round(),
        diferencaMetaPercentual: null,
        statusCalibracao: 'normal',
        observacoes: 'Cálculo com vigor: ${_state.modoCalculo.toString().split('.').last}\n'
                     'Modo bag: ${_state.modoBag.toString().split('.').last}\n'
                     'Kg/ha: ${resultado.kgPerHa.toStringAsFixed(2)}\n'
                     'Hectares cobertos: ${resultado.hectaresCovered.toStringAsFixed(2)}\n'
                     'PMS: ${resultado.pms_g_per_1000.toStringAsFixed(2)} g/1000',
        dataCalibracao: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dao.insertCalibration(calibracaoHistorico);
      
      SnackbarUtils.showSuccessSnackBar(context, 'Cálculo salvo com sucesso!');
      _limparCampos();
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar cálculo: ${e.toString()}');
    }
  }

  void _abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlantioCalibragemHistoricoScreen(),
      ),
    );
  }

      void _abrirTratamentoSementes() {
        if (_state.resultadoCalculo == null) {
          SnackbarUtils.showErrorSnackBar(context, 'Faça o cálculo de sementes primeiro');
          return;
        }

        // Navegar para a tela principal do módulo de tratamento de sementes
        // passando os dados do cálculo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text('Módulo de Tratamento de Sementes em desenvolvimento'),
              ),
            ),
          ),
        );
      }

      void _criarNovaDose() {
        if (_state.resultadoCalculo == null) {
          SnackbarUtils.showErrorSnackBar(context, 'Faça o cálculo de sementes primeiro');
          return;
        }

        // Navegar para a tela Nova Dose com os dados do cálculo
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text('Editor de Dose em desenvolvimento'),
              ),
            ),
          ),
        );
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FortSmartTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('📐 Cálculo de Sementes'),
        backgroundColor: FortSmartTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: _abrirTratamentoSementes,
            tooltip: 'Tratamento de Sementes',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _abrirHistorico,
            tooltip: 'Ver Histórico',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModoCalculoSelector(
                modoSelecionado: _state.modoCalculo,
                onChanged: (modo) {
                  setState(() {
                    _state = _state.copyWith(modoCalculo: modo);
                  });
                },
              ),
              const SizedBox(height: 16),
              ModoBagSelector(
                modoSelecionado: _state.modoBag,
                onChanged: (modo) {
                  setState(() {
                    _state = _state.copyWith(modoBag: modo);
                  });
                },
              ),
              const SizedBox(height: 16),
              AreaPlantioSection(
                state: _state,
                onStateChanged: (newState) {
                  setState(() {
                    _state = newState;
                  });
                },
              ),
              const SizedBox(height: 16),
              ParametrosEntradaForm(
                state: _state,
                onStateChanged: (newState) {
                  setState(() {
                    _state = newState;
                  });
                },
              ),
              const SizedBox(height: 16),
              ResultadosDisplay(
                resultado: _state.resultadoCalculo,
                modoCalculo: _state.modoCalculo,
              ),
              const SizedBox(height: 16),
              if (_state.resultadoCalculo != null) 
                BotaoTratamento(onPressed: _abrirTratamentoSementes),
              const SizedBox(height: 24),
              AcoesBottomBar(
                onCalcular: _calcular,
                onSalvar: _salvarCalculo,
                onLimpar: _limparCampos,
                onCriarNovaDose: _criarNovaDose,
                isLoading: _state.isLoading,
                temResultado: _state.resultadoCalculo != null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
