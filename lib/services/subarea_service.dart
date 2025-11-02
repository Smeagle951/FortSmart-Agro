import 'package:flutter/material.dart';
import '../database/daos/subarea_dao.dart';
import '../models/subarea_experimento_model.dart';
import '../models/drawing_polygon_model.dart';
import '../models/drawing_vertex_model.dart';
import '../utils/geodetic_utils.dart';

class SubareaService {
  final SubareaDao _subareaDao = SubareaDao();

  Future<Subarea> criarSubarea({
    required int talhaoId,
    required String nome,
    required List<DrawingVertex> vertices,
    String? cultura,
    String? variedade,
    int? populacao,
    Color? cor,
    DateTime? dataInicio,
    String? observacoes,
  }) async {
    if (vertices.length < 3) {
      throw Exception('É necessário pelo menos 3 vértices');
    }

    final polygon = DrawingPolygon(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nome,
      vertices: vertices,
      createdAt: DateTime.now(),
      isClosed: true,
    );

    final latLngVertices = vertices.map((v) => v.toLatLng()).toList();
    final areaM2 = await GeodeticUtils.calculatePolygonArea(latLngVertices);
    final perimetroM = await GeodeticUtils.calculatePolygonPerimeter(latLngVertices);

    final subarea = Subarea(
      talhaoId: talhaoId,
      nome: nome,
      cultura: cultura,
      variedade: variedade,
      populacao: populacao,
      cor: cor ?? Subarea.coresDisponiveis.first,
      polygon: polygon,
      areaHa: areaM2 / 10000,
      perimetroM: perimetroM,
      dataInicio: dataInicio,
      criadoEm: DateTime.now(),
      observacoes: observacoes,
    );

    final id = await _subareaDao.inserirSubarea(subarea);
    return subarea.copyWith(id: id);
  }

  Future<List<Subarea>> buscarPorTalhao(int talhaoId) async {
    return await _subareaDao.buscarPorTalhao(talhaoId);
  }

  Future<void> removerSubarea(int id) async {
    await _subareaDao.removerSubarea(id);
  }
}