import 'dart:async';

// Usando alias para evitar conflitos entre os modelos Crop
import '../../../models/crop.dart' as app_model;
import '../../../database/models/crop.dart' as db_model;
import '../../../models/agricultural_product.dart';
import '../../../models/crop_variety.dart';
import '../../../models/talhao_model.dart';
import '../../../repositories/crop_repository.dart';
import '../../../repositories/crop_variety_repository.dart';
import '../../../repositories/agricultural_product_repository.dart';
import '../../../repositories/talhao_repository.dart';
import '../../../utils/logger.dart';

/// Serviço para integração entre os módulos do sistema
/// 
/// Este serviço centraliza o acesso aos dados de Talhões, Culturas e Variedades
/// e implementa um sistema de cache para melhorar o desempenho.
class ModulesIntegrationService {
  // Singleton
  static final ModulesIntegrationService _instance = ModulesIntegrationService._internal();
  factory ModulesIntegrationService() => _instance;
  ModulesIntegrationService._internal() {
    // Inicialização dos repositórios
    _talhaoRepository = TalhaoRepository();
    _cropRepository = CropRepository();
    _cropVarietyRepository = CropVarietyRepository();
    _agriculturalProductRepository = AgriculturalProductRepository();
  }

  // Repositórios
  late final TalhaoRepository _talhaoRepository;
  late final CropRepository _cropRepository;
  late final CropVarietyRepository _cropVarietyRepository;
  late final AgriculturalProductRepository _agriculturalProductRepository;

  // Cache de dados com expiração
  DateTime? _talhoesCacheTime;
  DateTime? _culturasCacheTime;
  DateTime? _variedadesCacheTime;

  // Dados em cache
  List<TalhaoModel>? _cachedTalhoes;
  List<app_model.Crop>? _cachedCulturas;
  List<CropVariety>? _cachedVariedades;
  
  // Cache específico para variedades por cultura
  final Map<String, List<CropVariety>> _cachedVariedadesPorCultura = {};
  final Map<String, DateTime> _variedadesPorCulturaTime = {};

  // Duração do cache em minutos
  static const int _cacheDurationMinutes = 3;

