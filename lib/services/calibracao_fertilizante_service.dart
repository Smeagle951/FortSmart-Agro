import 'dart:math';
import '../models/calibracao_fertilizante_model.dart';
import '../utils/logger.dart';

/// Serviço para cálculos de calibração de fertilizantes
/// Implementa todas as fórmulas e validações do guia técnico
class CalibracaoFertilizanteService {
  
  /// Calcula o Coeficiente de Variação (CV%)
  /// pesos: lista de pesos coletados em gramas
  /// Retorna CV% com precisão de 2 casas decimais
  static double calcularCV(List<double> pesos) {
    if (pesos.length < 2) return 0.0;
    
    final n = pesos.length;
    final media = pesos.reduce((a, b) => a + b) / n;
    
    // Soma dos quadrados das diferenças
    final somaQuadrados = pesos.map((p) => (p - media) * (p - media))
        .reduce((a, b) => a + b);
    
    // Desvio padrão amostral (n-1)
    final desvioPadrao = sqrt(somaQuadrados / (n - 1));
    
    // CV% = (desvio padrão / média) * 100
    final cv = (desvioPadrao / media) * 100.0;
    
    return double.parse(cv.toStringAsFixed(2));
  }

  /// Calcula a taxa real em kg/ha
  /// pesos: lista de pesos coletados em gramas
  /// distanciaColeta: distância percorrida em metros
  /// espacamento: espaçamento entre bandejas em metros
  /// Retorna taxa real em kg/ha
  static double calcularTaxaRealKgHa(
    List<double> pesos, 
    double distanciaColeta, 
    double espacamento
  ) {
    final n = pesos.length;
    if (n == 0 || distanciaColeta <= 0 || espacamento <= 0) return 0.0;
    
    final sumGramas = pesos.reduce((a, b) => a + b);
    
    // Fórmula: taxa_real = (sum_grams * 10) / (L * N * S)
    // Onde: L = distância, N = número de bandejas, S = espaçamento
    final taxaReal = (sumGramas * 10.0) / (distanciaColeta * n * espacamento);
    
    return double.parse(taxaReal.toStringAsFixed(2));
  }

  /// Calcula a faixa real de aplicação
  /// pesos: lista de pesos coletados em gramas
  /// espacamento: espaçamento entre bandejas em metros
  /// tipoPaleta: "pequena" ou "grande"
  /// Retorna faixa real em metros
  static double calcularFaixaReal(
    List<double> pesos, 
    double espacamento, 
    String tipoPaleta
  ) {
    final n = pesos.length;
    if (n == 0) return 0.0;
    
    final centro = n ~/ 2;
    
    // Calcular média central (3 bandejas centrais quando possível)
    double mediaCentral;
    if (n >= 3) {
      final int c0 = max(0, centro - 1);
      final int c1 = centro;
      final int c2 = min(n - 1, centro + 1);
      mediaCentral = (pesos[c0] + pesos[c1] + pesos[c2]) / 3.0;
    } else {
      mediaCentral = pesos.reduce((a, b) => a + b) / n;
    }
    
    // Limite = 50% da média central
    final limite = mediaCentral * 0.5;
    
    // Encontrar bandejas válidas (>= limite)
    int esquerda = centro;
    while (esquerda > 0 && pesos[esquerda] >= limite) esquerda--;
    
    int direita = centro;
    while (direita < n - 1 && pesos[direita] >= limite) direita++;
    
    final bandejasValidas = direita - esquerda + 1;
    
    // Fator da paleta
    final fatorPaleta = (tipoPaleta.toLowerCase() == 'grande') ? 1.15 : 1.0;
    
    // Faixa real = bandejas válidas * espaçamento * fator paleta
    final faixaReal = bandejasValidas * espacamento * fatorPaleta;
    
    return double.parse(faixaReal.toStringAsFixed(2));
  }

  /// Classifica o CV% em categorias
  /// cv: coeficiente de variação em %
  /// Retorna classificação: "Bom", "Moderado", "Crítico"
  static String classificarCV(double cv) {
    if (cv <= 10.0) {
      return 'Bom';
    } else if (cv <= 15.0) {
      return 'Moderado';
    } else {
      return 'Crítico';
    }
  }

  /// Calcula a média dos pesos
  /// pesos: lista de pesos coletados em gramas
  /// Retorna média em gramas
  static double calcularMedia(List<double> pesos) {
    if (pesos.isEmpty) return 0.0;
    final media = pesos.reduce((a, b) => a + b) / pesos.length;
    return double.parse(media.toStringAsFixed(2));
  }

  /// Calcula o desvio padrão dos pesos
  /// pesos: lista de pesos coletados em gramas
  /// Retorna desvio padrão em gramas
  static double calcularDesvioPadrao(List<double> pesos) {
    if (pesos.length < 2) return 0.0;
    
    final n = pesos.length;
    final media = pesos.reduce((a, b) => a + b) / n;
    
    final somaQuadrados = pesos.map((p) => (p - media) * (p - media))
        .reduce((a, b) => a + b);
    
    final desvioPadrao = sqrt(somaQuadrados / (n - 1));
    return double.parse(desvioPadrao.toStringAsFixed(3));
  }

