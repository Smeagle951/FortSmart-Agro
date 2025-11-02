import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/soil_compaction_point_model.dart';

/// Serviço para análises temporais e mapas de tendência
class SoilTemporalAnalysisService {
  
  /// Calcula tendência entre duas safras
  static Map<String, dynamic> calcularTendencia({
    required List<SoilCompactionPointModel> pontosAtuais,
    required List<SoilCompactionPointModel> pontosAnteriores,
  }) {
    if (pontosAtuais.isEmpty || pontosAnteriores.isEmpty) {
      return {
        'tendencia_geral': 'Dados Insuficientes',
        'score_tendencia': 0.0,
        'melhorou': 0,
        'piorou': 0,
        'igual': 0,
        'total_pontos': 0,
        'variacao_percentual': 0.0,
        'interpretacao': 'Não foi possível calcular tendência',
      };
    }

    // Agrupa pontos por localização (raio de 10 metros)
    final gruposAtuais = _agruparPontosPorLocalizacao(pontosAtuais);
    final gruposAnteriores = _agruparPontosPorLocalizacao(pontosAnteriores);

    int melhorou = 0;
    int piorou = 0;
    int igual = 0;
    double variacaoTotal = 0.0;
    int totalComparacoes = 0;

    // Compara grupos próximos
    for (var grupoAtual in gruposAtuais) {
      final grupoAnterior = _encontrarGrupoMaisProximo(grupoAtual, gruposAnteriores);
      
      if (grupoAnterior != null) {
        final mediaAtual = _calcularMediaGrupo(grupoAtual);
        final mediaAnterior = _calcularMediaGrupo(grupoAnterior);
        
        if (mediaAtual != null && mediaAnterior != null) {
          final diferenca = mediaAtual - mediaAnterior;
          final variacaoPercentual = (diferenca / mediaAnterior) * 100;
          
          variacaoTotal += variacaoPercentual;
          totalComparacoes++;
          
          if (variacaoPercentual < -5.0) {
            melhorou++;
          } else if (variacaoPercentual > 5.0) {
            piorou++;
          } else {
            igual++;
          }
        }
      }
    }

    final variacaoMedia = totalComparacoes > 0 ? variacaoTotal / totalComparacoes : 0.0;
    final scoreTendencia = _calcularScoreTendencia(variacaoMedia);
    final tendenciaGeral = _classificarTendencia(variacaoMedia);

    return {
      'tendencia_geral': tendenciaGeral,
      'score_tendencia': scoreTendencia,
      'melhorou': melhorou,
      'piorou': piorou,
      'igual': igual,
      'total_pontos': totalComparacoes,
      'variacao_percentual': variacaoMedia,
      'interpretacao': _gerarInterpretacaoTendencia(tendenciaGeral, variacaoMedia),
      'detalhes_grupos': _gerarDetalhesGrupos(gruposAtuais, gruposAnteriores),
    };
  }

  /// Gera mapa de calor temporal
  static Map<String, dynamic> gerarMapaCalorTemporal({
    required List<SoilCompactionPointModel> pontos,
    required int safraId,
  }) {
    final Map<String, List<double>> dadosTemporais = {};
    
    // Agrupa por localização e coleta dados ao longo do tempo
    for (var ponto in pontos) {
      final chave = '${ponto.latitude.toStringAsFixed(4)}_${ponto.longitude.toStringAsFixed(4)}';
      
      if (ponto.penetrometria != null) {
        dadosTemporais[chave] ??= [];
        dadosTemporais[chave]!.add(ponto.penetrometria!);
      }
    }

    // Calcula tendência para cada localização
    final Map<String, Map<String, dynamic>> mapaCalor = {};
    
    dadosTemporais.forEach((chave, valores) {
      if (valores.length >= 2) {
        final tendencia = _calcularTendenciaLocalizacao(valores);
        final coordenadas = chave.split('_');
        
        mapaCalor[chave] = {
          'latitude': double.parse(coordenadas[0]),
          'longitude': double.parse(coordenadas[1]),
          'valores': valores,
          'tendencia': tendencia['tendencia'],
          'variacao_percentual': tendencia['variacao_percentual'],
          'cor': _getCorTendencia(tendencia['tendencia']),
          'intensidade': tendencia['intensidade'],
        };
      }
    });

    return {
      'safra_id': safraId,
      'total_localizacoes': mapaCalor.length,
      'dados_mapa': mapaCalor,
      'estatisticas': _calcularEstatisticasMapaCalor(mapaCalor),
    };
  }

