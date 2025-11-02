import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/soil_compaction_point_model.dart';

/// Serviço para análises e cálculos automáticos de compactação
class SoilAnalysisService {
  
  /// Calcula a média de compactação para um talhão
  static double calcularMediaCompactacao(List<SoilCompactionPointModel> pontos) {
    if (pontos.isEmpty) return 0.0;
    
    final pontosComMedicao = pontos.where((p) => p.penetrometria != null).toList();
    if (pontosComMedicao.isEmpty) return 0.0;
    
    final soma = pontosComMedicao.fold<double>(
      0.0, 
      (sum, ponto) => sum + (ponto.penetrometria ?? 0.0),
    );
    
    return soma / pontosComMedicao.length;
  }
  
  /// Calcula a média de compactação por profundidade
  static Map<String, double> calcularMediaPorProfundidade(
    List<SoilCompactionPointModel> pontos,
  ) {
    Map<String, List<double>> medicoesPorProfundidade = {};
    
    for (var ponto in pontos) {
      if (ponto.penetrometria == null) continue;
      
      String chave = '${ponto.profundidadeInicio.toInt()}-${ponto.profundidadeFim.toInt()}cm';
      
      if (!medicoesPorProfundidade.containsKey(chave)) {
        medicoesPorProfundidade[chave] = [];
      }
      
      medicoesPorProfundidade[chave]!.add(ponto.penetrometria!);
    }
    
    Map<String, double> medias = {};
    medicoesPorProfundidade.forEach((profundidade, valores) {
      double soma = valores.fold(0.0, (a, b) => a + b);
      medias[profundidade] = soma / valores.length;
    });
    
    return medias;
  }
  
  /// Calcula estatísticas completas de compactação
  static Map<String, dynamic> calcularEstatisticas(
    List<SoilCompactionPointModel> pontos,
  ) {
    final pontosComMedicao = pontos.where((p) => p.penetrometria != null).toList();
    
    if (pontosComMedicao.isEmpty) {
      return {
        'media': 0.0,
        'minimo': 0.0,
        'maximo': 0.0,
        'desvioPadrao': 0.0,
        'coeficienteVariacao': 0.0,
        'totalPontos': 0,
        'pontosComMedicao': 0,
      };
    }
    
    List<double> valores = pontosComMedicao
        .map((p) => p.penetrometria!)
        .toList();
    
    // Média
    double media = valores.fold(0.0, (a, b) => a + b) / valores.length;
    
    // Mínimo e Máximo
    double minimo = valores.reduce(min);
    double maximo = valores.reduce(max);
    
    // Desvio padrão
    double variancia = valores
        .map((v) => pow(v - media, 2))
        .fold(0.0, (a, b) => a + b) / valores.length;
    double desvioPadrao = sqrt(variancia);
    
    // Coeficiente de variação (%)
    double coeficienteVariacao = media > 0 ? (desvioPadrao / media) * 100 : 0.0;
    
    return {
      'media': media,
      'minimo': minimo,
      'maximo': maximo,
      'desvioPadrao': desvioPadrao,
      'coeficienteVariacao': coeficienteVariacao,
      'totalPontos': pontos.length,
      'pontosComMedicao': pontosComMedicao.length,
    };
  }
  
  /// Classifica o nível geral de compactação do talhão
  static Map<String, dynamic> classificarTalhao(
    List<SoilCompactionPointModel> pontos,
  ) {
    double media = calcularMediaCompactacao(pontos);
    
    String classificacao;
    String descricao;
    String recomendacao;
    
    if (media < 1.5) {
      classificacao = 'Solo Adequado';
      descricao = 'Solo com baixa resistência à penetração. Condição adequada para desenvolvimento radicular.';
      recomendacao = 'Manter práticas conservacionistas e monitorar periodicamente.';
    } else if (media < 2.0) {
      classificacao = 'Risco Moderado';
      descricao = 'Solo com resistência moderada. Pode limitar o crescimento de raízes em profundidade.';
      recomendacao = 'Implementar práticas de descompactação biológica com plantas de cobertura.';
    } else if (media < 2.5) {
      classificacao = 'Alta Compactação';
      descricao = 'Solo compactado. Limitação significativa ao desenvolvimento radicular.';
      recomendacao = 'Subsolagem recomendada antes do próximo plantio.';
    } else {
      classificacao = 'Compactação Crítica';
      descricao = 'Solo severamente compactado. Restrição severa ao crescimento radicular.';
      recomendacao = 'URGENTE: Subsolagem profunda obrigatória e manejo intensivo para recuperação.';
    }
    
    return {
      'media': media,
      'classificacao': classificacao,
      'descricao': descricao,
      'recomendacao': recomendacao,
    };
  }
  
  /// Agrupa pontos por nível de compactação
  static Map<String, List<SoilCompactionPointModel>> agruparPorNivel(
    List<SoilCompactionPointModel> pontos,
  ) {
    Map<String, List<SoilCompactionPointModel>> grupos = {
      'Solto': [],
      'Moderado': [],
      'Alto': [],
      'Crítico': [],
      'Não Medido': [],
    };
    
    for (var ponto in pontos) {
      String nivel = ponto.penetrometria != null 
          ? ponto.calcularNivelCompactacao()
          : 'Não Medido';
      
      grupos[nivel]!.add(ponto);
    }
    
    return grupos;
  }
  