  /// Verifica se o cache ainda é válido
  bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime).inMinutes < _cacheDurationMinutes;
  }

  // ===========================================
  // MÉTODOS DE LIMPEZA DE CACHE
  // ===========================================

  /// Limpa o cache de talhões
  void limparCacheTalhoes() {
    Logger.info('Cache de talhões limpo');
    _cachedTalhoes = null;
    _talhoesCacheTime = null;
  }

  /// Limpa o cache de culturas
  void limparCacheCulturas() {
    Logger.info('Cache de culturas limpo');
    _cachedCulturas = null;
    _culturasCacheTime = null;
  }

  /// Limpa o cache de variedades
  void limparCacheVariedades() {
    Logger.info('Cache de variedades limpo');
    _cachedVariedades = null;
    _variedadesCacheTime = null;
    _cachedVariedadesPorCultura.clear();
    _variedadesPorCulturaTime.clear();
  }

  /// Limpa o cache de talhões, forçando uma nova consulta na próxima vez (alias)
  void clearTalhoesCache() {
    limparCacheTalhoes();
  }
  
  /// Limpa o cache de culturas, forçando uma nova consulta na próxima vez (alias)
  void clearCulturasCache() {
    limparCacheCulturas();
    _cachedVariedadesPorCultura.clear();
    _variedadesPorCulturaTime.clear();
    Logger.log('Cache de culturas e variedades limpo');
  }

  // ===========================================
  // MÉTODOS PARA TALHÕES
  // ===========================================

  /// Obtém todos os talhões (com cache)
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
      Logger.log('Retornando ${_cachedTalhoes!.length} talhões do cache');
      return _cachedTalhoes!;
    }
    
    try {
      final talhoes = await _talhaoRepository.loadTalhoes();
      _cachedTalhoes = talhoes;
      _talhoesCacheTime = DateTime.now();
      Logger.log('Carregados ${talhoes.length} talhões do repositório');
      return talhoes;
    } catch (e) {
      Logger.error('Erro ao carregar talhões: $e');
      return [];
    }
  }

  /// Filtra talhões por safra e cultura
  Future<List<TalhaoModel>> filtrarTalhoesPorSafraECultura({String? safraId, String? culturaId}) async {
    try {
      final talhoes = await getTalhoes();
      
      // Aplica filtros se fornecidos
      List<TalhaoModel> resultado = talhoes;
      
      if (safraId != null) {
        resultado = resultado.where((t) => t.observacoes?.contains(safraId) == true).toList();
      }
      
      if (culturaId != null) {
        resultado = resultado.where((t) => t.cultura == culturaId).toList();
      }
      
      return resultado;
    } catch (e) {
      Logger.error('Erro ao filtrar talhões: $e');
      return [];
    }
  }

  /// Obtém todos os talhões filtrados por safra
  Future<List<TalhaoModel>> getTalhoesPorSafra(String safra) async {
    try {
      final talhoes = await getTalhoes();
      return talhoes.where((t) => t.observacoes?.contains(safra) == true).toList();
    } catch (e) {
      Logger.error('Erro ao carregar talhões por safra: $e');
      return [];
    }
  }
  
  /// Obtém todos os talhões filtrados por cultura
  Future<List<TalhaoModel>> getTalhoesPorCultura(String culturaId) async {
    try {
      final talhoes = await getTalhoes();
      final talhoesFiltrados = talhoes.where((t) => t.cultura == culturaId).toList();
      Logger.log('Carregados ${talhoesFiltrados.length} talhões filtrados por cultura');
      return talhoesFiltrados;
    } catch (e) {
      Logger.error('Erro ao carregar talhões por cultura: $e');
      return [];
    }
  }

  /// Obtém um talhão pelo seu ID
  Future<TalhaoModel?> getTalhaoById(String id) async {
    try {
      // Primeiro verifica no cache
      if (_cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
        try {
          final talhao = _cachedTalhoes!.firstWhere((t) => t.id == id);
          Logger.log('Talhão $id encontrado no cache');
          return talhao;
        } catch (e) {
          // Talhão não encontrado no cache, continua para buscar no repositório
        }
      }
      
      // Se não encontrou no cache, busca no repositório
      final talhao = await _talhaoRepository.getTalhaoById(id);
      Logger.log('Talhão $id carregado do repositório');
      return talhao;
    } catch (e) {
      Logger.error('Erro ao buscar talhão $id: $e');
      return null;
    }
  }

  // ===========================================
  // MÉTODOS PARA CULTURAS
  // ===========================================

  /// Obtém todas as culturas disponíveis
  Future<List<app_model.Crop>> getCulturas({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
      Logger.log('Retornando ${_cachedCulturas!.length} culturas do cache');
      return _cachedCulturas!;
    }

    try {
      // Primeiro tenta carregar do repositório de culturas
      final culturas = await _cropRepository.getAll();
      
      if (culturas.isNotEmpty) {
        _cachedCulturas = culturas.map((dbCrop) => _convertDbCropToAppCrop(dbCrop)).whereType<app_model.Crop>().toList();
        _culturasCacheTime = DateTime.now();
        Logger.log('Carregadas ${culturas.length} culturas do repositório principal');
        return _cachedCulturas!;
      }
      
      // Se não encontrou no repositório principal, tenta buscar produtos agrícolas
      try {
        final produtos = await _agriculturalProductRepository.getAll();
        final culturasProdutos = produtos
            .where((p) => p.type == 'seed')
            .map((p) => app_model.Crop(
                  id: int.tryParse(p.id) ?? 0,
                  name: p.name,
                  scientificName: p.name, // Usando name como fallback
                  description: p.name,
                ))
            .toList();
        
        if (culturasProdutos.isNotEmpty) {
          _cachedCulturas = culturasProdutos;
          _culturasCacheTime = DateTime.now();
          Logger.log('Carregadas ${culturasProdutos.length} culturas do repositório de produtos');
          return culturasProdutos;
        }
      } catch (prodError) {
        Logger.error('Erro ao carregar produtos agrícolas: $prodError');
      }
      
      // Se não encontrou em nenhum lugar, retorna lista vazia
      _cachedCulturas = [];
      _culturasCacheTime = DateTime.now();
      Logger.log('Nenhuma cultura encontrada');
      return [];
    } catch (e) {
      Logger.error('Erro ao carregar culturas: $e');
      return [];
    }
  }

  /// Obtém uma cultura pelo ID (versão que aceita int)
  Future<app_model.Crop?> getCulturaById(int id) async {
    try {
      if (_cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
        try {
          final cultura = _cachedCulturas!.firstWhere((c) => c.id == id);
          Logger.log('Cultura $id encontrada no cache');
          return cultura;
        } catch (notFound) {
          // Continua para buscar no repositório
        }
      }
      
      final dbCultura = await _cropRepository.getById(id);
      if (dbCultura == null) return null;
      
      return app_model.Crop(
        id: dbCultura.id,
        name: dbCultura.name,
        scientificName: dbCultura.scientificName != null ? dbCultura.scientificName! : dbCultura.name,
        description: dbCultura.description,
      );
    } catch (e) {
      Logger.error('Erro ao buscar cultura: $id - $e');
      return null;
    }
  }

  /// Obtém informações detalhadas de uma cultura específica (versão que aceita String)
  Future<app_model.Crop?> getCulturaPorId(String culturaId) async {
    try {
      if (_cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
        try {
          final cultura = _cachedCulturas!.firstWhere((c) => c.id.toString() == culturaId);
          Logger.log('Cultura $culturaId encontrada no cache');
          return cultura;
        } catch (notFound) {
          // Continua para buscar no repositório
        }
      }
      
      final id = int.tryParse(culturaId);
      if (id == null) {
        Logger.error('ID de cultura inválido: $culturaId');
        return null;
      }
      
      final dbCultura = await _cropRepository.getById(id);
      if (dbCultura == null) return null;
      
      return app_model.Crop(
        id: dbCultura.id,
        name: dbCultura.name,
        scientificName: dbCultura.scientificName ?? dbCultura.name,
        description: dbCultura.description,
      );
    } catch (e) {
      Logger.error('Erro ao buscar cultura: $culturaId - $e');
      return null;
    }
  }

  // Helper para converter entre os tipos Crop
  app_model.Crop? _convertDbCropToAppCrop(db_model.Crop? dbCrop) {
    if (dbCrop == null) return null;
    
    return app_model.Crop(
      id: dbCrop.id,
      name: dbCrop.name,
      scientificName: dbCrop.scientificName != null ? dbCrop.scientificName! : dbCrop.name,
      description: dbCrop.description ?? '',
    );
  }
  
  // ===========================================
  // MÉTODOS PARA VARIEDADES
  // ===========================================

  /// Obtém todas as variedades disponíveis
  Future<List<CropVariety>> getVariedades({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedVariedades != null && _isCacheValid(_variedadesCacheTime)) {
      Logger.info('Retornando variedades do cache');
      return _cachedVariedades!;
    }

    try {
      Logger.info('Buscando variedades do repositório');
      final variedades = await _cropVarietyRepository.getAll();
      
      // Atualiza o cache
      _cachedVariedades = variedades;
      _variedadesCacheTime = DateTime.now();
      
      return variedades;
    } catch (e) {
      Logger.error('Erro ao buscar variedades: $e');
      return [];
    }
  }

  /// Obtém todas as variedades disponíveis (alias para compatibilidade)
  Future<List<CropVariety>> getAllVariedades({bool forceRefresh = false}) async {
    return getVariedades(forceRefresh: forceRefresh);
  }

  /// Obtém variedades por cultura (versão que aceita int ou String)
  Future<List<CropVariety>> getVariedadesPorCultura(dynamic culturaId, {bool forceRefresh = false}) async {
    final cacheKey = culturaId.toString();
    try {
      // Verifica se tem no cache específico por cultura e se é válido
      if (!forceRefresh &&
          _cachedVariedadesPorCultura.containsKey(cacheKey) && 
          _variedadesPorCulturaTime.containsKey(cacheKey) && 
          _isCacheValid(_variedadesPorCulturaTime[cacheKey])) {
        Logger.info('Retornando variedades da cultura $culturaId do cache');
        return _cachedVariedadesPorCultura[cacheKey]!;
      }

      Logger.info('Buscando variedades da cultura $culturaId do repositório');
      int cropId;
      if (culturaId is String) {
        cropId = int.tryParse(culturaId) ?? 0;
      } else if (culturaId is int) {
        cropId = culturaId;
      } else {
        cropId = 0;
      }
      
      if (cropId == 0) {
        Logger.error('ID de cultura inválido: $culturaId');
        return [];
      }
      
      // Convertendo cropId para String conforme esperado pelo repository
      final variedades = await _cropVarietyRepository.getByCropId(cropId.toString());
      
      // Atualiza o cache específico por cultura
      _cachedVariedadesPorCultura[cacheKey] = variedades;
      _variedadesPorCulturaTime[cacheKey] = DateTime.now();
      
      return variedades;
    } catch (e) {
      Logger.error('Erro ao buscar variedades da cultura $culturaId: $e');
      return [];
    }
  }

  /// Obtém todas as variedades disponíveis para uma cultura específica (versão que aceita String)
  Future<List<CropVariety>> getVariedadesPorCulturaId(String culturaId, {bool forceRefresh = false}) async {
    return getVariedadesPorCultura(culturaId, forceRefresh: forceRefresh);
  }

  /// Obtém uma variedade pelo ID (versão que aceita int)
  Future<CropVariety?> getVariedadeById(int id) async {
    try {
      // Primeiro verifica no cache
      if (_cachedVariedades != null && _isCacheValid(_variedadesCacheTime)) {
        try {
          final variedade = _cachedVariedades!.firstWhere((v) => v.id == id.toString());
          Logger.log('Variedade $id encontrada no cache');
          return variedade;
        } catch (notFound) {
          // Continua para buscar no repositório
        }
      }
      
      // Se não encontrou no cache, busca no repositório
      final variedade = await _cropVarietyRepository.getById(id.toString());
      return variedade;
    } catch (e) {
      Logger.error('Erro ao buscar variedade $id: $e');
      return null;
    }
  }

  /// Obtém informações detalhadas de uma variedade específica (versão que aceita String)
  Future<CropVariety?> getVariedadePorId(String variedadeId) async {
    try {
      // Primeiro verifica no cache
      if (_cachedVariedades != null && _isCacheValid(_variedadesCacheTime)) {
        final variedade = _cachedVariedades!.firstWhere(
          (v) => v.id.toString() == variedadeId,
          orElse: () => CropVariety(id: '0', name: '', cropId: '0', description: '')
        );
        if (variedade.id != '0') return variedade;
      }
      
      // Se não estiver no cache, busca diretamente no repositório
      final variedade = await _cropVarietyRepository.getById(variedadeId);
      return variedade;
    } catch (e) {
      Logger.error('Erro ao buscar variedade $variedadeId: $e');
      return null;
    }
  }
}