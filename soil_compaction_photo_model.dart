import 'package:uuid/uuid.dart';

class SoilCompactionPhotoModel {
  final String id;
  final String compactionId; // ID da compactação relacionada
  final String imagePath; // Caminho da imagem no armazenamento
  final String? descricao;
  final DateTime dataCriacao;

  SoilCompactionPhotoModel({
    String? id,
    required this.compactionId,
    required this.imagePath,
    this.descricao,
    DateTime? dataCriacao,
  })  : id = id ?? const Uuid().v4(),
        dataCriacao = dataCriacao ?? DateTime.now();

  // Método para converter o modelo para um Map (para salvar no banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'compactionId': compactionId,
      'imagePath': imagePath,
      'descricao': descricao,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  // Método para criar um modelo a partir de um Map (para carregar do banco de dados)
  factory SoilCompactionPhotoModel.fromMap(Map<String, dynamic> map) {
    return SoilCompactionPhotoModel(
      id: map['id'],
      compactionId: map['compactionId'],
      imagePath: map['imagePath'],
      descricao: map['descricao'],
      dataCriacao: map['dataCriacao'] != null 
          ? DateTime.parse(map['dataCriacao']) 
          : DateTime.now(),
    );
  }

  // Método para criar uma cópia do modelo com algumas alterações
  SoilCompactionPhotoModel copyWith({
    String? id,
    String? compactionId,
    String? imagePath,
    String? descricao,
    DateTime? dataCriacao,
  }) {
    return SoilCompactionPhotoModel(
      id: id ?? this.id,
      compactionId: compactionId ?? this.compactionId,
      imagePath: imagePath ?? this.imagePath,
      descricao: descricao ?? this.descricao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