  /// Calcula a área amostrada
  /// distanciaColeta: distância percorrida em metros
  /// espacamento: espaçamento entre bandejas em metros
  /// numBandejas: número de bandejas
  /// Retorna área em metros quadrados
  static double calcularAreaAmostrada(
    double distanciaColeta, 
    double espacamento, 
    int numBandejas
  ) {
    return distanciaColeta * numBandejas * espacamento;
  }

  /// Calcula a área amostrada em hectares
  /// areaM2: área em metros quadrados
  /// Retorna área em hectares
  static double calcularAreaHectares(double areaM2) {
    return areaM2 / 10000.0;
  }

  /// Calcula o peso total em kg
  /// pesos: lista de pesos coletados em gramas
  /// Retorna peso total em kg
  static double calcularPesoTotalKg(List<double> pesos) {
    final sumGramas = pesos.reduce((a, b) => a + b);
    return sumGramas / 1000.0;
  }

  /// Calcula a vazão teórica necessária
  /// taxaDesejada: taxa desejada em kg/ha
  /// velocidade: velocidade em km/h
  /// faixaReal: faixa real em metros
  /// Retorna vazão em kg/s
  static double calcularVazaoTeorica(
    double taxaDesejada, 
    double velocidade, 
    double faixaReal
  ) {
    // Converter velocidade de km/h para m/s
    final velocidadeMS = velocidade / 3.6;
    
    // Vazão teórica = (taxa desejada * velocidade * faixa) / 10000 / 3600
    final vazao = (taxaDesejada * velocidadeMS * faixaReal) / 10000.0 / 3600.0;
    
    return double.parse(vazao.toStringAsFixed(4));
  }

  /// Calcula a eficiência da calibração
  /// taxaReal: taxa real em kg/ha
  /// taxaDesejada: taxa desejada em kg/ha
  /// Retorna eficiência em %
  static double calcularEficiencia(double taxaReal, double taxaDesejada) {
    if (taxaDesejada <= 0) return 0.0;
    
    final eficiencia = (taxaReal / taxaDesejada) * 100.0;
    return double.parse(eficiencia.toStringAsFixed(1));
  }

  /// Valida os dados de entrada
  /// Retorna lista de erros encontrados
  static List<String> validarDados({
    required List<double> pesos,
    required double distanciaColeta,
    required double espacamento,
    required String tipoPaleta,
    double? rpm,
    double? velocidade,
  }) {
    final erros = <String>[];
    
    // Validação dos pesos
    if (pesos.length < 5) {
      erros.add('Mínimo de 5 pesos é obrigatório (atual: ${pesos.length})');
    }
    if (pesos.length > 21) {
      erros.add('Máximo de 21 pesos permitido (atual: ${pesos.length})');
    }
    
    for (int i = 0; i < pesos.length; i++) {
      if (pesos[i] <= 0) {
        erros.add('Peso da bandeja ${i + 1} deve ser maior que zero');
      }
    }
    
    // Validação da distância
    if (distanciaColeta <= 0) {
      erros.add('Distância de coleta deve ser maior que zero');
    }
    if (distanciaColeta > 1000) {
      erros.add('Distância de coleta muito alta (máximo 1000m)');
    }
    
    // Validação do espaçamento
    if (espacamento <= 0) {
      erros.add('Espaçamento deve ser maior que zero');
    }
    if (espacamento > 10) {
      erros.add('Espaçamento muito alto (máximo 10m)');
    }
    
    // Validação do tipo de paleta
    if (!['pequena', 'grande'].contains(tipoPaleta.toLowerCase())) {
      erros.add('Tipo de paleta deve ser "pequena" ou "grande"');
    }
    
    // Validação do RPM (se fornecido)
    if (rpm != null) {
      if (rpm <= 0) {
        erros.add('RPM deve ser maior que zero');
      }
      if (rpm > 10000) {
        erros.add('RPM muito alto (máximo 10000)');
      }
    }
    
    // Validação da velocidade (se fornecida)
    if (velocidade != null) {
      if (velocidade <= 0) {
        erros.add('Velocidade deve ser maior que zero');
      }
      if (velocidade > 50) {
        erros.add('Velocidade muito alta (máximo 50 km/h)');
      }
    }
    
    return erros;
  }

  /// Gera relatório detalhado da calibração
  /// calibracao: modelo de calibração
  /// Retorna relatório em formato de texto
  static String gerarRelatorio(CalibracaoFertilizanteModel calibracao) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RELATÓRIO DE CALIBRAÇÃO DE FERTILIZANTES ===');
    buffer.writeln('Nome: ${calibracao.nome}');
    buffer.writeln('Data: ${calibracao.dataCalibracao.toString().split(' ')[0]}');
    buffer.writeln('Responsável: ${calibracao.responsavel}');
    buffer.writeln('');
    
