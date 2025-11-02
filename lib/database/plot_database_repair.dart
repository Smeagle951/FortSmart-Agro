import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import 'database_helper.dart';
import 'daos/plot_dao.dart';

/// Classe especializada para verificar e reparar problemas específicos
/// relacionados à tabela de talhões (plots) no banco de dados.
class PlotDatabaseRepair {
  final AppDatabase _appDatabase = AppDatabase();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final PlotDao _plotDao = PlotDao();

  /// Verifica e corrige problemas específicos na tabela de talhões
  Future<bool> repairPlotTable() async {
    debugPrint('Iniciando verificação e reparo da tabela de talhões...');
    
    try {
      final db = await _appDatabase.database;
      
      // Verifica se a tabela existe
      final tableExists = await _checkTableExists(db, 'plots');
      if (!tableExists) {
        debugPrint('Tabela de talhões não existe. Criando...');
        await _createPlotsTable(db);
      }
      
      // Verifica a estrutura da tabela
      final hasCorrectStructure = await _checkTableStructure(db);
      if (!hasCorrectStructure) {
        debugPrint('Estrutura da tabela de talhões incorreta. Recriando...');
        await _recreatePlotsTable(db);
      }
      
      // Verifica e corrige problemas de dados
      await _fixDataIssues(db);
      
      debugPrint('✅ Verificação e reparo da tabela de talhões concluídos com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ Erro durante o reparo da tabela de talhões: $e');
      return false;
    }
  }
  
