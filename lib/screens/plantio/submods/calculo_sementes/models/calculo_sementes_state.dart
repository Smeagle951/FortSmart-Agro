import '../../../../../models/seed_calc_result.dart';

/// Estado do cálculo de sementes
class CalculoSementesState {
  final double espacamento;
  final double sementesPorMetro;
  final double populacaoDesejada;
  final double pesoMilSementes;
  final double germinacao;
  final double vigor;
  final double areaManual;
  final double kgUtilizado;
  
  // Campos do bag
  final double sementesPorBag;
  final double pesoBag;
  final int numeroBags;
  final double? pmsManual;
  final double areaDesejada;
  
  // Flags
  final bool usarPMSManual;
  final bool usarAreaDesejada;
  final bool usarAreaManual;
  
  // Modos
  final ModoCalculo modoCalculo;
  final ModoBag modoBag;
  
  // Resultado
  final SeedCalcResult? resultadoCalculo;
  
  // Estados de UI
  final bool isLoading;
  final String? error;

  const CalculoSementesState({
    this.espacamento = 0.0,            // Campo vazio - usuário deve inserir
    this.sementesPorMetro = 0.0,       // Campo vazio - usuário deve inserir
    this.populacaoDesejada = 0.0,      // Campo vazio - usuário deve inserir
    this.pesoMilSementes = 0.0,        // Campo vazio - usuário deve inserir
    this.germinacao = 0.0,             // Campo vazio - usuário deve inserir
    this.vigor = 0.0,                  // Campo vazio - usuário deve inserir
    this.areaManual = 0.0,             // Campo vazio - usuário deve inserir
    this.kgUtilizado = 0,
    this.sementesPorBag = 0.0,         // Campo vazio - usuário deve inserir
    this.pesoBag = 0.0,                // Campo vazio - usuário deve inserir
    this.numeroBags = 0,               // Campo vazio - usuário deve inserir
    this.pmsManual,
    this.areaDesejada = 0.0,           // Campo vazio - usuário deve inserir
    this.usarPMSManual = false,
    this.usarAreaDesejada = false,
    this.usarAreaManual = false,
    this.modoCalculo = ModoCalculo.sementesPorMetro,
    this.modoBag = ModoBag.sementesPorBag,
    this.resultadoCalculo,
    this.isLoading = false,
    this.error,
  });

  CalculoSementesState copyWith({
    double? espacamento,
    double? sementesPorMetro,
    double? populacaoDesejada,
    double? pesoMilSementes,
    double? germinacao,
    double? vigor,
    double? areaManual,
    double? kgUtilizado,
    double? sementesPorBag,
    double? pesoBag,
    int? numeroBags,
    double? pmsManual,
    double? areaDesejada,
    bool? usarPMSManual,
    bool? usarAreaDesejada,
    bool? usarAreaManual,
    ModoCalculo? modoCalculo,
    ModoBag? modoBag,
    SeedCalcResult? resultadoCalculo,
    bool? isLoading,
    String? error,
  }) {
    return CalculoSementesState(
      espacamento: espacamento ?? this.espacamento,
      sementesPorMetro: sementesPorMetro ?? this.sementesPorMetro,
      populacaoDesejada: populacaoDesejada ?? this.populacaoDesejada,
      pesoMilSementes: pesoMilSementes ?? this.pesoMilSementes,
      germinacao: germinacao ?? this.germinacao,
      vigor: vigor ?? this.vigor,
      areaManual: areaManual ?? this.areaManual,
      kgUtilizado: kgUtilizado ?? this.kgUtilizado,
      sementesPorBag: sementesPorBag ?? this.sementesPorBag,
      pesoBag: pesoBag ?? this.pesoBag,
      numeroBags: numeroBags ?? this.numeroBags,
      pmsManual: pmsManual ?? this.pmsManual,
      areaDesejada: areaDesejada ?? this.areaDesejada,
      usarPMSManual: usarPMSManual ?? this.usarPMSManual,
      usarAreaDesejada: usarAreaDesejada ?? this.usarAreaDesejada,
      usarAreaManual: usarAreaManual ?? this.usarAreaManual,
      modoCalculo: modoCalculo ?? this.modoCalculo,
      modoBag: modoBag ?? this.modoBag,
      resultadoCalculo: resultadoCalculo ?? this.resultadoCalculo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Valida se o estado está válido para cálculo
  bool get isValid {
    if (espacamento <= 0) return false;
    if (germinacao <= 0 || germinacao > 100) return false;
    if (vigor <= 0 || vigor > 100) return false;
    if (pesoBag <= 0) return false;
    if (numeroBags <= 0) return false;
    
    // Validação específica para PMS
    if (usarPMSManual) {
      if (pmsManual == null || pmsManual! <= 0) return false;
    } else {
      // Se não está usando PMS manual, precisa ter dados para calcular
      // Precisa ter tanto sementes por bag quanto peso do bag para calcular PMS
      if (sementesPorBag <= 0 || pesoBag <= 0) return false;
    }
    
    switch (modoCalculo) {
      case ModoCalculo.sementesPorMetro:
        return sementesPorMetro > 0;
      case ModoCalculo.populacao:
        return populacaoDesejada > 0;
    }
  }

  /// Retorna os valores para o cálculo
  Map<String, dynamic> get calculoParams {
    return {
      'modeSeedsPerBag': modoBag == ModoBag.sementesPorBag,
      'seedsPerBag': sementesPorBag,
      'Wbag': pesoBag,
      'nBags': numeroBags,
      'PMS_g_per_1000_input': usarPMSManual ? pmsManual : null,
      'sMetro': modoCalculo == ModoCalculo.sementesPorMetro ? sementesPorMetro : 0.0,
      'populacaoDesejada': modoCalculo == ModoCalculo.populacao ? populacaoDesejada : 0.0,
      'modoPopulacao': modoCalculo == ModoCalculo.populacao,
      'esp': espacamento,
      'germPercent': germinacao,
      'vigorPercent': vigor,
      'Nha': usarAreaDesejada ? areaDesejada : 0.0,
    };
  }
}

/// Modos de cálculo disponíveis
enum ModoCalculo { sementesPorMetro, populacao }

/// Modos de bag disponíveis
enum ModoBag { sementesPorBag, pesoPorBag }
