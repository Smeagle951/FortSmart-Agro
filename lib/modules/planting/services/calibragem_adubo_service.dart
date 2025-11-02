import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/calibragem_adubo_model.dart';

import 'package:uuid/uuid.dart';

/// Serviço para gerenciar operações relacionadas à calibragem de adubo
class CalibragemAduboService {
  static final CalibragemAduboService _instance = CalibragemAduboService._internal();
  
  factory CalibragemAduboService() {
    return _instance;
  }
  
  CalibragemAduboService._internal();
  
  final String _tableName = 'calibragem_adubo';
  
  /// Inicializa a tabela de calibragem de adubo no banco de dados
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
            trator_id TEXT NOT NULL,
            plantadeira_id TEXT NOT NULL,
            data_calibragem TEXT NOT NULL,
            tipo_adubo TEXT NOT NULL,
            quantidade_hectare REAL NOT NULL,
            velocidade_trabalho REAL NOT NULL,
            largura_trabalho REAL NOT NULL,
            tempo_coleta INTEGER NOT NULL,
            quantidade_coletada REAL NOT NULL,
            quantidade_calculada REAL NOT NULL,
            diferenca_percentual REAL NOT NULL,
            observacoes TEXT,
            sincronizado INTEGER DEFAULT 0,
            criado_em TEXT NOT NULL,
            atualizado_em TEXT NOT NULL
          )
        ''');
        debugPrint('Tabela de calibragem de adubo criada com sucesso');
      } else {
        debugPrint('Tabela de calibragem de adubo já existe');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de calibragem de adubo: $e');
    }
  }
  
  /// Cadastra uma nova calibragem de adubo
  Future<bool> cadastrar(CalibragemAduboModel calibragem) async {
    try {
      final db = await AppDatabase().database;
      await db.insert(_tableName, calibragem.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao cadastrar calibragem de adubo: $e');
      return false;
    }
  }
  
  /// Atualiza uma calibragem de adubo existente
  Future<bool> atualizar(CalibragemAduboModel calibragem) async {
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
      debugPrint('Erro ao atualizar calibragem de adubo: $e');
      return false;
    }
  }
  
  /// Exclui uma calibragem de adubo
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
      debugPrint('Erro ao excluir calibragem de adubo: $e');
      return false;
    }
  }
  
  /// Obtém uma calibragem de adubo pelo ID
  Future<CalibragemAduboModel?> obterPorId(String id) async {
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
      
      return CalibragemAduboModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter calibragem de adubo por ID: $e');
      return null;
    }
  }
  
  /// Lista todas as calibragens de adubo
  Future<List<CalibragemAduboModel>> listar() async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'data_calibragem DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalibragemAduboModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar calibragens de adubo: $e');
      return [];
    }
  }
  
  /// Lista calibragens de adubo por talhão
  Future<List<CalibragemAduboModel>> listarPorTalhao(String talhaoId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_calibragem DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalibragemAduboModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar calibragens de adubo por talhão: $e');
      return [];
    }
  }
  
  /// Lista calibragens de adubo por cultura
  Future<List<CalibragemAduboModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'data_calibragem DESC',
      );
      
      return List.generate(maps.length, (i) {
        return CalibragemAduboModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar calibragens de adubo por cultura: $e');
      return [];
    }
  }
  
  /// Calcula a quantidade de adubo por hectare
  double calcularQuantidadeHectare(double quantidadeColetada, double larguraTrabalho, 
      double velocidadeTrabalho, int tempoColeta) {
    // Fórmula: (quantidadeColetada * 36000) / (larguraTrabalho * velocidadeTrabalho * tempoColeta)
    return (quantidadeColetada * 36000) / (larguraTrabalho * velocidadeTrabalho * tempoColeta);
  }
  
  /// Calcula a diferença percentual entre quantidade coletada e calculada
  double calcularDiferencaPercentual(double quantidadeColetada, double quantidadeCalculada) {
    if (quantidadeCalculada == 0) return 0;
    return ((quantidadeColetada - quantidadeCalculada) / quantidadeCalculada) * 100;
  }
  
  /// Gera um novo ID para calibragem de adubo
  String gerarId() {
    return const Uuid().v4();
  }
}
