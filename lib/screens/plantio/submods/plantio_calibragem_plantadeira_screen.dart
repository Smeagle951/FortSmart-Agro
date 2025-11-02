import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/cultura_talhao_service.dart';
import '../../../services/farm_culture_sync_service.dart';
import '../../../services/talhao_module_service.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/fortsmart_theme.dart';
import '../../../widgets/fortsmart_card.dart';
import '../../../models/talhao_model.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/poligono_model.dart';
import 'widgets/selecao_talhao_cultura_plantadeira_widget.dart';
import 'widgets/selecao_talhao_cultura_plantadeira_melhorado_widget.dart';
import 'package:sqflite/sqflite.dart';
import '../../../database/database_helper.dart';
import '../../../database/talhao_database.dart';
import '../../../providers/talhao_provider.dart';
import '../../../providers/cultura_provider.dart';
import '../../../services/data_cache_service.dart';
import '../../../services/talhao_unified_loader_service.dart';
import '../../../models/calibration_history_model.dart';
import '../../../database/daos/calibration_history_dao.dart';
import '../../../database/app_database.dart';
import 'plantio_calibragem_historico_screen.dart';

class PlantioCalibragePlantadeiraScreen extends StatefulWidget {
  const PlantioCalibragePlantadeiraScreen({Key? key}) : super(key: key);

  @override
  _PlantioCalibragePlantadeiraScreenState createState() => _PlantioCalibragePlantadeiraScreenState();
}

class _PlantioCalibragePlantadeiraScreenState extends State<PlantioCalibragePlantadeiraScreen> {
  final _formKey = GlobalKey<FormState>();
  final CulturaTalhaoService _culturaService = CulturaTalhaoService();
  final FarmCultureSyncService _farmCultureSyncService = FarmCultureSyncService();
  final TalhaoModuleService _talhaoModuleService = TalhaoModuleService();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final TalhaoUnifiedLoaderService _talhaoLoader = TalhaoUnifiedLoaderService();
  
  // Controllers para os campos de entrada
  final TextEditingController _discoNomeController = TextEditingController();
  final TextEditingController _furosDiscoController = TextEditingController();
  final TextEditingController _engrenagemMotoraController = TextEditingController();
  final TextEditingController _engrenagemMovidaController = TextEditingController();
  final TextEditingController _voltasDiscoController = TextEditingController();
  final TextEditingController _distanciaController = TextEditingController();
  final TextEditingController _sementesPorMetroController = TextEditingController();
  final TextEditingController _linhasController = TextEditingController(text: '1');
  final TextEditingController _espacamentoController = TextEditingController(text: '45');
  final TextEditingController _metaController = TextEditingController(text: '350000');
  
  // Valores calculados
  double _relacaoTransmissao = 0.0;
  double _voltasDisco = 0.0;
  double _sementesTotais = 0.0;
  double _sementesPorMetro = 0.0;
  double _sementesPorHectare = 0.0;
  double _diferencaMeta = 0.0;
  String _statusCalibracao = 'normal';
  
  // Seleções
  TalhaoModel? _talhaoSelecionado;
  AgriculturalProduct? _culturaSelecionada;
  
  // Listas para os dropdowns
  List<TalhaoModel> _talhoes = [];
  List<AgriculturalProduct> _culturas = [];
  