  /// Gera evolução por safra
  static Map<String, dynamic> gerarEvolucaoPorSafra({
    required Map<int, List<SoilCompactionPointModel>> dadosPorSafra,
  }) {
    final Map<String, dynamic> evolucao = {
      'safras': <Map<String, dynamic>>[],
      'tendencias': <Map<String, dynamic>>[],
      'grafico_dados': <Map<String, dynamic>>{},
    };

    final safras = dadosPorSafra.keys.toList()..sort();
    
    for (int i = 0; i < safras.length; i++) {
      final safraId = safras[i];
      final pontos = dadosPorSafra[safraId]!;
      
      final estatisticas = _calcularEstatisticasSafra(pontos);
      
      evolucao['safras'].add({
        'safra_id': safraId,
        'ano': safraId, // Assumindo que safraId é o ano
        'total_pontos': pontos.length,
        'media_compactacao': estatisticas['media'],
        'min_compactacao': estatisticas['minimo'],
        'max_compactacao': estatisticas['maximo'],
        'desvio_padrao': estatisticas['desvio_padrao'],
        'classificacao': _classificarSafra(estatisticas['media'] ?? 0.0),
        'areas_criticas': _contarAreasCriticas(pontos),
        'areas_adequadas': _contarAreasAdequadas(pontos),
      });

      // Dados para gráfico
      evolucao['grafico_dados']['$safraId'] = {
        'media': estatisticas['media'],
        'min': estatisticas['minimo'],
        'max': estatisticas['maximo'],
        'areas_criticas': _contarAreasCriticas(pontos),
      };
    }

    // Calcula tendências entre safras consecutivas
    for (int i = 1; i < safras.length; i++) {
      final safraAtual = safras[i];
      final safraAnterior = safras[i - 1];
      
      final tendencia = calcularTendencia(
        pontosAtuais: dadosPorSafra[safraAtual]!,
        pontosAnteriores: dadosPorSafra[safraAnterior]!,
      );

      evolucao['tendencias'].add({
        'de_safra': safraAnterior,
        'para_safra': safraAtual,
        'tendencia': tendencia['tendencia_geral'],
        'variacao_percentual': tendencia['variacao_percentual'],
        'melhorou': tendencia['melhorou'],
        'piorou': tendencia['piorou'],
        'igual': tendencia['igual'],
      });
    }

    return evolucao;
  }

  /// Gera dados para gráfico de evolução
  static Map<String, dynamic> gerarDadosGraficoEvolucao({
    required Map<int, List<SoilCompactionPointModel>> dadosPorSafra,
  }) {
    final Map<String, List<double>> series = {
      'media': [],
      'minimo': [],
      'maximo': [],
      'areas_criticas': [],
    };

    final List<String> labels = [];
    final safras = dadosPorSafra.keys.toList()..sort();

    for (var safraId in safras) {
      final pontos = dadosPorSafra[safraId]!;
      final estatisticas = _calcularEstatisticasSafra(pontos);
      
      series['media']!.add(estatisticas['media'] ?? 0.0);
      series['minimo']!.add(estatisticas['minimo'] ?? 0.0);
      series['maximo']!.add(estatisticas['maximo'] ?? 0.0);
      series['areas_criticas']!.add(_contarAreasCriticas(pontos).toDouble());
      
      labels.add(safraId.toString());
    }

    return {
      'series': series,
      'labels': labels,
      'titulo': 'Evolução da Compactação por Safra',
      'subtitulo': 'Média, Mínimo, Máximo e Áreas Críticas',
    };
  }

  /// Agrupa pontos por localização (raio de 10 metros)
  static List<List<SoilCompactionPointModel>> _agruparPontosPorLocalizacao(
    List<SoilCompactionPointModel> pontos,
  ) {
    final List<List<SoilCompactionPointModel>> grupos = [];
    final List<bool> processados = List.filled(pontos.length, false);

    for (int i = 0; i < pontos.length; i++) {
      if (processados[i]) continue;

      final grupo = <SoilCompactionPointModel>[];
      final pontoReferencia = pontos[i];
      
      grupo.add(pontoReferencia);
      processados[i] = true;

      // Encontra pontos próximos (raio de 10 metros)
      for (int j = i + 1; j < pontos.length; j++) {
        if (processados[j]) continue;

        final distancia = _calcularDistancia(
          pontoReferencia.latitude,
          pontoReferencia.longitude,
          pontos[j].latitude,
          pontos[j].longitude,
        );

        if (distancia <= 10.0) {
          grupo.add(pontos[j]);
          processados[j] = true;
        }
      }

      grupos.add(grupo);
    }

    return grupos;
  }

