import '../models/organism_catalog.dart';
import '../models/monitoring_point.dart';
import '../models/infestacao_model.dart';
import '../utils/logger.dart';
import '../utils/enums.dart';
import 'organism_catalog_loader_service.dart';
import 'agricultural_expert_validation_service.dart';
import '../modules/infestation_map/services/organism_catalog_integration_service.dart';
import '../modules/infestation_map/services/infestation_calculation_service.dart';

/// Serviço para testar o fluxo completo de integração
/// Monitoramento → Catálogo → Mapa de Infestação
class IntegrationFlowTestService {
  static const String _tag = 'INTEGRATION_FLOW_TEST';

  final OrganismCatalogLoaderService _catalogLoader = OrganismCatalogLoaderService();
  final AgriculturalExpertValidationService _validationService = AgriculturalExpertValidationService();
  final OrganismCatalogIntegrationService _integrationService = OrganismCatalogIntegrationService();
  final InfestationCalculationService _calculationService = InfestationCalculationService();

  /// Testa o fluxo completo de integração
  Future<Map<String, dynamic>> testCompleteIntegrationFlow() async {
    try {
      Logger.info('$_tag: Iniciando teste do fluxo completo de integração...');
      
      final results = {
        'success': true,
        'flow_tests': {},
        'summary': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // 1. Teste de carregamento do catálogo
      results['flow_tests']['catalog_loading'] = await _testCatalogLoading();
      
      // 2. Teste de validação de dados
      results['flow_tests']['data_validation'] = await _testDataValidation();
      
      // 3. Teste de integração com mapa de infestação
      results['flow_tests']['infestation_integration'] = await _testInfestationIntegration();
      
      // 4. Teste de cálculo de infestação
      results['flow_tests']['infestation_calculation'] = await _testInfestationCalculation();
      
      // 5. Teste de fluxo end-to-end
      results['flow_tests']['end_to_end'] = await _testEndToEndFlow();
      
      // Resumo dos testes
      results['summary'] = _generateSummary(results['flow_tests']);
      
      Logger.info('$_tag: Teste do fluxo completo concluído');
      return results;
      
    } catch (e) {
      Logger.error('$_tag: Erro no teste do fluxo completo: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Testa o carregamento do catálogo
  Future<Map<String, dynamic>> _testCatalogLoading() async {
    try {
      Logger.info('$_tag: Testando carregamento do catálogo...');
      
      final startTime = DateTime.now();
      final organisms = await _catalogLoader.loadAllOrganisms();
      final endTime = DateTime.now();
      
      final loadTime = endTime.difference(startTime);
      
      // Verificar se os organismos têm dados válidos
      int validOrganisms = 0;
      int invalidOrganisms = 0;
      
      for (final organism in organisms) {
        if (organism.name.isNotEmpty && 
            organism.scientificName.isNotEmpty && 
            organism.lowLimit < organism.mediumLimit && 
            organism.mediumLimit < organism.highLimit) {
          validOrganisms++;
        } else {
          invalidOrganisms++;
        }
      }
      
      return {
        'success': true,
        'total_organisms': organisms.length,
        'valid_organisms': validOrganisms,
        'invalid_organisms': invalidOrganisms,
        'load_time_ms': loadTime.inMilliseconds,
        'data_quality_rate': organisms.length > 0 ? (validOrganisms / organisms.length * 100).toStringAsFixed(1) + '%' : '0%',
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro no teste de carregamento: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Testa a validação de dados
  Future<Map<String, dynamic>> _testDataValidation() async {
    try {
      Logger.info('$_tag: Testando validação de dados...');
      
      final startTime = DateTime.now();
      final validationResults = await _catalogLoader.validateAllOrganisms();
      final endTime = DateTime.now();
      
      final validationTime = endTime.difference(startTime);
      
      return {
        'success': true,
        'validation_results': validationResults,
        'validation_time_ms': validationTime.inMilliseconds,
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro no teste de validação: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Testa a integração com mapa de infestação
  Future<Map<String, dynamic>> _testInfestationIntegration() async {
    try {
      Logger.info('$_tag: Testando integração com mapa de infestação...');
      
      final startTime = DateTime.now();
      
      // Testar obtenção de organismos validados
      final validatedOrganisms = await _integrationService.getValidatedOrganisms();
      
      // Testar obtenção de pesos de risco
      final riskWeights = await _integrationService.getRiskWeights();
      
      // Testar obtenção de organismos por cultura
      final sojaOrganisms = await _integrationService.getValidatedOrganismsByCrop('soja');
      final milhoOrganisms = await _integrationService.getValidatedOrganismsByCrop('milho');
      
      final endTime = DateTime.now();
      final integrationTime = endTime.difference(startTime);
      
      return {
        'success': true,
        'validated_organisms_count': validatedOrganisms.length,
        'risk_weights_count': riskWeights.length,
        'soja_organisms_count': sojaOrganisms.length,
        'milho_organisms_count': milhoOrganisms.length,
        'integration_time_ms': integrationTime.inMilliseconds,
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro no teste de integração: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Testa o cálculo de infestação
  Future<Map<String, dynamic>> _testInfestationCalculation() async {
    try {
      Logger.info('$_tag: Testando cálculo de infestação...');
      
      final startTime = DateTime.now();
      
      // Criar dados de teste
      final testOrganisms = await _integrationService.getValidatedOrganisms();
      if (testOrganisms.isEmpty) {
        return {
          'success': false,
          'error': 'Nenhum organismo validado encontrado para teste',
        };
      }
      
      final testOrganism = testOrganisms.first;
      
      // Testar conversão de quantidade para percentual
      final pctResult = _calculationService.pctFromQuantity(
        quantity: 10,
        unidade: testOrganism.unit,
        org: testOrganism,
        totalPlantas: 100,
      );
      
      // Testar determinação de nível de infestação
      final levelResult = await _calculationService.levelFromPct(
        pctResult,
        organismoId: testOrganism.id,
      );
      
      final endTime = DateTime.now();
      final calculationTime = endTime.difference(startTime);
      
      return {
        'success': true,
        'test_organism': testOrganism.name,
        'quantity_to_percentage': pctResult,
        'infestation_level': levelResult,
        'calculation_time_ms': calculationTime.inMilliseconds,
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro no teste de cálculo: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Testa o fluxo end-to-end
  Future<Map<String, dynamic>> _testEndToEndFlow() async {
    try {
      Logger.info('$_tag: Testando fluxo end-to-end...');
      
      final startTime = DateTime.now();
      
      // 1. Simular dados de monitoramento
      final monitoringData = _createMockMonitoringData();
      
      // 2. Carregar organismos validados
      final organisms = await _integrationService.getValidatedOrganisms();
      
      // 3. Processar dados de monitoramento
      final processedData = await _processMonitoringData(monitoringData, organisms);
      
      // 4. Calcular níveis de infestação
      final infestationLevels = await _calculateInfestationLevels(processedData, organisms);
      
      final endTime = DateTime.now();
      final endToEndTime = endTime.difference(startTime);
      
      return {
        'success': true,
        'monitoring_points': monitoringData.length,
        'validated_organisms': organisms.length,
        'processed_data_points': processedData.length,
        'infestation_levels_calculated': infestationLevels.length,
        'end_to_end_time_ms': endToEndTime.inMilliseconds,
      };
      
    } catch (e) {
      Logger.error('$_tag: Erro no teste end-to-end: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cria dados de monitoramento simulados
  List<Map<String, dynamic>> _createMockMonitoringData() {
    return [
      {
        'id': 'test_001',
        'talhao_id': 'talhao_001',
        'crop_id': 'soja',
        'organism_id': 'lagarta_soja',
        'quantity': 15,
        'unit': 'indivíduos/m²',
        'latitude': -23.5505,
        'longitude': -46.6333,
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'id': 'test_002',
        'talhao_id': 'talhao_001',
        'crop_id': 'soja',
        'organism_id': 'percevejo_verde',
        'quantity': 8,
        'unit': 'indivíduos/m²',
        'latitude': -23.5506,
        'longitude': -46.6334,
        'timestamp': DateTime.now().toIso8601String(),
      },
      {
        'id': 'test_003',
        'talhao_id': 'talhao_002',
        'crop_id': 'milho',
        'organism_id': 'lagarta_cartucho',
        'quantity': 25,
        'unit': 'indivíduos/m²',
        'latitude': -23.5507,
        'longitude': -46.6335,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ];
  }

  /// Processa dados de monitoramento
  Future<List<Map<String, dynamic>>> _processMonitoringData(
    List<Map<String, dynamic>> monitoringData,
    List<OrganismCatalog> organisms,
  ) async {
    final List<Map<String, dynamic>> processedData = [];
    
    for (final data in monitoringData) {
      // Encontrar organismo correspondente
      final organism = organisms.firstWhere(
        (org) => org.id == data['organism_id'] || org.name.toLowerCase().contains(data['organism_id'].toString().toLowerCase()),
        orElse: () => organisms.first,
      );
      
      // Calcular percentual
      final pct = _calculationService.pctFromQuantity(
        quantity: data['quantity'] as int,
        unidade: data['unit'] as String,
        org: organism,
        totalPlantas: 100,
      );
      
      processedData.add({
        ...data,
        'organism_name': organism.name,
        'scientific_name': organism.scientificName,
        'calculated_percentage': pct,
        'unit': organism.unit,
      });
    }
    
    return processedData;
  }

  /// Calcula níveis de infestação
  Future<List<Map<String, dynamic>>> _calculateInfestationLevels(
    List<Map<String, dynamic>> processedData,
    List<OrganismCatalog> organisms,
  ) async {
    final List<Map<String, dynamic>> infestationLevels = [];
    
    for (final data in processedData) {
      final organism = organisms.firstWhere(
        (org) => org.id == data['organism_id'] || org.name.toLowerCase().contains(data['organism_id'].toString().toLowerCase()),
        orElse: () => organisms.first,
      );
      
      final level = await _calculationService.levelFromPct(
        data['calculated_percentage'] as double,
        organismoId: organism.id,
      );
      
      infestationLevels.add({
        ...data,
        'infestation_level': level,
        'risk_assessment': _assessRisk(level, data['calculated_percentage'] as double),
      });
    }
    
    return infestationLevels;
  }

  /// Avalia o risco baseado no nível de infestação
  String _assessRisk(String level, double percentage) {
    switch (level) {
      case 'BAIXO':
        return 'Risco baixo - Monitoramento de rotina';
      case 'MEDIO':
        return 'Risco médio - Aplicação preventiva recomendada';
      case 'ALTO':
        return 'Risco alto - Aplicação curativa urgente';
      default:
        return 'Risco desconhecido - Investigação necessária';
    }
  }

  /// Gera resumo dos testes
  Map<String, dynamic> _generateSummary(Map<String, dynamic> flowTests) {
    int totalTests = 0;
    int passedTests = 0;
    
    flowTests.forEach((key, value) {
      if (value is Map<String, dynamic> && value.containsKey('success')) {
        totalTests++;
        if (value['success'] == true) {
          passedTests++;
        }
      }
    });
    
    return {
      'total_tests': totalTests,
      'passed_tests': passedTests,
      'failed_tests': totalTests - passedTests,
      'success_rate': totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(1) + '%' : '0%',
      'overall_status': passedTests == totalTests ? 'SUCCESS' : 'PARTIAL_SUCCESS',
    };
  }
}
