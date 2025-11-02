import '../../../services/organism_data_integration_service.dart';
import '../../../services/organism_data_service.dart';
import '../../../models/organism_catalog.dart';
import '../../../utils/logger.dart';

/// Serviço de Integração - Mapa de Infestação com Novo Sistema de Dados
/// 
/// Este serviço integra o módulo de infestation_map com o novo OrganismDataService,
/// garantindo que o mapa de infestação receba dados consistentes e atualizados.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class InfestationOrganismDataIntegrationService {
  static final InfestationOrganismDataIntegrationService _instance = InfestationOrganismDataIntegrationService._internal();
  factory InfestationOrganismDataIntegrationService() => _instance;
  InfestationOrganismDataIntegrationService._internal();

  final OrganismDataIntegrationService _integrationService = OrganismDataIntegrationService();
  final OrganismDataService _organismDataService = OrganismDataService();
  
  bool _isInitialized = false;

  /// Inicializa o serviço de integração do mapa de infestação
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('🗺️ Inicializando InfestationOrganismDataIntegrationService...');
    
    try {
      // Inicializar serviço de integração principal
      await _integrationService.initialize();
      
      _isInitialized = true;
      Logger.info('✅ InfestationOrganismDataIntegrationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar InfestationOrganismDataIntegrationService: $e');
      rethrow;
    }
  }

  /// Obtém pesos de risco para organismos (compatibilidade com sistema legado)
  Future<Map<String, double>> getRiskWeights() async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Obtendo pesos de risco dos organismos...');
      
      final organisms = await _integrationService.getAllOrganisms();
      final riskWeights = <String, double>{};

      for (final organism in organisms) {
        final riskWeight = _calculateRiskWeight(organism);
        riskWeights[organism.id] = riskWeight;
      }

      Logger.info('✅ Pesos de risco obtidos para ${riskWeights.length} organismos');
      return riskWeights;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter pesos de risco: $e');
      return {};
    }
  }

  /// Obtém organismos validados para uso no mapa de infestação
  Future<List<OrganismCatalog>> getValidatedOrganisms() async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Obtendo organismos validados para mapa de infestação...');
      
      final organisms = await _integrationService.getAllOrganisms();
      
      Logger.info('✅ ${organisms.length} organismos validados obtidos');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos validados: $e');
      return [];
    }
  }

  /// Obtém organismos por cultura validados
  Future<List<OrganismCatalog>> getValidatedOrganismsByCrop(String cropId) async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Obtendo organismos validados para cultura: $cropId');
      
      final organisms = await _integrationService.getOrganismsByCulture(cropId);
      
      Logger.info('✅ ${organisms.length} organismos validados para cultura $cropId');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por cultura: $e');
      return [];
    }
  }

  /// Obtém thresholds para um organismo específico
  Future<Map<String, dynamic>?> getOrganismThresholds(String organismId) async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Obtendo thresholds do organismo: $organismId');
      
      final organism = await _integrationService.getDetailedOrganism(organismId);
      if (organism == null) {
        Logger.warning('⚠️ Organismo não encontrado: $organismId');
        return null;
      }

      final thresholds = {
        'id': organism.id,
        'nome': organism.name,
        'tipo': _getOrganismType(organism.category),
        'cultura_id': organism.cultureId,
        'cultura_nome': organism.cultureName,
        'unidade': _getDefaultUnit(organism.category),
        'limiar_baixo': _extractThreshold(organism.actionThreshold, 'baixo'),
        'limiar_medio': _extractThreshold(organism.actionThreshold, 'medio'),
        'limiar_alto': _extractThreshold(organism.actionThreshold, 'alto'),
        'limiar_critico': _extractThreshold(organism.actionThreshold, 'critico'),
        'peso_risco': _calculateRiskWeight(organism),
        'descricao': organism.economicDamage,
        'ativo': organism.active,
        'version': '4.0',
        'created_at': organism.createdAt.toIso8601String(),
        'updated_at': organism.updatedAt.toIso8601String(),
      };

      Logger.info('✅ Thresholds obtidos para organismo $organismId');
      return thresholds;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter thresholds do organismo $organismId: $e');
      return null;
    }
  }

  /// Obtém organismos por fase fenológica
  Future<List<OrganismCatalog>> getOrganismsByPhenology(String cultureId, String phenologyPhase) async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Obtendo organismos por fenologia: $cultureId - $phenologyPhase');
      
      final organisms = await _integrationService.getOrganismsByPhenology(cultureId, phenologyPhase);
      
      Logger.info('✅ ${organisms.length} organismos encontrados para fase $phenologyPhase');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por fenologia: $e');
      return [];
    }
  }

  /// Obtém organismos por categoria
  Future<List<OrganismCatalog>> getOrganismsByCategory(String category) async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Obtendo organismos por categoria: $category');
      
      final organisms = await _integrationService.getOrganismsByCategory(category);
      
      Logger.info('✅ ${organisms.length} organismos encontrados para categoria $category');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por categoria: $e');
      return [];
    }
  }

  /// Busca organismos
  Future<List<OrganismCatalog>> searchOrganisms(String query) async {
    await _ensureInitialized();
    
    try {
      Logger.info('🔍 Buscando organismos: $query');
      
      final organisms = await _integrationService.searchOrganisms(query);
      
      Logger.info('✅ ${organisms.length} organismos encontrados para busca: $query');
      return organisms;
      
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismos: $e');
      return [];
    }
  }

  /// Obtém estatísticas para mapa de infestação
  Future<Map<String, dynamic>> getInfestationStatistics() async {
    await _ensureInitialized();
    
    try {
      final stats = await _integrationService.getDataStatistics();
      
      // Adicionar estatísticas específicas do mapa de infestação
      final infestationStats = Map<String, dynamic>.from(stats);
      infestationStats['infestation_specific'] = {
        'total_organisms_for_infestation': stats['total_organisms'],
        'active_organisms_for_infestation': stats['active_organisms'],
        'cultures_with_infestation_data': stats['total_cultures'],
        'data_quality_for_infestation': _calculateInfestationDataQuality(stats),
        'infestation_readiness': _calculateInfestationReadiness(stats),
      };
      
      return infestationStats;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas para infestação: $e');
      return {};
    }
  }

  /// Valida dados para mapa de infestação
  Future<List<String>> validateDataForInfestation() async {
    await _ensureInitialized();
    
    try {
      final issues = await _integrationService.validateData();
      
      // Adicionar validações específicas do mapa de infestação
      final infestationIssues = List<String>.from(issues);
      
      // Verificar se organismos têm dados suficientes para infestação
      final cultures = _organismDataService.getAllCultures();
      for (final culture in cultures) {
        for (final organism in culture.organisms) {
          if (organism.actionThreshold.isEmpty) {
            infestationIssues.add('Organismo ${organism.name} sem limiar de ação para infestação');
          }
          if (organism.severityLevels == null) {
            infestationIssues.add('Organismo ${organism.name} sem níveis de severidade para infestação');
          }
          if (organism.infestationLevels == null) {
            infestationIssues.add('Organismo ${organism.name} sem níveis de infestação');
          }
        }
      }
      
      return infestationIssues;
    } catch (e) {
      Logger.error('❌ Erro ao validar dados para infestação: $e');
      return ['Erro na validação de dados para infestação: $e'];
    }
  }

  /// Calcula peso de risco para um organismo
  double _calculateRiskWeight(dynamic organism) {
    try {
      double baseWeight = 0.5; // Peso base
      
      // Ajustar peso baseado no tipo
      if (organism.type != null) {
        switch (organism.type.toLowerCase()) {
          case 'pest':
          case 'praga':
            baseWeight = 0.8;
            break;
          case 'disease':
          case 'doença':
          case 'doenca':
            baseWeight = 0.7;
            break;
          case 'deficiency':
          case 'deficiência':
          case 'deficiencia':
            baseWeight = 0.4;
            break;
          default:
            baseWeight = 0.5;
        }
      }
      
      // Ajustar peso baseado nos limiares
      if (organism.lowLimit != null && organism.mediumLimit != null && organism.highLimit != null) {
        final lowLimit = organism.lowLimit as double;
        final mediumLimit = organism.mediumLimit as double;
        final highLimit = organism.highLimit as double;
        
        // Organismos com limiares mais baixos são mais críticos
        if (lowLimit < 1.0) {
          baseWeight += 0.2;
        } else if (lowLimit < 3.0) {
          baseWeight += 0.1;
        }
        
        // Verificar se há progressão adequada nos limiares
        if (mediumLimit > lowLimit && highLimit > mediumLimit) {
          baseWeight += 0.1;
        }
      }
      
      // Ajustar peso baseado na severidade
      if (organism.severity != null) {
        final severity = organism.severity as double;
        baseWeight += (severity * 0.2);
      }
      
      // Limitar peso entre 0.1 e 1.0
      return baseWeight.clamp(0.1, 1.0);
      
    } catch (e) {
      Logger.warning('⚠️ Erro ao calcular peso de risco: $e');
      return 0.5; // Peso padrão em caso de erro
    }
  }

  /// Determina tipo de organismo
  String _getOrganismType(String? category) {
    if (category == null) return 'other';
    
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'pest';
    if (cat.contains('doença') || cat.contains('doenca')) return 'disease';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return 'deficiency';
    return 'other';
  }

  /// Obtém unidade padrão para categoria
  String _getDefaultUnit(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'unidades/ponto';
    if (cat.contains('doença') || cat.contains('doenca')) return '% de incidência';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return '% de severidade';
    return 'unidades';
  }

  /// Extrai limiar específico do texto
  double _extractThreshold(String? thresholdText, String level) {
    if (thresholdText == null || thresholdText.isEmpty) return 0.0;
    
    // Implementar lógica para extrair limiares específicos
    // Por enquanto, retorna valores padrão baseados no nível
    switch (level) {
      case 'baixo': return 1.0;
      case 'medio': return 3.0;
      case 'alto': return 5.0;
      case 'critico': return 10.0;
      default: return 0.0;
    }
  }

  /// Calcula qualidade dos dados para infestação
  double _calculateInfestationDataQuality(Map<String, dynamic> stats) {
    final totalOrganisms = stats['total_organisms'] as int;
    final activeOrganisms = stats['active_organisms'] as int;
    
    if (totalOrganisms == 0) return 0.0;
    
    final activeRatio = activeOrganisms / totalOrganisms;
    return activeRatio * 100;
  }

  /// Calcula prontidão para infestação
  double _calculateInfestationReadiness(Map<String, dynamic> stats) {
    final totalOrganisms = stats['total_organisms'] as int;
    final activeOrganisms = stats['active_organisms'] as int;
    
    if (totalOrganisms == 0) return 0.0;
    
    // Implementar lógica mais sofisticada
    return (activeOrganisms / totalOrganisms) * 100;
  }

  /// Garante que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Obtém informações de compatibilidade
  Map<String, dynamic> getCompatibilityInfo() {
    return {
      'is_initialized': _isInitialized,
      'new_system_available': true,
      'legacy_system_available': true,
      'infestation_ready': _isInitialized,
    };
  }

  /// Executa diagnóstico para infestação
  Future<Map<String, dynamic>> runInfestationDiagnostics() async {
    Logger.info('🔍 Executando diagnóstico para mapa de infestação...');
    
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'compatibility_info': getCompatibilityInfo(),
      'infestation_stats': null,
      'validation_results': null,
      'recommendations': <String>[],
    };
    
    try {
      // Estatísticas para infestação
      if (_isInitialized) {
        diagnostics['infestation_stats'] = await getInfestationStatistics();
        diagnostics['validation_results'] = await validateDataForInfestation();
      }
      
      // Recomendações
      final recommendations = <String>[];
      
      if (!_isInitialized) {
        recommendations.add('Inicializar o serviço de integração para infestação');
      }
      
      if (diagnostics['validation_results'] != null) {
        final validationResults = diagnostics['validation_results'] as List<String>;
        if (validationResults.isNotEmpty) {
          recommendations.add('Corrigir problemas de validação para infestação: ${validationResults.length} issues');
        }
      }
      
      diagnostics['recommendations'] = recommendations;
      
      Logger.info('✅ Diagnóstico para infestação concluído');
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico para infestação: $e');
      diagnostics['error'] = e.toString();
    }
    
    return diagnostics;
  }
}
