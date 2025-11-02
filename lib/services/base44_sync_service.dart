import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import '../models/talhao_model.dart';
// import '../models/monitoring_model.dart'; // COMENTADO - Modelo não existe
// import '../models/infestation_report_model.dart'; // COMENTADO - Modelo não existe
import '../repositories/talhao_repository.dart';
// import '../repositories/monitoring_repository.dart'; // COMENTADO - Não disponível
// import '../services/infestation_report_service.dart'; // COMENTADO - Não disponível
// import '../services/monitoring_report_service.dart'; // COMENTADO - Não disponível
import '../utils/logger.dart';

/// Serviço para sincronização com o sistema Base44
/// Responsável por enviar relatórios agronômicos completos para a plataforma Base44
/// 
/// NOTA: Funcionalidades de relatórios agronômicos comentadas temporariamente
/// até que os modelos necessários estejam disponíveis
class Base44SyncService {
  // URL base da API Base44 - será configurável futuramente
  static const String _baseUrl = 'https://api.base44.com.br/v1';
  
  // Headers padrão para as requisições
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  // final MonitoringRepository _monitoringRepository = MonitoringRepository(); // COMENTADO
  // final InfestationReportService _infestationReportService = InfestationReportService(); // COMENTADO
  // final MonitoringReportService _monitoringReportService = MonitoringReportService(); // COMENTADO

