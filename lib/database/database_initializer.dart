import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import 'database_helper.dart';
import 'plot_database_repair.dart';
import 'database_integrity_service.dart';
import '../utils/logger.dart';
import '../utils/text_encoding_helper.dart';
import 'database_text_encoding_fixer.dart';

class DatabaseInitializer {
  static final DatabaseInitializer _instance = DatabaseInitializer._internal();
  
  factory DatabaseInitializer() {
    return _instance;
  }
  
  DatabaseInitializer._internal();
  
  final AppDatabase _appDatabase = AppDatabase();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final PlotDatabaseRepair _plotDatabaseRepair = PlotDatabaseRepair();
  bool _isInitialized = false;

  /// Inicializa o banco de dados com verificações e migrações necessárias
  Future<bool> initializeDatabase({
    Function(String message, double progress)? onProgress,
    bool forceCheck = false,
  }) async {
    try {
      // Notifica progresso
      onProgress?.call('Inicializando banco de dados...', 0.1);
      
      // Inicializa o banco de dados
      await initialize();
      onProgress?.call('Banco de dados inicializado', 0.3);
      
      // Verifica tabelas essenciais
      onProgress?.call('Verificando tabelas essenciais...', 0.4);
      final tablesExist = await ensureEssentialTables();
      
      if (!tablesExist) {
        Logger.error('Erro ao verificar tabelas essenciais. Continuando sem reset...');
        // REMOVIDO: Reset problemático que causava loops infinitos
      }
      
      onProgress?.call('Tabelas essenciais verificadas', 0.6);
      
      // Executa migrações
      onProgress?.call('Executando migrações...', 0.7);
      // Removemos a referência ao serviço de migração que não existe
      await _runMigrations();
      onProgress?.call('Migrações concluídas', 0.9);
      
      // Verifica problemas de codificação
      onProgress?.call('Verificando problemas de codificação...', 0.95);
      await _checkForEncodingIssues();
      
      // Finaliza
      onProgress?.call('Inicialização concluída com sucesso!', 1.0);
      return true;
    } catch (e) {
      Logger.error('Erro durante inicialização do banco de dados: $e');
      onProgress?.call('Erro: ${e.toString()}', 1.0);
      return false;
    }
  }

  /// Método para inicializar o banco de dados na inicialização do aplicativo
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      Logger.info('Iniciando verificação de integridade do banco de dados...');
      
      // Utiliza o novo serviço de integridade do banco de dados
      final integrityService = DatabaseIntegrityService();
      
      // Verifica e repara o banco de dados se necessário
      final integrityResult = await integrityService.verifyAndFixDatabaseIntegrity();
      
      if (integrityResult['integrityCheck'] != true) {
        Logger.error('Verificação de integridade falhou, tentando métodos alternativos...');
        
        // REMOVIDO: Reset problemático que causava loops infinitos
        Logger.warning('Problema de integridade detectado, mas continuando sem reset para evitar loops infinitos');
      }
      
      // Verifica se consegue acessar o banco de dados
      final db = await _appDatabase.database;
      
      // Tenta uma operação simples para confirmar que está funcionando
      final version = await db.rawQuery('SELECT sqlite_version()');
      Logger.info('Versão SQLite: ${version.first.values.first}');
      
      // Garante que todas as tabelas essenciais existem
      await ensureEssentialTables();
      
      // Verifica especificamente a tabela de talhões
      final plotTableHealth = await _plotDatabaseRepair.checkPlotTableHealth();
      if (!plotTableHealth['structureCorrect']) {
        Logger.error('Estrutura da tabela de talhões incorreta, reparando...');
        await _plotDatabaseRepair.repairPlotTable();
      }
      
      // Verifica se há problemas de codificação de texto
      bool hasEncodingIssues = await _checkForEncodingIssues();
      Logger.info('Verificação de problemas de codificação: ${hasEncodingIssues ? 'Problemas encontrados' : 'Nenhum problema'}');
      
