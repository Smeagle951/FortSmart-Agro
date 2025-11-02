import 'ai_organism_data.dart';

/// Modelo expandido para dados de organismos da IA com dados ricos do catálogo
class EnhancedAIOrganismData {
  final int id;
  final String name;
  final String scientificName;
  final String type; // 'pest', 'disease', 'weed'
  final List<String> crops;
  final List<String> symptoms;
  final List<String> managementStrategies;
  final String description;
  final String imageUrl;
  final Map<String, dynamic> characteristics;
  final double severity; // 0.0 a 1.0
  final List<String> keywords;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Novos campos expandidos do catálogo
  final List<FaseDesenvolvimento> fases;
  final Map<String, SeveridadeDetalhada> severidadeDetalhada;
  final CondicoesFavoraveis condicoesFavoraveis;
  final LimiaresAcao limiaresAcao;
  final DanoEconomico danoEconomico;
  final List<String> fenologia;
  final List<String> partesAfetadas;
  final ManejoIntegrado manejoIntegrado;
  final List<String> observacoes;
  final String icone;
  final bool ativo;
  final String categoria;
  final String culturaId;
  final String nivelAcao;

  EnhancedAIOrganismData({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.type,
    required this.crops,
    required this.symptoms,
    required this.managementStrategies,
    required this.description,
    required this.imageUrl,
    this.characteristics = const {},
    this.severity = 0.5,
    this.keywords = const [],
    required this.createdAt,
    required this.updatedAt,
    this.fases = const [],
    this.severidadeDetalhada = const {},
    required this.condicoesFavoraveis,
    required this.limiaresAcao,
    required this.danoEconomico,
    this.fenologia = const [],
    this.partesAfetadas = const [],
    required this.manejoIntegrado,
    this.observacoes = const [],
    this.icone = '🐛',
    this.ativo = true,
    this.categoria = 'Praga',
    this.culturaId = '',
    this.nivelAcao = '',
  });

