import 'dart:math';

/// Serviço universal para calibração de máquinas agrícolas
/// Suporta diferentes tipos de máquinas: Stara Tornado, Kuhn Accura, etc.
class UniversalCalibrationService {
  
  /// Tipos de máquinas suportadas
  static const Map<String, Map<String, dynamic>> MACHINE_TYPES = {
    'stara_tornado_1300': {
      'modelo': 'Stara Tornado 1300',
      'sistema': 'Bica com 2 pratos',
      'largura_padrao': 27.0,
      'fator_correcao': 0.85,
      'velocidade_min': 5.0,
      'velocidade_max': 15.0,
      'tolerancia_erro': 5.0,
    },
    'kuhn_accura_1200': {
      'modelo': 'Kuhn Accura 1200',
      'sistema': 'Bica com 2 pratos',
      'largura_padrao': 24.0,
      'fator_correcao': 0.88,
      'velocidade_min': 5.0,
      'velocidade_max': 15.0,
      'tolerancia_erro': 5.0,
    },
    'generico_bica': {
      'modelo': 'Máquina Genérica com Bica',
      'sistema': 'Sistema de bica',
      'largura_padrao': 25.0,
      'fator_correcao': 0.90,
      'velocidade_min': 5.0,
      'velocidade_max': 15.0,
      'tolerancia_erro': 5.0,
    },
    'generico_disco': {
      'modelo': 'Máquina Genérica com Disco',
      'sistema': 'Sistema de disco',
      'largura_padrao': 25.0,
      'fator_correcao': 1.0,
      'velocidade_min': 5.0,
      'velocidade_max': 15.0,
      'tolerancia_erro': 5.0,
    },
  };

  /// Resultado universal da calibração
  class UniversalCalibrationResult {
    final String tipoMaquina; // Tipo da máquina usada
    final String modeloMaquina; // Modelo da máquina
    final double distanciaPercorrida; // metros
    final double areaCoberta; // m²
    final double areaHectares; // ha
    final double taxaRealAplicada; // kg/ha
    final double erroPercentual; // %
    final double fatorAjuste; // Fator para ajustar abertura
    final String statusTolerancia; // "Dentro da tolerância" ou "Fora da tolerância"
    final String recomendacaoAjuste; // Recomendação específica
    final double aberturaSugerida; // % de abertura sugerida
    final bool precisaRecalibrar; // Se precisa recalibrar
    final Map<String, dynamic> infoMaquina; // Informações da máquina

    UniversalCalibrationResult({
      required this.tipoMaquina,
      required this.modeloMaquina,
      required this.distanciaPercorrida,
      required this.areaCoberta,
      required this.areaHectares,
      required this.taxaRealAplicada,
      required this.erroPercentual,
      required this.fatorAjuste,
      required this.statusTolerancia,
      required this.recomendacaoAjuste,
      required this.aberturaSugerida,
      required this.precisaRecalibrar,
      required this.infoMaquina,
    });
  }

