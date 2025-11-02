import 'dart:async';
import '../models/talhao_model.dart';
import '../models/crop.dart';
import '../models/agricultural_product.dart';
import '../models/integration/agro_context.dart';
import '../models/integration/atividade_agricola.dart';
import '../repositories/atividade_repository.dart';
import '../repositories/monitoring_repository.dart';
import '../modules/planting/repositories/plantio_repository.dart';
// Módulo de colheita removido
import '../utils/logger.dart';
import 'data_cache_service.dart';
import 'plot_sync_service.dart';
import 'crop_sync_service.dart';
import '../repositories/crop_repository.dart';
import '../database/app_database.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

// Constantes para identificação de módulos
const String MODULE_MONITORING = 'monitoring';
const String MODULE_PLANTING = 'planting';
// Módulo de colheita removido
// const String MODULE_HARVEST = 'harvest';
const String MODULE_APPLICATION = 'application';

/// Serviço para integração entre os diferentes módulos do sistema
/// Garante que todos os módulos tenham acesso aos mesmos dados de talhões e culturas
/// e mantém o contexto agrícola atual (talhão + safra + cultura)
class ModuleIntegrationService {
  final DataCacheService _dataCacheService = DataCacheService();
  final PlotSyncService _plotSyncService = PlotSyncService();
  final CropSyncService _cropSyncService = CropSyncService();
  final AtividadeRepository _atividadeRepository = AtividadeRepository();
  
  // Stream para notificar sobre mudanças no contexto
  final _contextController = StreamController<AgroContext>.broadcast();
  Stream<AgroContext> get contextStream => _contextController.stream;
  
  // Contexto agrícola atual
  AgroContext? _currentContext;
  AgroContext? get currentContext => _currentContext;

  /// Singleton
  static final ModuleIntegrationService _instance = ModuleIntegrationService._internal();
  factory ModuleIntegrationService() => _instance;
  ModuleIntegrationService._internal();

  /// Constantes para identificar os módulos
  static const String MODULE_PLANTING = 'plantio';
  // Módulo de colheita removido
  // static const String MODULE_HARVEST = 'colheita';
  static const String MODULE_APPLICATION = 'aplicacao';
  static const String MODULE_HISTORY = 'historico';
  static const String MODULE_MONITORING = 'monitoramento';
  static const String MODULE_REPORTS = 'relatorios';

  /// Retorna o talhão selecionado atualmente
  Future<dynamic> getSelectedPlot() async {
    // Implementação temporária - retorna o primeiro talhão encontrado
    try {
      final plots = await _plotSyncService.getAllPlots();
      return plots.isNotEmpty ? plots.first : null;
    } catch (e) {
      print('Erro ao obter talhão selecionado: $e');
      return null;
    }
  }

  /// Retorna a safra selecionada atualmente
  Future<dynamic> getSelectedCrop() async {
    // Implementação temporária - retorna a primeira safra encontrada
    try {
      // Sincronizar culturas primeiro
      await _cropSyncService.syncAllCrops();
      
      // Usar o repositório de culturas
      final cropRepository = CropRepository();
      final crops = await cropRepository.getAllCrops();
      return crops.isNotEmpty ? crops.first : null;
    } catch (e) {
      print('Erro ao obter safra selecionada: $e');
      return null;
    }
  }

  /// Inicializa o serviço de integração, sincronizando todos os dados necessários
  Future<void> initialize() async {
    try {
      print('Inicializando serviço de integração entre módulos...');
      
      // Sincronizar culturas
      await _cropSyncService.syncAllCrops();
      
      // Sincronizar talhões
      await _plotSyncService.syncAllPlots();
      
      print('Serviço de integração inicializado com sucesso!');
    } catch (e) {
      print('Erro ao inicializar serviço de integração: $e');
    }
  }

  /// Obtém todos os talhões disponíveis para um módulo específico
  Future<List<TalhaoModel>> getPlotsForModule(String moduleName) async {
    try {
      final plots = await _plotSyncService.getPlotsForModule(moduleName);
      return plots.cast<TalhaoModel>();
    } catch (e) {
      print('Erro ao obter talhões para o módulo $moduleName: $e');
      return [];
    }
  }