  /// Encontra o grupo mais próximo
  static List<SoilCompactionPointModel>? _encontrarGrupoMaisProximo(
    List<SoilCompactionPointModel> grupoAtual,
    List<List<SoilCompactionPointModel>> gruposAnteriores,
  ) {
    double menorDistancia = double.infinity;
    List<SoilCompactionPointModel>? grupoMaisProximo;

    final centroAtual = _calcularCentroGrupo(grupoAtual);

    for (var grupo in gruposAnteriores) {
      final centroAnterior = _calcularCentroGrupo(grupo);
      final distancia = _calcularDistancia(
        centroAtual.latitude,
        centroAtual.longitude,
        centroAnterior.latitude,
        centroAnterior.longitude,
      );

      if (distancia < menorDistancia && distancia <= 50.0) {
        menorDistancia = distancia;
        grupoMaisProximo = grupo;
      }
    }

    return grupoMaisProximo;
  }

  /// Calcula centro de um grupo
  static LatLng _calcularCentroGrupo(List<SoilCompactionPointModel> grupo) {
    double sumLat = 0;
    double sumLng = 0;

    for (var ponto in grupo) {
      sumLat += ponto.latitude;
      sumLng += ponto.longitude;
    }

    return LatLng(sumLat / grupo.length, sumLng / grupo.length);
  }

  /// Calcula média de um grupo
  static double? _calcularMediaGrupo(List<SoilCompactionPointModel> grupo) {
    final valores = grupo
        .where((p) => p.penetrometria != null)
        .map((p) => p.penetrometria!)
        .toList();

    if (valores.isEmpty) return null;

    return valores.reduce((a, b) => a + b) / valores.length;
  }

  /// Calcula tendência de uma localização
  static Map<String, dynamic> _calcularTendenciaLocalizacao(List<double> valores) {
    if (valores.length < 2) {
      return {
        'tendencia': 'Estável',
        'variacao_percentual': 0.0,
        'intensidade': 0.0,
      };
    }

    final primeiro = valores.first;
    final ultimo = valores.last;
    final variacao = ((ultimo - primeiro) / primeiro) * 100;

    String tendencia;
    if (variacao < -5.0) {
      tendencia = 'Melhorou';
    } else if (variacao > 5.0) {
      tendencia = 'Piorou';
    } else {
      tendencia = 'Estável';
    }

    return {
      'tendencia': tendencia,
      'variacao_percentual': variacao,
      'intensidade': variacao.abs(),
    };
  }

  /// Calcula score de tendência (-100 a +100)
  static double _calcularScoreTendencia(double variacaoPercentual) {
    if (variacaoPercentual < -20) return -100.0;
    if (variacaoPercentual < -10) return -50.0;
    if (variacaoPercentual < -5) return -25.0;
    if (variacaoPercentual < 5) return 0.0;
    if (variacaoPercentual < 10) return 25.0;
    if (variacaoPercentual < 20) return 50.0;
    return 100.0;
  }

  /// Classifica tendência geral
  static String _classificarTendencia(double variacaoPercentual) {
    if (variacaoPercentual < -10) return 'Melhora Significativa';
    if (variacaoPercentual < -5) return 'Melhora Moderada';
    if (variacaoPercentual < 5) return 'Estável';
    if (variacaoPercentual < 10) return 'Piora Moderada';
    return 'Piora Significativa';
  }

  /// Gera interpretação da tendência
  static String _gerarInterpretacaoTendencia(String tendencia, double variacao) {
    switch (tendencia) {
      case 'Melhora Significativa':
        return 'Excelente! A compactação reduziu significativamente (${variacao.toStringAsFixed(1)}%). Continue as práticas atuais.';
      case 'Melhora Moderada':
        return 'Bom! A compactação está melhorando (${variacao.toStringAsFixed(1)}%). Mantenha as práticas conservacionistas.';
      case 'Estável':
        return 'Estável. A compactação manteve-se no mesmo nível. Considere intensificar as práticas de manejo.';
      case 'Piora Moderada':
        return 'Atenção! A compactação aumentou moderadamente (${variacao.toStringAsFixed(1)}%). Revise as práticas de manejo.';
      case 'Piora Significativa':
        return 'Crítico! A compactação aumentou significativamente (${variacao.toStringAsFixed(1)}%). Intervenção urgente necessária.';
      default:
        return 'Tendência não identificada.';
    }
  }