  // Estado
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }
  
  // Função para converter string para ProductType
  ProductType _getProductTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'herbicide':
      case 'herbicida':
        return ProductType.herbicide;
      case 'insecticide':
      case 'inseticida':
        return ProductType.insecticide;
      case 'fungicide':
      case 'fungicida':
        return ProductType.fungicide;
      case 'fertilizer':
      case 'fertilizante':
        return ProductType.fertilizer;
      case 'growth':
      case 'regulador':
        return ProductType.growth;
      case 'adjuvant':
      case 'adjuvante':
        return ProductType.adjuvant;
      case 'seed':
      case 'semente':
        return ProductType.seed;
      default:
        return ProductType.other;
    }
  }

  Future<void> _carregarDados() async {
    try {
      print('🌱 Iniciando carregamento de dados do módulo calibragem de plantadeira...');
      
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Carregar dados em paralelo com timeout para evitar travamento
      await Future.wait([
        _carregarTalhoes().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⚠️ Timeout ao carregar talhões');
            return;
          },
        ),
        _carregarCulturas().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⚠️ Timeout ao carregar culturas');
            return;
          },
        ),
      ]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      print('✅ Dados carregados com sucesso!');
      print('  - Talhões: ${_talhoes.length}');
      print('  - Culturas: ${_culturas.length}');
      
    } catch (e, stackTrace) {
      print('❌ Erro ao carregar dados: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar dados: ${e.toString()}';
          _talhoes = [];
          _culturas = [];
        });
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao carregar dados: ${e.toString()}');
      }
    }
  }
  
  // Carregar talhões do módulo Talhões
  Future<void> _carregarTalhoes() async {
    try {
      print('🔄 Carregando talhões reais do módulo Talhões...');
      
      // Usar o serviço unificado para carregar talhões
      _talhoes = await _talhaoLoader.carregarTalhoes();
      
      if (_talhoes.isNotEmpty) {
        print('✅ ${_talhoes.length} talhões carregados pelo TalhaoUnifiedLoaderService');
        for (var talhao in _talhoes) {
          print('  - ${talhao.name} (ID: ${talhao.id})');
        }
        return;
      }
      
      // Se não conseguiu carregar, definir lista vazia
      print('❌ Nenhum talhão encontrado');
      _talhoes = [];
      
    } catch (e) {
      print('❌ Erro geral ao carregar talhões: $e');
      _talhoes = []; // Lista vazia em vez de fallback
    }
  }
  
  // Carregar culturas do módulo Culturas da Fazenda
  Future<void> _carregarCulturas() async {
    try {
      print('🔄 Carregando culturas para regulagem de plantadeira...');
      
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
            colorValue: cultura.color.value.toString(),
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
        final culturasData = await _culturaService.listarCulturas();
        
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
        print('❌ Erro ao carregar culturas do CulturaTalhaoService: $e');
      }
      
      // Se não houver culturas, tentar sincronizar com o módulo de culturas da fazenda
      if (_culturas.isEmpty) {
        print('🔄 Nenhuma cultura encontrada, sincronizando com módulo de culturas da fazenda...');
        // Comentado temporariamente até resolver dependências
        // await _farmCultureSyncService.syncFarmCulturesToMonitoring();
        // final culturasFazenda = await _farmCultureSyncService.getFarmCulturesForMonitoring();
        
        // Comentado temporariamente até resolver dependências
        // if (culturasFazenda.isNotEmpty) {
        //   _culturas = culturasFazenda.map((cultura) => AgriculturalProduct(
            // id: cultura.id,
            // name: cultura.name,
            // description: cultura.description ?? '',
            // type: ProductType.seed,
            // colorValue: cultura.color.value.toString(),
          // )).toList();
          // print('✅ ${_culturas.length} culturas carregadas do módulo de culturas da fazenda');
        // }
      }
      
      // Se ainda não houver culturas, tentar carregar do CulturaProvider
      if (_culturas.isEmpty) {
        print('⚠️ Nenhuma cultura encontrada, tentando carregar do CulturaProvider...');
        try {
          final culturaProvider = Provider.of<CulturaProvider>(context, listen: false);
          await culturaProvider.carregarCulturas();
          
          if (culturaProvider.culturas.isNotEmpty) {
            _culturas = culturaProvider.culturas.map((cultura) => AgriculturalProduct(
              id: cultura.id,
              name: cultura.name,
              description: cultura.description ?? '',
              type: ProductType.seed,
              colorValue: cultura.color.value.toString(),
            )).toList();
            print('✅ ${_culturas.length} culturas carregadas do CulturaProvider');
          } else {
            print('❌ Nenhuma cultura encontrada no CulturaProvider');
            _culturas = []; // Lista vazia em vez de fallback
          }
        } catch (e) {
          print('❌ Erro ao carregar do CulturaProvider: $e');
          _culturas = []; // Lista vazia em vez de fallback
        }
      }
      
      // Log detalhado das culturas
      for (int i = 0; i < _culturas.length; i++) {
        final cultura = _culturas[i];
        print('  ${i + 1}. ${cultura.name} (ID: ${cultura.id})');
      }
      
    } catch (e) {
      print('❌ Erro ao carregar culturas: $e');
      _culturas = []; // Lista vazia em vez de fallback
    }
  }
  

  

  
  // Método para selecionar um talhão
  Future<void> _selecionarTalhao() async {
    if (_talhoes.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Nenhum talhão disponível');
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione um Talhão'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _talhoes.length,
            itemBuilder: (context, index) {
              final talhao = _talhoes[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    talhao.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(talhao.name),
                subtitle: Text('${talhao.area?.toStringAsFixed(2) ?? '-'} ha'),
                onTap: () {
                  setState(() {
                    _talhaoSelecionado = talhao;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  // Método para selecionar uma cultura
  Future<void> _selecionarCultura() async {
    if (_culturas.isEmpty) {
      SnackbarUtils.showErrorSnackBar(context, 'Nenhuma cultura disponível');
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione uma Cultura'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _culturas.length,
            itemBuilder: (context, index) {
              final cultura = _culturas[index];
              Color corCultura;
              try {
                if (cultura.colorValue != null && cultura.colorValue!.isNotEmpty) {
                  String colorString = cultura.colorValue!.trim();
                  
                  // Se começa com #
                  if (colorString.startsWith('#')) {
                    String hex = colorString.substring(1);
                    if (hex.length == 6) {
                      corCultura = Color(int.parse('0xFF$hex'));
                    } else if (hex.length == 3) {
                      // Expandir cores de 3 dígitos
                      hex = hex.split('').map((c) => c + c).join();
                      corCultura = Color(int.parse('0xFF$hex'));
                    } else {
                      corCultura = Colors.grey;
                    }
                  }
                  // Se começa com 0x
                  else if (colorString.startsWith('0x')) {
                    corCultura = Color(int.parse(colorString));
                  }
                  // Se é apenas um número
                  else if (RegExp(r'^[0-9]+$').hasMatch(colorString)) {
                    corCultura = Color(int.parse(colorString));
                  }
                  // Se contém Color( (objeto Color)
                  else if (colorString.contains('Color(')) {
                    corCultura = Colors.grey;
                  }
                  else {
                    corCultura = Colors.grey;
                  }
                } else {
                  corCultura = Colors.grey;
                }
              } catch (e) {
                print('❌ Erro ao parsear color: "${cultura.colorValue}" - $e');
                corCultura = Colors.grey;
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: corCultura,
                  child: const Icon(Icons.grass, color: Colors.white),
                ),
                title: Text(cultura.name ?? 'Sem nome'),
                onTap: () {
                  setState(() {
                    _culturaSelecionada = cultura;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  // Cálculo detalhado conforme especificação
  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão');
      return;
    }
    
    if (_culturaSelecionada == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma cultura');
      return;
    }
    
    try {
      // Obter valores dos campos
      final furosDisco = int.parse(_furosDiscoController.text);
      final engrenagemMotora = int.parse(_engrenagemMotoraController.text);
      final engrenagemMovida = int.parse(_engrenagemMovidaController.text);
      final voltasRoda = double.parse(_voltasDiscoController.text);
      final distancia = double.parse(_distanciaController.text);
      final linhas = int.parse(_linhasController.text);
      final espacamento = double.parse(_espacamentoController.text) / 100; // Converter cm para metros
      final meta = double.parse(_metaController.text);
      
      // 1. Relação de transmissão entre engrenagens
      final relacao = engrenagemMovida / engrenagemMotora;
      
      // 2. Total de voltas do disco (ou do eixo)
      final voltasDisco = voltasRoda * relacao;
      
      // 3. Sementes liberadas por volta do disco
      final sementesPorVolta = furosDisco;
      
      // 4. Total de sementes distribuídas
      final sementesTotais = voltasDisco * sementesPorVolta;
      
      // 5. Sementes por metro linear
      final sementesPorMetro = sementesTotais / (distancia * linhas);
      
      // 6. Sementes por hectare
      final sementesPorHectare = sementesPorMetro * (10000 / espacamento);
      
      // Diferença da meta
      final diferencaMeta = ((sementesPorHectare - meta) / meta) * 100;
      
      // Determinar status da calibração
      final statusCalibracao = CalibrationHistoryModel.determinarStatusCalibracao(diferencaMeta);
      
      setState(() {
        _relacaoTransmissao = relacao;
        _voltasDisco = voltasDisco;
        _sementesTotais = sementesTotais;
        _sementesPorMetro = sementesPorMetro;
        _sementesPorHectare = sementesPorHectare;
        _diferencaMeta = diferencaMeta;
        _statusCalibracao = statusCalibracao;
      });
      
      SnackbarUtils.showSuccessSnackBar(context, 'Cálculo realizado com sucesso!');
      
    } catch (e) {
      SnackbarUtils.showErrorSnackBar(context, 'Erro no cálculo: ${e.toString()}');
    }
  }
  
  Future<void> _salvarCalibragem() async {
    if (_talhaoSelecionado == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione um talhão');
      return;
    }
    
    if (_culturaSelecionada == null) {
      SnackbarUtils.showErrorSnackBar(context, 'Selecione uma cultura');
      return;
    }
    
    if (_sementesPorHectare == 0.0) {
      SnackbarUtils.showErrorSnackBar(context, 'Faça o cálculo antes de salvar');
      return;
    }
    
    try {
      // Obter banco de dados
      await AppDatabase.instance.initDatabase();
      final database = await AppDatabase.instance.database;
      final dao = CalibrationHistoryDao(database);
      
      // Criar modelo de calibração
      final calibracao = CalibrationHistoryModel(
        talhaoId: _talhaoSelecionado!.id,
        talhaoName: _talhaoSelecionado!.name,
        culturaId: _culturaSelecionada!.id,
        culturaName: _culturaSelecionada!.name,
        discoNome: _discoNomeController.text.isNotEmpty ? _discoNomeController.text : null,
        furosDisco: _furosDiscoController.text.isNotEmpty ? int.tryParse(_furosDiscoController.text) : null,
        engrenagemMotora: _engrenagemMotoraController.text.isNotEmpty ? int.tryParse(_engrenagemMotoraController.text) : null,
        engrenagemMovida: _engrenagemMovidaController.text.isNotEmpty ? int.tryParse(_engrenagemMovidaController.text) : null,
        voltasDisco: _voltasDisco,
        distanciaPercorrida: _distanciaController.text.isNotEmpty ? double.tryParse(_distanciaController.text) : null,
        linhasColetadas: _linhasController.text.isNotEmpty ? int.tryParse(_linhasController.text) : null,
        espacamentoCm: _espacamentoController.text.isNotEmpty ? double.tryParse(_espacamentoController.text) : null,
        metaSementesHectare: _metaController.text.isNotEmpty ? int.tryParse(_metaController.text) : null,
        relacaoTransmissao: _relacaoTransmissao,
        sementesTotais: _sementesTotais.round(),
        sementesPorMetro: _sementesPorMetro,
        sementesPorHectare: _sementesPorHectare.round(),
        diferencaMetaPercentual: _diferencaMeta,
        statusCalibracao: _statusCalibracao,
        observacoes: null,
        dataCalibracao: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Salvar no banco de dados
      final id = await dao.insertCalibration(calibracao);
      
      if (id > 0) {
        SnackbarUtils.showSuccessSnackBar(
          context, 
          'Calibração salva com sucesso!\nStatus: ${CalibrationHistoryModel.getStatusText(_statusCalibracao)}'
        );
        
        // Limpar campos após salvar
        _limparCampos();
      } else {
        SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar calibração');
      }
    } catch (e) {
      print('❌ Erro ao salvar calibração: $e');
      SnackbarUtils.showErrorSnackBar(context, 'Erro ao salvar calibração: ${e.toString()}');
    }
  }
  
  void _limparCampos() {
    setState(() {
      _discoNomeController.text = '';
      _furosDiscoController.text = '';
      _engrenagemMotoraController.text = '';
      _engrenagemMovidaController.text = '';
      _voltasDiscoController.text = '';
      _distanciaController.text = '';
      _sementesPorMetroController.text = '';
      _linhasController.text = '1';
      _espacamentoController.text = '45';
      _metaController.text = '350000';
      _talhaoSelecionado = null;
      _culturaSelecionada = null;
      _relacaoTransmissao = 0.0;
      _voltasDisco = 0.0;
      _sementesTotais = 0.0;
      _sementesPorMetro = 0.0;
      _sementesPorHectare = 0.0;
      _diferencaMeta = 0.0;
      _statusCalibracao = 'normal';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibragem de Plantadeira'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _abrirHistorico,
            tooltip: 'Ver Histórico',
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
                        _buildSelecaoPlantio(),
                        const SizedBox(height: 16),
                        _buildEntradaDados(),
                        const SizedBox(height: 16),
                        _buildResultados(),
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
  
  Widget _buildSelecaoPlantio() {
    return SelecaoTalhaoCulturaPlantadeiraMelhoradoWidget(
      talhaoSelecionado: _talhaoSelecionado,
      culturaSelecionada: _culturaSelecionada,
      onSelecionarTalhao: _selecionarTalhao,
      onSelecionarCultura: _selecionarCultura,
    );
  }
  
  Widget _buildEntradaDados() {
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📥 Dados da Calibragem',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          TextFormField(
            controller: _discoNomeController,
            decoration: const InputDecoration(
              labelText: 'Disco (nome)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o nome do disco';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _furosDiscoController,
            decoration: const InputDecoration(
              labelText: 'Nº de furos no disco',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o número de furos';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _engrenagemMotoraController,
                  decoration: const InputDecoration(
                    labelText: 'Engrenagem Motora',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a engrenagem motora';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _engrenagemMovidaController,
                  decoration: const InputDecoration(
                    labelText: 'Engrenagem Movida',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe a engrenagem movida';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _voltasDiscoController,
            decoration: const InputDecoration(
              labelText: 'Nº de voltas do disco (opcional)',
              border: OutlineInputBorder(),
              hintText: 'Informe o número de voltas do disco',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            // Removido validator para tornar opcional
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _distanciaController,
            decoration: const InputDecoration(
              labelText: 'Distância percorrida (m)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe a distância percorrida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sementesPorMetroController,
            decoration: const InputDecoration(
              labelText: 'Sementes por metro desejado (opcional)',
              border: OutlineInputBorder(),
              hintText: 'Informe quantas sementes por metro deseja',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            // Opcional - sem validator
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _linhasController,
            decoration: const InputDecoration(
              labelText: 'Nº de linhas coletadas',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o número de linhas';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _espacamentoController,
            decoration: const InputDecoration(
              labelText: 'Espaçamento entre linhas (cm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe o espaçamento entre linhas';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _metaController,
            decoration: const InputDecoration(
              labelText: 'Meta de sementes por hectare',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe a meta de sementes';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultados() {
    if (_sementesPorHectare == 0.0) {
      return const SizedBox.shrink();
    }
    
    return FortSmartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧮 Resultados do Cálculo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          _buildResultadoItem('🔁 Relação de transmissão', '${_relacaoTransmissao.toStringAsFixed(2)}'),
          _buildResultadoItem('🔄 Voltas do disco', '${_voltasDisco.toStringAsFixed(1)}'),
          _buildResultadoItem('🌱 Sementes totais', '${_sementesTotais.toStringAsFixed(0)}'),
          _buildResultadoItem('📏 Sementes por metro', '${_sementesPorMetro.toStringAsFixed(2)}'),
          _buildResultadoItem('📐 Sementes por hectare', '${_sementesPorHectare.toStringAsFixed(0)}'),
          _buildResultadoItem('📊 Diferença da meta', '${_diferencaMeta.toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          _buildStatusCalibracao(),
        ],
      ),
    );
  }
  
  Widget _buildResultadoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusCalibracao() {
    if (_sementesPorHectare == 0.0) {
      return const SizedBox.shrink(); // Não mostrar se não foi calculado
    }
    
    final statusColor = CalibrationHistoryModel.getStatusColor(_statusCalibracao);
    final statusText = CalibrationHistoryModel.getStatusText(_statusCalibracao);
    final statusIcon = CalibrationHistoryModel.getStatusIcon(_statusCalibracao);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status da Calibração',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBotoes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura for muito pequena, usar layout vertical
        if (constraints.maxWidth < 400) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvarCalibragem,
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
          );
        }
        
        // Layout horizontal para telas maiores
        return Row(
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
                onPressed: _salvarCalibragem,
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
        );
      },
    );
  }
}
