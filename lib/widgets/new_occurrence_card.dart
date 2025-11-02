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
import '../services/monitoring_data_integration_service.dart';
import '../modules/ai/services/ai_infestation_map_integration_service.dart';
import '../database/models/estande_plantas_model.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';
import '../utils/media_helper.dart';
import '../services/agronomic_severity_calculator.dart';
import 'responsive_scroll_widget.dart';
import 'safe_dropdown.dart';

/// Widget profissional para o card de nova ocorrência com IA integrada
class NewOccurrenceCard extends StatefulWidget {
  final String cropName;
  final String fieldId;
  final Function(Map<String, dynamic>) onOccurrenceAdded;
  final VoidCallback? onClose;
  final VoidCallback? onSaveAndAdvance;
  final Map<String, dynamic>? initialData; // ✅ NOVO: Dados iniciais para edição

  const NewOccurrenceCard({
    Key? key,
    required this.cropName,
    required this.fieldId,
    required this.onOccurrenceAdded,
    this.onClose,
    this.onSaveAndAdvance,
    this.initialData, // ✅ NOVO
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
  final MonitoringDataIntegrationService _integrationService = MonitoringDataIntegrationService();
  
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
  
  // ✅ CAMPOS ADICIONAIS (Quantidade, Ovoposição, Sem Infestação)
  bool _semInfestacao = false;
  int _quantidadePragas = 0;
  bool _temOvoposicao = false;
  int _quantidadeOvos = 0;
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
    
    // ✅ PRÉ-PREENCHER CAMPOS SE FOR MODO DE EDIÇÃO
    if (widget.initialData != null) {
      _loadInitialData(widget.initialData!);
    }
    
    // Adicionar delay para evitar sobrecarga na inicialização
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeOrganismCache();
        _loadEnrichedData(); // ✅ Carregar TODOS os dados do módulo plantio
      }
    });
  }
  
  /// Carrega dados iniciais para modo de edição
  void _loadInitialData(Map<String, dynamic> data) {
    setState(() {
      // Tipo de organismo (converter de português para enum se necessário)
      if (data['tipo'] != null) {
        final tipoStr = data['tipo'].toString();
        if (tipoStr == 'Praga' || tipoStr.toLowerCase() == 'pest') {
          _selectedType = OccurrenceType.pest;
        } else if (tipoStr == 'Doença' || tipoStr.toLowerCase() == 'disease') {
          _selectedType = OccurrenceType.disease;
        } else if (tipoStr == 'Daninha' || tipoStr.toLowerCase() == 'weed') {
          _selectedType = OccurrenceType.weed;
        } else if (tipoStr == 'Deficiência' || tipoStr.toLowerCase() == 'deficiency') {
          _selectedType = OccurrenceType.deficiency;
        } else {
          _selectedType = OccurrenceType.other;
        }
      }
      
      // Nome e ID do organismo
      if (data['subtipo'] != null) {
        _selectedOrganismName = data['subtipo'].toString();
      } else if (data['organism_name'] != null) {
        _selectedOrganismName = data['organism_name'].toString();
      }
      
      if (data['organism_id'] != null) {
        _selectedOrganismId = data['organism_id'].toString();
      }
      
      // Quantidade de pragas
      if (data['quantidade'] != null) {
        _quantidadePragas = (data['quantidade'] as num).toInt();
      } else if (data['percentual'] != null) {
        _quantidadePragas = (data['percentual'] as num).toInt();
      }
      
      // Severidade/Tamanho da infestação
      if (data['percentual'] != null) {
        _infestationSize = (data['percentual'] as num).toDouble();
      }
      
      // Observações
      if (data['observacao'] != null) {
        _observationsController.text = data['observacao'].toString();
      } else if (data['observacoes'] != null) {
        _observationsController.text = data['observacoes'].toString();
      }
      
      // Fotos (se houver)
      if (data['foto_paths'] != null) {
        if (data['foto_paths'] is List) {
          _imagePaths = List<String>.from(data['foto_paths']);
        }
      } else if (data['fotoPaths'] != null) {
        if (data['fotoPaths'] is List) {
          _imagePaths = List<String>.from(data['fotoPaths']);
        }
      }
      
      // Marcar que há dados preenchidos
      if (_selectedOrganismName.isNotEmpty) {
        _showSuggestions = false; // ✅ CORRIGIDO: usar variável existente
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
        'tipo': _semInfestacao ? 'Sem Infestação' : _selectedType.name,
        'organismo': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
        'organismo_id': _selectedOrganismId,
        // Adicionar campos de compatibilidade para outros módulos
        'organism_name': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
        'name': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
        'subtipo': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
        'severidade': _semInfestacao ? 0 : _selectedSeverity,
        'terco_planta': _selectedPlantSection,
        'fase_organismo': _selectedPhase,
        'observacoes': _observationsController.text.trim(),
        'temperatura': _currentTemperature,
        'umidade': _currentHumidity,
        'nivel_risco': _semInfestacao ? 'Baixo' : _riskLevel,
        'tamanho_infestacao': _semInfestacao ? 0.0 : _infestationSize,
        'quantidade': _semInfestacao ? 0 : (_quantidadePragas > 0 ? _quantidadePragas : _infestationSize.toInt()),
        'fotos': List<String>.from(_imagePaths),
        
        // ✅ NOVOS CAMPOS ADICIONADOS
        'sem_infestacao': _semInfestacao,
        'quantidade_pragas': _quantidadePragas,
        'tem_ovoposicao': _temOvoposicao,
        'quantidade_ovos': _quantidadeOvos,
        
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
        'severidade_ia': enrichedSeverity['severity'],
        'nivel_ia': enrichedSeverity['level'],
        'confianca_ia': enrichedSeverity['confidence'],
        'cor_ia': enrichedSeverity['color'],
        'recomendacao_ia': enrichedSeverity['recommendation'],
        'perda_produtividade_ia': enrichedSeverity['productivityLoss'],
        'valor_ponderado_ia': enrichedSeverity['weightedValue'],
        'fatores_ia': enrichedSeverity['factors'],
        'calculo_ia': enrichedSeverity['calculation'],
        
        // ✅ ADICIONAR SEVERIDADE AGRONÔMICA PARA COMPATIBILIDADE
        'severidade_agronomica': enrichedSeverity['weightedValue'] as double? ?? 0.0,
      };
      
      setState(() {
        _ocorrenciasAdicionadas.add(novaOcorrencia);
        // Limpar campos para próxima ocorrência
        _limparCampos();
      });
      
      Logger.info('✅ Ocorrência adicionada com severidade IA: ${enrichedSeverity['severity']}');
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
      
      // Carregar organismos do módulo culturas da fazenda
      try {
        await _loadOrganismsFromFarmCultureModule(cropId ?? widget.cropName);
        print('✅ NewOccurrenceCard: Organismos carregados do módulo culturas da fazenda');
      } catch (e) {
        print('⚠️ NewOccurrenceCard: Erro ao carregar do módulo culturas, usando fallback: $e');
        _loadFallbackOrganisms();
      }
      
      // Carregar organismos baseado no tipo selecionado
      _loadOrganisms();
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro geral ao carregar organismos para cultura: $e');
      _loadFallbackOrganisms();
    }
  }
  
  /// Carrega organismos do módulo culturas da fazenda
  Future<void> _loadOrganismsFromFarmCultureModule(String cropId) async {
    try {
      print('🔍 NewOccurrenceCard: Carregando organismos do módulo culturas da fazenda...');
      
      // Mapear nome da cultura para ID
      final mappedCropId = _mapCropNameToId(widget.cropName);
      print('🔍 NewOccurrenceCard: ID da cultura mapeado: $mappedCropId');
      
      // Carregar organismos completos dos arquivos JSON
      await _loadOrganismsFromJsonFiles(mappedCropId);
      
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro ao carregar organismos do módulo culturas: $e');
      rethrow;
    }
  }
  
  /// Carrega plantas daninhas do arquivo específico da cultura
  Future<void> _carregarPlantasDaninhasEspecificas(String cropId) async {
    try {
      final fileName = 'plantas_daninhas_$cropId.json';
      final filePath = 'assets/data/$fileName';
      
      print('📁 NewOccurrenceCard: Carregando plantas daninhas específicas: $filePath');
      
      final String jsonString = await rootBundle.loadString(filePath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      if (jsonData.containsKey('plantas_daninhas')) {
        final List<dynamic> daninhas = jsonData['plantas_daninhas'];
        print('📊 NewOccurrenceCard: ${daninhas.length} plantas daninhas encontradas no arquivo específico');
        
        // Limpar daninhas existentes (do arquivo principal)
        _organismCache[widget.cropName]!['weed']!.clear();
        
        for (final daninha in daninhas) {
          final Map<String, dynamic> daninhaData = {
            'id': daninha['id']?.toString() ?? 'weed_${cropId}_${DateTime.now().millisecondsSinceEpoch}',
            'nome': daninha['nome']?.toString() ?? 'Planta daninha não identificada',
            'nome_cientifico': daninha['nome_cientifico']?.toString() ?? '',
            'familia': daninha['familia']?.toString() ?? '',
            'tipo': daninha['tipo']?.toString() ?? 'planta_daninha',
            'categoria': daninha['categoria']?.toString() ?? 'Daninha',
            'icone': daninha['icone']?.toString() ?? '🌿',
            'ativo': daninha['ativo'] ?? true,
            'caracteristicas': daninha['caracteristicas'] ?? {},
            'nivel_dano': daninha['nivel_dano'] ?? {},
            'controle': daninha['controle'] ?? {},
            'observacoes': daninha['observacoes']?.toString() ?? '',
            'cultura_id': cropId,
            'cultura_nome': widget.cropName,
          };
          
          _organismCache[widget.cropName]!['weed']!.add(daninhaData);
        }
        
        print('✅ NewOccurrenceCard: ${daninhas.length} plantas daninhas carregadas do arquivo específico');
      } else {
        print('⚠️ NewOccurrenceCard: Arquivo de daninhas não contém campo "plantas_daninhas"');
        _adicionarDaninhasFallback(cropId);
      }
    } catch (e) {
      print('⚠️ NewOccurrenceCard: Erro ao carregar plantas daninhas específicas: $e');
      _adicionarDaninhasFallback(cropId);
    }
  }
  
  /// Adiciona plantas daninhas comuns (fallback)
  void _adicionarDaninhasFallback(String cropId) {
    // Plantas daninhas mais comuns da agricultura brasileira
    final daninhasComuns = [
      {'id': 'weed_buva_001', 'nome': 'Buva (Conyza bonariensis)', 'icone': '🌿'},
      {'id': 'weed_caruru_001', 'nome': 'Caruru (Amaranthus spp.)', 'icone': '🌿'},
      {'id': 'weed_cordadevolta_001', 'nome': 'Corda-de-viola (Ipomoea spp.)', 'icone': '🌿'},
      {'id': 'weed_trapoeraba_001', 'nome': 'Trapoeraba (Commelina benghalensis)', 'icone': '🌿'},
      {'id': 'weed_picao_001', 'nome': 'Picão-preto (Bidens pilosa)', 'icone': '🌿'},
      {'id': 'weed_capim_001', 'nome': 'Capim-arroz (Echinochloa spp.)', 'icone': '🌾'},
      {'id': 'weed_papuã_001', 'nome': 'Papuã (Urochloa plantaginea)', 'icone': '🌾'},
      {'id': 'weed_nabiça_001', 'nome': 'Nabiça (Raphanus raphanistrum)', 'icone': '🌿'},
      {'id': 'weed_azevém_001', 'nome': 'Azevém (Lolium multiflorum)', 'icone': '🌾'},
      {'id': 'weed_guanxuma_001', 'nome': 'Guanxuma (Sida rhombifolia)', 'icone': '🌿'},
    ];
    
    for (final daninha in daninhasComuns) {
      _organismCache[widget.cropName]!['weed']!.add({
        'id': daninha['id'],
        'nome': daninha['nome'],
        'icone': daninha['icone'],
        'tipo': 'planta_daninha',
        'categoria': 'Daninha',
        'ativo': true,
      });
    }
  }
  
  /// Mapeia nome da cultura para ID
  String _mapCropNameToId(String cropName) {
    final cropMap = {
      'Soja': 'soja',
      'Milho': 'milho',
      'Trigo': 'trigo',
      'Feijão': 'feijao',
      'Algodão': 'algodao',
      'Sorgo': 'sorgo',
      'Girassol': 'girassol',
      'Aveia': 'aveia',
      'Gergelim': 'gergelim',
      'Cana-de-açúcar': 'cana_acucar',
      'Tomate': 'tomate',
      'Arroz': 'arroz',
    };
    
    return cropMap[cropName] ?? cropName.toLowerCase();
  }
  
  /// Carrega organismos completos dos arquivos JSON
  Future<void> _loadOrganismsFromJsonFiles(String cropId) async {
    try {
      print('🔍 NewOccurrenceCard: Carregando organismos completos dos arquivos JSON...');
      
      // Mapear ID da cultura para nome do arquivo
      final fileName = _getCultureFileName(cropId);
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
          if (tipo == 'doenca' || tipo.contains('doenca') || categoria.contains('doença') || categoria.contains('disease')) {
            organismType = 'disease';
            print('🦠 DOENÇA detectada: ${organismo['nome']}');
          } else if (tipo == 'planta_daninha' || tipo.contains('daninha') || categoria.contains('daninha') || categoria.contains('weed') || categoria.contains('planta daninha')) {
            organismType = 'weed';
            print('🌿 DANINHA detectada: ${organismo['nome']} (tipo: $tipo, categoria: $categoria)');
          } else if (tipo == 'praga' || tipo.contains('praga') || categoria.contains('praga') || categoria.contains('pest')) {
            organismType = 'pest';
            print('🐛 PRAGA detectada: ${organismo['nome']}');
          }
          
          // Adicionar ao cache
          final organismData = {
            'id': organismo['id']?.toString() ?? '',
            'nome': organismo['nome']?.toString() ?? '',
            'nome_cientifico': organismo['nome_cientifico']?.toString() ?? '',
            'tipo': tipo,
            'categoria': categoria,
            'cultura_id': cropId,
            'cultura_nome': widget.cropName,
            'descricao': organismo['dano_economico']?.toString() ?? organismo['descricao']?.toString() ?? '',
            'icone': _getOrganismIcon(organismType),
            'ativo': true,
          };
          
          _organismCache[widget.cropName]![organismType]!.add(organismData);
        }
        
        print('✅ NewOccurrenceCard: Organismos carregados dos arquivos JSON:');
        print('  - Pragas: ${_organismCache[widget.cropName]!['pest']!.length}');
        print('  - Doenças: ${_organismCache[widget.cropName]!['disease']!.length}');
        print('  - Plantas daninhas: ${_organismCache[widget.cropName]!['weed']!.length}');
        
        // ✅ CARREGAR DANINHAS do arquivo específico
        await _carregarPlantasDaninhasEspecificas(cropId);
        
        // DEBUG: Listar primeiras daninhas
        if (_organismCache[widget.cropName]!['weed']!.isNotEmpty) {
          print('🌿 DANINHAS DISPONÍVEIS:');
          for (final daninha in _organismCache[widget.cropName]!['weed']!.take(5)) {
            print('   - ${daninha['nome']}');
          }
        }
        
      } else {
        print('⚠️ NewOccurrenceCard: Arquivo JSON não contém campo "organismos"');
        throw Exception('Campo "organismos" não encontrado no arquivo JSON');
      }
      
    } catch (e) {
      print('❌ NewOccurrenceCard: Erro ao carregar organismos dos arquivos JSON: $e');
      rethrow;
    }
  }
  
  /// Mapeia ID da cultura para nome do arquivo JSON
  String _getCultureFileName(String cropId) {
    final fileMap = {
      'soja': 'organismos_soja.json',
      'milho': 'organismos_milho.json',
      'trigo': 'organismos_trigo.json',
      'feijao': 'organismos_feijao.json',
      'algodao': 'organismos_algodao.json',
      'sorgo': 'organismos_sorgo.json',
      'girassol': 'organismos_girassol.json',
      'aveia': 'organismos_aveia.json',
      'gergelim': 'organismos_gergelim.json',
      'cana_acucar': 'organismos_cana_acucar.json',
      'tomate': 'organismos_tomate.json',
      'arroz': 'organismos_arroz.json',
    };
    
    return fileMap[cropId] ?? 'organismos_soja.json';
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
  
  /// Carrega organismos específicos da cultura Soja (MÉTODO ANTIGO - MANTIDO PARA FALLBACK)
  Future<void> _loadSoybeanOrganisms() async {
    print('🔍 NewOccurrenceCard: Carregando organismos da Soja...');
    
    // Pragas da Soja
    final soybeanPests = [
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
      {
        'id': 'percevejo_soja',
        'nome': 'Percevejo da Soja',
        'nome_cientifico': 'Euschistus heros',
        'tipo': 'praga',
        'categoria': 'Praga',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Percevejo que suga grãos',
        'icone': '🐛',
        'ativo': true,
      },
      {
        'id': 'lagarta_elasmo',
        'nome': 'Lagarta Elasmo',
        'nome_cientifico': 'Elasmopalpus lignosellus',
        'tipo': 'praga',
        'categoria': 'Praga',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Lagarta que ataca o colo da planta',
        'icone': '🐛',
        'ativo': true,
      },
      {
        'id': 'lagarta_falsa_medideira',
        'nome': 'Lagarta Falsa Medideira',
        'nome_cientifico': 'Chrysodeixis includens',
        'tipo': 'praga',
        'categoria': 'Praga',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Lagarta que ataca folhas',
        'icone': '🐛',
        'ativo': true,
      },
      {
        'id': 'lagarta_helicoverpa',
        'nome': 'Lagarta Helicoverpa',
        'nome_cientifico': 'Helicoverpa armigera',
        'tipo': 'praga',
        'categoria': 'Praga',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Lagarta que ataca vagens',
        'icone': '🐛',
        'ativo': true,
      },
    ];
    
    // Doenças da Soja
    final soybeanDiseases = [
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
      {
        'id': 'mancha_parda',
        'nome': 'Mancha Parda',
        'nome_cientifico': 'Septoria glycines',
        'tipo': 'doenca',
        'categoria': 'Doença',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Doença fúngica das folhas',
        'icone': '🦠',
        'ativo': true,
      },
      {
        'id': 'cancro_hastes',
        'nome': 'Cancro da Haste',
        'nome_cientifico': 'Diaporthe phaseolorum',
        'tipo': 'doenca',
        'categoria': 'Doença',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Doença que ataca hastes',
        'icone': '🦠',
        'ativo': true,
      },
      {
        'id': 'podridao_radicular',
        'nome': 'Podridão Radicular',
        'nome_cientifico': 'Fusarium spp.',
        'tipo': 'doenca',
        'categoria': 'Doença',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Doença que ataca raízes',
        'icone': '🦠',
        'ativo': true,
      },
      {
        'id': 'mofo_branco',
        'nome': 'Mofo Branco',
        'nome_cientifico': 'Sclerotinia sclerotiorum',
        'tipo': 'doenca',
        'categoria': 'Doença',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Doença fúngica grave',
        'icone': '🦠',
        'ativo': true,
      },
    ];
    
    // Plantas daninhas da Soja
    final soybeanWeeds = [
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
      {
        'id': 'capim_amargoso',
        'nome': 'Capim Amargoso',
        'nome_cientifico': 'Digitaria insularis',
        'tipo': 'daninha',
        'categoria': 'Planta Daninha',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Gramínea daninha resistente',
        'icone': '🌿',
        'ativo': true,
      },
      {
        'id': 'leiteiro',
        'nome': 'Leiteiro',
        'nome_cientifico': 'Euphorbia heterophylla',
        'tipo': 'daninha',
        'categoria': 'Planta Daninha',
        'cultura_id': 'soja',
        'cultura_nome': 'Soja',
        'descricao': 'Planta daninha de folha larga',
        'icone': '🌿',
        'ativo': true,
      },
    ];
    
    // Adicionar ao cache
    _organismCache[widget.cropName]!['pest']!.addAll(soybeanPests);
    _organismCache[widget.cropName]!['disease']!.addAll(soybeanDiseases);
    _organismCache[widget.cropName]!['weed']!.addAll(soybeanWeeds);
    
    print('📊 NewOccurrenceCard: Organismos da Soja carregados:');
    print('  - Pragas: ${soybeanPests.length}');
    print('  - Doenças: ${soybeanDiseases.length}');
    print('  - Plantas daninhas: ${soybeanWeeds.length}');
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
      
      // 1. Carregar dados de estande usando novo serviço de integração
      await _loadEstandeDataFromIntegration();
      
      // 2. Carregar dados fenológicos usando novo serviço de integração
      await _loadPhenologicalDataFromIntegration();
      
      // 3. Carregar dados de CV%
      await _loadCvData();
      
      // 4. Carregar histórico de infestação
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
  Future<void> _saveOccurrence() async {
    Logger.info('🚨 [SAVE_START] ==========================================');
    Logger.info('🚨 [SAVE_START] USUÁRIO CLICOU EM SALVAR!');
    Logger.info('🚨 [SAVE_START] _semInfestacao: $_semInfestacao');
    Logger.info('🚨 [SAVE_START] _selectedOrganismName: "$_selectedOrganismName"');
    Logger.info('🚨 [SAVE_START] _selectedOrganismId: "$_selectedOrganismId"');
    Logger.info('🚨 [SAVE_START] _quantidadePragas: $_quantidadePragas');
    Logger.info('🚨 [SAVE_START] _infestationSize: $_infestationSize');
    Logger.info('🚨 [SAVE_START] _imagePaths: $_imagePaths');
    Logger.info('🚨 [SAVE_START] _imagePaths.length: ${_imagePaths.length}');
    Logger.info('🚨 [SAVE_START] _currentTemperature: $_currentTemperature');
    Logger.info('🚨 [SAVE_START] _currentHumidity: $_currentHumidity');
    Logger.info('🚨 [SAVE_START] ==========================================');
    
    // ✅ VALIDAÇÃO: Exigir QUANTIDADE se não for "sem infestação"
    if (!_semInfestacao) {
      if (_selectedOrganismId.isEmpty) {
        Logger.error('❌ [VALIDATION] Organismo não selecionado!');
        _showErrorSnackBar('Selecione um organismo');
        return;
      }
      if (_quantidadePragas == 0 && _infestationSize == 0) {
        Logger.error('❌ [VALIDATION] Quantidade está ZERADA!');
        Logger.error('   _quantidadePragas: $_quantidadePragas');
        Logger.error('   _infestationSize: $_infestationSize');
        _showErrorSnackBar('INSIRA A QUANTIDADE de organismos encontrados! Ex: 4, 6, 10...');
        return;
      }
      
      Logger.info('✅ [VALIDATION] Validações OK! Prosseguindo...');
      Logger.info('   _quantidadePragas: $_quantidadePragas');
      Logger.info('   _infestationSize: $_infestationSize');
    }

    double agronomicSeverity = 0.0;
    String alertLevel = 'Baixo';
    String recommendation = 'Nenhuma ação necessária';
    
    // ✅ CALCULAR SEVERIDADE APENAS SE NÃO FOR "SEM INFESTAÇÃO"
    if (!_semInfestacao) {
      // ✅ CORRIGIDO: Usar QUANTIDADE REAL, não severidade visual!
      // _quantidadePragas = quantidade real contada (ex: 5 lagartas)
      // _selectedSeverity = intensidade visual 0-10 (ex: 7/10)
      // Para cálculo agronômico, usar QUANTIDADE REAL!
      final quantidadeParaCalculo = _quantidadePragas > 0 ? _quantidadePragas : _infestationSize.round();
      
      agronomicSeverity = await AgronomicSeverityCalculator.calculateSeverity(
        pointCount: quantidadeParaCalculo, // ✅ USA QUANTIDADE REAL!
        organismName: _selectedOrganismName,
        cropName: widget.cropName,
        cropStage: _selectedPhase.isNotEmpty ? _selectedPhase : 'V6',
        organismType: _getOccurrenceTypeString(_selectedType),
        temperature: _currentTemperature > 0 ? _currentTemperature : null,
        humidity: _currentHumidity > 0 ? _currentHumidity : null,
        totalPlantsEvaluated: 10,
      );
      
      Logger.info('🔢 [CALC] Quantidade usada no cálculo: $quantidadeParaCalculo organismos');
      Logger.info('🎨 [CALC] Severidade visual: $_selectedSeverity/10 (NÃO usada no cálculo)');
      Logger.info('📊 [CALC] Severidade agronômica calculada: ${agronomicSeverity.toStringAsFixed(1)}%');
      
      alertLevel = AgronomicSeverityCalculator.getAlertLevel(agronomicSeverity);
      recommendation = AgronomicSeverityCalculator.getAgronomicRecommendation(
        agronomicSeverity, 
        _selectedOrganismName
      );
    }

    final occurrence = {
      // Dados básicos
      'organism_id': _semInfestacao ? 'sem_infestacao' : _selectedOrganismId,
      'organism_name': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
      'organism_type': _semInfestacao ? 'Sem Infestação' : _getOccurrenceTypeString(_selectedType),
      'plant_section': _selectedPlantSection,
      'observations': _observationsController.text.trim(),
      'crop_name': widget.cropName,
      'field_id': widget.fieldId,
      'image_paths': _imagePaths,
      'created_at': DateTime.now().toIso8601String(),
      
      // DADOS AGRONÔMICOS INTELIGENTES
      'severity': _semInfestacao ? 0 : _selectedSeverity,
      // ✅ CORRIGIDO: Enviar _quantidadePragas (valor REAL contado) como quantidade
      'quantity': _semInfestacao ? 0 : (_quantidadePragas > 0 ? _quantidadePragas : _infestationSize.round()),
      'quantidade': _semInfestacao ? 0 : (_quantidadePragas > 0 ? _quantidadePragas : _infestationSize.round()),
      'agronomic_severity': _semInfestacao ? 0.0 : agronomicSeverity,
      'percentual': _semInfestacao ? 0.0 : agronomicSeverity,
      'alert_level': _semInfestacao ? 'Baixo' : alertLevel,
      'agronomic_recommendation': _semInfestacao ? 'Ponto monitorado sem infestação detectada' : recommendation,
      'phase': _selectedPhase,
      'temperature': _currentTemperature,
      'humidity': _currentHumidity,
      'risk_level': _semInfestacao ? 'Baixo' : _riskLevel,
      'infestation_size': _semInfestacao ? 0.0 : _infestationSize,
      
      // ✅ CAMPOS ADICIONAIS PARA COMPATIBILIDADE
      'tipo': _semInfestacao ? 'Sem Infestação' : _getOccurrenceTypeString(_selectedType),
      'subtipo': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
      'nome': _semInfestacao ? 'Sem infestação detectada' : _selectedOrganismName,
      'sem_infestacao': _semInfestacao,
      'quantidade_pragas': _semInfestacao ? 0 : _quantidadePragas,
      'nivel': _semInfestacao ? 'Baixo' : alertLevel,
    };

    Logger.info('📤 [NEW_OCC_CARD] ===== SALVANDO OCORRÊNCIA =====');
    Logger.info('📤 [NEW_OCC_CARD] Organismo: ${_semInfestacao ? "SEM INFESTAÇÃO" : _selectedOrganismName}');
    Logger.info('📤 [NEW_OCC_CARD] _quantidadePragas: $_quantidadePragas');
    Logger.info('📤 [NEW_OCC_CARD] _infestationSize: $_infestationSize');
    Logger.info('📤 [NEW_OCC_CARD] Quantidade FINAL (occurrence): ${occurrence['quantidade']}');
    Logger.info('📤 [NEW_OCC_CARD] Quantity FINAL (occurrence): ${occurrence['quantity']}');
    Logger.info('📤 [NEW_OCC_CARD] Agronomic Severity: ${agronomicSeverity.toStringAsFixed(1)}%');
    Logger.info('📤 [NEW_OCC_CARD] 📸 _imagePaths: $_imagePaths (${_imagePaths.length} foto(s))'); // ✅ NOVO
    final imagePathsList = occurrence['image_paths'] as List<String>;
    Logger.info('📤 [NEW_OCC_CARD] 📸 occurrence[\'image_paths\']: Total de ${imagePathsList.length} foto(s)'); // ✅ NOVO
    Logger.info('📤 [NEW_OCC_CARD] ================================');

    // ✅ ADICIONAR À LISTA DE OCORRÊNCIAS PARA HABILITAR "SALVAR E AVANÇAR"
    setState(() {
      _ocorrenciasAdicionadas.add(occurrence);
    });

    Logger.info('📤 [NEW_OCC_CARD] Chamando callback onOccurrenceAdded...');
    widget.onOccurrenceAdded(occurrence);
    Logger.info('✅ [NEW_OCC_CARD] Callback onOccurrenceAdded executado!');
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
      // ✅ RESETAR "SEM INFESTAÇÃO" TAMBÉM
      _semInfestacao = false;
      _quantidadePragas = 0;
      _temOvoposicao = false;
      _quantidadeOvos = 0;
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
                fontSize: 12,
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
                    fontSize: 18,
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
                        // ✅ NOVO: Checkbox "Sem Infestação"
                        _buildNoInfestationCheckbox(),
                        
                        // Seletor de tipo (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildTypeSelector(),
                        SizedBox(height: 16),
                        
                        // Campo de busca de organismo (FUNCIONALIDADE ATUAL MANTIDA)
                        _buildOrganismSearchField(),
                        SizedBox(height: 16),
                        
                        // NOVA SEÇÃO: Tamanho da Infestação
                        _buildInfestationSizeCard(),
                        SizedBox(height: 16),
                        
                        // ✅ CAMPO ADICIONAL: Quantidade de Pragas
                        _buildQuantityField(),
                        
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Integração automática com Estande de Plantas',
                      style: TextStyle(
                        fontSize: 10,
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
                        fontSize: 8,
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
                        ? '${_ultimoEstande!.eficiencia!.toStringAsFixed(1)}%'  // ✅ REMOVIDO * 100
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cultura: ${widget.cropName}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '⚠️ Para maior precisão no diagnóstico, registre um estande de plantas neste talhão.',
                    style: TextStyle(
                      fontSize: 9,
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
                    fontSize: 9,
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
              fontSize: 11,
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
              fontSize: 12,
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
  
  /// ✅ NOVO: Campo de Quantidade de Pragas (somente para Pragas)
  Widget _buildQuantityField() {
    // ✅ CORRIGIDO: Mostrar campo de quantidade para TODOS os tipos (exceto "sem infestação")
    if (_semInfestacao) {
      return SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
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
            '🐛 QUANTIDADE DE PRAGAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 8),
          
          TextFormField(
            initialValue: _quantidadePragas > 0 ? _quantidadePragas.toString() : '',
            decoration: InputDecoration(
              labelText: '${_getLabelQuantidade()} *', // ✅ Obrigatório
              hintText: 'Ex: 15',
              prefixIcon: Icon(Icons.analytics, color: Colors.orange.shade600, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              helperText: _getHelperQuantidade(), // ✅ Helper dinâmico
              helperStyle: TextStyle(fontSize: 10, color: Colors.orange.shade700),
              filled: true, // ✅ Destacar campo
              fillColor: Colors.orange.shade50,
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // ✅ Texto maior
            validator: (value) {
              // ✅ VALIDAÇÃO OBRIGATÓRIA
              if (value == null || value.isEmpty) {
                return '⚠️ Campo obrigatório! Digite a quantidade.';
              }
              final qty = int.tryParse(value);
              if (qty == null || qty <= 0) {
                return '⚠️ Deve ser um número maior que zero!';
              }
              return null;
            },
            onChanged: (value) {
              final qty = int.tryParse(value) ?? 0;
              setState(() {
                _quantidadePragas = qty;
              });
              Logger.info('🔢 [QUANTIDADE] Usuário digitou: "$value" → _quantidadePragas = $qty');
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: 8),
          
          // Campos editáveis
          Row(
            children: [
              Flexible(
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
              Flexible(
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
              fontSize: 12,
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

  /// ✅ NOVO: Checkbox "Sem Infestação"
  Widget _buildNoInfestationCheckbox() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _semInfestacao ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _semInfestacao ? Colors.green.shade300 : Colors.grey.shade300,
          width: _semInfestacao ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _semInfestacao,
            onChanged: (value) {
              setState(() {
                _semInfestacao = value ?? false;
                if (_semInfestacao) {
                  // Resetar valores quando marcar "sem infestação"
                  _selectedSeverity = 0;
                  _quantidadePragas = 0;
                  _temOvoposicao = false;
                  _quantidadeOvos = 0;
                  _infestationSize = 0.0;
                  _selectedOrganismName = '';
                  _selectedOrganismId = '';
                }
              });
            },
            activeColor: Colors.green,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ SEM INFESTAÇÃO DETECTADA',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _semInfestacao ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Marque se o ponto está livre de pragas/doenças/daninhas',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
            fontSize: 12,
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
            fontSize: 12,
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        SafeDropdownButtonFormField<String>(
          value: _selectedPlantSection,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: ['Baixeiro', 'Médio', 'Superior'].map((section) {
            return DropdownMenuItem<String>(
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        SafeDropdownButtonFormField<String>(
          value: _selectedPhase.isEmpty ? null : _selectedPhase,
          decoration: InputDecoration(
            hintText: 'Selecione a fase',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: [
            // Adicionar item vazio para permitir seleção nula
            DropdownMenuItem<String>(
              value: null,
              child: Text('Selecione uma fase', style: TextStyle(color: Colors.grey)),
            ),
            ..._getAvailablePhases().map((phase) {
              return DropdownMenuItem(
                value: phase,
                child: Text(phase),
              );
            }).toList(),
          ],
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
            fontSize: 12,
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
                  _estadioFenologico ?? 'Nenhum estande recente encontrado',
                  style: TextStyle(
                    fontSize: 14,
                    color: _estadioFenologico != null ? Colors.green.shade800 : Colors.grey.shade600,
                  ),
                ),
              ),
              if (_estadioFenologico != null)
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
                  _impactoEconomicoPrevisto = (opcao['valorMax'] as num?)?.toDouble() ?? 0.0;
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
                    Logger.info('📸 [CAMERA] Retorno do MediaHelper: $imagePath');
                    
                    if (imagePath != null) {
                      // Verificar se arquivo existe antes de adicionar
                      final file = File(imagePath);
                      final exists = await file.exists();
                      Logger.info('📸 [CAMERA] Arquivo existe? $exists');
                      
                      if (exists) {
                        final size = await file.length();
                        Logger.info('📸 [CAMERA] Tamanho: ${(size / 1024).toStringAsFixed(2)} KB');
                        
                        if (size > 0) {
                          setState(() {
                            _imagePaths.add(imagePath);
                            Logger.info('✅ [CAMERA] Imagem ADICIONADA! Total: ${_imagePaths.length}');
                            Logger.info('   📋 Lista completa: $_imagePaths');
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
                          Logger.warning('⚠️ [CAMERA] Arquivo existe mas tamanho = 0!');
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
                        Logger.error('❌ [CAMERA] Arquivo NÃO existe no caminho: $imagePath');
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
                      Logger.warning('⚠️ [CAMERA] MediaHelper retornou NULL (usuário cancelou?)');
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
                  Logger.info('📸 [CAPTURE] Retorno do MediaHelper: $imagePath');
                  
                  if (imagePath != null) {
                    // Verificar se arquivo existe antes de adicionar
                    final file = File(imagePath);
                    final exists = await file.exists();
                    Logger.info('📸 [CAPTURE] Arquivo existe? $exists');
                    
                    if (exists) {
                      final size = await file.length();
                      Logger.info('📸 [CAPTURE] Tamanho: ${(size / 1024).toStringAsFixed(2)} KB');
                      
                      if (size > 0) {
                        setState(() {
                          _imagePaths.add(imagePath);
                          Logger.info('✅ [CAPTURE] Imagem ADICIONADA! Total: ${_imagePaths.length}');
                          Logger.info('   📋 Lista completa: $_imagePaths');
                        });
                      } else {
                        Logger.warning('⚠️ [CAPTURE] Arquivo existe mas tamanho = 0!');
                      }
                    } else {
                      Logger.error('❌ [CAPTURE] Arquivo NÃO existe no caminho: $imagePath');
                    }
                  } else {
                    Logger.warning('⚠️ [CAPTURE] MediaHelper retornou NULL (usuário cancelou?)');
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
                onPressed: (_ocorrenciasAdicionadas.isNotEmpty || _semInfestacao) ? _saveAndAdvance : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_ocorrenciasAdicionadas.isNotEmpty || _semInfestacao) ? Colors.blue : Colors.grey,
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
                  '${_getOccurrenceTypeString(OccurrenceType.values.firstWhere((e) => e.name == ocorrencia['tipo'], orElse: () => OccurrenceType.pest))} • Severidade: ${ocorrencia['severidade']}',
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
    // ✅ PERMITIR SALVAR MESMO SEM OCORRÊNCIAS (para "Sem Infestação")
    if (_ocorrenciasAdicionadas.isEmpty && !_semInfestacao) {
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
    // ✅ PERMITIR SALVAR MESMO SEM OCORRÊNCIAS (para "Sem Infestação")
    if (_ocorrenciasAdicionadas.isEmpty && !_semInfestacao) {
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
        // ✅ CORRIGIDO: Adicionar quantidade e image_paths
        'quantidade': oc['quantidade'],
        'quantity': oc['quantidade'],
        'quantidade_pragas': oc['quantidade_pragas'],
        'agronomic_severity': oc['severidade_agronomica'],
        'percentual': oc['severidade_agronomica'],
        'image_paths': oc['fotos'],
        'fotos': oc['fotos'],
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

  /// Carrega dados de estande usando o serviço de integração
  Future<void> _loadEstandeDataFromIntegration() async {
    try {
      Logger.info('🔍 Carregando dados de estande via integração para talhão: ${widget.fieldId}, cultura: ${widget.cropName}');
      
      // ✅ GARANTIR INICIALIZAÇÃO DO SERVIÇO
      await _integrationService.initialize();
      
      final estandeData = await _integrationService.getEstandeData(
        widget.fieldId,
        widget.cropName,
      );
      
      Logger.info('📊 Resultado getEstandeData: ${estandeData != null ? "DADOS ENCONTRADOS" : "NENHUM DADO"}');
      
      if (estandeData != null) {
        // Criar modelo de estande com os dados obtidos
        final estandeModel = EstandePlantasModel(
          id: 'integration_${widget.fieldId}_${widget.cropName}',
          talhaoId: widget.fieldId,
          culturaId: widget.cropName,
          dataAvaliacao: estandeData['dataAvaliacao'] != null 
              ? DateTime.tryParse(estandeData['dataAvaliacao']) 
              : DateTime.now(),
          diasAposEmergencia: estandeData['diasAposEmergencia'],
          metrosLinearesMedidos: estandeData['metrosLinearesMedidos'],
          plantasContadas: estandeData['plantasContadas'],
          espacamento: estandeData['espacamento'],
          plantasPorMetro: estandeData['plantasPorMetro'],
          plantasPorHectare: estandeData['plantasPorHectare'],
          populacaoIdeal: estandeData['populacaoIdeal'],
          eficiencia: estandeData['eficiencia'],
        );
        
        // Determinar estádio fenológico baseado nos dados
        final estadioFenologico = _integrationService.determinePhenologicalStage(
          estandeData['diasAposEmergencia'] ?? 0,
          widget.cropName,
        );
        
        setState(() {
          _ultimoEstande = estandeModel;
          _estadioFenologico = estadioFenologico;
          _hasRecentStand = true;
          _estandeId = estandeModel.id;
        });
        
        Logger.info('✅ Dados de estande carregados: ${estadioFenologico} (DAE: ${estandeData['diasAposEmergencia']})');
      } else {
        setState(() {
          _ultimoEstande = null;
          _estadioFenologico = null;
          _hasRecentStand = false;
          _estandeId = null;
        });
        Logger.info('⚠️ Nenhum dado de estande encontrado');
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de estande via integração: $e');
      setState(() {
        _ultimoEstande = null;
        _estadioFenologico = null;
        _hasRecentStand = false;
        _estandeId = null;
      });
    }
  }

  /// Carrega dados fenológicos usando o serviço de integração
  Future<void> _loadPhenologicalDataFromIntegration() async {
    try {
      Logger.info('🔍 Carregando dados fenológicos via integração para talhão: ${widget.fieldId}, cultura: ${widget.cropName}');
      
      // ✅ GARANTIR INICIALIZAÇÃO DO SERVIÇO
      await _integrationService.initialize();
      
      final phenologicalData = await _integrationService.getPhenologicalData(
        widget.fieldId,
        widget.cropName,
      );
      
      Logger.info('📊 Resultado getPhenologicalData: ${phenologicalData != null ? "DADOS ENCONTRADOS - ${phenologicalData['estagioAtual']}" : "NENHUM DADO"}');
      
      if (phenologicalData != null) {
        // Se já temos estádio fenológico do estande, manter, senão usar dos dados fenológicos
        if (_estadioFenologico == null) {
          setState(() {
            _estadioFenologico = phenologicalData['estagioAtual'];
          });
        }
        
        Logger.info('✅ Dados fenológicos carregados: ${phenologicalData['estagioAtual']}');
      } else {
        Logger.info('⚠️ Nenhum dado fenológico encontrado');
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados fenológicos via integração: $e');
    }
  }

  /// Carrega dados de CV% do plantio
  Future<void> _loadCvData() async {
    try {
      // Primeiro, tentar obter CV% dos dados de estande integrados
      if (_ultimoEstande != null) {
        final estandeData = await _integrationService.getEstandeData(
          widget.fieldId,
          widget.cropName,
        );
        
        if (estandeData != null && estandeData['cvPercentage'] != null) {
          final cvPercentage = (estandeData['cvPercentage'] as num?)?.toDouble() ?? 0.0;
          final cvClassification = _integrationService.calculateCvClassification(cvPercentage);
          
          setState(() {
            _cvPercentage = cvPercentage;
            _cvStatus = cvClassification;
            _hasCvData = true;
          });
          
          Logger.info('✅ CV% carregado dos dados de estande: ${cvPercentage.toStringAsFixed(1)}% - $cvClassification');
          return;
        }
      }
      
      // Fallback: tentar obter do serviço antigo
      final reportData = await _plantingDataService.getMonitoringReportData(
        talhaoId: widget.fieldId,
        culturaId: widget.cropName,
      );

      final contextoPlantio = reportData['contextoPlantio'] as Map<String, dynamic>?;
      
      if (contextoPlantio != null && contextoPlantio['temCvData'] == true) {
        final ultimoCv = (contextoPlantio['ultimoCv'] as num?)?.toDouble();
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
  
  /// ✅ NOVO: Retorna label apropriado para campo de quantidade baseado no tipo
  String _getLabelQuantidade() {
    switch (_selectedType) {
      case OccurrenceType.pest:
        return 'Quantidade de Pragas/m² *';
      case OccurrenceType.disease:
        return 'Intensidade da Doença (0-100%) *';
      case OccurrenceType.weed:
        return 'Densidade de Plantas Daninhas/m² *';
      case OccurrenceType.deficiency:
        return 'Severidade da Deficiência (0-100%) *';
      default:
        return 'Quantidade/Intensidade *';
    }
  }
  
  /// ✅ NOVO: Retorna texto de ajuda apropriado para cada tipo
  String _getHelperQuantidade() {
    switch (_selectedType) {
      case OccurrenceType.pest:
        return '⚠️ OBRIGATÓRIO: Contagem de indivíduos por m² (ex: 5, 10, 15)';
      case OccurrenceType.disease:
        return '⚠️ OBRIGATÓRIO: Percentual de plantas/área afetada (0-100)';
      case OccurrenceType.weed:
        return '⚠️ OBRIGATÓRIO: Número de plantas daninhas por m²';
      case OccurrenceType.deficiency:
        return '⚠️ OBRIGATÓRIO: Percentual de plantas com sintomas (0-100)';
      default:
        return '⚠️ OBRIGATÓRIO: Preencha com valor numérico';
    }
  }
}
