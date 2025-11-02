import '../../../services/organism_data_integration_service.dart';
import '../../../services/organism_data_service.dart';
import '../models/enhanced_ai_organism_data.dart';
import '../models/ai_organism_data.dart';
import '../../../utils/logger.dart';

/// Serviço de Integração - IA FortSmart com Novo Sistema de Dados
/// 
/// Este serviço integra os módulos de IA com o novo OrganismDataService,
/// garantindo que a IA FortSmart receba dados consistentes e atualizados.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class AIOrganismDataIntegrationService {
  static final AIOrganismDataIntegrationService _instance = AIOrganismDataIntegrationService._internal();
  factory AIOrganismDataIntegrationService() => _instance;
  AIOrganismDataIntegrationService._internal();

  final OrganismDataIntegrationService _integrationService = OrganismDataIntegrationService();
  final OrganismDataService _organismDataService = OrganismDataService();
  
  bool _isInitialized = false;

  /// Inicializa o serviço de integração da IA
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('🤖 Inicializando AIOrganismDataIntegrationService...');
    
    try {
      // Inicializar serviço de integração principal
      await _integrationService.initialize();
      
      _isInitialized = true;
      Logger.info('✅ AIOrganismDataIntegrationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar AIOrganismDataIntegrationService: $e');
      rethrow;
    }
  }

  /// Obtém todos os organismos para IA (formato legado)
  Future<List<AIOrganismData>> getAllOrganismsForAI() async {
    await _ensureInitialized();
    
    try {
      final organisms = await _integrationService.getAllOrganisms();
      return organisms.map((org) => _convertToLegacyAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos para IA: $e');
      return [];
    }
  }

  /// Obtém organismos expandidos para IA (formato novo)
  Future<List<EnhancedAIOrganismData>> getAllEnhancedOrganismsForAI() async {
    await _ensureInitialized();
    
    try {
      final cultures = _organismDataService.getAllCultures();
      final enhancedOrganisms = <EnhancedAIOrganismData>[];
      
      for (final culture in cultures) {
        for (final organism in culture.organisms) {
          final enhanced = _convertToEnhancedAIFormat(organism);
          enhancedOrganisms.add(enhanced);
        }
      }
      
      Logger.info('✅ Convertidos ${enhancedOrganisms.length} organismos para formato expandido da IA');
      return enhancedOrganisms;
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos expandidos para IA: $e');
      return [];
    }
  }

  /// Obtém organismos por cultura para IA
  Future<List<AIOrganismData>> getOrganismsByCropForAI(String cropName) async {
    await _ensureInitialized();
    
    try {
      final organisms = await _integrationService.getOrganismsByCulture(cropName);
      return organisms.map((org) => _convertToLegacyAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por cultura para IA: $e');
      return [];
    }
  }

  /// Obtém organismos expandidos por cultura para IA
  Future<List<EnhancedAIOrganismData>> getEnhancedOrganismsByCropForAI(String cropName) async {
    await _ensureInitialized();
    
    try {
      final culture = _organismDataService.getCultureByName(cropName);
      if (culture == null) return [];
      
      return culture.organisms.map((org) => _convertToEnhancedAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos expandidos por cultura para IA: $e');
      return [];
    }
  }

  /// Busca organismos para IA
  Future<List<AIOrganismData>> searchOrganismsForAI(String query) async {
    await _ensureInitialized();
    
    try {
      final organisms = await _integrationService.searchOrganisms(query);
      return organisms.map((org) => _convertToLegacyAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismos para IA: $e');
      return [];
    }
  }

  /// Busca organismos expandidos para IA
  Future<List<EnhancedAIOrganismData>> searchEnhancedOrganismsForAI(String query) async {
    await _ensureInitialized();
    
    try {
      final organisms = _organismDataService.searchOrganisms(query);
      return organisms.map((org) => _convertToEnhancedAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar organismos expandidos para IA: $e');
      return [];
    }
  }

  /// Obtém organismo específico para IA
  Future<AIOrganismData?> getOrganismForAI(String organismId) async {
    await _ensureInitialized();
    
    try {
      final organism = await _integrationService.getDetailedOrganism(organismId);
      if (organism == null) return null;
      
      return _convertToLegacyAIFormat(await _integrationService.getAllOrganisms().then((list) => 
        list.firstWhere((org) => org.id == organismId)));
    } catch (e) {
      Logger.error('❌ Erro ao obter organismo para IA: $e');
      return null;
    }
  }

  /// Obtém organismo expandido específico para IA
  Future<EnhancedAIOrganismData?> getEnhancedOrganismForAI(String organismId) async {
    await _ensureInitialized();
    
    try {
      final organism = _organismDataService.getOrganismById(organismId);
      if (organism == null) return null;
      
      return _convertToEnhancedAIFormat(organism);
    } catch (e) {
      Logger.error('❌ Erro ao obter organismo expandido para IA: $e');
      return null;
    }
  }

  /// Obtém organismos por categoria para IA
  Future<List<AIOrganismData>> getOrganismsByCategoryForAI(String category) async {
    await _ensureInitialized();
    
    try {
      final organisms = await _integrationService.getOrganismsByCategory(category);
      return organisms.map((org) => _convertToLegacyAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por categoria para IA: $e');
      return [];
    }
  }

  /// Obtém organismos por fase fenológica para IA
  Future<List<AIOrganismData>> getOrganismsByPhenologyForAI(String cultureId, String phenologyPhase) async {
    await _ensureInitialized();
    
    try {
      final organisms = await _integrationService.getOrganismsByPhenology(cultureId, phenologyPhase);
      return organisms.map((org) => _convertToLegacyAIFormat(org)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao obter organismos por fenologia para IA: $e');
      return [];
    }
  }

  /// Obtém estatísticas para IA
  Future<Map<String, dynamic>> getAIStatistics() async {
    await _ensureInitialized();
    
    try {
      final stats = await _integrationService.getDataStatistics();
      
      // Adicionar estatísticas específicas da IA
      final aiStats = Map<String, dynamic>.from(stats);
      aiStats['ai_specific'] = {
        'total_organisms_for_ai': stats['total_organisms'],
        'active_organisms_for_ai': stats['active_organisms'],
        'cultures_with_ai_data': stats['total_cultures'],
        'data_quality_score': _calculateDataQualityScore(stats),
        'ai_readiness': _calculateAIReadiness(stats),
      };
      
      return aiStats;
    } catch (e) {
      Logger.error('❌ Erro ao obter estatísticas para IA: $e');
      return {};
    }
  }

  /// Valida dados para IA
  Future<List<String>> validateDataForAI() async {
    await _ensureInitialized();
    
    try {
      final issues = await _integrationService.validateData();
      
      // Adicionar validações específicas da IA
      final aiIssues = List<String>.from(issues);
      
      // Verificar se organismos têm dados suficientes para IA
      final cultures = _organismDataService.getAllCultures();
      for (final culture in cultures) {
        for (final organism in culture.organisms) {
          if (organism.symptoms.isEmpty) {
            aiIssues.add('Organismo ${organism.name} sem sintomas para IA');
          }
          if (organism.chemicalManagement.isEmpty && 
              organism.biologicalManagement.isEmpty && 
              organism.culturalManagement.isEmpty) {
            aiIssues.add('Organismo ${organism.name} sem estratégias de manejo para IA');
          }
          if (organism.actionThreshold.isEmpty) {
            aiIssues.add('Organismo ${organism.name} sem limiar de ação para IA');
          }
        }
      }
      
      return aiIssues;
    } catch (e) {
      Logger.error('❌ Erro ao validar dados para IA: $e');
      return ['Erro na validação de dados para IA: $e'];
    }
  }

  /// Converte OrganismCatalog para formato legado da IA
  AIOrganismData _convertToLegacyAIFormat(dynamic organism) {
    return AIOrganismData(
      id: organism.id.hashCode,
      name: organism.name,
      scientificName: organism.scientificName,
      type: _convertType(organism.type),
      crops: [organism.cropName],
      symptoms: _extractSymptoms(organism),
      managementStrategies: _extractManagementStrategies(organism),
      description: organism.description ?? '',
      imageUrl: organism.imageUrl ?? '',
      severity: _calculateSeverity(organism),
      keywords: _extractKeywords(organism),
      createdAt: organism.createdAt ?? DateTime.now(),
      updatedAt: organism.updatedAt ?? DateTime.now(),
    );
  }

  /// Converte OrganismData para formato expandido da IA
  EnhancedAIOrganismData _convertToEnhancedAIFormat(OrganismData organism) {
    return EnhancedAIOrganismData(
      id: organism.id.hashCode,
      name: organism.name,
      scientificName: organism.scientificName,
      type: _convertType(organism.category),
      crops: [organism.cultureName],
      symptoms: organism.symptoms,
      managementStrategies: _combineManagementStrategies(organism),
      description: organism.economicDamage,
      imageUrl: '',
      characteristics: _buildCharacteristics(organism),
      severity: _calculateEnhancedSeverity(organism),
      keywords: _extractEnhancedKeywords(organism),
      createdAt: organism.createdAt,
      updatedAt: organism.updatedAt,
      fases: _parseFases(organism.lifeStages),
      severidadeDetalhada: _parseSeveridadeDetalhada(organism.severityLevels),
      condicoesFavoraveis: _parseCondicoesFavoraveis(organism.favorableConditions),
      limiaresAcao: LimiaresAcao(
        baixo: _extractThreshold(organism.actionThreshold, 'baixo'),
        medio: _extractThreshold(organism.actionThreshold, 'medio'),
        alto: _extractThreshold(organism.actionThreshold, 'alto'),
        unidade: _getDefaultUnit(organism.category),
      ),
      danoEconomico: DanoEconomico(
        descricao: organism.economicDamage,
        perdaMaxima: _extractMaxLoss(organism.economicDamage),
      ),
      fenologia: organism.phenology,
      partesAfetadas: organism.affectedParts,
      manejoIntegrado: ManejoIntegrado(
        quimico: organism.chemicalManagement,
        biologico: organism.biologicalManagement,
        cultural: organism.culturalManagement,
      ),
      codigosResistencia: _parseCodigosResistencia(organism.resistanceCodes),
      periodoCarencia: organism.safetyPeriod,
      eficaciaPorFase: _parseEficaciaPorFase(organism.efficacyByPhase),
      metodoMonitoramento: organism.monitoringMethod,
      observacoes: organism.observations,
      categoria: organism.category,
      culturaId: organism.cultureId,
      ativo: organism.active,
    );
  }

  /// Converte tipo de organismo
  String _convertType(String? type) {
    if (type == null) return 'other';
    final t = type.toLowerCase();
    if (t.contains('praga') || t == 'pest') return 'pest';
    if (t.contains('doença') || t.contains('doenca') || t == 'disease') return 'disease';
    if (t.contains('deficiência') || t.contains('deficiencia') || t == 'deficiency') return 'deficiency';
    return 'other';
  }

  /// Extrai sintomas
  List<String> _extractSymptoms(dynamic organism) {
    if (organism.symptoms != null) {
      return List<String>.from(organism.symptoms);
    }
    return [];
  }

  /// Extrai estratégias de manejo
  List<String> _extractManagementStrategies(dynamic organism) {
    final strategies = <String>[];
    
    if (organism.chemicalManagement != null) {
      strategies.addAll(List<String>.from(organism.chemicalManagement));
    }
    if (organism.biologicalManagement != null) {
      strategies.addAll(List<String>.from(organism.biologicalManagement));
    }
    if (organism.culturalManagement != null) {
      strategies.addAll(List<String>.from(organism.culturalManagement));
    }
    
    return strategies;
  }

  /// Combina estratégias de manejo
  List<String> _combineManagementStrategies(OrganismData organism) {
    final strategies = <String>[];
    strategies.addAll(organism.chemicalManagement);
    strategies.addAll(organism.biologicalManagement);
    strategies.addAll(organism.culturalManagement);
    return strategies;
  }

  /// Calcula severidade
  double _calculateSeverity(dynamic organism) {
    // Implementar lógica de cálculo de severidade
    return 0.5; // Valor padrão
  }

  /// Calcula severidade expandida
  double _calculateEnhancedSeverity(OrganismData organism) {
    if (organism.severityLevels != null) {
      // Implementar lógica baseada nos níveis de severidade
      return 0.7; // Valor padrão
    }
    return 0.5;
  }

  /// Extrai palavras-chave
  List<String> _extractKeywords(dynamic organism) {
    final keywords = <String>[];
    keywords.add(organism.name.toLowerCase());
    keywords.add(organism.scientificName.toLowerCase());
    if (organism.cropName != null) {
      keywords.add(organism.cropName.toLowerCase());
    }
    return keywords;
  }

  /// Extrai palavras-chave expandidas
  List<String> _extractEnhancedKeywords(OrganismData organism) {
    final keywords = <String>[];
    keywords.add(organism.name.toLowerCase());
    keywords.add(organism.scientificName.toLowerCase());
    keywords.add(organism.cultureName.toLowerCase());
    keywords.addAll(organism.symptoms.map((s) => s.toLowerCase()));
    keywords.addAll(organism.affectedParts.map((p) => p.toLowerCase()));
    return keywords;
  }

  /// Constrói características
  Map<String, dynamic> _buildCharacteristics(OrganismData organism) {
    return {
      'categoria': organism.category,
      'cultura': organism.cultureName,
      'fenologia': organism.phenology,
      'partes_afetadas': organism.affectedParts,
      'nivel_acao': organism.actionThreshold,
    };
  }

  /// Calcula score de qualidade dos dados
  double _calculateDataQualityScore(Map<String, dynamic> stats) {
    final totalOrganisms = stats['total_organisms'] as int;
    final activeOrganisms = stats['active_organisms'] as int;
    
    if (totalOrganisms == 0) return 0.0;
    
    final activeRatio = activeOrganisms / totalOrganisms;
    return activeRatio * 100;
  }

  /// Calcula prontidão para IA
  double _calculateAIReadiness(Map<String, dynamic> stats) {
    final totalOrganisms = stats['total_organisms'] as int;
    final activeOrganisms = stats['active_organisms'] as int;
    
    if (totalOrganisms == 0) return 0.0;
    
    // Implementar lógica mais sofisticada
    return (activeOrganisms / totalOrganisms) * 100;
  }

  /// Extrai limiar específico
  double _extractThreshold(String? thresholdText, String level) {
    if (thresholdText == null || thresholdText.isEmpty) return 0.0;
    
    // Implementar lógica para extrair limiares específicos
    switch (level) {
      case 'baixo': return 1.0;
      case 'medio': return 3.0;
      case 'alto': return 5.0;
      default: return 0.0;
    }
  }

  /// Obtém unidade padrão
  String _getDefaultUnit(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'unidades/ponto';
    if (cat.contains('doença') || cat.contains('doenca')) return '% de incidência';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return '% de severidade';
    return 'unidades';
  }

  /// Extrai perda máxima
  double _extractMaxLoss(String? damageText) {
    if (damageText == null || damageText.isEmpty) return 0.0;
    
    // Implementar lógica para extrair perda máxima
    return 50.0; // Valor padrão
  }

  /// Garante que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Métodos auxiliares para parsing (implementação simplificada)
  List<Map<String, dynamic>> _parseFases(List<Map<String, dynamic>>? fases) {
    return fases ?? [];
  }

  Map<String, dynamic> _parseSeveridadeDetalhada(Map<String, dynamic>? severidade) {
    return severidade ?? {};
  }

  Map<String, dynamic> _parseCondicoesFavoraveis(Map<String, dynamic>? condicoes) {
    return condicoes ?? {};
  }

  Map<String, dynamic> _parseCodigosResistencia(Map<String, dynamic>? codigos) {
    return codigos ?? {};
  }

  Map<String, dynamic> _parseEficaciaPorFase(Map<String, dynamic>? eficacia) {
    return eficacia ?? {};
  }
}

/// Classes auxiliares para o formato expandido da IA
class LimiaresAcao {
  final double baixo;
  final double medio;
  final double alto;
  final String unidade;

  LimiaresAcao({
    required this.baixo,
    required this.medio,
    required this.alto,
    required this.unidade,
  });
}

class DanoEconomico {
  final String descricao;
  final double perdaMaxima;

  DanoEconomico({
    required this.descricao,
    required this.perdaMaxima,
  });
}

class ManejoIntegrado {
  final List<String> quimico;
  final List<String> biologico;
  final List<String> cultural;

  ManejoIntegrado({
    required this.quimico,
    required this.biologico,
    required this.cultural,
  });
}
