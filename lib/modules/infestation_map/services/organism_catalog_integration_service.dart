import '../../../models/organism_catalog.dart';
import '../../../repositories/organism_catalog_repository.dart';
import '../../../services/organism_catalog_loader_service.dart';
import '../../../utils/enums.dart';
import '../../../utils/logger.dart';
import 'infestation_cache_service.dart';

/// Serviço para integração com o catálogo de organismos
/// Obtém thresholds reais e pesos de risco para classificação de infestação
class OrganismCatalogIntegrationService {
  final OrganismCatalogRepository _repository = OrganismCatalogRepository();
  final OrganismCatalogLoaderService _loaderService = OrganismCatalogLoaderService();
  final InfestationCacheService _cacheService = InfestationCacheService();

  /// Obtém pesos de risco para organismos
  /// Retorna um mapa com organismo ID e seu peso de risco
  Future<Map<String, double>> getRiskWeights() async {
    try {
      Logger.info('🔍 Obtendo pesos de risco dos organismos');
      
      // Tentar obter do cache primeiro
      final cachedThresholds = await _cacheService.getOrganismThresholdsCache();
      if (cachedThresholds != null && cachedThresholds['thresholds'] != null) {
        final thresholds = cachedThresholds['thresholds'] as List;
        final riskWeights = <String, double>{};
        
        for (final threshold in thresholds) {
          final thresholdMap = threshold as Map<String, dynamic>;
          riskWeights[thresholdMap['id'] as String] = thresholdMap['peso_risco'] as double;
        }
        
        Logger.info('✅ Pesos de risco obtidos do cache: ${riskWeights.length} organismos');
        return riskWeights;
      }
      
      // Se não estiver no cache, buscar organismos validados
      final organisms = await _loaderService.getValidatedOrganismsForInfestationMap();
      final riskWeights = <String, double>{};

      for (final organism in organisms) {
        // Calcular peso baseado no tipo e thresholds
        final riskWeight = _calculateRiskWeight(organism);
        riskWeights[organism.id] = riskWeight;
      }

      Logger.info('✅ Pesos de risco obtidos para ${riskWeights.length} organismos validados');
      return riskWeights;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter pesos de risco: $e');
      return {};
    }
  }

  /// Obtém organismos validados para uso no mapa de infestação
  Future<List<OrganismCatalog>> getValidatedOrganisms() async {
    try {
      Logger.info('🔍 Obtendo organismos validados para mapa de infestação...');
      
      final organisms = await _loaderService.getValidatedOrganismsForInfestationMap();
      
      Logger.info('✅ ${organisms.length} organismos validados obtidos');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos validados: $e');
      return [];
    }
  }

  /// Obtém organismos por cultura validados
  Future<List<OrganismCatalog>> getValidatedOrganismsByCrop(String cropId) async {
    try {
      Logger.info('🔍 Obtendo organismos validados para cultura: $cropId');
      
      final allOrganisms = await getValidatedOrganisms();
      final cropOrganisms = allOrganisms.where((org) => org.cropId == cropId).toList();
      
      Logger.info('✅ ${cropOrganisms.length} organismos validados para cultura $cropId');
      return cropOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por cultura: $e');
      return [];
    }
  }

  /// Obtém thresholds para um organismo específico
  Future<Map<String, dynamic>?> getOrganismThresholds(String organismId) async {
    try {
      Logger.info('🔍 Obtendo thresholds do organismo: $organismId');
      
      final organism = await _repository.getById(organismId);
      if (organism == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismId');
        return null;
      }

      final thresholds = {
        'id': organism.id,
        'nome': organism.name,
        'nome_cientifico': organism.scientificName,
        'tipo': organism.type.toString().split('.').last,
        'cultura_id': organism.cropId,
        'cultura_nome': organism.cropName,
        'unidade': organism.unit,
        'limite_baixo': organism.lowLimit,
        'limite_medio': organism.mediumLimit,
        'limite_alto': organism.highLimit,
        'peso_risco': _calculateRiskWeight(organism),
        'descricao': organism.description,
        'ativo': organism.isActive,
      };

      Logger.info('✅ Thresholds do organismo obtidos: ${organism.name}');
      return thresholds;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter thresholds do organismo: $e');
      return null;
    }
  }

