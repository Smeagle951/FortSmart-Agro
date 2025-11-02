import '../models/enhanced_ai_organism_data.dart';
import '../services/ai_catalog_migration_service.dart';
import '../../../utils/logger.dart';

/// Repositório expandido para organismos da IA com dados ricos do catálogo
class EnhancedAIOrganismRepository {
  final AICatalogMigrationService _migrationService = AICatalogMigrationService();
  List<EnhancedAIOrganismData> _cachedOrganisms = [];
  bool _isCacheLoaded = false;

  /// Inicializa o repositório carregando dados do catálogo
  Future<void> initialize() async {
    if (!_isCacheLoaded) {
      try {
        Logger.info('🔄 Inicializando repositório expandido de organismos...');
        _cachedOrganisms = await _migrationService.migrateAllOrganisms();
        _isCacheLoaded = true;
        Logger.info('✅ Repositório inicializado: ${_cachedOrganisms.length} organismos carregados');
      } catch (e) {
        Logger.error('❌ Erro ao inicializar repositório: $e');
      }
    }
  }

  /// Obtém todos os organismos
  Future<List<EnhancedAIOrganismData>> getAllOrganisms() async {
    await initialize();
    return List.from(_cachedOrganisms);
  }

  /// Obtém organismos por cultura
  Future<List<EnhancedAIOrganismData>> getOrganismsByCrop(String cropName) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase())).toList();
  }

  /// Obtém organismos por tipo
  Future<List<EnhancedAIOrganismData>> getOrganismsByType(String type) async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.type == type).toList();
  }

  /// Obtém organismos por categoria
  Future<List<EnhancedAIOrganismData>> getOrganismsByCategory(String category) async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.categoria == category).toList();
  }

  /// Obtém organismo por ID
  Future<EnhancedAIOrganismData?> getOrganismById(int id) async {
    await initialize();
    try {
      return _cachedOrganisms.firstWhere((organism) => organism.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtém organismo por nome
  Future<EnhancedAIOrganismData?> getOrganismByName(String name) async {
    await initialize();
    try {
      return _cachedOrganisms.firstWhere((organism) => 
          organism.name.toLowerCase().contains(name.toLowerCase()));
    } catch (e) {
      return null;
    }
  }

  /// Busca organismos por critérios
  Future<List<EnhancedAIOrganismData>> searchOrganisms({
    String? query,
    String? cropName,
    String? type,
    String? category,
    bool? hasPhaseData,
    bool? hasSeverityData,
    bool? hasEconomicData,
  }) async {
    await initialize();
    
    return _cachedOrganisms.where((organism) {
      // Filtro por query
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        if (!organism.name.toLowerCase().contains(searchQuery) &&
            !organism.scientificName.toLowerCase().contains(searchQuery) &&
            !organism.crops.any((crop) => crop.toLowerCase().contains(searchQuery)) &&
            !organism.symptoms.any((symptom) => symptom.toLowerCase().contains(searchQuery)) &&
            !organism.keywords.any((keyword) => keyword.toLowerCase().contains(searchQuery))) {
          return false;
        }
      }
      
      // Filtro por cultura
      if (cropName != null && !organism.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase())) {
        return false;
      }
      
      // Filtro por tipo
      if (type != null && organism.type != type) {
        return false;
      }
      
      // Filtro por categoria
      if (category != null && organism.categoria != category) {
        return false;
      }
      
      // Filtro por dados de fase
      if (hasPhaseData != null && hasPhaseData != organism.fases.isNotEmpty) {
        return false;
      }
      
      // Filtro por dados de severidade
      if (hasSeverityData != null && hasSeverityData != organism.severidadeDetalhada.isNotEmpty) {
        return false;
      }
      
      // Filtro por dados econômicos
      if (hasEconomicData != null && hasEconomicData != organism.danoEconomico.descricao.isNotEmpty) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Obtém organismos com dados de fase
  Future<List<EnhancedAIOrganismData>> getOrganismsWithPhaseData() async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.fases.isNotEmpty).toList();
  }

  /// Obtém organismos com dados de severidade
  Future<List<EnhancedAIOrganismData>> getOrganismsWithSeverityData() async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.severidadeDetalhada.isNotEmpty).toList();
  }

  /// Obtém organismos com dados econômicos
  Future<List<EnhancedAIOrganismData>> getOrganismsWithEconomicData() async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.danoEconomico.descricao.isNotEmpty).toList();
  }

  /// Obtém organismos por fenologia
  Future<List<EnhancedAIOrganismData>> getOrganismsByPhenology(String phenology) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.fenologia.any((p) => p.toLowerCase().contains(phenology.toLowerCase()))).toList();
  }

  /// Obtém organismos por partes afetadas
  Future<List<EnhancedAIOrganismData>> getOrganismsByAffectedParts(List<String> parts) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        parts.any((part) => organism.partesAfetadas.any((ap) => 
            ap.toLowerCase().contains(part.toLowerCase())))).toList();
  }

  /// Obtém organismos por condições favoráveis
  Future<List<EnhancedAIOrganismData>> getOrganismsByFavorableConditions({
    double? temperature,
    double? humidity,
  }) async {
    await initialize();
    
    if (temperature == null && humidity == null) {
      return _cachedOrganisms;
    }
    
    return _cachedOrganisms.where((organism) {
      if (temperature != null && !organism.condicoesFavoraveis.isFavorable(temperature, humidity ?? 50)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Obtém organismos por severidade
  Future<List<EnhancedAIOrganismData>> getOrganismsBySeverity(String severity) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.severidadeDetalhada.containsKey(severity)).toList();
  }

  /// Obtém organismos por limiar de ação
  Future<List<EnhancedAIOrganismData>> getOrganismsByActionThreshold({
    int? organismCount,
    String? severity,
  }) async {
    await initialize();
    
    return _cachedOrganisms.where((organism) {
      if (organismCount != null) {
        if (organismCount <= organism.limiaresAcao.baixo) {
          return severity == null || severity == 'baixo';
        } else if (organismCount <= organism.limiaresAcao.medio) {
          return severity == null || severity == 'medio';
        } else if (organismCount <= organism.limiaresAcao.alto) {
          return severity == null || severity == 'alto';
        } else {
          return severity == null || severity == 'critico';
        }
      }
      return true;
    }).toList();
  }

  /// Obtém organismos por manejo
  Future<List<EnhancedAIOrganismData>> getOrganismsByManagement({
    String? managementType, // 'quimico', 'biologico', 'cultural'
    String? specificManagement,
  }) async {
    await initialize();
    
    return _cachedOrganisms.where((organism) {
      if (managementType != null) {
        switch (managementType) {
          case 'quimico':
            if (organism.manejoIntegrado.quimico.isEmpty) return false;
            break;
          case 'biologico':
            if (organism.manejoIntegrado.biologico.isEmpty) return false;
            break;
          case 'cultural':
            if (organism.manejoIntegrado.cultural.isEmpty) return false;
            break;
        }
      }
      
      if (specificManagement != null) {
        final allManagement = [
          ...organism.manejoIntegrado.quimico,
          ...organism.manejoIntegrado.biologico,
          ...organism.manejoIntegrado.cultural,
        ];
        if (!allManagement.any((m) => m.toLowerCase().contains(specificManagement.toLowerCase()))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// Obtém organismos por dano econômico
  Future<List<EnhancedAIOrganismData>> getOrganismsByEconomicDamage({
    double? minLossPercentage,
    double? maxLossPercentage,
  }) async {
    await initialize();
    
    return _cachedOrganisms.where((organism) {
      if (organism.danoEconomico.descricao.isEmpty) return false;
      
      // Extrai porcentagem de perda máxima
      final regex = RegExp(r'(\d+(?:\.\d+)?)%');
      final match = regex.firstMatch(organism.danoEconomico.descricao);
      final lossPercentage = double.tryParse(match?.group(1) ?? '0') ?? 0.0;
      
      if (minLossPercentage != null && lossPercentage < minLossPercentage) {
        return false;
      }
      
      if (maxLossPercentage != null && lossPercentage > maxLossPercentage) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Obtém organismos ativos
  Future<List<EnhancedAIOrganismData>> getActiveOrganisms() async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.ativo).toList();
  }

  /// Obtém organismos por cultura e tipo
  Future<List<EnhancedAIOrganismData>> getOrganismsByCropAndType(String cropName, String type) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase()) &&
        organism.type == type).toList();
  }

  /// Obtém organismos por cultura e categoria
  Future<List<EnhancedAIOrganismData>> getOrganismsByCropAndCategory(String cropName, String category) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase()) &&
        organism.categoria == category).toList();
  }

  /// Obtém organismos por fase de desenvolvimento
  Future<List<EnhancedAIOrganismData>> getOrganismsByPhase(String phase) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.fases.any((f) => f.fase.toLowerCase().contains(phase.toLowerCase()))).toList();
  }

  /// Obtém organismos por tamanho
  Future<List<EnhancedAIOrganismData>> getOrganismsBySize(double sizeMM) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.fases.any((f) => f.isSizeInRange(sizeMM))).toList();
  }

  /// Obtém organismos por icone
  Future<List<EnhancedAIOrganismData>> getOrganismsByIcon(String icon) async {
    await initialize();
    return _cachedOrganisms.where((organism) => organism.icone == icon).toList();
  }

  /// Obtém organismos por observações
  Future<List<EnhancedAIOrganismData>> getOrganismsByObservations(String observation) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.observacoes.any((obs) => obs.toLowerCase().contains(observation.toLowerCase()))).toList();
  }

  /// Obtém organismos por nível de ação
  Future<List<EnhancedAIOrganismData>> getOrganismsByActionLevel(String actionLevel) async {
    await initialize();
    return _cachedOrganisms.where((organism) => 
        organism.nivelAcao.toLowerCase().contains(actionLevel.toLowerCase())).toList();
  }

  /// Obtém estatísticas detalhadas
  Future<Map<String, dynamic>> getDetailedStatistics() async {
    await initialize();
    
    final Map<String, int> organismsByType = {};
    final Map<String, int> organismsByCrop = {};
    final Map<String, int> organismsByCategory = {};
    final Map<String, int> organismsByIcon = {};
    final Map<String, int> organismsByPhase = {};
    final Map<String, int> organismsBySeverity = {};
    
    int organismsWithPhaseData = 0;
    int organismsWithSeverityData = 0;
    int organismsWithEconomicData = 0;
    int organismsWithManagementData = 0;
    int activeOrganisms = 0;
    
    for (var organism in _cachedOrganisms) {
      // Conta por tipo
      organismsByType[organism.type] = (organismsByType[organism.type] ?? 0) + 1;
      
      // Conta por cultura
      for (final crop in organism.crops) {
        organismsByCrop[crop] = (organismsByCrop[crop] ?? 0) + 1;
      }
      
      // Conta por categoria
      organismsByCategory[organism.categoria] = (organismsByCategory[organism.categoria] ?? 0) + 1;
      
      // Conta por icone
      organismsByIcon[organism.icone] = (organismsByIcon[organism.icone] ?? 0) + 1;
      
      // Conta por fase
      for (final fase in organism.fases) {
        organismsByPhase[fase.fase] = (organismsByPhase[fase.fase] ?? 0) + 1;
      }
      
      // Conta por severidade
      for (final severity in organism.severidadeDetalhada.keys) {
        organismsBySeverity[severity] = (organismsBySeverity[severity] ?? 0) + 1;
      }
      
      // Conta organismos com dados específicos
      if (organism.fases.isNotEmpty) organismsWithPhaseData++;
      if (organism.severidadeDetalhada.isNotEmpty) organismsWithSeverityData++;
      if (organism.danoEconomico.descricao.isNotEmpty) organismsWithEconomicData++;
      if (organism.manejoIntegrado.quimico.isNotEmpty || 
          organism.manejoIntegrado.biologico.isNotEmpty || 
          organism.manejoIntegrado.cultural.isNotEmpty) {
        organismsWithManagementData++;
      }
      if (organism.ativo) activeOrganisms++;
    }
    
    return {
      'totalOrganisms': _cachedOrganisms.length,
      'activeOrganisms': activeOrganisms,
      'byType': organismsByType,
      'byCrop': organismsByCrop,
      'byCategory': organismsByCategory,
      'byIcon': organismsByIcon,
      'byPhase': organismsByPhase,
      'bySeverity': organismsBySeverity,
      'culturesCount': organismsByCrop.length,
      'organismsWithPhaseData': organismsWithPhaseData,
      'organismsWithSeverityData': organismsWithSeverityData,
      'organismsWithEconomicData': organismsWithEconomicData,
      'organismsWithManagementData': organismsWithManagementData,
      'phaseDataPercentage': _cachedOrganisms.isNotEmpty ? 
          (organismsWithPhaseData / _cachedOrganisms.length * 100).toStringAsFixed(1) + '%' : '0%',
      'severityDataPercentage': _cachedOrganisms.isNotEmpty ? 
          (organismsWithSeverityData / _cachedOrganisms.length * 100).toStringAsFixed(1) + '%' : '0%',
      'economicDataPercentage': _cachedOrganisms.isNotEmpty ? 
          (organismsWithEconomicData / _cachedOrganisms.length * 100).toStringAsFixed(1) + '%' : '0%',
      'managementDataPercentage': _cachedOrganisms.isNotEmpty ? 
          (organismsWithManagementData / _cachedOrganisms.length * 100).toStringAsFixed(1) + '%' : '0%',
    };
  }

  /// Obtém organismos por critérios múltiplos
  Future<List<EnhancedAIOrganismData>> getOrganismsByMultipleCriteria({
    String? query,
    String? cropName,
    String? type,
    String? category,
    String? phenology,
    List<String>? affectedParts,
    double? temperature,
    double? humidity,
    String? severity,
    int? organismCount,
    String? managementType,
    String? specificManagement,
    double? minLossPercentage,
    double? maxLossPercentage,
    String? phase,
    double? sizeMM,
    String? icon,
    String? observation,
    String? actionLevel,
    bool? active,
    bool? hasPhaseData,
    bool? hasSeverityData,
    bool? hasEconomicData,
  }) async {
    await initialize();
    
    return _cachedOrganisms.where((organism) {
      // Aplica todos os filtros
      if (query != null && query.isNotEmpty) {
        final searchQuery = query.toLowerCase();
        if (!organism.name.toLowerCase().contains(searchQuery) &&
            !organism.scientificName.toLowerCase().contains(searchQuery) &&
            !organism.crops.any((crop) => crop.toLowerCase().contains(searchQuery)) &&
            !organism.symptoms.any((symptom) => symptom.toLowerCase().contains(searchQuery)) &&
            !organism.keywords.any((keyword) => keyword.toLowerCase().contains(searchQuery))) {
          return false;
        }
      }
      
      if (cropName != null && !organism.crops.any((crop) => crop.toLowerCase() == cropName.toLowerCase())) {
        return false;
      }
      
      if (type != null && organism.type != type) {
        return false;
      }
      
      if (category != null && organism.categoria != category) {
        return false;
      }
      
      if (phenology != null && !organism.fenologia.any((p) => p.toLowerCase().contains(phenology.toLowerCase()))) {
        return false;
      }
      
      if (affectedParts != null && !affectedParts.any((part) => organism.partesAfetadas.any((ap) => 
          ap.toLowerCase().contains(part.toLowerCase())))) {
        return false;
      }
      
      if (temperature != null && !organism.condicoesFavoraveis.isFavorable(temperature, humidity ?? 50)) {
        return false;
      }
      
      if (severity != null && !organism.severidadeDetalhada.containsKey(severity)) {
        return false;
      }
      
      if (organismCount != null) {
        if (organismCount <= organism.limiaresAcao.baixo) {
          if (severity != null && severity != 'baixo') return false;
        } else if (organismCount <= organism.limiaresAcao.medio) {
          if (severity != null && severity != 'medio') return false;
        } else if (organismCount <= organism.limiaresAcao.alto) {
          if (severity != null && severity != 'alto') return false;
        } else {
          if (severity != null && severity != 'critico') return false;
        }
      }
      
      if (managementType != null) {
        switch (managementType) {
          case 'quimico':
            if (organism.manejoIntegrado.quimico.isEmpty) return false;
            break;
          case 'biologico':
            if (organism.manejoIntegrado.biologico.isEmpty) return false;
            break;
          case 'cultural':
            if (organism.manejoIntegrado.cultural.isEmpty) return false;
            break;
        }
      }
      
      if (specificManagement != null) {
        final allManagement = [
          ...organism.manejoIntegrado.quimico,
          ...organism.manejoIntegrado.biologico,
          ...organism.manejoIntegrado.cultural,
        ];
        if (!allManagement.any((m) => m.toLowerCase().contains(specificManagement.toLowerCase()))) {
          return false;
        }
      }
      
      if (minLossPercentage != null || maxLossPercentage != null) {
        if (organism.danoEconomico.descricao.isEmpty) return false;
        
        final regex = RegExp(r'(\d+(?:\.\d+)?)%');
        final match = regex.firstMatch(organism.danoEconomico.descricao);
        final lossPercentage = double.tryParse(match?.group(1) ?? '0') ?? 0.0;
        
        if (minLossPercentage != null && lossPercentage < minLossPercentage) {
          return false;
        }
        
        if (maxLossPercentage != null && lossPercentage > maxLossPercentage) {
          return false;
        }
      }
      
      if (phase != null && !organism.fases.any((f) => f.fase.toLowerCase().contains(phase.toLowerCase()))) {
        return false;
      }
      
      if (sizeMM != null && !organism.fases.any((f) => f.isSizeInRange(sizeMM))) {
        return false;
      }
      
      if (icon != null && organism.icone != icon) {
        return false;
      }
      
      if (observation != null && !organism.observacoes.any((obs) => 
          obs.toLowerCase().contains(observation.toLowerCase()))) {
        return false;
      }
      
      if (actionLevel != null && !organism.nivelAcao.toLowerCase().contains(actionLevel.toLowerCase())) {
        return false;
      }
      
      if (active != null && organism.ativo != active) {
        return false;
      }
      
      if (hasPhaseData != null && hasPhaseData != organism.fases.isNotEmpty) {
        return false;
      }
      
      if (hasSeverityData != null && hasSeverityData != organism.severidadeDetalhada.isNotEmpty) {
        return false;
      }
      
      if (hasEconomicData != null && hasEconomicData != organism.danoEconomico.descricao.isNotEmpty) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Limpa cache
  void clearCache() {
    _cachedOrganisms.clear();
    _isCacheLoaded = false;
  }

  /// Recarrega dados
  Future<void> reload() async {
    clearCache();
    await initialize();
  }
}
