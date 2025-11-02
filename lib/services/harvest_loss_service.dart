import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/harvest_loss.dart';
import '../utils/text_encoding_helper.dart';
import 'dart:async';

/// Serviço para gerenciar perdas na colheita
class HarvestLossService {
  final AppDatabase _database = AppDatabase();

  /// Garante que o banco de dados esteja aberto antes de qualquer operação
  Future<void> _ensureDatabaseOpen() async {
    await _database.ensureDatabaseOpen();
  }
  
  /// Obtém todas as perdas na colheita
  Future<List<HarvestLoss>> getAllLosses() async {
    try {
      // Garante que o banco de dados esteja aberto
      await _ensureDatabaseOpen();
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('harvest_losses', orderBy: 'assessmentDate DESC');
      
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
        
        return HarvestLoss.fromMap(normalizedMap);
      });
    } catch (e) {
      // Verifica se o erro é relacionado à tabela inexistente
      if (e.toString().contains('no such table')) {
        // Tenta criar a tabela
        await _createHarvestLossesTable();
        // Retorna uma lista vazia após criar a tabela
        return [];
      }
      // Se for outro tipo de erro, propaga
      rethrow;
    }
  }
  
  /// Obtém uma perda na colheita pelo ID
  Future<HarvestLoss?> getLossById(int id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'harvest_losses',
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
      
      return HarvestLoss.fromMap(normalizedMap);
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createHarvestLossesTable();
        return null;
      }
      rethrow;
    }
  }
  
  /// Adiciona uma nova perda na colheita
  Future<int> addLoss(HarvestLoss loss) async {
    try {
      final db = await _database.database;
      return await db.insert(
        'harvest_losses',
        loss.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createHarvestLossesTable();
        // Tenta novamente após criar a tabela
        final db = await _database.database;
        return await db.insert(
          'harvest_losses',
          loss.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      rethrow;
    }
  }
  
  /// Atualiza uma perda na colheita existente
  Future<int> updateLoss(HarvestLoss loss) async {
    try {
      final db = await _database.database;
      return await db.update(
        'harvest_losses',
        loss.toMap(),
        where: 'id = ?',
        whereArgs: [loss.id],
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createHarvestLossesTable();
        // Tenta novamente após criar a tabela
        final db = await _database.database;
        return await db.update(
          'harvest_losses',
          loss.toMap(),
          where: 'id = ?',
          whereArgs: [loss.id],
        );
      }
      rethrow;
    }
  }
  
  /// Remove uma perda na colheita
  Future<int> deleteLoss(int id) async {
    try {
      final db = await _database.database;
      return await db.delete(
        'harvest_losses',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createHarvestLossesTable();
        return 0; // Não há nada para excluir se a tabela acabou de ser criada
      }
      rethrow;
    }
  }
  
  /// Cria a tabela de perdas na colheita se não existir
  Future<void> _createHarvestLossesTable() async {
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS harvest_losses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id TEXT NOT NULL,
        date TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        loss_percentage REAL NOT NULL,
        loss_cause TEXT,
        estimated_financial_loss REAL,
        mitigation_actions TEXT,
        images TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER DEFAULT 0,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');
  }
}
