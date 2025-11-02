import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/calibragem_semente_model.dart';

import 'package:uuid/uuid.dart';

/// Serviço para gerenciar operações relacionadas à calibragem de sementes
class CalibragemSementeService {
  static final CalibragemSementeService _instance = CalibragemSementeService._internal();
  
  factory CalibragemSementeService() {
    return _instance;
  }
  
  CalibragemSementeService._internal();
  
  final String _tableName = 'calibragem_semente';
  
  /// Inicializa a tabela de calibragem de sementes no banco de dados
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
            talhao_id TEXT NOT NULL,
            cultura_id TEXT NOT NULL,
            variedade_id TEXT,
            trator_id TEXT NOT NULL,
            plantadeira_id TEXT NOT NULL,
            data_calibragem TEXT NOT NULL,
            espacamento_cm REAL NOT NULL,
            populacao_desejada INTEGER NOT NULL,
            densidade_metro REAL NOT NULL,
            germinacao_percentual REAL NOT NULL,
            metodo_calibragem TEXT NOT NULL,
            engrenagem_configurada TEXT,
            peso_mil_sementes REAL,
            sementes_coletadas INTEGER,
            sementes_calculadas INTEGER,
            diferenca_percentual REAL NOT NULL,
            observacoes TEXT,
            sincronizado INTEGER DEFAULT 0,
            criado_em TEXT NOT NULL,
            atualizado_em TEXT NOT NULL
          )
        ''');
        debugPrint('Tabela de calibragem de sementes criada com sucesso');
      } else {
        debugPrint('Tabela de calibragem de sementes já existe');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de calibragem de sementes: $e');
    }
  }
  
  /// Cadastra uma nova calibragem de sementes
  Future<bool> cadastrar(CalibragemSementeModel calibragem) async {
    try {
      final db = await AppDatabase().database;
      await db.insert(_tableName, calibragem.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao cadastrar calibragem de sementes: $e');
      return false;
    }
  }
  
  /// Atualiza uma calibragem de sementes existente
  Future<bool> atualizar(CalibragemSementeModel calibragem) async {
    try {
      final db = await AppDatabase().database;
      final result = await db.update(
        _tableName,
        calibragem.toMap(),
        where: 'id = ?',
        whereArgs: [calibragem.id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao atualizar calibragem de sementes: $e');
      return false;
    }
  }
  
  /// Exclui uma calibragem de sementes
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
      debugPrint('Erro ao excluir calibragem de sementes: $e');
      return false;
    }
  }
  
  /// Obtém uma calibragem de sementes pelo ID
  Future<CalibragemSementeModel?> obterPorId(String id) async {
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
      
      return CalibragemSementeModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter calibragem de sementes por ID: $e');
      return null;
    }
  }
  
  /// Lista todas as calibragens de sementes
  Future<List<CalibragemSementeModel>> listar() async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'data_calibragem DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalibragemSementeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar calibragens de sementes: $e');
      return [];
    }
  }
  
  /// Lista calibragens de sementes por talhão
  Future<List<CalibragemSementeModel>> listarPorTalhao(String talhaoId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_calibragem DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalibragemSementeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar calibragens de sementes por talhão: $e');
      return [];
    }
  }
  
  /// Lista calibragens de sementes por cultura
  Future<List<CalibragemSementeModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'data_calibragem DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalibragemSementeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar calibragens de sementes por cultura: $e');
      return [];
    }
  }
  
  /// Calcula o número de sementes por metro linear
  double calcularSementesMetroLinear(int populacaoDesejada, double espacamentoCm) {
    // Fórmula: (populacaoDesejada * espacamentoCm) / 100000
    return (populacaoDesejada * espacamentoCm) / 100000;
  }
  
  /// Calcula o número de sementes por hectare
  int calcularSementesHectare(double sementesMetro, double espacamentoCm) {
    // Fórmula: (10000 / (espacamentoCm / 100)) * sementesMetro
    return ((10000 / (espacamentoCm / 100)) * sementesMetro).round();
  }
  
  /// Calcula a diferença percentual entre sementes coletadas e calculadas
  double calcularDiferencaPercentual(int sementesColetadas, int sementesCalculadas) {
    if (sementesCalculadas == 0) return 0;
    return ((sementesColetadas - sementesCalculadas) / sementesCalculadas) * 100;
  }
  
  /// Gera um novo ID para calibragem de sementes
  String gerarId() {
    return const Uuid().v4();
  }
}
