import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/subarea_model.dart';
import '../models/ponto_model.dart';

/// Repositório para gerenciar subáreas no banco de dados
class SubareaRepository {
  static const String _tableName = 'subareas';
  static const String _pontosTableName = 'pontos_subarea';

  /// Cria as tabelas se não existirem
  Future<void> _createTablesIfNotExist() async {
    final db = await DatabaseHelper.instance.database;
    
    // Criar tabela de subáreas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        experimento_id TEXT NOT NULL,
        area REAL NOT NULL,
        cor TEXT NOT NULL,
        pontos_count INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // Criar tabela de pontos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_pontosTableName (
        id TEXT PRIMARY KEY,
        subarea_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        ordem INTEGER NOT NULL,
        FOREIGN KEY (subarea_id) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Insere uma nova subárea
  Future<void> insertSubarea(SubareaModel subarea) async {
    await _createTablesIfNotExist();
    final db = await DatabaseHelper.instance.database;
    
    await db.transaction((txn) async {
      // Inserir subárea
      await txn.insert(_tableName, subarea.toMap());
      
      // Inserir pontos
      for (final ponto in subarea.pontos) {
        await txn.insert(_pontosTableName, ponto.toMap());
      }
    });
  }

  /// Atualiza uma subárea existente
  Future<void> updateSubarea(SubareaModel subarea) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.transaction((txn) async {
      // Atualizar subárea
      await txn.update(
        _tableName,
        subarea.toMap(),
        where: 'id = ?',
        whereArgs: [subarea.id],
      );
      
      // Remover pontos antigos
      await txn.delete(
        _pontosTableName,
        where: 'subarea_id = ?',
        whereArgs: [subarea.id],
      );
      
      // Inserir novos pontos
      for (final ponto in subarea.pontos) {
        await txn.insert(_pontosTableName, ponto.toMap());
      }
    });
  }

  /// Remove uma subárea
  Future<void> deleteSubarea(String subareaId) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.transaction((txn) async {
      // Remover pontos
      await txn.delete(
        _pontosTableName,
        where: 'subarea_id = ?',
        whereArgs: [subareaId],
      );
      
      // Remover subárea
      await txn.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [subareaId],
      );
    });
  }

  /// Busca subárea por ID
  Future<SubareaModel?> getSubareaById(String subareaId) async {
    final db = await DatabaseHelper.instance.database;
    
    final subareaMaps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [subareaId],
    );
    
    if (subareaMaps.isEmpty) return null;
    
    final subarea = SubareaModel.fromMap(subareaMaps.first);
    final pontos = await _getPontosBySubareaId(subareaId);
    
    return subarea.copyWith(pontos: pontos);
  }

  /// Busca subáreas por experimento
  Future<List<SubareaModel>> getSubareasByExperimentoId(String experimentoId) async {
    final db = await DatabaseHelper.instance.database;
    
    final subareaMaps = await db.query(
      _tableName,
      where: 'experimento_id = ?',
      whereArgs: [experimentoId],
      orderBy: 'created_at DESC',
    );
    
    final subareas = <SubareaModel>[];
    
    for (final map in subareaMaps) {
      final subarea = SubareaModel.fromMap(map);
      final pontos = await _getPontosBySubareaId(subarea.id);
      subareas.add(subarea.copyWith(pontos: pontos));
    }
    
    return subareas;
  }

  /// Busca pontos de uma subárea
  Future<List<PontoModel>> _getPontosBySubareaId(String subareaId) async {
    final db = await DatabaseHelper.instance.database;
    
    final pontoMaps = await db.query(
      _pontosTableName,
      where: 'subarea_id = ?',
      whereArgs: [subareaId],
    );
    
    return pontoMaps.map((map) => PontoModel.fromMap(map)).toList();
  }

  /// Busca todas as subáreas
  Future<List<SubareaModel>> getAllSubareas() async {
    final db = await DatabaseHelper.instance.database;
    
    final subareaMaps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    
    final subareas = <SubareaModel>[];
    
    for (final map in subareaMaps) {
      final subarea = SubareaModel.fromMap(map);
      final pontos = await _getPontosBySubareaId(subarea.id);
      subareas.add(subarea.copyWith(pontos: pontos));
    }
    
    return subareas;
  }

  /// Alias para compatibilidade com telas existentes
  Future<void> insert(SubareaModel subarea) async {
    return insertSubarea(subarea);
  }

  Future<void> update(SubareaModel subarea) async {
    return updateSubarea(subarea);
  }

  Future<void> delete(String id) async {
    return deleteSubarea(id);
  }

  Future<SubareaModel?> getById(String id) async {
    return getSubareaById(id);
  }

  Future<List<SubareaModel>> getAll() async {
    return getAllSubareas();
  }
}