  /// Calcula distribuição percentual por nível
  static Map<String, double> calcularDistribuicaoPercentual(
    List<SoilCompactionPointModel> pontos,
  ) {
    if (pontos.isEmpty) return {};
    
    var grupos = agruparPorNivel(pontos);
    Map<String, double> distribuicao = {};
    
    grupos.forEach((nivel, pontosList) {
      double percentual = (pontosList.length / pontos.length) * 100;
      distribuicao[nivel] = double.parse(percentual.toStringAsFixed(1));
    });
    
    return distribuicao;
  }
  
  /// Identifica áreas críticas (hot spots) de compactação
  static List<SoilCompactionPointModel> identificarAreasCriticas(
    List<SoilCompactionPointModel> pontos, {
    double limiarMPa = 2.5,
  }) {
    return pontos
        .where((p) => p.penetrometria != null && p.penetrometria! >= limiarMPa)
        .toList();
  }
  
  /// Gera relatório resumido de análise
  static Map<String, dynamic> gerarRelatorioResumido(
    List<SoilCompactionPointModel> pontos, {
    required String nomeTalhao,
    required double areaTalhao,
  }) {
    final estatisticas = calcularEstatisticas(pontos);
    final classificacao = classificarTalhao(pontos);
    final distribuicao = calcularDistribuicaoPercentual(pontos);
    final areasCriticas = identificarAreasCriticas(pontos);
    final mediaPorProfundidade = calcularMediaPorProfundidade(pontos);
    
    return {
      'talhao': nomeTalhao,
      'area': areaTalhao,
      'dataAnalise': DateTime.now().toIso8601String(),
      'totalPontos': pontos.length,
      'pontosAvaliados': estatisticas['pontosComMedicao'],
      'estatisticas': estatisticas,
      'classificacao': classificacao,
      'distribuicao': distribuicao,
      'areasCriticas': areasCriticas.length,
      'mediaPorProfundidade': mediaPorProfundidade,
      'necessitaIntervencao': classificacao['media'] >= 2.0,
    };
  }
  
  /// Calcula tendência temporal (comparação entre safras)
  static Map<String, dynamic>? calcularTendencia({
    required List<SoilCompactionPointModel> pontosAtuais,
    required List<SoilCompactionPointModel> pontosAnteriores,
  }) {
    if (pontosAtuais.isEmpty || pontosAnteriores.isEmpty) return null;
    
    double mediaAtual = calcularMediaCompactacao(pontosAtuais);
    double mediaAnterior = calcularMediaCompactacao(pontosAnteriores);
    
    double diferenca = mediaAtual - mediaAnterior;
    double percentualMudanca = mediaAnterior > 0 
        ? (diferenca / mediaAnterior) * 100 
        : 0.0;
    
    String tendencia;
    if (diferenca.abs() < 0.1) {
      tendencia = 'Estável';
    } else if (diferenca > 0) {
      tendencia = 'Aumentando';
    } else {
      tendencia = 'Diminuindo';
    }
    
    return {
      'mediaAtual': mediaAtual,
      'mediaAnterior': mediaAnterior,
      'diferenca': diferenca,
      'percentualMudanca': percentualMudanca,
      'tendencia': tendencia,
      'interpretacao': _interpretarTendencia(tendencia, diferenca),
    };
  }
  
  static String _interpretarTendencia(String tendencia, double diferenca) {
    switch (tendencia) {
      case 'Estável':
        return 'Nível de compactação manteve-se estável entre as avaliações.';
      case 'Aumentando':
        return 'ATENÇÃO: Compactação aumentou em ${diferenca.toStringAsFixed(2)} MPa. Revisar práticas de manejo.';
      case 'Diminuindo':
        return 'POSITIVO: Compactação reduziu em ${diferenca.abs().toStringAsFixed(2)} MPa. Práticas de descompactação efetivas.';
      default:
        return 'Análise inconclusiva.';
    }
  }
  
  /// Calcula índice de uniformidade da compactação
  static double calcularIndiceUniformidade(List<SoilCompactionPointModel> pontos) {
    final estatisticas = calcularEstatisticas(pontos);
    double cv = estatisticas['coeficienteVariacao'];
    
    // Índice de uniformidade: quanto menor o CV, maior a uniformidade
    // Normalizado para escala 0-100
    if (cv <= 10) return 100.0; // Excelente uniformidade
    if (cv <= 20) return 90.0;  // Boa uniformidade
    if (cv <= 30) return 70.0;  // Moderada uniformidade
    if (cv <= 40) return 50.0;  // Baixa uniformidade
    return 30.0; // Muito heterogêneo
  }
  
  /// Exporta dados para análise externa (CSV format)
  static String exportarParaCSV(List<SoilCompactionPointModel> pontos) {
    StringBuffer csv = StringBuffer();
    
    // Cabeçalho
    csv.writeln('Código;Latitude;Longitude;Profundidade(cm);Penetrometria(MPa);Umidade(%);Textura;Estrutura;Nível;Observações');
    
    // Dados
    for (var ponto in pontos) {
      csv.writeln(
        '${ponto.pointCode};'
        '${ponto.latitude};'
        '${ponto.longitude};'
        '${ponto.profundidadeInicio}-${ponto.profundidadeFim};'
        '${ponto.penetrometria ?? ""};'
        '${ponto.umidade ?? ""};'
        '${ponto.textura ?? ""};'
        '${ponto.estrutura ?? ""};'
        '${ponto.nivelCompactacao ?? ponto.calcularNivelCompactacao()};'
        '${ponto.observacoes ?? ""}'
      );
    }
    
    return csv.toString();
  }
}

