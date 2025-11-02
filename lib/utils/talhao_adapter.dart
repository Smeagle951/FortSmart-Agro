import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models/talhao_model.dart';
import '../models/poligono_model.dart';
import '../models/safra_model.dart';
import '../models/crop.dart' as app_crop;
import '../utils/poligono_adapter.dart';
import '../utils/safra_adapter.dart';

/// Classe utilitária para adaptar diferentes representações de talhões
/// Facilita a criação e conversão de TalhaoModel com compatibilidade para código legado
class TalhaoAdapter {
  /// Cria um TalhaoModel a partir de uma lista de pontos (LatLng)
  /// Útil para código legado que usa 'points' em vez de 'poligonos'
  static TalhaoModel fromPoints({
    String? id,
    String? name,
    List<LatLng>? points,
    String? culturaId,
    String? culturaNome,
    Color? culturaCor,
    String? fazendaId,
    String? observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    List<SafraModel>? safras,
    bool? sincronizado,
  }) {
    final talhaoId = id ?? const Uuid().v4();
    
    // Converter points para poligonos
    final poligonos = points != null && points.isNotEmpty
        ? PoligonoAdapter.fromLatLngList(points: points, talhaoId: talhaoId)
        : <PoligonoModel>[];
    
    // Calcular a área total dos polígonos
    double area = 0;
    for (final poligono in poligonos) {
      area += poligono.area;
    }
    
    // Criar um objeto Crop se tivermos informações de cultura
    app_crop.Crop? cropObject;
    if (culturaId != null && culturaNome != null) {
      cropObject = app_crop.Crop(
        id: int.tryParse(culturaId),
        name: culturaNome,
        colorValue: culturaCor?.value,
      );
    }
    
    return TalhaoModel(
      id: talhaoId,
      name: name ?? 'Novo Talhão',
      poligonos: poligonos,
      area: area,
      crop: cropObject,
      fazendaId: fazendaId ?? '',
      observacoes: observacoes,
      dataCriacao: dataCriacao ?? DateTime.now(),
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
      safras: safras ?? [],
      sincronizado: sincronizado ?? false,
      points: poligonos.isNotEmpty ? poligonos.first.pontos : [], // Adicionando points obrigatório
      syncStatus: sincronizado ?? false ? 1 : 0, // Adicionando syncStatus obrigatório
    );
  }

  /// Converte um mapa para TalhaoModel, com suporte para formato legado
  static TalhaoModel fromMap(Map<String, dynamic> map) {
    // Verificar se o mapa usa 'points' (formato legado) ou 'poligonos' (novo formato)
    final hasPoints = map.containsKey('points') && map['points'] != null;
    final hasPoligonos = map.containsKey('poligonos') && map['poligonos'] != null;
    
    final String talhaoId = map['id'] ?? const Uuid().v4();
    List<PoligonoModel> poligonos = [];
    
    // Converter 'points' para poligonos se necessário
    if (hasPoints) {
      final List<dynamic> pointsData = map['points'];
      final List<LatLng> points = pointsData.map((point) {
        if (point is List && point.length >= 2) {
          return LatLng(
            point[0] is num ? (point[0] as num).toDouble() : 0.0,
            point[1] is num ? (point[1] as num).toDouble() : 0.0,
          );
        }
        return LatLng(0, 0);
      }).toList();
      
      poligonos = PoligonoAdapter.fromLatLngList(points: points, talhaoId: talhaoId);
    } 
    // Usar poligonos do mapa se disponível
    else if (hasPoligonos) {
      final List<dynamic> poligonosData = map['poligonos'];
      poligonos = poligonosData.map((poligonoData) {
        if (poligonoData is Map<String, dynamic>) {
          return PoligonoModel.fromMap(poligonoData);
        }
        return PoligonoModel.criar(pontos: [], talhaoId: talhaoId);
      }).toList();
    }
    
    // Converter safras se disponível
    List<SafraModel> safras = [];
    if (map.containsKey('safras') && map['safras'] != null) {
      final safrasRaw = map['safras'] as List;
      if (safrasRaw.isNotEmpty && safrasRaw.first is String) {
        // Usar o construtor fromLegacy que fornece valores padrão
        safras = safrasRaw.map((id) => SafraModel.fromLegacy(
          id: id,
          talhaoId: talhaoId,
          safra: 'Safra atual',
          culturaId: '0',
          culturaNome: 'Cultura não especificada',
          culturaCor: Colors.green,
        )).toList();
      } else if (safrasRaw.isNotEmpty && safrasRaw.first is Map) {
        safras = SafraAdapter.listFromMaps(safrasRaw.cast<Map<String, dynamic>>());
      }
    }
    
    // Calcular a área total dos polígonos
    double area = 0;
    for (final poligono in poligonos) {
      area += poligono.area;
    }
    
    // Criar um objeto Crop se tivermos informações de cultura
    app_crop.Crop? cropObject;
    if (map['culturaId'] != null && map['culturaNome'] != null) {
      cropObject = app_crop.Crop(
        id: map['culturaId'] is int ? map['culturaId'] : int.tryParse(map['culturaId']?.toString() ?? ''),
        name: map['culturaNome']?.toString() ?? '',
        colorValue: map['culturaCor'] is int ? map['culturaCor'] : null,
      );
    }
    
    // Criar o TalhaoModel com os dados convertidos
    return TalhaoModel(
      id: talhaoId,
      name: map['name'] ?? map['nome'] ?? 'Sem nome',
      poligonos: poligonos,
      area: area,
      crop: cropObject,
      fazendaId: map['fazendaId'] ?? '',
      observacoes: map['observacoes'],
      dataCriacao: map['dataCriacao'] != null 
          ? DateTime.parse(map['dataCriacao']) 
          : DateTime.now(),
      dataAtualizacao: map['dataAtualizacao'] != null 
          ? DateTime.parse(map['dataAtualizacao']) 
          : DateTime.now(),
      safras: safras,
      sincronizado: map['sincronizado'] ?? false,
      points: poligonos.isNotEmpty ? poligonos.first.pontos : [], // Adicionando points obrigatório
      syncStatus: map['syncStatus'] ?? (map['sincronizado'] == true ? 1 : 0), // Adicionando syncStatus obrigatório
    );
  }

  /// Converte uma lista de mapas para uma lista de TalhaoModel
  static List<TalhaoModel> listFromMaps(List<dynamic>? mapList) {
    if (mapList == null) return [];
    
    return mapList
        .map((item) => item is Map<String, dynamic> 
            ? fromMap(item) 
            : TalhaoModel(
                id: const Uuid().v4(),
                name: 'Erro de conversão',
                poligonos: [],
                area: 0,
                fazendaId: '',
                dataCriacao: DateTime.now(),
                dataAtualizacao: DateTime.now(),
                safras: [],
                sincronizado: false, points: [], syncStatus: null,
              ))
        .toList();
  }
}