  /// Obtém todas as culturas disponíveis para um módulo específico
  Future<List<Crop>> getCropsForModule(String moduleName) async {
    try {
      final dbCulturas = await _dataCacheService.getCulturas();
      // Converter do tipo AgriculturalProduct para models/crop.dart
      final List<Crop> culturas = dbCulturas.map((dbCrop) => Crop(
        id: int.tryParse(dbCrop.id),
        name: dbCrop.name,
        // Usar campos disponíveis em AgriculturalProduct e mapear para Crop
        description: dbCrop.notes,
        scientificName: dbCrop.manufacturer, // Usando manufacturer como scientificName
        isSynced: dbCrop.isSynced,
        isDefault: false, // AgriculturalProduct não tem isDefault
        growthCycle: null, // AgriculturalProduct não tem growthCycle
        plantSpacing: null, // AgriculturalProduct não tem plantSpacing
        rowSpacing: null, // AgriculturalProduct não tem rowSpacing
        plantingDepth: null, // AgriculturalProduct não tem plantingDepth
        idealTemperature: null, // AgriculturalProduct não tem idealTemperature
        waterRequirement: null, // AgriculturalProduct não tem waterRequirement
        iconPath: dbCrop.iconPath,
        colorValue: dbCrop.colorValue != null ? int.tryParse(dbCrop.colorValue!) : null,
      )).toList();
      return culturas;
    } catch (e) {
      print('Erro ao obter culturas para o módulo $moduleName: $e');
      return <Crop>[];
    }
  }

  /// Obtém todos os produtos agrícolas disponíveis para um módulo específico
  Future<List<AgriculturalProduct>> getAgriculturalProductsForModule(String moduleName) async {
    try {
      // Usar o método correto do DataCacheService para obter produtos agrícolas
      // Como não existe um método específico, vamos deixar uma implementação vazia
      print('Obtendo produtos agrícolas para o módulo $moduleName');
      return [];
    } catch (e) {
      print('Erro ao obter produtos agrícolas para o módulo $moduleName: $e');
      return [];
    }
  }

  /// Notifica todos os módulos sobre uma alteração em um talhão
  Future<void> notifyPlotChange(TalhaoModel talhao) async {
    try {
      await _plotSyncService.syncPlot(talhao);
      print('Todos os módulos foram notificados sobre alteração no talhão ${talhao.nome}');
    } catch (e) {
      print('Erro ao notificar módulos sobre alteração no talhão: $e');
    }
  }

  /// Notifica todos os módulos sobre uma alteração em uma cultura
  Future<void> notifyCropChange() async {
    try {
      await _cropSyncService.syncAllCrops();
      print('Todos os módulos foram notificados sobre alterações nas culturas');
    } catch (e) {
      print('Erro ao notificar módulos sobre alterações nas culturas: $e');
    }
  }
  
  /// Define o contexto agrícola atual (talhão + safra + cultura)
  Future<void> setCurrentContext({required String talhaoId, required String safraId, required String culturaId}) async {
    _currentContext = AgroContext(
      talhaoId: talhaoId,
      safraId: safraId,
      culturaId: culturaId,
    );
    
    // Notificar ouvintes sobre a mudança no contexto
    _contextController.add(_currentContext!);
    print('Contexto agrícola atualizado: Talhão $talhaoId, Safra $safraId, Cultura $culturaId');
  }
  
  /// Limpa o contexto agrícola atual
  void clearCurrentContext() {
    _currentContext = null;
    print('Contexto agrícola limpo');
  }
  
  /// Verifica se existe um contexto agrícola atual
  bool hasCurrentContext() {
    return _currentContext != null;
  }
  
  /// Registra uma nova atividade agrícola com rastreabilidade completa
  Future<String> registrarAtividade({
    required TipoAtividade tipoAtividade,
    required String detalhesId,
    String? descricao,
    String? talhaoId,
    String? safraId,
    String? culturaId,
    DateTime? dataAtividade,
  }) async {
    // Se não foi fornecido contexto específico, usar o contexto atual
    final contexto = _currentContext;
    if (contexto == null && (talhaoId == null || safraId == null || culturaId == null)) {
      throw Exception('Não há contexto atual definido e os parâmetros de contexto estão incompletos');
    }
    
    // Criar a atividade
    final atividade = AtividadeAgricola.criar(
      talhaoId: talhaoId ?? contexto!.talhaoId,
      safraId: safraId ?? contexto!.safraId,
      culturaId: culturaId ?? contexto!.culturaId,
      tipoAtividade: tipoAtividade,
      detalhesId: detalhesId,
      descricao: descricao,
      dataAtividade: dataAtividade,
    );
    
    // Salvar no banco de dados
    await _atividadeRepository.inserir(atividade);
    print('Atividade registrada: ${atividade.tipoAtividade.nome} - ID: ${atividade.id}');
    
    return atividade.id;
  }
  