    buffer.writeln('=== DADOS DE ENTRADA ===');
    buffer.writeln('Pesos coletados (g): ${calibracao.pesos.join(', ')}');
    buffer.writeln('Número de bandejas: ${calibracao.pesos.length}');
    buffer.writeln('Distância de coleta: ${calibracao.distanciaColeta} m');
    buffer.writeln('Espaçamento: ${calibracao.espacamento} m');
    buffer.writeln('Tipo de paleta: ${calibracao.tipoPaleta}');
    
    if (calibracao.faixaEsperada != null) {
      buffer.writeln('Faixa esperada: ${calibracao.faixaEsperada} m');
    }
    if (calibracao.taxaDesejada != null) {
      buffer.writeln('Taxa desejada: ${calibracao.taxaDesejada} kg/ha');
    }
    buffer.writeln('');
    
    buffer.writeln('=== RESULTADOS ===');
    buffer.writeln('Taxa real: ${calibracao.taxaRealKgHa} kg/ha');
    buffer.writeln('Coeficiente de variação: ${calibracao.coeficienteVariacao}%');
    buffer.writeln('Classificação CV: ${calibracao.classificacaoCV}');
    buffer.writeln('Faixa real: ${calibracao.faixaReal} m');
    
    if (calibracao.taxaDesejada != null) {
      final eficiencia = calcularEficiencia(calibracao.taxaRealKgHa, calibracao.taxaDesejada!);
      buffer.writeln('Eficiência: ${eficiencia}%');
    }
    buffer.writeln('');
    
    buffer.writeln('=== ANÁLISE ESTATÍSTICA ===');
    final media = calcularMedia(calibracao.pesos);
    final desvioPadrao = calcularDesvioPadrao(calibracao.pesos);
    final pesoTotal = calcularPesoTotalKg(calibracao.pesos);
    final areaAmostrada = calcularAreaAmostrada(
      calibracao.distanciaColeta, 
      calibracao.espacamento, 
      calibracao.pesos.length
    );
    final areaHa = calcularAreaHectares(areaAmostrada);
    
    buffer.writeln('Média dos pesos: ${media} g');
    buffer.writeln('Desvio padrão: ${desvioPadrao} g');
    buffer.writeln('Peso total: ${pesoTotal} kg');
    buffer.writeln('Área amostrada: ${areaAmostrada} m² (${areaHa} ha)');
    buffer.writeln('');
    
    if (calibracao.observacoes != null && calibracao.observacoes!.isNotEmpty) {
      buffer.writeln('=== OBSERVAÇÕES ===');
      buffer.writeln(calibracao.observacoes);
      buffer.writeln('');
    }
    
    buffer.writeln('=== RECOMENDAÇÕES ===');
    if (calibracao.coeficienteVariacao <= 10.0) {
      buffer.writeln('✅ Distribuição uniforme - Calibração adequada');
    } else if (calibracao.coeficienteVariacao <= 15.0) {
      buffer.writeln('⚠️ Distribuição moderada - Verificar ajustes');
    } else {
      buffer.writeln('❌ Distribuição crítica - Recalibrar equipamento');
    }
    
    if (calibracao.taxaDesejada != null) {
      final eficiencia = calcularEficiencia(calibracao.taxaRealKgHa, calibracao.taxaDesejada!);
      if (eficiencia >= 95.0 && eficiencia <= 105.0) {
        buffer.writeln('✅ Taxa dentro da faixa aceitável (±5%)');
      } else {
        buffer.writeln('⚠️ Taxa fora da faixa aceitável - Ajustar configuração');
      }
    }
    
    return buffer.toString();
  }

  /// Calcula estatísticas detalhadas
  /// pesos: lista de pesos coletados em gramas
  /// Retorna mapa com estatísticas
  static Map<String, double> calcularEstatisticas(List<double> pesos) {
    if (pesos.isEmpty) {
      return {
        'media': 0.0,
        'mediana': 0.0,
        'desvio_padrao': 0.0,
        'cv': 0.0,
        'minimo': 0.0,
        'maximo': 0.0,
        'amplitude': 0.0,
      };
    }
    
    final ordenados = List<double>.from(pesos)..sort();
    final media = calcularMedia(pesos);
    final desvioPadrao = calcularDesvioPadrao(pesos);
    final cv = calcularCV(pesos);
    final minimo = ordenados.first;
    final maximo = ordenados.last;
    final amplitude = maximo - minimo;
    
    // Mediana
    double mediana;
    if (ordenados.length % 2 == 0) {
      final meio = ordenados.length ~/ 2;
      mediana = (ordenados[meio - 1] + ordenados[meio]) / 2.0;
    } else {
      mediana = ordenados[ordenados.length ~/ 2];
    }
    
    return {
      'media': double.parse(media.toStringAsFixed(2)),
      'mediana': double.parse(mediana.toStringAsFixed(2)),
      'desvio_padrao': double.parse(desvioPadrao.toStringAsFixed(3)),
      'cv': double.parse(cv.toStringAsFixed(2)),
      'minimo': double.parse(minimo.toStringAsFixed(2)),
      'maximo': double.parse(maximo.toStringAsFixed(2)),
      'amplitude': double.parse(amplitude.toStringAsFixed(2)),
    };
  }
}
