import 'dart:convert';

/// Modelo para diagnósticos agronômicos do solo
class SoilDiagnosticModel {
  final int? id;
  final int pointId; // Relacionado ao ponto de coleta
  final String tipoDiagnostico; // compactacao, nematoides, cisto, etc.
  final String severidade; // Baixa / Média / Alta / Crítica
  final String? especieIdentificada; // Ex: Meloidogyne spp., Pratylenchus spp.
  final double? profundidadeAfetada; // cm
  final String? culturaImpactada;
  final DateTime dataIdentificacao;
  final String? metodologiaAvaliacao; // Visual / Laboratorial / Molecular
  final Map<String, dynamic>? dadosLaboratoriais; // Dados detalhados do lab
  final String? observacoes;
  final List<String>? fotosPath;
  final List<String>? recomendacoes; // Recomendações agronômicas

  SoilDiagnosticModel({
    this.id,
    required this.pointId,
    required this.tipoDiagnostico,
    required this.severidade,
    this.especieIdentificada,
    this.profundidadeAfetada,
    this.culturaImpactada,
    required this.dataIdentificacao,
    this.metodologiaAvaliacao,
    this.dadosLaboratoriais,
    this.observacoes,
    this.fotosPath,
    this.recomendacoes,
  });

  SoilDiagnosticModel copyWith({
    int? id,
    int? pointId,
    String? tipoDiagnostico,
    String? severidade,
    String? especieIdentificada,
    double? profundidadeAfetada,
    String? culturaImpactada,
    DateTime? dataIdentificacao,
    String? metodologiaAvaliacao,
    Map<String, dynamic>? dadosLaboratoriais,
    String? observacoes,
    List<String>? fotosPath,
    List<String>? recomendacoes,
  }) {
    return SoilDiagnosticModel(
      id: id ?? this.id,
      pointId: pointId ?? this.pointId,
      tipoDiagnostico: tipoDiagnostico ?? this.tipoDiagnostico,
      severidade: severidade ?? this.severidade,
      especieIdentificada: especieIdentificada ?? this.especieIdentificada,
      profundidadeAfetada: profundidadeAfetada ?? this.profundidadeAfetada,
      culturaImpactada: culturaImpactada ?? this.culturaImpactada,
      dataIdentificacao: dataIdentificacao ?? this.dataIdentificacao,
      metodologiaAvaliacao: metodologiaAvaliacao ?? this.metodologiaAvaliacao,
      dadosLaboratoriais: dadosLaboratoriais ?? this.dadosLaboratoriais,
      observacoes: observacoes ?? this.observacoes,
      fotosPath: fotosPath ?? this.fotosPath,
      recomendacoes: recomendacoes ?? this.recomendacoes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'point_id': pointId,
      'tipo_diagnostico': tipoDiagnostico,
      'severidade': severidade,
      'especie_identificada': especieIdentificada,
      'profundidade_afetada': profundidadeAfetada,
      'cultura_impactada': culturaImpactada,
      'data_identificacao': dataIdentificacao.toIso8601String(),
      'metodologia_avaliacao': metodologiaAvaliacao,
      'dados_laboratoriais': dadosLaboratoriais != null 
          ? jsonEncode(dadosLaboratoriais) 
          : null,
      'observacoes': observacoes,
      'fotos_path': fotosPath != null ? jsonEncode(fotosPath) : null,
      'recomendacoes': recomendacoes != null ? jsonEncode(recomendacoes) : null,
    };
  }

  factory SoilDiagnosticModel.fromMap(Map<String, dynamic> map) {
    return SoilDiagnosticModel(
      id: map['id'],
      pointId: map['point_id'],
      tipoDiagnostico: map['tipo_diagnostico'],
      severidade: map['severidade'],
      especieIdentificada: map['especie_identificada'],
      profundidadeAfetada: map['profundidade_afetada'],
      culturaImpactada: map['cultura_impactada'],
      dataIdentificacao: DateTime.parse(map['data_identificacao']),
      metodologiaAvaliacao: map['metodologia_avaliacao'],
      dadosLaboratoriais: map['dados_laboratoriais'] != null 
          ? jsonDecode(map['dados_laboratoriais'])
          : null,
      observacoes: map['observacoes'],
      fotosPath: map['fotos_path'] != null 
          ? List<String>.from(jsonDecode(map['fotos_path']))
          : null,
      recomendacoes: map['recomendacoes'] != null 
          ? List<String>.from(jsonDecode(map['recomendacoes']))
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SoilDiagnosticModel.fromJson(String source) =>
      SoilDiagnosticModel.fromMap(jsonDecode(source));

  @override
  String toString() {
    return 'SoilDiagnosticModel(id: $id, tipo: $tipoDiagnostico, severidade: $severidade)';
  }
}

/// Tipos de diagnóstico disponíveis
class TipoDiagnostico {
  static const String compactacao = 'Compactação';
  static const String nematoides = 'Nematoides';
  static const String cistoSoja = 'Cisto de Soja';
  static const String baixaDrenagem = 'Baixa Drenagem';
  static const String encharcamento = 'Encharcamento';
  static const String baixaMateriaOrganica = 'Baixa Matéria Orgânica';
  static const String crostaSuperficial = 'Crosta Superficial';
  static const String baixaAtividadeBiologica = 'Baixa Atividade Biológica';
  
  static List<String> get todos => [
    compactacao,
    nematoides,
    cistoSoja,
    baixaDrenagem,
    encharcamento,
    baixaMateriaOrganica,
    crostaSuperficial,
    baixaAtividadeBiologica,
  ];
}

/// Espécies de nematoides comuns
class EspeciesNematoides {
  static const String meloidogyne = 'Meloidogyne spp.';
  static const String pratylenchus = 'Pratylenchus spp.';
  static const String heterodera = 'Heterodera glycines';
  static const String rotylenchulus = 'Rotylenchulus reniformis';
  
  static List<String> get todos => [
    meloidogyne,
    pratylenchus,
    heterodera,
    rotylenchulus,
  ];
}

