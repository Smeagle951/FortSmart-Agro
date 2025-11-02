import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fortsmart_agro/database/app_database.dart';
import 'package:fortsmart_agro/modules/planting/models/estande_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

/// Serviço para gerenciar operações relacionadas ao estande de plantas
class EstandeService {
  static final EstandeService _instance = EstandeService._internal();
  
  factory EstandeService() {
    return _instance;
  }
  
  EstandeService._internal();
  
  final String _tableName = 'estande_plantas';
  
  /// Inicializa a tabela de estande de plantas no banco de dados
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
            data_avaliacao TEXT NOT NULL,
            metros_avaliados REAL NOT NULL,
            plantas_contadas INTEGER NOT NULL,
            plantas_por_metro REAL NOT NULL,
            plantas_por_hectare INTEGER NOT NULL,
            observacoes TEXT,
            fotos TEXT,
            latitude REAL,
            longitude REAL,
            sincronizado INTEGER DEFAULT 0,
            criado_em TEXT NOT NULL,
            atualizado_em TEXT NOT NULL
          )
        ''');
        debugPrint('Tabela de estande de plantas criada com sucesso');
      } else {
        debugPrint('Tabela de estande de plantas já existe');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar tabela de estande de plantas: $e');
    }
  }
  
  /// Cadastra um novo registro de estande
  Future<bool> cadastrar(EstandeModel estande) async {
    try {
      final db = await AppDatabase().database;
      await db.insert(_tableName, estande.toMap());
      return true;
    } catch (e) {
      debugPrint('Erro ao cadastrar estande: $e');
      return false;
    }
  }
  
  /// Atualiza um registro de estande existente
  Future<bool> atualizar(EstandeModel estande) async {
    try {
      final db = await AppDatabase().database;
      final result = await db.update(
        _tableName,
        estande.toMap(),
        where: 'id = ?',
        whereArgs: [estande.id],
      );
      return result > 0;
    } catch (e) {
      debugPrint('Erro ao atualizar estande: $e');
      return false;
    }
  }
  
  /// Exclui um registro de estande
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
      debugPrint('Erro ao excluir estande: $e');
      return false;
    }
  }
  
  /// Obtém um registro de estande pelo ID
  Future<EstandeModel?> obterPorId(String id) async {
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
      
      return EstandeModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('Erro ao obter estande por ID: $e');
      return null;
    }
  }
  
  /// Lista todos os registros de estande
  Future<List<EstandeModel>> listar() async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'data_avaliacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return EstandeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar estandes: $e');
      return [];
    }
  }
  
  /// Lista estandes por talhão
  Future<List<EstandeModel>> listarPorTalhao(String talhaoId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_avaliacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return EstandeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar estandes por talhão: $e');
      return [];
    }
  }
  
  /// Lista estandes por cultura
  Future<List<EstandeModel>> listarPorCultura(String culturaId) async {
    try {
      final db = await AppDatabase().database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cultura_id = ?',
        whereArgs: [culturaId],
        orderBy: 'data_avaliacao DESC',
      );
      
      return List.generate(maps.length, (i) {
        return EstandeModel.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Erro ao listar estandes por cultura: $e');
      return [];
    }
  }
  
  /// Salva uma imagem do estande no armazenamento local
  Future<String?> salvarImagem(File imagem, String estandeId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${estandeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imagem.copy('${appDir.path}/estande_images/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Erro ao salvar imagem do estande: $e');
      return null;
    }
  }
  
  /// Calcula o número de plantas por hectare
  int calcularPlantasPorHectare(double plantasPorMetro, double espacamento) {
    // Fórmula: (10000 / (espacamento / 100)) * plantasPorMetro
    return ((10000 / (espacamento / 100)) * plantasPorMetro).round();
  }
  
  /// Gera um novo ID para estande
  String gerarId() {
    return const Uuid().v4();
  }
}
