// Este arquivo está sendo mantido para compatibilidade com código existente
// Todos os imports devem ser direcionados para talhao_model.dart

export 'talhao_model.dart';

// Código abaixo mantido apenas para referência histórica
/*
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'crop.dart';
import 'safra_model.dart';

/// Modelo de Talhão com suporte a múltiplas safras
class TalhaoModel_Old {
  /// Valor da cor em formato int (0xFFRRGGBB) para integração visual
  int? colorValue;
  // Campos principais
  int? id;
  String? name;
  List<LatLng> points;
  double? area;
  int? syncStatus; // 0 = não sincronizado, 1 = sincronizado
  int? cropId;
  int? safraId;
  Crop? crop;
  SafraModel? safra;
  DateTime? createdAt;
  DateTime? updatedAt;
  
  // Campos adicionais para compatibilidade com código existente
  String? nome; // Alias para name
  List<SafraModel> safras = [];
  List<List<LatLng>> poligonos = []; // Lista de polígonos (para compatibilidade)
  DateTime? criadoEm; // Alias para createdAt
  DateTime? atualizadoEm; // Alias para updatedAt
  String? criadoPor;
  bool sincronizado = false; // Alias para syncStatus

  TalhaoModel({
    this.id,
    this.name,
    required this.points,
    this.area,
    this.syncStatus = 0,
    this.cropId,
    this.safraId,
    this.crop,
    this.safra,
    this.createdAt,
    this.updatedAt,
    this.criadoPor,
    List<SafraModel>? safras,
    List<List<LatLng>>? poligonos,
  }) {
    // Inicializar campos de compatibilidade
    nome = name;
    this.safras = safras ?? [];
    this.poligonos = poligonos ?? [points];
    criadoEm = createdAt;
    atualizadoEm = updatedAt;
    sincronizado = syncStatus == 1;
    
    // Se não tiver polígonos, adicionar os pontos como primeiro polígono
    if (this.poligonos.isEmpty) {
      this.poligonos.add(points);
    }
    // Inicializar colorValue pela safra atual ou cultura (se houver)
    if (safraAtual != null) {
      colorValue = safraAtual!.culturaCor.value;
    } else if (crop != null && crop!.colorValue != null) {
      colorValue = crop!.colorValue;
    } else {
      colorValue = Colors.blue.value;
    }
  }

  /// Getter para cor padronizada (para UI)
  int? get getColorValue => colorValue;

  /// Converte o modelo para um mapa para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': _pointsToString(),
      'area': area,
      'sync_status': syncStatus,
      'crop_id': cropId,
      'safra_id': safraId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'safras': safras.map((s) => s.toMap()).toList(),
    };
  }

  /// Cria um modelo a partir de um mapa
  factory TalhaoModel.fromMap(Map<String, dynamic> map) {
    final talhao = TalhaoModel(
      id: map['id'],
      name: map['name'],
      points: _stringToPoints(map['points']),
      area: map['area'],
      syncStatus: map['sync_status'],
      cropId: map['crop_id'],
      safraId: map['safra_id'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
    
    // Carregar safras se disponíveis
    if (map['safras'] != null && map['safras'] is List) {
      talhao.safras = (map['safras'] as List)
          .map((safraMap) => SafraModel.fromMap(safraMap))
          .toList();
    }
    
    return talhao;
  }

  /// Converte a lista de pontos para string
  String _pointsToString() {
    return points.map((p) => '${p.latitude},${p.longitude}').join(';');
  }
  
  /// Converte todos os polígonos para string
  String _polygonsToString() {
    return poligonos.map((polygon) => 
      polygon.map((p) => '${p.latitude},${p.longitude}').join(';')
    ).join('|');
  }

  /// Converte uma string para lista de pontos
  static List<LatLng> _stringToPoints(String? pointsStr) {
    if (pointsStr == null || pointsStr.isEmpty) {
      return [];
    }
    
    List<LatLng> result = [];
    List<String> pointPairs = pointsStr.split(';');
    
    for (String pair in pointPairs) {
      List<String> coords = pair.split(',');
      if (coords.length >= 2) {
        double lat = double.tryParse(coords[0]) ?? 0;
        double lng = double.tryParse(coords[1]) ?? 0;
        result.add(LatLng(lat, lng));
      }
    }
    
    return result;
  }

  /// Calcula a área do talhão em hectares
  double calculateAreaInHectares() {
    if (points.length < 3) {
      return 0.0;
    }
    
    // Implementação do algoritmo de cálculo de área (Fórmula de Gauss)
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    
    area = (area.abs() / 2.0) * 11100000; // Converter para hectares usando fator de conversão correto
    return area;
  }

  /// Retorna a cor do talhão baseada na cultura
  Color getColor() {
    // Verificar se tem safra atual com cultura
    if (safraAtual != null) {
      return safraAtual!.culturaCor;
    }
    
    // Verificar se tem cultura definida diretamente
    if (crop != null) {
      // Tenta obter a cor da cultura
      String? colorHex = crop!.getColorHex();
      if (colorHex != null) {
        return Color(int.parse('0xFF$colorHex'));
      }
    }
    
    // Cor padrão se não tiver cultura ou cor definida
    return Colors.blue;
  }
  
  /// Cria um novo talhão
  static TalhaoModel criar({
    required String nome,
    required List<LatLng> points,
    double? area,
    int? culturaId,
    int? safraId,
  }) {
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    
    return TalhaoModel(
      id: id,
      name: nome,
      points: points,
      area: area ?? 0.0,
      syncStatus: 0,
      cropId: culturaId,
      safraId: safraId,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Adiciona uma nova safra ao talhão
  TalhaoModel adicionarSafra({
    required String safra,
    required String culturaId,
    required String culturaNome,
    required Color culturaCor,
  }) {
    final novaSafra = SafraModel.criar(
      talhaoId: id.toString(),
      safra: safra,
      culturaId: culturaId,
      culturaNome: culturaNome,
      culturaCor: culturaCor,
    );
    
    safras.add(novaSafra);
    return this;
  }
  
  /// Retorna a safra atual (a mais recente)
  SafraModel? get safraAtual {
    if (safras.isEmpty) return null;
    
    // Ordenar por data de criação (mais recente primeiro)
    final safrasOrdenadas = List<SafraModel>.from(safras);
    safrasOrdenadas.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
    
    return safrasOrdenadas.first;
  }
  
  /// Retorna o período da safra atual
  String? get safraAtualPeriodo => safraAtual?.periodo;

  get observacoes => null;

  /// Getter compatível para UI: retorna a cor do talhão
  Color get cor {
    // Safra atual tem cor?
    if (safraAtual != null && safraAtual!.culturaCor != null) {
      return safraAtual!.culturaCor;
    }
    // Crop tem cor?
    if (crop != null && crop!.colorValue != null) {
      return Color(crop!.colorValue!);
    }
    // Campo colorValue definido?
    if (colorValue != null) {
      return Color(colorValue!);
    }
    // Cor padrão
    return Colors.green;
  }

  /// Getter compatível para UI: retorna o nome do talhão
  String get nomeTalhao => name ?? nome ?? '';
}
*/
