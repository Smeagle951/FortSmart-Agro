import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'database_performance_monitor.dart';
import '../utils/config.dart'; // Import AppConfig
import 'migrations/talhoes_premium_migration.dart';
import 'migrations/create_missing_tables_migration.dart';
import 'app_database.dart'; // Import AppDatabase

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static bool _isInitializing = false;
  static final Completer<Database> _initCompleter = Completer<Database>();
  final DatabasePerformanceMonitor _performanceMonitor = DatabasePerformanceMonitor();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    
    // Se já estiver inicializando, aguarde a conclusão
    if (_isInitializing) {
      return _initCompleter.future;
    }
    
    _isInitializing = true;
    try {
      _database = await _initDatabase();
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(_database);
      }
      return _database!;
    } catch (e) {
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  // Método para compatibilidade com DatabaseSyncManager
  Future<Database> getDatabase() async {
    return database;
  }

  Future<Database> _initDatabase() async {
    try {
      // Usar o AppDatabase unificado em vez de criar um novo banco
      final appDatabase = AppDatabase();
      return await appDatabase.database;
    } catch (e) {
      print('Erro ao inicializar banco de dados: $e');
      // Tentar recuperar de um erro de inicialização
      await _recoverFromInitError();
      rethrow;
    }
  }

  // Configuração do banco de dados - PRAGMA deve ser executado aqui
  Future<void> _onConfigure(Database db) async {
    print('Configurando banco de dados...');
    await db.rawQuery('PRAGMA foreign_keys = ON');
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.rawQuery('PRAGMA synchronous = NORMAL');
    await db.rawQuery('PRAGMA cache_size = 1000');
    await db.rawQuery('PRAGMA temp_store = MEMORY');
    print('Banco de dados configurado com sucesso');
  }
  
  /// Verifica se o banco de dados está aberto e o reabre se necessário
  Future<Database> ensureDatabaseIsOpen() async {
    if (_database == null) {
      return database;
    }
    
    try {
      // Tenta executar uma consulta simples para verificar se o banco está aberto
      await _database!.rawQuery('SELECT 1');
      return _database!;
    } catch (e) {
      print('Banco de dados fechado, reabrindo: $e');
      _database = null;
      return database;
    }
  }
  
  Future<void> _recoverFromInitError() async {
    try {
      // Resetar a variável de banco de dados
      _database = null;
      _isInitializing = false;
      
      // Tentar limpar o arquivo de banco de dados corrompido
      final dbPath = join(await getDatabasesPath(), AppConfig.dbName); // Use AppConfig.dbName
      final file = io.File(dbPath);
      if (await file.exists()) {
        // Fazer backup do arquivo corrompido
        final backupPath = '$dbPath.bak';
        await file.copy(backupPath);
        
        // Excluir o arquivo corrompido
        await file.delete();
        
        print('Arquivo de banco de dados corrompido foi excluído e um backup foi criado em: $backupPath');
      }
    } catch (e) {
      print('Erro ao tentar recuperar de falha de inicialização: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Criando banco de dados versão $version...');
    
    // Tabela de fazendas (farms)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        logo_url TEXT,
        responsible_person TEXT,
        document_number TEXT,
        phone TEXT,
        email TEXT,
        address TEXT NOT NULL,
        total_area REAL NOT NULL,
        plots_count INTEGER NOT NULL,
        crops TEXT NOT NULL,
        cultivation_system TEXT,
        has_irrigation INTEGER NOT NULL,
        irrigation_type TEXT,
        mechanization_level TEXT,
        technical_responsible_name TEXT,
        technical_responsible_id TEXT,
        documents TEXT,
        is_verified INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        device_id TEXT
      )
    ''');

    // Tabela de talhões (plots)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        area REAL,
        coordinates TEXT,
        farmId INTEGER,
        isSynced INTEGER DEFAULT 0,
        device_id TEXT
      )
    ''');

    // Criar índice para farmId na tabela plots
    await db.execute('CREATE INDEX IF NOT EXISTS idx_plots_farm_id ON plots (farmId)');

    // Tabela de talhões premium (talhoes)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS talhoes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        idFazenda TEXT NOT NULL,
        poligonos TEXT NOT NULL,
        safras TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        device_id TEXT
      )
    ''');

    // Criar índice para idFazenda na tabela talhoes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_talhoes_fazenda_id ON talhoes (idFazenda)');

    // Tabela de culturas (crops) - CORRIGIDA: usando IF NOT EXISTS
    await db.execute('''
      CREATE TABLE IF NOT EXISTS crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        scientificName TEXT,
        category TEXT,
        isSynced INTEGER DEFAULT 0,
        device_id TEXT
      )
    ''');

    // Tabela de pragas (pests)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        scientificName TEXT,
        description TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Tabela de doenças (diseases)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diseases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        scientificName TEXT,
        description TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Tabela de plantas daninhas (weeds)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weeds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        scientificName TEXT,
        description TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Tabela de monitoramentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitorings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plotId INTEGER,
        cropId INTEGER,
        date TEXT,
        notes TEXT,
        isSynced INTEGER DEFAULT 0,
        device_id TEXT,
        FOREIGN KEY (plotId) REFERENCES plots (id),
        FOREIGN KEY (cropId) REFERENCES crops (id)
      )
    ''');

    // Tabela de pontos de monitoramento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monitoringId INTEGER,
        latitude REAL,
        longitude REAL,
        observations TEXT,
        isSynced INTEGER DEFAULT 0,
        device_id TEXT,
        FOREIGN KEY (monitoringId) REFERENCES monitorings (id)
      )
    ''');

    // Tabela de perdas na colheita
    await db.execute('''
      CREATE TABLE IF NOT EXISTS harvest_losses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plotId INTEGER,
        cropId INTEGER,
        date TEXT,
        loss_percentage REAL,
        notes TEXT,
        isSynced INTEGER DEFAULT 0,
        device_id TEXT,
        FOREIGN KEY (plotId) REFERENCES plots (id),
        FOREIGN KEY (cropId) REFERENCES crops (id)
      )
    ''');

    // Tabela de plantios
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plotId INTEGER,
        cropId INTEGER,
        planting_date TEXT,
        expected_harvest_date TEXT,
        notes TEXT,
        isSynced INTEGER DEFAULT 0,
        device_id TEXT,
        FOREIGN KEY (plotId) REFERENCES plots (id),
        FOREIGN KEY (cropId) REFERENCES crops (id)
      )
    ''');

    // Tabela de máquinas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS machines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        year INTEGER,
        serialNumber TEXT,
        status TEXT,
        lastMaintenance TEXT,
        nextMaintenance TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT DEFAULT 'pending',
        farmId TEXT,
        FOREIGN KEY (farmId) REFERENCES farms (id)
      )
    ''');

    // Criar tabelas faltantes (plantings e harvest_losses)
    await CreateMissingTablesMigration.executeMigration(db);
    
    print('Banco de dados criado com sucesso');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Atualizando banco de dados da versão $oldVersion para $newVersion');
    
    // Adicionando novas colunas à tabela machines se necessário
    if (oldVersion < 2) {
      // Adicionar coluna device_id nas tabelas
      await db.execute('ALTER TABLE plots ADD COLUMN device_id TEXT');
      await db.execute('ALTER TABLE crops ADD COLUMN device_id TEXT');
      await db.execute('ALTER TABLE monitorings ADD COLUMN device_id TEXT');
      await db.execute('ALTER TABLE monitoring_points ADD COLUMN device_id TEXT');
      
      // Verificar se a tabela farms existe e adicionar a coluna device_id
      try {
        await db.execute('ALTER TABLE farms ADD COLUMN device_id TEXT');
      } catch (e) {
        // A tabela farms pode não existir ainda
        print('Tabela farms não encontrada: $e');
      }
    }
    
    // Adicionar coluna isSynced nas tabelas (versão 3)
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE monitorings ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE monitoring_points ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE harvest_losses ADD COLUMN isSynced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE plantings ADD COLUMN isSynced INTEGER DEFAULT 0');
      } catch (e) {
        print('Erro ao adicionar coluna isSynced: $e');
      }
    }
    
    // Migração para versão 4 - Garantir que todas as tabelas usem IF NOT EXISTS
    if (oldVersion < 4) {
      print('Migração para versão 4: Verificando estrutura das tabelas...');
      
      // Verificar e recriar tabelas se necessário
      await _verifyAndRecreateTables(db);
      
      // Criar tabelas faltantes (plantings e harvest_losses)
      await CreateMissingTablesMigration.executeMigration(db);
      
      print('Migração para versão 4 concluída');
    }
    
    print('Atualização do banco de dados concluída');
  }

  // Método para verificar e recriar tabelas se necessário
  Future<void> _verifyAndRecreateTables(Database db) async {
    try {
      // Lista de tabelas essenciais
      final essentialTables = [
        'farms', 'plots', 'crops', 'pests', 'diseases', 'weeds',
        'monitorings', 'monitoring_points', 'harvest_losses', 'plantings', 'machines'
      ];

      for (final tableName in essentialTables) {
        final tables = await db.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', tableName],
        );

        if (tables.isEmpty) {
          print('Tabela $tableName não encontrada durante migração. Recriando...');
          // A tabela será recriada no próximo onCreate ou pode ser recriada aqui
        }
      }
    } catch (e) {
      print('Erro ao verificar tabelas durante migração: $e');
    }
  }

  /// Recria a tabela de máquinas
  Future<void> _recreateMachinesTable(Database db) async {
    try {
      // Criar tabela temporária
      await db.execute('''
        CREATE TABLE IF NOT EXISTS machines_temp (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT,
          brand TEXT,
          model TEXT,
          year INTEGER,
          licensePlate TEXT,
          serialNumber TEXT,
          status TEXT,
          lastMaintenanceDate TEXT,
          nextMaintenanceDate TEXT,
          notes TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncStatus TEXT,
          remoteId TEXT
        )
      ''');
      
      // Copiar dados da tabela original para a temporária
      await db.execute('''
        INSERT OR IGNORE INTO machines_temp
        SELECT * FROM machines
      ''');
      
      // Excluir tabela original
      await db.execute('DROP TABLE IF EXISTS machines');
      
      // Recriar tabela original
      await db.execute('''
        CREATE TABLE IF NOT EXISTS machines (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT,
          brand TEXT,
          model TEXT,
          year INTEGER,
          licensePlate TEXT,
          serialNumber TEXT,
          status TEXT,
          lastMaintenanceDate TEXT,
          nextMaintenanceDate TEXT,
          notes TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncStatus TEXT,
          remoteId TEXT
        )
      ''');
      
      // Copiar dados de volta para a tabela original
      await db.execute('''
        INSERT OR IGNORE INTO machines
        SELECT * FROM machines_temp
      ''');
      
      // Excluir tabela temporária
      await db.execute('DROP TABLE IF EXISTS machines_temp');
      
      // Criar índices
      await db.execute('CREATE INDEX IF NOT EXISTS idx_machines_type ON machines (type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_machines_status ON machines (status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_machines_syncStatus ON machines (syncStatus)');
      
    } catch (e) {
      print('Erro ao recriar tabela de máquinas: $e');
      rethrow;
    }
  }

  /// Recria a tabela de máquinas
  Future<bool> recreateMachinesTable(Database db) async {
    final batch = db.batch();
    try {
      // Verificar se a tabela existe
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='machines'");
      if (tables.isEmpty) {
        // Se a tabela não existe, apenas criar
        await db.execute('''
          CREATE TABLE machines(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            model TEXT,
            manufacturer TEXT,
            year INTEGER,
            serialNumber TEXT,
            status TEXT,
            lastMaintenance TEXT,
            nextMaintenance TEXT,
            notes TEXT,
            imageUrl TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        return true;
      }

      // Criar tabela temporária
      await db.execute('''
        CREATE TABLE machines_temp(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          model TEXT,
          manufacturer TEXT,
          year INTEGER,
          serialNumber TEXT,
          status TEXT,
          lastMaintenance TEXT,
          nextMaintenance TEXT,
          notes TEXT,
          imageUrl TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT
        )
      ''');

      // Copiar dados para tabela temporária
      await db.execute('''
        INSERT INTO machines_temp
        SELECT id, name, type, model, manufacturer, year, serialNumber, status, 
               lastMaintenance, nextMaintenance, notes, imageUrl, createdAt, updatedAt
        FROM machines
      ''');

      // Remover tabela original
      await db.execute('DROP TABLE machines');

      // Criar nova tabela
      await db.execute('''
        CREATE TABLE machines(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          model TEXT,
          manufacturer TEXT,
          year INTEGER,
          serialNumber TEXT,
          status TEXT,
          lastMaintenance TEXT,
          nextMaintenance TEXT,
          notes TEXT,
          imageUrl TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT
        )
      ''');

      // Copiar dados de volta
      await db.execute('''
        INSERT INTO machines
        SELECT id, name, type, model, manufacturer, year, serialNumber, status, 
               lastMaintenance, nextMaintenance, notes, imageUrl, createdAt, updatedAt
        FROM machines_temp
      ''');

      // Remover tabela temporária
      await db.execute('DROP TABLE machines_temp');

      return true;
    } catch (e) {
      print('Erro ao recriar tabela de máquinas: $e');
      return false;
    }
  }

  // Método para limpar o banco de dados (apenas para testes)
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('pesticide_applications');
    await db.delete('harvest_losses');
    // Removida referência a soil_samples
    await db.delete('plantings');
    await db.delete('machines');
    await db.delete('monitoring_points');
    await db.delete('monitorings');
    await db.delete('weeds');
    await db.delete('diseases');
    await db.delete('pests');
    await db.delete('crops');
    await db.delete('plots');
    await db.delete('farms');
  }

  /// Verifica a saúde do banco de dados
  Future<bool> checkDatabaseHealth() async {
    try {
      final db = await database;
      
      // Verificar se o banco está aberto
      if (!db.isOpen) {
        print('Banco de dados não está aberto');
        return false;
      }
      
      // Executar uma consulta simples para verificar se está funcionando
      final result = await db.rawQuery('SELECT 1');
      if (result.isEmpty) {
        print('Consulta de teste falhou');
        return false;
      }
      
      // Verificar se as tabelas essenciais existem
      final essentialTables = [
        'farms', 'plots', 'crops', 'pests', 'diseases', 'weeds',
        'monitorings', 'monitoring_points', 'harvest_losses', 'plantings', 'machines'
      ];
      
      for (final tableName in essentialTables) {
        final tables = await db.query(
          'sqlite_master',
          where: 'type = ? AND name = ?',
          whereArgs: ['table', tableName],
        );
        
        if (tables.isEmpty) {
          print('Tabela essencial $tableName não encontrada');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Erro ao verificar saúde do banco de dados: $e');
      return false;
    }
  }
  
  /// Obtém informações de diagnóstico do banco de dados
  Future<String> getDatabaseDiagnostics() async {
    try {
      final db = await database;
      final diagnostics = StringBuffer();
      
      // Lista de tabelas a verificar
      final tables = [
        'machines',
        'crops',
        'plots',
        'monitorings',
        'monitoring_points',
        // Removida referência a soil_samples
        'harvest_losses',
        'plantings'
      ];
      
      diagnostics.writeln('Diagnóstico do Banco de Dados:');
      diagnostics.writeln('----------------------------');
      
      // Verificar cada tabela
      for (final table in tables) {
        try {
          // Verificar se a tabela existe
          final tableCheck = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
          );
          
          if (tableCheck.isEmpty) {
            diagnostics.writeln('❌ Tabela $table não existe');
            continue;
          }
          
          // Obter informações sobre as colunas da tabela
          final tableInfo = await db.rawQuery('PRAGMA table_info($table)');
          final columns = tableInfo.map((col) => col['name'] as String).toList();
          
          diagnostics.writeln('✅ Tabela $table encontrada');
          diagnostics.writeln('   Colunas: ${columns.join(', ')}');
          
          // Verificar número de registros
          final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          final count = Sqflite.firstIntValue(countResult) ?? 0;
          diagnostics.writeln('   Registros: $count');
          
        } catch (e) {
          diagnostics.writeln('❌ Erro ao verificar tabela $table: $e');
        }
        
        diagnostics.writeln('----------------------------');
      }
      
      return diagnostics.toString();
    } catch (e) {
      return 'Erro ao obter diagnóstico: $e';
    }
  }
  
  /// Repara o banco de dados
  Future<void> repairDatabase() async {
    try {
      final db = await database;
      
      // Verificar e reparar a tabela machines
      try {
        // Verificar se a tabela existe
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='machines'"
        );
        
        if (result.isEmpty) {
          // Criar a tabela se não existir
          await db.execute('''
            CREATE TABLE machines (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              brand TEXT,
              model TEXT,
              year INTEGER,
              serialNumber TEXT,
              status TEXT,
              lastMaintenance TEXT,
              nextMaintenance TEXT,
              notes TEXT,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              syncStatus TEXT DEFAULT 'pending',
              farmId TEXT,
              FOREIGN KEY (farmId) REFERENCES farms (id)
            )
          ''');
        } else {
          // Verificar e adicionar colunas faltantes
          await _recreateMachinesTable(db);
        }
      } catch (e) {
        print('Erro ao reparar tabela machines: $e');
      }
      
      // Aqui você pode adicionar reparos para outras tabelas conforme necessário
      
      print('Reparo do banco de dados concluído');
    } catch (e) {
      print('Erro ao reparar banco de dados: $e');
      throw Exception('Falha ao reparar banco de dados: $e');
    }
  }
  
  /// Verifica se um erro é recuperável para tentativas
  bool _isRetryableError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('database is locked') ||
           errorMessage.contains('database disk image is malformed') ||
           errorMessage.contains('no such table') ||
           errorMessage.contains('disk i/o error') ||
           errorMessage.contains('database or disk is full');
  }
  
  Future<bool> verifyTableStructure(String tableName, List<String> expectedColumns) async {
    try {
      final db = await database;
      
      // Verifica se a tabela existe
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName]
      );
      
      if (tableCheck.isEmpty) {
        return false;
      }
      
      // Obter informações sobre as colunas
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      final columns = tableInfo.map((col) => col['name'] as String).toList();
      
      // Verifica se todas as colunas esperadas existem
      for (final column in expectedColumns) {
        if (!columns.contains(column)) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Erro ao verificar estrutura da tabela $tableName: $e');
      return false;
    }
  }

  /// Recria o banco de dados do zero (ATENÇÃO: todos os dados serão perdidos)
  Future<void> recreateDatabase() async {
    try {
      // Fechar conexão com o banco de dados
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Obter o caminho do banco de dados
      final dbPath = join(await getDatabasesPath(), AppConfig.dbName); // Use AppConfig.dbName
      
      // Excluir o arquivo do banco de dados
      if (await io.File(dbPath).exists()) {
        await io.File(dbPath).delete();
        print('Banco de dados excluído com sucesso');
      }
      
      // Recriar o banco de dados
      _database = await _initDatabase();
      print('Banco de dados recriado com sucesso');
      
      return;
    } catch (e) {
      print('Erro ao recriar banco de dados: $e');
      throw Exception('Falha ao recriar banco de dados: $e');
    }
  }

  /// Executa uma operação de banco de dados com retry automático
  Future<T> executeWithRetry<T>(Future<T> Function(Database) operation, {int maxRetries = 3}) async {
    Database? db;
    int retryCount = 0;
    
    while (true) {
      try {
        db = await database;
        
        // Monitora o desempenho da consulta
        final queryId = _performanceMonitor.startQuery('executeWithRetry');
        
        try {
          final result = await operation(db);
          _performanceMonitor.endQuery(queryId);
          return result;
        } catch (e) {
          _performanceMonitor.endQuery(queryId, error: e);
          throw e;
        }
      } catch (e) {
        retryCount++;
        
        if (e is DatabaseException) {
          // Verifica se é um erro que pode ser resolvido com retry
          if (_isRetryableError(e) && retryCount <= maxRetries) {
            print('Erro retryable no banco de dados: ${e.toString()}. Tentativa $retryCount de $maxRetries');
            await Future.delayed(Duration(milliseconds: 200 * retryCount));
            
            // Se for o último retry, tente reparar o banco
            if (retryCount == maxRetries - 1) {
              try {
                await repairDatabase();
              } catch (repairError) {
                print('Erro ao tentar reparar o banco de dados: $repairError');
              }
            }
            
            continue;
          }
        }
        
        // Se chegou aqui, é um erro não retryable ou excedeu o número de tentativas
        print('Erro não retryable ou máximo de tentativas excedido: ${e.toString()}');
        rethrow;
      }
    }
  }

  /// Executa uma operação dentro de uma transação
  Future<T> executeInTransaction<T>(Future<T> Function(Transaction) operation) async {
    return executeWithRetry((db) async {
      return await db.transaction((txn) async {
        return await operation(txn);
      });
    });
  }

  /// Obtém estatísticas de desempenho do banco de dados
  Map<String, dynamic> getDatabasePerformanceStats() {
    return {
      'general': _performanceMonitor.getGeneralStats(),
      'slowestQueries': _performanceMonitor.getSlowestQueries(),
      'mostFrequentQueries': _performanceMonitor.getMostFrequentQueries(),
      'errorProneQueries': _performanceMonitor.getMostErrorProneQueries(),
      'recentSlowQueries': _performanceMonitor.getRecentSlowQueries(),
    };
  }

  /// Ativa ou desativa o monitoramento de desempenho
  void setPerformanceMonitoring(bool enabled) {
    _performanceMonitor.enabled = enabled;
  }

  /// Define o limite para considerar uma consulta como lenta (em milissegundos)
  void setSlowQueryThreshold(int thresholdMs) {
    _performanceMonitor.slowQueryThresholdMs = thresholdMs;
  }

  /// Limpa todas as estatísticas de desempenho
  void resetPerformanceStats() {
    _performanceMonitor.reset();
  }

  /// Retorna o caminho do banco de dados
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, AppConfig.dbName); // Use AppConfig.dbName
  }
  
  /// Retorna o arquivo do banco de dados
  Future<io.File> getDatabaseFile() async {
    final dbPath = await getDatabasePath();
    return io.File(dbPath);
  }
  
  /// Reseta o banco de dados, excluindo o arquivo atual e criando um novo
  Future<void> resetDatabase() async {
    try {
      // Fechar a conexão com o banco de dados atual
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Excluir o arquivo do banco de dados
      final dbPath = await getDatabasePath();
      final dbFile = io.File(dbPath);
      
      if (await dbFile.exists()) {
        // Fazer backup antes de excluir
        final backupPath = '$dbPath.backup_reset_${DateTime.now().millisecondsSinceEpoch}';
        await dbFile.copy(backupPath);
        
        // Excluir o arquivo
        await dbFile.delete();
      }
      
      // Reinicializar o banco de dados
      _database = await _initDatabase();
      
      return;
    } catch (e) {
      print('Erro ao resetar banco de dados: $e');
      rethrow;
    }
  }
}