  /// Calcula calibração universal para diferentes tipos de máquinas
  static UniversalCalibrationResult calcularCalibracao({
    required String tipoMaquina, // 'stara_tornado_1300', 'kuhn_accura_1200', etc.
    required double tempoSegundos,
    required double larguraFaixa, // metros
    required double velocidadeKmh,
    required double valorColetadoKg,
    required double taxaDesejadaKgHa,
    double? aberturaAtual, // % de abertura atual (opcional)
    String? tipoProduto, // Tipo de produto para ajuste de densidade
  }) {
    
    // Obter especificações da máquina
    final specs = MACHINE_TYPES[tipoMaquina];
    if (specs == null) {
      throw ArgumentError('Tipo de máquina não suportado: $tipoMaquina');
    }
    
    // Validações básicas
    if (tempoSegundos <= 0) throw ArgumentError('Tempo deve ser > 0');
    if (larguraFaixa <= 0) throw ArgumentError('Largura da faixa deve ser > 0');
    if (velocidadeKmh <= 0) throw ArgumentError('Velocidade deve ser > 0');
    if (valorColetadoKg <= 0) throw ArgumentError('Valor coletado deve ser > 0');
    if (taxaDesejadaKgHa <= 0) throw ArgumentError('Taxa desejada deve ser > 0');

    // 1. CALCULAR DISTÂNCIA PERCORRIDA
    // D = V × t (onde V em m/s e t em s)
    final velocidadeMs = velocidadeKmh * 1000.0 / 3600.0; // Converter km/h para m/s
    final distanciaPercorrida = velocidadeMs * tempoSegundos;

    // 2. CALCULAR ÁREA COBERTA
    final areaCoberta = distanciaPercorrida * larguraFaixa; // m²
    final areaHectares = areaCoberta / 10000.0; // ha

    // 3. CALCULAR TAXA REAL APLICADA
    // Aplicar fator de correção específico da máquina
    final fatorCorrecao = specs['fator_correcao'] as double;
    final taxaRealAplicada = (valorColetadoKg / areaHectares) * fatorCorrecao;

    // 4. CALCULAR ERRO PERCENTUAL
    final erroPercentual = ((taxaRealAplicada - taxaDesejadaKgHa) / taxaDesejadaKgHa) * 100.0;

    // 5. CALCULAR FATOR DE AJUSTE
    final fatorAjuste = taxaDesejadaKgHa / taxaRealAplicada;

    // 6. DETERMINAR STATUS DE TOLERÂNCIA
    final tolerancia = specs['tolerancia_erro'] as double;
    final statusTolerancia = erroPercentual.abs() <= tolerancia 
        ? "Dentro da tolerância" 
        : "Fora da tolerância";

    // 7. GERAR RECOMENDAÇÃO DE AJUSTE
    String recomendacaoAjuste;
    double aberturaSugerida = 50.0; // % padrão

    if (erroPercentual.abs() <= tolerancia) {
      recomendacaoAjuste = "Calibração OK. Manter configuração atual.";
      aberturaSugerida = aberturaAtual ?? 50.0;
    } else if (erroPercentual > 0) {
      // Taxa real maior que desejada - diminuir abertura
      aberturaSugerida = (aberturaAtual ?? 50.0) * (1.0 - (erroPercentual / 100.0));
      recomendacaoAjuste = "Diminuir abertura da comporta em ${erroPercentual.abs().toStringAsFixed(1)}%";
    } else {
      // Taxa real menor que desejada - aumentar abertura
      aberturaSugerida = (aberturaAtual ?? 50.0) * (1.0 + (erroPercentual.abs() / 100.0));
      recomendacaoAjuste = "Aumentar abertura da comporta em ${erroPercentual.abs().toStringAsFixed(1)}%";
    }

    // Limitar abertura sugerida entre 10% e 100%
    aberturaSugerida = aberturaSugerida.clamp(10.0, 100.0);

    // 8. DETERMINAR SE PRECISA RECALIBRAR
    final precisaRecalibrar = erroPercentual.abs() > tolerancia;

    return UniversalCalibrationResult(
      tipoMaquina: tipoMaquina,
      modeloMaquina: specs['modelo'] as String,
      distanciaPercorrida: double.parse(distanciaPercorrida.toStringAsFixed(2)),
      areaCoberta: double.parse(areaCoberta.toStringAsFixed(2)),
      areaHectares: double.parse(areaHectares.toStringAsFixed(4)),
      taxaRealAplicada: double.parse(taxaRealAplicada.toStringAsFixed(2)),
      erroPercentual: double.parse(erroPercentual.toStringAsFixed(2)),
      fatorAjuste: double.parse(fatorAjuste.toStringAsFixed(3)),
      statusTolerancia: statusTolerancia,
      recomendacaoAjuste: recomendacaoAjuste,
      aberturaSugerida: double.parse(aberturaSugerida.toStringAsFixed(1)),
      precisaRecalibrar: precisaRecalibrar,
      infoMaquina: Map<String, dynamic>.from(specs),
    );
  }