  factory EnhancedAIOrganismData.fromMap(Map<String, dynamic> map) {
    return EnhancedAIOrganismData(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      type: map['type'] ?? 'pest',
      crops: List<String>.from(map['crops'] ?? []),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      managementStrategies: List<String>.from(map['managementStrategies'] ?? []),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      characteristics: Map<String, dynamic>.from(map['characteristics'] ?? {}),
      severity: (map['severity'] ?? 0.5).toDouble(),
      keywords: List<String>.from(map['keywords'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      fases: (map['fases'] as List<dynamic>? ?? [])
          .map((f) => FaseDesenvolvimento.fromMap(f))
          .toList(),
      severidadeDetalhada: (map['severidadeDetalhada'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, SeveridadeDetalhada.fromMap(v))),
      condicoesFavoraveis: CondicoesFavoraveis.fromMap(map['condicoesFavoraveis'] ?? {}),
      limiaresAcao: LimiaresAcao.fromMap(map['limiaresAcao'] ?? {}),
      danoEconomico: DanoEconomico.fromMap(map['danoEconomico'] ?? {}),
      fenologia: List<String>.from(map['fenologia'] ?? []),
      partesAfetadas: List<String>.from(map['partesAfetadas'] ?? []),
      manejoIntegrado: ManejoIntegrado.fromMap(map['manejoIntegrado'] ?? {}),
      observacoes: List<String>.from(map['observacoes'] ?? []),
      icone: map['icone'] ?? '🐛',
      ativo: map['ativo'] ?? true,
      categoria: map['categoria'] ?? 'Praga',
      culturaId: map['culturaId'] ?? '',
      nivelAcao: map['nivelAcao'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'type': type,
      'crops': crops,
      'symptoms': symptoms,
      'managementStrategies': managementStrategies,
      'description': description,
      'imageUrl': imageUrl,
      'characteristics': characteristics,
      'severity': severity,
      'keywords': keywords,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'fases': fases.map((f) => f.toMap()).toList(),
      'severidadeDetalhada': severidadeDetalhada.map((k, v) => MapEntry(k, v.toMap())),
      'condicoesFavoraveis': condicoesFavoraveis.toMap(),
      'limiaresAcao': limiaresAcao.toMap(),
      'danoEconomico': danoEconomico.toMap(),
      'fenologia': fenologia,
      'partesAfetadas': partesAfetadas,
      'manejoIntegrado': manejoIntegrado.toMap(),
      'observacoes': observacoes,
      'icone': icone,
      'ativo': ativo,
      'categoria': categoria,
      'culturaId': culturaId,
      'nivelAcao': nivelAcao,
    };
  }

  /// Converte de AIOrganismData básico para EnhancedAIOrganismData
  factory EnhancedAIOrganismData.fromBasicAIOrganismData(
    AIOrganismData basic,
    {
    List<FaseDesenvolvimento>? fases,
    Map<String, SeveridadeDetalhada>? severidadeDetalhada,
    CondicoesFavoraveis? condicoesFavoraveis,
    LimiaresAcao? limiaresAcao,
    DanoEconomico? danoEconomico,
    List<String>? fenologia,
    List<String>? partesAfetadas,
    ManejoIntegrado? manejoIntegrado,
    List<String>? observacoes,
    String? icone,
    bool? ativo,
    String? categoria,
    String? culturaId,
    String? nivelAcao,
  }) {
    return EnhancedAIOrganismData(
      id: basic.id,
      name: basic.name,
      scientificName: basic.scientificName,
      type: basic.type,
      crops: basic.crops,
      symptoms: basic.symptoms,
      managementStrategies: basic.managementStrategies,
      description: basic.description,
      imageUrl: basic.imageUrl,
      characteristics: basic.characteristics,
      severity: basic.severity,
      keywords: basic.keywords,
      createdAt: basic.createdAt,
      updatedAt: basic.updatedAt,
      fases: fases ?? [],
      severidadeDetalhada: severidadeDetalhada ?? {},
      condicoesFavoraveis: condicoesFavoraveis ?? CondicoesFavoraveis(
        temperatura: 'Temperatura ótima',
        umidade: 'Umidade adequada',
      ),
      limiaresAcao: limiaresAcao ?? LimiaresAcao(
        baixo: 10,
        medio: 25,
        alto: 50,
      ),
      danoEconomico: danoEconomico ?? DanoEconomico(
        descricao: 'Dano econômico padrão',
        perdaMaxima: 'Até 30% da produção',
      ),
      fenologia: fenologia ?? [],
      partesAfetadas: partesAfetadas ?? [],
      manejoIntegrado: manejoIntegrado ?? ManejoIntegrado(
        quimico: ['Controle químico padrão'],
        biologico: ['Controle biológico padrão'],
        cultural: ['Controle cultural padrão'],
      ),
      observacoes: observacoes ?? [],
      icone: icone ?? '🐛',
      ativo: ativo ?? true,
      categoria: categoria ?? 'Praga',
      culturaId: culturaId ?? '',
      nivelAcao: nivelAcao ?? '',
    );
  }

  /// Diagnóstico por fase de desenvolvimento
  FaseDesenvolvimento? diagnoseBySize(double sizeMM) {
    for (final fase in fases) {
      if (fase.isSizeInRange(sizeMM)) {
        return fase;
      }
    }
    return null;
  }

  /// Predição de severidade baseada em condições
  String predictSeverity({
    required double temperature,
    required double humidity,
    required int organismCount,
  }) {
    // Verifica condições favoráveis
    final isFavorableConditions = condicoesFavoraveis.isFavorable(temperature, humidity);
    
    // Ajusta contagem baseada nas condições
    final adjustedCount = isFavorableConditions ? (organismCount * 1.5).round() : organismCount;
    
    // Determina severidade baseada nos limiares
    if (adjustedCount <= limiaresAcao.baixo) {
      return 'baixo';
    } else if (adjustedCount <= limiaresAcao.medio) {
      return 'medio';
    } else {
      return 'alto';
    }
  }

  /// Obtém recomendação específica baseada na severidade
  String getRecommendation(String severityLevel) {
    final severidade = severidadeDetalhada[severityLevel];
    return severidade?.acao ?? 'Monitoramento contínuo';
  }

  /// Calcula perda de produtividade estimada
  String getEstimatedProductivityLoss(String severityLevel) {
    final severidade = severidadeDetalhada[severityLevel];
    return severidade?.perdaProdutividade ?? '0-5%';
  }

  /// Obtém cor de alerta para a severidade
  String getAlertColor(String severityLevel) {
    final severidade = severidadeDetalhada[severityLevel];
    return severidade?.corAlerta ?? '#4CAF50';
  }

  EnhancedAIOrganismData copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? type,
    List<String>? crops,
    List<String>? symptoms,
    List<String>? managementStrategies,
    String? description,
    String? imageUrl,
    Map<String, dynamic>? characteristics,
    double? severity,
    List<String>? keywords,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FaseDesenvolvimento>? fases,
    Map<String, SeveridadeDetalhada>? severidadeDetalhada,
    CondicoesFavoraveis? condicoesFavoraveis,
    LimiaresAcao? limiaresAcao,
    DanoEconomico? danoEconomico,
    List<String>? fenologia,
    List<String>? partesAfetadas,
    ManejoIntegrado? manejoIntegrado,
    List<String>? observacoes,
    String? icone,
    bool? ativo,
    String? categoria,
    String? culturaId,
    String? nivelAcao,
  }) {
    return EnhancedAIOrganismData(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      type: type ?? this.type,
      crops: crops ?? this.crops,
      symptoms: symptoms ?? this.symptoms,
      managementStrategies: managementStrategies ?? this.managementStrategies,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      characteristics: characteristics ?? this.characteristics,
      severity: severity ?? this.severity,
      keywords: keywords ?? this.keywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fases: fases ?? this.fases,
      severidadeDetalhada: severidadeDetalhada ?? this.severidadeDetalhada,
      condicoesFavoraveis: condicoesFavoraveis ?? this.condicoesFavoraveis,
      limiaresAcao: limiaresAcao ?? this.limiaresAcao,
      danoEconomico: danoEconomico ?? this.danoEconomico,
      fenologia: fenologia ?? this.fenologia,
      partesAfetadas: partesAfetadas ?? this.partesAfetadas,
      manejoIntegrado: manejoIntegrado ?? this.manejoIntegrado,
      observacoes: observacoes ?? this.observacoes,
      icone: icone ?? this.icone,
      ativo: ativo ?? this.ativo,
      categoria: categoria ?? this.categoria,
      culturaId: culturaId ?? this.culturaId,
      nivelAcao: nivelAcao ?? this.nivelAcao,
    );
  }
}

/// Modelo para fase de desenvolvimento do organismo
class FaseDesenvolvimento {
  final String fase;
  final String tamanhoMM;
  final String danos;
  final String duracaoDias;
  final String caracteristicas;

