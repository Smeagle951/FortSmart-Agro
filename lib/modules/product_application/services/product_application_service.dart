import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/product_application/models/product_application_model.dart';
import 'package:fortsmart_agro/services/user_service.dart';
import 'package:fortsmart_agro/utils/date_utils.dart' as date_utils;

/// Enum para o tipo de aplicação
enum ApplicationType { aerial, ground }

/// Serviço para gerenciar aplicações de produtos
class ProductApplicationService {
  static final ProductApplicationService _instance = ProductApplicationService._internal();
  
  factory ProductApplicationService() {
    return _instance;
  }
  
  ProductApplicationService._internal();
  
  final String _tableName = 'product_applications';
  final UserService _userService = UserService();
  
  /// Inicializa o serviço, criando a tabela se necessário
  Future<void> initialize() async {
    try {
      final db = await AppDatabase().database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableName (
          id TEXT PRIMARY KEY,
          plotId TEXT,
          cropId TEXT,
          applicationDate TEXT,
          applicationType INTEGER,
          numberOfTanks INTEGER,
          tankVolume REAL,
          totalArea REAL,
          userId TEXT,
          notes TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          products TEXT,
          weatherConditions TEXT
        )
      ''');
      debugPrint('Tabela de aplicações de produtos inicializada');
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de aplicações de produtos: $e');
    }
  }
  
  /// Registra uma nova aplicação de produto
  Future<bool> registerApplication(ProductApplicationModel application) async {
    try {
      final db = await AppDatabase().database;
      
      // Adiciona informações de auditoria
      final user = await _userService.getCurrentUser();
      final now = DateTime.now();
      
      final applicationWithAudit = application.copyWith(
        userId: user?.id,
        createdAt: now,
        updatedAt: now,
      );
      
      await db.insert(_tableName, applicationWithAudit.toMap());
      debugPrint('Aplicação de produto registrada com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao registrar aplicação de produto: $e');
      return false;
    }
  }
  
  /// Atualiza uma aplicação de produto existente
  Future<bool> updateApplication(ProductApplicationModel application) async {
    try {
      final db = await AppDatabase().database;
      
      // Atualiza apenas a data de modificação
      final now = DateTime.now();
      final applicationWithAudit = application.copyWith(
        updatedAt: now,
      );
      
      await db.update(
        _tableName,
        applicationWithAudit.toMap(),
        where: 'id = ?',
        whereArgs: [application.id],
      );
      
      debugPrint('Aplicação de produto atualizada com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar aplicação de produto: $e');
      return false;
    }
  }
  
  /// Exclui uma aplicação de produto
  Future<bool> deleteApplication(String id) async {
    try {
      final db = await AppDatabase().database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      debugPrint('Aplicação de produto excluída com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir aplicação de produto: $e');
      return false;
    }
  }
  
  /// Obtém uma aplicação de produto pelo ID
  Future<ProductApplicationModel?> getApplicationById(String id) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return ProductApplicationModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter aplicação de produto por ID: $e');
      return null;
    }
  }
  
  /// Lista todas as aplicações de produtos
  Future<List<ProductApplicationModel>> getAllApplications() async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar aplicações de produtos: $e');
      return [];
    }
  }
  
  /// Lista aplicações de produtos por talhão
  Future<List<ProductApplicationModel>> getApplicationsByPlot(String plotId) async {
    try {
      final db = await AppDatabase().database;
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
      debugPrint('Erro ao listar aplicações de produtos por talhão: $e');
      return [];
    }
  }
  
  /// Lista aplicações de produtos por cultura
  Future<List<ProductApplicationModel>> getApplicationsByCrop(String cropId) async {
    try {
      final db = await AppDatabase().database;
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
      debugPrint('Erro ao listar aplicações de produtos por cultura: $e');
      return [];
    }
  }
  
  /// Lista aplicações de produtos por período
  Future<List<ProductApplicationModel>> getApplicationsByPeriod(DateTime start, DateTime end) async {
    try {
      final db = await AppDatabase().database;
      final startDate = start.toIso8601String();
      final endDate = end.add(const Duration(days: 1)).toIso8601String();
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'applicationDate >= ? AND applicationDate < ?',
        whereArgs: [startDate, endDate],
        orderBy: 'applicationDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ProductApplicationModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar aplicações de produtos por período: $e');
      return [];
    }
  }
  
  /// Calcula estatísticas de aplicação por talhão
  Future<Map<String, dynamic>> getApplicationStatsByPlot(String plotId) async {
    try {
      final applications = await getApplicationsByPlot(plotId);
      
      double totalArea = 0;
      int totalApplications = applications.length;
      
      for (var app in applications) {
        totalArea += app.totalArea ?? 0;
      }
      
      return {
        'totalApplications': totalApplications,
        'totalArea': totalArea,
        'averageAreaPerApplication': totalApplications > 0 ? totalArea / totalApplications : 0,
      };
    } catch (e) {
      debugPrint('Erro ao calcular estatísticas de aplicação por talhão: $e');
      return {
        'totalApplications': 0,
        'totalArea': 0,
        'averageAreaPerApplication': 0,
      };
    }
  }
}
