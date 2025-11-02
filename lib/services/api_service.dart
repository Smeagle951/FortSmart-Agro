import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../models/plot_status.dart';
import '../models/monitoring_alert.dart';
import '../models/planting_progress.dart';
import '../models/inventory_status.dart';
import '../models/experiment.dart';

/// Serviço responsável por comunicação com APIs externas
class ApiService {
  final String _baseUrl = 'https://api.fortsmartagro.com/v1';
  
  /// Getter para a URL base da API
  String get baseUrl => _baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Configura o token de autenticação
  void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }
  
  /// Obtém a URL base da API
  String getBaseUrl() {
    return _baseUrl;
  }
  
  /// Busca talhões da API
  Future<List<dynamic>> fetchPlots() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plots'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        Logger.error('Erro ao buscar talhões: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      Logger.error('Erro ao buscar talhões', e);
      return [];
    }
  }
  
  /// Busca culturas da API
  Future<List<dynamic>> fetchCrops() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/crops'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        Logger.error('Erro ao buscar culturas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      Logger.error('Erro ao buscar culturas', e);
      return [];
    }
  }
  
  /// Busca variedades da API
  Future<List<dynamic>> fetchVarieties() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/varieties'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        Logger.error('Erro ao buscar variedades: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      Logger.error('Erro ao buscar variedades', e);
      return [];
    }
  }
  
  /// Envia uma propriedade para a API
  Future<Map<String, dynamic>> sendProperty(dynamic property) async {
    try {
      // Preparar dados para envio
      final Map<String, dynamic> propertyData = {
        'id': property.id.toString(),
        'name': property.name,
        // Adicionar outros campos necessários
      };
      
      return await post('properties', propertyData);
    } catch (e) {
      Logger.error('Erro ao enviar propriedade: $e');
      return {'success': false, 'error': 'Erro ao enviar propriedade: $e'};
    }
  }

  /// Realiza uma requisição GET
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
      );
      
      return _handleResponse(response);
    } catch (e) {
      Logger.error('Erro na requisição GET: $e');
      return {'success': false, 'error': 'Erro na comunicação: $e'};
    }
  }

  /// Realiza uma requisição POST
  Future<Map<String, dynamic>> post(String endpoint, dynamic data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      Logger.error('Erro na requisição POST: $e');
      return {'success': false, 'error': 'Erro na comunicação: $e'};
    }
  }

  /// Obtém dados gerais do dashboard (culturas, estoque, alertas)
  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await get('dashboard/overview');
      return response;
    } catch (e) {
      Logger.error('Erro ao obter visão geral do dashboard: $e');
      return {'success': false, 'error': 'Erro ao obter dados do dashboard: $e'};
    }
  }

  /// Obtém status de todos os talhões com monitoramento
  Future<List<PlotStatus>> getPlotStatuses({
    String? plotId,
    String? cropType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Construir parâmetros da consulta
      final queryParams = <String>[];
      
      if (plotId != null) queryParams.add('plot_id=$plotId');
      if (cropType != null) queryParams.add('crop_type=$cropType');
      if (startDate != null) queryParams.add('start_date=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('end_date=${endDate.toIso8601String()}');
      
      final endpoint = queryParams.isEmpty
          ? 'talhoes/status'
          : 'talhoes/status?${queryParams.join('&')}';
          
      final response = await get(endpoint);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => PlotStatus.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao obter status dos talhões: $e');
      return [];
    }
  }

  /// Obtém dados de evolução de DAE nos plantios
  Future<List<PlantingProgress>> getPlantingProgress({
    String? plotId,
    String? cropType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Construir parâmetros da consulta
      final queryParams = <String>[];
      
      if (plotId != null) queryParams.add('plot_id=$plotId');
      if (cropType != null) queryParams.add('crop_type=$cropType');
      if (startDate != null) queryParams.add('start_date=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('end_date=${endDate.toIso8601String()}');
      
      final endpoint = queryParams.isEmpty
          ? 'plantios/dae'
          : 'plantios/dae?${queryParams.join('&')}';
          
      final response = await get(endpoint);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => PlantingProgress.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao obter progresso dos plantios: $e');
      return [];
    }
  }

  /// Obtém alertas de monitoramento
  Future<List<MonitoringAlert>> getMonitoringAlerts({
    String? plotId,
    String? cropType,
    DateTime? startDate,
    DateTime? endDate,
    bool includeResolved = false,
  }) async {
    try {
      // Construir parâmetros da consulta
      final queryParams = <String>[];
      
      if (plotId != null) queryParams.add('plot_id=$plotId');
      if (cropType != null) queryParams.add('crop_type=$cropType');
      if (startDate != null) queryParams.add('start_date=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('end_date=${endDate.toIso8601String()}');
      queryParams.add('include_resolved=${includeResolved ? 'true' : 'false'}');
      
      final endpoint = queryParams.isEmpty
          ? 'monitoramentos/alertas'
          : 'monitoramentos/alertas?${queryParams.join('&')}';
          
      final response = await get(endpoint);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => MonitoringAlert.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao obter alertas de monitoramento: $e');
      return [];
    }
  }

  /// Obtém status do inventário
  Future<List<InventoryStatus>> getInventoryStatus({
    String? category,
    InventoryStatusLevel? level,
  }) async {
    try {
      // Construir parâmetros da consulta
      final queryParams = <String>[];
      
      if (category != null) queryParams.add('category=$category');
      if (level != null) {
        String levelStr = '';
        switch (level) {
          case InventoryStatusLevel.critical:
            levelStr = 'critical';
            break;
          case InventoryStatusLevel.warning:
            levelStr = 'warning';
            break;
          case InventoryStatusLevel.ok:
            levelStr = 'ok';
            break;
        }
        queryParams.add('level=$levelStr');
      }
      
      final endpoint = queryParams.isEmpty
          ? 'estoque'
          : 'estoque?${queryParams.join('&')}';
          
      final response = await get(endpoint);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => InventoryStatus.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao obter status do inventário: $e');
      return [];
    }
  }

  /// Obtém dados dos experimentos ativos
  Future<List<Experiment>> getActiveExperiments({
    String? plotId,
    String? cropType,
  }) async {
    try {
      // Construir parâmetros da consulta
      final queryParams = <String>[];
      
      if (plotId != null) queryParams.add('plot_id=$plotId');
      if (cropType != null) queryParams.add('crop_type=$cropType');
      
      final endpoint = queryParams.isEmpty
          ? 'experimentos'
          : 'experimentos?${queryParams.join('&')}';
          
      final response = await get(endpoint);
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((item) => Experiment.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      Logger.error('Erro ao obter experimentos ativos: $e');
      return [];
    }
  }
  
  /// Sincroniza uma amostra de solo com o servidor
  Future<Map<String, dynamic>> syncSoilSample(
    Map<String, dynamic> sampleData,
    List<Map<String, dynamic>> pointsData,
    Map<String, List<int>> images
  ) async {
    try {
      final endpoint = 'soil-samples/sync';
      
      // Preparar os dados para envio
      final requestData = {
        'sample': sampleData,
        'points': pointsData,
      };
      
      // Criar um cliente HTTP multipart para enviar as imagens
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$endpoint'),
      );
      
      // Adicionar headers
      _headers.forEach((key, value) {
        request.headers[key] = value;
      });
      
      // Adicionar os dados da amostra e pontos como um campo JSON
      request.fields['data'] = jsonEncode(requestData);
      
      // Adicionar as imagens como arquivos
      for (final entry in images.entries) {
        final pointId = entry.key;
        final imageBytes = entry.value;
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'image_$pointId',
            imageBytes,
            filename: '$pointId.jpg',
          ),
        );
      }
      
      // Enviar a requisição
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      Logger.error('Erro ao sincronizar amostra de solo: $e');
      return {'success': false, 'error': 'Erro na comunicação: $e'};
    }
  }

  /// Resolve um alerta marcando-o como resolvido
  Future<bool> resolveAlert(String alertId) async {
    try {
      final response = await post('monitoramentos/alertas/$alertId/resolver', {});
      return response['success'] == true;
    } catch (e) {
      Logger.error('Erro ao resolver alerta: $e');
      return false;
    }
  }

  /// Manipula respostas das requisições
  Map<String, dynamic> _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    
    if (statusCode >= 200 && statusCode < 300) {
      return responseData;
    } else {
      Logger.error('Erro na API: ${responseData['message'] ?? 'Desconhecido'} (código: $statusCode)');
      return {
        'success': false,
        'error': responseData['message'] ?? 'Erro no servidor',
        'errorCode': statusCode,
        'statusCode': statusCode,
      };
    }
  }

  // Método removido por não ser utilizado
}
