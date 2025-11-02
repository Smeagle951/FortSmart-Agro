import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/cultura_talhao_service.dart';
import '../services/culture_import_service.dart';
import '../services/estande_service.dart';
import '../services/infestation_history_service.dart';
import '../services/planting_unified_data_service.dart';
import '../modules/ai/services/ai_infestation_map_integration_service.dart';
import '../database/models/estande_plantas_model.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import '../utils/media_helper.dart';
import 'responsive_scroll_widget.dart';

/// Widget profissional para o card de nova ocorrência com IA integrada
class NewOccurrenceCard extends StatefulWidget {
  final String cropName;
  final String fieldId;
  final Function(Map<String, dynamic>) onOccurrenceAdded;
  final VoidCallback? onClose;
  final VoidCallback? onSaveAndAdvance;

  const NewOccurrenceCard({
    Key? key,
    required this.cropName,
    required this.fieldId,
    required this.onOccurrenceAdded,
    this.onClose,
    this.onSaveAndAdvance,
  }) : super(key: key);

  @override
  _NewOccurrenceCardState createState() => _NewOccurrenceCardState();
}

class _NewOccurrenceCardState extends State<NewOccurrenceCard> {
  final CulturaTalhaoService _culturaService = CulturaTalhaoService();
  final CultureImportService _cultureImportService = CultureImportService();
  final EstandeService _estandeService = EstandeService();
  final InfestationHistoryService _historyService = InfestationHistoryService();
  final PlantingUnifiedDataService _plantingDataService = PlantingUnifiedDataService();
  final AIInfestationMapIntegrationService _aiService = AIInfestationMapIntegrationService();
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();
  
  // Timer para debounce da busca
  Timer? _searchDebounceTimer;
  
  OccurrenceType _selectedType = OccurrenceType.pest;
  String _selectedOrganismId = '';
  String _selectedOrganismName = '';
  String _selectedPlantSection = 'Baixeiro';
  String _selectedPhase = '';
  
  // NOVOS CAMPOS INTELIGENTES
  int _selectedSeverity = 0;
  double _currentTemperature = 0.0;
  double _currentHumidity = 0.0;
  String _riskLevel = 'Baixo';
  double _infestationSize = 0.0; // Tamanho da infestação em mm
  // Lista de imagens selecionadas (usando _imagePaths)
  
  // CAMPOS ENRIQUECIDOS COM IA
  String? _estadioFenologico; // Preenchido automaticamente
  List<String> _tipoManejoAnterior = []; // Checkbox múltiplo
  String? _historicoResumo; // Gerado automaticamente
  String? _estandeId; // ID do último estande
  double? _impactoEconomicoPrevisto; // Calculado pela IA
  EstandePlantasModel? _ultimoEstande; // Dados do último estande
  bool _hasRecentStand = false; // Se tem estande recente
  String _historySummary = ''; // Resumo do histórico
  
  // CAMPOS DE CV% DO PLANTIO
  double? _cvPercentage; // Valor do CV%
  String? _cvStatus; // Status: RUIM, BOM ou EXCELENTE
  bool _hasCvData = false; // Se tem dados de CV%
  
  // MÚLTIPLAS OCORRÊNCIAS
  List<Map<String, dynamic>> _ocorrenciasAdicionadas = [];
  
  List<Map<String, dynamic>> _allOrganisms = [];
  List<Map<String, dynamic>> _filteredOrganisms = [];
  bool _showSuggestions = false;
  
  // Cache para melhorar performance (igual ao card antigo)
  Map<String, Map<String, List<Map<String, dynamic>>>> _organismCache = {};
  bool _isInitialized = false;
  