  FaseDesenvolvimento({
    required this.fase,
    required this.tamanhoMM,
    required this.danos,
    required this.duracaoDias,
    required this.caracteristicas,
  });

  factory FaseDesenvolvimento.fromMap(Map<String, dynamic> map) {
    return FaseDesenvolvimento(
      fase: map['fase'] ?? '',
      tamanhoMM: map['tamanho_mm'] ?? '',
      danos: map['danos'] ?? '',
      duracaoDias: map['duracao_dias'] ?? '',
      caracteristicas: map['caracteristicas'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fase': fase,
      'tamanho_mm': tamanhoMM,
      'danos': danos,
      'duracao_dias': duracaoDias,
      'caracteristicas': caracteristicas,
    };
  }

  /// Verifica se um tamanho está na faixa desta fase
  bool isSizeInRange(double sizeMM) {
    if (tamanhoMM.contains('-')) {
      final parts = tamanhoMM.split('-');
      if (parts.length == 2) {
        final min = double.tryParse(parts[0]) ?? 0;
        final max = double.tryParse(parts[1]) ?? 0;
        return sizeMM >= min && sizeMM <= max;
      }
    } else {
      final targetSize = double.tryParse(tamanhoMM) ?? 0;
      return (sizeMM - targetSize).abs() <= 0.5; // Margem de erro de 0.5mm
    }
    return false;
  }
}

/// Modelo para severidade detalhada
class SeveridadeDetalhada {
  final String descricao;
  final String perdaProdutividade;
  final String corAlerta;
  final String acao;

  SeveridadeDetalhada({
    required this.descricao,
    required this.perdaProdutividade,
    required this.corAlerta,
    required this.acao,
  });