  /// Valida se os dados são realistas para o tipo de máquina especificado
  static Map<String, dynamic> validarDados({
    required String tipoMaquina,
    required double tempoSegundos,
    required double larguraFaixa,
    required double velocidadeKmh,
    required double valorColetadoKg,
    required double taxaDesejadaKgHa,
  }) {
    final specs = MACHINE_TYPES[tipoMaquina];
    if (specs == null) {
      return {
        'valido': false,
        'alertas': ['Tipo de máquina não suportado: $tipoMaquina'],
        'avisos': [],
        'taxa_esperada': 0.0,
      };
    }

    final List<String> alertas = [];
    final List<String> avisos = [];

    // Validações específicas para o tipo de máquina
    final larguraPadrao = specs['largura_padrao'] as double;
    if ((larguraFaixa - larguraPadrao).abs() > 1.0) {
      avisos.add("Largura da faixa (${larguraFaixa}m) diferente do padrão da ${specs['modelo']} (${larguraPadrao}m)");
    }

    final velocidadeMin = specs['velocidade_min'] as double;
    final velocidadeMax = specs['velocidade_max'] as double;
    if (velocidadeKmh < velocidadeMin || velocidadeKmh > velocidadeMax) {
      alertas.add("Velocidade (${velocidadeKmh} km/h) fora da faixa recomendada (${velocidadeMin}-${velocidadeMax} km/h)");
    }

    if (tempoSegundos < 10.0 || tempoSegundos > 120.0) {
      avisos.add("Tempo de coleta (${tempoSegundos}s) fora da faixa recomendada (10-120s)");
    }

    // Calcular taxa esperada para validação
    final velocidadeMs = velocidadeKmh * 1000.0 / 3600.0;
    final distancia = velocidadeMs * tempoSegundos;
    final area = distancia * larguraFaixa / 10000.0; // ha
    final taxaEsperada = valorColetadoKg / area;

    if (taxaEsperada > taxaDesejadaKgHa * 2.0) {
      alertas.add("Valor coletado muito alto para a taxa desejada. Verificar abertura da comporta.");
    } else if (taxaEsperada < taxaDesejadaKgHa * 0.1) {
      alertas.add("Valor coletado muito baixo para a taxa desejada. Verificar se a comporta está aberta.");
    }

    return {
      'valido': alertas.isEmpty,
      'alertas': alertas,
      'avisos': avisos,
      'taxa_esperada': double.parse(taxaEsperada.toStringAsFixed(2)),
      'tipo_maquina': tipoMaquina,
      'modelo_maquina': specs['modelo'],
    };
  }

  /// Obtém informações técnicas de uma máquina específica
  static Map<String, dynamic> obterInfoTecnica(String tipoMaquina) {
    return Map<String, dynamic>.from(MACHINE_TYPES[tipoMaquina] ?? {});
  }

  /// Lista todos os tipos de máquinas disponíveis
  static List<Map<String, dynamic>> listarMaquinasDisponiveis() {
    return MACHINE_TYPES.entries.map((entry) {
      final specs = entry.value;
      return {
        'tipo': entry.key,
        'modelo': specs['modelo'],
        'sistema': specs['sistema'],
        'largura_padrao': specs['largura_padrao'],
      };
    }).toList();
  }

  /// Obtém lista de tipos de máquinas para dropdown
  static List<String> obterTiposMaquinas() {
    return MACHINE_TYPES.keys.toList();
  }

  /// Obtém lista de modelos de máquinas para exibição
  static List<String> obterModelosMaquinas() {
    return MACHINE_TYPES.values.map((specs) => specs['modelo'] as String).toList();
  }
}
