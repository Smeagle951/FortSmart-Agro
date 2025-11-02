import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/plot.dart';
import 'dart:convert';

class PlotDao {
  AppDatabase? _appDatabase;
  
  /// Obtém a instância do AppDatabase de forma lazy
  AppDatabase get appDatabase {
    _appDatabase ??= AppDatabase();
    return _appDatabase!;
  }
  
  /// Retorna a instância do banco de dados
  Future<Database> getDatabase() async {
    return await appDatabase.database;
  }

  /// Cria a tabela de talhões se não existir
  Future<void> createTable(Database db) async {
    debugPrint('PlotDao: Verificando/criando tabela de talhões');
    try {
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
      debugPrint('PlotDao: Tabela de talhões verificada/criada com sucesso');
    } catch (e) {
      debugPrint('PlotDao: Erro ao criar tabela de talhões: $e');
      rethrow;
    }
  }

  /// Verifica se a tabela existe e a cria se necessário
  Future<void> ensureTableExists() async {
    try {
      final db = await appDatabase.database;
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='plots'");
      
      if (result.isEmpty) {
        debugPrint('PlotDao: Tabela de talhões não existe. Criando...');
        await createTable(db);
      }
    } catch (e) {
      debugPrint('PlotDao: Erro ao verificar tabela: $e');
      rethrow;
    }
  }

  /// Insere um novo talhão no banco de dados
  Future<String?> insert(Plot plot) async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      // Validação dos dados antes de inserir
      if (plot.id == null) {
        throw Exception('ID do talhão não pode ser nulo');
      }
      
      if (plot.name.isEmpty) {
        throw Exception('Nome do talhão não pode ser vazio');
      }
      
      // Verifica se o JSON do polígono é válido
      if (plot.polygonJson != null) {
        try {
          json.decode(plot.polygonJson!);
        } catch (e) {
          throw Exception('JSON do polígono inválido: $e');
        }
      }
      
      // Prepara os dados para inserção
      final plotMap = plot.toMap();
      
      await db.insert('plots', plotMap, conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('PlotDao: Talhão inserido com sucesso: ${plot.id}');
      return plot.id;
    } catch (e) {
      debugPrint('PlotDao: Erro ao inserir talhão: $e');
      return null;
    }
  }

  /// Atualiza um talhão existente
  Future<bool> update(Plot plot) async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      // Validação dos dados antes de atualizar
      if (plot.id == null || plot.id!.isEmpty) {
        throw Exception('ID do talhão não pode ser nulo ou vazio');
      }
      
      // Verifica se o talhão existe
      final exists = await _checkPlotExists(db, plot.id!);
      if (!exists) {
        debugPrint('PlotDao: Talhão não existe, tentando inserir: ${plot.id}');
        return await insert(plot) != null;
      }
      
      // Verifica se o JSON do polígono é válido
      if (plot.polygonJson != null) {
        try {
          json.decode(plot.polygonJson!);
        } catch (e) {
          throw Exception('JSON do polígono inválido: $e');
        }
      }
      
      // Garante que property_id e farm_id não são nulos
      final propertyId = plot.propertyId ?? 0;
      final farmId = plot.farmId ?? 0;
      
      // Prepara os dados para atualização
      final plotMap = {
        'property_id': propertyId,
        'farm_id': farmId,
        'name': plot.name,
        'area': plot.area,
        'crop_type': plot.cropType,
        'planting_date': plot.plantingDate,
        'harvest_date': plot.harvestDate,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_status': plot.syncStatus ?? 0,
        'remote_id': plot.remoteId,
        'polygon_json': plot.polygonJson,
      };
      
      await db.update(
        'plots', 
        plotMap, 
        where: 'id = ?', 
        whereArgs: [plot.id],
      );
      
      debugPrint('PlotDao: Talhão atualizado com sucesso: ${plot.id}');
      return true;
    } catch (e) {
      debugPrint('PlotDao: Erro ao atualizar talhão: $e');
      return false;
    }
  }

  /// Verifica se um talhão existe no banco de dados
  Future<bool> _checkPlotExists(Database db, String id) async {
    try {
      final result = await db.query(
        'plots',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('PlotDao: Erro ao verificar existência do talhão: $e');
      return false;
    }
  }

  /// Exclui um talhão do banco de dados
  Future<bool> delete(String id) async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      await db.delete(
        'plots',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      debugPrint('PlotDao: Talhão excluído com sucesso: $id');
      return true;
    } catch (e) {
      debugPrint('PlotDao: Erro ao excluir talhão: $e');
      return false;
    }
  }

  /// Obtém todos os talhões do banco de dados
  Future<List<Plot>> getAll() async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      final result = await db.query('plots');
      
      return result.map((map) => Plot.fromMap(map)).toList();
    } catch (e) {
      debugPrint('PlotDao: Erro ao obter talhões: $e');
      return [];
    }
  }

  /// Obtém um talhão pelo ID
  Future<Plot?> getById(String id) async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      final result = await db.query(
        'plots',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (result.isEmpty) {
        return null;
      }
      
      return Plot.fromMap(result.first);
    } catch (e) {
      debugPrint('PlotDao: Erro ao obter talhão por ID: $e');
      return null;
    }
  }

  /// Obtém talhões por propriedade
  Future<List<Plot>> getByPropertyId(int propertyId) async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      final result = await db.query(
        'plots',
        where: 'property_id = ?',
        whereArgs: [propertyId],
      );
      
      return result.map((map) => Plot.fromMap(map)).toList();
    } catch (e) {
      debugPrint('PlotDao: Erro ao obter talhões por propriedade: $e');
      return [];
    }
  }

  /// Obtém talhões por fazenda
  Future<List<Plot>> getByFarmId(int farmId) async {
    try {
      await ensureTableExists();
      
      final db = await appDatabase.database;
      
      final result = await db.query(
        'plots',
        where: 'farm_id = ?',
        whereArgs: [farmId],
      );
      
      return result.map((map) => Plot.fromMap(map)).toList();
    } catch (e) {
      debugPrint('PlotDao: Erro ao obter talhões por fazenda: $e');
      return [];
    }
  }

  /// Retorna todos os talhões pendentes de sincronização
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    final db = await appDatabase.database;
    try {
      return await db.query(
        'plots',
        where: 'sync_status = ?',
        whereArgs: [0],
      );
    } catch (e) {
      debugPrint('PlotDao: Erro ao obter talhões pendentes de sincronização: $e');
      return [];
    }
  }

  /// Atualiza o status de sincronização de um talhão
  Future<bool> updateSyncStatus(String id, int syncStatus, int? remoteId) async {
    final db = await appDatabase.database;
    try {
      final updateMap = {
        'sync_status': syncStatus,
      };
      
      if (remoteId != null) {
        updateMap['remote_id'] = remoteId;
      }
      
      final count = await db.update(
        'plots',
        updateMap,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return count > 0;
    } catch (e) {
      debugPrint('PlotDao: Erro ao atualizar status de sincronização: $e');
      return false;
    }
  }
}
