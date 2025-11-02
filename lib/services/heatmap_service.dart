import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../database/app_database.dart';
import '../utils/logger.dart';

/// Serviço para gerar mapas de calor baseados em dados de monitoramento
class HeatmapService {
  final AppDatabase _database = AppDatabase();

  /// Determina a área mais atacada de um talhão baseado nos pontos de monitoramento
  Future<String> determinarLocalMaisAtacado(String talhaoId) async {
    try {
      final db = await _database.database;
      
      // Buscar pontos de monitoramento do talhão
      final List<Map<String, dynamic>> pontos = await db.query(
        'monitoring_points',
        where: 'plot_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'created_at DESC',
        limit: 10, // Últimos 10 pontos
      );

      if (pontos.isEmpty) {
        return 'Sem dados de monitoramento';
      }

      // Analisar coordenadas para determinar a área mais crítica
      final coordenadas = pontos.map((ponto) {
        return LatLng(
          ponto['latitude'] as double,
          ponto['longitude'] as double,
        );
      }).toList();

      // Calcular centro e determinar direção predominante
      final centro = _calcularCentro(coordenadas);
      final direcao = _determinarDirecao(centro, coordenadas);
      
      return direcao;
    } catch (e) {
      Logger.error('HeatmapService', 'Erro ao determinar local mais atacado: $e');
      return 'Local não determinado';
    }
  }

  /// Gera dados de mapa de calor para um talhão
  Future<List<Map<String, dynamic>>> gerarDadosHeatmap(String talhaoId) async {
    try {
      final db = await _database.database;
      
      // Buscar pontos de monitoramento com ocorrências
      final List<Map<String, dynamic>> pontos = await db.rawQuery('''
        SELECT 
          mp.latitude,
          mp.longitude,
          mp.created_at,
          0 as severidade_total
        FROM monitoring_points mp
        WHERE mp.plot_id = ?
        ORDER BY mp.created_at DESC
      ''', [talhaoId]);

      return pontos.map((ponto) {
        final severidade = (ponto['severidade_total'] as num?)?.toDouble() ?? 0.0;
        return {
          'latitude': ponto['latitude'],
          'longitude': ponto['longitude'],
          'intensity': _normalizarIntensidade(severidade),
          'severidade': severidade,
          'data': ponto['created_at'],
        };
      }).toList();
    } catch (e) {
      Logger.error('HeatmapService', 'Erro ao gerar dados de heatmap: $e');
      return [];
    }
  }

  /// Calcula o centro de um conjunto de coordenadas
  LatLng _calcularCentro(List<LatLng> coordenadas) {
    if (coordenadas.isEmpty) {
      return LatLng(0, 0);
    }

    double latSum = 0;
    double lngSum = 0;

    for (final coord in coordenadas) {
      latSum += coord.latitude;
      lngSum += coord.longitude;
    }

    return LatLng(
      latSum / coordenadas.length,
      lngSum / coordenadas.length,
    );
  }

  /// Determina a direção predominante baseada no centro e coordenadas
  String _determinarDirecao(LatLng centro, List<LatLng> coordenadas) {
    if (coordenadas.isEmpty) {
      return 'Centro do talhão';
    }

    // Calcular distâncias em cada direção
    double norte = 0, sul = 0, leste = 0, oeste = 0;
    int countNorte = 0, countSul = 0, countLeste = 0, countOeste = 0;

    for (final coord in coordenadas) {
      final latDiff = coord.latitude - centro.latitude;
      final lngDiff = coord.longitude - centro.longitude;

      if (latDiff > 0.001) { // Norte
        norte += latDiff;
        countNorte++;
      } else if (latDiff < -0.001) { // Sul
        sul += latDiff.abs();
        countSul++;
      }

      if (lngDiff > 0.001) { // Leste
        leste += lngDiff;
        countLeste++;
      } else if (lngDiff < -0.001) { // Oeste
        oeste += lngDiff.abs();
        countOeste++;
      }
    }

    // Determinar direção predominante
    final direcoes = [
      {'nome': 'Norte', 'valor': norte, 'count': countNorte},
      {'nome': 'Sul', 'valor': sul, 'count': countSul},
      {'nome': 'Leste', 'valor': leste, 'count': countLeste},
      {'nome': 'Oeste', 'valor': oeste, 'count': countOeste},
    ];

    direcoes.sort((a, b) {
      final aScore = (a['valor'] as double) * (a['count'] as int);
      final bScore = (b['valor'] as double) * (b['count'] as int);
      return bScore.compareTo(aScore);
    });

    if (direcoes.first['count'] as int > 0) {
      return '${direcoes.first['nome']} do talhão';
    }

    return 'Centro do talhão';
  }

