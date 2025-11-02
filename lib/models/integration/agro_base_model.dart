import 'dart:convert';

/// Modelo base para todos os modelos agrícolas do sistema
abstract class AgroBaseModel {
  final String id;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final bool sincronizado;
  
  AgroBaseModel({
    required this.id,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.sincronizado,
  });
  
  /// Converte o modelo para um mapa
  Map<String, dynamic> toMap();
  
  /// Converte o modelo para JSON
  String toJson() => json.encode(toMap());
}