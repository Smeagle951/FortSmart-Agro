import 'dart:async';

import '../../../models/crop.dart';
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
  List<Crop>? _cachedCulturas;
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
  
  /// Obtém todos os talhões (com cache)
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
      Logger.log('Retornando ${_cachedTalhoes!.length} talhões do cache');
      return Future.value(_cachedTalhoes!);
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

  /// Limpa o cache de talhões, forçando uma nova consulta na próxima vez
  void clearTalhoesCache() {
    _cachedTalhoes = null;
    _talhoesCacheTime = null;
    Logger.log('Cache de talhões limpo');
  }
  
  /// Limpa o cache de culturas, forçando uma nova consulta na próxima vez
  void clearCulturasCache() {
    _cachedCulturas = null;
    _culturasCacheTime = null;
    _cachedVariedadesPorCultura.clear();
    _variedadesPorCulturaTime.clear();
    Logger.log('Cache de culturas e variedades limpo');
  }

  // ===========================================
  // MÉTODOS PARA TALHÕES
  // ===========================================

  /// Busca todas os talhões da base de dados
  Future<List<TalhaoModel>> getTalhoes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
      return _cachedTalhoes!;
    }

    try {
      // Usando loadTalhoes do repositório para obter todos os talhões
      final talhoes = await _talhaoRepository.loadTalhoes();
      if (talhoes.isNotEmpty) {
        _cachedTalhoes = talhoes;
        _talhoesCacheTime = DateTime.now();
        return talhoes;
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao buscar talhões: $e');
      return [];
    }
      return []; // Retorna lista vazia em vez de rethrow
    }
  }

  /// Filtra talhões por safra e cultura
  Future<List<TalhaoModel>> filtrarTalhoesPorSafraECultura({String? safraId, String? culturaId}) async {
    try {
      final talhoes = await getTalhoes();
      // Verificando se o talhão está associado à safra especificada
      // Em uma implementação completa, buscaríamos pela safra relacionada
      // Como não há campo safra explicitamente, vamos fazer matching baseado apenas no ID de safra
      // que pode estar em dados adicionais ou observações, etc.
      // Como safraId pode ser nulo, verificamos antes de fazer o filtro
      if (safraId == null) return talhoes;
      return talhoes.where((t) => t.observacoes?.contains(safraId) == true).toList();
    } catch (e) {
      Logger.error('Erro ao filtrar talhões: $e');
      return [];
    }
  }

  /// Obtém todos os talhões filtrados por safra
  Future<List<TalhaoModel>> getTalhoesPorSafra(String safra) async {
    if (_cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
      try {
        return _cachedTalhoes!.where((t) => t.observacoes?.contains(safra) == true).toList();
      } catch (e) {
        // Continua para buscar no repositório
      }
    }

    try {
      // Usando loadTalhoes que é o método correto para obter todos os talhões
      final talhoes = await _talhaoRepository.loadTalhoes();
      if (talhoes.isNotEmpty) {
        _cachedTalhoes = talhoes;
        _talhoesCacheTime = DateTime.now();
        Logger.log('Carregados ${talhoes.length} talhões do repositório');
        // Filtra os talhões pela safra
        return talhoes.where((t) => t.observacoes?.contains(safra) == true).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao carregar talhões por safra: $e');
      return [];
    }
  }
  
  /// Obtém todos os talhões filtrados por cultura
  Future<List<TalhaoModel>> getTalhoesPorCultura(String culturaId) async {
    if (_cachedTalhoes != null && _isCacheValid(_talhoesCacheTime)) {
      try {
        return _cachedTalhoes!.where((t) => t.cultura == culturaId).toList();
      } catch (e) {
        // Continua para buscar no repositório
      }
    }

    try {
      // Usando loadTalhoes que é o método correto para obter todos os talhões
      final talhoes = await _talhaoRepository.loadTalhoes();
      // Filtrando apenas pelo campo cultura existente
      final talhoesFiltrados = talhoes.where((t) => t.cultura == culturaId).toList();
      Logger.log('Carregados ${talhoesFiltrados.length} talhões filtrados por cultura do repositório');
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
          final talhao = _cachedTalhoes!.firstWhere(
            (t) => t.id == id,
          );
          Logger.log('Talhão $id encontrado no cache');
          return talhao;
        } catch (e) {
          // Talhão não encontrado no cache, continua para buscar no repositório
        }
      }
      
      // Se não encontrou no cache, busca no repositório
      final talhao = await _talhaoRepository.buscarPorId(id);
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
  Future<List<Crop>> getCulturas({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
      Logger.log('Retornando ${_cachedCulturas!.length} culturas do cache');
      return _cachedCulturas!;
    }

    try {
      // Primeiro tenta carregar do repositório de culturas
      final culturas = await _cropRepository.getAll();
      
      if (culturas.isNotEmpty) {
        _cachedCulturas = List<Crop>.from(culturas);
        _culturasCacheTime = DateTime.now();
        Logger.log('Carregadas ${culturas.length} culturas do repositório principal');
        return Future<List<Crop>>.value(culturas);
      }
      
      // Se não encontrou no repositório principal, tenta buscar produtos agrícolas
      try {
        final produtos = await _agriculturalProductRepository.getAll();
        final culturasProdutos = produtos
            .where((p) => p.type == 'seed')
            .map((p) => Crop(
                  id: int.tryParse(p.id ?? '0') ?? 0,
                  name: p.name ?? '',
                  scientificName: p.name ?? '', // Usando name como fallback
                  description: p.name ?? '',
                ))
            .toList();
        
        if (culturasProdutos.isNotEmpty) {
          _cachedCulturas = culturasProdutos;
          _culturasCacheTime = DateTime.now();
          Logger.log('Carregadas ${culturasProdutos.length} culturas do repositório de produtos');
          return Future<List<Crop>>.value(culturasProdutos);
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
  Future<Crop?> getCulturaById(int id) async {
    try {
      if (_cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
        try {
          final cultura = _cachedCulturas!.firstWhere((c) => c.id == id);
          Logger.log('Cultura $id encontrada no cache');
          return Future<Crop?>.value(cultura);
        } catch (notFound) {
          // Continua para buscar no repositório
        }
      }
      
      final cultura = await _cropRepository.getById(id);
      return Future<Crop?>.value(cultura);
    } catch (e) {
      Logger.error('Erro ao buscar cultura $id: $e');
      return null;
    }
  }

  /// Obtém informações detalhadas de uma cultura específica (versão que aceita String)
  Future<Crop?> getCulturaPorId(String culturaId) async {
    try {
      if (_cachedCulturas != null && _isCacheValid(_culturasCacheTime)) {
        try {
          final cultura = _cachedCulturas!.firstWhere((c) => c.id.toString() == culturaId);
          Logger.log('Cultura $culturaId encontrada no cache');
          return Future<Crop?>.value(cultura);
        } catch (notFound) {
          // Continua para buscar no repositório
        }
      }
      
      final id = int.tryParse(culturaId);
      if (id == null) {
        Logger.error('ID de cultura inválido: $culturaId');
        return Future<Crop?>.value(null);
      }
      
      final cultura = await _cropRepository.getById(id);
      return Future<Crop?>.value(cultura);
    } catch (e) {
      Logger.error('Erro ao buscar cultura $culturaId: $e');
      return null;
    }
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
    if (!forceRefresh && 
        _cachedVariedadesPorCultura.containsKey(culturaId) && 
        _variedadesPorCulturaTime.containsKey(culturaId) &&
        _isCacheValid(_variedadesPorCulturaTime[culturaId])) {
      Logger.log('Retornando ${_cachedVariedadesPorCultura[culturaId]!.length} variedades da cultura $culturaId do cache');
      return _cachedVariedadesPorCultura[culturaId]!;
    }

    try {
      // Primeiro tenta carregar do repositório de variedades
      final id = int.tryParse(culturaId);
      if (id == null) {
        Logger.error('ID de cultura inválido: $culturaId');
        return Future<List<CropVariety>>.value([]);
      }

      final variedades = await _cropVarietyRepository.getByCropId(id.toString());
      
      if (variedades.isNotEmpty) {
        _cachedVariedadesPorCultura[culturaId] = variedades;
        _variedadesPorCulturaTime[culturaId] = DateTime.now();
        Logger.log('Carregadas ${variedades.length} variedades para cultura $culturaId do repositório principal');
        return variedades;
      }
      
      // Se não encontrou, retorna lista vazia
      _cachedVariedadesPorCultura[culturaId] = [];
      _variedadesPorCulturaTime[culturaId] = DateTime.now();
      Logger.log('Nenhuma variedade encontrada para cultura $culturaId');
      return [];
    } catch (e) {
      Logger.error('Erro ao carregar variedades para cultura $culturaId: $e');
      return [];
    }
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
      // Como o método getById no repositório espera uma String, vamos usar ele diretamente
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
      // Passamos o ID como string já que o repositório espera String
      final variedade = await _cropVarietyRepository.getById(variedadeId);
      return variedade;
    } catch (e) {
      Logger.error('Erro ao buscar variedade $variedadeId: $e');
      return null;
    }
  }
}