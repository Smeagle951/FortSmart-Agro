import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'crop.dart';
import 'safra_model.dart';

/// Modelo de Talhão unificado com suporte a múltiplas safras
class TalhaoModel {
  // Campos principais
  int? id;
  String name;
  List<LatLng> points;
  double area;
  int? cropId;
  int? safraId;
  Crop? crop;
  SafraModel? safra;
  DateTime createdAt;
  DateTime updatedAt;
  bool synced;
  
  // Lista de safras associadas a este talhão
  List<SafraModel> safras;

  TalhaoModel({
    this.id,
    required this.name,
    required this.points,
    this.area = 0.0,
    this.cropId,
    this.safraId,
    this.crop,
    this.safra,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.synced = false,
    List<SafraModel>? safras,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now(),
    this.safras = safras ?? [];

  /// Converte o modelo para um mapa para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': _pointsToString(),
      'area': area,
      'crop_id': cropId,
      'safra_id': safraId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
      'safras': safras.map((s) => s.toMap()).toList(),
    };
  }

  /// Cria um modelo a partir de um mapa
  factory TalhaoModel.fromMap(Map<String, dynamic> map) {
    final talhao = TalhaoModel(
      id: map['id'],
      name: map['name'] ?? '',
      points: _stringToPoints(map['points']),
      area: map['area'] ?? 0.0,
      cropId: map['crop_id'],
      safraId: map['safra_id'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      synced: map['synced'] == 1,
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
    double calculatedArea = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      calculatedArea += points[i].longitude * points[j].latitude;
      calculatedArea -= points[j].longitude * points[i].latitude;
    }
    
    calculatedArea = (calculatedArea.abs() / 2.0) * 11100000; // Converter para hectares usando fator de conversão correto
    return calculatedArea;
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
  
  /// Retorna a safra sugerida para o ano atual
  static String getSafraAtualSugerida() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    
    // Se estamos no segundo semestre, a safra é do ano atual/próximo
    // Se estamos no primeiro semestre, a safra é do ano anterior/atual
    if (month >= 7) {
      return '$year/${year + 1}';
    } else {
      return '${year - 1}/$year';
    }
  }
}
