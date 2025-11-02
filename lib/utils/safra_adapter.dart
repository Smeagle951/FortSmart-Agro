import 'package:flutter/material.dart';
import '../models/safra_model.dart';

/// Classe utilitária para adaptar diferentes representações de safras
/// Facilita a criação e conversão de SafraModel com valores padrão para campos obrigatórios
class SafraAdapter {
  /// Cria uma instância de SafraModel a partir de um mapa, garantindo que todos
  /// os campos obrigatórios estejam presentes
  static SafraModel fromMap(Map<String, dynamic> map) {
    return SafraModel(
      id: map['id'] ?? '',
      talhaoId: map['talhaoId'] ?? '',
      safra: map['safra'] ?? '',
      culturaId: map['culturaId'] ?? '',
      culturaNome: map['culturaNome'] ?? '',
      culturaCor: map['culturaCor'] != null 
          ? Color(map['culturaCor']) 
          : Colors.green,
      dataCriacao: map['dataCriacao'] != null 
          ? DateTime.parse(map['dataCriacao']) 
          : DateTime.now(),
      dataAtualizacao: map['dataAtualizacao'] != null 
          ? DateTime.parse(map['dataAtualizacao']) 
          : DateTime.now(),
      sincronizado: map['sincronizado'] ?? false,
    );
  }

  /// Cria uma instância de SafraModel a partir de parâmetros individuais,
  /// fornecendo valores padrão para campos obrigatórios
  static SafraModel create({
    String? id,
    String? talhaoId,
    String? safra,
    String? culturaId,
    String? culturaNome,
    Color? culturaCor,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? sincronizado,
  }) {
    return SafraModel.fromLegacy(
      id: id,
      talhaoId: talhaoId,
      safra: safra,
      culturaId: culturaId,
      culturaNome: culturaNome,
      culturaCor: culturaCor,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao,
      sincronizado: sincronizado,
    );
  }

  /// Converte uma lista de mapas para uma lista de SafraModel
  static List<SafraModel> listFromMaps(List<dynamic>? mapList) {
    if (mapList == null) return [];
    
    return mapList
        .map((item) => item is Map<String, dynamic> 
            ? fromMap(item) 
            : SafraModel.fromLegacy())
        .toList();
  }

  /// Converte uma lista de SafraModel para uma lista de mapas
  static List<Map<String, dynamic>> listToMaps(List<SafraModel>? safras) {
    if (safras == null) return [];
    
    return safras.map((safra) => safra.toMap()).toList();
  }
}