  /// Verifica se a tabela existe no banco de dados
  Future<bool> _checkTableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
    return result.isNotEmpty;
  }
  
  /// Verifica se a estrutura da tabela está correta
  Future<bool> _checkTableStructure(Database db) async {
    try {
      // Verifica se as colunas necessárias existem
      final columns = await db.rawQuery('PRAGMA table_info(plots)');
      
      // Lista de colunas obrigatórias
      final requiredColumns = [
        'id', 'property_id', 'farm_id', 'name', 'area', 
        'polygon_json', 'created_at', 'updated_at', 'sync_status'
      ];
      
      // Verifica se todas as colunas obrigatórias existem
      final columnNames = columns.map((c) => c['name'].toString()).toList();
      for (final column in requiredColumns) {
        if (!columnNames.contains(column)) {
          debugPrint('Coluna obrigatória não encontrada: $column');
          return false;
        }
      }
      
      // Verifica se a chave primária está correta
      final primaryKey = columns.firstWhere(
        (c) => c['pk'] == 1, 
        orElse: () => {}
      );
      
      if (primaryKey.isEmpty || primaryKey['name'] != 'id') {
        debugPrint('Chave primária incorreta ou não encontrada');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Erro ao verificar estrutura da tabela: $e');
      return false;
    }
  }
  
  /// Cria a tabela de talhões
  Future<void> _createPlotsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plots (
        id TEXT PRIMARY KEY,
        property_id INTEGER NOT NULL,
        farm_id INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        area REAL,
        crop_type TEXT,
        planting_date TEXT,
        harvest_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        remote_id INTEGER,
        polygon_json TEXT
      )
    ''');
  }
  
  /// Recria a tabela de talhões preservando os dados
  Future<void> _recreatePlotsTable(Database db) async {
    // Cria uma tabela temporária com a estrutura correta
    await db.execute('''
      CREATE TABLE plots_temp (
        id TEXT PRIMARY KEY,
        property_id INTEGER NOT NULL,
        farm_id INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        area REAL,
        crop_type TEXT,
        planting_date TEXT,
        harvest_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        remote_id INTEGER,
        polygon_json TEXT
      )
    ''');
    
    // Tenta migrar os dados da tabela antiga
    try {
      // Obtém as colunas existentes na tabela antiga
      final columns = await db.rawQuery('PRAGMA table_info(plots)');
      final columnNames = columns.map((c) => c['name'].toString()).toList();
      
      // Cria uma lista de colunas que existem em ambas as tabelas
      final commonColumns = [
        'id', 'name', 'area', 'polygon_json', 'created_at', 
        'updated_at', 'sync_status', 'remote_id'
      ].where((col) => columnNames.contains(col)).toList();
      
      // Adiciona property_id e farm_id se existirem ou com valores padrão
      final hasPropertyId = columnNames.contains('property_id');
      final hasFarmId = columnNames.contains('farm_id');
      
      // Constrói a consulta de inserção
      final columnsString = commonColumns.join(', ');
      final selectColumnsString = commonColumns.join(', ');
      
      // Migra os dados
      if (hasPropertyId && hasFarmId) {
        await db.execute('''
          INSERT INTO plots_temp (
            $columnsString, property_id, farm_id
          )
          SELECT $selectColumnsString, property_id, farm_id FROM plots
        ''');
      } else if (hasPropertyId) {
        await db.execute('''
          INSERT INTO plots_temp (
            $columnsString, property_id, farm_id
          )
          SELECT $selectColumnsString, property_id, 0 FROM plots
        ''');
      } else if (hasFarmId) {
        await db.execute('''
          INSERT INTO plots_temp (
            $columnsString, property_id, farm_id
          )
          SELECT $selectColumnsString, 0, farm_id FROM plots
        ''');
      } else {
        await db.execute('''
          INSERT INTO plots_temp (
            $columnsString, property_id, farm_id
          )
          SELECT $selectColumnsString, 0, 0 FROM plots
        ''');
      }
      
      debugPrint('Dados migrados com sucesso para a tabela temporária');
    } catch (e) {
      debugPrint('Erro ao migrar dados: $e');
      // Continua mesmo com erro, pois precisamos recriar a tabela
    }
    
    // Exclui a tabela antiga
    await db.execute('DROP TABLE plots');
    
    // Renomeia a tabela temporária
    await db.execute('ALTER TABLE plots_temp RENAME TO plots');
    
    debugPrint('Tabela de talhões recriada com sucesso');
  }
  
  /// Corrige problemas específicos nos dados
  Future<void> _fixDataIssues(Database db) async {
    try {
      // Corrige registros com farmId nulo
      await db.execute('''
        UPDATE plots SET farm_id = 0 WHERE farm_id IS NULL
      ''');
      
      // Corrige registros com property_id nulo
      await db.execute('''
        UPDATE plots SET property_id = 0 WHERE property_id IS NULL
      ''');
      
      // Corrige registros com datas inválidas
      final now = DateTime.now().toIso8601String();
      await db.execute('''
        UPDATE plots SET created_at = ? WHERE created_at IS NULL
      ''', [now]);
      
      await db.execute('''
        UPDATE plots SET updated_at = ? WHERE updated_at IS NULL
      ''', [now]);
      
      debugPrint('Problemas de dados corrigidos');
    } catch (e) {
      debugPrint('Erro ao corrigir problemas de dados: $e');
    }
  }
  
  /// Método público para verificar a saúde da tabela de talhões
  Future<Map<String, dynamic>> checkPlotTableHealth() async {
    final result = {
      'tableExists': false,
      'structureCorrect': false,
      'recordCount': 0,
      'issues': <String>[],
    };
    
    try {
      final db = await _appDatabase.database;
      
      // Verifica se a tabela existe
      final tableExists = await _checkTableExists(db, 'plots');
      result['tableExists'] = tableExists;
      if (!tableExists) {
        final issues = result['issues'] as List<String>;
        issues.add('Tabela de talhões não existe');
        result['issues'] = issues;
        return result;
      }
      
      // Verifica a estrutura
      final structureCorrect = await _checkTableStructure(db);
      result['structureCorrect'] = structureCorrect;
      if (!structureCorrect) {
        final issues = result['issues'] as List<String>;
        issues.add('Estrutura da tabela incorreta');
        result['issues'] = issues;
      }
      
      // Conta registros
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM plots');
      result['recordCount'] = Sqflite.firstIntValue(countResult) ?? 0;
      
      // Verifica problemas específicos
      final nullFarmIds = await db.rawQuery('SELECT COUNT(*) as count FROM plots WHERE farm_id IS NULL');
      final nullFarmCount = Sqflite.firstIntValue(nullFarmIds) ?? 0;
      if (nullFarmCount > 0) {
        final issues = result['issues'] as List<String>;
        issues.add('$nullFarmCount registros com farm_id nulo');
        result['issues'] = issues;
      }
      
      final nullPropertyIds = await db.rawQuery('SELECT COUNT(*) as count FROM plots WHERE property_id IS NULL');
      final nullPropertyCount = Sqflite.firstIntValue(nullPropertyIds) ?? 0;
      if (nullPropertyCount > 0) {
        final issues = result['issues'] as List<String>;
        issues.add('$nullPropertyCount registros com property_id nulo');
        result['issues'] = issues;
      }
      
      return result;
    } catch (e) {
      debugPrint('Erro ao verificar saúde da tabela: $e');
      final issues = result['issues'] as List<String>;
      issues.add('Erro ao verificar: $e');
      result['issues'] = issues;
      return result;
    }
  }
}
