class EstandeModel {
  final int? id;
  final int talhaoId;
  final int culturaId;
  final int variedadeId;
  final int linhas;
  final double comprimento;
  final double espacamento;
  final int plantasContadas;
  final double resultadoEstande;
  final double? germinacaoEstimada;
  final int? populacaoDesejada;
  final double? dae; // Desvio Absoluto Esperado
  final double? porcentagemFalha;
  final String? observacoes;
  final String? recomendacaoTecnica;
  final DateTime dataAvaliacao;
  final List<String>? fotos;
  final DateTime createdAt;

  EstandeModel({
    this.id,
    required this.talhaoId,
    required this.culturaId,
    required this.variedadeId,
    required this.linhas,
    required this.comprimento,
    required this.espacamento,
    required this.plantasContadas,
    required this.resultadoEstande,
    this.germinacaoEstimada,
    this.populacaoDesejada,
    this.dae,
    this.porcentagemFalha,
    this.observacoes,
    this.recomendacaoTecnica,
    required this.dataAvaliacao,
    this.fotos,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'cultura_id': culturaId,
      'variedade_id': variedadeId,
      'linhas': linhas,
      'comprimento': comprimento,
      'espacamento': espacamento,
      'plantas_contadas': plantasContadas,
      'resultado_estande': resultadoEstande,
      'germinacao_estimada': germinacaoEstimada,
      'populacao_desejada': populacaoDesejada,
      'dae': dae,
      'porcentagem_falha': porcentagemFalha,
      'observacoes': observacoes,
      'recomendacao_tecnica': recomendacaoTecnica,
      'data_avaliacao': dataAvaliacao.toIso8601String(),
      'fotos': fotos?.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EstandeModel.fromMap(Map<String, dynamic> map) {
    return EstandeModel(
      id: map['id'],
      talhaoId: map['talhao_id'],
      culturaId: map['cultura_id'],
      variedadeId: map['variedade_id'],
      linhas: map['linhas'],
      comprimento: map['comprimento'],
      espacamento: map['espacamento'],
      plantasContadas: map['plantas_contadas'],
      resultadoEstande: map['resultado_estande'],
      germinacaoEstimada: map['germinacao_estimada'],
      populacaoDesejada: map['populacao_desejada'],
      dae: map['dae'],
      porcentagemFalha: map['porcentagem_falha'],
      observacoes: map['observacoes'],
      recomendacaoTecnica: map['recomendacao_tecnica'],
      dataAvaliacao: DateTime.parse(map['data_avaliacao']),
      fotos: map['fotos'] != null && map['fotos'].isNotEmpty
          ? map['fotos'].split(',')
          : [],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Calcula o estande em plantas por hectare
  static double calcularEstande(int plantasContadas, int linhas, double comprimento, double espacamento) {
    // Área avaliada (ha) = (linhas × comprimento × espaçamento) / 10.000
    double areaAvaliada = (linhas * comprimento * espacamento) / 10000;
    
    // Estande (plantas/ha) = Plantas contadas ÷ área avaliada
    return plantasContadas / areaAvaliada;
  }
  
  /// Calcula o Desvio Absoluto Esperado (DAE)
  static double calcularDAE(double populacaoReal, int populacaoDesejada) {
    // DAE = |População real - População desejada|
    return (populacaoReal - populacaoDesejada).abs();
  }
  
  /// Calcula a porcentagem de falha
  static double calcularPorcentagemFalha(double dae, int populacaoDesejada) {
    // % Falha = (DAE / População desejada) * 100
    return (dae / populacaoDesejada) * 100;
  }
  
  /// Gera uma recomendação técnica com base na porcentagem de falha
  static String gerarRecomendacaoTecnica(double porcentagemFalha) {
    if (porcentagemFalha <= 5) {
      return "Estande excelente. Nenhuma ação necessária.";
    } else if (porcentagemFalha <= 10) {
      return "Estande bom. Monitorar o desenvolvimento da cultura.";
    } else if (porcentagemFalha <= 20) {
      return "Estande regular. Considerar ajustes na adubação e manejo da cultura.";
    } else if (porcentagemFalha <= 30) {
      return "Estande abaixo do esperado. Avaliar possíveis causas e implementar medidas corretivas.";
    } else {
      return "Estande crítico. Considerar replantio ou medidas compensatórias urgentes.";
    }
  }

  EstandeModel copyWith({
    int? id,
    int? talhaoId,
    int? culturaId,
    int? variedadeId,
    int? linhas,
    double? comprimento,
    double? espacamento,
    int? plantasContadas,
    double? resultadoEstande,
    double? germinacaoEstimada,
    int? populacaoDesejada,
    double? dae,
    double? porcentagemFalha,
    String? observacoes,
    String? recomendacaoTecnica,
    DateTime? dataAvaliacao,
    List<String>? fotos,
    DateTime? createdAt,
  }) {
    return EstandeModel(
      id: id ?? this.id,
      talhaoId: talhaoId ?? this.talhaoId,
      culturaId: culturaId ?? this.culturaId,
      variedadeId: variedadeId ?? this.variedadeId,
      linhas: linhas ?? this.linhas,
      comprimento: comprimento ?? this.comprimento,
      espacamento: espacamento ?? this.espacamento,
      plantasContadas: plantasContadas ?? this.plantasContadas,
      resultadoEstande: resultadoEstande ?? this.resultadoEstande,
      germinacaoEstimada: germinacaoEstimada ?? this.germinacaoEstimada,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      dae: dae ?? this.dae,
      porcentagemFalha: porcentagemFalha ?? this.porcentagemFalha,
      observacoes: observacoes ?? this.observacoes,
      recomendacaoTecnica: recomendacaoTecnica ?? this.recomendacaoTecnica,
      dataAvaliacao: dataAvaliacao ?? this.dataAvaliacao,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
