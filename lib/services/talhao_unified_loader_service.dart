import 'package:flutter/material.dart';
import '../models/talhao_model.dart';
import '../repositories/talhao_repository.dart';
import '../repositories/talhoes/talhao_sqlite_repository.dart';
import '../repositories/talhoes/talhao_safra_repository.dart';
import '../services/talhao_service.dart';
import '../modules/planting/services/data_cache_service.dart';

/// Serviço unificado para carregamento de talhões em todos os módulos
/// Resolve o problema de inconsistência entre diferentes repositórios
class TalhaoUnifiedLoaderService {
  static final TalhaoUnifiedLoaderService _instance = TalhaoUnifiedLoaderService._internal();
  factory TalhaoUnifiedLoaderService() => _instance;
  TalhaoUnifiedLoaderService._internal();

  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final TalhaoSQLiteRepository _talhaoSQLiteRepository = TalhaoSQLiteRepository();
  final TalhaoSafraRepository _talhaoSafraRepository = TalhaoSafraRepository();
  final TalhaoService _talhaoService = TalhaoService();
  final DataCacheService _dataCacheService = DataCacheService();

  /// Carrega talhões de todas as fontes disponíveis e retorna uma lista unificada
  Future<List<TalhaoModel>> carregarTalhoes({bool forceRefresh = false}) async {
    try {
      print('🔄 [TalhaoUnifiedLoader] Iniciando carregamento unificado de talhões...');
      
      List<TalhaoModel> talhoes = [];
      
      // 1. Tentar carregar do TalhaoRepository (fonte principal)
      try {
        print('📋 [TalhaoUnifiedLoader] Tentando carregar do TalhaoRepository...');
        talhoes = await _talhaoRepository.getTalhoes();
        if (talhoes.isNotEmpty) {
          print('✅ [TalhaoUnifiedLoader] ${talhoes.length} talhões carregados do TalhaoRepository');
          return talhoes;
        }
      } catch (e) {
        print('❌ [TalhaoUnifiedLoader] Erro no TalhaoRepository: $e');
      }
      
      // 2. Tentar carregar do TalhaoSQLiteRepository
      try {
        print('📋 [TalhaoUnifiedLoader] Tentando carregar do TalhaoSQLiteRepository...');
        talhoes = await _talhaoSQLiteRepository.listarTodos();
        if (talhoes.isNotEmpty) {
          print('✅ [TalhaoUnifiedLoader] ${talhoes.length} talhões carregados do TalhaoSQLiteRepository');
          return talhoes;
        }
      } catch (e) {
        print('❌ [TalhaoUnifiedLoader] Erro no TalhaoSQLiteRepository: $e');
      }
      
      // 3. Tentar carregar do TalhaoService
      try {
        print('📋 [TalhaoUnifiedLoader] Tentando carregar do TalhaoService...');
        talhoes = await _talhaoService.listarTodos();
        if (talhoes.isNotEmpty) {
          print('✅ [TalhaoUnifiedLoader] ${talhoes.length} talhões carregados do TalhaoService');
          return talhoes;
        }
      } catch (e) {
        print('❌ [TalhaoUnifiedLoader] Erro no TalhaoService: $e');
      }
      
      // 4. Tentar carregar do DataCacheService
      try {
        print('📋 [TalhaoUnifiedLoader] Tentando carregar do DataCacheService...');
        talhoes = await _dataCacheService.getTalhoes(forceRefresh: forceRefresh);
        if (talhoes.isNotEmpty) {
          print('✅ [TalhaoUnifiedLoader] ${talhoes.length} talhões carregados do DataCacheService');
          return talhoes;
        }
      } catch (e) {
        print('❌ [TalhaoUnifiedLoader] Erro no DataCacheService: $e');
      }
      
      // 5. Tentar carregar do TalhaoSafraRepository (converter para TalhaoModel)
      try {
        print('📋 [TalhaoUnifiedLoader] Tentando carregar do TalhaoSafraRepository...');
        final talhoesSafra = await _talhaoSafraRepository.listarTodosTalhoes();
        if (talhoesSafra.isNotEmpty) {
          // Converter TalhaoSafraModel para TalhaoModel
          talhoes = talhoesSafra.map((talhaoSafra) => _convertTalhaoSafraToTalhaoModel(talhaoSafra)).toList();
          print('✅ [TalhaoUnifiedLoader] ${talhoes.length} talhões carregados do TalhaoSafraRepository');
          return talhoes;
        }
      } catch (e) {
        print('❌ [TalhaoUnifiedLoader] Erro no TalhaoSafraRepository: $e');
      }
      
      // Se chegou até aqui, não conseguiu carregar de nenhuma fonte
      print('⚠️ [TalhaoUnifiedLoader] Nenhum talhão encontrado em nenhuma fonte');
      return [];
      
    } catch (e) {
      print('❌ [TalhaoUnifiedLoader] Erro geral ao carregar talhões: $e');
      return [];
    }
  }
  