  factory SeveridadeDetalhada.fromMap(Map<String, dynamic> map) {
    return SeveridadeDetalhada(
      descricao: map['descricao'] ?? '',
      perdaProdutividade: map['perda_produtividade'] ?? '',
      corAlerta: map['cor_alerta'] ?? '#4CAF50',
      acao: map['acao'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'perda_produtividade': perdaProdutividade,
      'cor_alerta': corAlerta,
      'acao': acao,
    };
  }
}

/// Modelo para condições favoráveis
class CondicoesFavoraveis {
  final String temperatura;
  final String umidade;
  final String? vento;
  final String? chuva;
  final String? solo;

  CondicoesFavoraveis({
    required this.temperatura,
    required this.umidade,
    this.vento,
    this.chuva,
    this.solo,
  });

  factory CondicoesFavoraveis.fromMap(Map<String, dynamic> map) {
    return CondicoesFavoraveis(
      temperatura: map['temperatura'] ?? '',
      umidade: map['umidade'] ?? '',
      vento: map['vento'],
      chuva: map['chuva'],
      solo: map['solo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperatura': temperatura,
      'umidade': umidade,
      'vento': vento,
      'chuva': chuva,
      'solo': solo,
    };
  }

  /// Verifica se as condições são favoráveis
  bool isFavorable(double temperature, double humidity) {
    // Extrai faixa de temperatura
    if (temperatura.contains('-')) {
      final parts = temperatura.split('-');
      if (parts.length == 2) {
        final minTemp = double.tryParse(parts[0].replaceAll('°C', '')) ?? 0;
        final maxTemp = double.tryParse(parts[1].replaceAll('°C', '')) ?? 0;
        if (temperature < minTemp || temperature > maxTemp) {
          return false;
        }
      }
    }

    // Verifica umidade (assume que >70% é alta umidade)
    if (umidade.toLowerCase().contains('alta') && humidity < 70) {
      return false;
    }

    return true;
  }
}

/// Modelo para limiares de ação
class LimiaresAcao {
  final int baixo;
  final int medio;
  final int alto;
  final String unidade;

  LimiaresAcao({
    required this.baixo,
    required this.medio,
    required this.alto,
    this.unidade = 'unidade',
  });

  factory LimiaresAcao.fromMap(Map<String, dynamic> map) {
    return LimiaresAcao(
      baixo: map['baixo'] ?? 0,
      medio: map['medio'] ?? 0,
      alto: map['alto'] ?? 0,
      unidade: map['unidade'] ?? 'unidade',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baixo': baixo,
      'medio': medio,
      'alto': alto,
      'unidade': unidade,
    };
  }
}

/// Modelo para dano econômico
class DanoEconomico {
  final String descricao;
  final String perdaMaxima;
  final String? custoControle;
  final String? roi;

  DanoEconomico({
    required this.descricao,
    required this.perdaMaxima,
    this.custoControle,
    this.roi,
  });

  factory DanoEconomico.fromMap(Map<String, dynamic> map) {
    return DanoEconomico(
      descricao: map['descricao'] ?? '',
      perdaMaxima: map['perda_maxima'] ?? '',
      custoControle: map['custo_controle'],
      roi: map['roi'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'perda_maxima': perdaMaxima,
      'custo_controle': custoControle,
      'roi': roi,
    };
  }
}

/// Modelo para manejo integrado
class ManejoIntegrado {
  final List<String> quimico;
  final List<String> biologico;
  final List<String> cultural;
  final List<String>? fisico;

  ManejoIntegrado({
    required this.quimico,
    required this.biologico,
    required this.cultural,
    this.fisico,
  });

  factory ManejoIntegrado.fromMap(Map<String, dynamic> map) {
    return ManejoIntegrado(
      quimico: List<String>.from(map['quimico'] ?? []),
      biologico: List<String>.from(map['biologico'] ?? []),
      cultural: List<String>.from(map['cultural'] ?? []),
      fisico: map['fisico'] != null ? List<String>.from(map['fisico']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quimico': quimico,
      'biologico': biologico,
      'cultural': cultural,
      'fisico': fisico,
    };
  }
}

