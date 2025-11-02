import '../database/monitoring_tables_creator.dart';
import '../services/monitoring_session_service.dart';
import '../utils/logger.dart';

/// Script para inicializar o sistema de monitoramento completo
/// Executa todas as configurações necessárias
class MonitoringSystemInitializer {
  static const String _tag = 'MonitoringSystemInitializer';
  
  final MonitoringTablesCreator _tablesCreator = MonitoringTablesCreator();
  final MonitoringSessionService _sessionService = MonitoringSessionService();

  /// Inicializa todo o sistema de monitoramento
  Future<void> initializeCompleteSystem() async {
    try {
      Logger.info('$_tag: 🚀 Iniciando sistema de monitoramento completo...');
      
      // 1. Criar todas as tabelas
      await _createAllTables();
      
                   // 2. Inicializar dados reais
             await _initializeRealData();
      
      // 3. Testar funcionalidades básicas
      await _testBasicFunctionality();
      
      Logger.info('$_tag: ✅ Sistema de monitoramento inicializado com sucesso!');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao inicializar sistema: $e');
      rethrow;
    }
  }

  /// Cria todas as tabelas necessárias
  Future<void> _createAllTables() async {
    try {
      Logger.info('$_tag: 📋 Criando tabelas...');
      
      await _tablesCreator.createAllTables();
      
      // Verificar se as tabelas foram criadas
      final tablesExist = await _tablesCreator.checkTablesExist();
      if (!tablesExist) {
        throw Exception('Falha ao criar tabelas');
      }
      
      Logger.info('$_tag: ✅ Tabelas criadas com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao criar tabelas: $e');
      rethrow;
    }
  }

           /// Inicializa dados reais do sistema
         Future<void> _initializeRealData() async {
           try {
             Logger.info('$_tag: 📊 Inicializando dados reais do sistema...');
             
             // Inicializar catálogo de organismos com dados reais
             await _tablesCreator.initializeOrganismCatalog();
             
             Logger.info('$_tag: ✅ Dados reais inicializados');
             
           } catch (e) {
             Logger.error('$_tag: ❌ Erro ao inicializar dados reais: $e');
             rethrow;
           }
         }

  /// Testa funcionalidades básicas
  Future<void> _testBasicFunctionality() async {
    try {
      Logger.info('$_tag: 🧪 Testando funcionalidades básicas...');
      
      // Teste 1: Criar sessão
      final sessionId = await _sessionService.createSession(
        fazendaId: '1',
        talhaoId: '1',
        culturaId: '1',
        culturaNome: 'Soja',
        amostragemPadraoPlantasPorPonto: 10,
        deviceId: 'test_device',
      );
      
      Logger.info('$_tag: ✅ Sessão criada: $sessionId');
      
      // Teste 2: Adicionar ponto
      final pointId = await _sessionService.addPoint(
        sessionId: sessionId,
        numero: 1,
        latitude: -19.231,
        longitude: -44.119,
        plantasAvaliadas: 10,
        gpsAccuracy: 5.0,
        observacoes: 'Ponto de teste',
      );
      
      Logger.info('$_tag: ✅ Ponto adicionado: $pointId');
      
                   // Teste 3: Adicionar ocorrência
             // Buscar um organismo real do catálogo
             final organisms = await _sessionService.getOrganismsForCrop('1');
             if (organisms.isNotEmpty) {
               final organism = organisms.first;
               final occurrenceId = await _sessionService.addOccurrence(
                 pointId: pointId,
                 organismId: organism.id,
                 valorBruto: 5.0,
                 observacao: 'Ocorrência de teste',
               );
               
               Logger.info('$_tag: ✅ Ocorrência adicionada: $occurrenceId (${organism.name})');
             } else {
               Logger.warning('$_tag: ⚠️ Nenhum organismo encontrado para cultura 1');
             }
      
              // Remover linha duplicada
      
      // Teste 4: Finalizar sessão
      final result = await _sessionService.finalizeSession(sessionId);
      
      Logger.info('$_tag: ✅ Sessão finalizada com sucesso');
      Logger.info('$_tag: 📊 Resultado: ${result['resumo_por_organismo'].length} organismos analisados');
      
      // Teste 5: Buscar dados de infestação
      final infestationData = await _sessionService.getInfestationData('1');
      
      if (infestationData != null) {
        Logger.info('$_tag: ✅ Dados de infestação obtidos');
        Logger.info('$_tag: 📍 Pontos: ${infestationData['pontos'].length}');
        Logger.info('$_tag: 🦠 Organismos: ${infestationData['organismos'].length}');
      }
      
      Logger.info('$_tag: ✅ Todos os testes passaram!');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro nos testes: $e');
      rethrow;
    }
  }

  /// Limpa todos os dados (apenas para desenvolvimento)
  Future<void> clearAllData() async {
    try {
      Logger.info('$_tag: 🗑️ Limpando todos os dados...');
      
      await _tablesCreator.clearAllTables();
      
      Logger.info('$_tag: ✅ Dados limpos com sucesso');
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao limpar dados: $e');
      rethrow;
    }
  }

  /// Verifica status do sistema
  Future<Map<String, dynamic>> checkSystemStatus() async {
    try {
      final status = <String, dynamic>{};
      
      // Verificar tabelas
      status['tables_exist'] = await _tablesCreator.checkTablesExist();
      
      // Verificar sessões
      final sessions = await _sessionService.getSessions();
      status['sessions_count'] = sessions.length;
      
      // Verificar dados de infestação
      final infestationData = await _sessionService.getInfestationData('1');
      status['has_infestation_data'] = infestationData != null;
      
      return status;
      
    } catch (e) {
      Logger.error('$_tag: ❌ Erro ao verificar status: $e');
      return {'error': e.toString()};
    }
  }
}

/// Função principal para executar a inicialização
Future<void> initializeMonitoringSystem() async {
  final initializer = MonitoringSystemInitializer();
  await initializer.initializeCompleteSystem();
}
