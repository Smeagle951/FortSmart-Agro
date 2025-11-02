/// 🌱 Modelo de Teste de Germinação - FortSmart Agro
/// 
/// Seguindo metodologias agronômicas (ABNT NBR 9787) e protocolos de pesquisa
/// Suporte a testes individuais e até 3 subtestes comparativos (A, B, C)

class GerminationTest {
  final int? id;
  final String culture;
  final String variety;
  final String seedLot;
  final int totalSeeds;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final int pureSeeds;
  final int brokenSeeds;
  final int stainedSeeds;
  final String status; // 'active', 'completed', 'cancelled'
  final String? observations;
  final String? photos;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos de subtestes
  final bool useSubtests; // Renomeado de hasSubtests para useSubtests
  final bool hasSubtests; // Mantido para compatibilidade
  final int subtestSeedCount;
  final String? subtestNames; // JSON: ["A", "B", "C"]
  final String? position; // Posição no canteiro
  
  // Resultados finais
  final double? finalGerminationPercentage;
  final double? purityPercentage;
  final double? diseasedPercentage;
  final double? culturalValue;
  final double? averageGerminationTime;
  final int? firstCountDay;
  final int? day50PercentGermination;

  const GerminationTest({
    this.id,
    required this.culture,
    required this.variety,
    required this.seedLot,
    required this.totalSeeds,
    required this.startDate,
    this.expectedEndDate,
    required this.pureSeeds,
    required this.brokenSeeds,
    required this.stainedSeeds,
    this.status = 'active',
    this.observations,
    this.photos,
    required this.createdAt,
    required this.updatedAt,
    this.useSubtests = false,
    this.hasSubtests = false,
    this.subtestSeedCount = 100,
    this.subtestNames,
    this.position,
    this.finalGerminationPercentage,
    this.purityPercentage,
    this.diseasedPercentage,
    this.culturalValue,
    this.averageGerminationTime,
    this.firstCountDay,
    this.day50PercentGermination,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'culture': culture,
      'variety': variety,
      'seedLot': seedLot,
      'totalSeeds': totalSeeds,
      'startDate': startDate.toIso8601String(),
      'expectedEndDate': expectedEndDate?.toIso8601String(),
      'pureSeeds': pureSeeds,
      'brokenSeeds': brokenSeeds,
      'stainedSeeds': stainedSeeds,
      'status': status,
      'observations': observations,
      'photos': photos,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'useSubtests': useSubtests ? 1 : 0,
      'hasSubtests': hasSubtests ? 1 : 0,
      'subtestSeedCount': subtestSeedCount,
      'subtestNames': subtestNames,
      'position': position,
      'finalGerminationPercentage': finalGerminationPercentage,
      'purityPercentage': purityPercentage,
      'diseasedPercentage': diseasedPercentage,
      'culturalValue': culturalValue,
      'averageGerminationTime': averageGerminationTime,
      'firstCountDay': firstCountDay,
      'day50PercentGermination': day50PercentGermination,
    };
  }