  /// Carrega o histórico completo de atividades para um contexto
  Future<List<AtividadeAgricola>> carregarHistorico({
    String? talhaoId,
    String? safraId,
    String? culturaId,
    TipoAtividade? tipoAtividade,
  }) async {
    // Se não foi fornecido contexto específico, usar o contexto atual
    if (talhaoId == null && safraId == null && culturaId == null) {
      final contexto = _currentContext;
      if (contexto == null) {
        throw Exception('Não há contexto atual definido e nenhum filtro foi fornecido');
      }
      
      talhaoId = contexto.talhaoId;
      safraId = contexto.safraId;
      culturaId = contexto.culturaId;
    }
    
    // Buscar atividades com base nos filtros fornecidos
    List<AtividadeAgricola> atividades = [];
    
    if (tipoAtividade != null) {
      // Filtrar por tipo de atividade
      atividades = await _atividadeRepository.listarPorTipo(tipoAtividade);
      
      // Filtrar adicionalmente por contexto, se fornecido
      if (talhaoId != null) {
        atividades = atividades.where((a) => a.talhaoId == talhaoId).toList();
      }
      if (safraId != null) {
        atividades = atividades.where((a) => a.safraId == safraId).toList();
      }
      if (culturaId != null) {
        atividades = atividades.where((a) => a.culturaId == culturaId).toList();
      }
    } else if (talhaoId != null && safraId != null && culturaId != null) {
      // Buscar por contexto completo
      atividades = await _atividadeRepository.listarPorContexto(
        talhaoId: talhaoId,
        safraId: safraId,
        culturaId: culturaId,
      );
    } else if (talhaoId != null) {
      // Buscar por talhão
      atividades = await _atividadeRepository.listarPorTalhao(talhaoId);
      
      // Filtrar adicionalmente, se necessário
      if (safraId != null) {
        atividades = atividades.where((a) => a.safraId == safraId).toList();
      }
      if (culturaId != null) {
        atividades = atividades.where((a) => a.culturaId == culturaId).toList();
      }
    } else if (safraId != null) {
      // Buscar por safra
      atividades = await _atividadeRepository.listarPorSafra(safraId);
      
      // Filtrar adicionalmente, se necessário
      if (culturaId != null) {
        atividades = atividades.where((a) => a.culturaId == culturaId).toList();
      }
    } else if (culturaId != null) {
      // Buscar por cultura
      atividades = await _atividadeRepository.listarPorCultura(culturaId);
    } else {
      // Sem filtros, retornar todas as atividades
      atividades = await _atividadeRepository.listarTodas();
    }
    
    // Ordenar por data de atividade (mais recente primeiro)
    atividades.sort((a, b) => b.dataAtividade.compareTo(a.dataAtividade));
    
    return atividades;
  }
  
  /// Obtém o contexto agrícola para um objeto específico em qualquer módulo
  Future<AgroContext?> getAgroContextForObject(String moduleId, String objectId) async {
    try {
      switch (moduleId) {
        case MODULE_MONITORING:
          final monitoringRepository = MonitoringRepository();
          final monitoring = await monitoringRepository.getById(objectId);
          if (monitoring != null) {
            return AgroContext(
              talhaoId: monitoring.plotId.toString(),
              safraId: '', // Monitoring não tem safraId
              culturaId: monitoring.cropId.toString(),
            );
          }
          break;
        case MODULE_PLANTING:
          final plantioRepository = PlantioRepository();
          try {
            final int plantioId = int.parse(objectId);
            final plantio = await plantioRepository.getById(plantioId.toString());
            if (plantio != null) {
              return AgroContext(
                talhaoId: plantio.talhaoId.toString(),
                safraId: plantio.safraId?.toString() ?? '',
                culturaId: plantio.culturaId.toString(),
              );
            }
          } catch (e) {
            Logger.error('Erro ao converter ID do plantio: $e', e, null, 'ModuleIntegrationService');
          }
          break;
        // Módulo de colheita foi removido
        case 'harvest': // Constante direta para evitar erro de referência
          Logger.info('Módulo de colheita foi removido', 'ModuleIntegrationService');
          break;
        // Adicionar outros módulos conforme necessário
      }
      return null;
    } catch (e) {
      Logger.error("Erro ao obter contexto: $e", e, null, "ModuleIntegrationService");
      return null;
    }
  }