  /// Configura o token de autenticação para a API Base44
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  /// Sincroniza os dados da fazenda com o Base44
  Future<Map<String, dynamic>> syncFarm(Farm farm) async {
    try {
      Logger.info('🔄 [BASE44] Iniciando sincronização da fazenda: ${farm.name}');

      // Buscar talhões da fazenda
      final talhoes = await _talhaoRepository.getTalhoes();
      
      // Preparar dados para envio
      final farmData = _prepareFarmData(farm, talhoes);

      // Enviar para o Base44
      final response = await http.post(
        Uri.parse('$_baseUrl/farms/sync'),
        headers: _headers,
        body: jsonEncode(farmData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao conectar com Base44');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        Logger.info('✅ [BASE44] Fazenda sincronizada com sucesso');
        
        return {
          'success': true,
          'message': 'Sincronização concluída',
          'data': responseData,
        };
      } else {
        Logger.error('❌ [BASE44] Erro na sincronização: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erro ao sincronizar: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro na sincronização: $e');
      return {
        'success': false,
        'message': 'Erro ao sincronizar: $e',
      };
    }
  }

  /// Sincroniza dados de monitoramento com o Base44
  Future<Map<String, dynamic>> syncMonitoringData(Map<String, dynamic> monitoringData) async {
    try {
      Logger.info('🔄 [BASE44] Sincronizando dados de monitoramento...');

      final response = await http.post(
        Uri.parse('$_baseUrl/monitoring/sync'),
        headers: _headers,
        body: jsonEncode(monitoringData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao enviar dados de monitoramento');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('✅ [BASE44] Dados de monitoramento sincronizados');
        return {
          'success': true,
          'message': 'Monitoramento sincronizado',
        };
      } else {
        Logger.error('❌ [BASE44] Erro ao sincronizar monitoramento: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erro ao sincronizar monitoramento',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro ao sincronizar monitoramento: $e');
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  /// Sincroniza dados de plantio com o Base44
  Future<Map<String, dynamic>> syncPlantingData(Map<String, dynamic> plantingData) async {
    try {
      Logger.info('🔄 [BASE44] Sincronizando dados de plantio...');

      final response = await http.post(
        Uri.parse('$_baseUrl/planting/sync'),
        headers: _headers,
        body: jsonEncode(plantingData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao enviar dados de plantio');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('✅ [BASE44] Dados de plantio sincronizados');
        return {
          'success': true,
          'message': 'Plantio sincronizado',
        };
      } else {
        Logger.error('❌ [BASE44] Erro ao sincronizar plantio: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erro ao sincronizar plantio',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro ao sincronizar plantio: $e');
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  /// Prepara os dados da fazenda para envio ao Base44
  Map<String, dynamic> _prepareFarmData(Farm farm, List<TalhaoModel> talhoes) {
    // Calcular área total dos talhões
    double totalArea = 0.0;
    List<String> cultures = <String>[];
    
    for (var talhao in talhoes) {
      totalArea += talhao.area;
      
      // Coletar culturas únicas
      for (var safra in talhao.safras) {
        if (safra.culturaNome.isNotEmpty && !cultures.contains(safra.culturaNome)) {
          cultures.add(safra.culturaNome);
        }
      }
    }

    // Adicionar culturas do farm também
    for (var crop in farm.crops) {
      if (!cultures.contains(crop)) {
        cultures.add(crop);
      }
    }

    return {
      'farm': {
        'id': farm.id,
        'name': farm.name,
        'address': farm.address,
        'city': farm.municipality,
        'state': farm.state,
        'owner': farm.ownerName,
        'document': farm.documentNumber,
        'phone': farm.phone,
        'email': farm.email,
        'total_area': totalArea,
        'plots_count': talhoes.length,
        'cultures': cultures,
        'has_irrigation': farm.hasIrrigation,
        'created_at': farm.createdAt.toIso8601String(),
        'updated_at': farm.updatedAt.toIso8601String(),
      },
      'plots': talhoes.map((talhao) => {
        'id': talhao.id,
        'name': talhao.name,
        'area': talhao.area,
        'farm_id': talhao.fazendaId,
        'created_at': talhao.dataCriacao.toIso8601String(),
        'updated_at': talhao.dataAtualizacao.toIso8601String(),
        'cultures': talhao.safras.map((safra) => {
          'id': safra.culturaId,
          'name': safra.culturaNome,
          'color': safra.culturaCor,
          'harvest': safra.safra,
        }).toList(),
      }).toList(),
      'sync_metadata': {
        'sync_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'source': 'FortSmart Agro',
      },
    };
  }

  /// Verifica o status de sincronização com o Base44
  Future<Map<String, dynamic>> checkSyncStatus(String farmId) async {
    try {
      Logger.info('🔍 [BASE44] Verificando status de sincronização...');

      final response = await http.get(
        Uri.parse('$_baseUrl/farms/$farmId/sync-status'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout ao verificar status');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('✅ [BASE44] Status obtido com sucesso');
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao verificar status',
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro ao verificar status: $e');
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  /// Obtém o histórico de sincronizações
  Future<List<Map<String, dynamic>>> getSyncHistory(String farmId) async {
    try {
      Logger.info('📜 [BASE44] Buscando histórico de sincronizações...');

      final response = await http.get(
        Uri.parse('$_baseUrl/farms/$farmId/sync-history'),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout ao buscar histórico');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        Logger.info('✅ [BASE44] Histórico obtido: ${data.length} registros');
        return data.cast<Map<String, dynamic>>();
      } else {
        Logger.error('❌ [BASE44] Erro ao buscar histórico');
        return [];
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro ao buscar histórico: $e');
      return [];
    }
  }

  // ========================================================================
  // RELATÓRIOS AGRONÔMICOS - SINCRONIZAÇÃO COMPLETA
  // ========================================================================
  // COMENTADO TEMPORARIAMENTE - Aguardando modelos necessários
  
  /* 
  /// Sincroniza relatório agronômico completo com o Base44
  /// Inclui: monitoramento, infestação, mapas térmicos e análises
  Future<Map<String, dynamic>> syncAgronomicReport({
    required String farmId,
    required String talhaoId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeHeatmap = true,
    bool includeInfestationData = true,
    bool includeMonitoringData = true,
  }) async {
    try {
      Logger.info('🌾 [BASE44] Iniciando sincronização de relatório agronômico...');
      Logger.info('📍 Fazenda: $farmId | Talhão: $talhaoId');

      // 1. Buscar dados de monitoramento
      List<Monitoring> monitorings = [];
      if (includeMonitoringData) {
        monitorings = await _getMonitoringData(talhaoId, startDate, endDate);
        Logger.info('✅ ${monitorings.length} monitoramentos coletados');
      }

      // 2. Gerar relatório de infestação
      Map<String, dynamic>? infestationReport;
      if (includeInfestationData && monitorings.isNotEmpty) {
        infestationReport = await _generateInfestationReport(monitorings);
        Logger.info('✅ Relatório de infestação gerado');
      }

      // 3. Gerar dados de mapa térmico
      List<Map<String, dynamic>> heatmapData = [];
      if (includeHeatmap && monitorings.isNotEmpty) {
        heatmapData = _generateHeatmapData(monitorings);
        Logger.info('✅ ${heatmapData.length} pontos de mapa térmico gerados');
      }

      // 4. Preparar relatório completo
      final reportData = _prepareAgronomicReport(
        farmId: farmId,
        talhaoId: talhaoId,
        monitorings: monitorings,
        infestationReport: infestationReport,
        heatmapData: heatmapData,
        startDate: startDate,
        endDate: endDate,
      );

      // 5. Enviar para o Base44
      final response = await http.post(
        Uri.parse('$_baseUrl/agronomic-reports/sync'),
        headers: _headers,
        body: jsonEncode(reportData),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout ao enviar relatório agronômico');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        Logger.info('✅ [BASE44] Relatório agronômico sincronizado com sucesso');
        
        return {
          'success': true,
          'message': 'Relatório agronômico sincronizado',
          'report_id': responseData['report_id'],
          'data': responseData,
        };
      } else {
        Logger.error('❌ [BASE44] Erro ao sincronizar relatório: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erro ao sincronizar relatório: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro na sincronização do relatório: $e');
      return {
        'success': false,
        'message': 'Erro ao sincronizar relatório: $e',
      };
    }
  }

  /// Sincroniza apenas dados de infestação
  Future<Map<String, dynamic>> syncInfestationData({
    required String farmId,
    required String talhaoId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Logger.info('🐛 [BASE44] Sincronizando dados de infestação...');

      // Buscar monitoramentos
      final monitorings = await _getMonitoringData(talhaoId, startDate, endDate);
      
      if (monitorings.isEmpty) {
        return {
          'success': false,
          'message': 'Nenhum dado de monitoramento encontrado',
        };
      }

      // Gerar relatório de infestação
      final infestationData = await _generateInfestationReport(monitorings);

      // Enviar para Base44
      final response = await http.post(
        Uri.parse('$_baseUrl/infestation/sync'),
        headers: _headers,
        body: jsonEncode({
          'farm_id': farmId,
          'talhao_id': talhaoId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'infestation_data': infestationData,
          'sync_date': DateTime.now().toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao enviar dados de infestação');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('✅ [BASE44] Dados de infestação sincronizados');
        return {
          'success': true,
          'message': 'Dados de infestação sincronizados',
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao sincronizar infestação',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro ao sincronizar infestação: $e');
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  /// Sincroniza mapa térmico (heatmap)
  Future<Map<String, dynamic>> syncHeatmap({
    required String farmId,
    required String talhaoId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Logger.info('🗺️ [BASE44] Sincronizando mapa térmico...');

      // Buscar monitoramentos
      final monitorings = await _getMonitoringData(talhaoId, startDate, endDate);
      
      if (monitorings.isEmpty) {
        return {
          'success': false,
          'message': 'Nenhum dado para gerar mapa térmico',
        };
      }

      // Gerar dados do heatmap
      final heatmapData = _generateHeatmapData(monitorings);

      // Enviar para Base44
      final response = await http.post(
        Uri.parse('$_baseUrl/heatmap/sync'),
        headers: _headers,
        body: jsonEncode({
          'farm_id': farmId,
          'talhao_id': talhaoId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'heatmap_points': heatmapData,
          'sync_date': DateTime.now().toIso8601String(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao enviar mapa térmico');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('✅ [BASE44] Mapa térmico sincronizado');
        return {
          'success': true,
          'message': 'Mapa térmico sincronizado',
          'points_count': heatmapData.length,
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao sincronizar mapa térmico',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ [BASE44] Erro ao sincronizar mapa térmico: $e');
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  // ========================================================================
  // MÉTODOS AUXILIARES PRIVADOS
  // ========================================================================

  /// Busca dados de monitoramento filtrados por período
  Future<List<Monitoring>> _getMonitoringData(
    String talhaoId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      // Buscar todos os monitoramentos
      final allMonitorings = await _monitoringRepository.getAll();

      // Filtrar por talhão e período
      return allMonitorings.where((m) {
        // Filtro por talhão
        if (m.plotId != talhaoId && m.farmId != talhaoId) {
          return false;
        }

        // Filtro por data início
        if (startDate != null && m.date.isBefore(startDate)) {
          return false;
        }

        // Filtro por data fim
        if (endDate != null && m.date.isAfter(endDate)) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao buscar dados de monitoramento: $e');
      return [];
    }
  }

  /// Gera relatório de infestação a partir dos monitoramentos
  Future<Map<String, dynamic>> _generateInfestationReport(
    List<Monitoring> monitorings,
  ) async {
    try {
      final infestationData = <String, dynamic>{
        'total_monitorings': monitorings.length,
        'total_points': 0,
        'total_occurrences': 0,
        'organisms': <Map<String, dynamic>>[],
        'severity_distribution': {
          'low': 0,
          'medium': 0,
          'high': 0,
          'critical': 0,
        },
        'areas_affected': <Map<String, dynamic>>[],
      };

      // Mapear organismos encontrados
      final Map<String, Map<String, dynamic>> organismsMap = {};
      int totalPoints = 0;
      int totalOccurrences = 0;

      for (final monitoring in monitorings) {
        totalPoints += monitoring.points.length;

        for (final point in monitoring.points) {
          for (final occurrence in point.occurrences) {
            totalOccurrences++;

            // Agregar dados por organismo
            final organismId = occurrence.organismId?.toString() ?? 'unknown';
            final organismName = occurrence.organismName ?? 'Desconhecido';

            if (!organismsMap.containsKey(organismId)) {
              organismsMap[organismId] = {
                'id': organismId,
                'name': organismName,
                'count': 0,
                'total_severity': 0.0,
                'locations': <Map<String, dynamic>>[],
              };
            }

            organismsMap[organismId]!['count'] = 
                (organismsMap[organismId]!['count'] as int) + 1;
            organismsMap[organismId]!['total_severity'] = 
                (organismsMap[organismId]!['total_severity'] as double) + 
                occurrence.severity;

            // Adicionar localização
            (organismsMap[organismId]!['locations'] as List).add({
              'latitude': point.latitude,
              'longitude': point.longitude,
              'severity': occurrence.severity,
              'date': point.date.toIso8601String(),
            });

            // Classificar severidade
            if (occurrence.severity < 25) {
              infestationData['severity_distribution']['low']++;
            } else if (occurrence.severity < 50) {
              infestationData['severity_distribution']['medium']++;
            } else if (occurrence.severity < 75) {
              infestationData['severity_distribution']['high']++;
            } else {
              infestationData['severity_distribution']['critical']++;
            }
          }
        }
      }

      // Calcular médias e finalizar dados
      for (final organism in organismsMap.values) {
        final count = organism['count'] as int;
        final totalSeverity = organism['total_severity'] as double;
        organism['average_severity'] = count > 0 ? totalSeverity / count : 0.0;
        infestationData['organisms'].add(organism);
      }

      infestationData['total_points'] = totalPoints;
      infestationData['total_occurrences'] = totalOccurrences;

      return infestationData;
    } catch (e) {
      Logger.error('❌ Erro ao gerar relatório de infestação: $e');
      return {};
    }
  }

  /// Gera dados de mapa térmico a partir dos monitoramentos
  List<Map<String, dynamic>> _generateHeatmapData(List<Monitoring> monitorings) {
    final heatmapPoints = <Map<String, dynamic>>[];

    try {
      for (final monitoring in monitorings) {
        for (final point in monitoring.points) {
          if (point.occurrences.isEmpty) continue;

          // Calcular intensidade média do ponto
          double totalSeverity = 0.0;
          int occurrenceCount = 0;

          for (final occurrence in point.occurrences) {
            totalSeverity += occurrence.severity;
            occurrenceCount++;
          }

          final averageIntensity = occurrenceCount > 0 
              ? totalSeverity / occurrenceCount 
              : 0.0;

          // Normalizar intensidade para 0-1
          final normalizedIntensity = averageIntensity / 100.0;

          // Determinar cor baseado na intensidade
          String color;
          String level;
          if (averageIntensity >= 75) {
            color = '#FF0000'; // Vermelho - Crítico
            level = 'critical';
          } else if (averageIntensity >= 50) {
            color = '#FF9800'; // Laranja - Alto
            level = 'high';
          } else if (averageIntensity >= 25) {
            color = '#FFEB3B'; // Amarelo - Médio
            level = 'medium';
          } else {
            color = '#4CAF50'; // Verde - Baixo
            level = 'low';
          }

          heatmapPoints.add({
            'latitude': point.latitude,
            'longitude': point.longitude,
            'intensity': normalizedIntensity,
            'severity': averageIntensity,
            'color': color,
            'level': level,
            'occurrence_count': occurrenceCount,
            'date': point.date.toIso8601String(),
            'organisms': point.occurrences.map((o) => {
              'id': o.organismId,
              'name': o.organismName ?? o.name,
              'severity': o.severity,
            }).toList(),
          });
        }
      }

      Logger.info('📍 ${heatmapPoints.length} pontos de heatmap gerados');
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados de heatmap: $e');
    }

    return heatmapPoints;
  }

  /// Prepara relatório agronômico completo para envio
  Map<String, dynamic> _prepareAgronomicReport({
    required String farmId,
    required String talhaoId,
    required List<Monitoring> monitorings,
    Map<String, dynamic>? infestationReport,
    List<Map<String, dynamic>>? heatmapData,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return {
      'report_type': 'agronomic_complete',
      'farm_id': farmId,
      'talhao_id': talhaoId,
      'period': {
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'generated_at': DateTime.now().toIso8601String(),
      },
      'summary': {
        'total_monitorings': monitorings.length,
        'total_points': monitorings.fold<int>(
          0,
          (sum, m) => sum + m.points.length,
        ),
        'date_range': monitorings.isNotEmpty
            ? {
                'first': monitorings.first.date.toIso8601String(),
                'last': monitorings.last.date.toIso8601String(),
              }
            : null,
      },
      'monitoring_data': monitorings.map((m) => {
        'id': m.id,
        'date': m.date.toIso8601String(),
        'crop_name': m.cropName,
        'plot_name': m.plotName,
        'points_count': m.points.length,
        'weather_data': m.weatherData,
      }).toList(),
      'infestation_analysis': infestationReport,
      'heatmap_data': heatmapData,
      'metadata': {
        'app_version': '1.0.0',
        'source': 'FortSmart Agro',
        'sync_date': DateTime.now().toIso8601String(),
      },
    };
  }
  */ // FIM DO BLOCO COMENTADO - RELATÓRIOS AGRONÔMICOS
}