  /// Normaliza a intensidade para o mapa de calor (0-1)
  double _normalizarIntensidade(double severidade) {
    // Normalizar para escala 0-1
    // Severidade máxima considerada: 100%
    return (severidade / 100.0).clamp(0.0, 1.0);
  }

  /// Obtém estatísticas de infestação por região do talhão
  Future<Map<String, dynamic>> obterEstatisticasRegiao(String talhaoId) async {
    try {
      final db = await _database.database;
      
      // Buscar dados de monitoramento
      final List<Map<String, dynamic>> dados = await db.rawQuery('''
        SELECT 
          latitude,
          longitude,
          created_at,
          occurrences
        FROM monitoring_points
        WHERE plot_id = ?
        ORDER BY created_at DESC
        LIMIT 20
      ''', [talhaoId]);

      if (dados.isEmpty) {
        return {
          'regiao_mais_critica': 'Sem dados',
          'severidade_media': 0.0,
          'total_pontos': 0,
          'ultima_atualizacao': null,
        };
      }

      // Analisar dados por região
      final regioes = _analisarRegioes(dados);
      final regiaoMaisCritica = regioes.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      return {
        'regiao_mais_critica': regiaoMaisCritica.key,
        'severidade_media': regioes.values.reduce((a, b) => a + b) / regioes.length,
        'total_pontos': dados.length,
        'ultima_atualizacao': dados.first['created_at'],
        'regioes': regioes,
      };
    } catch (e) {
      Logger.error('HeatmapService', 'Erro ao obter estatísticas de região: $e');
      return {
        'regiao_mais_critica': 'Erro ao analisar',
        'severidade_media': 0.0,
        'total_pontos': 0,
        'ultima_atualizacao': null,
      };
    }
  }

  /// Analisa dados por regiões do talhão
  Map<String, double> _analisarRegioes(List<Map<String, dynamic>> dados) {
    final regioes = <String, double>{};
    
    for (final dado in dados) {
      final lat = dado['latitude'] as double;
      final lng = dado['longitude'] as double;
      
      // Determinar região baseada nas coordenadas
      String regiao = _determinarRegiao(lat, lng);
      
      // Calcular severidade total das ocorrências
      double severidade = 0.0;
      try {
        final ocorrencias = jsonDecode(dado['occurrences'] ?? '[]') as List;
        for (final ocorrencia in ocorrencias) {
          if (ocorrencia is Map<String, dynamic>) {
            severidade += (ocorrencia['infestationIndex'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (e) {
        // Ignorar erros de parsing
      }
      
      regioes[regiao] = (regioes[regiao] ?? 0.0) + severidade;
    }
    
    return regioes;
  }

  /// Determina a região baseada nas coordenadas
  String _determinarRegiao(double lat, double lng) {
    // Implementação simplificada - pode ser melhorada com dados reais do talhão
    if (lat > 0 && lng > 0) return 'Noroeste';
    if (lat > 0 && lng < 0) return 'Nordeste';
    if (lat < 0 && lng > 0) return 'Sudoeste';
    if (lat < 0 && lng < 0) return 'Sudeste';
    return 'Centro';
  }
} 