  factory GerminationTest.fromMap(Map<String, dynamic> map) {
    return GerminationTest(
      id: map['id'] as int?,
      culture: map['culture'] as String,
      variety: map['variety'] as String,
      seedLot: map['seedLot'] as String,
      totalSeeds: map['totalSeeds'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      expectedEndDate: map['expectedEndDate'] != null 
          ? DateTime.parse(map['expectedEndDate'] as String) 
          : null,
      pureSeeds: map['pureSeeds'] as int,
      brokenSeeds: map['brokenSeeds'] as int,
      stainedSeeds: map['stainedSeeds'] as int,
      status: map['status'] as String,
      observations: map['observations'] as String?,
      photos: map['photos'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      useSubtests: (map['useSubtests'] as int?) == 1,
      hasSubtests: (map['hasSubtests'] as int?) == 1,
      subtestSeedCount: map['subtestSeedCount'] as int? ?? 100,
      subtestNames: map['subtestNames'] as String?,
      position: map['position'] as String?,
      finalGerminationPercentage: map['finalGerminationPercentage'] as double?,
      purityPercentage: map['purityPercentage'] as double?,
      diseasedPercentage: map['diseasedPercentage'] as double?,
      culturalValue: map['culturalValue'] as double?,
      averageGerminationTime: map['averageGerminationTime'] as double?,
      firstCountDay: map['firstCountDay'] as int?,
      day50PercentGermination: map['day50PercentGermination'] as int?,
    );
  }

  GerminationTest copyWith({
    int? id,
    String? culture,
    String? variety,
    String? seedLot,
    int? totalSeeds,
    DateTime? startDate,
    DateTime? expectedEndDate,
    int? pureSeeds,
    int? brokenSeeds,
    int? stainedSeeds,
    String? status,
    String? observations,
    String? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? useSubtests,
    bool? hasSubtests,
    int? subtestSeedCount,
    String? subtestNames,
    String? position,
    double? finalGerminationPercentage,
    double? purityPercentage,
    double? diseasedPercentage,
    double? culturalValue,
    double? averageGerminationTime,
    int? firstCountDay,
    int? day50PercentGermination,
  }) {
    return GerminationTest(
      id: id ?? this.id,
      culture: culture ?? this.culture,
      variety: variety ?? this.variety,
      seedLot: seedLot ?? this.seedLot,
      totalSeeds: totalSeeds ?? this.totalSeeds,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      pureSeeds: pureSeeds ?? this.pureSeeds,
      brokenSeeds: brokenSeeds ?? this.brokenSeeds,
      stainedSeeds: stainedSeeds ?? this.stainedSeeds,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      useSubtests: useSubtests ?? this.useSubtests,
      hasSubtests: hasSubtests ?? this.hasSubtests,
      subtestSeedCount: subtestSeedCount ?? this.subtestSeedCount,
      subtestNames: subtestNames ?? this.subtestNames,
      position: position ?? this.position,
      finalGerminationPercentage: finalGerminationPercentage ?? this.finalGerminationPercentage,
      purityPercentage: purityPercentage ?? this.purityPercentage,
      diseasedPercentage: diseasedPercentage ?? this.diseasedPercentage,
      culturalValue: culturalValue ?? this.culturalValue,
      averageGerminationTime: averageGerminationTime ?? this.averageGerminationTime,
      firstCountDay: firstCountDay ?? this.firstCountDay,
      day50PercentGermination: day50PercentGermination ?? this.day50PercentGermination,
    );
  }

  /// Calcula a pureza das sementes
  double get purity {
    if (totalSeeds == 0) return 0.0;
    return (pureSeeds / totalSeeds) * 100;
  }

  /// Calcula o percentual de sementes quebradas
  double get brokenPercentage {
    if (totalSeeds == 0) return 0.0;
    return (brokenSeeds / totalSeeds) * 100;
  }

  /// Calcula o percentual de sementes manchadas
  double get stainedPercentage {
    if (totalSeeds == 0) return 0.0;
    return (stainedSeeds / totalSeeds) * 100;
  }

  /// Verifica se o teste está ativo
  bool get isActive => status == 'active';

  /// Verifica se o teste está completo
  bool get isCompleted => status == 'completed';

  /// Verifica se o teste foi cancelado
  bool get isCancelled => status == 'cancelled';

  /// Obtém os nomes dos subtestes como lista
  List<String> get subtestNamesList {
    if (subtestNames == null || subtestNames!.isEmpty) return [];
    try {
      return List<String>.from(
        (subtestNames!.split(',').map((s) => s.trim()))
      );
    } catch (e) {
      return [];
    }
  }

  /// Define os nomes dos subtestes
  GerminationTest withSubtestNames(List<String> names) {
    return copyWith(subtestNames: names.join(','));
  }
}

/// 🌱 Modelo de Subteste (A, B, C)
class GerminationSubtest {
  final int? id;
  final int germinationTestId;
  final String subtestCode; // 'A', 'B', 'C'
  final String subtestName;
  final int seedCount;
  final String status; // 'active', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;

  const GerminationSubtest({
    this.id,
    required this.germinationTestId,
    required this.subtestCode,
    required this.subtestName,
    required this.seedCount,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testId': germinationTestId,
      'subtestCode': subtestCode,
      'subtestName': subtestName,
      'seedCount': seedCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GerminationSubtest.fromMap(Map<String, dynamic> map) {
    return GerminationSubtest(
      id: map['id'] as int?,
      germinationTestId: map['testId'] as int,
      subtestCode: map['subtestCode'] as String,
      subtestName: map['subtestName'] as String,
      seedCount: map['seedCount'] as int,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  GerminationSubtest copyWith({
    int? id,
    int? germinationTestId,
    String? subtestCode,
    String? subtestName,
    int? seedCount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GerminationSubtest(
      id: id ?? this.id,
      germinationTestId: germinationTestId ?? this.germinationTestId,
      subtestCode: subtestCode ?? this.subtestCode,
      subtestName: subtestName ?? this.subtestName,
      seedCount: seedCount ?? this.seedCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica se o subteste está ativo
  bool get isActive => status == 'active';

  /// Verifica se o subteste está completo
  bool get isCompleted => status == 'completed';
}

/// 🌱 Modelo de Registro Diário de Germinação
class GerminationDailyRecord {
  final int? id;
  final int germinationTestId;
  final int? subtestId; // Para subtestes específicos
  final int day;
  final DateTime recordDate;
  final int normalGerminated;
  final int abnormalGerminated;
  final int diseasedFungi;
  final int diseasedBacteria;
  final int notGerminated;
  final int otherSeeds;
  final int inertMatter;
  final String? observations;
  final String? photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GerminationDailyRecord({
    this.id,
    required this.germinationTestId,
    this.subtestId,
    required this.day,
    required this.recordDate,
    required this.normalGerminated,
    required this.abnormalGerminated,
    required this.diseasedFungi,
    required this.diseasedBacteria,
    required this.notGerminated,
    this.otherSeeds = 0,
    this.inertMatter = 0,
    this.observations,
    this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'germinationTestId': germinationTestId, // Correto: germinationTestId é o nome real da coluna no banco
      'subtestId': subtestId,
      'day': day,
      'recordDate': recordDate.toIso8601String(),
      'normalGerminated': normalGerminated,
      'abnormalGerminated': abnormalGerminated,
      'diseasedFungi': diseasedFungi,
      'diseasedBacteria': diseasedBacteria,
      'notGerminated': notGerminated,
      'otherSeeds': otherSeeds, // Adicionado
      'inertMatter': inertMatter, // Adicionado
      'observations': observations,
      'photos': photos, // Adicionado
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GerminationDailyRecord.fromMap(Map<String, dynamic> map) {
    return GerminationDailyRecord(
      id: map['id'] as int?,
      germinationTestId: map['germinationTestId'] as int, // Correto: germinationTestId é o nome real da coluna no banco
      subtestId: map['subtestId'] as int?,
      day: map['day'] as int,
      recordDate: DateTime.parse(map['recordDate'] as String),
      normalGerminated: map['normalGerminated'] as int,
      abnormalGerminated: map['abnormalGerminated'] as int,
      diseasedFungi: map['diseasedFungi'] as int,
      diseasedBacteria: map['diseasedBacteria'] as int,
      notGerminated: map['notGerminated'] as int,
      otherSeeds: map['otherSeeds'] as int? ?? 0,
      inertMatter: map['inertMatter'] as int? ?? 0,
      observations: map['observations'] as String?,
      photos: map['photos'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  GerminationDailyRecord copyWith({
    int? id,
    int? germinationTestId,
    int? subtestId,
    int? day,
    DateTime? recordDate,
    int? normalGerminated,
    int? abnormalGerminated,
    int? diseasedFungi,
    int? diseasedBacteria,
    int? notGerminated,
    int? otherSeeds,
    int? inertMatter,
    String? observations,
    String? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GerminationDailyRecord(
      id: id ?? this.id,
      germinationTestId: germinationTestId ?? this.germinationTestId,
      subtestId: subtestId ?? this.subtestId,
      day: day ?? this.day,
      recordDate: recordDate ?? this.recordDate,
      normalGerminated: normalGerminated ?? this.normalGerminated,
      abnormalGerminated: abnormalGerminated ?? this.abnormalGerminated,
      diseasedFungi: diseasedFungi ?? this.diseasedFungi,
      diseasedBacteria: diseasedBacteria ?? this.diseasedBacteria,
      notGerminated: notGerminated ?? this.notGerminated,
      otherSeeds: otherSeeds ?? this.otherSeeds,
      inertMatter: inertMatter ?? this.inertMatter,
      observations: observations ?? this.observations,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Total de sementes germinadas (normais + anormais)
  int get totalGerminated => normalGerminated + abnormalGerminated;

  /// Total de sementes contaminadas (fungos + bactérias)
  int get totalContaminated => diseasedFungi + diseasedBacteria;

  /// Total de sementes contadas no dia
  int get totalCounted => totalGerminated + totalContaminated + notGerminated;

  /// Percentual de germinação do dia
  double get germinationPercentage {
    if (totalCounted == 0) return 0.0;
    return (normalGerminated / totalCounted) * 100;
  }

  /// Percentual de contaminação do dia
  double get contaminationPercentage {
    if (totalCounted == 0) return 0.0;
    return (totalContaminated / totalCounted) * 100;
  }

  /// Percentual de pureza do dia
  double get purityPercentage {
    if (totalCounted == 0) return 0.0;
    final pureSeeds = totalCounted - otherSeeds - inertMatter;
    return (pureSeeds / totalCounted) * 100;
  }
}

/// 🌱 Modelo de Registro Diário de Subteste
class GerminationSubtestDailyRecord {
  final int? id;
  final int subtestId;
  final int day;
  final DateTime recordDate;
  final int normalGerminated;
  final int abnormalGerminated;
  final int diseasedFungi;
  final int diseasedBacteria;
  final int notGerminated;
  final int otherSeeds;
  final int inertMatter;
  final String? observations;
  final String? photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GerminationSubtestDailyRecord({
    this.id,
    required this.subtestId,
    required this.day,
    required this.recordDate,
    required this.normalGerminated,
    required this.abnormalGerminated,
    required this.diseasedFungi,
    required this.diseasedBacteria,
    required this.notGerminated,
    required this.otherSeeds,
    required this.inertMatter,
    this.observations,
    this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subtestId': subtestId,
      'day': day,
      'recordDate': recordDate.toIso8601String(),
      'normalGerminated': normalGerminated,
      'abnormalGerminated': abnormalGerminated,
      'diseasedFungi': diseasedFungi,
      'diseasedBacteria': diseasedBacteria,
      'notGerminated': notGerminated,
      'otherSeeds': otherSeeds,
      'inertMatter': inertMatter,
      'observations': observations,
      'photos': photos,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GerminationSubtestDailyRecord.fromMap(Map<String, dynamic> map) {
    return GerminationSubtestDailyRecord(
      id: map['id'] as int?,
      subtestId: map['subtestId'] as int,
      day: map['day'] as int,
      recordDate: DateTime.parse(map['recordDate'] as String),
      normalGerminated: map['normalGerminated'] as int,
      abnormalGerminated: map['abnormalGerminated'] as int,
      diseasedFungi: map['diseasedFungi'] as int,
      diseasedBacteria: map['diseasedBacteria'] as int,
      notGerminated: map['notGerminated'] as int,
      otherSeeds: map['otherSeeds'] as int,
      inertMatter: map['inertMatter'] as int,
      observations: map['observations'] as String?,
      photos: map['photos'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Total de sementes germinadas (normais + anormais)
  int get totalGerminated => normalGerminated + abnormalGerminated;

  /// Total de sementes contaminadas (fungos + bactérias)
  int get totalContaminated => diseasedFungi + diseasedBacteria;

  /// Total de sementes contadas no dia
  int get totalCounted => totalGerminated + totalContaminated + notGerminated;

  /// Percentual de germinação do dia
  double get germinationPercentage {
    if (totalCounted == 0) return 0.0;
    return (normalGerminated / totalCounted) * 100;
  }

  /// Percentual de contaminação do dia
  double get contaminationPercentage {
    if (totalCounted == 0) return 0.0;
    return (totalContaminated / totalCounted) * 100;
  }

  /// Percentual de pureza do dia
  double get purityPercentage {
    if (totalCounted == 0) return 0.0;
    final pureSeeds = totalCounted - otherSeeds - inertMatter;
    return (pureSeeds / totalCounted) * 100;
  }
}

/// 🌱 Modelo de Resultados de Teste
class GerminationTestResults {
  final int testId;
  final double finalGerminationPercentage;
  final double averageGerminationTime;
  final double diseasedPercentage;
  final double purityPercentage;
  final String classification;
  final List<GerminationSubtestResults> subtestResults;
  final DateTime calculatedAt;

  const GerminationTestResults({
    required this.testId,
    required this.finalGerminationPercentage,
    required this.averageGerminationTime,
    required this.diseasedPercentage,
    required this.purityPercentage,
    required this.classification,
    required this.subtestResults,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'finalGerminationPercentage': finalGerminationPercentage,
      'averageGerminationTime': averageGerminationTime,
      'diseasedPercentage': diseasedPercentage,
      'purityPercentage': purityPercentage,
      'classification': classification,
      'subtestResults': subtestResults.map((s) => s.toMap()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory GerminationTestResults.fromMap(Map<String, dynamic> map) {
    return GerminationTestResults(
      testId: map['testId'] as int,
      finalGerminationPercentage: map['finalGerminationPercentage'] as double,
      averageGerminationTime: map['averageGerminationTime'] as double,
      diseasedPercentage: map['diseasedPercentage'] as double,
      purityPercentage: map['purityPercentage'] as double,
      classification: map['classification'] as String,
      subtestResults: (map['subtestResults'] as List)
          .map((s) => GerminationSubtestResults.fromMap(s))
          .toList(),
      calculatedAt: DateTime.parse(map['calculatedAt'] as String),
    );
  }
}

/// 🌱 Modelo de Resultados de Subteste
class GerminationSubtestResults {
  final int subtestId;
  final String subtestCode;
  final String subtestName;
  final double germinationPercentage;
  final double diseasedPercentage;
  final double purityPercentage;
  final String classification;
  final List<GerminationSubtestDailyRecord> dailyRecords;

  const GerminationSubtestResults({
    required this.subtestId,
    required this.subtestCode,
    required this.subtestName,
    required this.germinationPercentage,
    required this.diseasedPercentage,
    required this.purityPercentage,
    required this.classification,
    required this.dailyRecords,
  });

  Map<String, dynamic> toMap() {
    return {
      'subtestId': subtestId,
      'subtestCode': subtestCode,
      'subtestName': subtestName,
      'germinationPercentage': germinationPercentage,
      'diseasedPercentage': diseasedPercentage,
      'purityPercentage': purityPercentage,
      'classification': classification,
      'dailyRecords': dailyRecords.map((r) => r.toMap()).toList(),
    };
  }

  factory GerminationSubtestResults.fromMap(Map<String, dynamic> map) {
    return GerminationSubtestResults(
      subtestId: map['subtestId'] as int,
      subtestCode: map['subtestCode'] as String,
      subtestName: map['subtestName'] as String,
      germinationPercentage: map['germinationPercentage'] as double,
      diseasedPercentage: map['diseasedPercentage'] as double,
      purityPercentage: map['purityPercentage'] as double,
      classification: map['classification'] as String,
      dailyRecords: (map['dailyRecords'] as List)
          .map((r) => GerminationSubtestDailyRecord.fromMap(r))
          .toList(),
    );
  }
}

/// 🌱 Modelo de Configurações de Germinação
class GerminationSettings {
  final double approvalThreshold; // Limite para aprovação (ex: 80%)
  final double alertThreshold; // Limite para alerta (ex: 70%)
  final double diseaseThreshold; // Limite para doenças (ex: 10%)
  final bool autoAlerts; // Alertas automáticos
  final bool autoApproval; // Aprovação automática
  final int defaultSeedCount; // Quantidade padrão de sementes
  final int vigorDays; // Dias para cálculo de vigor
  final String temperature; // Temperatura padrão
  final String humidity; // Umidade padrão

  const GerminationSettings({
    this.approvalThreshold = 80.0,
    this.alertThreshold = 70.0,
    this.diseaseThreshold = 10.0,
    this.autoAlerts = true,
    this.autoApproval = false,
    this.defaultSeedCount = 100,
    this.vigorDays = 5,
    this.temperature = '25°C',
    this.humidity = '60%',
  });

  Map<String, dynamic> toMap() {
    return {
      'approvalThreshold': approvalThreshold,
      'alertThreshold': alertThreshold,
      'diseaseThreshold': diseaseThreshold,
      'autoAlerts': autoAlerts,
      'autoApproval': autoApproval,
      'defaultSeedCount': defaultSeedCount,
      'vigorDays': vigorDays,
      'temperature': temperature,
      'humidity': humidity,
    };
  }

  factory GerminationSettings.fromMap(Map<String, dynamic> map) {
    return GerminationSettings(
      approvalThreshold: map['approvalThreshold'] as double? ?? 80.0,
      alertThreshold: map['alertThreshold'] as double? ?? 70.0,
      diseaseThreshold: map['diseaseThreshold'] as double? ?? 10.0,
      autoAlerts: map['autoAlerts'] as bool? ?? true,
      autoApproval: map['autoApproval'] as bool? ?? false,
      defaultSeedCount: map['defaultSeedCount'] as int? ?? 100,
      vigorDays: map['vigorDays'] as int? ?? 5,
      temperature: map['temperature'] as String? ?? '25°C',
      humidity: map['humidity'] as String? ?? '60%',
    );
  }

  static GerminationSettings defaultSettings() {
    return const GerminationSettings();
  }
}
