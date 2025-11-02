import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/enums.dart';

/// Níveis de severidade para infestações
enum SeveridadeLevel {
  BAIXO,
  MODERADO,
  ALTO,
  CRITICO
}

/// Classe para resumir uma ocorrência (praga, doença ou planta daninha)
class OcorrenciaResumo {
  final String nome;
  final OccurrenceType tipo; // PEST, DISEASE, WEED
  final double indiceInfestacao;
  final String? imagemPath;
  
  OcorrenciaResumo({
    required this.nome,
    required this.tipo,
    required this.indiceInfestacao,
    this.imagemPath,
  });
}

/// Modelo para armazenar o resumo de infestação por talhão
class TalhaoResumoModel {
  final String talhaoId;
  final String talhaoNome;
  final double severidadeMedia; // 0-100
  final SeveridadeLevel nivelSeveridade; // BAIXO, MODERADO, ALTO, CRITICO
  final Color corSeveridade; // Verde, Amarelo, Laranja, Vermelho
  final List<OcorrenciaResumo> principaisOcorrencias; // Top 3 ocorrências
  final List<String> diagnosticos; // Diagnósticos baseados nos limiares do catálogo
  final DateTime ultimaAtualizacao;
  final String? imagemRepresentativa; // Caminho para a imagem mais representativa
  
  TalhaoResumoModel({
    required this.talhaoId,
    required this.talhaoNome,
    required this.severidadeMedia,
    required this.nivelSeveridade,
    required this.corSeveridade,
    required this.principaisOcorrencias,
    required this.diagnosticos,
    required this.ultimaAtualizacao,
    this.imagemRepresentativa,
  });
  
  /// Cria um objeto a partir de um Map
  factory TalhaoResumoModel.fromMap(Map<String, dynamic> map) {
    // Converter a lista de ocorrências
    List<OcorrenciaResumo> ocorrencias = [];
    if (map['principaisOcorrencias'] != null) {
      final List<dynamic> ocorrenciasList = map['principaisOcorrencias'];
      ocorrencias = ocorrenciasList.map((item) => OcorrenciaResumo(
        nome: item['nome'],
        tipo: _parseOccurrenceType(item['tipo']),
        indiceInfestacao: item['indiceInfestacao'].toDouble(),
        imagemPath: item['imagemPath'],
      )).toList();
    }
    
    // Converter a lista de diagnósticos
    List<String> diagnosticos = [];
    if (map['diagnosticos'] != null) {
      if (map['diagnosticos'] is List) {
        diagnosticos = List<String>.from(map['diagnosticos']);
      } else if (map['diagnosticos'] is String) {
        try {
          final List<dynamic> diagnosticosList = jsonDecode(map['diagnosticos']);
          diagnosticos = diagnosticosList.map((item) => item.toString()).toList();
        } catch (e) {
          diagnosticos = [map['diagnosticos']];
        }
      }
    }
    
    // Calcular severidade e nível se não estiverem presentes
    double severidade = map['severidadeMedia']?.toDouble() ?? 0.0;
    SeveridadeLevel nivel = map['nivelSeveridade'] != null 
        ? _parseSeveridadeLevel(map['nivelSeveridade'])
        : getNivelSeveridade(severidade);
    Color cor = map['corSeveridade'] != null 
        ? Color(map['corSeveridade'])
        : getCorPorSeveridade(severidade);
    
    return TalhaoResumoModel(
      talhaoId: map['talhaoId'],
      talhaoNome: map['talhaoNome'],
      severidadeMedia: severidade,
      nivelSeveridade: nivel,
      corSeveridade: cor,
      principaisOcorrencias: ocorrencias,
      diagnosticos: diagnosticos,
      ultimaAtualizacao: map['ultimaAtualizacao'] is DateTime 
          ? map['ultimaAtualizacao'] 
          : DateTime.parse(map['ultimaAtualizacao'] ?? DateTime.now().toIso8601String()),
      imagemRepresentativa: map['imagemRepresentativa'],
    );
  }
  
  /// Cria um objeto a partir de JSON
  factory TalhaoResumoModel.fromJson(Map<String, dynamic> json) {
    return TalhaoResumoModel.fromMap(json);
  }
  
  /// Converte o objeto para um Map
  Map<String, dynamic> toMap() {
    return {
      'talhaoId': talhaoId,
      'talhaoNome': talhaoNome,
      'severidadeMedia': severidadeMedia,
      'nivelSeveridade': nivelSeveridade.toString().split('.').last,
      'corSeveridade': corSeveridade.value,
      'principaisOcorrencias': principaisOcorrencias.map((o) => {
        'nome': o.nome,
        'tipo': o.tipo.toString().split('.').last,
        'indiceInfestacao': o.indiceInfestacao,
        'imagemPath': o.imagemPath,
      }).toList(),
      'diagnosticos': diagnosticos,
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
      'imagemRepresentativa': imagemRepresentativa,
    };
  }
  
  /// Converte o objeto para JSON
  Map<String, dynamic> toJson() => toMap();
  
  /// Método auxiliar para converter string em OccurrenceType
  static OccurrenceType _parseOccurrenceType(String? typeStr) {
    if (typeStr == null) return OccurrenceType.pest;
    
    switch (typeStr.toUpperCase()) {
      case 'PEST': return OccurrenceType.pest;
      case 'DISEASE': return OccurrenceType.disease;
      case 'WEED': return OccurrenceType.weed;
      case 'DEFICIENCY': return OccurrenceType.deficiency;
      default: return OccurrenceType.other;
    }
  }
  
  /// Método auxiliar para converter string em SeveridadeLevel
  static SeveridadeLevel _parseSeveridadeLevel(String? levelStr) {
    if (levelStr == null) return SeveridadeLevel.BAIXO;
    
    switch (levelStr.toUpperCase()) {
      case 'BAIXO': return SeveridadeLevel.BAIXO;
      case 'MODERADO': return SeveridadeLevel.MODERADO;
      case 'ALTO': return SeveridadeLevel.ALTO;
      case 'CRITICO': return SeveridadeLevel.CRITICO;
      default: return SeveridadeLevel.BAIXO;
    }
  }
  
  /// Método para calcular a cor baseada na severidade
  static Color getCorPorSeveridade(double severidade) {
    if (severidade < 25) {
      return Colors.green;
    } else if (severidade < 50) {
      return Colors.yellow;
    } else if (severidade < 75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  /// Método para calcular o nível de severidade baseado no índice
  static SeveridadeLevel getNivelSeveridade(double severidade) {
    if (severidade < 25) {
      return SeveridadeLevel.BAIXO;
    } else if (severidade < 50) {
      return SeveridadeLevel.MODERADO;
    } else if (severidade < 75) {
      return SeveridadeLevel.ALTO;
    } else {
      return SeveridadeLevel.CRITICO;
    }
  }
}

/// Classe auxiliar para acumular ocorrências durante o cálculo
class OcorrenciaAcumulada {
  final String nome;
  final OccurrenceType tipo;
  double indiceAcumulado;
  double contagem;
  final String? imagemPath;
  
  OcorrenciaAcumulada({
    required this.nome,
    required this.tipo,
    required this.indiceAcumulado,
    required this.contagem,
    this.imagemPath,
  });
}
