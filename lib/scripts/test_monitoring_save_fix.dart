import 'dart:async';
import '../services/monitoring_save_fix_service.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Script de teste para verificar o serviço de correção de salvamento
class TestMonitoringSaveFix {
  static Future<void> runTest() async {
    try {
      Logger.info('🧪 Iniciando teste do serviço de correção de salvamento...');
      
      // Criar dados de teste
      final testMonitoring = _createTestMonitoring();
      
      // Testar o serviço de correção
      final saveFixService = MonitoringSaveFixService();
      
      Logger.info('🔄 Testando salvamento com correções automáticas...');
      final result = await saveFixService.saveMonitoringWithFix(testMonitoring);
      
      if (result) {
        Logger.info('✅ Teste PASSOU: Monitoramento salvo com sucesso!');
      } else {
        Logger.error('❌ Teste FALHOU: Falha ao salvar monitoramento');
      }
      
    } catch (e) {
      Logger.error('❌ Erro durante o teste: $e');
    }
  }

  /// Cria um monitoramento de teste
  static Monitoring _createTestMonitoring() {
    // Criar ocorrências de teste
    final testOccurrences = [
      Occurrence(
        type: OccurrenceType.pest,
        name: 'Lagarta do Cartucho',
        infestationIndex: 25.0,
        affectedSections: [PlantSection.upper, PlantSection.middle],
        notes: 'Ocorrência de teste',
      ),
      Occurrence(
        type: OccurrenceType.disease,
        name: 'Ferrugem Asiática',
        infestationIndex: 15.0,
        affectedSections: [PlantSection.lower],
        notes: 'Doença de teste',
      ),
    ];

    // Criar pontos de teste
    final testPoints = [
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão Teste 1',
        cropId: 1,
        cropName: 'Soja',
        latitude: -23.5505,
        longitude: -46.6333,
        occurrences: testOccurrences,
        observations: 'Ponto de teste 1',
      ),
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão Teste 1',
        cropId: 1,
        cropName: 'Soja',
        latitude: -23.5506,
        longitude: -46.6334,
        occurrences: [testOccurrences[0]],
        observations: 'Ponto de teste 2',
      ),
    ];

    // Criar rota de teste
    final testRoute = [
      {'latitude': -23.5505, 'longitude': -46.6333},
      {'latitude': -23.5506, 'longitude': -46.6334},
    ];

    // Criar monitoramento de teste
    return Monitoring(
      id: 'test-monitoring-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      plotId: 1,
      plotName: 'Talhão Teste 1',
      cropId: 1,
      cropName: 'Soja',
      cropType: 'Grãos',
      route: testRoute,
      points: testPoints,
      isCompleted: true,
      isSynced: false,
      severity: 30,
      observations: 'Monitoramento de teste',
      recommendations: 'Aplicar tratamento preventivo',
    );
  }

  /// Executa teste de validação de dados
  static Future<void> testDataValidation() async {
    try {
      Logger.info('🧪 Testando validação de dados...');
      
      // Teste 1: Monitoramento com dados válidos
      final validMonitoring = _createTestMonitoring();
      final saveFixService = MonitoringSaveFixService();
      
      // Usar reflexão para acessar método privado (apenas para teste)
      // final validated = await saveFixService._validateAndFixMonitoring(validMonitoring);
      // Logger.info('✅ Validação de dados válidos: OK');
      
      // Teste 2: Monitoramento com dados inválidos
      final invalidMonitoring = Monitoring(
        id: '', // ID vazio
        date: DateTime.now(),
        plotId: 0, // plotId inválido
        plotName: '', // Nome vazio
        cropId: 0, // cropId inválido
        cropName: '', // Nome vazio
        route: [],
        points: [
          MonitoringPoint(
            plotId: 0,
            plotName: '',
            latitude: double.nan, // Latitude inválida
            longitude: double.infinity, // Longitude inválida
            occurrences: [
              Occurrence(
                type: OccurrenceType.pest,
                name: '', // Nome vazio
                infestationIndex: -10.0, // Índice inválido
                affectedSections: [],
              ),
            ],
          ),
        ],
      );
      
      final result = await saveFixService.saveMonitoringWithFix(invalidMonitoring);
      
      if (result) {
        Logger.info('✅ Teste de correção automática: PASSOU');
      } else {
        Logger.error('❌ Teste de correção automática: FALHOU');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de validação: $e');
    }
  }

  /// Executa teste de banco de dados
  static Future<void> testDatabaseOperations() async {
    try {
      Logger.info('🧪 Testando operações de banco de dados...');
      
      final saveFixService = MonitoringSaveFixService();
      
      // Teste 1: Verificar se as tabelas existem
      // final dbOk = await saveFixService._ensureDatabaseReady();
      // Logger.info('✅ Verificação de banco de dados: ${dbOk ? 'OK' : 'FALHOU'}');
      
      // Teste 2: Criar monitoramento e verificar se foi salvo
      final testMonitoring = _createTestMonitoring();
      final saveResult = await saveFixService.saveMonitoringWithFix(testMonitoring);
      
      if (saveResult) {
        Logger.info('✅ Salvamento no banco: OK');
        
        // Verificar se foi salvo corretamente
        // final savedMonitoring = await _getMonitoringById(testMonitoring.id);
        // if (savedMonitoring != null) {
        //   Logger.info('✅ Verificação de salvamento: OK');
        // } else {
        //   Logger.error('❌ Monitoramento não encontrado após salvar');
        // }
      } else {
        Logger.error('❌ Falha no salvamento no banco');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de banco de dados: $e');
    }
  }

  /// Executa todos os testes
  static Future<void> runAllTests() async {
    Logger.info('🚀 Iniciando bateria completa de testes...');
    
    await runTest();
    await testDataValidation();
    await testDatabaseOperations();
    
    Logger.info('🏁 Bateria de testes concluída!');
  }
}

/// Função principal para executar os testes
Future<void> main() async {
  await TestMonitoringSaveFix.runAllTests();
}
