/// Serviço universal para calibração de máquinas agrícolas
/// Suporta diferentes tipos de máquinas: Stara Tornado, Kuhn Accura, etc.
class UniversalCalibrationService {
  
  /// Tipos de máquinas suportadas (exemplos - usuário pode inserir qualquer máquina)
  static const Map<String, Map<String, dynamic>> machineTypes = {
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
    'jan_lancer_1350': {
      'modelo': 'Jan Lancer 1350',
      'sistema': 'Sistema de disco com distribuição pneumática',
      'largura_padrao': 30.0,
      'fator_correcao': 0.92,
      'velocidade_min': 5.0,
      'velocidade_max': 18.0,
      'tolerancia_erro': 5.0,
    },
    'personalizada': {
      'modelo': 'Máquina Personalizada',
      'sistema': 'Sistema personalizado',
      'largura_padrao': 0.0, // Será definida pelo usuário
      'fator_correcao': 1.0, // Fator padrão, pode ser ajustado
      'velocidade_min': 3.0,
      'velocidade_max': 20.0,
      'tolerancia_erro': 5.0,
    },
  };

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
    final specs = machineTypes[tipoMaquina];
    if (specs == null) {
      throw ArgumentError('Tipo de máquina não suportado: $tipoMaquina');
    }

    // Calcular distância percorrida
    final velocidadeMs = velocidadeKmh * 1000.0 / 3600.0; // km/h para m/s
    final distanciaPercorrida = velocidadeMs * tempoSegundos;

    // Calcular área coberta
    final areaCoberta = distanciaPercorrida * larguraFaixa; // m²
    final areaHectares = areaCoberta / 10000.0; // ha

    // Calcular taxa real aplicada
    final taxaRealAplicada = valorColetadoKg / areaHectares; // kg/ha

    // Calcular erro percentual
    final erroPercentual = ((taxaRealAplicada - taxaDesejadaKgHa) / taxaDesejadaKgHa) * 100.0;

    // Calcular fator de ajuste
    final fatorAjuste = taxaDesejadaKgHa / taxaRealAplicada;

    // Determinar status de tolerância
    final tolerancia = specs['tolerancia_erro'] as double;
    final statusTolerancia = erroPercentual.abs() <= tolerancia 
        ? 'Dentro da tolerância' 
        : 'Fora da tolerância';

    // Gerar recomendação de ajuste
    String recomendacaoAjuste = '';
    double aberturaSugerida = 0.0;
    
    if (erroPercentual.abs() > tolerancia) {
      if (erroPercentual > 0) {
        recomendacaoAjuste = 'Reduzir abertura da comporta em ${(erroPercentual / 2).toStringAsFixed(1)}%';
        aberturaSugerida = (aberturaAtual ?? 50.0) - (erroPercentual / 2);
      } else {
        recomendacaoAjuste = 'Aumentar abertura da comporta em ${(erroPercentual.abs() / 2).toStringAsFixed(1)}%';
        aberturaSugerida = (aberturaAtual ?? 50.0) + (erroPercentual.abs() / 2);
      }
    } else {
      recomendacaoAjuste = 'Calibração adequada, manter configurações atuais';
      aberturaSugerida = aberturaAtual ?? 50.0;
    }

    // Determinar se precisa recalibrar
    final precisaRecalibrar = erroPercentual.abs() > tolerancia;

    return UniversalCalibrationResult(
      tipoMaquina: tipoMaquina,
      modeloMaquina: specs['modelo'] as String,
      distanciaPercorrida: distanciaPercorrida,
      areaCoberta: areaCoberta,
      areaHectares: areaHectares,
      taxaRealAplicada: taxaRealAplicada,
      erroPercentual: erroPercentual,
      fatorAjuste: fatorAjuste,
      statusTolerancia: statusTolerancia,
      recomendacaoAjuste: recomendacaoAjuste,
      aberturaSugerida: aberturaSugerida,
      precisaRecalibrar: precisaRecalibrar,
      infoMaquina: specs,
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
    final specs = machineTypes[tipoMaquina];
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

    // Validações específicas para o tipo de máquina (apenas se não for personalizada)
    final larguraPadrao = specs['largura_padrao'] as double;
    if (larguraPadrao > 0 && (larguraFaixa - larguraPadrao).abs() > 1.0) {
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

  /// Obtém informações técnicas de uma máquina
  static Map<String, dynamic> obterInfoTecnica(String tipoMaquina) {
    return machineTypes[tipoMaquina] ?? {
      'modelo': 'Máquina Desconhecida',
      'sistema': 'Sistema não identificado',
      'largura_padrao': 0.0,
      'fator_correcao': 1.0,
      'velocidade_min': 3.0,
      'velocidade_max': 20.0,
      'tolerancia_erro': 5.0,
    };
  }

  /// Lista todas as máquinas disponíveis
  static List<Map<String, dynamic>> listarMaquinasDisponiveis() {
    return machineTypes.entries.map((entry) {
      final info = entry.value;
      return {
        'tipo': entry.key,
        'modelo': info['modelo'],
        'sistema': info['sistema'],
        'largura_padrao': info['largura_padrao'],
        'fator_correcao': info['fator_correcao'],
        'velocidade_min': info['velocidade_min'],
        'velocidade_max': info['velocidade_max'],
        'tolerancia_erro': info['tolerancia_erro'],
      };
    }).toList();
  }

  /// Obtém lista de tipos de máquinas
  static List<String> obterTiposMaquinas() {
    return machineTypes.keys.toList();
  }

  /// Obtém lista de modelos de máquinas
  static List<String> obterModelosMaquinas() {
    return machineTypes.values.map((info) => info['modelo'] as String).toList();
  }
}

/// Resultado universal da calibração
class UniversalCalibrationResult {
  final String tipoMaquina; // Tipo da máquina usada
  final String modeloMaquina; // Modelo da máquina
  final double distanciaPercorrida; // metros
  final double areaCoberta; // m²
  final double areaHectares; // ha
  final double taxaRealAplicada; // kg/ha
  final double erroPercentual; // %
  final double fatorAjuste; // Fator para ajustar dosagem
  final String statusTolerancia; // 'Dentro da tolerância' ou 'Fora da tolerância'
  final String recomendacaoAjuste; // Recomendação de ajuste
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