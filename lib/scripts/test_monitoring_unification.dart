import 'dart:async';
import '../services/monitoring_unification_service.dart';
import '../services/monitoring_save_fix_service.dart';
import '../models/monitoring.dart';
import '../models/monitoring_point.dart';
import '../models/occurrence.dart';
import '../utils/enums.dart';
import '../utils/logger.dart';

/// Script de teste para verificar a unificação do módulo de monitoramento
class TestMonitoringUnification {
  static Future<void> runAllTests() async {
    try {
      Logger.info('🧪 Iniciando testes de unificação do módulo de monitoramento...');
      
      // Teste 1: Verificar estatísticas dos dados
      await testDataStatistics();
      
      // Teste 2: Verificar duplicação de dados
      await testDataDuplication();
      
      // Teste 3: Testar migração de dados
      await testDataMigration();
      
      // Teste 4: Testar processo completo de unificação
      await testCompleteUnification();
      
      Logger.info('🏁 Todos os testes de unificação concluídos!');
      
    } catch (e) {
      Logger.error('❌ Erro durante os testes: $e');
    }
  }

  /// Teste 1: Verificar estatísticas dos dados
  static Future<void> testDataStatistics() async {
    try {
      Logger.info('📊 Teste 1: Verificando estatísticas dos dados...');
      
      final unificationService = MonitoringUnificationService();
      final statistics = await unificationService.getDataStatistics();
      
      Logger.info('📈 Estatísticas obtidas:');
      Logger.info('  - Repositório Principal: ${statistics['mainRepository']}');
      Logger.info('  - Repositório de Módulo: ${statistics['moduleRepository']}');
      Logger.info('  - Total: ${statistics['total']}');
      
      if (statistics.containsKey('error')) {
        Logger.warning('⚠️ Erro ao obter estatísticas: ${statistics['error']}');
      } else {
        Logger.info('✅ Estatísticas obtidas com sucesso');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de estatísticas: $e');
    }
  }

  /// Teste 2: Verificar duplicação de dados
  static Future<void> testDataDuplication() async {
    try {
      Logger.info('🔍 Teste 2: Verificando duplicação de dados...');
      
      final unificationService = MonitoringUnificationService();
      final duplicationInfo = await unificationService.checkDataDuplication();
      
      Logger.info('📋 Informações de duplicação:');
      Logger.info('  - Monitoramentos no repositório principal: ${duplicationInfo['mainCount']}');
      Logger.info('  - Monitoramentos no repositório de módulo: ${duplicationInfo['moduleCount']}');
      Logger.info('  - Dados duplicados: ${duplicationInfo['duplicatedCount']}');
      Logger.info('  - Possui duplicação: ${duplicationInfo['hasDuplication']}');
      
      if (duplicationInfo['hasDuplication']) {
        Logger.warning('⚠️ Dados duplicados encontrados!');
        final duplicatedIds = duplicationInfo['duplicatedIds'] as List<String>;
        Logger.info('  - IDs duplicados: $duplicatedIds');
      } else {
        Logger.info('✅ Nenhuma duplicação encontrada');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de duplicação: $e');
    }
  }

  /// Teste 3: Testar migração de dados
  static Future<void> testDataMigration() async {
    try {
      Logger.info('🔄 Teste 3: Testando migração de dados...');
      
      final unificationService = MonitoringUnificationService();
      
      // Primeiro verificar se há dados para migrar
      final statistics = await unificationService.getDataStatistics();
      final moduleCount = statistics['moduleRepository']?['monitorings'] ?? 0;
      
      if (moduleCount == 0) {
        Logger.info('ℹ️ Nenhum dado no repositório de módulo para migrar');
        return;
      }
      
      Logger.info('📦 Migrando $moduleCount monitoramentos...');
      
      // Executar migração
      final migrationSuccess = await unificationService.migrateModuleDataToMain();
      
      if (migrationSuccess) {
        Logger.info('✅ Migração concluída com sucesso');
      } else {
        Logger.error('❌ Falha na migração');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de migração: $e');
    }
  }

  /// Teste 4: Testar processo completo de unificação
  static Future<void> testCompleteUnification() async {
    try {
      Logger.info('🚀 Teste 4: Testando processo completo de unificação...');
      
      final unificationService = MonitoringUnificationService();
      
      // Executar unificação completa
      final unificationSuccess = await unificationService.unifyMonitoringData();
      
      if (unificationSuccess) {
        Logger.info('✅ Unificação completa concluída com sucesso!');
        
        // Verificar resultado final
        final finalStatistics = await unificationService.getDataStatistics();
        Logger.info('📊 Estatísticas finais: $finalStatistics');
        
      } else {
        Logger.error('❌ Falha na unificação completa');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de unificação completa: $e');
    }
  }

  /// Teste 5: Testar conversão de modelos
  static Future<void> testModelConversion() async {
    try {
      Logger.info('🔄 Teste 5: Testando conversão de modelos...');
      
      // Criar um monitoramento de teste
      final testMonitoring = _createTestMonitoring();
      
      Logger.info('✅ Monitoramento de teste criado com ID: ${testMonitoring.id}');
      Logger.info('  - Pontos: ${testMonitoring.points.length}');
      Logger.info('  - Ocorrências: ${testMonitoring.points.fold(0, (sum, point) => sum + point.occurrences.length)}');
      
      // Testar salvamento com o serviço de correção
      final saveFixService = MonitoringSaveFixService();
      final saveResult = await saveFixService.saveMonitoringWithFix(testMonitoring);
      
      if (saveResult) {
        Logger.info('✅ Monitoramento salvo com sucesso usando serviço de correção');
      } else {
        Logger.error('❌ Falha ao salvar monitoramento');
      }
      
    } catch (e) {
      Logger.error('❌ Erro no teste de conversão: $e');
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
        notes: 'Ocorrência de teste para unificação',
      ),
      Occurrence(
        type: OccurrenceType.disease,
        name: 'Ferrugem Asiática',
        infestationIndex: 15.0,
        affectedSections: [PlantSection.lower],
        notes: 'Doença de teste para unificação',
      ),
    ];

    // Criar pontos de teste
    final testPoints = [
      MonitoringPoint(
        plotId: 1,
        plotName: 'Talhão Teste Unificação',
        cropId: 1,
        cropName: 'Soja',
        latitude: -23.5505,
        longitude: -46.6333,
        occurrences: testOccurrences,
        observations: 'Ponto de teste para unificação',
      ),
    ];

    // Criar rota de teste
    final testRoute = [
      {'latitude': -23.5505, 'longitude': -46.6333},
    ];

    // Criar monitoramento de teste
    return Monitoring(
      id: 'test-unification-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      plotId: 1,
      plotName: 'Talhão Teste Unificação',
      cropId: 1,
      cropName: 'Soja',
      cropType: 'Grãos',
      route: testRoute,
      points: testPoints,
      isCompleted: true,
      isSynced: false,
      severity: 30,
      observations: 'Monitoramento de teste para unificação',
      recommendations: 'Aplicar tratamento preventivo',
    );
  }
}

/// Função principal para executar os testes
Future<void> main() async {
  await TestMonitoringUnification.runAllTests();
}