  /// Obtém thresholds para todos os organismos
  Future<List<Map<String, dynamic>>> getAllThresholds() async {
    try {
      Logger.info('🔍 Obtendo thresholds de todos os organismos');
      
      // Tentar obter do cache primeiro
      final cachedThresholds = await _cacheService.getOrganismThresholdsCache();
      if (cachedThresholds != null && cachedThresholds['thresholds'] != null) {
        final thresholds = cachedThresholds['thresholds'] as List;
        Logger.info('✅ Thresholds obtidos do cache: ${thresholds.length} organismos');
        return thresholds.cast<Map<String, dynamic>>();
      }
      
      // Se não estiver no cache, buscar do repositório
      final organisms = await _repository.getAll();
      final thresholds = <Map<String, dynamic>>[];

      for (final organism in organisms) {
        thresholds.add({
          'id': organism.id,
          'nome': organism.name,
          'nome_cientifico': organism.scientificName,
          'tipo': organism.type.toString().split('.').last,
          'cultura_id': organism.cropId,
          'cultura_nome': organism.cropName,
          'unidade': organism.unit,
          'limite_baixo': organism.lowLimit,
          'limite_medio': organism.mediumLimit,
          'limite_alto': organism.highLimit,
          'peso_risco': _calculateRiskWeight(organism),
          'descricao': organism.description,
          'ativo': organism.isActive,
        });
      }

      // Salvar no cache
      await _cacheService.cacheOrganismThresholds({
        'thresholds': thresholds,
        'timestamp': DateTime.now().toIso8601String(),
        'count': thresholds.length,
      });
      Logger.info('💾 Thresholds salvos no cache: ${thresholds.length} organismos');

      Logger.info('✅ Thresholds obtidos para ${thresholds.length} organismos');
      return thresholds;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter thresholds: $e');
      return [];
    }
  }

  /// Obtém thresholds por tipo de organismo
  Future<List<Map<String, dynamic>>> getThresholdsByType(OccurrenceType type) async {
    try {
      Logger.info('🔍 Obtendo thresholds por tipo: ${type.toString().split('.').last}');
      
      final organisms = await _repository.getByType(type);
      final thresholds = <Map<String, dynamic>>[];

      for (final organism in organisms) {
        thresholds.add({
          'id': organism.id,
          'nome': organism.name,
          'nome_cientifico': organism.scientificName,
          'tipo': organism.type.toString().split('.').last,
          'cultura_id': organism.cropId,
          'cultura_nome': organism.cropName,
          'unidade': organism.unit,
          'limite_baixo': organism.lowLimit,
          'limite_medio': organism.mediumLimit,
          'limite_alto': organism.highLimit,
          'peso_risco': _calculateRiskWeight(organism),
          'descricao': organism.description,
          'ativo': organism.isActive,
        });
      }

      Logger.info('✅ Thresholds obtidos para ${thresholds.length} organismos do tipo ${type.toString().split('.').last}');
      return thresholds;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter thresholds por tipo: $e');
      return [];
    }
  }

  /// Obtém thresholds por cultura
  Future<List<Map<String, dynamic>>> getThresholdsByCrop(String cropId) async {
    try {
      Logger.info('🔍 Obtendo thresholds por cultura: $cropId');
      
      final organisms = await _repository.getByCrop(cropId);
      final thresholds = <Map<String, dynamic>>[];

      for (final organism in organisms) {
        thresholds.add({
          'id': organism.id,
          'nome': organism.name,
          'nome_cientifico': organism.scientificName,
          'tipo': organism.type.toString().split('.').last,
          'cultura_id': organism.cropId,
          'cultura_nome': organism.cropName,
          'unidade': organism.unit,
          'limite_baixo': organism.lowLimit,
          'limite_medio': organism.mediumLimit,
          'limite_alto': organism.highLimit,
          'peso_risco': _calculateRiskWeight(organism),
          'descricao': organism.description,
          'ativo': organism.isActive,
        });
      }

      Logger.info('✅ Thresholds obtidos para ${thresholds.length} organismos da cultura $cropId');
      return thresholds;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter thresholds por cultura: $e');
      return [];
    }
  }

  /// Obtém dados do organismo para cálculo de infestação
  Future<Map<String, dynamic>?> getOrganismData(String organismId, String cropId) async {
    try {
      Logger.info('🔍 Obtendo dados do organismo para cálculo: $organismId (cultura: $cropId)');
      
      final organism = await _repository.getById(organismId);
      if (organism == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismId');
        return null;
      }

      // Verificar se o organismo pertence à cultura especificada
      if (organism.cropId != cropId) {
        Logger.warning('⚠️ Organismo $organismId não pertence à cultura $cropId');
        return null;
      }

      final data = {
        'id': organism.id,
        'nome': organism.name,
        'nome_cientifico': organism.scientificName,
        'tipo': organism.type.toString().split('.').last,
        'categoria': organism.type.toString().split('.').last,
        'cultura_id': organism.cropId,
        'cultura_nome': organism.cropName,
        'unidade': organism.unit,
        'limite_baixo': organism.lowLimit,
        'limite_medio': organism.mediumLimit,
        'limite_alto': organism.highLimit,
        'peso_risco': _calculateRiskWeight(organism),
        'descricao': organism.description,
        'ativo': organism.isActive,
        'versao': '1.0',
        'severidade': {
          'baixo': {
            'limite': organism.lowLimit,
            'cor_alerta': '#4CAF50',
            'descricao': 'Baixa infestação',
          },
          'medio': {
            'limite': organism.mediumLimit,
            'cor_alerta': '#FF9800',
            'descricao': 'Infestação moderada',
          },
          'alto': {
            'limite': organism.highLimit,
            'cor_alerta': '#F44336',
            'descricao': 'Alta infestação',
          },
        },
      };

      Logger.info('✅ Dados do organismo obtidos: ${organism.name}');
      return data;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter dados do organismo: $e');
      return null;
    }
  }

