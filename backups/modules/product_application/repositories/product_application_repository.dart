import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/product_application_model.dart';
import '../../../services/database_service.dart';

class ProductApplicationRepository {
  final DatabaseService _databaseService = DatabaseService();
  final String _tableName = 'product_applications';
  
  // Inicialização da tabela
  Future<void> initTable() async {
    final db = await _databaseService.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        applicationType INTEGER NOT NULL,
        applicationDate TEXT NOT NULL,
        responsibleName TEXT NOT NULL,
        equipmentType TEXT NOT NULL,
        syrupVolumePerHectare REAL NOT NULL,
        cropId TEXT NOT NULL,
        cropName TEXT NOT NULL,
        plotId TEXT NOT NULL,
        plotName TEXT NOT NULL,
        area REAL NOT NULL,
        targetIds TEXT NOT NULL,
        products TEXT NOT NULL,
        totalSyrupVolume REAL NOT NULL,
        equipmentCapacity REAL NOT NULL,
        numberOfTanks INTEGER NOT NULL,
        nozzleType TEXT NOT NULL,
        technicalJustification TEXT,
        deductFromStock INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');
    
    print('Tabela $_tableName inicializada com sucesso');
  }
  
  // Inserir uma nova aplicação
  Future<String> insert(ProductApplicationModel application) async {
    try {
      final db = await _databaseService.database;
      
      await db.insert(
        _tableName,
        application.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('Aplicação inserida com sucesso: ${application.id}');
      return application.id;
    } catch (e) {
      print('Erro ao inserir aplicação: $e');
      throw Exception('Falha ao inserir aplicação: $e');
    }
  }
  
  // Atualizar uma aplicação existente
  Future<int> update(ProductApplicationModel application) async {
    try {
      final db = await _databaseService.database;
      
      return await db.update(
        _tableName,
        application.toMap(),
        where: 'id = ?',
        whereArgs: [application.id],
      );
    } catch (e) {
      print('Erro ao atualizar aplicação: $e');
      throw Exception('Falha ao atualizar aplicação: $e');
    }
  }
  
  // Excluir uma aplicação
  Future<int> delete(String id) async {
    try {
      final db = await _databaseService.database;
      
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Erro ao excluir aplicação: $e');
      throw Exception('Falha ao excluir aplicação: $e');
    }
  }
  
  // Obter uma aplicação pelo ID
  Future<ProductApplicationModel?> getById(String id) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return ProductApplicationModel.fromMap(maps.first);
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar aplicação: $e');
      throw Exception('Falha ao buscar aplicação: $e');
    }
  }
  
  // Listar todas as aplicações
  Future<List<ProductApplicationModel>> getAll() async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar aplicações: $e');
      throw Exception('Falha ao listar aplicações: $e');
    }
  }
  
  // Listar aplicações por talhão
  Future<List<ProductApplicationModel>> getByPlot(String plotId) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'plotId = ?',
        whereArgs: [plotId],
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar aplicações por talhão: $e');
      throw Exception('Falha ao listar aplicações por talhão: $e');
    }
  }
  
  // Listar aplicações por cultura
  Future<List<ProductApplicationModel>> getByCrop(String cropId) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cropId = ?',
        whereArgs: [cropId],
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar aplicações por cultura: $e');
      throw Exception('Falha ao listar aplicações por cultura: $e');
    }
  }
  
  // Listar aplicações por período
  Future<List<ProductApplicationModel>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'applicationDate BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar aplicações por período: $e');
      throw Exception('Falha ao listar aplicações por período: $e');
    }
  }
  
  // Listar aplicações por tipo (terrestre/aérea)
  Future<List<ProductApplicationModel>> getByType(ApplicationType type) async {
    try {
      final db = await _databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'applicationType = ?',
        whereArgs: [type.index],
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('Erro ao listar aplicações por tipo: $e');
      throw Exception('Falha ao listar aplicações por tipo: $e');
    }
  }
  
  // Obter estatísticas de aplicação por talhão
  Future<Map<String, dynamic>> getStatsByPlot(String plotId) async {
    try {
      final applications = await getByPlot(plotId);
      
      if (applications.isEmpty) {
        return {
          'totalApplications': 0,
          'totalProducts': 0,
          'totalArea': 0.0,
        };
      }
      
      // Contagem de produtos únicos aplicados
      final Set<String> uniqueProducts = {};
      for (var app in applications) {
        for (var product in app.products) {
          uniqueProducts.add(product.productId);
        }
      }
      
      return {
        'totalApplications': applications.length,
        'totalProducts': uniqueProducts.length,
        'totalArea': applications.fold<double>(0, (sum, app) => sum + app.area),
        'lastApplication': applications.first.applicationDate,
      };
    } catch (e) {
      print('Erro ao obter estatísticas de aplicação por talhão: $e');
      throw Exception('Falha ao obter estatísticas de aplicação por talhão: $e');
    }
  }
}
