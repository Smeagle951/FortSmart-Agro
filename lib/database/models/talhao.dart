import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class Talhao {
  final String id;
  final String nome;
  final double area;
  final List<List<LatLng>> poligonos;
  final String? culturaId;
  final String? safraId;
  final String? variedadeId;
  final DateTime? dataCriacao;
  final DateTime? dataAtualizacao;
  final Map<String, dynamic>? metadados;

  Talhao({
    required this.id,
    required this.nome,
    required this.area,
    required this.poligonos,
    this.culturaId,
    this.safraId,
    this.variedadeId,
    this.dataCriacao,
    this.dataAtualizacao,
    this.metadados,
  });

  Talhao copyWith({
    String? id,
    String? nome,
    double? area,
    List<List<LatLng>>? poligonos,
    String? culturaId,
    String? safraId,
    String? variedadeId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    Map<String, dynamic>? metadados,
  }) {
    return Talhao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      area: area ?? this.area,
      poligonos: poligonos ?? this.poligonos,
      culturaId: culturaId ?? this.culturaId,
      safraId: safraId ?? this.safraId,
      variedadeId: variedadeId ?? this.variedadeId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      metadados: metadados ?? this.metadados,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'area': area,
      'poligonos': poligonosToJson(),
      'culturaId': culturaId,
      'safraId': safraId,
      'variedadeId': variedadeId,
      'dataCriacao': dataCriacao?.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
      'metadados': metadados,
    };
  }

  String poligonosToJson() {
    final List<List<Map<String, double>>> poligonosJson = [];
    
    for (final poligono in poligonos) {
      final List<Map<String, double>> pontos = [];
      for (final ponto in poligono) {
        pontos.add({
          'latitude': ponto.latitude,
          'longitude': ponto.longitude,
        });
      }
      poligonosJson.add(pontos);
    }
    
    return poligonosJson.toString();
  }

  factory Talhao.fromMap(Map<String, dynamic> map) {
    return Talhao(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      area: map['area']?.toDouble() ?? 0.0,
      poligonos: _decodePoligonos(map['poligonos'] ?? '[]'),
      culturaId: map['culturaId'],
      safraId: map['safraId'],
      variedadeId: map['variedadeId'],
      dataCriacao: map['dataCriacao'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dataCriacao']) : null,
      dataAtualizacao: map['dataAtualizacao'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dataAtualizacao']) : null,
      metadados: map['metadados'],
    );
  }

  static List<List<LatLng>> _decodePoligonos(String poligonosJson) {
    try {
      // Implementação simplificada para converter a string JSON em polígonos
      // Esta é uma implementação básica que deve ser adaptada conforme necessário
      final List<List<LatLng>> poligonos = [];
      
      // Lógica de conversão aqui
      // Este é um placeholder - a implementação real dependerá do formato exato do JSON
      
      return poligonos;
    } catch (e) {
      print('Erro ao decodificar polígonos: $e');
      return [];
    }
  }

  @override
  String toString() {
    return 'Talhao(id: $id, nome: $nome, area: $area)';
  }
}