  /// Obtém organismo por ID (compatibilidade)
  Future<OrganismCatalog?> getOrganismById(String organismId) async {
    try {
      Logger.info('🔍 Obtendo organismo por ID: $organismId');
      
      final organism = await _repository.getById(organismId);
      if (organism == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismId');
        return null;
      }

      Logger.info('✅ Organismo obtido: ${organism.name}');
      return organism;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismo por ID: $e');
      return null;
    }
  }

  /// Obtém informações completas de um organismo
  Future<Map<String, dynamic>?> getOrganismInfo(String organismId) async {
    try {
      Logger.info('🔍 Obtendo informações do organismo: $organismId');
      
      final organism = await _repository.getById(organismId);
      if (organism == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismId');
        return null;
      }

      final info = {
        'id': organism.id,
        'nome': organism.name,
        'nome_cientifico': organism.scientificName,
        'tipo': organism.type.toString().split('.').last,
        'cultura_id': organism.cropId,
        'cultura_nome': organism.cropName,
        'unidade': organism.unit,
        'limite_baixo': organism.lowLimit,
        'limite_medio': organism.mediumLimit,
        'limite_alto': organism.highLimit,
        'peso_risco': _calculateRiskWeight(organism),
        'descricao': organism.description,
        'imagem_url': organism.imageUrl,
        'ativo': organism.isActive,
        'data_criacao': organism.createdAt.toIso8601String(),
        'data_atualizacao': organism.updatedAt?.toIso8601String(),
        'metadados': {
          'tipo_enum': organism.type.toString(),
          'severidade_padrao': _getDefaultSeverity(organism),
          'categoria_risco': _getRiskCategory(organism),
        },
      };

      Logger.info('✅ Informações do organismo obtidas: ${organism.name}');
      return info;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter informações do organismo: $e');
      return null;
    }
  }

  /// Determina o nível de infestação baseado nos thresholds reais
  Future<String> determineInfestationLevel(
    String organismId, 
    double infestationValue,
  ) async {
    try {
      Logger.info('🔍 Determinando nível de infestação para organismo: $organismId (valor: $infestationValue)');
      
      final organism = await _repository.getById(organismId);
      if (organism == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismId');
        return 'DESCONHECIDO';
      }

      final level = organism.getAlertLevel(infestationValue.toInt());
      final levelString = _convertAlertLevelToString(level);
      
      Logger.info('✅ Nível de infestação determinado: $levelString');
      return levelString;
      
    } catch (e) {
      Logger.error('❌ Erro ao determinar nível de infestação: $e');
      return 'DESCONHECIDO';
    }
  }

  /// Obtém organismos mais críticos (com thresholds mais baixos)
  Future<List<Map<String, dynamic>>> getCriticalOrganisms({int limit = 10}) async {
    try {
      Logger.info('🔍 Obtendo organismos mais críticos (limite: $limit)');
      
      final organisms = await _repository.getAll();
      
      // Ordenar por criticidade (thresholds mais baixos = mais críticos)
      organisms.sort((a, b) => a.lowLimit.compareTo(b.lowLimit));
      
      final criticalOrganisms = <Map<String, dynamic>>[];
      for (int i = 0; i < organisms.length && i < limit; i++) {
        final organism = organisms[i];
        criticalOrganisms.add({
          'id': organism.id,
          'nome': organism.name,
          'nome_cientifico': organism.scientificName,
          'tipo': organism.type.toString().split('.').last,
          'cultura_id': organism.cropId,
          'cultura_nome': organism.cropName,
          'unidade': organism.unit,
          'limite_baixo': organism.lowLimit,
          'limite_medio': organism.mediumLimit,
          'limite_alto': organism.highLimit,
          'peso_risco': _calculateRiskWeight(organism),
          'criticidade': _calculateCriticality(organism),
        });
      }

      Logger.info('✅ ${criticalOrganisms.length} organismos críticos obtidos');
      return criticalOrganisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos críticos: $e');
      return [];
    }
  }

