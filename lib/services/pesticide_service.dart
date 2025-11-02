import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/pesticide_application.dart';
import '../utils/text_encoding_helper.dart';
import 'dart:async';

/// Serviço para gerenciar aplicações de defensivos
class PesticideService {
  final AppDatabase _database = AppDatabase();
  
  /// Obtém todas as aplicações de defensivos
  Future<List<PesticideApplication>> getAllApplications() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query('pesticide_applications', orderBy: 'application_date DESC');
      
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
        
        return PesticideApplication.fromMap(normalizedMap);
      });
    } catch (e) {
      // Verifica se o erro é relacionado à tabela inexistente
      if (e.toString().contains('no such table')) {
        // Tenta criar a tabela
        await _createPesticideApplicationsTable();
        // Retorna uma lista vazia após criar a tabela
        return [];
      }
      // Se for outro tipo de erro, propaga
      rethrow;
    }
  }
  
  /// Obtém uma aplicação de defensivo pelo ID
  Future<PesticideApplication?> getApplicationById(int id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'pesticide_applications',
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
      
      return PesticideApplication.fromMap(normalizedMap);
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPesticideApplicationsTable();
        return null;
      }
      rethrow;
    }
  }
  
  /// Adiciona uma nova aplicação de defensivo
  Future<int> addApplication(PesticideApplication application) async {
    try {
      final db = await _database.database;
      return await db.insert(
        'pesticide_applications',
        application.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPesticideApplicationsTable();
        // Tenta novamente após criar a tabela
        final db = await _database.database;
        return await db.insert(
          'pesticide_applications',
          application.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      rethrow;
    }
  }
  
  /// Atualiza uma aplicação de defensivo existente
  Future<int> updateApplication(PesticideApplication application) async {
    try {
      final db = await _database.database;
      return await db.update(
        'pesticide_applications',
        application.toMap(),
        where: 'id = ?',
        whereArgs: [application.id],
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPesticideApplicationsTable();
        // Tenta novamente após criar a tabela
        final db = await _database.database;
        return await db.update(
          'pesticide_applications',
          application.toMap(),
          where: 'id = ?',
          whereArgs: [application.id],
        );
      }
      rethrow;
    }
  }
  
  /// Remove uma aplicação de defensivo
  Future<int> deleteApplication(int id) async {
    try {
      final db = await _database.database;
      return await db.delete(
        'pesticide_applications',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e.toString().contains('no such table')) {
        await _createPesticideApplicationsTable();
        return 0; // Não há nada para excluir se a tabela acabou de ser criada
      }
      rethrow;
    }
  }
  
  /// Cria a tabela de aplicações de defensivos se não existir
  Future<void> _createPesticideApplicationsTable() async {
    final db = await _database.database;
    await db.execute('''
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
    ''');
  }
}
