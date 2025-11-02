import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/semente_hectare_model.dart';

import 'package:uuid/uuid.dart';

/// Serviço para gerenciar operações relacionadas ao cálculo de sementes por hectare
class SementeHectareService {
  static final SementeHectareService _instance = SementeHectareService._internal();
  
  factory SementeHectareService() {
    return _instance;
  }
  
  SementeHectareService._internal();
  
  final String _tableName = 'semente_hectare';
  
  /// Inicializa a tabela de cálculo de sementes por hectare no banco de dados
  Future<void> inicializarTabela() async {
    try {
      final db = await AppDatabase().database;
      
      // Verifica se a tabela já existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
      );
      
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            talhao_id TEXT,
            cultura_id TEXT NOT NULL,
            variedade_id TEXT,
            espacamento_cm REAL NOT NULL,
            populacao_desejada INTEGER NOT NULL,
            densidade_metro REAL NOT NULL,
            germinacao_percentual REAL NOT NULL,
            peso_mil_sementes REAL NOT NULL,
            sementes_ha INTEGER NOT NULL,
            kg_ha REAL NOT NULL,
            sacas_ha REAL NOT NULL,
            sementes_metro_linear REAL NOT NULL,
            observacoes TEXT,
            data_criacao TEXT NOT NULL,
            sincronizado INTEGER DEFAULT 0
          )
        ''');
        debugPrint('Tabela de cálculo de sementes por hectare criada com sucesso');
      } else {
        debugPrint('Tabela de cálculo de sementes por hectare já existe');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de cálculo de sementes por hectare: $e');
    }
  }
  
  /// Cadastra um novo cálculo de sementes por hectare
  Future<bool> cadastrar(SementeHectareModel calculo) async {
    try {
      final db = await AppDatabase().database;
      await db.insert(_tableName, calculo.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao cadastrar cálculo de sementes por hectare: $e');
      return false;
    }
  }
  
  /// Atualiza um cálculo de sementes por hectare existente
  Future<bool> atualizar(SementeHectareModel calculo) async {
    try {
      final db = await AppDatabase().database;
      final result = await db.update(
        _tableName,
        calculo.toMap(),
        where: 'id = ?',
        whereArgs: [calculo.id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao atualizar cálculo de sementes por hectare: $e');
      return false;
    }
  }
  
  /// Exclui um cálculo de sementes por hectare
  Future<bool> excluir(String id) async {
    try {
      final db = await AppDatabase().database;
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao excluir cálculo de sementes por hectare: $e');
      return false;
    }
  }
  
  /// Obtém um cálculo de sementes por hectare pelo ID
  Future<SementeHectareModel?> obterPorId(String id) async {
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
      
      return SementeHectareModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter cálculo de sementes por hectare por ID: $e');
      return null;
    }
  }
  
  /// Lista todos os cálculos de sementes por hectare
  Future<List<SementeHectareModel>> listar() async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'data_criacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return SementeHectareModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar cálculos de sementes por hectare: $e');
      return [];
    }
  }
  
  /// Lista cálculos de sementes por hectare por talhão
  Future<List<SementeHectareModel>> listarPorTalhao(String talhaoId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_criacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return SementeHectareModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar cálculos de sementes por hectare por talhão: $e');
      return [];
    }
  }
  
  /// Lista cálculos de sementes por hectare por cultura
  Future<List<SementeHectareModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'data_criacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return SementeHectareModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar cálculos de sementes por hectare por cultura: $e');
      return [];
    }
  }
  
  /// Calcula o número de sementes por hectare
  int calcularSementesHa(double espacamento, int densidade) {
    // Fórmula: (10000 / (espacamento / 100)) * densidade
    return ((10000 / (espacamento / 100)) * densidade).round();
  }
  
  /// Calcula a quantidade em kg por hectare
  double calcularKgHa(int sementesHa, double pesoMilSementes) {
    // Fórmula: (sementesHa * pesoMilSementes) / 1000000
    return (sementesHa * pesoMilSementes) / 1000000;
  }
  
  /// Calcula a quantidade em sacas por hectare
  double calcularSacasHa(double kgHa) {
    // Considerando sacas de 60kg
    return kgHa / 60;
  }
  
  /// Calcula o número de sementes por metro linear
  double calcularSementesMetroLinear(double densidade, double germinacao) {
    // Fórmula: densidade / (germinacao / 100)
    return densidade / (germinacao / 100);
  }
  
  /// Gera um novo ID para cálculo de sementes por hectare
  String gerarId() {
    return const Uuid().v4();
  }
}