  /// Obtém estatísticas do catálogo
  Future<Map<String, dynamic>> getCatalogStats() async {
    try {
      Logger.info('🔍 Obtendo estatísticas do catálogo');
      
      final organisms = await _repository.getAll();
      final activeOrganisms = organisms.where((o) => o.isActive).toList();
      
      // Contar por tipo
      final pests = activeOrganisms.where((o) => o.type == OccurrenceType.pest).length;
      final diseases = activeOrganisms.where((o) => o.type == OccurrenceType.disease).length;
      final weeds = activeOrganisms.where((o) => o.type == OccurrenceType.weed).length;
      
      // Contar por cultura
      final crops = activeOrganisms.map((o) => o.cropId).toSet().length;
      
      // Calcular thresholds médios
      double avgLowLimit = 0.0;
      double avgMediumLimit = 0.0;
      double avgHighLimit = 0.0;
      
      if (activeOrganisms.isNotEmpty) {
        for (final organism in activeOrganisms) {
          avgLowLimit += organism.lowLimit;
          avgMediumLimit += organism.mediumLimit;
          avgHighLimit += organism.highLimit;
        }
        
        avgLowLimit /= activeOrganisms.length;
        avgMediumLimit /= activeOrganisms.length;
        avgHighLimit /= activeOrganisms.length;
      }

      final stats = {
        'total_organismos': organisms.length,
        'organismos_ativos': activeOrganisms.length,
        'pragas': pests,
        'doencas': diseases,
        'plantas_daninhas': weeds,
        'culturas_cobertas': crops,
        'threshold_medio_baixo': avgLowLimit,
        'threshold_medio_medio': avgMediumLimit,
        'threshold_medio_alto': avgHighLimit,
        'data_atualizacao': DateTime.now().toIso8601String(),
      };

      Logger.info('✅ Estatísticas do catálogo obtidas');
      return stats;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas do catálogo: $e');
      return {};
    }
  }

  // ===== MÉTODOS PRIVADOS =====

  /// Calcula o peso de risco de um organismo
  double _calculateRiskWeight(OrganismCatalog organism) {
    // Base: tipo do organismo
    double baseWeight = 1.0;
    switch (organism.type) {
      case OccurrenceType.pest:
        baseWeight = 1.2; // Pragas são mais críticas
        break;
      case OccurrenceType.disease:
        baseWeight = 1.5; // Doenças são mais críticas
        break;
      case OccurrenceType.weed:
        baseWeight = 1.0; // Plantas daninhas
        break;
      default:
        baseWeight = 1.0;
    }

    // Multiplicador baseado nos thresholds
    // Thresholds mais baixos = maior risco
    final thresholdMultiplier = 100.0 / (organism.lowLimit + 1);
    
    // Multiplicador baseado na cultura (algumas são mais sensíveis)
    final cropMultiplier = _getCropSensitivityMultiplier(organism.cropId);
    
    return baseWeight * thresholdMultiplier * cropMultiplier;
  }

  /// Obtém multiplicador de sensibilidade da cultura
  double _getCropSensitivityMultiplier(String cropId) {
    // Culturas mais sensíveis têm multiplicador maior
    switch (cropId.toLowerCase()) {
      case 'soja':
        return 1.3;
      case 'milho':
        return 1.2;
      case 'algodao':
        return 1.4;
      case 'cafe':
        return 1.5;
      case 'cana':
        return 1.1;
      default:
        return 1.0;
    }
  }

  /// Obtém severidade padrão do organismo
  String _getDefaultSeverity(OrganismCatalog organism) {
    if (organism.lowLimit <= 5) return 'ALTA';
    if (organism.lowLimit <= 15) return 'MEDIA';
    return 'BAIXA';
  }

  /// Obtém categoria de risco do organismo
  String _getRiskCategory(OrganismCatalog organism) {
    final riskWeight = _calculateRiskWeight(organism);
    if (riskWeight > 5.0) return 'CRITICO';
    if (riskWeight > 3.0) return 'ALTO';
    if (riskWeight > 1.5) return 'MEDIO';
    return 'BAIXO';
  }

  /// Converte AlertLevel para string
  String _convertAlertLevelToString(AlertLevel level) {
    switch (level) {
      case AlertLevel.low:
        return 'BAIXO';
      case AlertLevel.medium:
        return 'MEDIO';
      case AlertLevel.high:
        return 'ALTO';
      case AlertLevel.critical:
        return 'CRITICO';
      default:
        return 'DESCONHECIDO';
    }
  }

  /// Calcula criticidade do organismo
  double _calculateCriticality(OrganismCatalog organism) {
    // Criticidade baseada na relação entre thresholds
    if (organism.lowLimit == 0) return 1.0;
    
    final ratio = organism.mediumLimit / organism.lowLimit;
    return (1.0 / ratio).clamp(0.0, 1.0);
  }
}
