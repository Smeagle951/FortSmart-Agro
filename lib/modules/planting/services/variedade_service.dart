import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/variedade_model.dart';

import 'package:uuid/uuid.dart';

/// Serviço para gerenciar operações relacionadas às variedades de culturas
class VariedadeService {
  static final VariedadeService _instance = VariedadeService._internal();
  
  factory VariedadeService() {
    return _instance;
  }
  
  VariedadeService._internal();
  
  final String _tableName = 'variedades';
  
  /// Inicializa a tabela de variedades no banco de dados
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
            nome TEXT NOT NULL,
            cultura_id TEXT NOT NULL,
            descricao TEXT,
            ciclo_dias INTEGER,
            peso_mil_sementes REAL,
            germinacao_percentual REAL,
            vigor_percentual REAL,
            pureza_percentual REAL,
            observacoes TEXT,
            sincronizado INTEGER DEFAULT 0,
            criado_em TEXT NOT NULL,
            atualizado_em TEXT NOT NULL
          )
        ''');
        debugPrint('Tabela de variedades criada com sucesso');
      } else {
        debugPrint('Tabela de variedades já existe');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de variedades: $e');
    }
  }
  
  /// Cadastra uma nova variedade
  Future<bool> cadastrar(VariedadeModel variedade) async {
    try {
      final db = await AppDatabase().database;
      await db.insert(_tableName, variedade.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao cadastrar variedade: $e');
      return false;
    }
  }
  
  /// Atualiza uma variedade existente
  Future<bool> atualizar(VariedadeModel variedade) async {
    try {
      final db = await AppDatabase().database;
      final result = await db.update(
        _tableName,
        variedade.toMap(),
        where: 'id = ?',
        whereArgs: [variedade.id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao atualizar variedade: $e');
      return false;
    }
  }
  
  /// Exclui uma variedade
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
      debugPrint('Erro ao excluir variedade: $e');
      return false;
    }
  }
  
  /// Obtém uma variedade pelo ID
  Future<VariedadeModel?> obterPorId(String id) async {
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
      
      return VariedadeModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter variedade por ID: $e');
      return null;
    }
  }
  
  /// Lista todas as variedades
  Future<List<VariedadeModel>> listar() async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'nome ASC',
      );
      
      return List.generate(maps.length, (i) {
        return VariedadeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar variedades: $e');
      return [];
    }
  }
  
  /// Lista variedades por cultura
  Future<List<VariedadeModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'nome ASC',
      );
      
      return List.generate(maps.length, (i) {
        return VariedadeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar variedades por cultura: $e');
      return [];
    }
  }
  
  /// Busca variedades por nome
  Future<List<VariedadeModel>> buscarPorNome(String nome) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'nome LIKE ?',
        whereArgs: ['%$nome%'],
        orderBy: 'nome ASC',
      );
      
      return List.generate(maps.length, (i) {
        return VariedadeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao buscar variedades por nome: $e');
      return [];
    }
  }
  
  /// Gera um novo ID para variedade
  String gerarId() {
    return const Uuid().v4();
  }
}
