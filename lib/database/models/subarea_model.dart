import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'ponto_model.dart';

/// Modelo para subáreas experimentais
class SubareaModel {
  final String id;
  final String experimentoId;
  final String talhaoId;
  final String nome;
  final String? descricao;
  final int cor; // Cor armazenada como valor inteiro
  final String? cultura;
  final String? variedade;
  final String? produto;
  final double populacaoDesejada;
  final double areaHa;
  final List<PontoModel> pontos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubareaModel({
    required this.id,
    required this.experimentoId,
    required this.talhaoId,
    required this.nome,
    this.descricao,
    required this.cor,
    this.cultura,
    this.variedade,
    this.produto,
    required this.populacaoDesejada,
    required this.areaHa,
    required this.pontos,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma nova subárea
  factory SubareaModel.create({
    required String experimentoId,
    required String talhaoId,
    required String nome,
    String? descricao,
    required int cor,
    String? cultura,
    String? variedade,
    String? produto,
    required double populacaoDesejada,
    required double areaHa,
    required List<LatLng> pontos,
  }) {
    final uuid = Uuid();
    final now = DateTime.now();
    
    final pontosModel = pontos.map((p) => PontoModel(
      id: uuid.v4(),
      latitude: p.latitude,
      longitude: p.longitude,
      subareaId: '', // Será definido após criar a subárea
    )).toList();
    
    final subareaId = uuid.v4();
    
    return SubareaModel(
      id: subareaId,
      experimentoId: experimentoId,
      talhaoId: talhaoId,
      nome: nome,
      descricao: descricao,
      cor: cor,
      cultura: cultura,
      variedade: variedade,
      produto: produto,
      populacaoDesejada: populacaoDesejada,
      areaHa: areaHa,
      pontos: pontosModel.map((p) => p.copyWith(subareaId: subareaId)).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Cria uma cópia da subárea com campos alterados
  SubareaModel copyWith({
    String? id,
    String? experimentoId,
    String? talhaoId,
    String? nome,
    String? descricao,
    int? cor,
    String? cultura,
    String? variedade,
    String? produto,
    double? populacaoDesejada,
    double? areaHa,
    List<PontoModel>? pontos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubareaModel(
      id: id ?? this.id,
      experimentoId: experimentoId ?? this.experimentoId,
      talhaoId: talhaoId ?? this.talhaoId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      cor: cor ?? this.cor,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      produto: produto ?? this.produto,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      areaHa: areaHa ?? this.areaHa,
      pontos: pontos ?? this.pontos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para Map para salvar no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'experimento_id': experimentoId,
      'talhao_id': talhaoId,
      'nome': nome,
      'descricao': descricao,
      'cor': cor,
      'cultura': cultura,
      'variedade': variedade,
      'produto': produto,
      'populacao_desejada': populacaoDesejada,
      'area_ha': areaHa,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Cria a partir de Map do banco
  factory SubareaModel.fromMap(Map<String, dynamic> map) {
    return SubareaModel(
      id: map['id'],
      experimentoId: map['experimento_id'],
      talhaoId: map['talhao_id'],
      nome: map['nome'],
      descricao: map['descricao'],
      cor: map['cor'],
      cultura: map['cultura'],
      variedade: map['variedade'],
      produto: map['produto'],
      populacaoDesejada: map['populacao_desejada'],
      areaHa: map['area_ha'],
      pontos: [], // Pontos serão carregados separadamente
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'SubareaModel(id: $id, nome: $nome, areaHa: $areaHa)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubareaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