  // Variáveis para fotos
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    // Adicionar delay para evitar sobrecarga na inicialização
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeOrganismCache();
        _loadCvData();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  /// Adiciona uma nova ocorrência à lista
  void _adicionarOcorrencia() async {
    print('🔍 DEBUG: Tentando adicionar ocorrência...');
    print('🔍 DEBUG: _selectedOrganismName: "${_selectedOrganismName}"');
    print('🔍 DEBUG: _selectedOrganismId: "${_selectedOrganismId}"');
    print('🔍 DEBUG: _selectedType: $_selectedType');
    print('🔍 DEBUG: _selectedSeverity: $_selectedSeverity');
    
    if (_selectedOrganismName.isNotEmpty) {
      // Gerar resumo do histórico para o organismo selecionado
      await _generateOrganismHistorySummary();
      
      // Dados básicos da ocorrência
      final occurrenceData = {
        'tipo': _selectedType.name,
        'organismo': _selectedOrganismName,
        'organismo_id': _selectedOrganismId,
        'severidade': _selectedSeverity,
        'terco_planta': _selectedPlantSection,
        'fase_organismo': _selectedPhase,
        'temperatura': _currentTemperature,
        'umidade': _currentHumidity,
        'nivel_risco': _riskLevel,
        'tamanho_infestacao': _infestationSize,
      };

      // Calcula severidade enriquecida com IA
      final enrichedSeverity = await _calculateEnrichedSeverity(occurrenceData);
      
      final novaOcorrencia = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'tipo': _selectedType.name,
        'organismo': _selectedOrganismName,
        'organismo_id': _selectedOrganismId,
        // Adicionar campos de compatibilidade para outros módulos
        'organism_name': _selectedOrganismName,
        'name': _selectedOrganismName,
        'subtipo': _selectedOrganismName,
        'severidade': _selectedSeverity,
        'terco_planta': _selectedPlantSection,
        'fase_organismo': _selectedPhase,
        'observacoes': _observationsController.text.trim(),
        'temperatura': _currentTemperature,
        'umidade': _currentHumidity,
        'nivel_risco': _riskLevel,
        'tamanho_infestacao': _infestationSize,
        'fotos': List<String>.from(_imagePaths),
        
        // CAMPOS ENRIQUECIDOS
        'estadio_fenologico': _estadioFenologico,
        'estadio_fenologico_id': _estadioFenologico,
        'tipo_manejo_anterior': List<String>.from(_tipoManejoAnterior),
        'historico_resumo': _historicoResumo,
        'estande_id': _estandeId,
        'impacto_economico_previsto': _impactoEconomicoPrevisto,
        'has_recent_stand': _hasRecentStand,
        'ultimo_estande_data': _ultimoEstande?.dataAvaliacao?.toIso8601String(),
        'ultimo_estande_populacao': _ultimoEstande?.plantasPorHectare,
        'ultimo_estande_germinacao': _ultimoEstande?.eficiencia,
        
        // DADOS DE IA ENRIQUECIDOS
        'severidade_ia': enrichedSeverity is Map ? enrichedSeverity['severity'] : 0,
        'nivel_ia': enrichedSeverity is Map ? enrichedSeverity['level'] : 'Desconhecido',
        'confianca_ia': enrichedSeverity is Map ? enrichedSeverity['confidence'] : 0.0,
        'cor_ia': enrichedSeverity is Map ? enrichedSeverity['color'] : '#000000',
        'recomendacao_ia': enrichedSeverity is Map ? enrichedSeverity['recommendation'] : 'Nenhuma',
        'perda_produtividade_ia': enrichedSeverity is Map ? enrichedSeverity['productivityLoss'] : 0.0,
        'valor_ponderado_ia': enrichedSeverity is Map ? enrichedSeverity['weightedValue'] : 0.0,
        'fatores_ia': enrichedSeverity is Map ? enrichedSeverity['factors'] : [],
        'calculo_ia': enrichedSeverity is Map ? enrichedSeverity['calculation'] : 'Nenhum',
      };
      
      setState(() {
        _ocorrenciasAdicionadas.add(novaOcorrencia);
        // Limpar campos para próxima ocorrência
        _limparCampos();
      });
      
      Logger.info('✅ Ocorrência adicionada com severidade IA: ${enrichedSeverity is Map ? enrichedSeverity['severity'] : 0}');
      print('✅ DEBUG: Ocorrência adicionada com sucesso! Total: ${_ocorrenciasAdicionadas.length}');
    } else {
      print('⚠️ DEBUG: Não foi possível adicionar ocorrência - organismo não selecionado');
      print('⚠️ DEBUG: _selectedOrganismName está vazio: "${_selectedOrganismName}"');
    }
  }

  /// Remove uma ocorrência da lista
  void _removerOcorrencia(String id) {
    setState(() {
      _ocorrenciasAdicionadas.removeWhere((oc) => oc['id'] == id);
    });
  }

  /// Limpa os campos do formulário
  void _limparCampos() {
    _searchController.clear();
    _observationsController.clear();
    _selectedOrganismId = '';
    _selectedOrganismName = '';
    _selectedPlantSection = 'Baixeiro';
    _selectedPhase = '';
    _selectedSeverity = 0;
    _currentTemperature = 0.0;
    _currentHumidity = 0.0;
    _riskLevel = 'Baixo';
    _infestationSize = 0.0;
    _imagePaths.clear();
    _showSuggestions = false;
  }

  /// Inicializa o cache de organismos (USANDO MESMA ABORDAGEM DO CARD ANTIGO)
  Future<void> _initializeOrganismCache() async {
    try {
      if (_isInitialized) return;
      
      print('🔄 NewOccurrenceCard: Inicializando cache de organismos...');
      
      // Garantir que os dados padrão estejam carregados
      try {
        await _cultureImportService.initialize();
        print('✅ NewOccurrenceCard: CultureImportService inicializado');
      } catch (e) {
        print('⚠️ NewOccurrenceCard: Erro ao inicializar CultureImportService: $e');
      }
      
      // Carregar organismos para a cultura atual
      await _loadOrganismsForCrop();
      
      _isInitialized = true;
      print('✅ NewOccurrenceCard: Cache inicializado com sucesso');
      
      // Carregar organismos baseado no tipo selecionado
      _loadOrganisms();
      
      // Carregar dados enriquecidos após inicialização
      _loadEnrichedData();
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro ao inicializar cache: $e');
      // Em caso de erro, tentar carregar organismos diretamente
      _loadOrganisms();
    }
  }

  /// Mapeia nome da cultura para nome do arquivo JSON
  String _getCultureFileName(String cropName) {
    final Map<String, String> cultureFileMap = {
      'Soja': 'organismos_soja.json',
      'Milho': 'organismos_milho.json',
      'Trigo': 'organismos_trigo.json',
      'Feijão': 'organismos_feijao.json',
      'Algodão': 'organismos_algodao.json',
      'Sorgo': 'organismos_sorgo.json',
      'Girassol': 'organismos_girassol.json',
      'Aveia': 'organismos_aveia.json',
      'Gergelim': 'organismos_gergelim.json',
      'Cana-de-açúcar': 'organismos_cana_acucar.json',
      'Tomate': 'organismos_tomate.json',
      'Arroz': 'organismos_arroz.json',
    };
    
    return cultureFileMap[cropName] ?? 'organismos_soja.json';
  }
  
  /// Retorna ícone baseado no tipo de organismo
  String _getOrganismIcon(String type) {
    switch (type) {
      case 'pest':
        return '🐛';
      case 'disease':
        return '🦠';
      case 'weed':
        return '🌿';
      default:
        return '🐛';
    }
  }

  /// Carrega organismos diretamente dos arquivos JSON
  Future<void> _loadOrganismsFromJsonFiles() async {
    try {
      print('🔄 NewOccurrenceCard: Carregando organismos dos arquivos JSON...');
      
      // Mapear nome da cultura para nome do arquivo
      String fileName = _getCultureFileName(widget.cropName);
      print('📁 NewOccurrenceCard: Arquivo JSON: $fileName');
      
      // Carregar arquivo JSON
      final jsonString = await rootBundle.loadString('assets/data/$fileName');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Verificar se tem organismos
      if (jsonData.containsKey('organismos')) {
        final List<dynamic> organismos = jsonData['organismos'];
        print('📊 NewOccurrenceCard: ${organismos.length} organismos encontrados no arquivo');
        
        // Processar cada organismo
        for (final organismo in organismos) {
          final tipo = organismo['tipo']?.toString().toLowerCase() ?? '';
          final categoria = organismo['categoria']?.toString().toLowerCase() ?? '';
          
          // Determinar tipo baseado no campo 'tipo' ou 'categoria'
          String organismType = 'pest'; // padrão
          if (tipo == 'DOENCA' || tipo.contains('doenca') || categoria.contains('doença') || categoria.contains('disease')) {
            organismType = 'disease';
          } else if (tipo == 'PLANTA DANINHA' || tipo.contains('daninha') || categoria.contains('daninha') || categoria.contains('weed')) {
            organismType = 'weed';
          } else if (tipo == 'PRAGA' || tipo.contains('praga') || categoria.contains('praga') || categoria.contains('pest')) {
            organismType = 'pest';
          }
          
          // Adicionar ao cache
          final organismData = {
            'id': organismo['id']?.toString() ?? '',
            'nome': organismo['nome']?.toString() ?? '',
            'nome_cientifico': organismo['nome_cientifico']?.toString() ?? '',
            'tipo': tipo,
            'categoria': categoria,
            'cultura_id': widget.cropName.toLowerCase(),
            'cultura_nome': widget.cropName,
            'descricao': organismo['descricao']?.toString() ?? '',
            'icone': _getOrganismIcon(organismType),
            'ativo': true,
          };
          
          _organismCache[widget.cropName]![organismType]!.add(organismData);
        }
        
        print('✅ NewOccurrenceCard: Organismos carregados dos arquivos JSON:');
        print('  - Pragas: ${_organismCache[widget.cropName]!['pest']!.length}');
        print('  - Doenças: ${_organismCache[widget.cropName]!['disease']!.length}');
        print('  - Plantas daninhas: ${_organismCache[widget.cropName]!['weed']!.length}');
        
      } else {
        print('⚠️ NewOccurrenceCard: Arquivo JSON não contém campo "organismos"');
        throw Exception('Campo "organismos" não encontrado no arquivo JSON');
      }
      
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro ao carregar organismos dos arquivos JSON: $e');
      rethrow;
    }
  }

  /// Carrega organismos de fallback em caso de erro
  void _loadFallbackOrganisms() {
    print('🔄 NewOccurrenceCard: Carregando organismos de fallback...');
    
    // Organismos básicos de fallback
    final fallbackOrganisms = {
      'pest': [
        {
          'id': 'lagarta_soja',
          'nome': 'Lagarta da Soja',
          'nome_cientifico': 'Anticarsia gemmatalis',
          'tipo': 'praga',
          'categoria': 'Praga',
          'cultura_id': 'soja',
          'cultura_nome': 'Soja',
          'descricao': 'Lagarta que ataca folhas da soja',
          'icone': '🐛',
          'ativo': true,
        },
      ],
      'disease': [
        {
          'id': 'ferrugem_soja',
          'nome': 'Ferrugem da Soja',
          'nome_cientifico': 'Phakopsora pachyrhizi',
          'tipo': 'doenca',
          'categoria': 'Doença',
          'cultura_id': 'soja',
          'cultura_nome': 'Soja',
          'descricao': 'Doença fúngica que ataca folhas',
          'icone': '🦠',
          'ativo': true,
        },
      ],
      'weed': [
        {
          'id': 'buva',
          'nome': 'Buva',
          'nome_cientifico': 'Conyza bonariensis',
          'tipo': 'daninha',
          'categoria': 'Planta Daninha',
          'cultura_id': 'soja',
          'cultura_nome': 'Soja',
          'descricao': 'Planta daninha comum na soja',
          'icone': '🌿',
          'ativo': true,
        },
      ],
    };
    
    _organismCache[widget.cropName] = fallbackOrganisms;
    print('✅ NewOccurrenceCard: Organismos de fallback carregados');
  }

  /// Carrega organismos baseado no tipo selecionado
  void _loadOrganisms() {
    if (!_organismCache.containsKey(widget.cropName)) {
      print('⚠️ NewOccurrenceCard: Cache não encontrado para ${widget.cropName}');
      return;
    }
    
    final cache = _organismCache[widget.cropName]!;
    _allOrganisms = [];
    
    switch (_selectedType) {
      case OccurrenceType.pest:
        _allOrganisms = List.from(cache['pest']!);
        break;
      case OccurrenceType.disease:
        _allOrganisms = List.from(cache['disease']!);
        break;
      case OccurrenceType.weed:
        _allOrganisms = List.from(cache['weed']!);
        break;
      case OccurrenceType.deficiency:
        _allOrganisms = List.from(cache['pest']!); // Usar pragas como fallback
        break;
      case OccurrenceType.other:
        _allOrganisms = List.from(cache['pest']!); // Usar pragas como fallback
        break;
    }
    
    print('📊 NewOccurrenceCard: ${_allOrganisms.length} organismos carregados para tipo ${_selectedType.name}');
  }

  /// Carrega dados enriquecidos (estande e histórico)
  Future<void> _loadEnrichedData() async {
    try {
      Logger.info('🔍 Carregando dados enriquecidos para talhão: ${widget.fieldId}');
      
      // 1. Carregar último estande
      await _loadLastStand();
      
      // 2. Verificar se há estande recente
      await _checkRecentStand();
      
      // 3. Carregar histórico de infestação
      await _loadInfestationHistory();
      
      Logger.info('✅ Dados enriquecidos carregados com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados enriquecidos: $e');
    }
  }

  /// Carrega o último estande do talhão
  Future<void> _loadLastStand() async {
    try {
      final lastStand = await _estandeService.getLastStandByTalhao(widget.fieldId);
      
      setState(() {
        _ultimoEstande = lastStand;
        if (lastStand != null) {
          _estadioFenologico = _estandeService.calculateEstadioFenologico(
            lastStand.culturaId ?? 'soja',
            lastStand.diasAposEmergencia ?? 0,
          );
          _estandeId = lastStand.id;
        }
      });
      
      Logger.info(_ultimoEstande != null 
        ? '✅ Último estande carregado: ${_estadioFenologico} (DAE: ${_ultimoEstande!.diasAposEmergencia})'
        : '⚠️ Nenhum estande encontrado');
    } catch (e) {
      Logger.error('❌ Erro ao carregar último estande: $e');
      // Não falhar se houver erro no banco de dados
      setState(() {
        _ultimoEstande = null;
        _estadioFenologico = null;
        _estandeId = null;
      });
    }
  }

  /// Verifica se há estande recente
  Future<void> _checkRecentStand() async {
    try {
      if (_ultimoEstande != null) {
        final daysSinceLastStand = DateTime.now().difference(_ultimoEstande!.dataAvaliacao ?? DateTime.now()).inDays;
        Logger.info('📅 Dias desde último estande: $daysSinceLastStand');
        
        if (daysSinceLastStand > 30) {
          Logger.warning('⚠️ Estande antigo detectado (${daysSinceLastStand} dias)');
        }
      }
    } catch (e) {
      Logger.error('❌ Erro ao verificar estande recente: $e');
    }
  }

  /// Carrega histórico de infestação
  Future<void> _loadInfestationHistory() async {
    try {
      final history = await _historyService.getHistoryByTalhao(widget.fieldId);
      
      if (history.isNotEmpty) {
        _historicoResumo = 'Histórico: ${history.length} ocorrências registradas';
        Logger.info('📊 Histórico carregado: ${history.length} ocorrências');
      } else {
        _historicoResumo = 'Nenhum histórico de infestação encontrado';
        Logger.info('📊 Nenhum histórico encontrado');
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar histórico: $e');
      _historicoResumo = 'Erro ao carregar histórico';
    }
  }

  /// Obtém ID da cultura do módulo culturas da fazenda
  Future<String?> _getCropIdFromFarmCultureModule(String cropName) async {
    try {
      Logger.info('🔍 Buscando ID da cultura "$cropName" no módulo culturas da fazenda...');
      
      // Tentar obter ID da cultura através do serviço
      final cropId = await _culturaService.getCulturaIdByName(cropName);
      
      if (cropId != null) {
        Logger.info('✅ ID da cultura encontrado: $cropId');
        return cropId;
      } else {
        Logger.warning('⚠️ ID da cultura não encontrado, usando nome como fallback');
        return cropName.toLowerCase();
      }
    } catch (e) {
      Logger.error('❌ Erro ao obter ID da cultura do módulo culturas da fazenda: $e');
      return null;
    }
  }

  /// Mostra mensagem de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Limpa o formulário
  void _clearForm() {
    setState(() {
      _selectedOrganismId = '';
      _selectedOrganismName = '';
      _selectedPlantSection = 'Baixeiro';
      _selectedPhase = '';
      _selectedSeverity = 0;
      _infestationSize = 0.0;
      _observationsController.clear();
      _searchController.clear();
      _imagePaths.clear();
      _filteredOrganisms = [];
      _showSuggestions = false;
    });
  }

  /// Converte tipo de ocorrência para string
  String _getOccurrenceTypeString(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'Praga';
      case OccurrenceType.disease:
        return 'Doença';
      case OccurrenceType.weed:
        return 'Planta Daninha';
      case OccurrenceType.deficiency:
        return 'Deficiência';
      case OccurrenceType.other:
        return 'Outro';
    }
  }

  /// Retorna cor baseada na severidade
  Color _getSeverityColor(int severity) {
    if (severity <= 2) return Colors.green;
    if (severity <= 4) return Colors.yellow;
    if (severity <= 6) return Colors.orange;
    if (severity <= 8) return Colors.red;
    return Colors.purple;
  }

  /// Retorna label da severidade
  String _getSeverityLabel(int severity) {
    if (severity <= 2) return 'Baixa';
    if (severity <= 4) return 'Moderada';
    if (severity <= 6) return 'Alta';
    if (severity <= 8) return 'Muito Alta';
    return 'Crítica';
  }

  /// Retorna ícone do risco
  String _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'baixo':
        return '🟢';
      case 'médio':
        return '🟡';
      case 'alto':
        return '🔴';
      default:
        return '⚪';
    }
  }

  /// Retorna fases disponíveis
  List<String> _getAvailablePhases() {
    return ['V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'R1', 'R2', 'R3', 'R4', 'R5', 'R6'];
  }

  /// Converte cor hex para Color
  Color _getAIColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  /// Retorna cor do status CV
  Color _getCvStatusColor() {
    if (!_hasCvData) return Colors.grey;
    return Colors.green;
  }

  /// Retorna ícone do status CV
  IconData _getCvStatusIcon() {
    if (!_hasCvData) return Icons.help_outline;
    return Icons.check_circle;
  }

  /// Carrega dados CV
  Future<void> _loadCvData() async {
    try {
      Logger.info('🔍 Carregando dados CV para talhão: ${widget.fieldId}');
      
      final cvData = await _cvService.getCvDataByTalhao(widget.fieldId);
      
      setState(() {
        _hasCvData = cvData != null;
        if (cvData != null) {
          _cvPlantio = cvData.plantio;
          _tipoManejoAnterior = cvData.tipoManejoAnterior;
          _impactoEconomico = cvData.impactoEconomico;
        }
      });
      
      Logger.info(_hasCvData ? '✅ Dados CV carregados' : '⚠️ Nenhum dado CV encontrado');
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados CV: $e');
      setState(() {
        _hasCvData = false;
      });
    }
  }

  /// Gera resumo do histórico de organismos
  Future<void> _generateOrganismHistorySummary() async {
    try {
      Logger.info('🔍 Gerando resumo do histórico de organismos...');
      
      // Simular geração de resumo baseado no histórico
      if (_historicoResumo?.isNotEmpty == true) {
        _historicoResumo = 'Resumo: ${_historicoResumo} - Análise automática concluída';
      }
      
      Logger.info('✅ Resumo do histórico gerado');
    } catch (e) {
      Logger.error('❌ Erro ao gerar resumo do histórico: $e');
    }
  }

  /// Calcula severidade enriquecida
  Future<int> _calculateEnrichedSeverity(Map<String, dynamic> occurrenceData) async {
    try {
      Logger.info('🔍 Calculando severidade enriquecida...');
      
      int baseSeverity = occurrenceData['severidade'] ?? 0;
      
      // Aplicar fatores de enriquecimento
      if (_hasCvData) {
        baseSeverity = (baseSeverity * 1.1).round(); // +10% se tem dados CV
      }
      
      if (_ultimoEstande != null) {
        baseSeverity = (baseSeverity * 1.05).round(); // +5% se tem estande
      }
      
      // Limitar entre 0 e 10
      return baseSeverity.clamp(0, 10);
    } catch (e) {
      Logger.error('❌ Erro ao calcular severidade enriquecida: $e');
      return occurrenceData['severidade'] ?? 0;
    }
  }

  /// Carrega organismos para a cultura atual
  Future<void> _loadOrganismsForCrop() async {
    try {
      print('🔍 NewOccurrenceCard: Carregando organismos para cultura: ${widget.cropName}');
      print('🔍 NewOccurrenceCard: CultureImportService disponível: ${_cultureImportService != null}');
      
      // Inicializar cache para esta cultura
      _organismCache[widget.cropName] = {
        'pest': [],
        'disease': [],
        'weed': [],
      };
      print('🔍 NewOccurrenceCard: Cache inicializado para ${widget.cropName}');
      
      // Tentar obter ID da cultura
      String? cropId;
      try {
        cropId = await _getCropIdFromFarmCultureModule(widget.cropName);
        print('📊 NewOccurrenceCard: ID da cultura obtido: $cropId');
      } catch (e) {
        print('⚠️ NewOccurrenceCard: Erro ao obter ID da cultura: $e');
        // Usar fallback
        cropId = widget.cropName.toLowerCase();
      }
      
      // Carregar organismos diretamente dos arquivos JSON
      try {
        await _loadOrganismsFromJsonFiles();
        print('✅ NewOccurrenceCard: Organismos carregados dos arquivos JSON');
      } catch (e) {
        print('⚠️ NewOccurrenceCard: Erro ao carregar dos arquivos JSON: $e');
        // Fallback: tentar CultureImportService
        try {
          final pests = await _cultureImportService.getPestsByCrop(cropId ?? widget.cropName);
          print('🔍 DEBUG: Pragas carregadas via CultureImportService: ${pests.length}');
          for (final pest in pests) {
            print('🔍 DEBUG: Praga: ${pest}');
            _organismCache[widget.cropName]!['pest']!.add({
              'id': pest['id']?.toString() ?? '',
              'nome': pest['name'] ?? pest['nome'] ?? pest['title'] ?? '',
              'nome_cientifico': pest['scientificName'] ?? pest['nome_cientifico'] ?? pest['scientific_name'] ?? '',
              'tipo': 'praga',
              'categoria': 'Praga',
              'cultura_id': cropId,
              'cultura_nome': widget.cropName,
              'descricao': pest['description'] ?? pest['descricao'] ?? '',
              'icone': '🐛',
              'ativo': true,
            });
          }
        
        // Carregar doenças
        final diseases = await _cultureImportService.getDiseasesByCrop(cropId ?? widget.cropName);
        print('🔍 DEBUG: Doenças carregadas: ${diseases.length}');
        for (final disease in diseases) {
          print('🔍 DEBUG: Doença: ${disease}');
          _organismCache[widget.cropName]!['disease']!.add({
            'id': disease['id']?.toString() ?? '',
            'nome': disease['name'] ?? disease['nome'] ?? disease['title'] ?? '',
            'nome_cientifico': disease['scientificName'] ?? disease['nome_cientifico'] ?? disease['scientific_name'] ?? '',
            'tipo': 'doenca',
            'categoria': 'Doença',
            'cultura_id': cropId,
            'cultura_nome': widget.cropName,
            'descricao': disease['description'] ?? disease['descricao'] ?? '',
            'icone': '🦠',
            'ativo': true,
          });
        }
        
        // Carregar plantas daninhas
        final weeds = await _cultureImportService.getWeedsByCrop(cropId ?? widget.cropName);
        print('🔍 DEBUG: Plantas daninhas carregadas: ${weeds.length}');
        for (final weed in weeds) {
          print('🔍 DEBUG: Planta daninha: ${weed}');
          _organismCache[widget.cropName]!['weed']!.add({
            'id': weed['id']?.toString() ?? '',
            'nome': weed['name'] ?? weed['nome'] ?? weed['title'] ?? '',
            'nome_cientifico': weed['scientificName'] ?? weed['nome_cientifico'] ?? weed['scientific_name'] ?? '',
            'tipo': 'daninha',
            'categoria': 'Planta Daninha',
            'cultura_id': cropId,
            'cultura_nome': widget.cropName,
            'descricao': weed['description'] ?? weed['descricao'] ?? '',
            'icone': '🌿',
            'ativo': true,
          });
        }
        
        print('📊 NewOccurrenceCard: Organismos carregados para ${widget.cropName}:');
        print('  - Pragas: ${pests.length}');
        print('  - Doenças: ${diseases.length}');
        print('  - Plantas daninhas: ${weeds.length}');
        
      } catch (e) {
        print('⚠️ NewOccurrenceCard: Erro ao carregar organismos específicos, usando fallback: $e');
        _loadFallbackOrganisms();
      }
      
      // Carregar organismos baseado no tipo selecionado
      _loadOrganisms();
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro geral ao carregar organismos para cultura: $e');
      _loadFallbackOrganisms();
    }
  }
  
  /// Carrega organismos diretamente dos arquivos JSON
  Future<void> _loadOrganismsFromJsonFiles() async {
    try {
      print('🔄 NewOccurrenceCard: Carregando organismos dos arquivos JSON...');
      
      // Mapear nome da cultura para nome do arquivo
      String fileName = _getCultureFileName(widget.cropName);
      print('📁 NewOccurrenceCard: Arquivo JSON: $fileName');
      
      // Carregar arquivo JSON
      final jsonString = await rootBundle.loadString('assets/data/$fileName');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Verificar se tem organismos
      if (jsonData.containsKey('organismos')) {
        final List<dynamic> organismos = jsonData['organismos'];
        print('📊 NewOccurrenceCard: ${organismos.length} organismos encontrados no arquivo');
        
        // Processar cada organismo
        for (final organismo in organismos) {
          final tipo = organismo['tipo']?.toString().toLowerCase() ?? '';
          final categoria = organismo['categoria']?.toString().toLowerCase() ?? '';
          
          // Determinar tipo baseado no campo 'tipo' ou 'categoria'
          String organismType = 'pest'; // padrão
          if (tipo == 'DOENCA' || tipo.contains('doenca') || categoria.contains('doença') || categoria.contains('disease')) {
            organismType = 'disease';
          } else if (tipo == 'PLANTA DANINHA' || tipo.contains('daninha') || categoria.contains('daninha') || categoria.contains('weed')) {
            organismType = 'weed';
          } else if (tipo == 'PRAGA' || tipo.contains('praga') || categoria.contains('praga') || categoria.contains('pest')) {
            organismType = 'pest';
          }
          
          // Adicionar ao cache
          final organismData = {
            'id': organismo['id']?.toString() ?? '',
            'nome': organismo['nome']?.toString() ?? '',
            'nome_cientifico': organismo['nome_cientifico']?.toString() ?? '',
            'tipo': tipo,
            'categoria': categoria,
            'cultura_id': widget.cropName.toLowerCase(),
            'cultura_nome': widget.cropName,
            'descricao': organismo['descricao']?.toString() ?? '',
            'icone': _getOrganismIcon(organismType),
            'ativo': true,
          };
          
          _organismCache[widget.cropName]![organismType]!.add(organismData);
        }
        
        print('✅ NewOccurrenceCard: Organismos carregados dos arquivos JSON:');
        print('  - Pragas: ${_organismCache[widget.cropName]!['pest']!.length}');
        print('  - Doenças: ${_organismCache[widget.cropName]!['disease']!.length}');
        print('  - Plantas daninhas: ${_organismCache[widget.cropName]!['weed']!.length}');
        
      } else {
        print('⚠️ NewOccurrenceCard: Arquivo JSON não contém campo "organismos"');
        throw Exception('Campo "organismos" não encontrado no arquivo JSON');
      }
      
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro ao carregar organismos dos arquivos JSON: $e');
      rethrow;
    }
  }
  
  /// Mapeia nome da cultura para nome do arquivo JSON
  String _getCultureFileName(String cropName) {
    final Map<String, String> cultureFileMap = {
      'Soja': 'organismos_soja.json',
      'Milho': 'organismos_milho.json',
      'Trigo': 'organismos_trigo.json',
      'Feijão': 'organismos_feijao.json',
      'Algodão': 'organismos_algodao.json',
      'Sorgo': 'organismos_sorgo.json',
      'Girassol': 'organismos_girassol.json',
      'Aveia': 'organismos_aveia.json',
      'Gergelim': 'organismos_gergelim.json',
      'Cana-de-açúcar': 'organismos_cana_acucar.json',
      'Tomate': 'organismos_tomate.json',
      'Arroz': 'organismos_arroz.json',
    };
    
    return cultureFileMap[cropName] ?? 'organismos_soja.json';
  }
  
  /// Retorna ícone baseado no tipo de organismo
  String _getOrganismIcon(String type) {
    switch (type) {
      case 'pest':
        return '🐛';
      case 'disease':
        return '🦠';
      case 'weed':
        return '🌿';
      default:
        return '🐛';
    }
  }
  
  /// Carrega organismos de fallback em caso de erro
  void _loadFallbackOrganisms() {
    print('🔄 NewOccurrenceCard: Carregando organismos de fallback...');
    
    // Organismos básicos de fallback
    final fallbackOrganisms = {
      'pest': [
        {
          'id': 'pest_1',
          'nome': 'Lagarta da Soja',
          'nome_cientifico': 'Anticarsia gemmatalis',
          'tipo': 'praga',
          'categoria': 'Praga',
          'cultura_id': widget.cropName,
          'cultura_nome': widget.cropName,
          'descricao': 'Principal praga da soja',
          'icone': '🐛',
          'ativo': true,
        },
      ],
      'disease': [
        {
          'id': 'disease_1',
          'nome': 'Ferrugem Asiática',
          'nome_cientifico': 'Phakopsora pachyrhizi',
          'tipo': 'doenca',
          'categoria': 'Doença',
          'cultura_id': widget.cropName,
          'cultura_nome': widget.cropName,
          'descricao': 'Doença fúngica da soja',
          'icone': '🦠',
          'ativo': true,
        },
      ],
      'weed': [
        {
          'id': 'weed_1',
          'nome': 'Buva',
          'nome_cientifico': 'Conyza bonariensis',
          'tipo': 'daninha',
          'categoria': 'Planta Daninha',
          'cultura_id': widget.cropName,
          'cultura_nome': widget.cropName,
          'descricao': 'Planta daninha comum',
          'icone': '🌿',
          'ativo': true,
        },
      ],
    };
    
    _organismCache[widget.cropName] = fallbackOrganisms;
    print('✅ NewOccurrenceCard: Organismos de fallback carregados');
  }

  /// Carrega organismos do cache baseado no tipo selecionado (USANDO MESMA ABORDAGEM DO CARD ANTIGO)
  void _loadOrganisms() {
    try {
      // Usar cache em vez de fazer nova consulta
      if (!_organismCache.containsKey(widget.cropName)) {
        print('⚠️ NewOccurrenceCard: Cache não encontrado para cultura: ${widget.cropName}');
        // Tentar recarregar o cache
        _loadOrganismsForCrop();
        return;
      }
      
      // Determinar tipo de organismo baseado no tipo selecionado
      String organismType;
      switch (_selectedType) {
        case OccurrenceType.pest:
          organismType = 'pest';
          break;
        case OccurrenceType.disease:
          organismType = 'disease';
          break;
        case OccurrenceType.weed:
          organismType = 'weed';
          break;
        default:
          organismType = 'pest';
      }
      
      // Obter organismos do cache
      final organisms = _organismCache[widget.cropName]![organismType] ?? [];
      
      print('🎯 NewOccurrenceCard: Carregando ${organisms.length} organismos do tipo $organismType para ${widget.cropName}');
      
      setState(() {
        _allOrganisms = organisms;
        _filteredOrganisms = organisms;
      });
      
      print('✅ NewOccurrenceCard: ${organisms.length} organismos carregados do cache');
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro ao carregar organismos do cache: $e');
      setState(() {
        _allOrganisms = [];
        _filteredOrganisms = [];
      });
    }
  }

  /// Carrega dados enriquecidos (estande e histórico)
  Future<void> _loadEnrichedData() async {
    try {
      Logger.info('🔍 Carregando dados enriquecidos para talhão: ${widget.fieldId}');
      
      // 1. Carregar último estande
      await _loadLastStand();
      
      // 2. Verificar se há estande recente
      await _checkRecentStand();
      
      // 3. Carregar histórico de infestação
      await _loadInfestationHistory();
      
      Logger.info('✅ Dados enriquecidos carregados com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados enriquecidos: $e');
    }
  }

  /// Carrega o último estande do talhão
  Future<void> _loadLastStand() async {
    try {
      final lastStand = await _estandeService.getLastStandByTalhao(widget.fieldId);
      
      setState(() {
        _ultimoEstande = lastStand;
        if (lastStand != null) {
          _estadioFenologico = _estandeService.calculateEstadioFenologico(
            lastStand.culturaId ?? 'soja',
            lastStand.diasAposEmergencia ?? 0,
          );
          _estandeId = lastStand.id;
        }
      });
      
      Logger.info(_ultimoEstande != null 
        ? '✅ Último estande carregado: ${_estadioFenologico} (DAE: ${_ultimoEstande!.diasAposEmergencia})'
        : '⚠️ Nenhum estande encontrado');
    } catch (e) {
      Logger.error('❌ Erro ao carregar último estande: $e');
      // Não falhar se houver erro no banco de dados
      setState(() {
        _ultimoEstande = null;
        _estadioFenologico = null;
        _estandeId = null;
      });
    }
  }

  /// Verifica se há estande recente
  Future<void> _checkRecentStand() async {
    try {
      final hasRecent = await _estandeService.hasRecentStand(widget.fieldId);
      
      setState(() {
        _hasRecentStand = hasRecent;
      });
      
      Logger.info('📅 Estande recente: ${hasRecent ? 'Sim' : 'Não'}');
    } catch (e) {
      Logger.error('❌ Erro ao verificar estande recente: $e');
    }
  }

  /// Carrega histórico de infestação
  Future<void> _loadInfestationHistory() async {
    try {
      // Carrega histórico geral do talhão
      final history = await _historyService.getTalhaoInfestationHistory(
        talhaoId: widget.fieldId,
        limit: 5,
      );
      
      if (history.isNotEmpty) {
        final lastOccurrence = history.first;
        final daysSince = DateTime.now().difference(lastOccurrence.createdAt).inDays;
        
        setState(() {
          _historySummary = 'Última infestação há $daysSince dias: ${lastOccurrence.name} (${lastOccurrence.infestationIndex.toStringAsFixed(1)}%)';
        });
      } else {
        setState(() {
          _historySummary = 'Nenhum histórico de infestação encontrado';
        });
      }
      
      Logger.info('📈 Histórico carregado: ${history.length} ocorrências');
    } catch (e) {
      Logger.error('❌ Erro ao carregar histórico: $e');
    }
  }

  /// Gera resumo do histórico para organismo específico
  Future<void> _generateOrganismHistorySummary() async {
    if (_selectedOrganismName.isEmpty) {
      print('⚠️ DEBUG: _generateOrganismHistorySummary - organismo vazio');
      return;
    }
    
    print('🔍 DEBUG: Gerando resumo do histórico para: $_selectedOrganismName');
    
    try {
      final summary = await _historyService.generateHistorySummary(
        talhaoId: widget.fieldId,
        organismId: _selectedOrganismName,
      );
      
      setState(() {
        _historicoResumo = summary;
      });
      
      print('✅ DEBUG: Resumo do histórico gerado com sucesso');
      Logger.info('📝 Resumo do histórico gerado para $_selectedOrganismName');
    } catch (e) {
      print('❌ DEBUG: Erro ao gerar resumo do histórico: $e');
      Logger.error('❌ Erro ao gerar resumo do histórico: $e');
    }
  }

  /// Calcula severidade enriquecida com IA
  Future<Map<String, dynamic>> _calculateEnrichedSeverity(Map<String, dynamic> occurrenceData) async {
    try {
      Logger.info('🧠 Calculando severidade enriquecida para ocorrência');
      
      // Obtém dados do estande
      final standData = await _estandeService.getEstandeDataForOccurrence(widget.fieldId);
      
      // Calcula severidade ponderada com IA
      final enrichedSeverity = _aiService.calculateEnrichedSeverity(
        organismId: _selectedOrganismId,
        occurrenceData: occurrenceData,
        standData: standData,
        historySummary: _historySummary.isEmpty ? null : _historySummary,
        previousManagement: _tipoManejoAnterior,
        economicImpact: _impactoEconomicoPrevisto,
      );
      
      Logger.info('✅ Severidade enriquecida calculada: ${enrichedSeverity['severity']}');
      return enrichedSeverity;
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular severidade enriquecida: $e');
      // Fallback para severidade simples
      return {
        'severity': 'medio',
        'level': 'medio',
        'confidence': 0.5,
        'color': '#FF9800',
        'recommendation': 'Avaliar situação',
        'productivityLoss': 8.0,
      };
    }
  }

  /// Obtém o ID da cultura do módulo culturas da fazenda (FUNCIONALIDADE ATUAL MANTIDA)
  Future<String?> _getCropIdFromFarmCultureModule(String cropName) async {
    try {
      Logger.info('🔍 Buscando cultura no módulo culturas da fazenda: $cropName');
      
      final culturas = await _culturaService.listarCulturas();
      Logger.info('📊 Total de culturas no módulo culturas da fazenda: ${culturas.length}');
      
      for (final cultura in culturas) {
        Logger.info('  - Cultura: ${cultura['nome']} (ID: ${cultura['id']})');
        if (cultura['nome'].toLowerCase() == cropName.toLowerCase()) {
          Logger.info('✅ Cultura encontrada no módulo culturas da fazenda: ${cultura['nome']} (ID: ${cultura['id']})');
          return cultura['id'].toString();
        }
      }
      
      Logger.warning('⚠️ Cultura não encontrada no módulo culturas da fazenda: $cropName');
      return null;
    } catch (e) {
      Logger.error('❌ Erro ao obter ID da cultura do módulo culturas da fazenda: $e');
      return null;
    }
  }

  /// Filtra organismos baseado no tipo selecionado e busca (OTIMIZADO)
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    // Cancelar timer anterior
    _searchDebounceTimer?.cancel();
    
    // Para queries muito curtas, limpar resultados imediatamente
    if (query.length < 2 && query.isNotEmpty) {
      setState(() {
        _filteredOrganisms = [];
        _showSuggestions = false;
      });
      return;
    }
    
    // Para query vazia, limpar imediatamente
    if (query.isEmpty) {
      setState(() {
        _filteredOrganisms = [];
        _showSuggestions = false;
      });
      return;
    }
    
    // Usar debounce para evitar muitas atualizações
    _searchDebounceTimer = Timer(Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final filtered = _allOrganisms.where((organism) {
        final name = (organism['nome'] ?? '').toLowerCase();
        final scientificName = (organism['nome_cientifico'] ?? '').toLowerCase();
        return name.contains(query) || scientificName.contains(query);
      }).toList();
      
      if (mounted) {
        setState(() {
          _filteredOrganisms = filtered;
          _showSuggestions = filtered.isNotEmpty;
        });
      }
    });
  }

  /// Seleciona um organismo (FUNCIONALIDADE ATUAL MANTIDA)
  void _selectOrganism(Map<String, dynamic> organism) {
    final organismId = organism['id']?.toString() ?? '';
    final organismName = organism['nome']?.toString() ?? '';
    
    print('🔍 DEBUG: Selecionando organismo...');
    print('🔍 DEBUG: organismId: "$organismId"');
    print('🔍 DEBUG: organismName: "$organismName"');
    
    setState(() {
      _selectedOrganismId = organismId;
      _selectedOrganismName = organismName;
      _searchController.text = organismName;
      _showSuggestions = false;
      _selectedPhase = organism['fases']?.isNotEmpty == true ? organism['fases'][0] : '';
    });
    
    print('✅ DEBUG: Organismo selecionado com sucesso!');
    print('✅ DEBUG: _selectedOrganismId: "${_selectedOrganismId}"');
    print('✅ DEBUG: _selectedOrganismName: "${_selectedOrganismName}"');
    
    Logger.info('✅ Organismo selecionado: $organismName (ID: $organismId)');
  }



  /// Calcula nível de risco baseado nas condições
  String _calculateRiskLevel() {
    if (_currentTemperature > 30 && _currentHumidity > 70) return 'Alto';
    if (_currentTemperature > 25 && _currentHumidity > 60) return 'Médio';
    return 'Baixo';
  }

  /// Salva a ocorrência com dados enriquecidos
  void _saveOccurrence() {
    if (_selectedOrganismId.isEmpty || _selectedSeverity == 0) {
      _showErrorSnackBar('Preencha todos os campos obrigatórios');
      return;
    }

    final occurrence = {
      // Dados básicos (mantidos)
      'organism_id': _selectedOrganismId,
      'organism_name': _selectedOrganismName,
      'organism_type': _getOccurrenceTypeString(_selectedType),
      'plant_section': _selectedPlantSection,
      'observations': _observationsController.text.trim(),
      'crop_name': widget.cropName,
      'field_id': widget.fieldId,
      'image_paths': _imagePaths,
      'created_at': DateTime.now().toIso8601String(),
      
      // DADOS AMBIENTAIS
      'severity': _selectedSeverity, // 0-10
      'phase': _selectedPhase,
      'temperature': _currentTemperature,
      'humidity': _currentHumidity,
      'risk_level': _riskLevel,
      'infestation_size': _infestationSize, // Tamanho em mm
    };

    widget.onOccurrenceAdded(occurrence);
    _clearForm();
  }

  /// Limpa o formulário
  void _clearForm() {
    setState(() {
      _selectedOrganismId = '';
      _selectedOrganismName = '';
      _searchController.clear();
      _observationsController.clear();
      _selectedPlantSection = 'Baixeiro';
      _selectedPhase = '';
      _selectedSeverity = 0;
      _infestationSize = 0.0;
      _showSuggestions = false;
      _imagePaths.clear();
    });
  }

  /// Mostra mensagem de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostra mensagem de sucesso
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
        border: Border.all(color: Colors.blue.shade300, width: 3),
      ),
      child: Column(
        children: [
          // Indicador visual de que o modal está funcionando
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8),
            color: Colors.blue.shade50,
            child: Text(
              '📋 Nova Ocorrência - Modal Funcionando',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  ' Nova Ocorrência',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NOVO: Bloco de Dados do Talhão (Integração Automática)
                  _buildTalhaoDataCard(),
                  
                  // Lista de ocorrências adicionadas
                  if (_ocorrenciasAdicionadas.isNotEmpty) ...[
                    _buildOcorrenciasList(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Conteúdo
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Seletor de tipo (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildTypeSelector(),
                        SizedBox(height: 16),
                        
                        // Campo de busca de organismo (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildOrganismSearchField(),
                        SizedBox(height: 16),
                        
                        // NOVA SEÇÃO: Tamanho da Infestação
                        _buildInfestationSizeCard(),
                        SizedBox(height: 16),
                        
                        // NOVA SEÇÃO: Condições Ambientais
                        _buildEnvironmentalConditions(),
                        SizedBox(height: 16),
                        
                        // NOVA SEÇÃO: Escala de Severidade Visual
                        _buildSeverityScale(),
                        SizedBox(height: 16),
                        
                        // Seletor de terço da planta (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildPlantSectionSelector(),
                        SizedBox(height: 16),
                        
                        // NOVO: Seletor de fase
                        _buildPhaseSelector(),
                        SizedBox(height: 16),
                        
                        // Campo de observações (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildObservationsField(),
                        SizedBox(height: 16),
                        
                        // NOVA SEÇÃO: Dados Aprimorados FortSmart
                        _buildEnrichedDataSection(),
                        SizedBox(height: 16),
                        
                        // Seção de fotos (MELHORADA)
                        _buildPhotosSection(),
                        SizedBox(height: 30),
                        
                        // Botões de ação (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildActionButtons(),
                        SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// NOVO: Bloco de Dados do Talhão (Integração Automática)
  Widget _buildTalhaoDataCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.agriculture, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌱 Dados do Talhão',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Integração automática com Estande de Plantas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Indicador de status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _hasRecentStand ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasRecentStand ? Icons.check_circle : Icons.warning,
                      size: 12,
                      color: _hasRecentStand ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _hasRecentStand ? 'Atualizado' : 'Desatualizado',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _hasRecentStand ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Dados do estande
          if (_ultimoEstande != null) ...[
            Row(
              children: [
                Flexible(
                  child: _buildDataItem(
                    icon: Icons.eco,
                    label: 'Cultura',
                    value: widget.cropName,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: _buildDataItem(
                    icon: Icons.calendar_today,
                    label: 'Estágio',
                    value: _estadioFenologico ?? 'Não definido',
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: _buildDataItem(
                    icon: Icons.grass,
                    label: 'População',
                    value: '${_ultimoEstande!.plantasPorHectare?.round() ?? 0} plantas/ha',
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: _buildDataItem(
                    icon: Icons.timeline,
                    label: 'DAE',
                    value: '${_ultimoEstande!.diasAposEmergencia ?? 0} dias',
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: _buildDataItem(
                    icon: Icons.date_range,
                    label: 'Último Estande',
                    value: _ultimoEstande!.dataAvaliacao != null 
                        ? '${_ultimoEstande!.dataAvaliacao!.day}/${_ultimoEstande!.dataAvaliacao!.month}/${_ultimoEstande!.dataAvaliacao!.year}'
                        : 'Data não disponível',
                    color: Colors.indigo.shade700,
                  ),
                ),
                SizedBox(width: 12),
                Flexible(
                  child: _buildDataItem(
                    icon: Icons.analytics,
                    label: 'Eficiência',
                    value: _ultimoEstande!.eficiencia != null 
                        ? '${(_ultimoEstande!.eficiencia! * 100).toStringAsFixed(0)}%'
                        : 'N/A',
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Estado sem estande
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Nenhum Estande de Plantas Encontrado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cultura: ${widget.cropName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '⚠️ Para maior precisão no diagnóstico, registre um estande de plantas neste talhão.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Constrói item de dados do talhão
  Widget _buildDataItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// NOVA SEÇÃO: Tamanho da Infestação
  Widget _buildInfestationSizeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📏 TAMANHO DA INFESTAÇÃO',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          SizedBox(height: 8),
          
          TextFormField(
            initialValue: _infestationSize > 0 ? _infestationSize.toStringAsFixed(1) : '',
            decoration: InputDecoration(
              labelText: 'Tamanho (mm)',
              hintText: 'Ex: 15.0',
              prefixIcon: Icon(Icons.straighten, color: Colors.purple.shade600, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final size = double.tryParse(value);
              if (size != null) {
                setState(() {
                  _infestationSize = size;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  /// NOVA SEÇÃO: Condições Ambientais (EDITÁVEIS)
  Widget _buildEnvironmentalConditions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌡️ CONDIÇÕES AMBIENTAIS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 8),
          
          // Campos editáveis
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _currentTemperature > 0 ? _currentTemperature.toStringAsFixed(1) : '',
                  decoration: InputDecoration(
                    labelText: 'Temp (°C)',
                    hintText: '25.0',
                    prefixIcon: Icon(Icons.thermostat, color: Colors.orange.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final temp = double.tryParse(value);
                    if (temp != null) {
                      setState(() {
                        _currentTemperature = temp;
                        _riskLevel = _calculateRiskLevel();
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _currentHumidity > 0 ? _currentHumidity.toStringAsFixed(0) : '',
                  decoration: InputDecoration(
                    labelText: 'Umidade (%)',
                    hintText: '80',
                    prefixIcon: Icon(Icons.water_drop, color: Colors.blue.shade600, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final humidity = double.tryParse(value);
                    if (humidity != null) {
                      setState(() {
                        _currentHumidity = humidity;
                        _riskLevel = _calculateRiskLevel();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Nível de risco calculado
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600),
              SizedBox(width: 8),
              Text('Risco: ${_getRiskIcon(_riskLevel)} $_riskLevel'),
            ],
          ),
        ],
      ),
    );
  }

  /// NOVA SEÇÃO: Escala de Severidade Visual
  Widget _buildSeverityScale() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 SEVERIDADE VISUAL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          SizedBox(height: 8),
          
          // Escala 0-10
          Container(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(11, (index) {
                  final color = _getSeverityColor(index);
                  final isSelected = _selectedSeverity == index;
                
                return Container(
                  width: 30,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSeverity = index),
                        child: Container(
                          height: 32,
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.3),
                            border: Border.all(color: color, width: isSelected ? 2 : 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ),
            ),
          ),
          
          SizedBox(height: 8),
          
          // Labels da escala
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🟢 Baixo', style: TextStyle(fontSize: 8)),
              Text('🟡 Médio', style: TextStyle(fontSize: 8)),
              Text('🟠 Alto', style: TextStyle(fontSize: 8)),
              Text('🔴 Crítico', style: TextStyle(fontSize: 8)),
            ],
          ),
          
          SizedBox(height: 8),
          
          // Severidade selecionada
          if (_selectedSeverity > 0)
            Text(
              '${_getSeverityLabel(_selectedSeverity)} ($_selectedSeverity/10)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getSeverityColor(_selectedSeverity),
              ),
            ),
        ],
      ),
    );
  }

  /// Constrói o seletor de tipo (FUNCIONALIDADE ATUAL MANTIDA)
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione o Tipo:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                'Praga',
                Icons.bug_report,
                OccurrenceType.pest,
                Colors.orange,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildTypeButton(
                'Doença',
                Icons.coronavirus,
                OccurrenceType.disease,
                Colors.red,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildTypeButton(
                'Daninha',
                Icons.grass,
                OccurrenceType.weed,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói botão de tipo (FUNCIONALIDADE ATUAL MANTIDA)
  Widget _buildTypeButton(String label, IconData icon, OccurrenceType type, Color color) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedOrganismId = '';
          _selectedOrganismName = '';
          _searchController.clear();
        });
        _loadOrganisms();
        Logger.info('🔄 Tipo alterado para: $type - recarregando organismos');
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 20,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói campo de busca de organismo (FUNCIONALIDADE ATUAL MANTIDA)
  Widget _buildOrganismSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organismo:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        Container(
          width: double.infinity,
          child: TextFormField(
            controller: _searchController,
            onChanged: (value) {
              // Atualizar o texto imediatamente para responsividade
              setState(() {
                // Apenas atualizar o estado visual, sem processamento pesado
              });
              // Processar busca com debounce
              _onSearchChanged();
            },
            decoration: InputDecoration(
              hintText: 'Buscar organismo...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        
        // Sugestões
        if (_showSuggestions && _filteredOrganisms.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            constraints: BoxConstraints(
              maxHeight: 200, // Limitar altura para evitar overflow
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _filteredOrganisms.take(5).map((organism) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      organism['nome'] ?? '',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      organism['nome_cientifico'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectOrganism(organism),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  /// Constrói seletor de terço da planta (FUNCIONALIDADE ATUAL MANTIDA)
  Widget _buildPlantSectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terço da Planta:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedPlantSection,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: ['Baixeiro', 'Médio', 'Superior'].map((section) {
            return DropdownMenuItem(
              value: section,
              child: Text(section),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPlantSection = value ?? 'Baixeiro');
          },
        ),
      ],
    );
  }

  /// NOVO: Constrói seletor de fase
  Widget _buildPhaseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fase do Organismo:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedPhase.isEmpty ? null : _selectedPhase,
          decoration: InputDecoration(
            hintText: 'Selecione a fase',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _getAvailablePhases().map((phase) {
            return DropdownMenuItem(
              value: phase,
              child: Text(phase),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedPhase = value ?? '');
          },
        ),
      ],
    );
  }

  /// Constrói campo de observações (FUNCIONALIDADE ATUAL MANTIDA)
  Widget _buildObservationsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observações:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: _observationsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Descreva as observações...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  /// NOVA SEÇÃO: Dados Aprimorados FortSmart
  Widget _buildEnrichedDataSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com ícone
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue.shade700, size: 20),
              SizedBox(width: 8),
              Text(
                'Dados Complementares',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Estádio Fenológico
          _buildEstadioFenologicoField(),
          SizedBox(height: 12),
          
          // CV% do Plantio
          _buildCvPlantioField(),
          SizedBox(height: 12),
          
          // Tipo de Manejo Anterior
          _buildTipoManejoAnteriorField(),
          SizedBox(height: 12),
          
          // Histórico Resumido
          _buildHistoricoResumoField(),
          SizedBox(height: 12),
          
          // Impacto Econômico Previsto
          _buildImpactoEconomicoField(),
          SizedBox(height: 12),
          
          // Resultados da IA (se houver ocorrências)
          if (_ocorrenciasAdicionadas.isNotEmpty)
            _buildAIResultsSection(),
        ],
      ),
    );
  }

  /// Campo de estádio fenológico
  Widget _buildEstadioFenologicoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.eco, size: 16, color: Colors.green.shade700),
            SizedBox(width: 4),
            Text(
              'Estádio Fenológico',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _estadioFenologico != null ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _estadioFenologico ?? 'Carregando...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _estadioFenologico != null ? Colors.green.shade800 : Colors.grey.shade600,
                  ),
                ),
              ),
              if (_hasRecentStand)
                Icon(Icons.check_circle, color: Colors.green, size: 16)
              else
                Icon(Icons.warning, color: Colors.orange, size: 16),
            ],
          ),
        ),
        if (!_hasRecentStand)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '⚠️ Nenhum estande recente encontrado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ),
      ],
    );
  }

  /// Campo de tipo de manejo anterior
  Widget _buildTipoManejoAnteriorField() {
    final tiposManejo = _estandeService.getTiposManejoAnterior();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.agriculture, size: 16, color: Colors.brown.shade700),
            SizedBox(width: 4),
            Text(
              'Tipo de Manejo Anterior',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tiposManejo.map((tipo) {
            final isSelected = _tipoManejoAnterior.contains(tipo['id']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tipoManejoAnterior.remove(tipo['id']);
                  } else {
                    _tipoManejoAnterior.add(tipo['id']);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? tipo['cor'].withOpacity(0.2) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? tipo['cor'] : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tipo['icone'],
                      size: 14,
                      color: isSelected ? tipo['cor'] : Colors.grey.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      tipo['nome'],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? tipo['cor'] : Colors.grey.shade600,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Campo de histórico resumido
  Widget _buildHistoricoResumoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 16, color: Colors.purple.shade700),
            SizedBox(width: 4),
            Text(
              'Histórico Resumido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Text(
            _historySummary.isEmpty ? 'Nenhum histórico encontrado' : _historySummary,
            style: TextStyle(
              fontSize: 13,
              color: _historySummary.isEmpty ? Colors.grey.shade600 : Colors.purple.shade800,
              fontStyle: _historySummary.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de impacto econômico previsto
  Widget _buildImpactoEconomicoField() {
    final opcoesImpacto = _estandeService.getImpactoEconomicoOptions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_down, size: 16, color: Colors.red.shade700),
            SizedBox(width: 4),
            Text(
              'Impacto Econômico Previsto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: opcoesImpacto.map((opcao) {
            final isSelected = _impactoEconomicoPrevisto != null && 
                              _impactoEconomicoPrevisto! >= opcao['valorMin'] && 
                              _impactoEconomicoPrevisto! <= opcao['valorMax'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _impactoEconomicoPrevisto = opcao['valorMax'].toDouble();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? opcao['cor'].withOpacity(0.2) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? opcao['cor'] : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  opcao['nome'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? opcao['cor'] : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_impactoEconomicoPrevisto != null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Impacto estimado: ${_impactoEconomicoPrevisto!.toStringAsFixed(1)}% na produtividade',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// Seção de resultados da IA
  Widget _buildAIResultsSection() {
    if (_ocorrenciasAdicionadas.isEmpty) return SizedBox.shrink();
    
    // Pega a última ocorrência para mostrar os resultados da IA
    final lastOccurrence = _ocorrenciasAdicionadas.last;
    final aiSeverity = lastOccurrence['severidade_ia'];
    final aiConfidence = lastOccurrence['confianca_ia'];
    final aiRecommendation = lastOccurrence['recomendacao_ia'];
    final aiProductivityLoss = lastOccurrence['perda_produtividade_ia'];
    final aiColor = lastOccurrence['cor_ia'];
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAIColorFromHex(aiColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAIColorFromHex(aiColor), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Análise
          Row(
            children: [
              Icon(Icons.analytics, color: _getAIColorFromHex(aiColor), size: 20),
              SizedBox(width: 8),
              Text(
                'Análise - Última Ocorrência',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getAIColorFromHex(aiColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Severidade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Severidade:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAIColorFromHex(aiColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  aiSeverity?.toString().toUpperCase() ?? 'N/A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Confiança da Análise
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Precisão:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(aiConfidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getAIColorFromHex(aiColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // Perda de produtividade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perda Estimada:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${aiProductivityLoss?.toStringAsFixed(1) ?? 'N/A'}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Recomendação
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAIColorFromHex(aiColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendação:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getAIColorFromHex(aiColor),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  aiRecommendation?.toString() ?? 'Nenhuma recomendação disponível',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Converte cor hex para Color
  Color _getAIColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.grey;
    
    try {
      // Remove # se presente
      String color = hexColor.replaceAll('#', '');
      // Adiciona FF para alpha se não presente
      if (color.length == 6) color = 'FF$color';
      return Color(int.parse(color, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// Constrói seção de fotos (MELHORADA)
  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        
        // Botões de captura
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  print('📷 Botão câmera pressionado');
                  
                  try {
                    // Verificar permissões primeiro
                    final cameraStatus = await Permission.camera.request();
                    if (!cameraStatus.isGranted) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Permissão da câmera negada. Habilite nas configurações.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    
                    final imagePath = await MediaHelper.captureImage(context);
                    print('📷 Retorno do MediaHelper: $imagePath');
                    
                    if (imagePath != null) {
                      // Verificar se arquivo existe antes de adicionar
                      final file = File(imagePath);
                      final exists = await file.exists();
                      print('📷 Arquivo existe? $exists');
                      
                      if (exists) {
                        final size = await file.length();
                        print('📷 Tamanho: $size bytes');
                        
                        if (size > 0) {
                          setState(() {
                            _imagePaths.add(imagePath);
                            print('✅ Imagem adicionada. Total: ${_imagePaths.length}');
                          });
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Foto capturada com sucesso!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          print('❌ Arquivo vazio');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro: Arquivo de imagem vazio'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        print('❌ Arquivo não existe');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro: Arquivo não foi salvo'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      print('❌ MediaHelper retornou null');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Captura cancelada ou falhou'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('❌ Erro na captura: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao capturar foto: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: Icon(Icons.camera_alt, size: 18),
                label: Text('📸 Câmera', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  print('🖼 Botão galeria pressionado');
                  final imagePath = await MediaHelper.pickImage(context);
                  print('🖼 Retorno do MediaHelper: $imagePath');
                  
                  if (imagePath != null) {
                    // Verificar se arquivo existe antes de adicionar
                    final file = File(imagePath);
                    final exists = await file.exists();
                    print('🖼 Arquivo existe? $exists');
                    
                    if (exists) {
                      final size = await file.length();
                      print('🖼 Tamanho: $size bytes');
                      
                      if (size > 0) {
                        setState(() {
                          _imagePaths.add(imagePath);
                          print('✅ Imagem adicionada. Total: ${_imagePaths.length}');
                        });
                      }
                    }
                  }
                },
                icon: Icon(Icons.photo_library, size: 18),
                label: Text('📁 Galeria', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        if (_imagePaths.isNotEmpty)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      // Preview da imagem com toque
                      GestureDetector(
                        onTap: () => _showImagePreview(_imagePaths[index]),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<bool>(
                              future: File(_imagePaths[index]).exists(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                                
                                if (snapshot.data == true) {
                                  return Image.file(
                                    File(_imagePaths[index]),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('❌ ERROR ao carregar imagem: $error');
                                      print('❌ Caminho: ${_imagePaths[index]}');
                                      return Container(
                                        color: Colors.red[100],
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, color: Colors.red[600], size: 20),
                                            SizedBox(height: 2),
                                            Text(
                                              'Erro',
                                              style: TextStyle(fontSize: 8, color: Colors.red[600]),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  return Container(
                                    color: Colors.orange[100],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange[600], size: 20),
                                        SizedBox(height: 2),
                                        Text(
                                          'Não existe',
                                          style: TextStyle(fontSize: 8, color: Colors.orange[600]),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      // Botão de remoção
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imagePaths.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Imagem removida'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Mostra preview da imagem em tela cheia
  void _showImagePreview(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // Imagem em tela cheia
              Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white, size: 64),
                            SizedBox(height: 16),
                            Text(
                              'Erro ao carregar imagem',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Caminho: $imagePath',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Botão de fechar
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Constrói botões de ação (FUNCIONALIDADE ATUAL MANTIDA)
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão para adicionar ocorrência
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _adicionarOcorrencia,
            icon: Icon(Icons.add),
            label: Text('Adicionar Ocorrência'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Botões de ação
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clearForm,
                child: Text('Limpar'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _ocorrenciasAdicionadas.isNotEmpty ? _saveAllOccurrences : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ocorrenciasAdicionadas.isNotEmpty ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text('Salvar (${_ocorrenciasAdicionadas.length})'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _ocorrenciasAdicionadas.isNotEmpty ? _saveAndAdvance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ocorrenciasAdicionadas.isNotEmpty ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text('Salvar e Avançar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói a lista de ocorrências adicionadas
  Widget _buildOcorrenciasList() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Ocorrências Adicionadas (${_ocorrenciasAdicionadas.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ..._ocorrenciasAdicionadas.map((ocorrencia) => _buildOcorrenciaItem(ocorrencia)).toList(),
        ],
      ),
    );
  }

  /// Constrói um item da lista de ocorrências
  Widget _buildOcorrenciaItem(Map<String, dynamic> ocorrencia) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ocorrencia['organismo'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${_getOccurrenceTypeString(OccurrenceType.values.firstWhere((e) => e.name == ocorrencia['tipo']))} • Severidade: ${ocorrencia['severidade']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (ocorrencia['observacoes'].isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    ocorrencia['observacoes'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removerOcorrencia(ocorrencia['id']),
            tooltip: 'Remover ocorrência',
          ),
        ],
      ),
    );
  }

  /// Salva todas as ocorrências e avança para o próximo ponto
  Future<void> _saveAndAdvance() async {
    if (_ocorrenciasAdicionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adicione pelo menos uma ocorrência antes de salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Salvar todas as ocorrências primeiro
      await _saveAllOccurrences();
      
      // Aguardar um pouco para o usuário ver a mensagem de sucesso
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Chamar o callback de salvar e avançar
      if (widget.onSaveAndAdvance != null) {
        widget.onSaveAndAdvance!();
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar e avançar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Salva todas as ocorrências
  Future<void> _saveAllOccurrences() async {
    if (_ocorrenciasAdicionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Adicione pelo menos uma ocorrência antes de salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Converter ocorrências para o formato esperado
      final ocorrenciasData = _ocorrenciasAdicionadas.map((oc) => {
        'type': oc['tipo'],
        'name': oc['organismo'],
        'organism_name': oc['organismo'],
        'subtipo': oc['organismo'],
        'organismo': oc['organismo'],
        'organismId': oc['organismo_id'],
        'organismo_id': oc['organismo_id'],
        'severity': oc['severidade'],
        'plantSection': oc['terco_planta'],
        'phase': oc['fase_organismo'],
        'observations': oc['observacoes'],
        'temperature': oc['temperatura'],
        'humidity': oc['umidade'],
        'riskLevel': oc['nivel_risco'],
        'infestationSize': oc['tamanho_infestacao'],
        'images': oc['fotos'],
        'cropName': widget.cropName,
        'fieldId': widget.fieldId,
      }).toList();

      // Salvar todas as ocorrências
      for (final ocorrenciaData in ocorrenciasData) {
        await widget.onOccurrenceAdded(ocorrenciaData);
      }

      // Limpar lista após salvar
      setState(() {
        _ocorrenciasAdicionadas.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ocorrenciasData.length} ocorrências salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar ocorrências: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Métodos auxiliares
  String _getOccurrenceTypeString(OccurrenceType type) {
    switch (type) {
      case OccurrenceType.pest:
        return 'praga';
      case OccurrenceType.disease:
        return 'doenca';
      case OccurrenceType.weed:
        return 'daninha';
      case OccurrenceType.deficiency:
        return 'deficiencia';
      case OccurrenceType.other:
        return 'outro';
    }
  }

  Color _getSeverityColor(int severity) {
    if (severity <= 2) return Colors.green;
    if (severity <= 5) return Colors.yellow;
    if (severity <= 8) return Colors.orange;
    return Colors.red;
  }

  String _getSeverityLabel(int severity) {
    if (severity <= 2) return 'Baixo';
    if (severity <= 5) return 'Médio';
    if (severity <= 8) return 'Alto';
    return 'Crítico';
  }

  String _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'alto':
        return '🔴';
      case 'médio':
        return '🟡';
      default:
        return '🟢';
    }
  }

  List<String> _getAvailablePhases() {
    // Buscar fases do organismo selecionado
    if (_selectedOrganismId.isNotEmpty) {
      final organism = _allOrganisms.firstWhere(
        (org) => org['id'].toString() == _selectedOrganismId,
        orElse: () => {},
      );
      return organism['fases'] ?? ['Ovo', 'Larva Pequena', 'Larva Média', 'Adulto'];
    }
    return ['Ovo', 'Larva Pequena', 'Larva Média', 'Adulto'];
  }

  /// Carrega dados de CV% do plantio
  Future<void> _loadCvData() async {
    try {
      final reportData = await _plantingDataService.getMonitoringReportData(
        talhaoId: widget.fieldId,
        culturaId: widget.cropName,
      );

      final contextoPlantio = reportData['contextoPlantio'] as Map<String, dynamic>?;
      
      if (contextoPlantio != null && contextoPlantio['temCvData'] == true) {
        final ultimoCv = contextoPlantio['ultimoCv'] as double?;
        final classificacaoCv = contextoPlantio['classificacaoCv'] as String?;
        
        setState(() {
          _cvPercentage = ultimoCv;
          _cvStatus = classificacaoCv;
          _hasCvData = true;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar dados de CV%: $e');
    }
  }

  /// Campo de CV% do plantio
  Widget _buildCvPlantioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calculate, size: 16, color: Colors.blue.shade700),
            SizedBox(width: 4),
            Text(
              'CV% do Plantio',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hasCvData ? _getCvStatusColor() : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _hasCvData 
                    ? 'CV%: ${_cvPercentage!.toStringAsFixed(1)}% - $_cvStatus'
                    : 'Nenhum dado de CV% encontrado',
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasCvData ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_hasCvData)
                Icon(
                  _getCvStatusIcon(),
                  color: Colors.white,
                  size: 16,
                )
              else
                Icon(Icons.info, color: Colors.grey.shade600, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// Retorna a cor baseada no status do CV%
  Color _getCvStatusColor() {
    switch (_cvStatus?.toLowerCase()) {
      case 'excelente':
        return Colors.green;
      case 'bom':
        return Colors.orange;
      case 'ruim':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Retorna o ícone baseado no status do CV%
  IconData _getCvStatusIcon() {
    switch (_cvStatus?.toLowerCase()) {
      case 'excelente':
        return Icons.check_circle;
      case 'bom':
        return Icons.warning;
      case 'ruim':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