  /// Vincula atividades entre diferentes módulos
  Future<void> linkModuleActivities(
    String sourceModuleId, 
    String sourceObjectId,
    String targetModuleId, 
    String targetObjectId
  ) async {
    try {
      // Obter contextos dos objetos de origem e destino
      final sourceContext = await getAgroContextForObject(sourceModuleId, sourceObjectId);
      final targetContext = await getAgroContextForObject(targetModuleId, targetObjectId);
      
      if (sourceContext != null && targetContext != null) {
        // Registrar a vinculação no histórico
        final now = DateTime.now();
        final activityId = Uuid().v4();
        await _atividadeRepository.inserir(AtividadeAgricola(
          id: activityId,
          tipoAtividade: TipoAtividade.integracao,
          detalhesId: '$sourceObjectId:$targetObjectId',
          talhaoId: sourceContext.talhaoId,
          safraId: sourceContext.safraId,
          culturaId: sourceContext.culturaId,
          descricao: 'Vinculação entre $sourceModuleId e $targetModuleId',
          dataAtividade: now,
          criadoEm: now,
          atualizadoEm: now,
          sincronizado: false,
        ));
      }
    } catch (e) {
      Logger.error("Erro ao vincular atividades: $e", e, null, "ModuleIntegrationService");
    }
  }

  /// Atualiza o ID de detalhes de uma atividade após criação do objeto
  Future<void> atualizarDetalhesAtividade({
    required String atividadeId,
    required String detalhesId,
  }) async {
    try {
      await _atividadeRepository.atualizarDetalhesId(atividadeId, detalhesId);
    } catch (e) {
      Logger.error("Erro ao atualizar detalhes da atividade: $e", e, null, "ModuleIntegrationService");
    }
  }
  
  /// Inicializa as tabelas de integração do banco de dados
  Future<void> initializeDatabase() async {
    try {
      final db = await AppDatabase.instance.database;
      Logger.info('Inicializando tabelas de integração entre módulos...', 'ModuleIntegrationService');
      
      // Verificar e criar tabela de atividades agrícolas se não existir
      await db.execute('''
        CREATE TABLE IF NOT EXISTS atividades_agricolas (
          id TEXT PRIMARY KEY,
          talhaoId TEXT NOT NULL,
          safraId TEXT NOT NULL,
          culturaId TEXT NOT NULL,
          tipoAtividade TEXT NOT NULL,
          dataAtividade TEXT NOT NULL,
          detalhesId TEXT NOT NULL,
          descricao TEXT,
          criadoEm TEXT NOT NULL,
          atualizadoEm TEXT NOT NULL,
          sincronizado INTEGER NOT NULL DEFAULT 0
        )
      ''');
      
      // Criar índices para otimizar consultas
      await _createIndices(db);
      
      // Criar tabela de configurações de integração (para futuras configurações específicas por módulo)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS modulo_config (
          moduleId TEXT PRIMARY KEY,
          configJson TEXT NOT NULL,
          version INTEGER NOT NULL DEFAULT 1,
          updatedAt TEXT NOT NULL
        )
      ''');
      
      Logger.info('Tabelas de integração inicializadas com sucesso!', 'ModuleIntegrationService');
    } catch (e) {
      Logger.error('Erro ao inicializar tabelas de integração: $e', e, null, 'ModuleIntegrationService');
    }
  }
  
  /// Cria índices para otimizar as consultas de integração
  Future<void> _createIndices(Database db) async {
    try {
      // Índice para consultas por talhão
      await db.execute('CREATE INDEX IF NOT EXISTS idx_atividades_talhao ON atividades_agricolas (talhaoId)');
      
      // Índice para consultas por safra
      await db.execute('CREATE INDEX IF NOT EXISTS idx_atividades_safra ON atividades_agricolas (safraId)');
      
      // Índice para consultas por cultura
      await db.execute('CREATE INDEX IF NOT EXISTS idx_atividades_cultura ON atividades_agricolas (culturaId)');
      
      // Índice para consultas por tipo de atividade
      await db.execute('CREATE INDEX IF NOT EXISTS idx_atividades_tipo ON atividades_agricolas (tipoAtividade)');
      
      // Índice para consultas por detalhesId (para encontrar atividades relacionadas a um objeto)
      await db.execute('CREATE INDEX IF NOT EXISTS idx_atividades_detalhes ON atividades_agricolas (detalhesId)');
      
      // Índice para ordenar por data de atividade (comum em listagens)
      await db.execute('CREATE INDEX IF NOT EXISTS idx_atividades_data ON atividades_agricolas (dataAtividade)');
      
      Logger.info('\u00cdndices criados com sucesso para tabelas de integração', 'ModuleIntegrationService');
    } catch (e) {
      Logger.error('Erro ao criar índices para tabelas de integração: $e', e, null, 'ModuleIntegrationService');
    }
  }
  
  /// Fecha o serviço de integração
  void dispose() {
    _contextController.close();
  }
}
