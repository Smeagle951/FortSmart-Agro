import 'package:sqflite/sqflite.dart';

/// Modelo para teste de germinação com subtestes A, B, C
class GerminationTestModel {
  final String id;
  final String loteId;
  final String cultura;
  final String variedade;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String status; // 'em_andamento', 'concluido', 'cancelado'
  final String observacoes;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String usuarioId;
  final int sincronizado;

  // Resultados consolidados
  final double? percentualFinal;
  final String? categoriaFinal;
  final double? vigorFinal;
  final double? purezaFinal;

  const GerminationTestModel({
    required this.id,
    required this.loteId,
    required this.cultura,
    required this.variedade,
    required this.dataInicio,
    this.dataFim,
    required this.status,
    this.observacoes = '',
    required this.criadoEm,
    required this.atualizadoEm,
    required this.usuarioId,
    this.sincronizado = 0,
    this.percentualFinal,
    this.categoriaFinal,
    this.vigorFinal,
    this.purezaFinal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lote_id': loteId,
      'cultura': cultura,
      'variedade': variedade,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'status': status,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'usuario_id': usuarioId,
      'sincronizado': sincronizado,
      'percentual_final': percentualFinal,
      'categoria_final': categoriaFinal,
      'vigor_final': vigorFinal,
      'pureza_final': purezaFinal,
    };
  }

  factory GerminationTestModel.fromMap(Map<String, dynamic> map) {
    return GerminationTestModel(
      id: map['id'] as String,
      loteId: map['lote_id'] as String,
      cultura: map['cultura'] as String,
      variedade: map['variedade'] as String,
      dataInicio: DateTime.parse(map['data_inicio'] as String),
      dataFim: map['data_fim'] != null ? DateTime.parse(map['data_fim'] as String) : null,
      status: map['status'] as String,
      observacoes: map['observacoes'] as String? ?? '',
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
      usuarioId: map['usuario_id'] as String,
      sincronizado: map['sincronizado'] as int? ?? 0,
      percentualFinal: map['percentual_final'] as double?,
      categoriaFinal: map['categoria_final'] as String?,
      vigorFinal: map['vigor_final'] as double?,
      purezaFinal: map['pureza_final'] as double?,
    );
  }

  GerminationTestModel copyWith({
    String? id,
    String? loteId,
    String? cultura,
    String? variedade,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
    String? observacoes,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
    String? usuarioId,
    int? sincronizado,
    double? percentualFinal,
    String? categoriaFinal,
    double? vigorFinal,
    double? purezaFinal,
  }) {
    return GerminationTestModel(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      cultura: cultura ?? this.cultura,
      variedade: variedade ?? this.variedade,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
      usuarioId: usuarioId ?? this.usuarioId,
      sincronizado: sincronizado ?? this.sincronizado,
      percentualFinal: percentualFinal ?? this.percentualFinal,
      categoriaFinal: categoriaFinal ?? this.categoriaFinal,
      vigorFinal: vigorFinal ?? this.vigorFinal,
      purezaFinal: purezaFinal ?? this.purezaFinal,
    );
  }
}

/// Modelo para subtestes A, B, C
class GerminationSubtestModel {
  final String id;
  final String testId;
  final String subtestLabel; // 'A', 'B', 'C'
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final int sincronizado;

  const GerminationSubtestModel({
    required this.id,
    required this.testId,
    required this.subtestLabel,
    required this.criadoEm,
    required this.atualizadoEm,
    this.sincronizado = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'test_id': testId,
      'subtest_label': subtestLabel,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'sincronizado': sincronizado,
    };
  }

  factory GerminationSubtestModel.fromMap(Map<String, dynamic> map) {
    return GerminationSubtestModel(
      id: map['id'] as String,
      testId: map['test_id'] as String,
      subtestLabel: map['subtest_label'] as String,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
      sincronizado: map['sincronizado'] as int? ?? 0,
    );
  }
}

/// Modelo para registros diários de germinação
class GerminationDailyRecordModel {
  final String id;
  final String subtestId;
  final int dia; // Dia da avaliação (3, 5, 7, etc.)
  final int germinadas;
  final int naoGerminadas;
  final int manchas;
  final int podridao;
  final int cotiledonesAmarelados;
  final String vigor; // 'Baixo', 'Médio', 'Alto'
  final double pureza; // Percentual de pureza
  final double percentualGerminacao; // Calculado
  final String categoriaGerminacao; // 'Excelente', 'Boa', 'Regular', 'Ruim'
  final DateTime dataRegistro;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String usuarioId;
  final int sincronizado;

