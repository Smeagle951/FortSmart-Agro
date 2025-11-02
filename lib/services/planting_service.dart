import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/planting.dart';
import '../utils/text_encoding_helper.dart';
import 'dart:async';

/// Serviço para gerenciar plantios
class PlantingService {
  final AppDatabase _database = AppDatabase();

  /// Garante que o banco de dados esteja aberto antes de qualquer operação
  Future<void> _ensureDatabaseOpen() async {
    await _database.ensureDatabaseOpen();
  }
  
  /// Obtém todos os plantios
  Future<List<Planting>> getAllPlantings() async {
    try {
      // Garante que o banco de dados esteja aberto
      await _ensureDatabaseOpen();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('plantings', orderBy: 'planting_date DESC');
      
      return List.generate(maps.length, (i) {
        // Normaliza os textos para evitar problemas de codificação
        final Map<String, dynamic> normalizedMap = {};
        maps[i].forEach((key, value) {
          if (value is String) {
            normalizedMap[key] = TextEncodingHelper.normalizeText(value);
          } else {
            normalizedMap[key] = value;
          }
        });
        
        return Planting.fromMap(normalizedMap);
      });
    } catch (e) {
      // Verifica se o erro é relacionado à tabela inexistente
      if (e.toString().contains('no such table')) {
        // Tenta criar a tabela
        await _createPlantingsTable();
        // Retorna uma lista vazia após criar a tabela
        return [];
      }
      // Se for outro tipo de erro, propaga
      rethrow;
    }
  }
  
  /// Obtém um plantio pelo ID
  Future<Planting?> getPlantingById(int id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'plantings',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      // Normaliza os textos
      final Map<String, dynamic> normalizedMap = {};
      maps.first.forEach((key, value) {
        if (value is String) {
          normalizedMap[key] = TextEncodingHelper.normalizeText(value);
        } else {
          normalizedMap[key] = value;
        }
      });
      
      return Planting.fromMap(normalizedMap);
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPlantingsTable();
        return null;
      }
      rethrow;
    }
  }
  
  /// Adiciona um novo plantio
  Future<int> addPlanting(Planting planting) async {
    try {
      final db = await _database.database;
      return await db.insert(
        'plantings',
        planting.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPlantingsTable();
        // Tenta novamente após criar a tabela
        final db = await _database.database;
        return await db.insert(
          'plantings',
          planting.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      rethrow;
    }
  }
  
  /// Atualiza um plantio existente
  Future<int> updatePlanting(Planting planting) async {
    try {
      final db = await _database.database;
      return await db.update(
        'plantings',
        planting.toMap(),
        where: 'id = ?',
        whereArgs: [planting.id],
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPlantingsTable();
        // Tenta novamente após criar a tabela
        final db = await _database.database;
        return await db.update(
          'plantings',
          planting.toMap(),
          where: 'id = ?',
          whereArgs: [planting.id],
        );
      }
      rethrow;
    }
  }
  
  /// Remove um plantio
  Future<int> deletePlanting(String id) async {
    try {
      final db = await _database.database;
      return await db.delete(
        'plantings',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPlantingsTable();
        return 0; // Não há nada para excluir se a tabela acabou de ser criada
      }
      rethrow;
    }
  }
  
  /// Obtém estatísticas dos plantios ativos
  Future<Map<String, dynamic>> getActivePlantingsStats() async {
    try {
      final plantings = await getAllPlantings();
      final activePlantings = plantings.where((p) => p.plantingDate != null).toList();
      final areaPlanted = activePlantings.fold<double>(0, (total, p) => total + (p.area ?? 0));
      
      return {
        'total': activePlantings.length,
        'active': activePlantings.length,
        'areaPlanted': areaPlanted,
      };
    } catch (e) {
      print('❌ [PlantingService] Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'active': 0,
        'areaPlanted': 0.0,
      };
    }
  }

  /// Cria a tabela de plantios se não existir
  Future<void> _createPlantingsTable() async {
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plantings (
        id TEXT PRIMARY KEY,
        plot_id TEXT NOT NULL,
        crop_id TEXT,
        crop_variety_id TEXT,
        planting_date TEXT NOT NULL,
        expected_harvest_date TEXT,
        planter_id TEXT,
        tractor_id TEXT,
        seed_rate REAL,
        seed_depth REAL,
        row_spacing REAL,
        area REAL,
        notes TEXT,
        image_urls TEXT,
        coordinates TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        crop_type TEXT,
        variety TEXT,
        observations TEXT,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');
  }
}
