import 'package:flutter/material.dart';

/// Classe que representa informações básicas de uma cultura agrícola
/// Usada para simplificar a referência a culturas em outros modelos
class CropInfo {
  /// Identificador único da cultura
  final String id;
  
  /// Nome da cultura
  final String name;
  
  /// Cor associada à cultura para visualização em mapas e gráficos
  final Color color;
  
  /// Construtor padrão
  const CropInfo({
    required this.id,
    required this.name,
    required this.color,
  });
  
  /// Cria uma instância de CropInfo a partir de um mapa
  factory CropInfo.fromMap(Map<String, dynamic> map) {
    return CropInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? map['nome'] ?? '',
      color: map['color'] != null 
          ? Color(map['color']) 
          : (map['cor'] != null ? Color(map['cor']) : Colors.green),
    );
  }
  
  /// Converte a instância para um mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }
  
  /// Cria uma cópia da instância com valores alterados
  CropInfo copyWith({
    String? id,
    String? name,
    Color? color,
  }) {
    return CropInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
  
  @override
  String toString() => 'CropInfo(id: $id, name: $name)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropInfo && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
