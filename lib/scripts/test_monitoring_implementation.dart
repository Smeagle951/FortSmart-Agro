import '../database/app_database.dart';
import '../services/monitoring_analysis_service.dart';
import '../services/monitoring_api_service.dart';
import '../services/organism_catalog_service.dart';
import '../utils/logger.dart';

/// Script de teste para verificar a implementação da FASE 1
/// Testa: Estrutura de banco, Análise, API e Catálogo
class TestMonitoringImplementation {
  static const String _tag = 'TestMonitoringImplementation';

  /// Executa todos os testes da FASE 1
  static Future<void> runAllTests() async {
    Logger.info('$_tag: 🚀 Iniciando testes da FASE 1 - Monitoramento Avançado');
    
    try {
      // Teste 1: Estrutura de Banco de Dados
      await _testDatabaseStructure();
      
      // Teste 2: Catálogo de Organismos
      await _testOrganismCatalog();
      
      // Teste 3: Serviço de Análise
      await _testAnalysisService();
      
      // Teste 4: API Service (simulado)
      await _testApiService();
      
      Logger.info('$_tag: ✅ Todos os testes da FASE 1 passaram com sucesso!');
    } catch (e) {
      Logger.error('$_tag: ❌ Falha nos testes: $e');
      rethrow;
    }
  }

  /// Teste 1: Estrutura de Banco de Dados
  static Future<void> _testDatabaseStructure() async {
    Logger.info('$_tag: 📊 Testando estrutura de banco de dados...');
    
    try {
      final db = await AppDatabase.instance.database;
      
      // Verificar se as tabelas foram criadas
      final tables = [
        'catalog_organisms',
        'monitoring_sessions',
        'monitoring_points',
        'monitoring_occurrences',
        'infestation_map',
        'sync_history',
      ];
      
      for (final table in tables) {
        final result = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="$table"');
        if (result.isEmpty) {
          throw Exception('Tabela $table não foi criada');
        }
        Logger.info('$_tag: ✅ Tabela $table existe');
      }
      
      // Verificar integridade do banco
      final integrityOk = await MonitoringDatabaseSchema.checkDatabaseIntegrity(db);
      if (!integrityOk) {
        throw Exception('Problemas de integridade detectados');
      }
      
      Logger.info('$_tag: ✅ Estrutura de banco de dados OK');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no teste de estrutura: $e');
      rethrow;
    }
  }

  /// Teste 2: Catálogo de Organismos
  static Future<void> _testOrganismCatalog() async {
    Logger.info('$_tag: 🐛 Testando catálogo de organismos...');
    
    try {
      final catalogService = OrganismCatalogService();
      
      // Inicializar catálogo padrão
      await catalogService.initializeDefaultCatalog();
      
      // Obter todos os organismos
      final organisms = await catalogService.getAllOrganisms();
      if (organisms.isEmpty) {
        throw Exception('Nenhum organismo encontrado no catálogo');
      }
      
      Logger.info('$_tag: ✅ ${organisms.length} organismos carregados');
      
      // Testar busca por cultura
      final sojaOrganisms = await catalogService.getOrganismsByCrop('soja');
      if (sojaOrganisms.isEmpty) {
        throw Exception('Nenhum organismo encontrado para soja');
      }
      
      Logger.info('$_tag: ✅ ${sojaOrganisms.length} organismos para soja');
      
      // Testar busca por tipo
      final pests = await catalogService.getOrganismsByType(OccurrenceType.pest);
      final diseases = await catalogService.getOrganismsByType(OccurrenceType.disease);
      final weeds = await catalogService.getOrganismsByType(OccurrenceType.weed);
      
      Logger.info('$_tag: ✅ Pragas: ${pests.length}, Doenças: ${diseases.length}, Daninhas: ${weeds.length}');
      
      // Testar normalização
      if (pests.isNotEmpty) {
        final pest = pests.first;
        final normalizedValue = pest.normalizeValue(15.0, 10);
        final alertLevel = pest.getAlertLevel(normalizedValue);
        
        Logger.info('$_tag: ✅ Normalização: 15.0 -> $normalizedValue (nível: $alertLevel)');
      }
      
      // Testar estatísticas
      final stats = await catalogService.getCatalogStats();
      Logger.info('$_tag: ✅ Estatísticas: $stats');
      
      Logger.info('$_tag: ✅ Catálogo de organismos OK');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no teste de catálogo: $e');
      rethrow;
    }
  }

