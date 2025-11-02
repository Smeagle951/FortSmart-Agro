import 'dart:convert';
import 'package:flutter/material.dart';

/// Modelo para representar um produto agrícola (cultura, variedade, praga, etc.)
class AgriculturalProduct {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final Color color;
  final String type; // 'culture', 'variety', 'pest', etc.
  final String? parentId; // ID do produto pai (ex: variedade -> cultura)
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isPending;
  final bool isSynced;
  
  AgriculturalProduct({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.color,
    required this.type,
    this.parentId,
    this.tags = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isPending = false,
    this.isSynced = false,
  });
  
  /// Cria uma cópia do objeto com os campos especificados alterados
  AgriculturalProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    Color? color,
    String? type,
    String? parentId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isPending,
    bool? isSynced,
  }) {
    return AgriculturalProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
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
      'type': type,
      'parentId': parentId,
      'tags': jsonEncode(tags),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'isPending': isPending ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }
  
  /// Cria um objeto a partir de um Map
  factory AgriculturalProduct.fromMap(Map<String, dynamic> map) {
    return AgriculturalProduct(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      color: Color(map['color'] is int ? map['color'] : int.parse(map['color'].toString())),
      type: map['type'],
      parentId: map['parentId'],
      tags: map['tags'] != null 
          ? (map['tags'] is List 
              ? List<String>.from(map['tags']) 
              : List<String>.from(jsonDecode(map['tags'])))
          : [],
      metadata: map['metadata'] != null 
          ? (map['metadata'] is Map 
              ? Map<String, dynamic>.from(map['metadata'])
              : jsonDecode(map['metadata']))
          : null,
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
  factory AgriculturalProduct.fromJson(String source) => 
      AgriculturalProduct.fromMap(json.decode(source));
  
  /// Verifica se o produto é uma cultura
  bool get isCulture => type == 'culture';
  
  /// Verifica se o produto é uma variedade
  bool get isVariety => type == 'variety';
  
  /// Verifica se o produto é uma praga
  bool get isPest => type == 'pest';
  
  /// Converte para o modelo Crop para compatibilidade com código legado
  Map<String, dynamic> toCropMap() {
    return {
      'id': id,
      'name': name,
      'description': description ?? '',
      'imageUrl': imageUrl ?? '',
      'color': color.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'isPending': isPending ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
    };
  }
  
  @override
  String toString() {
    return 'AgriculturalProduct(id: $id, name: $name, type: $type)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgriculturalProduct && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
