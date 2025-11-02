import 'dart:convert';
import 'package:flutter/material.dart';

/// Modelo para representar uma cultura agrícola
import 'package:fortsmart_agro/models/crop.dart' as old_crop;

class Crop {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final Color color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isPending;
  final bool isSynced;
  
  Crop({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isPending = false,
    this.isSynced = false,
  });
  
  /// Cria uma cópia do objeto com os campos especificados alterados
  Crop copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isPending,
    bool? isSynced,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isPending: isPending ?? this.isPending,
      isSynced: isSynced ?? this.isSynced,
    );
  }
  
  /// Converte o objeto para um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'isPending': isPending ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }
  
  /// Cria um objeto a partir de um Map
  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      color: Color(map['color'] is int ? map['color'] : int.parse(map['color'].toString())),
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] 
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] is DateTime 
          ? map['updatedAt'] 
          : DateTime.parse(map['updatedAt']),
      isDeleted: map['isDeleted'] == 1 || map['isDeleted'] == true,
      isPending: map['isPending'] == 1 || map['isPending'] == true,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }
  
  /// Converte o objeto para JSON
  String toJson() => json.encode(toMap());
  
  /// Cria um objeto a partir de JSON
  factory Crop.fromJson(String source) => Crop.fromMap(json.decode(source));
  
  @override
  String toString() {
    return 'Crop(id: $id, name: $name, color: $color)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Crop && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;

  /// Conversão do modelo antigo para o novo
  factory Crop.fromDbModel(old_crop.Crop dbCrop) {
    return Crop(
      id: dbCrop.id?.toString() ?? '',
      name: dbCrop.name,
      description: dbCrop.description,
      imageUrl: dbCrop.imageUrl,
      color: dbCrop.color,
      createdAt: DateTime.now(), // Ajuste se o modelo antigo tiver esses campos
      updatedAt: DateTime.now(),
      // Outros campos opcionais podem ser preenchidos conforme necessário
    );
  }
}

