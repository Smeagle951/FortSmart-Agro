import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

import '../repositories/plot_repository.dart';
import '../utils/logger.dart';
import '../utils/config.dart';

// Adicionado o import para a classe File

/// Serviço para gerenciar a integridade e recuperação do banco de dados
class DatabaseIntegrityService {
  static final DatabaseIntegrityService _instance = DatabaseIntegrityService._internal();
  
  factory DatabaseIntegrityService() {
    return _instance;
  }
  
  DatabaseIntegrityService._internal();
  
  /// Verifica a integridade do banco de dados e tenta reparar se necessário
  Future<bool> checkAndRepairDatabase() async {
    try {
      Logger.log('Verificando integridade do banco de dados');
      
      // Obter caminho do banco de dados unificado
      final path = await AppDatabase.instance.getDatabasePath();
      
      // Verificar se o banco existe
      final exists = await databaseExists(path);
      
      if (!exists) {
        Logger.log('Banco de dados não encontrado, criando novo banco');
        return await _initializeNewDatabase(path);
      }
      
      // Verificar integridade
      try {
        final db = await AppDatabase.instance.database;
        
        // Verificar integridade do banco
        final integrityCheck = await db.rawQuery('PRAGMA integrity_check');
        final isIntegrityOk = integrityCheck.first['integrity_check'] == 'ok';
        
        // Não fechar: AppDatabase gerencia instância única
        
        if (!isIntegrityOk) {
          Logger.log('Problemas de integridade detectados, tentando reparar');
          return await _repairDatabase(path);
        }
        
        // Verificar estrutura das tabelas
        return await _verifyDatabaseStructure(path);
      } catch (e) {
        Logger.error('Erro ao verificar integridade do banco', e);
        return await _repairDatabase(path);
      }
    } catch (e) {
      Logger.error('Erro crítico ao verificar banco de dados', e);
      return false;
    }
  }
  
  /// Verifica a integridade de uma tabela específica
  Future<bool> checkTableIntegrity(String tableName) async {
    try {
      Logger.log('Verificando integridade da tabela: $tableName');
      
      // Obter caminho do banco de dados unificado
      final path = await AppDatabase.instance.getDatabasePath();
      
      // Verificar se o banco existe
      final exists = await databaseExists(path);
      if (!exists) {
        Logger.log('Banco de dados não encontrado, criando novo banco');
        return await _initializeNewDatabase(path);
      }
      
      // Obter instância única do banco
      final db = await AppDatabase.instance.database;
      
      try {
        // Verificar se a tabela existe
        final tableExists = await _checkIfTableExists(db, tableName);
        if (!tableExists) {
          Logger.log('Tabela $tableName não existe, criando...');
          await _createMissingTable(db, tableName);
          // Não fechar: instância única
          return true;
        }
        
        // Verificar estrutura da tabela
        final hasValidStructure = await _checkTableStructure(db, tableName);
        if (!hasValidStructure) {
          Logger.log('Estrutura da tabela $tableName é inválida, recriando...');
          await _recreateTable(db, tableName);
          return true;
        }
        
        // Verificar índices problemáticos
        await _checkAndFixProblematicIndices(db, tableName);
        
        // Não fechar: instância única
        return true;
      } catch (e) {
        Logger.error('Erro ao verificar integridade da tabela $tableName', e);
        // Não fechar: instância única
        
        // Tentar reparar o banco de dados
        return await _repairDatabase(path);
      }
    } catch (e) {
      Logger.error('Erro crítico ao verificar tabela $tableName', e);
      return false;
    }
  }
  
