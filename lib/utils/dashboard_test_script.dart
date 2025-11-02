import '../services/dashboard_data_service.dart';
import '../services/infestation_data_diagnostic_service.dart';
import '../utils/logger.dart';

/// Script de teste para verificar dados do dashboard
class DashboardTestScript {
  final DashboardDataService _dashboardDataService = DashboardDataService();
  final InfestationDataDiagnosticService _diagnosticService = InfestationDataDiagnosticService();

  /// Executa teste completo do dashboard
  Future<Map<String, dynamic>> runFullTest() async {
    Logger.info('🧪 Iniciando teste completo do dashboard...');
    
    final results = <String, dynamic>{};
    
    try {
      // 1. Testar diagnóstico de dados de infestação
      results['infestation_diagnostic'] = await _runInfestationDiagnostic();
      
      // 2. Testar carregamento de alertas
      results['alerts_test'] = await _testAlertsLoading();
      
      // 3. Testar carregamento de monitoramento
      results['monitoring_test'] = await _testMonitoringLoading();
      
      // 4. Testar dados do mapa de infestação
      results['map_data_test'] = await _testMapDataLoading();
      
      // 5. Verificar disponibilidade geral de dados
      results['data_availability'] = await _checkDataAvailability();
      
      // 6. Gerar dados de teste se necessário
      results['test_data_generation'] = await _generateTestDataIfNeeded();
      
      Logger.info('✅ Teste completo do dashboard finalizado');
      
    } catch (e) {
      Logger.error('❌ Erro durante teste do dashboard: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Executa diagnóstico de dados de infestação
  Future<Map<String, dynamic>> _runInfestationDiagnostic() async {
    try {
      Logger.info('🔍 Executando diagnóstico de dados de infestação...');
      
      final diagnostic = await _diagnosticService.runFullDiagnostic();
      
      Logger.info('📊 Resultado do diagnóstico: ${diagnostic.keys.join(', ')}');
      
      return {
        'status': 'completed',
        'diagnostic': diagnostic,
        'has_data': _checkIfHasData(diagnostic),
      };
      
    } catch (e) {
      Logger.error('❌ Erro no diagnóstico de infestação: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Testa carregamento de alertas
  Future<Map<String, dynamic>> _testAlertsLoading() async {
    try {
      Logger.info('🔍 Testando carregamento de alertas...');
      
      final alertsData = await _dashboardDataService.loadInfestationAlerts();
      
      Logger.info('📊 Alertas carregados: ${alertsData['total_count']} total, ${alertsData['high_severity']} alta severidade');
      
      return {
        'status': 'completed',
        'total_count': alertsData['total_count'] ?? 0,
        'high_severity': alertsData['high_severity'] ?? 0,
        'critical_severity': alertsData['critical_severity'] ?? 0,
        'has_data': (alertsData['total_count'] ?? 0) > 0,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao testar carregamento de alertas: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Testa carregamento de monitoramento
  Future<Map<String, dynamic>> _testMonitoringLoading() async {
    try {
      Logger.info('🔍 Testando carregamento de monitoramento...');
      
      final monitoringData = await _dashboardDataService.loadMonitoringData();
      
      Logger.info('📊 Monitoramentos carregados: ${monitoringData['total']} total, ${monitoringData['pendentes']} pendentes');
      
      return {
        'status': 'completed',
        'total': monitoringData['total'] ?? 0,
        'pendentes': monitoringData['pendentes'] ?? 0,
        'realizados': monitoringData['realizados'] ?? 0,
        'has_data': (monitoringData['total'] ?? 0) > 0,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao testar carregamento de monitoramento: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Testa carregamento de dados do mapa
  Future<Map<String, dynamic>> _testMapDataLoading() async {
    try {
      Logger.info('🔍 Testando carregamento de dados do mapa...');
      
      final mapData = await _dashboardDataService.loadInfestationMapData();
      
      Logger.info('📊 Dados do mapa carregados: ${mapData['total_points']} pontos, ${mapData['talhoes_count']} talhões');
      
      return {
        'status': 'completed',
        'total_points': mapData['total_points'] ?? 0,
        'talhoes_count': mapData['talhoes_count'] ?? 0,
        'has_data': (mapData['total_points'] ?? 0) > 0,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao testar carregamento de dados do mapa: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Verifica disponibilidade geral de dados
  Future<Map<String, dynamic>> _checkDataAvailability() async {
    try {
      Logger.info('🔍 Verificando disponibilidade geral de dados...');
      
      final hasData = await _dashboardDataService.hasDashboardData();
      
      Logger.info('📊 Dados disponíveis: $hasData');
      
      return {
        'status': 'completed',
        'has_data': hasData,
        'recommendation': hasData 
          ? 'Dados disponíveis - dashboard deve funcionar normalmente'
          : 'Nenhum dado encontrado - considere gerar dados de teste',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar disponibilidade de dados: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Gera dados de teste se necessário
  Future<Map<String, dynamic>> _generateTestDataIfNeeded() async {
    try {
      Logger.info('🔍 Verificando necessidade de gerar dados de teste...');
      
      final testDataResult = await _dashboardDataService.generateTestDataIfNeeded();
      
      Logger.info('📊 Resultado da geração de dados de teste: ${testDataResult['test_data_created']}');
      
      return {
        'status': 'completed',
        'test_data_created': testDataResult['test_data_created'] ?? false,
        'has_existing_data': testDataResult['has_existing_data'] ?? false,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de teste: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Verifica se há dados baseado no diagnóstico
  bool _checkIfHasData(Map<String, dynamic> diagnostic) {
    try {
      final dataCounts = diagnostic['data_counts'] as Map<String, dynamic>?;
      if (dataCounts == null) return false;
      
      // Verificar se há dados em tabelas principais
      final infestationCount = dataCounts['infestacoes_monitoramento']?['count'] ?? 0;
      final monitoringCount = dataCounts['monitoring_sessions']?['count'] ?? 0;
      final talhoesCount = dataCounts['talhoes']?['count'] ?? 0;
      
      return infestationCount > 0 || monitoringCount > 0 || talhoesCount > 0;
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar dados: $e');
      return false;
    }
  }

  /// Gera relatório de teste
  String generateTestReport(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 RELATÓRIO DE TESTE DO DASHBOARD');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Diagnóstico de infestação
    final infestationDiagnostic = results['infestation_diagnostic'] as Map<String, dynamic>?;
    if (infestationDiagnostic != null) {
      buffer.writeln('🔍 DIAGNÓSTICO DE INFESTAÇÃO:');
      buffer.writeln('  Status: ${infestationDiagnostic['status']}');
      buffer.writeln('  Tem dados: ${infestationDiagnostic['has_data']}');
      buffer.writeln();
    }
    
    // Teste de alertas
    final alertsTest = results['alerts_test'] as Map<String, dynamic>?;
    if (alertsTest != null) {
      buffer.writeln('⚠️ TESTE DE ALERTAS:');
      buffer.writeln('  Status: ${alertsTest['status']}');
      buffer.writeln('  Total: ${alertsTest['total_count']}');
      buffer.writeln('  Alta severidade: ${alertsTest['high_severity']}');
      buffer.writeln('  Tem dados: ${alertsTest['has_data']}');
      buffer.writeln();
    }
    
    // Teste de monitoramento
    final monitoringTest = results['monitoring_test'] as Map<String, dynamic>?;
    if (monitoringTest != null) {
      buffer.writeln('🔬 TESTE DE MONITORAMENTO:');
      buffer.writeln('  Status: ${monitoringTest['status']}');
      buffer.writeln('  Total: ${monitoringTest['total']}');
      buffer.writeln('  Pendentes: ${monitoringTest['pendentes']}');
      buffer.writeln('  Realizados: ${monitoringTest['realizados']}');
      buffer.writeln('  Tem dados: ${monitoringTest['has_data']}');
      buffer.writeln();
    }
    
    // Teste de dados do mapa
    final mapDataTest = results['map_data_test'] as Map<String, dynamic>?;
    if (mapDataTest != null) {
      buffer.writeln('🗺️ TESTE DE DADOS DO MAPA:');
      buffer.writeln('  Status: ${mapDataTest['status']}');
      buffer.writeln('  Pontos: ${mapDataTest['total_points']}');
      buffer.writeln('  Talhões: ${mapDataTest['talhoes_count']}');
      buffer.writeln('  Tem dados: ${mapDataTest['has_data']}');
      buffer.writeln();
    }
    
    // Disponibilidade de dados
    final dataAvailability = results['data_availability'] as Map<String, dynamic>?;
    if (dataAvailability != null) {
      buffer.writeln('📈 DISPONIBILIDADE DE DADOS:');
      buffer.writeln('  Tem dados: ${dataAvailability['has_data']}');
      buffer.writeln('  Recomendação: ${dataAvailability['recommendation']}');
      buffer.writeln();
    }
    
    // Geração de dados de teste
    final testDataGeneration = results['test_data_generation'] as Map<String, dynamic>?;
    if (testDataGeneration != null) {
      buffer.writeln('🧪 GERAÇÃO DE DADOS DE TESTE:');
      buffer.writeln('  Status: ${testDataGeneration['status']}');
      buffer.writeln('  Dados criados: ${testDataGeneration['test_data_created']}');
      buffer.writeln('  Dados existentes: ${testDataGeneration['has_existing_data']}');
      buffer.writeln();
    }
    
    // Resumo geral
    buffer.writeln('📋 RESUMO GERAL:');
    final hasAlerts = alertsTest?['has_data'] ?? false;
    final hasMonitoring = monitoringTest?['has_data'] ?? false;
    final hasMapData = mapDataTest?['has_data'] ?? false;
    
    if (hasAlerts || hasMonitoring || hasMapData) {
      buffer.writeln('  ✅ Dashboard deve funcionar com dados disponíveis');
    } else {
      buffer.writeln('  ⚠️ Nenhum dado encontrado - dashboard pode não funcionar corretamente');
    }
    
    return buffer.toString();
  }
}