  /// Calcula estatísticas de uma safra
  static Map<String, double> _calcularEstatisticasSafra(List<SoilCompactionPointModel> pontos) {
    final valores = pontos
        .where((p) => p.penetrometria != null)
        .map((p) => p.penetrometria!)
        .toList();

    if (valores.isEmpty) {
      return {'media': 0.0, 'minimo': 0.0, 'maximo': 0.0, 'desvio_padrao': 0.0};
    }

    final media = valores.reduce((a, b) => a + b) / valores.length;
    final minimo = valores.reduce(min);
    final maximo = valores.reduce(max);
    
    final variancia = valores
        .map((v) => pow(v - media, 2))
        .fold(0.0, (a, b) => a + b) / valores.length;
    final desvioPadrao = sqrt(variancia);

    return {
      'media': media,
      'minimo': minimo,
      'maximo': maximo,
      'desvio_padrao': desvioPadrao,
    };
  }

  /// Classifica uma safra
  static String _classificarSafra(double media) {
    if (media < 1.5) return 'Adequada';
    if (media < 2.0) return 'Moderada';
    if (media < 2.5) return 'Alta';
    return 'Crítica';
  }

  /// Conta áreas críticas
  static int _contarAreasCriticas(List<SoilCompactionPointModel> pontos) {
    return pontos
        .where((p) => p.penetrometria != null && p.penetrometria! > 2.0)
        .length;
  }

  /// Conta áreas adequadas
  static int _contarAreasAdequadas(List<SoilCompactionPointModel> pontos) {
    return pontos
        .where((p) => p.penetrometria != null && p.penetrometria! < 1.5)
        .length;
  }

  /// Retorna cor da tendência
  static String _getCorTendencia(String tendencia) {
    switch (tendencia) {
      case 'Melhorou':
        return '#4CAF50'; // Verde
      case 'Piorou':
        return '#F44336'; // Vermelho
      case 'Estável':
        return '#9E9E9E'; // Cinza
      default:
        return '#9E9E9E';
    }
  }

  /// Calcula estatísticas do mapa de calor
  static Map<String, dynamic> _calcularEstatisticasMapaCalor(
    Map<String, Map<String, dynamic>> mapaCalor,
  ) {
    int melhorou = 0;
    int piorou = 0;
    int estavel = 0;
    double variacaoTotal = 0.0;

    for (var dados in mapaCalor.values) {
      final tendencia = dados['tendencia'] as String;
      final variacao = dados['variacao_percentual'] as double;
      
      variacaoTotal += variacao;
      
      switch (tendencia) {
        case 'Melhorou':
          melhorou++;
          break;
        case 'Piorou':
          piorou++;
          break;
        case 'Estável':
          estavel++;
          break;
      }
    }

    return {
      'melhorou': melhorou,
      'piorou': piorou,
      'estavel': estavel,
      'variacao_media': mapaCalor.isNotEmpty ? variacaoTotal / mapaCalor.length : 0.0,
    };
  }

  /// Gera detalhes dos grupos
  static List<Map<String, dynamic>> _gerarDetalhesGrupos(
    List<List<SoilCompactionPointModel>> gruposAtuais,
    List<List<SoilCompactionPointModel>> gruposAnteriores,
  ) {
    final List<Map<String, dynamic>> detalhes = [];

    for (var grupoAtual in gruposAtuais) {
      final grupoAnterior = _encontrarGrupoMaisProximo(grupoAtual, gruposAnteriores);
      
      if (grupoAnterior != null) {
        final centroAtual = _calcularCentroGrupo(grupoAtual);
        final centroAnterior = _calcularCentroGrupo(grupoAnterior);
        final mediaAtual = _calcularMediaGrupo(grupoAtual);
        final mediaAnterior = _calcularMediaGrupo(grupoAnterior);
        
        if (mediaAtual != null && mediaAnterior != null) {
          final variacao = ((mediaAtual - mediaAnterior) / mediaAnterior) * 100;
          
          detalhes.add({
            'latitude': centroAtual.latitude,
            'longitude': centroAtual.longitude,
            'media_atual': mediaAtual,
            'media_anterior': mediaAnterior,
            'variacao_percentual': variacao,
            'tendencia': _classificarTendencia(variacao),
            'cor': _getCorTendencia(_classificarTendencia(variacao)),
          });
        }
      }
    }

    return detalhes;
  }

  /// Calcula distância entre dois pontos
  static double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
               sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