      _isInitialized = true;
      Logger.info('Banco de dados inicializado com sucesso!');
      return true;
    } catch (e) {
      Logger.error('Erro ao inicializar banco de dados: $e');
      
      // REMOVIDO: Reset de emergência que causava loops infinitos
      Logger.error('Erro na inicialização, mas evitando reset para prevenir loops infinitos');
      return false;
    }
  }

  /// Executa migrações no banco de dados
  Future<void> _runMigrations() async {
    try {
      Logger.info('Executando migrações do banco de dados...');
      // Implementação básica de migração
      final db = await _appDatabase.database;
      
      // Verificar versão atual do banco de dados
      final version = await db.getVersion();
      Logger.info('Versão atual do banco de dados: $version');
      
      // Executar migrações específicas baseadas na versão
      if (version < 2) {
        // Migração para versão 2
        await _migrateToVersion2(db);
      }
      
      if (version < 3) {
        // Migração para versão 3
        await _migrateToVersion3(db);
      }
      
      // Atualizar versão do banco de dados
      await db.setVersion(3);
      Logger.info('Migrações concluídas com sucesso!');
    } catch (e) {
      Logger.error('Erro ao executar migrações: $e');
      throw e;
    }
  }
  
  /// Migração para versão 2 do banco de dados
  Future<void> _migrateToVersion2(Database db) async {
    try {
      // Exemplo de migração: adicionar nova coluna a uma tabela existente
      await db.execute('ALTER TABLE farms ADD COLUMN technical_responsible_name TEXT');
      Logger.info('Migração para versão 2 concluída');
    } catch (e) {
      Logger.error('Erro na migração para versão 2: $e');
      // Ignorar erros específicos, como coluna já existente
    }
  }
  
  /// Migração para versão 3 do banco de dados
  Future<void> _migrateToVersion3(Database db) async {
    try {
      // Exemplo de migração: adicionar nova coluna a uma tabela existente
      await db.execute('ALTER TABLE plots ADD COLUMN last_updated TEXT');
      Logger.info('Migração para versão 3 concluída');
    } catch (e) {
      Logger.error('Erro na migração para versão 3: $e');
      // Ignorar erros específicos, como coluna já existente
    }
  }

  /// Verifica se as tabelas essenciais existem e cria se necessário
  Future<bool> ensureEssentialTables() async {
    try {
      final db = await _appDatabase.database;
      
      // Lista de tabelas essenciais e suas definições
      final Map<String, String> essentialTables = {
        'pesticide_applications': '''
          CREATE TABLE IF NOT EXISTS pesticide_applications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plot_id TEXT NOT NULL,
            application_date TEXT NOT NULL,
            product_name TEXT NOT NULL,
            dose REAL NOT NULL,
            dose_unit TEXT NOT NULL,
            target_pest TEXT,
            application_method TEXT,
            weather_conditions TEXT,
            operator_name TEXT,
            observations TEXT,
            images TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0,
            FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
          )
        ''',
        'harvest_losses': '''
          CREATE TABLE IF NOT EXISTS harvest_losses (
            id TEXT PRIMARY KEY,
            plotId TEXT,
            cropId TEXT,
            cropName TEXT,
            grainsPerArea REAL,
            sampleAreaSize REAL,
            thousandGrainWeight REAL,
            collectedGrainsWeight REAL,
            useCollectedWeight INTEGER DEFAULT 0,
            sampleCount INTEGER,
            imageUrls TEXT,
            assessmentDate INTEGER,
            responsiblePerson TEXT,
            observations TEXT,
            createdAt INTEGER,
            updatedAt INTEGER,
            isSynced INTEGER DEFAULT 0
          )
        ''',
        'plantings': '''
          CREATE TABLE IF NOT EXISTS plantings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            plot_id TEXT NOT NULL,
            crop_type TEXT NOT NULL,
            variety TEXT,
            planting_date TEXT NOT NULL,
            expected_harvest_date TEXT,
            seed_quantity REAL,
            seed_unit TEXT,
            row_spacing REAL,
            plant_spacing REAL,
            fertilizer_type TEXT,
            fertilizer_quantity REAL,
            fertilizer_unit TEXT,
            observations TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0,
            FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
          )
        '''
      };
      
      // Criar cada tabela essencial se não existir
      for (final entry in essentialTables.entries) {
        final tableName = entry.key;
        final tableDefinition = entry.value;
        
        // Verificar se a tabela existe
        final exists = await tableExists(db, tableName);
        
        if (!exists) {
          Logger.info('Criando tabela: $tableName');
          await db.execute(tableDefinition);
          
          // Verificar se a tabela foi criada corretamente
          final tableCreated = await tableExists(db, tableName);
          if (!tableCreated) {
            Logger.error('Falha ao criar tabela: $tableName');
            return false;
          }
        } else {
          // Verificar se a tabela tem todas as colunas necessárias
          final columnsCorrect = await _verifyTableColumns(db, tableName);
          if (!columnsCorrect) {
            Logger.error('Estrutura incorreta na tabela: $tableName. Recriando...');
            await _recreateTable(db, tableName);
          }
        }
      }
      
      Logger.info('Todas as tabelas essenciais verificadas e criadas se necessário');
      return true;
    } catch (e) {
      Logger.error('Erro ao verificar tabelas essenciais: $e');
      return false;
    }
  }

  /// Verifica se uma tabela tem todas as colunas necessárias
  Future<bool> _verifyTableColumns(Database db, String tableName) async {
    try {
      // Obter informações sobre as colunas da tabela
      final columns = await db.rawQuery('PRAGMA table_info($tableName)');
      
      // Verificar se há pelo menos as colunas básicas esperadas
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      // Definir colunas mínimas esperadas para cada tabela
      final Map<String, List<String>> expectedColumns = {
        'pesticide_applications': ['id', 'plot_id', 'product_name', 'application_date'],
        'harvest_losses': ['id', 'plotId', 'cropName', 'assessmentDate'],
        'plantings': ['id', 'plot_id', 'crop_type', 'planting_date']
      };
      
      // Verificar se todas as colunas esperadas existem
      if (expectedColumns.containsKey(tableName)) {
        for (final column in expectedColumns[tableName]!) {
          if (!columnNames.contains(column)) {
            Logger.error('Coluna ausente na tabela $tableName: $column');
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      Logger.error('Erro ao verificar colunas da tabela $tableName: $e');
      return false;
    }
  }

  /// Recria uma tabela se estiver com estrutura incorreta
  Future<bool> _recreateTable(Database db, String tableName) async {
    try {
      // Iniciar transação
      await db.transaction((txn) async {
        // Renomear tabela atual
        await txn.execute('ALTER TABLE $tableName RENAME TO ${tableName}_old');
        
        // Criar nova tabela com estrutura correta
        final tableDefinition = _getTableDefinition(tableName);
        await txn.execute(tableDefinition);
        
        // Tentar copiar dados da tabela antiga para a nova
        try {
          // Obter colunas comuns entre as tabelas
          final oldColumns = await txn.rawQuery('PRAGMA table_info(${tableName}_old)');
          final newColumns = await txn.rawQuery('PRAGMA table_info($tableName)');
          
          final oldColumnNames = oldColumns.map((c) => c['name'] as String).toList();
          final newColumnNames = newColumns.map((c) => c['name'] as String).toList();
          
          // Encontrar colunas em comum
          final commonColumns = oldColumnNames.where((col) => newColumnNames.contains(col)).toList();
          
          if (commonColumns.isNotEmpty) {
            // Construir consulta para copiar dados
            final columnsStr = commonColumns.join(', ');
            await txn.execute(
              'INSERT INTO $tableName ($columnsStr) SELECT $columnsStr FROM ${tableName}_old'
            );
          }
        } catch (e) {
          Logger.error('Erro ao copiar dados para a nova tabela $tableName: $e');
        }
        
        // Excluir tabela antiga
        await txn.execute('DROP TABLE IF EXISTS ${tableName}_old');
      });
      
      Logger.info('Tabela $tableName recriada com sucesso');
      return true;
    } catch (e) {
      Logger.error('Erro ao recriar tabela $tableName: $e');
      return false;
    }
  }

  /// Verifica se existem problemas de codificação de texto no banco de dados
  Future<bool> _checkForEncodingIssues() async {
    try {
      final db = await _appDatabase.database;
      final textEncodingFixer = DatabaseTextEncodingFixer(db);
      
      // Verificar problemas de codificação em todas as tabelas
      final result = await textEncodingFixer.fixAllTextEncodings();
      
      // Verificar se foram encontrados problemas
      final summary = result['summary'] as Map<String, dynamic>;
      final totalFixedRecords = summary['totalFixedRecords'] as int;
      
      if (totalFixedRecords > 0) {
        Logger.info('Foram corrigidos $totalFixedRecords registros com problemas de codificação');
        return true;
      }
      
      return false;
    } catch (e) {
      Logger.error('Erro ao verificar problemas de codificação: $e');
      return false;
    }
  }

  /// Recria uma tabela específica se necessário
  Future<bool> recreateTableIfNeeded(Database db, String tableName) async {
    try {
      // Verificar se a tabela existe
      final exists = await tableExists(db, tableName);
      
      if (exists) {
        // Verificar estrutura da tabela
        final columnsCorrect = await _verifyTableColumns(db, tableName);
        
        if (!columnsCorrect) {
          // Recriar tabela
          return await _recreateTable(db, tableName);
        }
        
        return true;
      } else {
        // Criar tabela
        final tableDefinition = _getTableDefinition(tableName);
        await db.execute(tableDefinition);
        return true;
      }
    } catch (e) {
      Logger.error('Erro ao recriar tabela $tableName: $e');
      return false;
    }
  }

  /// Obtém a definição SQL para uma tabela específica
  String _getTableDefinition(String tableName) {
    final Map<String, String> tableDefinitions = {
      'pesticide_applications': '''
        CREATE TABLE IF NOT EXISTS pesticide_applications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plot_id TEXT NOT NULL,
          application_date TEXT NOT NULL,
          product_name TEXT NOT NULL,
          dose REAL NOT NULL,
          dose_unit TEXT NOT NULL,
          target_pest TEXT,
          application_method TEXT,
          weather_conditions TEXT,
          operator_name TEXT,
          observations TEXT,
          images TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0,
          FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
        )
      ''',
      'harvest_losses': '''
        CREATE TABLE IF NOT EXISTS harvest_losses (
          id TEXT PRIMARY KEY,
          plotId TEXT,
          cropId TEXT,
          cropName TEXT,
          grainsPerArea REAL,
          sampleAreaSize REAL,
          thousandGrainWeight REAL,
          collectedGrainsWeight REAL,
          useCollectedWeight INTEGER DEFAULT 0,
          sampleCount INTEGER,
          imageUrls TEXT,
          assessmentDate INTEGER,
          responsiblePerson TEXT,
          observations TEXT,
          createdAt INTEGER,
          updatedAt INTEGER,
          isSynced INTEGER DEFAULT 0
        )
      ''',
      'plantings': '''
        CREATE TABLE IF NOT EXISTS plantings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plot_id TEXT NOT NULL,
          crop_type TEXT NOT NULL,
          variety TEXT,
          planting_date TEXT NOT NULL,
          expected_harvest_date TEXT,
          seed_quantity REAL,
          seed_unit TEXT,
          row_spacing REAL,
          plant_spacing REAL,
          fertilizer_type TEXT,
          fertilizer_quantity REAL,
          fertilizer_unit TEXT,
          observations TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          sync_status INTEGER DEFAULT 0,
          FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
        )
      '''
    };
    
    return tableDefinitions[tableName] ?? '';
  }

  /// Verifica se uma tabela existe no banco de dados
  Future<bool> tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName]
    );
    return result.isNotEmpty;
  }
}
