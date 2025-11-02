import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../database/migration/agriculture_integration_migration.dart';
import '../utils/logger.dart';
import './module_integration_service.dart';

/// Serviço responsável por gerenciar a integração entre os módulos agrícolas
/// Inicializa as migrações de banco de dados e prepara a aplicação para o uso
/// integrado do contexto agrícola (Talhão + Safra + Cultura)
class AgricultureIntegrationService {
  final Logger _logger = Logger('AgricultureIntegrationService');
  final ModuleIntegrationService _moduleIntegrationService = ModuleIntegrationService();
  
  /// Singleton para acesso global
  static final AgricultureIntegrationService _instance = AgricultureIntegrationService._internal();
  factory AgricultureIntegrationService() => _instance;
  AgricultureIntegrationService._internal();
  
  /// Flag para controle de inicialização
  bool _initialized = false;
  bool get isInitialized => _initialized;
  
  /// Inicializa o serviço e executa as migrações necessárias
  Future<void> initialize() async {
    if (_initialized) {
      Logger.info('Serviço de integração agrícola já inicializado.');
      return;
    }
    
    try {
      Logger.info('Iniciando serviço de integração agrícola...');
      
      // Inicializar banco de dados
      final Database db = await AppDatabase.instance.database;
      
      // Executar migrações para adicionar campos de contexto
      final migration = AgricultureIntegrationMigration(db);
      await migration.migrateAll();
      
      // Inicializar a tabela de atividades e outros componentes
      await _moduleIntegrationService.initializeDatabase();
      
      // Inicializar o serviço de integração entre módulos
      await _moduleIntegrationService.initialize();
      
      _initialized = true;
      Logger.info('Serviço de integração agrícola inicializado com sucesso.');
    } catch (e) {
      Logger.error('Erro ao inicializar serviço de integração agrícola: $e');
      rethrow;
    }
  }
  
  /// Verifica se as tabelas do banco de dados possuem os campos de contexto
  /// necessários para a integração entre módulos
  Future<Map<String, bool>> verificarIntegracao() async {
    try {
      Logger.info('Verificando integração das tabelas agrícolas...');
      
      final Database db = await AppDatabase.instance.database;
      final Map<String, bool> status = {};
      
      // Tabelas para verificar
      final tabelas = [
        'plantio',
        'colheita',
        'monitoramento',
        'aplicacao',
        'historico_atividades',
      ];
      
      // Colunas que devem existir
      final colunas = ['talhaoId', 'safraId', 'culturaId'];
      
      // Verificar cada tabela
      for (final tabela in tabelas) {
        try {
          final result = await db.rawQuery("PRAGMA table_info($tabela)");
          final colunasExistentes = result.map((col) => col['name'] as String).toList();
          
          // Verificar se todas as colunas necessárias existem
          final todasColunasExistem = colunas.every((col) => colunasExistentes.contains(col));
          status[tabela] = todasColunasExistem;
        } catch (e) {
          Logger.error('Erro ao verificar tabela $tabela: $e');
          status[tabela] = false;
        }
      }
      
      return status;
    } catch (e) {
     Logger.error('Erro ao verificar integração das tabelas agrícolas: $e');
      return {};
    }
  }
  
  /// Executa a migração manual para adicionar as colunas de contexto às tabelas
  /// Útil para situações em que a migração automática falhou
  Future<void> executarMigracaoManual() async {
    try {
      Logger.info('Executando migração manual das tabelas agrícolas...');
      
      final Database db = await AppDatabase.instance.database;
      final migration = AgricultureIntegrationMigration(db);
      await migration.migrateAll();
      
      Logger.info('Migração manual concluída com sucesso.');
    } catch (e) {
      Logger.error('Erro ao executar migração manual: $e');
      rethrow;
    }
  }
}