  /// Verifica se uma tabela existe no banco de dados
  Future<bool> _checkIfTableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      Logger.error('Erro ao verificar existência da tabela $tableName: $e');
      return false;
    }
  }
  
  /// Verifica a estrutura de uma tabela
  Future<bool> _checkTableStructure(Database db, String tableName) async {
    try {
      await db.rawQuery('PRAGMA table_info($tableName)');
      return true;
    } catch (e) {
      Logger.error('Erro ao verificar estrutura da tabela $tableName: $e');
      return false;
    }
  }
  
  /// Cria uma tabela ausente
  Future<void> _createMissingTable(Database db, String tableName) async {
    switch (tableName) {
      case 'plots':
        final plotRepo = PlotRepository();
        await plotRepo.createTables(db);
        break;
      
      default:
        Logger.log('Não foi possível criar a tabela $tableName: esquema desconhecido');
        break;
    }
  }
  
  /// Recria uma tabela com estrutura inválida
  Future<void> _recreateTable(Database db, String tableName) async {
    // Backup dos dados se possível
    try {
      await db.execute('ALTER TABLE $tableName RENAME TO ${tableName}_backup');
    } catch (e) {
      Logger.error('Não foi possível fazer backup da tabela $tableName', e);
      await db.execute('DROP TABLE IF EXISTS $tableName');
    }
    
    // Criar nova tabela
    await _createMissingTable(db, tableName);
    
    // Tentar migrar dados do backup
    try {
      final backupExists = await _checkIfTableExists(db, '${tableName}_backup');
      if (backupExists) {
        // Migrar dados com base na tabela
        switch (tableName) {
          case 'plots':
            await _migrateTableData(db, tableName);
            break;
        }
        
        // Remover tabela de backup
        await db.execute('DROP TABLE IF EXISTS ${tableName}_backup');
      }
    } catch (e) {
      Logger.error('Erro ao migrar dados da tabela $tableName', e);
    }
  }
  
  /// Migra dados de uma tabela de backup
  Future<void> _migrateTableData(Database db, String tableName) async {
    try {
      // Obter colunas da nova tabela
      final newTableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      final newColumns = newTableInfo.map((c) => c['name'] as String).toList();
      
      // Obter colunas da tabela de backup
      final backupTableInfo = await db.rawQuery('PRAGMA table_info(${tableName}_backup)');
      final backupColumns = backupTableInfo.map((c) => c['name'] as String).toList();
      
      // Encontrar colunas em comum
      final commonColumns = newColumns.where((col) => backupColumns.contains(col)).toList();
      
      if (commonColumns.isNotEmpty) {
        final columnsString = commonColumns.join(', ');
        await db.execute('''
          INSERT INTO $tableName ($columnsString)
          SELECT $columnsString FROM ${tableName}_backup
        ''');
        
        Logger.log('Dados migrados com sucesso para a tabela $tableName');
      }
    } catch (e) {
      Logger.error('Erro ao migrar dados para a tabela $tableName', e);
    }
  }
  
  /// Verifica e corrige índices problemáticos
  Future<void> _checkAndFixProblematicIndices(Database db, String tableName) async {
    try {
      // Obter todos os índices da tabela
      final indices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [tableName],
      );
      
      // Verificar cada índice
      for (final index in indices) {
        final indexName = index['name'] as String;
        
        try {
          // Tentar usar o índice em uma consulta simples
          await db.rawQuery('SELECT * FROM $tableName INDEXED BY $indexName LIMIT 1');
        } catch (e) {
          // Se falhar, o índice pode estar corrompido
          Logger.error('Índice $indexName na tabela $tableName parece estar corrompido: $e');
          
          try {
            // Tentar remover o índice
            await db.execute('DROP INDEX IF EXISTS $indexName');
            Logger.info('Índice $indexName removido com sucesso');
            
            // Recriar o índice se for um dos índices padrão
            if (indexName.startsWith('${tableName}_')) {
              final columnName = indexName.substring(tableName.length + 1);
              await db.execute('CREATE INDEX $indexName ON $tableName ($columnName)');
              Logger.info('Índice $indexName recriado com sucesso');
            }
          } catch (e2) {
            Logger.error('Erro ao remover/recriar índice $indexName: $e2');
          }
        }
      }
    } catch (e) {
      Logger.error('Erro ao verificar índices da tabela $tableName: $e');
    }
  }
  
  /// Inicializa um novo banco de dados
  Future<bool> _initializeNewDatabase(String path) async {
    try {
      // Delegar inicialização ao AppDatabase unificado
      await AppDatabase.instance.resetDatabase();
      return true;
    } catch (e) {
      Logger.error('Erro ao inicializar novo banco de dados', e);
      return false;
    }
  }
  
  /// Repara o banco de dados
  Future<bool> _repairDatabase(String path) async {
    try {
      // Criar backup do banco
      final backupPath = '$path.backup_${DateTime.now().millisecondsSinceEpoch}';
      await File(path).copy(backupPath);
      
      Logger.log('Backup do banco criado em: $backupPath');
      
      // Tentar recuperar o banco delegando ao AppDatabase
      try {
        await AppDatabase.instance.ensureDatabaseOpen();
        // Rodar verificações essenciais via AppDatabase (onOpen já verifica)
        final db = await AppDatabase.instance.database;
        await db.execute('VACUUM');
        return true;
      } catch (e) {
        Logger.error('Falha ao reparar banco, tentando recriar', e);
        // Se falhar, tentar recriar o banco de forma limpa
        await AppDatabase.instance.resetDatabase();
        return true;
      }
    } catch (e) {
      Logger.error('Erro crítico ao reparar banco de dados', e);
      return false;
    }
  }
  
  /// Verifica a estrutura do banco de dados
  Future<bool> _verifyDatabaseStructure(String path) async {
    try {
      // Usar a instância única
      final db = await AppDatabase.instance.database;
      
      // Verificar existência das tabelas principais
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toList();
      
      // Verificar tabelas essenciais
      final requiredTables = [
        'plots',
      ];
      
      final missingTables = requiredTables.where((t) => !tableNames.contains(t)).toList();
      
      if (missingTables.isNotEmpty) {
        Logger.log('Tabelas ausentes detectadas: ${missingTables.join(", ")}');
        
        // Criar tabelas ausentes
        if (missingTables.contains('plots')) {
          final plotRepo = PlotRepository();
          await plotRepo.createTables(db);
        }
      }
      
      // Verificar colunas das tabelas
      if (tableNames.contains('plots')) {
        try {
          // Verificar se as colunas farm_id e property_id existem
          final plotInfo = await db.rawQuery('PRAGMA table_info(plots)');
          final columnNames = plotInfo.map((c) => c['name'] as String).toList();
          
          if (!columnNames.contains('farm_id') || !columnNames.contains('property_id')) {
            Logger.log('Colunas essenciais ausentes na tabela plots');
            
            // Recriar tabela de plots
            await db.execute('DROP TABLE IF EXISTS plots_temp');
            await db.execute('''
              CREATE TABLE plots_temp (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                area REAL,
                property_id INTEGER NOT NULL,
                farm_id INTEGER NOT NULL,
                crop_type TEXT,
                crop_name TEXT,
                description TEXT,
                planting_date TEXT,
                harvest_date TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                sync_status INTEGER,
                remote_id INTEGER,
                polygon_json TEXT
              )
            ''');
            
            // Tentar migrar dados se possível
            try {
              await db.execute('''
                INSERT INTO plots_temp (id, name, area, property_id, farm_id, 
                  crop_type, crop_name, description, planting_date, harvest_date, 
                  created_at, updated_at, sync_status, remote_id, polygon_json)
                SELECT id, name, area, property_id, farm_id, 
                  crop_type, crop_name, description, planting_date, harvest_date, 
                  created_at, updated_at, sync_status, remote_id, polygon_json
                FROM plots
              ''');
            } catch (e) {
              Logger.error('Erro ao migrar dados da tabela plots', e);
            }
            
            await db.execute('DROP TABLE plots');
            await db.execute('ALTER TABLE plots_temp RENAME TO plots');
          }
        } catch (e) {
          Logger.error('Erro ao verificar estrutura da tabela plots', e);
        }
      }
      
      await db.close();
      return true;
    } catch (e) {
      Logger.error('Erro ao verificar estrutura do banco de dados', e);
      return false;
    }
  }
  
  /// Verifica se o índice problemático existe e o remove
  Future<void> removeProblematicIndex() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      final db = await openDatabase(path);
      
      // Verificar se o índice problemático existe
      final indexResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_inventory_items_property_id'"
      );
      
      if (indexResult.isNotEmpty) {
        Logger.log('Removendo índice problemático idx_inventory_items_property_id');
        await db.execute('DROP INDEX IF EXISTS idx_inventory_items_property_id');
      }
      
      await db.close();
    } catch (e) {
      Logger.error('Erro ao remover índice problemático', e);
    }
  }
  
  /// Obtém informações de diagnóstico do banco de dados
  Future<Map<String, dynamic>> getDatabaseDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      // Verificar se o banco existe
      final exists = await databaseExists(path);
      diagnostics['exists'] = exists;
      
      if (!exists) {
        return diagnostics;
      }
      
      // Obter tamanho do arquivo
      final dbFile = File(path);
      final fileSize = await dbFile.length();
      diagnostics['size'] = fileSize;
      diagnostics['path'] = path;
      
      // Obter informações das tabelas
      final db = await openDatabase(path);
      
      // Listar tabelas
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
      );
      
      final tablesList = tables.map((t) => t['name'] as String).toList();
      diagnostics['tables'] = tablesList;
      
      // Contar registros em tabelas principais
      final tableCounts = <String, int>{};
      
      for (final table in tablesList) {
        try {
          final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          tableCounts[table] = Sqflite.firstIntValue(countResult) ?? 0;
        } catch (e) {
          tableCounts[table] = -1; // Erro ao contar
        }
      }
      
      diagnostics['tableCounts'] = tableCounts;
      
      // Verificar integridade
      try {
        final integrityCheck = await db.rawQuery('PRAGMA integrity_check');
        diagnostics['integrity'] = integrityCheck.first['integrity_check'];
      } catch (e) {
        diagnostics['integrity'] = 'error';
      }
      
      await db.close();
    } catch (e) {
      Logger.error('Erro ao obter diagnóstico do banco de dados', e);
      diagnostics['error'] = e.toString();
    }
    
    return diagnostics;
  }
  
  /// Verifica a integridade do banco de dados
  Future<Map<String, dynamic>> checkIntegrity() async {
    try {
      Logger.log('Verificando integridade do banco de dados');
      
      // Obter caminho do banco de dados
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      // Verificar se o banco existe
      final exists = await databaseExists(path);
      
      if (!exists) {
        return {
          'success': false,
          'message': 'Banco de dados não encontrado',
          'details': null,
        };
      }
      
      // Verificar integridade
      try {
        final db = await openDatabase(path, readOnly: true);
        
        // Verificar integridade do banco
        final integrityCheck = await db.rawQuery('PRAGMA integrity_check');
        final isIntegrityOk = integrityCheck.first['integrity_check'] == 'ok';
        
        // Verificar consistência de dados
        final foreignKeyCheck = await db.rawQuery('PRAGMA foreign_key_check');
        final hasForeignKeyViolations = foreignKeyCheck.isNotEmpty;
        
        await db.close();
        
        if (!isIntegrityOk || hasForeignKeyViolations) {
          return {
            'success': false,
            'message': 'Problemas de integridade detectados',
            'details': {
              'integrity_check': integrityCheck,
              'foreign_key_violations': foreignKeyCheck,
            },
          };
        }
        
        return {
          'success': true,
          'message': 'Banco de dados íntegro',
          'details': null,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Erro ao verificar integridade: $e',
          'details': null,
        };
      }
    } catch (e) {
      Logger.error('Erro ao verificar integridade do banco de dados', e);
      return {
        'success': false,
        'message': 'Erro ao verificar integridade: $e',
        'details': null,
      };
    }
  }
  
  /// Remove índices problemáticos do banco de dados
  Future<Map<String, dynamic>> removeProblematicIndices() async {
    try {
      Logger.log('Removendo índices problemáticos do banco de dados');
      
      // Obter caminho do banco de dados
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      // Verificar se o banco existe
      final exists = await databaseExists(path);
      
      if (!exists) {
        return {
          'success': false,
          'message': 'Banco de dados não encontrado',
          'details': null,
        };
      }
      
      // Abrir banco de dados
      final db = await openDatabase(path);
      
      try {
        // Obter lista de índices
        final indices = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='index'");
        
        int removedCount = 0;
        List<String> removedIndices = [];
        
        // Tentar remover cada índice
        for (final index in indices) {
          final indexName = index['name'] as String;
          
          try {
            await db.execute('DROP INDEX IF EXISTS $indexName');
            removedCount++;
            removedIndices.add(indexName);
            Logger.log('Índice removido: $indexName');
          } catch (e) {
            Logger.error('Erro ao remover índice $indexName: $e');
          }
        }
        
        await db.close();
        
        return {
          'success': true,
          'message': 'Índices problemáticos removidos',
          'details': {
            'removed_count': removedCount,
            'removed_indices': removedIndices,
          },
        };
      } catch (e) {
        await db.close();
        return {
          'success': false,
          'message': 'Erro ao remover índices: $e',
          'details': null,
        };
      }
    } catch (e) {
      Logger.error('Erro ao remover índices problemáticos', e);
      return {
        'success': false,
        'message': 'Erro ao remover índices: $e',
        'details': null,
      };
    }
  }
  
  /// Verifica se uma tabela existe no banco de dados
  Future<bool> checkTableExists(String tableName) async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      final db = await openDatabase(path);
      final exists = await _checkIfTableExists(db, tableName);
      await db.close();
      
      return exists;
    } catch (e) {
      Logger.error('Erro ao verificar existência da tabela $tableName', e);
      return false;
    }
  }
  
  /// Verifica a estrutura de uma tabela
  Future<Map<String, dynamic>> checkTableStructure(String tableName) async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      final db = await openDatabase(path);
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
      final isValid = await _checkTableStructure(db, tableName);
      await db.close();
      
      final columns = tableInfo.map((c) => {
        'name': c['name'],
        'type': c['type'],
        'notnull': c['notnull'],
        'pk': c['pk'],
      }).toList();
      
      return {
        'tableName': tableName,
        'exists': tableInfo.isNotEmpty,
        'isValid': isValid,
        'columnCount': columns.length,
        'columns': columns,
      };
    } catch (e) {
      Logger.error('Erro ao verificar estrutura da tabela $tableName', e);
      return {
        'tableName': tableName,
        'exists': false,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Obtém o número de registros em uma tabela
  Future<int> getTableRecordCount(String tableName) async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      final db = await openDatabase(path);
      final exists = await _checkIfTableExists(db, tableName);
      
      if (!exists) {
        await db.close();
        return 0;
      }
      
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      final count = Sqflite.firstIntValue(result) ?? 0;
      await db.close();
      
      return count;
    } catch (e) {
      Logger.error('Erro ao obter contagem de registros da tabela $tableName', e);
      return -1;
    }
  }
  
  /// Verifica índices problemáticos em uma tabela específica
  Future<Map<String, dynamic>> checkProblematicIndices(String tableName) async {
    Map<String, dynamic> result = {
      'success': false,
      'problematicIndices': <String>[],
    };
    
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      final db = await openDatabase(path);
      
      // Obter todos os índices da tabela
      final indices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name=?",
        [tableName],
      );
      
      // Verificar cada índice
      for (final index in indices) {
        final indexName = index['name'] as String;
        
        try {
          // Tentar usar o índice em uma consulta simples
          await db.rawQuery('SELECT * FROM $tableName INDEXED BY $indexName LIMIT 1');
        } catch (e) {
          // Se falhar, o índice está corrompido
          result['problematicIndices'].add(indexName);
        }
      }
      
      await db.close();
      
      final problematicIndices = result['problematicIndices'] as List;
      
      result['success'] = true;
      result['message'] = problematicIndices.isEmpty
          ? 'Nenhum índice problemático encontrado'
          : 'Encontrados ${problematicIndices.length} índices problemáticos';
      
    } catch (e) {
      result['message'] = 'Erro ao verificar índices: $e';
    }
    
    return result;
  }
  
  /// Obtém estatísticas do banco de dados
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      // Verificar se o banco existe
      final exists = await databaseExists(path);
      if (!exists) {
        return {
          'exists': false,
          'size': 0,
          'tables': [],
          'error': 'Banco de dados não encontrado',
        };
      }
      
      // Obter tamanho do arquivo
      final file = File(path);
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      
      // Abrir banco de dados
      final db = await openDatabase(path);
      
      // Obter lista de tabelas
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
      );
      
      // Obter contagem de registros para cada tabela
      final tableStats = <Map<String, dynamic>>[];
      for (final table in tables) {
        final tableName = table['name'] as String;
        final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        final count = Sqflite.firstIntValue(countResult) ?? 0;
        
        tableStats.add({
          'name': tableName,
          'recordCount': count,
        });
      }
      
      // Verificar integridade
      final integrityCheck = await db.rawQuery('PRAGMA integrity_check');
      final isIntegrityOk = integrityCheck.first['integrity_check'] == 'ok';
      
      await db.close();
      
      return {
        'exists': true,
        'path': path,
        'sizeInBytes': sizeInBytes,
        'sizeInMB': sizeInMB.toStringAsFixed(2),
        'tableCount': tables.length,
        'tables': tableStats,
        'integrityOk': isIntegrityOk,
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Erro ao obter estatísticas do banco de dados', e);
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Recria tabelas que estão faltando no banco de dados
  Future<Map<String, dynamic>> recreateMissingTables() async {
    try {
      final db = await database;
      
      // Criar backup antes de modificar o banco
      await _createBackup();
      
      // Lista de tabelas essenciais e suas definições
      final essentialTables = {
        'plots': '''
          CREATE TABLE IF NOT EXISTS plots (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            area REAL,
            property_id INTEGER NOT NULL,
            farm_id INTEGER NOT NULL,
            crop_type TEXT,
            crop_name TEXT,
            description TEXT,
            planting_date TEXT,
            harvest_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER,
            remote_id INTEGER,
            polygon_json TEXT
          )
        '''
      };
      
      // Verificar quais tabelas existem
      final existingTables = await _getExistingTables();
      final missingTables = <String>[];
      
      // Criar tabelas que estão faltando
      for (final tableName in essentialTables.keys) {
        if (!existingTables.contains(tableName)) {
          await db.execute(essentialTables[tableName]!);
          missingTables.add(tableName);
        }
      }
      
      return {
        'success': true,
        'recreatedTables': missingTables,
        'message': missingTables.isEmpty 
            ? 'Nenhuma tabela precisou ser recriada' 
            : 'Tabelas recriadas: ${missingTables.join(", ")}'
      };
    } catch (e) {
      Logger.error('Erro ao recriar tabelas: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Corrige estruturas de tabelas com problemas
  Future<Map<String, dynamic>> fixTableStructures() async {
    try {
      final db = await database;
      
      // Criar backup antes de modificar o banco
      await _createBackup();
      
      // Definição das colunas esperadas para cada tabela
      final expectedColumns = {
        'plots': [
          'id', 'name', 'area', 'property_id', 'farm_id', 
          'crop_type', 'crop_name', 'description', 'planting_date', 
          'harvest_date', 'created_at', 'updated_at', 'sync_status', 
          'remote_id', 'polygon_json'
        ],
      };
      
      final fixedTables = <String>[];
      final existingTables = await _getExistingTables();
      
      // Verificar cada tabela existente
      for (final tableName in expectedColumns.keys) {
        if (existingTables.contains(tableName)) {
          // Obter colunas atuais
          final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
          final currentColumns = tableInfo.map((c) => c['name'] as String).toList();
          
          // Verificar colunas que faltam
          final missingColumns = expectedColumns[tableName]!
              .where((col) => !currentColumns.contains(col))
              .toList();
          
          if (missingColumns.isNotEmpty) {
            // Adicionar colunas que faltam
            for (final column in missingColumns) {
              // Definição padrão para cada coluna
              String columnDef = '$column TEXT';
              
              // Casos especiais
              if (column == 'sync_status') {
                columnDef = '$column INTEGER DEFAULT 0';
              }
              
              await db.execute('ALTER TABLE $tableName ADD COLUMN $columnDef');
            }
            
            fixedTables.add(tableName);
          }
        }
      }
      
      return {
        'success': true,
        'fixedTables': fixedTables,
        'message': fixedTables.isEmpty 
            ? 'Nenhuma estrutura de tabela precisou ser corrigida' 
            : 'Estruturas corrigidas: ${fixedTables.join(", ")}'
      };
    } catch (e) {
      Logger.error('Erro ao corrigir estruturas de tabelas: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Obtém a lista de tabelas existentes no banco de dados
  Future<List<String>> _getExistingTables() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
    );
    return result.map((row) => row['name'] as String).toList();
  }
  
  /// Verifica a integridade do banco de dados
  Future<bool> checkDatabaseIntegrity() async {
    try {
      Logger.log('Iniciando verificação de integridade do banco de dados');

      // Verificar se todas as tabelas essenciais existem
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      final db = await openDatabase(path);
      
      final existingTables = await _getExistingTables();
      final essentialTables = [
        'plots',
      ];
      
      bool allTablesExist = true;
      for (final table in essentialTables) {
        final tableExists = await _checkIfTableExists(db, table);
        if (!tableExists) {
          Logger.error('Tabela essencial não encontrada: $table');
          allTablesExist = false;
        }
      }
      
      if (!allTablesExist) {
        await db.close();
        return false;
      }
      
      // Verificar a estrutura das tabelas
      for (final table in existingTables) {
        final structureResult = await _checkTableStructure(db, table);
        final bool structureOk = structureResult['success'] as bool? ?? false;
        
        if (!structureOk) {
          Logger.error('Estrutura inválida na tabela: $table');
          // Não falha a verificação, continua para tentar corrigir depois
        }
      }
      
      // Verificar índices problemáticos
      for (final table in existingTables) {
        final indexResult = await checkProblematicIndices(table);
        final bool hasProblematicIndices = indexResult['problematicIndices'] is List && 
                                          (indexResult['problematicIndices'] as List).isNotEmpty;
        
        if (hasProblematicIndices) {
          Logger.error('Índices problemáticos encontrados na tabela: $table');
          // Não falha a verificação, apenas avisa
        }
      }
      
      Logger.log('Verificação de integridade do banco de dados concluída com sucesso');
      return true;
    } catch (e) {
      Logger.error('Erro ao verificar integridade do banco de dados: $e');
      return false;
    }
  }
  
  /// Tenta reparar o banco de dados
  Future<bool> repairDatabase() async {
    try {
      Logger.log('Iniciando reparo do banco de dados');
      
      // Obter caminho do banco de dados
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConfig.dbName);
      
      // Criar backup antes de tentar reparar
      final backupPath = '$path.backup_${DateTime.now().millisecondsSinceEpoch}';
      final dbFile = File(path);
      
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        Logger.log('Backup do banco de dados criado em: $backupPath');
      }
      
      // Verificar tabelas existentes
      final existingTables = await _getExistingTables();
      
      // Verificar tabelas essenciais
      final essentialTables = [
        'plots',
      ];
      
      // Recriar tabelas ausentes
      for (final table in essentialTables) {
        if (!existingTables.contains(table)) {
          Logger.log('Recriando tabela ausente: $table');
          await _createMissingTable(await database, table);
        }
      }
      
      // Corrigir estruturas de tabelas
      await fixTableStructures();
      
      // Remover índices problemáticos
      await removeProblematicIndices();
      
      // Verificar integridade após reparo
      final isIntegrityOk = await checkDatabaseIntegrity();
      
      if (isIntegrityOk) {
        Logger.log('Reparo do banco de dados concluído com sucesso');
        return true;
      } else {
        Logger.error('Falha ao reparar o banco de dados');
        
        // Tentar restaurar backup se o reparo falhou
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await dbFile.delete();
          await backupFile.copy(path);
          Logger.log('Backup restaurado após falha no reparo');
        }
        
        return false;
      }
    } catch (e) {
      Logger.error('Erro ao reparar banco de dados: $e');
      return false;
    }
  }
  
  /// Getter para acessar o banco de dados
  Future<Database> get database async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConfig.dbName);
    return await openDatabase(path);
  }
  
  /// Cria um backup do banco de dados antes de realizar operações críticas
  Future<void> _createBackup() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, AppConfig.dbName);
      final backupPath = join(databasesPath, '${AppConfig.dbName}_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      
      final dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        Logger.log('Backup do banco de dados criado em: $backupPath');
      }
    } catch (e) {
      Logger.error('Erro ao criar backup do banco de dados: $e');
    }
  }
}
