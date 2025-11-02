import 'package:flutter/material.dart';
import 'drawing_polygon_model.dart';
import '../utils/type_utils.dart';

class Subarea {
  final int? id;
  final int talhaoId;
  final String nome;
  final String? cultura;
  final String? variedade;
  final int? populacao;
  final Color cor;
  final DrawingPolygon polygon;
  final double areaHa;
  final double perimetroM;
  final DateTime? dataInicio;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final String? observacoes;

  Subarea({
    this.id,
    required this.talhaoId,
    required this.nome,
    this.cultura,
    this.variedade,
    this.populacao,
    required this.cor,
    required this.polygon,
    required this.areaHa,
    required this.perimetroM,
    this.dataInicio,
    required this.criadoEm,
    this.atualizadoEm,
    this.observacoes,
  });

  // Calcular DAE (Dias Após Emergência)
  int? get dae {
    if (dataInicio == null) return null;
    final now = DateTime.now();
    final difference = now.difference(dataInicio!);
    return difference.inDays;
  }

  // Calcular percentual em relação ao talhão
  double calcularPercentualTalhao(double areaTalhaoHa) {
    if (areaTalhaoHa <= 0) return 0;
    return (areaHa / areaTalhaoHa) * 100;
  }

  // Cores predefinidas para subáreas
  static const List<Color> coresDisponiveis = [
    Color(0xFF2196F3), // Azul
    Color(0xFF4CAF50), // Verde
    Color(0xFFFF9800), // Laranja
    Color(0xFF9C27B0), // Roxo
    Color(0xFFF44336), // Vermelho
  ];

  // Criar subárea a partir de Map do banco
  factory Subarea.fromMap(Map<String, dynamic> map, DrawingPolygon polygon) {
    return Subarea(
      id: map['id'],
      talhaoId: map['talhao_id'] ?? 0,
      nome: map['nome']?.toString() ?? '',
      cultura: map['cultura']?.toString(),
      variedade: map['variedade']?.toString(),
      populacao: map['populacao'],
      cor: TypeUtils.parseColorSafely(map['cor'], fallback: const Color(0xFF2196F3)),
      polygon: polygon,
      areaHa: _parseDouble(map['area_ha']),
      perimetroM: _parseDouble(map['perimetro_m']),
      dataInicio: map['data_inicio'] != null 
          ? DateTime.parse(map['data_inicio'].toString())
          : null,
      criadoEm: DateTime.parse(map['criado_em']?.toString() ?? DateTime.now().toIso8601String()),
      atualizadoEm: map['atualizado_em'] != null 
          ? DateTime.parse(map['atualizado_em'].toString())
          : null,
      observacoes: map['observacoes']?.toString(),
    );
  }

  // Converter para Map para o banco
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'talhao_id': talhaoId,
      'nome': nome,
      'cultura': cultura,
      'variedade': variedade,
      'populacao': populacao,
      'cor': '#${cor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [polygon.latLngVertices.map((latlng) => [latlng.longitude, latlng.latitude]).toList()]
      },
      'area_ha': areaHa,
      'perimetro_m': perimetroM,
      'data_inicio': dataInicio?.toIso8601String(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'talhaoId': talhaoId,
      'nome': nome,
      'cultura': cultura,
      'variedade': variedade,
      'populacao': populacao,
      'cor': cor.value,
      'polygon': polygon.toJson(),
      'areaHa': areaHa,
      'perimetroM': perimetroM,
      'dataInicio': dataInicio?.toIso8601String(),
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm?.toIso8601String(),
      'observacoes': observacoes,
    };
  }

  // Criar a partir de JSON
  factory Subarea.fromJson(Map<String, dynamic> json) {
    return Subarea(
      id: json['id'],
      talhaoId: json['talhaoId'] ?? 0,
      nome: json['nome'] ?? '',
      cultura: json['cultura'],
      variedade: json['variedade'],
      populacao: json['populacao'],
      cor: Color(json['cor'] ?? 0xFF2196F3),
      polygon: DrawingPolygon.fromJson(json['polygon'] ?? {}),
      areaHa: (json['areaHa'] ?? 0).toDouble(),
      perimetroM: (json['perimetroM'] ?? 0).toDouble(),
      dataInicio: json['dataInicio'] != null ? DateTime.parse(json['dataInicio']) : null,
      criadoEm: DateTime.parse(json['criadoEm'] ?? DateTime.now().toIso8601String()),
      atualizadoEm: json['atualizadoEm'] != null ? DateTime.parse(json['atualizadoEm']) : null,
      observacoes: json['observacoes'],
    );
  }

  // Copiar com alterações
  Subarea copyWith({
    int? id,
    int? talhaoId,
    String? nome,
    String? cultura,
    String? variedade,
    int? populacao,
    Color? cor,
    DrawingPolygon? polygon,
    double? areaHa,
    double? perimetroM,
    DateTime? dataInicio,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? observacoes,
  }) {
    return Subarea(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      nome: nome ?? this.nome,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      populacao: populacao ?? this.populacao,
      cor: cor ?? this.cor,
      polygon: polygon ?? this.polygon,
      areaHa: areaHa ?? this.areaHa,
      perimetroM: perimetroM ?? this.perimetroM,
      dataInicio: dataInicio ?? this.dataInicio,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  // Método auxiliar para parsing de double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
