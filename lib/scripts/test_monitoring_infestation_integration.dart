import 'dart:io';
import '../services/monitoring_infestation_integration_service.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Script de teste para verificar a integração entre monitoramento e mapa de infestação
class TestMonitoringInfestationIntegration {
  static Future<void> runTest() async {
    try {
      Logger.info('🧪 Iniciando teste de integração monitoramento → mapa de infestação...');
      
      // 1. Criar dados de teste
      final testMonitoring = _createTestMonitoring();
      
      // 2. Testar serviço de integração
      final integrationService = MonitoringInfestationIntegrationService();
      
      // 3. Processar monitoramento
      final success = await integrationService.processMonitoringForInfestation(testMonitoring);
      
      if (success) {
        Logger.info('✅ Teste de integração: SUCESSO');
        
        // 4. Verificar se os dados foram salvos
        await _verifyDataSaved(integrationService, testMonitoring);
        
      } else {
        Logger.error('❌ Teste de integração: FALHA');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de integração: $e');
    }
  }
  
  /// Cria dados de teste para monitoramento
  static Monitoring _createTestMonitoring() {
    final now = DateTime.now();
    
    // Criar ocorrências de teste
    final occurrences = [
      Occurrence(
        id: 'occ_1',
        type: OccurrenceType.pest,
        name: 'Lagarta-do-cartucho',
        infestationIndex: 45.0,
        affectedSections: ['folhas', 'cartucho'],
        notes: 'Infestação moderada detectada',
        createdAt: now,
        updatedAt: now,
      ),
      Occurrence(
        id: 'occ_2',
        type: OccurrenceType.disease,
        name: 'Ferrugem',
        infestationIndex: 25.0,
        affectedSections: ['folhas'],
        notes: 'Doença em estágio inicial',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    
    // Criar pontos de monitoramento
    final points = [
      MonitoringPoint(
        id: 'point_1',
        monitoringId: 'test_monitoring',
        plotId: 1,
        plotName: 'Talhão Teste',
        latitude: -23.5505,
        longitude: -46.6333,
        gpsAccuracy: 3.0,
        occurrences: [occurrences[0]],
        observations: 'Ponto 1 - Lagarta detectada',
        createdAt: now,
        updatedAt: now,
      ),
      MonitoringPoint(
        id: 'point_2',
        monitoringId: 'test_monitoring',
        plotId: 1,
        plotName: 'Talhão Teste',
        latitude: -23.5506,
        longitude: -46.6334,
        gpsAccuracy: 2.5,
        occurrences: [occurrences[1]],
        observations: 'Ponto 2 - Ferrugem detectada',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    
    // Criar monitoramento de teste
    return Monitoring(
      id: 'test_monitoring_${now.millisecondsSinceEpoch}',
      date: now,
      plotId: 1,
      plotName: 'Talhão Teste',
      cropId: 1,
      cropName: 'Milho',
      route: 'Rota de teste',
      points: points,
      isCompleted: true,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Verifica se os dados foram salvos corretamente
  static Future<void> _verifyDataSaved(
    MonitoringInfestationIntegrationService service,
    Monitoring monitoring,
  ) async {
    try {
      Logger.info('🔍 Verificando se os dados foram salvos...');
      
      // Buscar dados de infestação do talhão
      final summaries = await service.getInfestationDataForTalhao(monitoring.plotId.toString());
      
      if (summaries.isNotEmpty) {
        Logger.info('✅ ${summaries.length} resumos de infestação encontrados');
        
        for (final summary in summaries) {
          Logger.info('   📊 Organismo: ${summary.organismoId}');
          Logger.info('   📈 Nível: ${summary.level}');
          Logger.info('   📊 Infestação: ${summary.avgInfestation.toStringAsFixed(1)}%');
          Logger.info('   📍 Pontos: ${summary.totalPoints}');
        }
      } else {
        Logger.warning('⚠️ Nenhum resumo de infestação encontrado');
      }
      
      // Buscar alertas
      final alerts = await service.getActiveAlerts(talhaoId: monitoring.plotId.toString());
      
      if (alerts.isNotEmpty) {
        Logger.info('🚨 ${alerts.length} alertas ativos encontrados');
        
        for (final alert in alerts) {
          Logger.info('   🚨 Alerta: ${alert.level} para ${alert.organismoId}');
          Logger.info('   📝 Descrição: ${alert.description}');
        }
      } else {
        Logger.info('ℹ️ Nenhum alerta ativo encontrado');
      }
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados salvos: $e');
    }
  }
}

/// Função principal para executar o teste
Future<void> main() async {
  await TestMonitoringInfestationIntegration.runTest();
  exit(0);
}