  /// Teste 3: Serviço de Análise
  static Future<void> _testAnalysisService() async {
    Logger.info('$_tag: 🔬 Testando serviço de análise...');
    
    try {
      final analysisService = MonitoringAnalysisService();
      final db = await AppDatabase.instance.database;
      
      // Criar dados de teste
      final sessionId = await _createTestSession(db);
      final pointId = await _createTestPoint(db, sessionId);
      await _createTestOccurrences(db, pointId);
      
      // Executar análise
      final result = await analysisService.analyzeSession(sessionId);
      
      // Verificar resultado
      if (result.resumoPorOrganismo.isEmpty) {
        throw Exception('Análise não retornou resumo de organismos');
      }
      
      Logger.info('$_tag: ✅ Análise concluída: ${result.resumoPorOrganismo.length} organismos');
      
      // Verificar dados salvos no banco
      final infestationData = await db.query(
        'infestation_map',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      
      if (infestationData.isEmpty) {
        throw Exception('Dados de infestação não foram salvos');
      }
      
      Logger.info('$_tag: ✅ ${infestationData.length} registros de infestação salvos');
      
      // Limpar dados de teste
      await _cleanupTestData(db, sessionId);
      
      Logger.info('$_tag: ✅ Serviço de análise OK');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no teste de análise: $e');
      rethrow;
    }
  }

  /// Teste 4: API Service (simulado)
  static Future<void> _testApiService() async {
    Logger.info('$_tag: 🌐 Testando serviço de API (simulado)...');
    
    try {
      final apiService = MonitoringApiService();
      
      // Testar verificação de servidor online
      final isOnline = await apiService.isServerOnline();
      Logger.info('$_tag: Servidor online: $isOnline');
      
      // Testar estrutura de dados para API
      final db = await AppDatabase.instance.database;
      final sessionId = await _createTestSession(db);
      final pointId = await _createTestPoint(db, sessionId);
      await _createTestOccurrences(db, pointId);
      
      // Simular dados completos da sessão
      final sessionData = await apiService._getCompleteSessionData(sessionId);
      
      if (sessionData['session'] == null || sessionData['points'] == null) {
        throw Exception('Estrutura de dados da sessão inválida');
      }
      
      Logger.info('$_tag: ✅ Estrutura de dados da API OK');
      
      // Limpar dados de teste
      await _cleanupTestData(db, sessionId);
      
      Logger.info('$_tag: ✅ Serviço de API OK');
    } catch (e) {
      Logger.error('$_tag: ❌ Erro no teste de API: $e');
      rethrow;
    }
  }

  /// Cria uma sessão de teste
  static Future<String> _createTestSession(Database db) async {
    final sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert('monitoring_sessions', {
      'id': sessionId,
      'fazenda_id': 'test_fazenda',
      'talhao_id': 'test_talhao',
      'cultura_id': 'soja',
      'amostragem_padrao_plantas_por_ponto': 10,
      'started_at': DateTime.now().toIso8601String(),
      'status': 'draft',
      'device_id': 'test_device',
      'catalog_version': '1.0.0',
      'sync_state': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    return sessionId;
  }

  /// Cria um ponto de teste
  static Future<String> _createTestPoint(Database db, String sessionId) async {
    final pointId = 'test_point_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert('monitoring_points', {
      'id': pointId,
      'session_id': sessionId,
      'numero': 1,
      'latitude': -19.231,
      'longitude': -44.119,
      'timestamp': DateTime.now().toIso8601String(),
      'plantas_avaliadas': 10,
      'gps_accuracy': 3.2,
      'manual_entry': 0,
      'sync_state': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    return pointId;
  }

  /// Cria ocorrências de teste
  static Future<void> _createTestOccurrences(Database db, String pointId) async {
    // Obter organismos do catálogo
    final organisms = await db.query('catalog_organisms', limit: 2);
    
    for (int i = 0; i < organisms.length; i++) {
      final organism = organisms[i];
      final occurrenceId = 'test_occurrence_${DateTime.now().millisecondsSinceEpoch}_$i';
      
      await db.insert('monitoring_occurrences', {
        'id': occurrenceId,
        'point_id': pointId,
        'organism_id': organism['id'],
        'valor_bruto': 15.0 + (i * 5.0), // Valores diferentes para cada organismo
        'observacao': 'Teste de ocorrência $i',
        'sync_state': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Limpa dados de teste
  static Future<void> _cleanupTestData(Database db, String sessionId) async {
    await db.delete('monitoring_sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db.delete('infestation_map', where: 'session_id = ?', whereArgs: [sessionId]);
  }
}

/// Função principal para executar os testes
Future<void> main() async {
  Logger.info('Iniciando testes de implementação do Monitoramento Avançado...');
  await TestMonitoringImplementation.runAllTests();
  Logger.info('Testes concluídos!');
}
