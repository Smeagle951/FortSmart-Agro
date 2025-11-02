import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

/// Modelo para representar um talhão agrícola com suporte a Google Maps
class TalhaoModel {
  final String id;
  final String name;
  final String cultura;
  final double area;
  final List<List<LatLng>> poligonos;
  final String? observacoes;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final String criadoPor;
  final bool sincronizado;
  
  // Campos adicionais para compatibilidade com TalhaoModel unificado
  final List points;
  final int syncStatus;
  final List safras;
  final String? fazendaId;
  
  /// Retorna a cor associada à cultura do talhão
  Color get cor => _getCulturaColor(cultura);
  
  /// Retorna um ícone representativo da cultura
  String get icone {
    final culturaLower = cultura.toLowerCase();
    
    if (culturaLower.contains('soja')) {
      return '🌱'; // Broto
    } else if (culturaLower.contains('milho')) {
      return '🌽'; // Milho
    } else if (culturaLower.contains('algodão') || culturaLower.contains('algodao')) {
      return '🧺'; // Algodão
    } else if (culturaLower.contains('café')) {
      return '☕'; // Café
    } else if (culturaLower.contains('cana')) {
      return '🌾'; // Arroz/Cana
    } else if (culturaLower.contains('feijão') || culturaLower.contains('feijao')) {
      return '🌰'; // Feijão
    } else if (culturaLower.contains('trigo')) {
      return '🌿'; // Erva
    } else if (culturaLower.contains('girassol')) {
      return '🌻'; // Girassol
    } else {
      return '🌿'; // Planta genérica
    }
  }

  TalhaoModel({
    required this.id,
    required this.name,
    required this.cultura,
    required this.area,
    required this.poligonos,
    this.observacoes,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.criadoPor,
    required this.sincronizado,
    required this.points,
    required this.syncStatus,
    required this.safras,
    this.fazendaId,
  });
  
  /// Cria um novo talhão com valores padrão
  factory TalhaoModel.criar({
    required String name,
    required String cultura,
    required List<List<LatLng>> poligonos,
    String? observacoes,
    String? fazendaId,
  }) {
    final now = DateTime.now();
    final id = const Uuid().v4();
    
    // Calcular área total dos polígonos
    double areaTotal = 0;
    for (final poligono in poligonos) {
      areaTotal += _calcularAreaPoligono(poligono);
    }
    
    // Extrair pontos do primeiro polígono para o campo points (compatibilidade)
    final points = poligonos.isNotEmpty ? poligonos.first : <LatLng>[];
    
    return TalhaoModel(
      id: id,
      name: name,
      cultura: cultura,
      area: areaTotal,
      poligonos: poligonos,
      observacoes: observacoes,
      dataCriacao: now,
      dataAtualizacao: now,
      criadoPor: 'app_user', // Idealmente, usar o ID do usuário logado
      sincronizado: false,
      points: points,
      syncStatus: 0, // 0 = não sincronizado
      safras: [], // Lista vazia de safras
      fazendaId: fazendaId,
    );
  }
  
  /// Cria uma cópia do talhão com alguns valores alterados
  TalhaoModel copyWith({
    String? id,
    String? name,
    String? cultura,
    double? area,
    List<List<LatLng>>? poligonos,
    String? observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    String? criadoPor,
    bool? sincronizado,
    List? points,
    int? syncStatus,
    List? safras,
    String? fazendaId,
  }) {
    return TalhaoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      cultura: cultura ?? this.cultura,
      area: area ?? this.area,
      poligonos: poligonos ?? this.poligonos,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      criadoPor: criadoPor ?? this.criadoPor,
      sincronizado: sincronizado ?? this.sincronizado,
      points: points ?? this.points,
      syncStatus: syncStatus ?? this.syncStatus,
      safras: safras ?? this.safras,
      fazendaId: fazendaId ?? this.fazendaId,
    );
  }
  
  /// Retorna a cor associada a uma cultura específica
  static Color _getCulturaColor(String cultura) {
    final culturaLower = cultura.toLowerCase();
    
    if (culturaLower.contains('soja')) {
      return const Color(0xFF33CC33); // Verde
    } else if (culturaLower.contains('milho')) {
      return const Color(0xFFFFCC00); // Amarelo
    } else if (culturaLower.contains('algodão') || culturaLower.contains('algodao')) {
      return const Color(0xFF00CCFF); // Azul claro
    } else if (culturaLower.contains('café')) {
      return const Color(0xFF996633); // Marrom
    } else if (culturaLower.contains('cana')) {
      return const Color(0xFF00FF99); // Verde-água
    } else if (culturaLower.contains('feijão') || culturaLower.contains('feijao')) {
      return const Color(0xFFFF3333); // Vermelho
    } else if (culturaLower.contains('trigo')) {
      return const Color(0xFFFF9900); // Laranja
    } else if (culturaLower.contains('girassol')) {
      return const Color(0xFFFFFF33); // Amarelo claro
    } else {
      // Gerar uma cor baseada no hash da string da cultura
      final hash = cultura.hashCode.abs();
      return Color.fromARGB(
        255,
        (hash & 0xFF0000) >> 16,
        (hash & 0x00FF00) >> 8,
        hash & 0x0000FF,
      );
    }
  }
  
  /// Calcula a área de um polígono em hectares
  static double _calcularAreaPoligono(List<LatLng> pontos) {
    if (pontos.length < 3) return 0;
    
    const double raioTerra = 6371000; // em metros
    double area = 0;
    
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      
      final p1 = pontos[i];
      final p2 = pontos[j];
      
      final lat1 = p1.latitude * pi / 180;
      final lon1 = p1.longitude * pi / 180;
      final lat2 = p2.latitude * pi / 180;
      final lon2 = p2.longitude * pi / 180;
      
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area * raioTerra * raioTerra / 2;
    area = area.abs();
    
    // Converter de metros quadrados para hectares
    return area / 10000;
  }
}
