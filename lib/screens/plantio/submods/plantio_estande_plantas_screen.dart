import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../utils/fortsmart_theme.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Importações dos modelos
import '../../../models/talhao_model.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/poligono_model.dart';
import '../../../database/models/estande_plantas_model.dart';
import '../../../database/repositories/estande_plantas_repository.dart';
import '../../../database/repositories/planting_cv_repository.dart';
import '../../../models/calibration_history_model.dart';
import '../../../database/daos/calibration_history_dao.dart';
import '../../../database/app_database.dart';
import 'plantio_calibragem_historico_screen.dart';
import '../../../services/data_cache_service.dart';
import '../../../services/talhao_unified_loader_service.dart';
import '../../../utils/snackbar_utils.dart';
import 'widgets/selecao_talhao_cultura_widget.dart';
import 'widgets/selecao_datas_widget.dart';
import '../../../services/talhao_module_service.dart';
import '../../../services/cultura_talhao_service.dart';
import '../../../services/farm_culture_sync_service.dart';
import '../../../services/database_service.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../providers/talhao_provider.dart';
import '../../../providers/cultura_provider.dart';
import '../../../widgets/planting_integrated_data_widget.dart';
import 'planting_cv/planting_cv_calculation_screen.dart';
import 'planting_quality_report_screen.dart';
import '../../../services/planting_quality_report_service.dart';
import '../../../services/planting_submodules_integration_service.dart';
import '../../../models/planting_quality_report_model.dart';
import '../../../models/planting_cv_model.dart';
import '../../../utils/logger.dart';
import '../../../services/planting_cv_persistence_service.dart';
import '../../../services/planting_integrated_analysis_service.dart';
import '../../../services/planting_cv_result_card_service.dart';
import '../../../services/plantio_loader_service.dart';

class PlantioEstandePlantasScreen extends StatefulWidget {
  final String? estandeId;
  
  const PlantioEstandePlantasScreen({Key? key, this.estandeId}) : super(key: key);

  @override
  State<PlantioEstandePlantasScreen> createState() => _PlantioEstandePlantasScreenState();
}

