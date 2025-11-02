import '../../../models/talhao_model_new.dart';
import '../../../models/agricultural_product.dart';
import '../../../models/safra_model.dart';
import 'data_cache_service.dart';

/// Serviço para gerenciar o contexto agrícola e integração entre módulos
class ContextoAgricolaService {
  final DataCacheService _cacheService = DataCacheService();
  
  /// Carrega o contexto completo de um talhão, incluindo safra atual e cultura
  Future<Map<String, dynamic>> carregarContextoDoTalhao(String talhaoId) async {
    // Carregar talhão
    final talhoes = await _cacheService.getTalhoes();
    final talhao = talhoes.firstWhere(
      (t) => t.id == talhaoId,
      orElse: () => throw Exception('Talhão não encontrado'),
    );
    
    // Obter safra atual
    final safraAtual = talhao.safraAtual;
    if (safraAtual == null) {
      throw Exception('Talhão não possui safra atual');
    }
    
    // Carregar cultura
    final culturas = await _cacheService.getCulturas();
    final cultura = culturas.firstWhere(
      (c) => c.id == safraAtual.culturaId,
      orElse: () => throw Exception('Cultura não encontrada'),
    );
    
    // Carregar variedades da cultura
    final variedades = await _cacheService.getVariedades(culturaId: cultura.id);
    
    return {
      'talhao': talhao,
      'safra': safraAtual,
      'cultura': cultura,
      'variedades': variedades,
    };
  }

  /// Valida se um talhão está pronto para ser usado em operações agrícolas
  Future<bool> validarTalhao(String talhaoId) async {
    try {
      final contexto = await carregarContextoDoTalhao(talhaoId);
      return contexto['safra'] != null && contexto['cultura'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtém os parâmetros técnicos de uma cultura
  Future<Map<String, dynamic>> obterParametrosTecnicosCultura(String culturaId) async {
    final culturas = await _cacheService.getCulturas();
    final cultura = culturas.firstWhere(
      (c) => c.id == culturaId,
      orElse: () => throw Exception('Cultura não encontrada'),
    );

    // Retorna os parâmetros técnicos da cultura
    return {
      'populacaoIdeal': cultura.dosageRecommendation,
      'espacamento': cultura.applicationInstructions,
      'sementesPorSaco': cultura.concentration,
    };
  }

  /// Obtém as variedades disponíveis para uma cultura
  Future<List<AgriculturalProduct>> obterVariedadesCultura(String culturaId) async {
    return await _cacheService.getVariedades(culturaId: culturaId);
  }
}