  /// Converte TalhaoSafraModel para TalhaoModel
  TalhaoModel _convertTalhaoSafraToTalhaoModel(dynamic talhaoSafra) {
    try {
      return TalhaoModel(
        id: talhaoSafra.id?.toString() ?? '',
        name: talhaoSafra.nome ?? talhaoSafra.name ?? 'Sem nome',
        area: talhaoSafra.area?.toDouble() ?? 0.0,
        fazendaId: talhaoSafra.idFazenda?.toString(),
        poligonos: [], // Será preenchido se necessário
        safras: [], // Será preenchido se necessário
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false,
      );
    } catch (e) {
      print('❌ [TalhaoUnifiedLoader] Erro ao converter TalhaoSafraModel: $e');
      return TalhaoModel(
        id: 'erro_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Erro na conversão',
        area: 0.0,
        poligonos: [],
        safras: [],
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
        sincronizado: false,
      );
    }
  }
  
  /// Carrega um talhão específico por ID
  Future<TalhaoModel?> carregarTalhaoPorId(String id) async {
    try {
      print('🔄 [TalhaoUnifiedLoader] Carregando talhão por ID: $id');
      
      // Tentar carregar de todas as fontes
      final talhoes = await carregarTalhoes();
      
      // Procurar o talhão específico
      for (final talhao in talhoes) {
        if (talhao.id == id) {
          print('✅ [TalhaoUnifiedLoader] Talhão encontrado: ${talhao.name}');
          return talhao;
        }
      }
      
      print('⚠️ [TalhaoUnifiedLoader] Talhão não encontrado: $id');
      return null;
      
    } catch (e) {
      print('❌ [TalhaoUnifiedLoader] Erro ao carregar talhão por ID: $e');
      return null;
    }
  }
  
  /// Verifica se há talhões disponíveis
  Future<bool> temTalhoesDisponiveis() async {
    try {
      final talhoes = await carregarTalhoes();
      return talhoes.isNotEmpty;
    } catch (e) {
      print('❌ [TalhaoUnifiedLoader] Erro ao verificar disponibilidade: $e');
      return false;
    }
  }
  
  /// Carrega talhões para um módulo específico
  Future<List<TalhaoModel>> carregarTalhoesParaModulo({
    required String nomeModulo,
    bool forceRefresh = false,
  }) async {
    try {
      print('🔄 [TalhaoUnifiedLoader] Carregando talhões para módulo: $nomeModulo');
      
      // Usar o método principal de carregamento
      final talhoes = await carregarTalhoes(forceRefresh: forceRefresh);
      
      print('✅ [TalhaoUnifiedLoader] ${talhoes.length} talhões carregados para $nomeModulo');
      return talhoes;
      
    } catch (e) {
      print('❌ [TalhaoUnifiedLoader] Erro ao carregar talhões para $nomeModulo: $e');
      return [];
    }
  }

  /// Retorna informações de debug sobre as fontes de dados
  Future<Map<String, dynamic>> getDebugInfo() async {
    final info = <String, dynamic>{};
    
    try {
      // Testar cada fonte
      final talhaoRepo = await _talhaoRepository.getTalhoes();
      info['talhao_repository'] = talhaoRepo.length;
      
      final talhaoSQLite = await _talhaoSQLiteRepository.listarTodos();
      info['talhao_sqlite_repository'] = talhaoSQLite.length;
      
      final talhaoService = await _talhaoService.listarTodos();
      info['talhao_service'] = talhaoService.length;
      
      final dataCache = await _dataCacheService.getTalhoes();
      info['data_cache_service'] = dataCache.length;
      
      final talhaoSafra = await _talhaoSafraRepository.listarTodosTalhoes();
      info['talhao_safra_repository'] = talhaoSafra.length;
      
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }
}