class _PlantioEstandePlantasScreenState extends State<PlantioEstandePlantasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataCacheService = DataCacheService();
  final _estandePlantasRepository = EstandePlantasRepository();
  final _plantingCVRepository = PlantingCVRepository();
  final _talhaoModuleService = TalhaoModuleService();
  final _culturaTalhaoService = CulturaTalhaoService();
  final _farmCultureSyncService = FarmCultureSyncService();
  final _talhaoRepository = TalhaoRepository();
  final _talhaoLoader = TalhaoUnifiedLoaderService();
  final _plantingQualityReportService = PlantingQualityReportService();
  final _integrationService = PlantingSubmodulesIntegrationService();
  final _cvPersistenceService = PlantingCVPersistenceService();
  final _integratedAnalysisService = PlantingIntegratedAnalysisService();
  
  // Controllers
  final _dataEmergenciaController = TextEditingController();
  final _dataAvaliacaoController = TextEditingController();
  final _metrosLinearesMedidosController = TextEditingController();
  // ❌ REMOVIDO: _plantasContadasController (campo de população removido da UI)
  final _espacamentoController = TextEditingController();
  final _populacaoIdealController = TextEditingController();
  
  // Novos controllers para os campos adicionais
  final _numeroPlantasController = TextEditingController();
  final _distanciaEntreLinhasController = TextEditingController();
  final _metrosQuadradosController = TextEditingController();
  final _sementesPorMetroDesejadoController = TextEditingController();
  
  // Controllers para múltiplas linhas
  final _numeroLinhasController = TextEditingController();
  final _plantasLinha1Controller = TextEditingController();
  final _plantasLinha2Controller = TextEditingController();
  final _plantasLinha3Controller = TextEditingController();
  final _plantasLinha4Controller = TextEditingController();
  final _plantasLinha5Controller = TextEditingController();
  final _comprimentoLinhaController = TextEditingController(); // Sem pré-preenchimento
  final _observacoesController = TextEditingController();
  
  // Controllers para comparação manual (ao invés de buscar do banco)
  final _populacaoEsperadaController = TextEditingController();
  final _plantasPorMetroEsperadoController = TextEditingController();
  final _cvEsperadoController = TextEditingController();
  
  // Variáveis de estado
  List<TalhaoModel> _talhoes = []; // Modelo novo
  List<AgriculturalProduct> _culturas = []; // Lista de culturas disponíveis
  TalhaoModel? _talhaoSelecionado; // Talhão selecionado
  
  // Dados reais calculados para o relatório
  PlantingCVModel? _plantingCVModel;
  EstandePlantasModel? _estandePlantasModel;
  AgriculturalProduct? _culturaSelecionada; // Cultura selecionada
  String _culturaManual = ''; // Cultura inserida manualmente
  int? _diasAposEmergencia;
  double? _plantasPorMetro;
  double? _plantasPorHectare;
  double? _populacaoIdeal;
  double? _eficiencia;
  List<String> _fotos = [];
  
  // Novas variáveis para os cálculos adicionais
  double? _sementesPorMetroReal;
  double? _sementesPorMetroEsperado;
  double? _porcentagemVariacaoSementes;
  double? _populacaoIdealCalculada;
  double? _populacaoEsperada;
  double? _porcentagemVariacaoPopulacao;
  
  // Variáveis para múltiplas linhas
  int _numeroLinhas = 1;
  List<int> _plantasPorLinha = [];
  double? _mediaPlantasPorLinha;
  double? _desvioPadraoPlantas;
  double? _coeficienteVariacao;
  bool _usarMultiplasLinhas = false;
  
  // Variáveis para comparação com CV%
  Map<String, dynamic>? _dadosCVExistentes;
  double? _cvEsperado;
  double? _plantasPorMetroEsperado;
  String _statusComparacao = '';
  
  // Variáveis de controle
  bool _isLoading = true;
  String? _estandeId;
  String? _errorMessage;
  
  // Método para calcular estatísticas agronômicas rigorosas
  void _calcularEstatisticasAgronomicas() {
    if (_plantasPorLinha.isEmpty) return;
    
    // Calcular média
    _mediaPlantasPorLinha = _plantasPorLinha.reduce((a, b) => a + b) / _plantasPorLinha.length;
    
    // Calcular desvio padrão
    double somaQuadrados = 0;
    for (int valor in _plantasPorLinha) {
      somaQuadrados += math.pow(valor - _mediaPlantasPorLinha!, 2);
    }
    _desvioPadraoPlantas = math.sqrt(somaQuadrados / (_plantasPorLinha.length - 1));
    
    // Calcular coeficiente de variação (%)
    _coeficienteVariacao = (_desvioPadraoPlantas! / _mediaPlantasPorLinha!) * 100;
  }
  
  // Método para coletar dados das múltiplas linhas
  void _coletarDadosMultiplasLinhas() {
    _plantasPorLinha.clear();
    
    List<TextEditingController> controllers = [
      _plantasLinha1Controller,
      _plantasLinha2Controller,
      _plantasLinha3Controller,
      _plantasLinha4Controller,
      _plantasLinha5Controller,
    ];
    
    for (int i = 0; i < _numeroLinhas && i < controllers.length; i++) {
      final texto = controllers[i].text.trim();
      if (texto.isNotEmpty) {
        final valor = int.tryParse(texto);
        if (valor != null && valor > 0) {
          _plantasPorLinha.add(valor);
        }
      }
    }
    
    if (_plantasPorLinha.isNotEmpty) {
      _calcularEstatisticasAgronomicas();
    }
  }

  /// Usa dados de CV% informados manualmente pelo usuário para comparação agronômica
  void _buscarDadosCVExistentes() {
    Logger.info('🔍 Usando dados de CV% informados manualmente pelo usuário...');
    
    try {
      // ✅ USAR APENAS OS VALORES INFORMADOS PELO USUÁRIO
      final cvText = _cvEsperadoController.text.replaceAll(',', '.');
      final plantasPorMetroText = _plantasPorMetroEsperadoController.text.replaceAll(',', '.');
      final populacaoText = _populacaoEsperadaController.text.replaceAll(',', '.');
      
      _cvEsperado = cvText.isNotEmpty ? double.tryParse(cvText) : null;
      _plantasPorMetroEsperado = plantasPorMetroText.isNotEmpty ? double.tryParse(plantasPorMetroText) : null;
      _populacaoEsperada = populacaoText.isNotEmpty ? double.tryParse(populacaoText) : null;
      
      if (_cvEsperado != null || _plantasPorMetroEsperado != null || _populacaoEsperada != null) {
        _dadosCVExistentes = {
          'cvPercentual': _cvEsperado,
          'plantasPorMetro': _plantasPorMetroEsperado,
          'populacaoHectare': _populacaoEsperada,
          'dataCalibracao': DateTime.now().toIso8601String(),
          'classificacao': 'INFORMADO MANUALMENTE',
        };
        
        Logger.info('✅ Dados informados pelo usuário:');
        Logger.info('  - CV% esperado: ${_cvEsperado?.toStringAsFixed(1)}%');
        Logger.info('  - Plantas/m esperadas: ${_plantasPorMetroEsperado?.toStringAsFixed(1)}');
        Logger.info('  - População/ha esperada: ${_populacaoEsperada?.toStringAsFixed(0)}');
      } else {
        Logger.info('💡 Nenhum dado de comparação informado');
        _dadosCVExistentes = null;
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao processar dados informados: $e');
      _dadosCVExistentes = null;
      _cvEsperado = null;
      _plantasPorMetroEsperado = null;
      _populacaoEsperada = null;
    }
  }
  
  /// Compara dados do estande real com dados de CV% esperados
  void _compararComDadosCV() {
    if (_dadosCVExistentes == null || _plantasPorMetro == null) return;
    
    Logger.info('📊 Iniciando comparação agronômica: Estande Real vs CV% Esperado');
    
    // Comparar plantas por metro
    double? diferencaPlantasPorMetro;
    if (_plantasPorMetroEsperado != null) {
      diferencaPlantasPorMetro = ((_plantasPorMetro! - _plantasPorMetroEsperado!) / _plantasPorMetroEsperado!) * 100;
    }
    
    // Comparar população por hectare
    double? diferencaPopulacao;
    if (_populacaoEsperada != null && _plantasPorHectare != null) {
      diferencaPopulacao = ((_plantasPorHectare! - _populacaoEsperada!) / _populacaoEsperada!) * 100;
    }
    
    // Comparar CV% (se temos dados de múltiplas linhas)
    double? diferencaCV;
    if (_coeficienteVariacao != null && _cvEsperado != null) {
      diferencaCV = _coeficienteVariacao! - _cvEsperado!;
    }
    
    // Determinar status da comparação
    String statusGeral = 'ANÁLISE';
    Color corStatus = Colors.blue;
    
    if (diferencaPlantasPorMetro != null && diferencaPopulacao != null) {
      double diferencaMedia = (diferencaPlantasPorMetro.abs() + diferencaPopulacao.abs()) / 2;
      
      if (diferencaMedia <= 5) {
        statusGeral = 'EXCELENTE';
        corStatus = Colors.green;
      } else if (diferencaMedia <= 15) {
        statusGeral = 'BOA';
        corStatus = Colors.orange;
      } else {
        statusGeral = 'ATENÇÃO';
        corStatus = Colors.red;
      }
    }
    
    _statusComparacao = '''
=== COMPARAÇÃO AGRONÔMICA ===
CV% Calibração: ${_cvEsperado?.toStringAsFixed(1)}%

Plantas/m Esperado: ${_plantasPorMetroEsperado?.toStringAsFixed(1)}
Plantas/m Real: ${_plantasPorMetro?.toStringAsFixed(1)}
${diferencaPlantasPorMetro != null ? 'Variação: ${diferencaPlantasPorMetro > 0 ? '+' : ''}${diferencaPlantasPorMetro.toStringAsFixed(1)}%' : ''}

População/ha Esperada: ${_populacaoEsperada?.toStringAsFixed(0)}
População/ha Real: ${_plantasPorHectare?.toStringAsFixed(0)}
${diferencaPopulacao != null ? 'Variação: ${diferencaPopulacao > 0 ? '+' : ''}${diferencaPopulacao.toStringAsFixed(1)}%' : ''}

STATUS GERAL: $statusGeral
''';
    
    Logger.info('📈 Comparação concluída - Status: $statusGeral');
    Logger.info('  - Diferença plantas/m: ${diferencaPlantasPorMetro?.toStringAsFixed(1)}%');
    Logger.info('  - Diferença população: ${diferencaPopulacao?.toStringAsFixed(1)}%');
    Logger.info('  - Diferença CV%: ${diferencaCV?.toStringAsFixed(1)}%');
  }

  // Método para calcular os resultados
  Future<void> _calcular() async {
    if (_formKey.currentState?.validate() != true) {
      SnackbarUtils.showErrorSnackBar(context, 'Por favor, corrija os campos com erro');
      return;
    }
    try {
      // Coletar dados das múltiplas linhas se habilitado
      if (_usarMultiplasLinhas) {
        _coletarDadosMultiplasLinhas();
      }
      
      // 📊 DADOS DE ENTRADA - Nomes claros e consistentes
      double plantasContadasArea;
      
      if (_usarMultiplasLinhas && _mediaPlantasPorLinha != null) {
        // Usar média das múltiplas linhas
        plantasContadasArea = _mediaPlantasPorLinha!;
      } else {
        // Usar contagem única
        plantasContadasArea = double.tryParse(_numeroPlantasController.text.replaceAll(',', '.')) ?? 0;
      }
      
      final distanciaEntreLinhasCm = double.tryParse(_distanciaEntreLinhasController.text.replaceAll(',', '.')) ?? 0;
      final areaMedidaM2 = double.tryParse(_metrosQuadradosController.text.replaceAll(',', '.')) ?? 0;
      final sementesPorMetroDesejado = double.tryParse(_sementesPorMetroDesejadoController.text.replaceAll(',', '.')) ?? 0;
      final populacaoIdealEsperada = double.tryParse(_populacaoIdealController.text.replaceAll(',', '.')) ?? 0;
      
      // ❌ REMOVIDO: espacamentoEntrePlantasCm - Campo irrelevante removido
      
      // Validação dos campos obrigatórios
      if (distanciaEntreLinhasCm <= 0) {
        SnackbarUtils.showErrorSnackBar(context, 'Distância entre linhas é obrigatória');
        return;
      }
      
      if (!_usarMultiplasLinhas && plantasContadasArea <= 0) {
        SnackbarUtils.showErrorSnackBar(context, 'Informe o número de plantas contadas');
        return;
      }
      
      if (_usarMultiplasLinhas && _plantasPorLinha.isEmpty) {
        SnackbarUtils.showErrorSnackBar(context, 'Informe o número de plantas em pelo menos uma linha');
        return;
      }
      
      // 🎯 CÁLCULOS AGRONÔMICOS CORRETOS
      // Baseados em fórmulas agronômicas padrão
      
      // 1. Conversão de cm para metros
      final distanciaEntreLinhasM = distanciaEntreLinhasCm / 100;
      
      // 2. Linhas por hectare
      final linhasPorHectare = 10000 / distanciaEntreLinhasM;
      
      // 3. ABORDAGEM 1: Contagem por área (m²) - MAIS PRECISA
      double plantasPorHectareFinal;
      double plantasPorMetroFinal;
      
      if (_usarMultiplasLinhas && _mediaPlantasPorLinha != null) {
        // ABORDAGEM MÚLTIPLAS LINHAS: Mais precisa estatisticamente
        
        // CORREÇÃO FUNDAMENTAL: Soma total das plantas ÷ comprimento total
        final comprimentoLinhaAmostrada = double.tryParse(_comprimentoLinhaController.text.replaceAll(',', '.')) ?? 1.0;
        final totalPlantas = _plantasPorLinha.reduce((a, b) => a + b); // Soma de todas as plantas
        final comprimentoTotal = _plantasPorLinha.length * comprimentoLinhaAmostrada; // Comprimento total das linhas
        
        // Plantas por metro = total de plantas ÷ comprimento total
        plantasPorMetroFinal = totalPlantas / comprimentoTotal;
        
        // Plantas por hectare = plantas/metro × linhas/hectare
        plantasPorHectareFinal = plantasPorMetroFinal * linhasPorHectare;
        
      } else if (plantasContadasArea > 0 && areaMedidaM2 > 0) {
        // ABORDAGEM 1: Contagem por área (m²)
        
        // Densidade real de plantas por m²
        final plantasPorM2 = plantasContadasArea / areaMedidaM2;
        
        // Plantas por hectare = plantas/m² × 10.000 m²/ha
        plantasPorHectareFinal = plantasPorM2 * 10000;
        
        // Plantas por metro = plantas/hectare ÷ linhas/hectare
        plantasPorMetroFinal = plantasPorHectareFinal / linhasPorHectare;
        
      } else {
        // Sem dados válidos - não deve chegar aqui por causa da validação
        SnackbarUtils.showErrorSnackBar(context, 'Dados insuficientes para o cálculo');
        return;
      }
      
      // 📈 CÁLCULOS DE EFICIÊNCIA
      // Eficiência = População Real / População Ideal Informada pelo usuário
      double? eficiencia;
      if (populacaoIdealEsperada > 0) {
        eficiencia = (plantasPorHectareFinal / populacaoIdealEsperada) * 100;
      }
      
      // ❌ REMOVIDO: Cálculo de "População Ideal Calculada" baseado em espaçamento
      // Motivo: O espaçamento entre plantas não é relevante para o ESTANDE
      // O estande mede a REALIDADE (plantas emergidas)
      // A "população ideal" deve ser informada pelo usuário ou vir do planejamento de plantio
      
      // Variáveis mantidas apenas para compatibilidade
      double? sementesPorMetroReal;
      double? sementesPorMetroEsperado;
      double? porcentagemVariacaoSementes;
      double? populacaoEsperada = populacaoIdealEsperada > 0 ? populacaoIdealEsperada : null;
      
      setState(() {
        _plantasPorMetro = plantasPorMetroFinal;
        _plantasPorHectare = plantasPorHectareFinal;
        _populacaoIdeal = populacaoIdealEsperada;
        _eficiencia = eficiencia;
        _sementesPorMetroReal = sementesPorMetroReal;
        _sementesPorMetroEsperado = sementesPorMetroEsperado;
        _porcentagemVariacaoSementes = porcentagemVariacaoSementes;
        _populacaoIdealCalculada = null; // ❌ REMOVIDO: não calculamos mais isso
        _populacaoEsperada = populacaoEsperada;
        _porcentagemVariacaoPopulacao = null; // ❌ REMOVIDO: cálculo irrelevante
        _diasAposEmergencia = _calcularDiasAposEmergencia();
      });
      
      // Buscar dados de CV% existentes e comparar automaticamente
      _buscarDadosCVExistentes(); // ✅ REMOVIDO await (método é void)
      _compararComDadosCV();
      
      SnackbarUtils.showSuccessSnackBar(context, 'Cálculo realizado com sucesso! Comparação com CV% executada.');
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao calcular: ${e.toString()}');
    }
  }

  int? _calcularDiasAposEmergencia() {
    if (_dataEmergenciaController.text.isEmpty || _dataAvaliacaoController.text.isEmpty) {
      return null;
    }
    try {
      final DateFormat format = DateFormat('dd/MM/yyyy');
      final DateTime dataEmergencia = format.parse(_dataEmergenciaController.text);
      final DateTime dataAvaliacao = format.parse(_dataAvaliacaoController.text);
      return dataAvaliacao.difference(dataEmergencia).inDays;
    } catch (e) {
      return null;
    }
  }

  void _limpar() {
    setState(() {
      _talhaoSelecionado = null;
      _culturaSelecionada = null;
      _culturaManual = '';
      _dataEmergenciaController.clear();
      _dataAvaliacaoController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _metrosLinearesMedidosController.clear();
      // ❌ REMOVIDO: _plantasContadasController (campo removido da UI)
      // ❌ REMOVIDO: _espacamentoController (campo removido)
      _populacaoIdealController.clear();
      _numeroPlantasController.clear();
      _distanciaEntreLinhasController.clear();
      _metrosQuadradosController.clear();
      _sementesPorMetroDesejadoController.clear();
      _numeroLinhasController.clear();
      _plantasLinha1Controller.clear();
      _plantasLinha2Controller.clear();
      _plantasLinha3Controller.clear();
      _plantasLinha4Controller.clear();
      _plantasLinha5Controller.clear();
      _diasAposEmergencia = null;
      _plantasPorMetro = null;
      _plantasPorHectare = null;
      _populacaoIdeal = null;
      _eficiencia = null;
      _sementesPorMetroReal = null;
      _sementesPorMetroEsperado = null;
      _porcentagemVariacaoSementes = null;
      _populacaoIdealCalculada = null;
      _populacaoEsperada = null;
      _porcentagemVariacaoPopulacao = null;
      _numeroLinhas = 1;
      _plantasPorLinha = [];
      _mediaPlantasPorLinha = null;
      _desvioPadraoPlantas = null;
      _coeficienteVariacao = null;
      _usarMultiplasLinhas = false;
      _dadosCVExistentes = null;
      _cvEsperado = null;
      _plantasPorMetroEsperado = null;
      _populacaoEsperada = null;
      _statusComparacao = '';
      _fotos = [];
    });
  }

  void _abrirHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlantioCalibragemHistoricoScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _dataAvaliacaoController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _carregarDados();
  }
  
  @override
  void dispose() {
    _dataEmergenciaController.dispose();
    _dataAvaliacaoController.dispose();
    _metrosLinearesMedidosController.dispose();
    // ❌ REMOVIDO: _plantasContadasController (campo removido da UI)
    // ❌ REMOVIDO: _espacamentoController (campo removido)
    _populacaoIdealController.dispose();
    _numeroPlantasController.dispose();
    _distanciaEntreLinhasController.dispose();
    _metrosQuadradosController.dispose();
    _sementesPorMetroDesejadoController.dispose();
    _numeroLinhasController.dispose();
    _plantasLinha1Controller.dispose();
    _plantasLinha2Controller.dispose();
    _plantasLinha3Controller.dispose();
    _plantasLinha4Controller.dispose();
    _plantasLinha5Controller.dispose();
    _comprimentoLinhaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }
  
  ProductType _getProductTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'seed':
      case 'semente':
        return ProductType.seed;
      case 'fertilizer':
      case 'fertilizante':
        return ProductType.fertilizer;
      case 'pesticide':
      case 'pesticida':
        return ProductType.herbicide; // Usando herbicide como fallback para pesticide
      default:
        return ProductType.other;
    }
  }
  
  Future<void> _carregarDados() async {
    try {
      print('🌱 Iniciando carregamento de dados do módulo estande de plantas...');
      
      // Carregar talhões do módulo Talhões
      print('📋 Carregando talhões do módulo Talhões...');
      await _carregarTalhoes();
      
      // Carregar culturas do módulo Culturas da Fazenda
      print('🌾 Carregando culturas do módulo Culturas da Fazenda...');
      await _carregarCulturas();
      
      if (widget.estandeId != null) {
        await _carregarEstande();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      
      print('✅ Dados carregados com sucesso!');
      print('  - Talhões: ${_talhoes.length}');
      print('  - Culturas: ${_culturas.length}');
      
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: ${e.toString()}';
        });
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados: ${e.toString()}');
      }
    }
  }
  
  // Carregar talhões do módulo Talhões
  Future<void> _carregarTalhoes() async {
    try {
      print('🔄 Carregando talhões reais do módulo Talhões...');
      
      // Primeiro, tentar carregar do TalhaoUnifiedService (mais confiável)
      try {
        print('🔄 Tentativa 1: Carregando do TalhaoUnifiedService...');
        final talhoesUnificados = await _talhaoLoader.carregarTalhoesParaModulo(
          nomeModulo: 'Estande de Plantas',
          forceRefresh: true,
        );
        
        if (talhoesUnificados.isNotEmpty) {
          _talhoes = talhoesUnificados;
          print('✅ ${talhoesUnificados.length} talhões carregados do TalhaoUnifiedService');
          for (var talhao in talhoesUnificados) {
            print('  - ${talhao.name} (ID: ${talhao.id})');
          }
          return; // Sair se conseguiu carregar do serviço unificado
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoUnifiedService: $e');
      }
      
      // Segundo, tentar carregar do TalhaoProvider
      try {
        print('🔄 Tentativa 2: Carregando do TalhaoProvider...');
        final talhaoProvider = Provider.of<TalhaoProvider>(context, listen: false);
        await talhaoProvider.carregarTalhoes();
        
        if (talhaoProvider.talhoes.isNotEmpty) {
          // Converter TalhaoSafraModel para TalhaoModel
          final talhoesConvertidos = talhaoProvider.talhoes.map((talhaoSafra) => TalhaoModel(
            id: talhaoSafra.id,
            name: talhaoSafra.nome,
            area: talhaoSafra.area,
            poligonos: [PoligonoModel(
              id: '1',
              pontos: talhaoSafra.pontos,
              area: talhaoSafra.area,
              perimetro: talhaoSafra.perimetro,
              dataCriacao: talhaoSafra.dataCriacao,
              dataAtualizacao: DateTime.now(),
              ativo: true,
              talhaoId: talhaoSafra.id,
            )],
            dataCriacao: talhaoSafra.dataCriacao,
            dataAtualizacao: DateTime.now(),
            safras: [],
          )).toList();
          
          _talhoes = talhoesConvertidos;
          print('✅ ${talhaoProvider.talhoes.length} talhões carregados do TalhaoProvider');
          for (var talhao in talhaoProvider.talhoes) {
            print('  - ${talhao.nome} (ID: ${talhao.id})');
          }
          return; // Sair se conseguiu carregar do provider
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoProvider: $e');
      }
      
      // Terceiro, tentar carregar do TalhaoModuleService
      try {
        print('🔄 Tentativa 3: Carregando do TalhaoModuleService...');
        await _talhaoModuleService.initialize();
        _talhoes = await _talhaoModuleService.getTalhoes();
        if (_talhoes.isNotEmpty) {
          print('✅ ${_talhoes.length} talhões carregados do TalhaoModuleService');
          return; // Sair se conseguiu carregar do serviço
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoModuleService: $e');
      }
      
      // Quarto, tentar carregar do TalhaoRepository
      try {
        print('🔄 Tentativa 4: Carregando do TalhaoRepository...');
        _talhoes = await _talhaoRepository.getTalhoes();
        if (_talhoes.isNotEmpty) {
          print('✅ ${_talhoes.length} talhões carregados do TalhaoRepository');
          return; // Sair se conseguiu carregar do repositório
        }
      } catch (e) {
        print('❌ Erro ao carregar do TalhaoRepository: $e');
      }
      
      // Quinto, tentar carregar diretamente do banco de dados
      try {
        print('🔄 Tentativa 5: Carregando talhões diretamente do banco...');
        _talhoes = await _carregarTalhoesDiretoBanco();
        if (_talhoes.isNotEmpty) {
          print('✅ ${_talhoes.length} talhões carregados diretamente do banco');
          return;
        }
      } catch (e) {
        print('❌ Erro ao carregar diretamente do banco: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhum talhão real
      print('❌ Nenhum talhão real encontrado em nenhuma fonte');
      _talhoes = []; // Lista vazia em vez de fallback
      
    } catch (e) {
      print('❌ Erro geral ao carregar talhões: $e');
      _talhoes = []; // Lista vazia em vez de fallback
    }
  }
  
  /// Carrega talhões diretamente do banco de dados
  Future<List<TalhaoModel>> _carregarTalhoesDiretoBanco() async {
    try {
      print('🔄 Acessando banco de dados diretamente...');
      
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      
      // Lista de possíveis tabelas de talhões
      final possiveisTabelas = [
        'talhoes',
        'talhao_safra',
        'talhoes_safras',
        'talhao',
        'plots',
      ];
      
      List<Map<String, dynamic>> talhoesData = [];
      String tabelaUsada = '';
      
      // Tentar cada tabela possível
      for (final tabela in possiveisTabelas) {
        try {
          final tableExists = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$tabela'"
          );
          
          if (tableExists.isNotEmpty) {
            print('🔍 Tabela encontrada: $tabela');
            talhoesData = await db.query(tabela);
            tabelaUsada = tabela;
            print('📊 Registros encontrados na tabela $tabela: ${talhoesData.length}');
            break; // Sair do loop se encontrou dados
          }
        } catch (e) {
          print('⚠️ Erro ao verificar tabela $tabela: $e');
          continue;
        }
      }
      
      if (talhoesData.isEmpty) {
        print('❌ Nenhuma tabela de talhões encontrada');
        return [];
      }
      
      // Converter para TalhaoModel
      final talhoes = talhoesData.map((data) {
        // Tentar diferentes campos de nome
        String nome = '';
        if (data['nome'] != null) {
          nome = data['nome'].toString();
        } else if (data['name'] != null) {
          nome = data['name'].toString();
        } else if (data['nome_talhao'] != null) {
          nome = data['nome_talhao'].toString();
        } else {
          nome = 'Talhão sem nome';
        }
        
        // Tentar diferentes campos de área
        double area = 0.0;
        if (data['area'] != null) {
          area = (data['area'] as num?)?.toDouble() ?? 0.0;
        } else if (data['area_ha'] != null) {
          area = (data['area_ha'] as num?)?.toDouble() ?? 0.0;
        }
        
        // Tentar diferentes campos de data
        DateTime dataCriacao = DateTime.now();
        if (data['created_at'] != null) {
          dataCriacao = DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now();
        } else if (data['data_criacao'] != null) {
          dataCriacao = DateTime.tryParse(data['data_criacao'].toString()) ?? DateTime.now();
        } else if (data['createdAt'] != null) {
          dataCriacao = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
        }
        
        return TalhaoModel(
          id: data['id']?.toString() ?? '',
          name: nome,
          area: area,
          poligonos: [],
          dataCriacao: dataCriacao,
          dataAtualizacao: DateTime.now(),
          safras: [],
          sincronizado: false,
        );
      }).toList();
      
      print('✅ ${talhoes.length} talhões convertidos com sucesso da tabela $tabelaUsada');
      for (var talhao in talhoes) {
        print('  - ${talhao.name} (ID: ${talhao.id}, Área: ${talhao.area} ha)');
      }
      
      return talhoes;
    } catch (e) {
      print('❌ Erro ao carregar talhões do banco: $e');
      return [];
    }
  }
  
  // Carregar culturas do módulo Culturas da Fazenda
  Future<void> _carregarCulturas() async {
    try {
      print('🔄 Iniciando carregamento de culturas para estande...');
      
      // Primeiro, tentar carregar do CulturaProvider (método unificado)
      print('🔄 Tentando carregar culturas do CulturaProvider...');
      try {
        final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
        final culturasProvider = await culturaProvider.getCulturasParaPlantio();
        
        if (culturasProvider.isNotEmpty) {
          _culturas = culturasProvider.map((cultura) => AgriculturalProduct(
            id: cultura.id,
            name: cultura.name,
            description: cultura.description ?? '',
            type: ProductType.seed,
            colorValue: _obterCorSegura(cultura.color.value.toString()).value.toRadixString(16).padLeft(8, '0'),
          )).toList();
          print('✅ ${_culturas.length} culturas carregadas do CulturaProvider');
          
          // Log detalhado das culturas
          for (int i = 0; i < _culturas.length; i++) {
            final cultura = _culturas[i];
            print('  ${i + 1}. ${cultura.name} (ID: ${cultura.id})');
          }
          return; // Sair se conseguiu carregar do provider
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaProvider: $e');
      }
      
      // Fallback: tentar carregar do serviço de cultura da fazenda
      print('🔄 Tentando carregar culturas do CulturaTalhaoService (fallback)...');
      try {
        final culturasData = await _culturaTalhaoService.listarCulturas();
        
        if (culturasData.isNotEmpty) {
          _culturas = culturasData.map((cultura) => AgriculturalProduct(
            id: cultura['id']?.toString() ?? '',
            name: cultura['nome']?.toString() ?? 'Cultura',
            description: cultura['descricao']?.toString() ?? '',
            type: ProductType.seed,
            colorValue: cultura['cor']?.toString() ?? '#4CAF50',
          )).toList();
          print('✅ ${_culturas.length} culturas carregadas do CulturaTalhaoService (fallback)');
          
          // Log detalhado das culturas
          for (int i = 0; i < _culturas.length; i++) {
            final cultura = _culturas[i];
            print('  ${i + 1}. ${cultura.name} (ID: ${cultura.id})');
          }
          return; // Sair se conseguiu carregar do serviço
        }
      } catch (e) {
        print('❌ Erro ao carregar do CulturaTalhaoService: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar nenhuma cultura real
      print('❌ Nenhuma cultura real encontrada em nenhuma fonte');
      print('🔍 Verificando se o módulo Culturas da Fazenda está configurado...');
      
      // Tentar uma última vez com uma abordagem mais direta
      try {
        print('🔄 Tentativa final: carregando culturas diretamente do DataCacheService...');
        final culturasCache = await _dataCacheService.getCulturas();
        if (culturasCache.isNotEmpty) {
          // culturasCache já retorna AgriculturalProduct, não precisa converter
          _culturas = culturasCache;
          print('✅ ${_culturas.length} culturas carregadas do DataCacheService (tentativa final)');
          return;
        }
      } catch (e) {
        print('❌ Erro na tentativa final de carregar culturas: $e');
      }
      
      _culturas = []; // Lista vazia em vez de fallback
      print('ℹ️ Nenhuma cultura disponível - verifique se o módulo Culturas da Fazenda está configurado');
      
    } catch (e) {
      print('❌ Erro geral ao carregar culturas: $e');
      _culturas = []; // Lista vazia em vez de fallback
    }
  }
  

  

  
  Future<void> _carregarEstande() async {
    if (widget.estandeId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final estande = await _estandePlantasRepository.buscarPorId(widget.estandeId!);
      
      if (estande == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          SnackbarUtils.showErrorSnackBar(context, 'Estande não encontrado');
        }
        return;
      }
      
      _talhaoSelecionado = _talhoes.firstWhere(
        (t) => t.id == estande.talhaoId,
        orElse: () => TalhaoModel(
          id: '0',
          name: 'Desconhecido',
          poligonos: const [],
          area: 0.0,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          safras: [],
          sincronizado: false,
        ),
      );
      
      _culturaSelecionada = _culturas.isNotEmpty ? _culturas.firstWhere(
        (c) => c.id.toString() == estande.culturaId,
        orElse: () => _culturas.first,
      ) : null;
      
      if (mounted) {
        setState(() {
          _estandeId = estande.id;
          _dataEmergenciaController.text = estande.dataEmergencia != null ? DateFormat('dd/MM/yyyy').format(estande.dataEmergencia!) : '';
          _dataAvaliacaoController.text = estande.dataAvaliacao != null ? DateFormat('dd/MM/yyyy').format(estande.dataAvaliacao!) : '';
          _metrosLinearesMedidosController.text = estande.metrosLinearesMedidos.toString();
          // ❌ REMOVIDO: _plantasContadasController (campo removido da UI)
          _espacamentoController.text = estande.espacamento.toString();
          _diasAposEmergencia = estande.diasAposEmergencia;
          _plantasPorMetro = estande.plantasPorMetro;
          _plantasPorHectare = estande.plantasPorHectare;
          _populacaoIdeal = estande.populacaoIdeal;
          _eficiencia = estande.eficiencia;
          _populacaoIdealController.text = estande.populacaoIdeal?.toString() ?? '';
          _fotos = List<String>.from(estande.fotos);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar estande: ${e.toString()}');
      }
    }
  }

  Future<void> _selecionarTalhao() async {
    try {
      if (_talhoes.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nenhum Talhão Encontrado'),
            content: const Text(
              'Não foram encontrados talhões cadastrados no módulo Talhões. '
              'Por favor, cadastre pelo menos um talhão antes de continuar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _recarregarTalhoes();
                },
                child: const Text('Recarregar'),
              ),
            ],
          ),
        );
        return;
      }

      if (!mounted) return;

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
                  title: Text(talhao.name),
                  subtitle: Text('Área: ${talhao.area?.toStringAsFixed(2) ?? '-'} ha'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      talhao.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarTalhaoCallback(talhao);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar talhões: ${e.toString()}');
      }
    }
  }
  
  Future<void> _selecionarTalhaoCallback(TalhaoModel talhao) async {
    setState(() {
      _talhaoSelecionado = talhao;
      _culturaSelecionada = null;
    });
    
    // Se o talhão tiver cultura associada, selecionar automaticamente
    if (talhao.cropId != null) {
      final culturaPadrao = _culturas.isNotEmpty ? _culturas.firstWhere(
        (c) => c.id.toString() == talhao.cropId.toString(),
        orElse: () => _culturas.first,
      ) : null;
      
      if (culturaPadrao != null) {
        setState(() {
          _culturaSelecionada = culturaPadrao;
        });
      }
    }
  }

  /// Recarrega os talhões manualmente
  Future<void> _recarregarTalhoes() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('🔄 Recarregando talhões manualmente...');
      await _carregarTalhoes();
      
      setState(() {
        _isLoading = false;
      });
      
      if (_talhoes.isNotEmpty) {
        SnackbarUtils.showSuccessSnackBar(context, '${_talhoes.length} talhões carregados com sucesso!');
      } else {
        SnackbarUtils.showErrorSnackBar(context, 'Nenhum talhão encontrado. Verifique se há talhões cadastrados no módulo Talhões.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao recarregar talhões: ${e.toString()}');
    }
  }
  
  void _selecionarCultura() {
    if (_culturas.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nenhuma Cultura Encontrada'),
          content: const Text(
            'Não foram encontradas culturas cadastradas no módulo Culturas da Fazenda. '
            'Por favor, use a entrada manual para digitar o nome da cultura.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    try {
      showDialog(
        context: context,
        builder: (context) {
          String buscaCultura = '';
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Selecionar Cultura'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400, // Altura fixa para evitar problemas de layout
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar cultura',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          buscaCultura = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _culturas.where((c) => (c.name ?? '').toLowerCase().contains(buscaCultura.toLowerCase())).length,
                        itemBuilder: (context, index) {
                          final listaFiltrada = _culturas.where((c) => (c.name ?? '').toLowerCase().contains(buscaCultura.toLowerCase())).toList();
                          final cultura = listaFiltrada[index];
                          
                          // Função simplificada para obter cor
                          Color corCultura = _obterCorSegura(cultura.colorValue);
                          
                          return ListTile(
                            title: Text(cultura.name ?? 'Sem nome'),
                            leading: CircleAvatar(
                              backgroundColor: corCultura,
                              child: const Icon(Icons.grass, color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _selecionarCulturaCallback(cultura);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('❌ Erro ao abrir diálogo de seleção de cultura: $e');
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao abrir seleção de cultura: ${e.toString()}');
    }
  }
  
  /// Função segura para obter cor da cultura
  Color _obterCorSegura(String? colorValue) {
    if (colorValue == null || colorValue.isEmpty) {
      return Colors.green; // Cor padrão
    }
    
    try {
      String colorString = colorValue.trim();
      
      // Se começa com #
      if (colorString.startsWith('#')) {
        String hex = colorString.substring(1);
        if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
          return Color(int.parse('0xFF$hex'));
        } else if (RegExp(r'^[0-9A-Fa-f]{3}$').hasMatch(hex)) {
          // Expandir cores de 3 dígitos
          hex = hex.split('').map((c) => c + c).join();
          return Color(int.parse('0xFF$hex'));
        }
      }
      // Se começa com 0x
      else if (colorString.startsWith('0x')) {
        if (RegExp(r'^0x[0-9A-Fa-f]{8}$').hasMatch(colorString)) {
          return Color(int.parse(colorString));
        }
      }
      // Se é apenas um número
      else if (RegExp(r'^[0-9]+$').hasMatch(colorString)) {
        return Color(int.parse(colorString));
      }
    } catch (e) {
      print('❌ Erro ao parsear cor: "$colorValue" - $e');
    }
    
    return Colors.green; // Cor padrão em caso de erro
  }

  Future<void> _selecionarCulturaCallback(AgriculturalProduct cultura) async {
    if (mounted) {
      setState(() {
        _culturaSelecionada = cultura;
      });
    }
  }

  void _onCulturaManualChanged(String cultura) {
    setState(() {
      _culturaManual = cultura;
      // Limpar cultura selecionada quando usar entrada manual
      _culturaSelecionada = null;
    });
  }
  
  // Método removido pois não estava sendo usado
  
  Widget _buildSelecaoTalhaoCultura() {
    // Debug: Verificar se os dados estão carregados
    print('🔍 Debug _buildSelecaoTalhaoCultura:');
    print('  - _talhoes.length: ${_talhoes.length}');
    print('  - _culturas.length: ${_culturas.length}');
    print('  - _talhaoSelecionado: ${_talhaoSelecionado?.name ?? 'null'}');
    print('  - _culturaSelecionada: ${_culturaSelecionada?.name ?? 'null'}');
    print('  - _culturaManual: $_culturaManual');
    
    return SelecaoTalhaoCulturaWidget(
      talhaoSelecionado: _talhaoSelecionado,
      culturaSelecionada: _culturaSelecionada,
      onSelecionarTalhao: _selecionarTalhao,
      onSelecionarCultura: _selecionarCultura,
      onCulturaManualChanged: _onCulturaManualChanged,
    );
  }

  Widget _buildSelecaoDatas() {
    return SelecaoDatasWidget(
      dataEmergenciaController: _dataEmergenciaController,
      dataAvaliacaoController: _dataAvaliacaoController,
      diasAposEmergencia: _diasAposEmergencia,
      onDataEmergenciaSelecionada: _selecionarDataEmergencia,
      onDataAvaliacaoSelecionada: _selecionarDataAvaliacao,
      calcularDiasAposEmergencia: _calcularDiasAposEmergencia,
    );
  }
  
  void _selecionarDataEmergencia(String data) {
    setState(() {
      _dataEmergenciaController.text = data;
      _diasAposEmergencia = _calcularDiasAposEmergencia();
    });
  }
  
  void _selecionarDataAvaliacao(String data) {
    setState(() {
      _dataAvaliacaoController.text = data;
      _diasAposEmergencia = _calcularDiasAposEmergencia();
    });
  }
  

  
  Widget _buildMultiplasLinhas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Contagem por Múltiplas Linhas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _usarMultiplasLinhas,
                  onChanged: (value) {
                    setState(() {
                      _usarMultiplasLinhas = value;
                      if (value) {
                        _numeroLinhas = 3; // Padrão para 3 linhas
                        _numeroLinhasController.text = '3';
                      } else {
                        _plantasPorLinha.clear();
                        _mediaPlantasPorLinha = null;
                        _desvioPadraoPlantas = null;
                        _coeficienteVariacao = null;
                      }
                    });
                  },
                ),
              ],
            ),
            
            if (_usarMultiplasLinhas) ...[
              const SizedBox(height: 16),
              
              // Card informativo sobre cálculos agronômicos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Cálculos Agronômicos Rigorosos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                      const Text(
                        '• Estique a trena em cada linha (ex: 5 metros)\n'
                        '• Conte plantas vivas na distância da trena\n'
                        '• Soma total de plantas ÷ comprimento total\n'
                        '• Exemplo: 158 plantas ÷ 15 metros = 10,53 plantas/metro\n'
                        '• Para análise de CV%, use a tela específica de cálculo de CV%',
                        style: TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Comprimento das linhas amostradas
              TextFormField(
                controller: _comprimentoLinhaController,
                decoration: const InputDecoration(
                  labelText: 'Comprimento de cada linha (trena esticada)',
                  hintText: 'Ex: 5.0 (apenas exemplo)',
                  helperText: 'Comprimento em metros da trena esticada para contagem em cada linha',
                  suffixText: 'm',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o comprimento das linhas';
                  }
                  final comprimento = double.tryParse(value);
                  if (comprimento == null || comprimento <= 0) {
                    return 'Comprimento deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Número de linhas
              TextFormField(
                controller: _numeroLinhasController,
                decoration: const InputDecoration(
                  labelText: 'Número de linhas contadas',
                  hintText: 'Ex: 3',
                  helperText: 'Mínimo 2, máximo 5 linhas para análise estatística',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (_usarMultiplasLinhas) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o número de linhas';
                    }
                    final numero = int.tryParse(value);
                    if (numero == null || numero < 2 || numero > 5) {
                      return 'Número deve ser entre 2 e 5';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  final numero = int.tryParse(value);
                  if (numero != null && numero >= 2 && numero <= 5) {
                    setState(() {
                      _numeroLinhas = numero;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Campos para cada linha
              ...List.generate(_numeroLinhas, (index) {
                final controller = [
                  _plantasLinha1Controller,
                  _plantasLinha2Controller,
                  _plantasLinha3Controller,
                  _plantasLinha4Controller,
                  _plantasLinha5Controller,
                ][index];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Plantas na linha ${index + 1}',
                      hintText: 'Ex: 95',
                      helperText: 'Número de plantas vivas encontradas na linha ${index + 1}',
                      prefixIcon: const Icon(Icons.eco),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (_usarMultiplasLinhas && index < _numeroLinhas) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o número de plantas da linha ${index + 1}';
                        }
                        final numero = int.tryParse(value);
                        if (numero == null || numero <= 0) {
                          return 'Valor inválido';
                        }
                      }
                      return null;
                    },
                  ),
                );
              }),
              
              // Resultados básicos (sem CV% - calculado em outra tela)
              if (_mediaPlantasPorLinha != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados Coletados',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Média das linhas:'),
                          Text(
                            '${_mediaPlantasPorLinha!.toStringAsFixed(1)} plantas/linha',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💡 Para análise estatística completa (CV%, desvio padrão), use a tela específica de cálculo de CV%',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntradaDados() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados da Medição',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Card informativo com instruções
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Instruções de Cálculo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MÉTODO RECOMENDADO - Contagem por Área (m²):\n'
                    '• Conte plantas vivas em uma área conhecida\n'
                    '• Meça distância entre linhas de plantio\n'
                    '• Sistema calcula densidade por m² e converte para ha\n'
                    '• Dados reais para relatório preciso',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Número de plantas (apenas quando não usar múltiplas linhas)
            if (!_usarMultiplasLinhas)
              TextFormField(
                controller: _numeroPlantasController,
                decoration: const InputDecoration(
                  labelText: 'Plantas contadas na área medida',
                  hintText: 'Ex: 120',
                  helperText: 'Total de plantas vivas encontradas na área medida (m²)',
                  prefixIcon: Icon(Icons.eco),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (!_usarMultiplasLinhas) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o número de plantas';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Valor inválido';
                    }
                  }
                  return null;
                },
              ),
            const SizedBox(height: 12),
            
            // Distância entre linhas
            TextFormField(
              controller: _distanciaEntreLinhasController,
              decoration: const InputDecoration(
                labelText: 'Distância entre linhas',
                hintText: 'Ex: 45',
                helperText: 'Espaçamento entre as linhas de plantio',
                suffixText: 'cm',
                prefixIcon: Icon(Icons.straighten),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a distância entre linhas';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // ❌ REMOVIDO: Campo "Espaçamento entre plantas" - irrelevante para cálculo real
            // O estande é calculado apenas pela contagem real de plantas nas linhas
            
            
            
            // Metros quadrados feito a contagem
            TextFormField(
              controller: _metrosQuadradosController,
              decoration: const InputDecoration(
                labelText: 'Área medida para contagem',
                hintText: 'Ex: 2,5',
                helperText: 'Área em metros quadrados onde foi feita a contagem',
                suffixText: 'm²',
                prefixIcon: Icon(Icons.crop_square),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe os metros quadrados';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // ❌ CAMPO REMOVIDO: População (sementes)
            // Motivo: Informação desnecessária - já temos a opção de inserir população de cada linha
            
            // Sementes por metro desejado
            TextFormField(
              controller: _sementesPorMetroDesejadoController,
              decoration: const InputDecoration(
                labelText: 'Sementes por metro desejado',
                hintText: 'Ex: 12',
                helperText: 'Meta de sementes por metro linear (opcional)',
                prefixIcon: Icon(Icons.grain),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Valor inválido';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPopulacaoIdeal() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'População Ideal (plantas/ha)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _populacaoIdealController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Informe a população ideal',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Informe um valor válido';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosComparacao() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Dados para Comparação (opcional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Informe os valores esperados para comparar com o estande real',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            
            // CV% Esperado
            TextFormField(
              controller: _cvEsperadoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'CV% da Calibração (%)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.assessment, color: Colors.blue.shade700),
              ),
              onChanged: (value) {
                setState(() {
                  _buscarDadosCVExistentes();
                  _compararComDadosCV();
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Plantas/m Esperadas
            TextFormField(
              controller: _plantasPorMetroEsperadoController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Plantas/m Esperadas',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.grass, color: Colors.green.shade700),
              ),
              onChanged: (value) {
                setState(() {
                  _buscarDadosCVExistentes();
                  _compararComDadosCV();
                });
              },
            ),
            const SizedBox(height: 12),
            
            // População Esperada
            TextFormField(
              controller: _populacaoEsperadaController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'População/ha Esperada',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.area_chart, color: Colors.orange.shade700),
              ),
              onChanged: (value) {
                setState(() {
                  _buscarDadosCVExistentes();
                  _compararComDadosCV();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Resultados básicos
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  // Indicador da abordagem usada
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _usarMultiplasLinhas 
                          ? 'ABORDAGEM MÚLTIPLAS LINHAS'
                          : (_numeroPlantasController.text.isNotEmpty && double.tryParse(_numeroPlantasController.text) != null && double.tryParse(_numeroPlantasController.text)! > 0
                              ? 'MÉTODO: Contagem por Área (m²)'
                              : 'MÉTODO: Múltiplas Linhas'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plantas por Metro:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _plantasPorMetro != null
                            ? NumberFormat('0.00').format(_plantasPorMetro)
                            : '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plantas por Hectare:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _plantasPorHectare != null
                            ? NumberFormat('#,###').format(_plantasPorHectare)
                            : '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Eficiência:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _eficiencia != null
                            ? '${NumberFormat('0.00').format(_eficiencia)}%'
                            : '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _eficiencia != null
                              ? (_eficiencia! >= 90 ? Colors.green : (_eficiencia! >= 70 ? Colors.orange : Colors.red))
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Resultados de sementes
            if (_sementesPorMetroReal != null || _sementesPorMetroEsperado != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sementes por Metro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Real:'),
                        Text(
                          _sementesPorMetroReal != null
                              ? NumberFormat('0.00').format(_sementesPorMetroReal)
                              : '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Esperado:'),
                        Text(
                          _sementesPorMetroEsperado != null
                              ? NumberFormat('0.00').format(_sementesPorMetroEsperado)
                              : '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_porcentagemVariacaoSementes != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Variação:'),
                          Text(
                            '${_porcentagemVariacaoSementes! > 0 ? '+' : ''}${NumberFormat('0.00').format(_porcentagemVariacaoSementes)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _porcentagemVariacaoSementes!.abs() <= 10 
                                  ? Colors.green 
                                  : _porcentagemVariacaoSementes!.abs() <= 20 
                                      ? Colors.orange 
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // ❌ REMOVIDO: Card "População Ideal"
            // Motivo: Cálculos baseados em espaçamento entre plantas são irrelevantes
            // O estande mede a REALIDADE (contagem real de plantas emergidas)
            // A variação mostrada (-92.83%) era um erro matemático grotesco
            // O CV% já vem calculado corretamente do submódulo de CV%
            
            // Seção de comparação com CV% (dados de calibração)
            if (_dadosCVExistentes != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare_arrows, color: Colors.indigo.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Comparação com Dados de CV% (Calibração)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // CV% da Calibração
                    if (_cvEsperado != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CV% Calibração:'),
                          Text(
                            '${_cvEsperado!.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Plantas por metro
                    if (_plantasPorMetroEsperado != null && _plantasPorMetro != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Plantas/m Esperado:'),
                          Text(
                            '${_plantasPorMetroEsperado!.toStringAsFixed(1)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Plantas/m Real:'),
                          Text(
                            '${_plantasPorMetro!.toStringAsFixed(1)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // População por hectare
                    if (_populacaoEsperada != null && _plantasPorHectare != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('População/ha Esperada:'),
                          Text(
                            '${_populacaoEsperada!.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('População/ha Real:'),
                          Text(
                            '${_plantasPorHectare!.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Status da comparação
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _statusComparacao,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Seção específica para múltiplas linhas (dados básicos apenas)
            if (_usarMultiplasLinhas && _mediaPlantasPorLinha != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados das Múltiplas Linhas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Linhas analisadas:'),
                        Text(
                          '$_numeroLinhas linhas',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Média das linhas:'),
                        Text(
                          '${_mediaPlantasPorLinha!.toStringAsFixed(1)} plantas/linha',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '💡 Para análise estatística completa (CV%, desvio padrão, uniformidade), use a tela específica de cálculo de CV%',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFotos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fotos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selecionarFotos,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FortSmartTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _fotos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhuma foto adicionada',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fotos.length,
                      itemBuilder: (context, index) {
                        // Verificar se o caminho da foto é válido
                        final String fotoPath = _fotos[index] ?? '';
                        final File imageFile = File(fotoPath);
                        final bool fileExists = imageFile.existsSync();
                        
                        print('🖼️ Verificando foto: $fotoPath');
                        print('📁 Arquivo existe: $fileExists');
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: fileExists ? () => _visualizarFoto(fotoPath) : null,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: fileExists
                                    ? Image.file(
                                        imageFile,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Erro ao carregar imagem: $error');
                                          print('❌ Stack trace: $stackTrace');
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.broken_image,
                                                  color: Colors.red,
                                                  size: 30,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Erro',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.image_not_supported,
                                              color: Colors.red,
                                              size: 30,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Não encontrado',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () => _removerFoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  Future<bool> _verificarPermissoes() async {
    print('🔐 Verificando permissões...');
    
    // Verificar permissão da câmera
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      print('📷 Permissão da câmera não concedida, solicitando...');
      final cameraResult = await Permission.camera.request();
      if (!cameraResult.isGranted) {
        print('❌ Permissão da câmera negada');
        if (mounted) {
          SnackbarUtils.showErrorSnackBar(
            context, 
            'Permissão da câmera é necessária para tirar fotos'
          );
        }
        return false;
      }
    }
    
    // Verificar permissão de armazenamento (Android 13+)
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          print('📸 Permissão de fotos não concedida, solicitando...');
          final photosResult = await Permission.photos.request();
          if (!photosResult.isGranted) {
            print('❌ Permissão de fotos negada');
            if (mounted) {
              SnackbarUtils.showErrorSnackBar(
                context, 
                'Permissão de acesso às fotos é necessária'
              );
            }
            return false;
          }
        }
      } else {
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          print('💾 Permissão de armazenamento não concedida, solicitando...');
          final storageResult = await Permission.storage.request();
          if (!storageResult.isGranted) {
            print('❌ Permissão de armazenamento negada');
            if (mounted) {
              SnackbarUtils.showErrorSnackBar(
                context, 
                'Permissão de armazenamento é necessária'
              );
            }
            return false;
          }
        }
      }
    }
    
    print('✅ Todas as permissões concedidas');
    return true;
  }

  Future<void> _selecionarFotos() async {
    try {
      print('🔍 Iniciando seleção de fotos...');
      
      // Verificar permissões primeiro
      final temPermissoes = await _verificarPermissoes();
      if (!temPermissoes) {
        return;
      }
      
      // Mostrar indicador de progresso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abrindo câmera...')),
        );
      }
      
      final ImagePicker picker = ImagePicker();
      final XFile? imagem = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      if (imagem != null) {
        print('📸 Imagem selecionada: ${imagem.path}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Processando imagem...')),
          );
        }
        
        // Verificar se o arquivo existe
        final File originalFile = File(imagem.path);
        if (!await originalFile.exists()) {
          print('❌ Arquivo original não encontrado: ${imagem.path}');
          if (mounted) {
            SnackbarUtils.showErrorSnackBar(context, 'Arquivo de imagem não encontrado');
          }
          return;
        }
        
        print('✅ Arquivo original existe, iniciando processamento...');
        
        try {
          final String caminhoComprimido = await _processarFoto(imagem.path);
          print('✅ Foto processada: $caminhoComprimido');
          
          final File compressedFile = File(caminhoComprimido);
          
          // Verificar se o arquivo comprimido foi criado com sucesso
          if (await compressedFile.exists()) {
            print('✅ Arquivo comprimido existe, adicionando à lista...');
            if (mounted) {
              setState(() {
                _fotos.add(caminhoComprimido);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto adicionada com sucesso')),
              );
            }
          } else {
            print('❌ Arquivo comprimido não foi criado: $caminhoComprimido');
            if (mounted) {
              SnackbarUtils.showErrorSnackBar(context, 'Falha ao processar a imagem');
            }
          }
        } catch (processError) {
          print('❌ Erro ao processar foto: $processError');
          if (mounted) {
            SnackbarUtils.showErrorSnackBar(context, 'Erro ao processar foto: $processError');
          }
        }
      } else {
        print('⚠️ Nenhuma imagem selecionada');
      }
    } catch (e) {
      print('❌ Erro ao selecionar foto: $e');
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao selecionar foto: ${e.toString()}');
      }
    }
  }
  
  Future<String> _processarFoto(String caminhoOriginal) async {
    try {
      print('🔄 Iniciando processamento da foto: $caminhoOriginal');
      
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/estande_fotos');
      
      print('📁 Diretório de destino: ${targetDir.path}');
      
      if (!await targetDir.exists()) {
        print('📁 Criando diretório de destino...');
        await targetDir.create(recursive: true);
      }
      
      final String nomeArquivo = path.basename(caminhoOriginal);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String caminhoDestino = '${targetDir.path}/${timestamp}_$nomeArquivo';
      
      print('📄 Caminho de destino: $caminhoDestino');
      
      // Verificar se o arquivo original existe
      final File originalFile = File(caminhoOriginal);
      if (!await originalFile.exists()) {
        throw Exception('Arquivo original não encontrado: $caminhoOriginal');
      }
      
      print('✅ Arquivo original existe, iniciando compressão...');
      
      // Comprimir a imagem
      final result = await FlutterImageCompress.compressAndGetFile(
        caminhoOriginal,
        caminhoDestino,
        quality: 70,
        minWidth: 800,
        minHeight: 600,
      );
      
      if (result == null) {
        throw Exception('Falha ao comprimir imagem');
      }
      
      print('✅ Imagem processada com sucesso: $caminhoDestino');
      
      // Verificar se o arquivo foi criado
      final File resultFile = File(result.path);
      if (await resultFile.exists()) {
        final fileSize = await resultFile.length();
        print('📊 Tamanho do arquivo comprimido: ${fileSize} bytes');
        return result.path;
      } else {
        throw Exception('Arquivo comprimido não foi criado: ${result.path}');
      }
    } catch (e) {
      print('❌ Erro ao processar foto: $e');
      rethrow; // Repassar o erro para ser tratado pelo chamador
    }
  }
  
  void _removerFoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }
  
  void _visualizarFoto(String caminhoFoto) {
    final File file = File(caminhoFoto);
    final bool fileExists = file.existsSync();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Visualizar Foto'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: fileExists
                ? InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print('Erro ao exibir imagem: $error');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                color: Colors.red,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar imagem:\n$error',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.red,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Imagem não encontrada',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _salvar() async {
    // Validar o formulário primeiro
    if (_formKey.currentState?.validate() != true) {
      SnackbarUtils.showErrorSnackBar(context, 'Corrija os erros nos campos antes de salvar');
      return;
    }
    
    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão');
      return;
    }
    
    // Verificar se há cultura selecionada ou cultura manual
    if (_culturaSelecionada == null && _culturaManual.trim().isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma cultura ou digite o nome da cultura');
      return;
    }
    
    // A validação dos campos obrigatórios já foi feita pelo _formKey.currentState!.validate()
    
    try {
      // Verificar se os cálculos foram realizados
      if (_plantasPorMetro == null || _plantasPorHectare == null) {
        SnackbarUtils.showErrorSnackBar(context, 'Realize o cálculo antes de salvar');
        return;
      }
      
      // Verificar se a população ideal foi informada
      if (_populacaoIdealController.text.isNotEmpty) {
        _populacaoIdeal = double.tryParse(_populacaoIdealController.text);
        if (_populacaoIdeal != null && _populacaoIdeal! > 0 && _plantasPorHectare! > 0) {
          _eficiencia = (_plantasPorHectare! / _populacaoIdeal!) * 100;
        }
      }
      
      // Criar o modelo de estande de plantas
      String culturaIdTemp = _culturaSelecionada?.id ?? _getCulturaIdFromName(_culturaManual);
      print('🔍 DEBUG: _culturaSelecionada?.id = "${_culturaSelecionada?.id}"');
      print('🔍 DEBUG: _culturaManual = "$_culturaManual"');
      print('🔍 DEBUG: culturaIdTemp = "$culturaIdTemp"');
      
      // MAPEAMENTO: Converter IDs do CultureImportService para IDs da tabela culturas
      final Map<String, String> idMapping = {
        'soja': 'custom_soja',
        'milho': 'custom_milho',
        'sorgo': 'custom_sorgo',
        'algodao': 'custom_algodao',
        'feijao': 'custom_feijao',
        'girassol': 'custom_girassol',
        'aveia': 'custom_aveia',
        'trigo': 'custom_trigo',
        'gergelim': 'custom_gergelim',
        'arroz': 'custom_arroz',
        'tomate': 'custom_tomate',
        'cana_acucar': 'custom_cana',
        '1': 'custom_soja',
        '2': 'custom_milho',
        '3': 'custom_sorgo',
      };
      
      // Converter ID se necessário
      String culturaIdFinal = culturaIdTemp;
      if (idMapping.containsKey(culturaIdTemp)) {
        print('🔄 Convertendo ID "$culturaIdTemp" para "${idMapping[culturaIdTemp]}"');
        culturaIdFinal = idMapping[culturaIdTemp]!;
      }
      
      print('🔍 DEBUG: culturaIdFinal após conversão = "$culturaIdFinal"');
      
      final estande = EstandePlantasModel.novo(
        talhaoId: _talhaoSelecionado!.id.toString(), // Convertendo int? para String
        culturaId: culturaIdFinal,
        dataEmergencia: _parseDate(_dataEmergenciaController.text) ?? DateTime.now(),
        dataAvaliacao: _parseDate(_dataAvaliacaoController.text) ?? DateTime.now(),
        diasAposEmergencia: _diasAposEmergencia != null ? _diasAposEmergencia!.toInt() : 0,
        metrosLinearesMedidos: double.tryParse(_metrosLinearesMedidosController.text) ?? 
                               double.tryParse(_metrosQuadradosController.text) ?? 0.0,
        // ❌ REMOVIDO campo de entrada única - agora usa soma das múltiplas linhas
        plantasContadas: _plantasPorLinha.isNotEmpty ? _plantasPorLinha.reduce((a, b) => a + b) : 0,
        espacamento: double.tryParse(_espacamentoController.text) ?? 0.0,
        plantasPorMetro: _plantasPorMetro ?? 0.0,
        plantasPorHectare: _plantasPorHectare ?? 0.0,
        populacaoIdeal: _populacaoIdeal,
        eficiencia: _eficiencia,
        fotos: _fotos,
        // createdAt e updatedAt são definidos automaticamente no factory
      );
      
      print('🔍 Salvando estande de plantas...');
      print('📊 Dados do estande: talhaoId=${estande.talhaoId}, culturaId=${estande.culturaId}');
      await _estandePlantasRepository.salvar(estande);
      print('✅ Estande salvo com sucesso!');
      
      // Armazenar dados reais para o relatório
      _estandePlantasModel = estande;
      
      // Criar modelo de CV% com dados reais calculados
      if (_usarMultiplasLinhas && _mediaPlantasPorLinha != null && _coeficienteVariacao != null) {
        final comprimentoLinha = double.tryParse(_comprimentoLinhaController.text.replaceAll(',', '.')) ?? 1.0;
        final totalPlantas = _plantasPorLinha.reduce((a, b) => a + b);
        final comprimentoTotal = _plantasPorLinha.length * comprimentoLinha;
        
        // Gerar card de resultado completo usando o serviço
        _plantingCVModel = PlantingCVResultCardService.gerarCardResultado(
          talhaoId: _talhaoSelecionado!.id.toString(),
          talhaoNome: _talhaoSelecionado!.name,
          culturaId: _culturaSelecionada?.id ?? _getCulturaIdFromName(_culturaManual),
          culturaNome: _culturaSelecionada?.name ?? _culturaManual,
          dataPlantio: _parseDate(_dataEmergenciaController.text) ?? DateTime.now(),
          comprimentoLinhaAmostrada: comprimentoLinha,
          espacamentoEntreLinhas: double.tryParse(_distanciaEntreLinhasController.text) ?? 0.0,
          distanciasEntreSementes: _plantasPorLinha.map((p) => comprimentoLinha / p).toList(),
          mediaEspacamento: comprimentoLinha / _mediaPlantasPorLinha!,
          desvioPadrao: _desvioPadraoPlantas ?? 0.0,
          coeficienteVariacao: _coeficienteVariacao!,
          plantasPorMetro: totalPlantas / comprimentoTotal,
          populacaoEstimadaPorHectare: _plantasPorHectare ?? 0.0,
          metaPopulacaoPorHectare: _populacaoIdeal,
          metaPlantasPorMetro: _populacaoIdeal != null ? _populacaoIdeal! / 10000 : null,
          observacoes: _observacoesController.text,
        );
        
        // Salvar o CV% no histórico usando o serviço de persistência
        print('🔍 Salvando CV% do plantio no histórico...');
        print('📊 Dados do CV%: talhaoId=${_plantingCVModel!.talhaoId}, cv=${_plantingCVModel!.coeficienteVariacao}%');
        
        final cvSalvo = await _cvPersistenceService.salvarCvNoHistorico(_plantingCVModel!);
        if (cvSalvo) {
          print('✅ CV% salvo no histórico com sucesso!');
          
          // Criar análise integrada
          print('🔍 Criando análise integrada de plantio...');
          final analiseIntegrada = await _integratedAnalysisService.criarAnaliseIntegrada(
            talhaoId: _talhaoSelecionado!.id,
            talhaoNome: _talhaoSelecionado!.name,
            culturaId: _culturaSelecionada?.id ?? _getCulturaIdFromName(_culturaManual),
            culturaNome: _culturaSelecionada?.name ?? _culturaManual,
            cvModel: _plantingCVModel!,
            estandeModel: estande,
          );
          
          if (analiseIntegrada != null) {
            print('✅ Análise integrada criada com sucesso!');
            print('📊 Status: ${analiseIntegrada.statusGeral}');
            print('📊 Qualidade: ${analiseIntegrada.qualidadePlantio}');
            print('📊 Recomendações: ${analiseIntegrada.recomendacoes.length}');
          } else {
            print('⚠️ Análise integrada não pôde ser criada');
          }
        } else {
          print('❌ Erro ao salvar CV% no histórico');
        }
      }
      
      // Salvar no histórico usando o modelo de calibração
      await AppDatabase.instance.initDatabase();
      final database = await AppDatabase.instance.database;
      final dao = CalibrationHistoryDao(database);
      
      // Determinar status baseado na eficiência
      String statusCalibracao;
      if (_eficiencia != null) {
        if (_eficiencia! >= 90) {
          statusCalibracao = 'dentro_esperado';
        } else if (_eficiencia! >= 75) {
          statusCalibracao = 'normal';
        } else {
          statusCalibracao = 'fora_esperado';
        }
      } else {
        statusCalibracao = 'normal';
      }
      
      // Criar modelo de histórico de calibração
      final calibracaoHistorico = CalibrationHistoryModel(
        talhaoId: _talhaoSelecionado!.id.toString(),
        talhaoName: _talhaoSelecionado!.name,
        culturaId: _culturaSelecionada?.id ?? _getCulturaIdFromName(_culturaManual),
        culturaName: _culturaSelecionada?.name ?? _culturaManual.trim(),
        discoNome: null,
        furosDisco: null,
        engrenagemMotora: null,
        engrenagemMovida: null,
        voltasDisco: null,
        distanciaPercorrida: double.tryParse(_metrosLinearesMedidosController.text) ?? 
                             double.tryParse(_metrosQuadradosController.text),
        // ❌ REMOVIDO campo de entrada única - agora usa número de linhas coletadas
        linhasColetadas: _plantasPorLinha.length > 0 ? _plantasPorLinha.length : null,
        espacamentoCm: double.tryParse(_espacamentoController.text),
        metaSementesHectare: _populacaoIdeal?.round(),
        relacaoTransmissao: null,
        sementesTotais: null,
        sementesPorMetro: _plantasPorMetro,
        sementesPorHectare: _plantasPorHectare?.round(),
        diferencaMetaPercentual: _eficiencia != null ? (100 - _eficiencia!) : null,
        statusCalibracao: statusCalibracao,
        observacoes: 'Dias após emergência: ${_diasAposEmergencia ?? 0}\n'
                     'Plantas por metro: ${_plantasPorMetro?.toStringAsFixed(1) ?? 'N/A'}\n'
                     'Eficiência: ${_eficiencia?.toStringAsFixed(1) ?? 'N/A'}%\n'
                     'Fotos: ${_fotos.length}',
        dataCalibracao: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await dao.insertCalibration(calibracaoHistorico);
      
      if (mounted) {
        setState(() {
          _estandeId = estande.id;
        });
        
        SnackbarUtils.showSuccessSnackBar(
          context, 
          'Estande salvo com sucesso!\nStatus: ${CalibrationHistoryModel.getStatusText(statusCalibracao)}'
        );
      }
    } catch (e, stackTrace) {
      print('❌ ERRO AO SALVAR ESTANDE: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar estande: ${e.toString()}');
      }
    }
  }
  

  
  DateTime? _parseDate(String date) {
    try {
      if (date.isEmpty) return null;
      final parts = date.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Busca o ID correto da cultura pelo nome nas culturas carregadas
  String _getCulturaIdFromName(String culturaName) {
    if (culturaName.trim().isEmpty) {
      print('⚠️ Nome de cultura vazio, retornando ID padrão');
      return 'custom_soja';
    }
    
    if (_culturas.isEmpty) {
      print('⚠️ Lista de culturas vazia, retornando ID padrão');
      return 'custom_soja';
    }
    
    final culturaLower = culturaName.toLowerCase().trim();
    
    try {
      // Buscar nas culturas já carregadas do módulo Culturas da Fazenda
      final culturaEncontrada = _culturas.firstWhere(
        (cultura) => cultura.name.toLowerCase().trim() == culturaLower,
        orElse: () {
          print('⚠️ Cultura "$culturaName" não encontrada na lista de culturas carregadas');
          print('📋 Culturas disponíveis: ${_culturas.map((c) => c.name).join(', ')}');
          return AgriculturalProduct(
            id: 'custom_soja', // ID padrão apenas se não encontrar
            name: 'Soja',
            type: ProductType.seed,
            colorValue: 'FF4CAF50',
          );
        },
      );
      
      print('🔍 Buscando cultura "$culturaName": encontrada "${culturaEncontrada.name}" com ID "${culturaEncontrada.id}"');
      
      // MAPEAMENTO: Converter IDs do CultureImportService para IDs da tabela culturas
      final Map<String, String> idMapping = {
        'soja': 'custom_soja',
        'milho': 'custom_milho',
        'sorgo': 'custom_sorgo',
        'algodao': 'custom_algodao',
        'feijao': 'custom_feijao',
        'girassol': 'custom_girassol',
        'aveia': 'custom_aveia',
        'trigo': 'custom_trigo',
        'gergelim': 'custom_gergelim',
        'arroz': 'custom_arroz',
        'tomate': 'custom_tomate',
        'cana_acucar': 'custom_cana',
        '1': 'custom_soja',
        '2': 'custom_milho',
        '3': 'custom_sorgo',
      };
      
      // Converter ID se necessário
      String culturaId = culturaEncontrada.id;
      if (idMapping.containsKey(culturaId)) {
        print('🔄 Convertendo ID "$culturaId" para "${idMapping[culturaId]}"');
        culturaId = idMapping[culturaId]!;
      }
      
      // VALIDAÇÃO: Garantir que o ID é válido
      if (culturaId.isEmpty || culturaId == '1') {
        print('⚠️ ID de cultura inválido "$culturaId", usando ID padrão válido');
        return 'custom_soja';
      }
      
      print('✅ ID final da cultura: "$culturaId"');
      return culturaId;
      
    } catch (e) {
      print('❌ Erro ao buscar cultura "$culturaName": $e');
      return 'custom_soja'; // ID padrão em caso de erro
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_estandeId == null ? 'Novo Estande de Plantas' : 'Editar Estande de Plantas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: _abrirCalculoCv,
            tooltip: 'Calcular CV% do Plantio',
          ),
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: _gerarRelatorioQualidade,
            tooltip: 'Gerar Relatório de Qualidade',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _abrirHistorico,
            tooltip: 'Ver Histórico',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregarTalhoes,
            tooltip: 'Recarregar talhões',
          ),
        ],
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
                        const SizedBox(height: 12),
                        // Widget de dados integrados (só aparece quando talhão e cultura estão selecionados)
                        if (_talhaoSelecionado != null && (_culturaSelecionada != null || _culturaManual.isNotEmpty))
                          _buildIntegratedDataWidget(),
                        const SizedBox(height: 12),
                        _buildSelecaoDatas(),
                        const SizedBox(height: 12),
                        _buildMultiplasLinhas(),
                        const SizedBox(height: 12),
                        _buildEntradaDados(),
                        const SizedBox(height: 12),
                        _buildPopulacaoIdeal(),
                        const SizedBox(height: 12),
                        _buildDadosComparacao(),
                        const SizedBox(height: 12),
                        _buildResultados(),
                        const SizedBox(height: 12),
                        _buildFotos(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _calcular,
                                icon: const Icon(Icons.calculate),
                                label: const Text('Calcular'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FortSmartTheme.primaryButton,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _salvar,
                                icon: const Icon(Icons.save),
                                label: const Text('Salvar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FortSmartTheme.successColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _limpar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Limpar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _carregarDados();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FortSmartTheme.primaryButton,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de dados integrados de plantio e estande
  Widget _buildIntegratedDataWidget() {
    final talhaoId = _talhaoSelecionado?.id ?? '';
    final culturaId = _culturaSelecionada?.id ?? _culturaManual;
    final talhaoNome = _talhaoSelecionado?.name ?? 'Talhão';
    final culturaNome = _culturaSelecionada?.name ?? _culturaManual;

    return PlantingIntegratedDataWidget(
      talhaoId: talhaoId,
      culturaId: culturaId,
      talhaoNome: talhaoNome,
      culturaNome: culturaNome,
      showFullAnalysis: true,
      onDataUpdated: () {
        // Callback para atualizar dados quando necessário
        print('Dados integrados atualizados para talhão $talhaoNome');
      },
    );
  }

  /// Abre a tela de cálculo de CV% para comparação agronômica
  void _abrirCalculoCv() async {
    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Por favor, selecione um talhão primeiro');
      return;
    }

    final talhaoId = _talhaoSelecionado!.id;
    final culturaId = _culturaSelecionada?.id ?? _culturaManual;

    if (culturaId.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Por favor, selecione uma cultura primeiro');
      return;
    }

    // Navegar para a tela de cálculo de CV% 
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantingCVCalculationScreen(
          talhaoId: talhaoId,
          talhaoNome: _talhaoSelecionado?.name ?? 'Talhão',
          culturaId: culturaId,
          culturaNome: _culturaSelecionada?.name ?? 'Cultura',
        ),
      ),
    );
    
    // Se o usuário salvou dados de CV%, recarregar automaticamente
    if (result == true) {
      print('🔄 CV% salvo, recarregando dados de comparação...');
      _buscarDadosCVExistentes(); // ✅ REMOVIDO await (método é void)
      _compararComDadosCV();
      
      if (mounted) {
        setState(() {}); // Atualizar UI
        SnackbarUtils.showSuccessSnackBar(
          context, 
          'Dados de CV% atualizados! Comparação agronômica realizada.'
        );
      }
    }
  }

  /// Gera relatório de qualidade de plantio
  void _gerarRelatorioQualidade() async {
    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Por favor, selecione um talhão primeiro');
      return;
    }

    if (_culturaSelecionada == null && _culturaManual.trim().isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Por favor, selecione uma cultura primeiro');
      return;
    }

    // Verificar se os cálculos foram realizados
    if (_plantasPorMetro == null || _plantasPorHectare == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Realize o cálculo do estande antes de gerar o relatório');
      return;
    }

    try {
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Gerando relatório de qualidade...'),
            ],
          ),
        ),
      );

      // Primeiro tentar gerar relatório com dados dos submódulos
      PlantingQualityReportModel relatorio;
      
      // Buscar dados do plantio (variedade e safra)
      String variedadePlantio = '';
      String safraPlantio = '';
      
      try {
        final plantioLoaderService = PlantioLoaderService();
        final plantio = await plantioLoaderService.buscarUltimoPlantio(
          talhaoId: _talhaoSelecionado!.id,
          culturaId: _culturaSelecionada?.name ?? _culturaManual,
        );
        
        if (plantio != null) {
          variedadePlantio = plantio.variedade ?? '';
          // A safra virá do plantio quando implementado
          print('✅ Dados do plantio carregados: variedade=$variedadePlantio');
        }
      } catch (e) {
        print('⚠️ Erro ao carregar dados do plantio: $e');
      }
      
      // Pegar a primeira foto da lista (se existir)
      String? primeiraFoto = _fotos.isNotEmpty ? _fotos.first : null;
      
      try {
        print('🔄 Tentando gerar relatório com dados dos submódulos...');
        relatorio = await _integrationService.gerarRelatorioComDadosSubmodulos(
          talhaoData: _talhaoSelecionado!,
          executor: 'Usuário FortSmart',
          variedade: variedadePlantio,
          safra: safraPlantio,
        );
        print('✅ Relatório gerado com dados dos submódulos');
      } catch (e) {
        print('⚠️ Erro ao buscar dados dos submódulos: $e');
        print('🔄 Tentando gerar relatório com dados calculados atuais...');
        
        // Se falhar, usar dados calculados atuais
        if (_plantingCVModel == null || _estandePlantasModel == null) {
          SnackbarUtils.showErrorSnackBar(context, 'Erro: Nenhum dado encontrado nos submódulos ou cálculos atuais');
          Navigator.of(context).pop(); // Fechar diálogo de carregamento
          return;
        }
        
        // Log dos dados reais para debug
        print('🔍 DADOS REAIS PARA RELATÓRIO:');
        print('📊 CV%: ${_plantingCVModel!.coeficienteVariacao}%');
        print('🌱 Plantas/metro: ${_plantingCVModel!.plantasPorMetro}');
        print('📈 Plantas/hectare: ${_plantingCVModel!.populacaoEstimadaPorHectare}');
        print('🎯 Estande plantas/metro: ${_estandePlantasModel!.plantasPorMetro}');
        print('🎯 Estande plantas/hectare: ${_estandePlantasModel!.plantasPorHectare}');
        
        relatorio = _plantingQualityReportService.gerarRelatorioComDadosReais(
          talhaoNome: _talhaoSelecionado!.name,
          culturaNome: _culturaSelecionada?.name ?? _culturaManual,
          executor: 'Usuário FortSmart', // Em produção, pegar do usuário logado
          cvDataReal: _plantingCVModel!, // Dados REAIS do CV% calculado
          estandeDataReal: _estandePlantasModel!, // Dados REAIS do estande calculado
          talhaoDataReal: _talhaoSelecionado!, // Dados REAIS do talhão
          variedade: variedadePlantio,
          safra: safraPlantio,
          imagemEstande: primeiraFoto, // ✅ Passar foto do estande para o relatório
        );
        print('✅ Relatório gerado com dados calculados atuais');
      }

      // Fechar diálogo de carregamento
      Navigator.of(context).pop();

      // Navegar para a tela de relatório
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlantingQualityReportScreen(
            relatorio: relatorio,
          ),
        ),
      );

    } catch (e) {
      // Fechar diálogo de carregamento se estiver aberto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      SnackbarUtils.showErrorSnackBar(
        context, 
        'Erro ao gerar relatório: ${e.toString()}'
      );
    }
  }
}