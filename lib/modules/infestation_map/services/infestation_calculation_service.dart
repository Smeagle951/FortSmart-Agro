import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../models/monitoring_point.dart';
import '../../../models/organism_catalog.dart';
import '../../../models/infestation_point.dart';
import '../../../utils/logger.dart';
import 'organism_catalog_integration_service.dart';
import 'hexbin_service.dart';
import 'mathematical_infestation_calculator.dart';

/// Resultado do cálculo de score composto
class CompositeScoreResult {
  final double scorePct; // 0–100
  final String? hexbinGeoJson; // opcional
  final Map<String, dynamic> metadata; // metadados do cálculo

  CompositeScoreResult(
    this.scorePct, {
    this.hexbinGeoJson,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toMap() {
    return {
      'scorePct': scorePct,
      'hexbinGeoJson': hexbinGeoJson,
      'metadata': metadata,
    };
  }
}

/// Serviço de cálculos para infestação
/// Implementa algoritmos ponderados por precisão GPS e tempo
class InfestationCalculationService {
  final OrganismCatalogIntegrationService _organismService = OrganismCatalogIntegrationService();
  
  // Constantes para cálculos
  static const double _defaultTau = 14.0; // dias para decay exponencial
  static const double _minAccuracyWeight = 0.5; // peso mínimo para precisão GPS
  static const double _maxAccuracyWeight = 1.0; // peso máximo para precisão GPS

  /// Converte quantidade para percentual baseado na unidade e total
  double pctFromQuantity({
    required int quantity,
    required String unidade,
    required OrganismCatalog org,
    required int totalPlantas,
  }) {
    try {
      if (totalPlantas <= 0) return 0.0;
      
      double pct = 0.0;
      
      switch (unidade.toLowerCase()) {
        case 'insetos/m²':
        case 'plantas/m²':
        case 'folhas/m²':
          // Para unidades por área, considerar área do talhão
          pct = (quantity / totalPlantas.clamp(1, 1 << 31)) * 100.0;
          break;
          
        case '%':
          // Já está em percentual
          pct = quantity.toDouble();
          break;
          
        case 'unidades':
        case 'contagem':
          // Contagem simples
          pct = (quantity / totalPlantas.clamp(1, 1 << 31)) * 100.0;
          break;
          
        default:
          // Unidade não reconhecida, usar contagem simples
          pct = (quantity / totalPlantas.clamp(1, 1 << 31)) * 100.0;
      }
      
      // Garantir que está no intervalo [0, 100]
      return pct.clamp(0.0, 100.0);
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular percentual: $e');
      return 0.0;
    }
  }

  /// Determina o nível de infestação baseado no percentual
  Future<String> levelFromPct(double pct, {required String organismoId}) async {
    try {
      final thresholds = await _organismService.getOrganismThresholds(organismoId);
      if (thresholds == null) {
        Logger.warning('⚠️ Thresholds não encontrados para organismo: $organismoId');
        return 'DESCONHECIDO';
      }

      final lowLimit = thresholds['limite_baixo'] as double? ?? 25.0;
      final mediumLimit = thresholds['limite_medio'] as double? ?? 50.0;
      final highLimit = thresholds['limite_alto'] as double? ?? 75.0;

      if (pct <= lowLimit) return 'BAIXO';
      if (pct <= mediumLimit) return 'MODERADO';
      if (pct <= highLimit) return 'ALTO';
      return 'CRITICO';
      
    } catch (e) {
      Logger.error('❌ Erro ao determinar nível: $e');
      return 'DESCONHECIDO';
    }
  }

  /// Verifica se deve gerar alerta
  Future<bool> shouldAlert({
    required String level,
    required double pct,
    required String organismoId,
  }) async {
    try {
      // Sempre alertar em níveis críticos
      if (level == 'ALTO' || level == 'CRITICO') return true;
      
      // Para níveis moderados, verificar tendência
      if (level == 'MODERADO') {
        // TODO: Implementar análise de tendência
        // Por enquanto, alertar em moderado se > 40%
        return pct > 40.0;
      }
      
      return false;
      
    } catch (e) {
      Logger.error('❌ Erro ao verificar se deve alertar: $e');
      return false;
    }
  }

  /// Calcula score composto ponderado por precisão GPS e tempo
  Future<CompositeScoreResult> computeCompositeScore(
    List<MonitoringPoint> pontos, {
    required DateTime now,
    double tau = _defaultTau,
  }) async {
    try {
      if (pontos.isEmpty) {
        return CompositeScoreResult(0.0, metadata: {'error': 'Nenhum ponto fornecido'});
      }

      double numerator = 0.0;
      double denominator = 0.0;
             final weights = <String, double>{};
      
      for (final ponto in pontos) {
                 // Peso por precisão GPS
         final accuracy = ponto.gpsAccuracy ?? 3.0; // metros
         final wAcc = (1 / (1 + accuracy)).clamp(_minAccuracyWeight, _maxAccuracyWeight);
        
        // Peso por tempo (decay exponencial)
        final dtDays = now.difference(ponto.createdAt).inHours / 24.0;
        final wTime = exp(-dtDays / tau);
        
        // Peso por densidade amostral (opcional)
        final wDensity = 1.0; // Por enquanto fixo
        
        // Peso total
        final w = wAcc * wTime * wDensity;
        
                 // Calcular infestação baseado nas ocorrências
         double infestationValue = 0.0;
         if (ponto.occurrences.isNotEmpty) {
           // Usar a primeira ocorrência para cálculo
           final occurrence = ponto.occurrences.first;
           infestationValue = occurrence.infestationIndex;
         }
        
        numerator += infestationValue * w;
        denominator += w;
        
        // Armazenar pesos para debug
        weights[ponto.id] = w;
      }
      
      final score = denominator > 0 ? (numerator / denominator) : 0.0;
      
      // Gerar metadados do cálculo
      final metadata = {
        'pontos_processados': pontos.length,
        'pesos_calculados': weights,
        'tau_usado': tau,
        'timestamp_calculo': now.toIso8601String(),
        'formula': 'score = Σ(pct_i * w_acc_i * w_time_i * w_density_i) / Σ(w_acc_i * w_time_i * w_density_i)',
      };
      
      Logger.info('✅ Score composto calculado: ${score.toStringAsFixed(2)}%');
      
      return CompositeScoreResult(
        score.clamp(0.0, 100.0),
        metadata: metadata,
      );
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular score composto: $e');
      return CompositeScoreResult(0.0, metadata: {'error': e.toString()});
    }
  }

  /// Calcula estatísticas agregadas dos pontos
  Map<String, dynamic> calculateAggregateStats(List<MonitoringPoint> pontos) {
    try {
      if (pontos.isEmpty) {
        return {
          'total_pontos': 0,
          'media_infestacao': 0.0,
          'desvio_padrao': 0.0,
          'minimo': 0.0,
          'maximo': 0.0,
          'mediana': 0.0,
        };
      }

             final values = <double>[];
       for (final ponto in pontos) {
         if (ponto.occurrences.isNotEmpty) {
           final occurrence = ponto.occurrences.first;
           values.add(occurrence.infestationIndex);
         }
       }
      values.sort();
      
      final total = values.length;
      final sum = values.reduce((a, b) => a + b);
      final mean = sum / total;
      
      // Desvio padrão
      final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / total;
      final stdDev = sqrt(variance);
      
      // Estatísticas
      final min = values.first;
      final max = values.last;
      final median = total % 2 == 0 
          ? (values[total ~/ 2 - 1] + values[total ~/ 2]) / 2
          : values[total ~/ 2];

      return {
        'total_pontos': total,
        'media_infestacao': mean,
        'desvio_padrao': stdDev,
        'minimo': min,
        'maximo': max,
        'mediana': median,
        'quartil_25': values[total ~/ 4],
        'quartil_75': values[3 * total ~/ 4],
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas agregadas: $e');
      return {'error': e.toString()};
    }
  }

  /// Calcula tendência temporal dos pontos
  Map<String, dynamic> calculateTemporalTrend(List<MonitoringPoint> pontos) {
    try {
      if (pontos.length < 2) {
        return {
          'tendencia': 'INSUFICIENTE_DADOS',
          'coeficiente_angular': 0.0,
          'r_quadrado': 0.0,
        };
      }

      // Ordenar por data
      final sortedPoints = List<MonitoringPoint>.from(pontos)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      final n = sortedPoints.length;
      final xValues = <double>[];
      final yValues = <double>[];
      
      // Converter datas para dias desde o primeiro ponto
      final firstDate = sortedPoints.first.createdAt;
             for (final ponto in sortedPoints) {
         if (ponto.occurrences.isNotEmpty) {
           final occurrence = ponto.occurrences.first;
           final days = ponto.createdAt.difference(firstDate).inDays.toDouble();
           xValues.add(days);
           yValues.add(occurrence.infestationIndex);
         }
       }
      
      // Regressão linear simples
      final sumX = xValues.reduce((a, b) => a + b);
      final sumY = yValues.reduce((a, b) => a + b);
      final sumXY = xValues.asMap().entries.map((e) => e.value * yValues[e.key]).reduce((a, b) => a + b);
      final sumX2 = xValues.map((x) => x * x).reduce((a, b) => a + b);
      
      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;
      
      // Calcular R²
      final yMean = sumY / n;
      final ssRes = yValues.asMap().entries.map((e) {
        final yPred = slope * xValues[e.key] + intercept;
        return pow(e.value - yPred, 2);
      }).reduce((a, b) => a + b);
      
      final ssTot = yValues.map((y) => pow(y - yMean, 2)).reduce((a, b) => a + b);
      final rSquared = ssTot > 0 ? (1 - ssRes / ssTot) : 0.0;
      
      // Determinar tendência
      String trend;
      if (rSquared < 0.3) {
        trend = 'ESTAVEL';
      } else if (slope > 1.0) {
        trend = 'CRESCENTE_FORTE';
      } else if (slope > 0.1) {
        trend = 'CRESCENTE_SUAVE';
      } else if (slope < -1.0) {
        trend = 'DECRESCENTE_FORTE';
      } else if (slope < -0.1) {
        trend = 'DECRESCENTE_SUAVE';
      } else {
        trend = 'ESTAVEL';
      }

      return {
        'tendencia': trend,
        'coeficiente_angular': slope,
        'intercepto': intercept,
        'r_quadrado': rSquared,
        'pontos_analisados': n,
        'periodo_dias': xValues.last - xValues.first,
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao calcular tendência temporal: $e');
      return {'error': e.toString()};
    }
  }

  /// Gera dados para heatmap hexbin
  Future<Map<String, dynamic>> generateHexbinData(
    List<MonitoringPoint> pontos,
    List<LatLng> polygonBounds, {
    double hexSize = 50.0, // metros
    String? organismoId,
  }) async {
    try {
      if (pontos.isEmpty || polygonBounds.isEmpty) {
        return {
          'hexagons': [],
          'error': 'Dados insuficientes para gerar heatmap',
        };
      }

      // Usar o HexbinService para gerar dados
      final hexbinService = HexbinService();
      
      // Calcular tamanho otimizado se não especificado
      if (hexSize <= 0) {
        hexSize = hexbinService.calculateOptimalHexSize(pontos, polygonBounds);
      }
      
      // Gerar dados de hexbin
      final hexagons = await hexbinService.generateHexbinData(
        pontos,
        polygonBounds: polygonBounds,
        hexSize: hexSize,
        organismoId: organismoId,
      );
      
      // Converter para GeoJSON
      final geoJson = hexbinService.toGeoJsonFeatureCollection(hexagons);
      
      return {
        'hexagons': hexagons.map((h) => h.toMap()).toList(),
        'hex_size_meters': hexSize,
        'total_hexagons': hexagons.length,
        'status': 'IMPLEMENTADO',
        'geo_json': geoJson,
        'message': 'Heatmap hexbin gerado com sucesso',
      };
      
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados hexbin: $e');
      return {'error': e.toString()};
    }
  }

  /// NOVO: Calcula infestação usando o motor matemático unificado
  /// Combina cálculo por ponto georreferenciado + consolidação por talhão
  Future<InfestationCalculationResult> calculateMathematicalInfestation({
    required List<InfestationPoint> points,
    required String organismId,
    required String phenologicalPhase,
    double? talhaoArea,
    int? totalPlants,
  }) async {
    try {
      Logger.info('🧮 Iniciando cálculo matemático de infestação...');
      Logger.info('📊 Pontos: ${points.length}, Organismo: $organismId, Fase: $phenologicalPhase');

      // 1. Obter dados do organismo
      final organism = await _organismService.getOrganismById(organismId);
      if (organism == null) {
        Logger.error('❌ Organismo não encontrado: $organismId');
        throw Exception('Organismo não encontrado: $organismId');
      }

      // 2. Criar calculador matemático
      final calculator = MathematicalInfestationCalculator(
        points: points,
        organism: organism,
        phenologicalPhase: phenologicalPhase,
        talhaoArea: talhaoArea,
        totalPlants: totalPlants,
      );

      // 3. Executar cálculo
      final result = calculator.calculate();

      Logger.info('✅ Cálculo matemático concluído:');
      Logger.info('   📈 Classificação: ${result.classification}');
      Logger.info('   📊 Índice: ${result.infestationIndex.toStringAsFixed(2)}%');
      Logger.info('   🔥 Pontos críticos: ${result.criticalPoints.length}');
      Logger.info('   🗺️ Dados heatmap: ${result.heatmapData.length}');

      return result;

    } catch (e) {
      Logger.error('❌ Erro no cálculo matemático: $e');
      rethrow;
    }
  }

  /// NOVO: Converte MonitoringPoint para InfestationPoint
  List<InfestationPoint> convertMonitoringPointsToInfestationPoints({
    required List<MonitoringPoint> monitoringPoints,
    required String organismId,
    required String organismName,
    required String talhaoId,
    String? talhaoName,
  }) {
    return monitoringPoints.map((mp) {
      return InfestationPoint(
        latitude: mp.latitude,
        longitude: mp.longitude,
        organismId: organismId,
        organismName: organismName,
        count: mp.quantity,
        unit: mp.unidade,
        accuracy: mp.accuracy,
        collectedAt: mp.collectedAt,
        notes: mp.observacoes,
        collectorId: mp.collectorId,
        talhaoId: talhaoId,
        talhaoName: talhaoName,
      );
    }).toList();
  }

  /// NOVO: Calcula infestação a partir de dados de monitoramento
  Future<InfestationCalculationResult> calculateFromMonitoringData({
    required List<MonitoringPoint> monitoringPoints,
    required String organismId,
    required String organismName,
    required String talhaoId,
    required String phenologicalPhase,
    String? talhaoName,
    double? talhaoArea,
    int? totalPlants,
  }) async {
    try {
      Logger.info('🔄 Convertendo dados de monitoramento para cálculo matemático...');

      // 1. Converter MonitoringPoints para InfestationPoints
      final infestationPoints = convertMonitoringPointsToInfestationPoints(
        monitoringPoints: monitoringPoints,
        organismId: organismId,
        organismName: organismName,
        talhaoId: talhaoId,
        talhaoName: talhaoName,
      );

      // 2. Executar cálculo matemático
      final result = await calculateMathematicalInfestation(
        points: infestationPoints,
        organismId: organismId,
        phenologicalPhase: phenologicalPhase,
        talhaoArea: talhaoArea,
        totalPlants: totalPlants,
      );

      Logger.info('✅ Cálculo a partir de monitoramento concluído');
      return result;

    } catch (e) {
      Logger.error('❌ Erro no cálculo a partir de monitoramento: $e');
      rethrow;
    }
  }

  /// NOVO: Gera dados para visualização no mapa
  Map<String, dynamic> generateMapVisualizationData({
    required InfestationCalculationResult result,
    required String talhaoId,
  }) {
    try {
      Logger.info('🗺️ Gerando dados de visualização para o mapa...');

      // 1. Preparar dados do heatmap
      final heatmapFeatures = result.heatmapData.map((heatmap) {
        return {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [heatmap.longitude, heatmap.latitude],
          },
          'properties': {
            'intensity': heatmap.intensity,
            'level': heatmap.level,
            'radius': heatmap.radius,
            'color': _getColorForLevel(heatmap.level),
          },
        };
      }).toList();

      // 2. Preparar dados dos pontos críticos
      final criticalFeatures = result.criticalPoints.map((point) {
        return {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
          'properties': {
            'id': point.id,
            'count': point.count,
            'unit': point.unit,
            'level': 'CRÍTICO',
            'color': '#F44336',
            'collected_at': point.collectedAt.toIso8601String(),
            'notes': point.notes,
          },
        };
      }).toList();

      // 3. Compilar GeoJSON
      final geoJson = {
        'type': 'FeatureCollection',
        'features': [...heatmapFeatures, ...criticalFeatures],
        'properties': {
          'talhao_id': talhaoId,
          'classification': result.classification,
          'infestation_index': result.infestationIndex,
          'point_count': result.pointCount,
          'critical_points_count': result.criticalPoints.length,
          'generated_at': DateTime.now().toIso8601String(),
        },
      };

      Logger.info('✅ Dados de visualização gerados:');
      Logger.info('   🔥 Features heatmap: ${heatmapFeatures.length}');
      Logger.info('   ⚠️ Features críticas: ${criticalFeatures.length}');

      return {
        'success': true,
        'geojson': geoJson,
        'summary': {
          'classification': result.classification,
          'infestation_index': result.infestationIndex,
          'total_points': result.pointCount,
          'critical_points': result.criticalPoints.length,
          'average_count': result.averageCount,
          'total_count': result.totalCount,
        },
        'metadata': result.metadata,
      };

    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de visualização: $e');
      return {'error': e.toString()};
    }
  }

  /// Obtém cor para o nível de infestação
  String _getColorForLevel(String level) {
    switch (level.toUpperCase()) {
      case 'BAIXO':
        return '#4CAF50';
      case 'MODERADO':
        return '#FF9800';
      case 'ALTO':
        return '#FF5722';
      case 'CRÍTICO':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }
}