  const GerminationDailyRecordModel({
    required this.id,
    required this.subtestId,
    required this.dia,
    required this.germinadas,
    required this.naoGerminadas,
    required this.manchas,
    required this.podridao,
    required this.cotiledonesAmarelados,
    required this.vigor,
    required this.pureza,
    required this.percentualGerminacao,
    required this.categoriaGerminacao,
    required this.dataRegistro,
    required this.criadoEm,
    required this.atualizadoEm,
    required this.usuarioId,
    this.sincronizado = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subtest_id': subtestId,
      'dia': dia,
      'germinadas': germinadas,
      'nao_germinadas': naoGerminadas,
      'manchas': manchas,
      'podridao': podridao,
      'cotiledones_amarelados': cotiledonesAmarelados,
      'vigor': vigor,
      'pureza': pureza,
      'percentual_germinacao': percentualGerminacao,
      'categoria_germinacao': categoriaGerminacao,
      'data_registro': dataRegistro.toIso8601String(),
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
      'usuario_id': usuarioId,
      'sincronizado': sincronizado,
    };
  }

  factory GerminationDailyRecordModel.fromMap(Map<String, dynamic> map) {
    return GerminationDailyRecordModel(
      id: map['id'] as String,
      subtestId: map['subtest_id'] as String,
      dia: map['dia'] as int,
      germinadas: map['germinadas'] as int,
      naoGerminadas: map['nao_germinadas'] as int,
      manchas: map['manchas'] as int,
      podridao: map['podridao'] as int,
      cotiledonesAmarelados: map['cotiledones_amarelados'] as int,
      vigor: map['vigor'] as String,
      pureza: map['pureza'] as double,
      percentualGerminacao: map['percentual_germinacao'] as double,
      categoriaGerminacao: map['categoria_germinacao'] as String,
      dataRegistro: DateTime.parse(map['data_registro'] as String),
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
      usuarioId: map['usuario_id'] as String,
      sincronizado: map['sincronizado'] as int? ?? 0,
    );
  }

  /// Calcula o percentual de germinação considerando problemas
  double calcularPercentualGerminacao() {
    final totalSementes = germinadas + naoGerminadas;
    if (totalSementes == 0) return 0.0;
    
    // Subtrair problemas do total de germinadas
    final germinadasEfetivas = germinadas - manchas - podridao - cotiledonesAmarelados;
    return (germinadasEfetivas / totalSementes) * 100;
  }

  /// Determina a categoria baseada no percentual
  String determinarCategoria(double percentual) {
    if (percentual >= 90) return 'Excelente';
    if (percentual >= 80) return 'Boa';
    if (percentual >= 70) return 'Regular';
    return 'Ruim';
  }
}

/// Modelo para resultados consolidados do teste
class GerminationTestResultModel {
  final String testId;
  final double percentualMedio;
  final String categoriaMedia;
  final double vigorMedio;
  final double purezaMedia;
  final List<GerminationSubtestResult> subtestes;
  final DateTime calculadoEm;

  const GerminationTestResultModel({
    required this.testId,
    required this.percentualMedio,
    required this.categoriaMedia,
    required this.vigorMedio,
    required this.purezaMedia,
    required this.subtestes,
    required this.calculadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'test_id': testId,
      'percentual_medio': percentualMedio,
      'categoria_media': categoriaMedia,
      'vigor_medio': vigorMedio,
      'pureza_media': purezaMedia,
      'subtestes': subtestes.map((s) => s.toMap()).toList(),
      'calculado_em': calculadoEm.toIso8601String(),
    };
  }

  factory GerminationTestResultModel.fromMap(Map<String, dynamic> map) {
    return GerminationTestResultModel(
      testId: map['test_id'] as String,
      percentualMedio: map['percentual_medio'] as double,
      categoriaMedia: map['categoria_media'] as String,
      vigorMedio: map['vigor_medio'] as double,
      purezaMedia: map['pureza_media'] as double,
      subtestes: (map['subtestes'] as List)
          .map((s) => GerminationSubtestResult.fromMap(s))
          .toList(),
      calculadoEm: DateTime.parse(map['calculado_em'] as String),
    );
  }
}

/// Resultado de um subteste específico
class GerminationSubtestResult {
  final String subtestLabel;
  final double percentualFinal;
  final String categoriaFinal;
  final double vigorMedio;
  final double purezaMedia;
  final List<GerminationDailyRecordModel> registros;

  const GerminationSubtestResult({
    required this.subtestLabel,
    required this.percentualFinal,
    required this.categoriaFinal,
    required this.vigorMedio,
    required this.purezaMedia,
    required this.registros,
  });

  Map<String, dynamic> toMap() {
    return {
      'subtest_label': subtestLabel,
      'percentual_final': percentualFinal,
      'categoria_final': categoriaFinal,
      'vigor_medio': vigorMedio,
      'pureza_media': purezaMedia,
      'registros': registros.map((r) => r.toMap()).toList(),
    };
  }

  factory GerminationSubtestResult.fromMap(Map<String, dynamic> map) {
    return GerminationSubtestResult(
      subtestLabel: map['subtest_label'] as String,
      percentualFinal: map['percentual_final'] as double,
      categoriaFinal: map['categoria_final'] as String,
      vigorMedio: map['vigor_medio'] as double,
      purezaMedia: map['pureza_media'] as double,
      registros: (map['registros'] as List)
          .map((r) => GerminationDailyRecordModel.fromMap(r))
          .toList(),
    );
  }
}
