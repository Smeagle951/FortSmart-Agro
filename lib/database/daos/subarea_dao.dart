import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import '../app_database.dart';
import '../../models/subarea_experimento_model.dart';
import '../../models/drawing_polygon_model.dart';
import '../../models/drawing_vertex_model.dart';
import 'dart:convert';

class SubareaDao {
  static const String _tableName = 'subareas';
  static const String _polygonTableName = 'drawing_polygons';
  static const String _vertexTableName = 'drawing_vertices';

  // Inserir subárea
  Future<int> inserirSubarea(Subarea subarea) async {
    final db = await AppDatabase.instance.database;
    
    // Inserir polígono primeiro
    final polygonId = await _inserirPolygon(subarea.polygon);
    
    // Inserir subárea
    final subareaMap = subarea.toMap();
    subareaMap['geometry'] = jsonEncode(subareaMap['geometry']);
    
    final id = await db.insert(_tableName, subareaMap);
    
    return id;
  }

  // Atualizar subárea
  Future<int> atualizarSubarea(Subarea subarea) async {
    final db = await AppDatabase.instance.database;
    
    if (subarea.id == null) {
      throw Exception('ID da subárea é obrigatório para atualização');
    }
    
    // Atualizar polígono
    await _atualizarPolygon(subarea.polygon);
    
    // Atualizar subárea
    final subareaMap = subarea.toMap();
    subareaMap['geometry'] = jsonEncode(subareaMap['geometry']);
    subareaMap['atualizado_em'] = DateTime.now().toIso8601String();
    
    return await db.update(
      _tableName,
      subareaMap,
      where: 'id = ?',
      whereArgs: [subarea.id],
    );
  }

  // Remover subárea
  Future<int> removerSubarea(int id) async {
    final db = await AppDatabase.instance.database;
    
    // Buscar subárea para obter o ID do polígono
    final subarea = await buscarPorId(id);
    if (subarea != null) {
      // Remover vértices do polígono
      await db.delete(
        _vertexTableName,
        where: 'polygon_id = ?',
        whereArgs: [subarea.polygon.id],
      );
      
      // Remover polígono
      await db.delete(
        _polygonTableName,
        where: 'id = ?',
        whereArgs: [subarea.polygon.id],
      );
    }
    
    // Remover subárea
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar subárea por ID
  Future<Subarea?> buscarPorId(int id) async {
    final db = await AppDatabase.instance.database;
    
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isEmpty) return null;
    
    final polygon = await _buscarPolygonPorSubareaId(id);
    if (polygon == null) return null;
    
    return Subarea.fromMap(result.first, polygon);
  }

  // Buscar subáreas por talhão
  Future<List<Subarea>> buscarPorTalhao(int talhaoId) async {
    final db = await AppDatabase.instance.database;
    
    final results = await db.query(
      _tableName,
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'criado_em DESC',
    );
    
    final subareas = <Subarea>[];
    for (final result in results) {
      final polygon = await _buscarPolygonPorSubareaId(result['id'] as int);
      if (polygon != null) {
        subareas.add(Subarea.fromMap(result, polygon));
      }
    }
    
    return subareas;
  }

  // Buscar todas as subáreas ativas
  Future<List<Subarea>> buscarTodasAtivas() async {
    final db = await AppDatabase.instance.database;
    
    final results = await db.query(
      _tableName,
      orderBy: 'criado_em DESC',
    );
    
    final subareas = <Subarea>[];
    for (final result in results) {
      final polygon = await _buscarPolygonPorSubareaId(result['id'] as int);
      if (polygon != null) {
        subareas.add(Subarea.fromMap(result, polygon));
      }
    }
    
    return subareas;
  }

  // Verificar se nome existe no talhão
  Future<bool> nomeExisteNoTalhao(String nome, int talhaoId, {int? excludeId}) async {
    final db = await AppDatabase.instance.database;
    
    String whereClause = 'nome = ? AND talhao_id = ?';
    List<dynamic> whereArgs = [nome, talhaoId];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final result = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    
    return result.isNotEmpty;
  }

  // Métodos privados para gerenciar polígonos

  Future<String> _inserirPolygon(DrawingPolygon polygon) async {
    final db = await AppDatabase.instance.database;
    
    // Inserir polígono
    final polygonMap = polygon.toMap();
    await db.insert(_polygonTableName, polygonMap);
    
    // Inserir vértices
    for (final vertex in polygon.vertices) {
      final vertexMap = vertex.toMap();
      vertexMap['polygon_id'] = polygon.id;
      await db.insert(_vertexTableName, vertexMap);
    }
    
    return polygon.id;
  }

  Future<void> _atualizarPolygon(DrawingPolygon polygon) async {
    final db = await AppDatabase.instance.database;
    
    // Atualizar polígono
    final polygonMap = polygon.toMap();
    polygonMap['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      _polygonTableName,
      polygonMap,
      where: 'id = ?',
      whereArgs: [polygon.id],
    );
    
    // Remover vértices antigos
    await db.delete(
      _vertexTableName,
      where: 'polygon_id = ?',
      whereArgs: [polygon.id],
    );
    
    // Inserir novos vértices
    for (final vertex in polygon.vertices) {
      final vertexMap = vertex.toMap();
      vertexMap['polygon_id'] = polygon.id;
      await db.insert(_vertexTableName, vertexMap);
    }
  }

  Future<DrawingPolygon?> _buscarPolygonPorSubareaId(int subareaId) async {
    final db = await AppDatabase.instance.database;
    
    // Buscar geometria da subárea
    final subareaResult = await db.query(
      _tableName,
      columns: ['geometry'],
      where: 'id = ?',
      whereArgs: [subareaId],
    );
    
    if (subareaResult.isEmpty) return null;
    
    final geometry = jsonDecode(subareaResult.first['geometry'] as String);
    final coordinates = geometry['coordinates'][0] as List<dynamic>;
    
    // Criar vértices
    final vertices = <DrawingVertex>[];
    for (int i = 0; i < coordinates.length; i++) {
      final coord = coordinates[i] as List<dynamic>;
      vertices.add(DrawingVertex(
        id: '${subareaId}_$i',
        latitude: (coord[1] as num).toDouble(),
        longitude: (coord[0] as num).toDouble(),
        accuracy: 0.0,
        timestamp: DateTime.now(),
        source: 'database',
      ));
    }
    
    // Criar polígono
    return DrawingPolygon(
      id: 'polygon_$subareaId',
      name: 'Subárea $subareaId',
      vertices: vertices,
      createdAt: DateTime.now(),
      isClosed: true,
    );
  }
}
