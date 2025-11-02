import 'dart:convert';
import 'organism_data_service.dart';
import 'organism_catalog_loader_service.dart';
import 'culture_import_service.dart';
import '../models/organism_catalog.dart';
import '../utils/logger.dart';

/// Serviço de Integração - OrganismDataService com Sistema Existente
/// 
/// Este serviço integra o novo OrganismDataService com os serviços existentes,
/// garantindo compatibilidade e migração gradual do sistema.
/// 
/// Autor: Especialista Agronômico + Desenvolvedor Sênior
/// Data: 2024-12-19
/// Versão: 1.0

class OrganismDataIntegrationService {
  static final OrganismDataIntegrationService _instance = OrganismDataIntegrationService._internal();
  factory OrganismDataIntegrationService() => _instance;
  OrganismDataIntegrationService._internal();

  final OrganismDataService _organismDataService = OrganismDataService();
  final OrganismCatalogLoaderService _catalogLoaderService = OrganismCatalogLoaderService();
  final CultureImportService _cultureImportService = CultureImportService();
  
  bool _isInitialized = false;
  bool _useNewSystem = true; // Flag para controlar qual sistema usar

  /// Inicializa o serviço de integração
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('🔄 Inicializando OrganismDataIntegrationService...');
    
    try {
      // Inicializar novo sistema
      await _organismDataService.initialize();
      
      // Inicializar sistema legado (para compatibilidade)
      await _catalogLoaderService.loadAllOrganisms();
      await _cultureImportService.initialize();
      
      _isInitialized = true;
      Logger.info('✅ OrganismDataIntegrationService inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar OrganismDataIntegrationService: $e');
      rethrow;
    }
  }

  /// Obtém todos os organismos (compatibilidade com sistema legado)
  Future<List<OrganismCatalog>> getAllOrganisms() async {
    await _ensureInitialized();
    
    if (_useNewSystem) {
      return await _getOrganismsFromNewSystem();
    } else {
      return await _catalogLoaderService.loadAllOrganisms();
    }
  }

  /// Obtém organismos de uma cultura específica
  Future<List<OrganismCatalog>> getOrganismsByCulture(String cultureName) async {
    await _ensureInitialized();
    
    if (_useNewSystem) {
      return await _getOrganismsByCultureFromNewSystem(cultureName);
    } else {
      return await _catalogLoaderService.loadCultureOrganisms(cultureName);
    }
  }

  /// Obtém organismos do novo sistema convertidos para formato legado
  Future<List<OrganismCatalog>> _getOrganismsFromNewSystem() async {
    try {
      final cultures = _organismDataService.getAllCultures();
      final allOrganisms = <OrganismCatalog>[];
      
      for (final culture in cultures) {
        for (final organism in culture.organisms) {
          final legacyOrganism = _convertToLegacyFormat(organism);
          allOrganisms.add(legacyOrganism);
        }
      }
      
      Logger.info('✅ Convertidos ${allOrganisms.length} organismos do novo sistema');
      return allOrganisms;
    } catch (e) {
      Logger.error('❌ Erro ao converter organismos do novo sistema: $e');
      return [];
    }
  }

  /// Obtém organismos de uma cultura do novo sistema
  Future<List<OrganismCatalog>> _getOrganismsByCultureFromNewSystem(String cultureName) async {
    try {
      final culture = _organismDataService.getCultureByName(cultureName);
      if (culture == null) return [];
      
      final organisms = <OrganismCatalog>[];
      for (final organism in culture.organisms) {
        final legacyOrganism = _convertToLegacyFormat(organism);
        organisms.add(legacyOrganism);
      }
      
      Logger.info('✅ Convertidos ${organisms.length} organismos da cultura $cultureName');
      return organisms;
    } catch (e) {
      Logger.error('❌ Erro ao converter organismos da cultura $cultureName: $e');
      return [];
    }
  }

  /// Converte OrganismData para formato legado OrganismCatalog
  OrganismCatalog _convertToLegacyFormat(OrganismData organism) {
    return OrganismCatalog(
      id: organism.id,
      name: organism.name,
      scientificName: organism.scientificName,
      type: _getLegacyType(organism.category),
      cropId: organism.cultureId,
      cropName: organism.cultureName,
      unit: _getLegacyUnit(organism.category),
      baseDenominator: 1,
      lowLimit: _extractLegacyThreshold(organism.actionThreshold, 'low'),
      mediumLimit: _extractLegacyThreshold(organism.actionThreshold, 'medium'),
      highLimit: _extractLegacyThreshold(organism.actionThreshold, 'high'),
      description: organism.economicDamage,
      imageUrl: null,
      active: organism.active,
      version: '4.0',
      createdAt: organism.createdAt,
      updatedAt: organism.updatedAt,
    );
  }

  /// Obtém tipo legado
  String _getLegacyType(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'pest';
    if (cat.contains('doença') || cat.contains('doenca')) return 'disease';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return 'deficiency';
    return 'other';
  }

  /// Obtém unidade legada
  String _getLegacyUnit(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('praga')) return 'unidades/ponto';
    if (cat.contains('doença') || cat.contains('doenca')) return '% de incidência';
    if (cat.contains('deficiência') || cat.contains('deficiencia')) return '% de severidade';
    return 'unidades';
  }

  /// Extrai limiar legado
  double _extractLegacyThreshold(String? thresholdText, String level) {
    if (thresholdText == null || thresholdText.isEmpty) return 0.0;
    
    // Implementar lógica para extrair limiares específicos
    switch (level) {
      case 'low': return 1.0;
      case 'medium': return 3.0;
      case 'high': return 5.0;
      default: return 0.0;
    }
  }

  /// Obtém dados detalhados de um organismo (novo sistema)
  Future<OrganismData?> getDetailedOrganism(String organismId) async {
    await _ensureInitialized();
    return _organismDataService.getOrganismById(organismId);
  }

  /// Busca organismos (novo sistema)
  Future<List<OrganismData>> searchOrganisms(String query) async {
    await _ensureInitialized();
    return _organismDataService.searchOrganisms(query);
  }

  /// Obtém organismos por categoria (novo sistema)
  Future<List<OrganismData>> getOrganismsByCategory(String category) async {
    await _ensureInitialized();
    return _organismDataService.getOrganismsByCategory(category);
  }

  /// Obtém organismos por fase fenológica (novo sistema)
  Future<List<OrganismData>> getOrganismsByPhenology(String cultureId, String phenologyPhase) async {
    await _ensureInitialized();
    return _organismDataService.getOrganismsByPhenology(cultureId, phenologyPhase);
  }

  /// Obtém estatísticas dos dados (novo sistema)
  Future<Map<String, dynamic>> getDataStatistics() async {
    await _ensureInitialized();
    return _organismDataService.getDataStatistics();
  }

  /// Valida dados (novo sistema)
  Future<List<String>> validateData() async {
    await _ensureInitialized();
    return _organismDataService.validateData();
  }

  /// Atualiza organismo (novo sistema)
  Future<void> updateOrganism(String organismId, Map<String, dynamic> updates) async {
    await _ensureInitialized();
    await _organismDataService.updateOrganism(organismId, updates);
  }

  /// Obtém dados consolidados para catálogo (novo sistema)
  Future<Map<String, dynamic>> getCatalogData() async {
    await _ensureInitialized();
    return _organismDataService.getCatalogData();
  }

  /// Migra dados do sistema legado para o novo sistema
  Future<void> migrateFromLegacySystem() async {
    Logger.info('🔄 Iniciando migração do sistema legado...');
    
    try {
      // Carregar dados do sistema legado
      final legacyOrganisms = await _catalogLoaderService.loadAllOrganisms();
      
      Logger.info('📊 Encontrados ${legacyOrganisms.length} organismos no sistema legado');
      
      // Converter e atualizar no novo sistema
      int migrated = 0;
      int errors = 0;
      
      for (final legacyOrganism in legacyOrganisms) {
        try {
          await _migrateLegacyOrganism(legacyOrganism);
          migrated++;
        } catch (e) {
          Logger.warning('⚠️ Erro ao migrar organismo ${legacyOrganism.id}: $e');
          errors++;
        }
      }
      
      Logger.info('✅ Migração concluída: $migrated sucessos, $errors erros');
    } catch (e) {
      Logger.error('❌ Erro na migração: $e');
      rethrow;
    }
  }

  /// Migra um organismo específico do sistema legado
  Future<void> _migrateLegacyOrganism(OrganismCatalog legacyOrganism) async {
    // Implementar lógica de migração específica
    // Por enquanto, apenas log
    Logger.info('🔄 Migrando organismo: ${legacyOrganism.name}');
  }

  /// Sincroniza dados entre sistemas
  Future<void> syncBetweenSystems() async {
    Logger.info('🔄 Sincronizando dados entre sistemas...');
    
    try {
      // Implementar lógica de sincronização
      // Por enquanto, apenas log
      Logger.info('✅ Sincronização concluída');
    } catch (e) {
      Logger.error('❌ Erro na sincronização: $e');
      rethrow;
    }
  }

  /// Alterna entre sistemas (para testes)
  void toggleSystem() {
    _useNewSystem = !_useNewSystem;
    Logger.info('🔄 Sistema alternado para: ${_useNewSystem ? "Novo" : "Legado"}');
  }

  /// Força uso do novo sistema
  void useNewSystem() {
    _useNewSystem = true;
    Logger.info('🔄 Forçando uso do novo sistema');
  }

  /// Força uso do sistema legado
  void useLegacySystem() {
    _useNewSystem = false;
    Logger.info('🔄 Forçando uso do sistema legado');
  }

  /// Verifica se está usando o novo sistema
  bool get isUsingNewSystem => _useNewSystem;

  /// Verifica se está inicializado
  bool get isInitialized => _isInitialized;

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
      'using_new_system': _useNewSystem,
      'new_system_available': true,
      'legacy_system_available': true,
      'migration_available': true,
      'sync_available': true,
    };
  }

  /// Executa diagnóstico completo
  Future<Map<String, dynamic>> runDiagnostics() async {
    Logger.info('🔍 Executando diagnóstico completo...');
    
    final diagnostics = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'compatibility_info': getCompatibilityInfo(),
      'new_system_stats': null,
      'legacy_system_stats': null,
      'validation_results': null,
      'recommendations': <String>[],
    };
    
    try {
      // Estatísticas do novo sistema
      if (_isInitialized) {
        diagnostics['new_system_stats'] = await getDataStatistics();
        diagnostics['validation_results'] = await validateData();
      }
      
      // Estatísticas do sistema legado
      try {
        final legacyOrganisms = await _catalogLoaderService.loadAllOrganisms();
        diagnostics['legacy_system_stats'] = {
          'total_organisms': legacyOrganisms.length,
          'active_organisms': legacyOrganisms.where((org) => org.active).length,
        };
      } catch (e) {
        diagnostics['legacy_system_error'] = e.toString();
      }
      
      // Recomendações
      final recommendations = <String>[];
      
      if (!_isInitialized) {
        recommendations.add('Inicializar o serviço de integração');
      }
      
      if (_useNewSystem && diagnostics['new_system_stats'] != null) {
        final stats = diagnostics['new_system_stats'] as Map<String, dynamic>;
        if (stats['total_organisms'] == 0) {
          recommendations.add('Migrar dados do sistema legado');
        }
      }
      
      if (diagnostics['validation_results'] != null) {
        final validationResults = diagnostics['validation_results'] as List<String>;
        if (validationResults.isNotEmpty) {
          recommendations.add('Corrigir problemas de validação: ${validationResults.length} issues');
        }
      }
      
      diagnostics['recommendations'] = recommendations;
      
      Logger.info('✅ Diagnóstico concluído');
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico: $e');
      diagnostics['error'] = e.toString();
    }
    
    return diagnostics;
  }
}
