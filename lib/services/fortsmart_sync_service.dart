import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farm.dart';
import '../models/talhao_model.dart';
import '../repositories/talhao_repository.dart';
import '../repositories/monitoring_repository.dart';
import '../utils/logger.dart';

/// Serviço de sincronização com o backend próprio no Render
/// SEM dependência de Base44 - backend 100% próprio
class FortSmartSyncService {
  // URL da sua API no Render (alterar após deploy)
  static const String _baseUrl = 'https://fortsmart-agro-api.onrender.com/api';
  
  // Headers padrão
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final MonitoringRepository _monitoringRepository = MonitoringRepository();

  /// Configura token de autenticação (se necessário no futuro)
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // ========================================================================
  // SINCRONIZAÇÃO DE FAZENDAS
  // ========================================================================

  /// Sincroniza fazenda com o servidor
  Future<Map<String, dynamic>> syncFarm(Farm farm) async {
    try {
      Logger.info('🏡 [SYNC] Sincronizando fazenda: ${farm.name}');

      // Buscar talhões
      final talhoes = await _talhaoRepository.getTalhoes();
      
      // Preparar dados
      final farmData = {
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
          'total_area': _calculateTotalArea(talhoes),
          'plots_count': talhoes.length,
          'cultures': _extractCultures(talhoes),
        },
        'plots': talhoes.map((t) => {
          'id': t.id,
          'name': t.name,
          'area': t.area,
          'farm_id': t.fazendaId,
          'polygon': t.poligonos.isNotEmpty 
            ? t.poligonos.first.pontos.map((p) => {
                'lat': p.latitude,
                'lng': p.longitude,
              }).toList()
            : [],
          'culture_id': t.cropId?.toString(),
          'culture_name': t.safras.isNotEmpty ? t.safras.first.culturaNome : null,
        }).toList(),
      };

      // Enviar para servidor
      final response = await http.post(
        Uri.parse('$_baseUrl/farms/sync'),
        headers: _headers,
        body: jsonEncode(farmData),
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('✅ [SYNC] Fazenda sincronizada');
        return {
          'success': true,
          'message': 'Fazenda sincronizada',
          'data': data,
        };
      } else {
        Logger.error('❌ [SYNC] Erro: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erro ao sincronizar: ${response.statusCode}',
        };
      }
    } catch (e) {
      Logger.error('❌ [SYNC] Erro: $e');
      return {
        'success': false,
        'message': 'Erro ao sincronizar: $e',
      };
    }
  }

  // ========================================================================
  // SINCRONIZAÇÃO DE RELATÓRIOS AGRONÔMICOS
  // ========================================================================

  /// Sincroniza relatório agronômico completo
  Future<Map<String, dynamic>> syncAgronomicReport({
    required String farmId,
    required String plotId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Logger.info('🌾 [SYNC] Sincronizando relatório agronômico...');

      // Buscar monitoramentos
      final monitorings = await _monitoringRepository.getAll();
      
      // Filtrar por talhão e período
      final filteredMonitorings = monitorings.where((m) {
        if (m.plotId != plotId && m.farmId != plotId) return false;
        if (startDate != null && m.date.isBefore(startDate)) return false;
        if (endDate != null && m.date.isAfter(endDate)) return false;
        return true;
      }).toList();

      // Preparar dados do relatório
      final reportData = {
        'farm_id': farmId,
        'plot_id': plotId,
        'report_type': 'agronomic_complete',
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'summary': {
          'total_monitorings': filteredMonitorings.length,
          'total_points': filteredMonitorings.fold<int>(
            0,
            (sum, m) => sum + m.points.length,
          ),
        },
        'monitoring_data': filteredMonitorings.map((m) => {
          'id': m.id,
          'date': m.date.toIso8601String(),
          'crop_name': m.cropName,
          'plot_name': m.plotName,
          'points_count': m.points.length,
          'weather_data': m.weatherData,
          'points': m.points.map((p) => {
            'latitude': p.latitude,
            'longitude': p.longitude,
            'date': p.date.toIso8601String(),
            'occurrences': p.occurrences.map((o) => {
              'organism_id': o.organismId,
              'organism_name': o.organismName ?? o.name,
              'severity': o.severity,
              'quantity': o.quantity ?? 0,
            }).toList(),
          }).toList(),
        }).toList(),
        'infestation_analysis': _generateInfestationAnalysis(filteredMonitorings),
        'heatmap_data': _generateHeatmapData(filteredMonitorings),
      };

      // Enviar para servidor
      final response = await http.post(
        Uri.parse('$_baseUrl/reports/agronomic'),
        headers: _headers,
        body: jsonEncode(reportData),
      ).timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('✅ [SYNC] Relatório sincronizado');
        return {
          'success': true,
          'message': 'Relatório sincronizado',
          'report_id': data['report_id'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao sincronizar relatório',
        };
      }
    } catch (e) {
      Logger.error('❌ [SYNC] Erro: $e');
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  // ========================================================================
  // BUSCAR DADOS DO SERVIDOR
  // ========================================================================

  /// Busca dados da fazenda do servidor
  Future<Map<String, dynamic>> getFarmData(String farmId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/farms/$farmId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Fazenda não encontrada'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  /// Busca estatísticas do dashboard
  Future<Map<String, dynamic>> getDashboardStats(String farmId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/farm/$farmId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  /// Busca heatmap de um talhão
  Future<Map<String, dynamic>> getHeatmap(String plotId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/heatmap/plot/$plotId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  // ========================================================================
  // MÉTODOS AUXILIARES
  // ========================================================================

  double _calculateTotalArea(List<TalhaoModel> talhoes) {
    return talhoes.fold(0.0, (sum, t) => sum + t.area);
  }

  List<String> _extractCultures(List<TalhaoModel> talhoes) {
    final Set<String> cultures = {};
    for (var t in talhoes) {
      for (var safra in t.safras) {
        if (safra.culturaNome.isNotEmpty) {
          cultures.add(safra.culturaNome);
        }
      }
    }
    return cultures.toList();
  }

  Map<String, dynamic> _generateInfestationAnalysis(List monitorings) {
    final Map<String, Map<String, dynamic>> organisms = {};
    int totalOccurrences = 0;
    final distribution = {'low': 0, 'medium': 0, 'high': 0, 'critical': 0};

    for (final m in monitorings) {
      for (final point in m.points) {
        for (final occ in point.occurrences) {
          totalOccurrences++;
          
          final orgId = occ.organismId?.toString() ?? 'unknown';
          final orgName = occ.organismName ?? occ.name ?? 'Desconhecido';

          if (!organisms.containsKey(orgId)) {
            organisms[orgId] = {
              'id': orgId,
              'name': orgName,
              'count': 0,
              'total_severity': 0.0,
            };
          }

          organisms[orgId]!['count'] = (organisms[orgId]!['count'] as int) + 1;
          organisms[orgId]!['total_severity'] = 
            (organisms[orgId]!['total_severity'] as double) + occ.severity;

          // Distribuição
          if (occ.severity < 25) distribution['low'] = distribution['low']! + 1;
          else if (occ.severity < 50) distribution['medium'] = distribution['medium']! + 1;
          else if (occ.severity < 75) distribution['high'] = distribution['high']! + 1;
          else distribution['critical'] = distribution['critical']! + 1;
        }
      }
    }

    return {
      'total_occurrences': totalOccurrences,
      'organisms': organisms.values.toList(),
      'severity_distribution': distribution,
    };
  }

  List<Map<String, dynamic>> _generateHeatmapData(List monitorings) {
    final List<Map<String, dynamic>> heatmap = [];

    for (final m in monitorings) {
      for (final point in m.points) {
        if (point.occurrences.isEmpty) continue;

        final avgSeverity = point.occurrences.fold<double>(
          0.0,
          (sum, o) => sum + o.severity,
        ) / point.occurrences.length;

        String color, level;
        if (avgSeverity >= 75) {
          color = '#FF0000';
          level = 'critical';
        } else if (avgSeverity >= 50) {
          color = '#FF9800';
          level = 'high';
        } else if (avgSeverity >= 25) {
          color = '#FFEB3B';
          level = 'medium';
        } else {
          color = '#4CAF50';
          level = 'low';
        }

        heatmap.add({
          'latitude': point.latitude,
          'longitude': point.longitude,
          'intensity': avgSeverity / 100.0,
          'severity': avgSeverity,
          'color': color,
          'level': level,
          'occurrence_count': point.occurrences.length,
          'date': point.date.toIso8601String(),
        });
      }
    }

    return heatmap;
  }
}

