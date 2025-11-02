import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// Serviço de IA para detecção de pragas e doenças
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Configurações
  static const String _apiBaseUrl = 'http://localhost:8000';
  static const String _tfliteModelPath = 'assets/models/';
  
  // Cache de predições
  final Map<String, Map<String, dynamic>> _predictionCache = {};
  
  /// Prediz risco de infestação para um talhão
  Future<Map<String, dynamic>> predictInfestationRisk({
    required String talhaoId,
    required String cultura,
    required double areaHa,
    double? temperatura,
    double? umidade,
    double? precipitacao7d,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Verificar cache primeiro
      final cacheKey = '${talhaoId}_${DateTime.now().toIso8601String().split('T')[0]}';
      if (_predictionCache.containsKey(cacheKey)) {
        print('🎯 Usando predição do cache para talhão: $talhaoId');
        return _predictionCache[cacheKey]!;
      }

      // Preparar dados para predição
      final talhaoData = {
        'talhao_id': talhaoId,
        'cultura': cultura,
        'area_ha': areaHa,
        'temperatura': temperatura ?? 25.0,
        'umidade': umidade ?? 60.0,
        'precipitacao_7d': precipitacao7d ?? 0.0,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Tentar predição local primeiro (TensorFlow Lite)
      Map<String, dynamic>? localPrediction;
      try {
        localPrediction = await _predictLocal(talhaoData);
        if (localPrediction != null && localPrediction['status'] == 'success') {
          print('🤖 Predição local realizada com sucesso');
          _predictionCache[cacheKey] = localPrediction;
          return localPrediction;
        }
      } catch (e) {
        print('⚠️ Erro na predição local: $e');
      }

      // Fallback para API remota
      print('🌐 Usando predição remota via API');
      final remotePrediction = await _predictRemote(talhaoData);
      _predictionCache[cacheKey] = remotePrediction;
      return remotePrediction;

    } catch (e) {
      print('❌ Erro na predição de infestação: $e');
      return {
        'status': 'error',
        'message': 'Erro na predição: $e',
        'risk_level': 'Desconhecido',
        'risk_score': 0.0,
        'recommendations': ['Verificar conexão e tentar novamente']
      };
    }
  }

  /// Predição local usando TensorFlow Lite
  Future<Map<String, dynamic>?> _predictLocal(Map<String, dynamic> talhaoData) async {
    try {
      // TODO: Implementar TensorFlow Lite
      // Por enquanto, retorna null para usar API remota
      print('🔧 TensorFlow Lite não implementado ainda');
      return null;
      
      // Código futuro para TFLite:
      /*
      final interpreter = await tflite.Interpreter.fromAsset('models/pest_detection.tflite');
      
      // Preparar input
      final input = _prepareInputForTFLite(talhaoData);
      
      // Fazer predição
      final output = List.filled(1, 0.0);
      interpreter.run(input, output);
      
      final riskScore = output[0];
      final riskLevel = _getRiskLevel(riskScore);
      
      return {
        'status': 'success',
        'risk_score': riskScore,
        'risk_level': riskLevel,
        'recommendations': _getRecommendations(riskLevel),
        'source': 'local_tflite'
      };
      */
    } catch (e) {
      print('❌ Erro na predição local: $e');
      return null;
    }
  }

  /// Predição remota via API
  Future<Map<String, dynamic>> _predictRemote(Map<String, dynamic> talhaoData) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/predict/infestation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(talhaoData),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        result['source'] = 'remote_api';
        return result;
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na predição remota: $e');
      // Retornar predição baseada em regras simples
      return _getFallbackPrediction(talhaoData);
    }
  }

  /// Predição de fallback baseada em regras simples
  Map<String, dynamic> _getFallbackPrediction(Map<String, dynamic> talhaoData) {
    final temperatura = talhaoData['temperatura'] ?? 25.0;
    final umidade = talhaoData['umidade'] ?? 60.0;
    final precipitacao = talhaoData['precipitacao_7d'] ?? 0.0;
    
    // Regras simples baseadas em condições climáticas
    double riskScore = 0.0;
    
    // Temperatura alta aumenta risco
    if (temperatura > 30) riskScore += 0.3;
    else if (temperatura > 25) riskScore += 0.2;
    
    // Umidade alta aumenta risco
    if (umidade > 80) riskScore += 0.3;
    else if (umidade > 70) riskScore += 0.2;
    
    // Precipitação recente aumenta risco
    if (precipitacao > 20) riskScore += 0.2;
    else if (precipitacao > 10) riskScore += 0.1;
    
    final riskLevel = _getRiskLevel(riskScore);
    
    return {
      'status': 'success',
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'recommendations': _getRecommendations(riskLevel),
      'source': 'fallback_rules'
    };
  }

  /// Determina nível de risco baseado no score
  String _getRiskLevel(double riskScore) {
    if (riskScore >= 0.7) return 'Alto';
    if (riskScore >= 0.4) return 'Médio';
    return 'Baixo';
  }

  /// Gera recomendações baseadas no nível de risco
  List<String> _getRecommendations(String riskLevel) {
    switch (riskLevel) {
      case 'Alto':
        return [
          'Realizar monitoramento intensivo',
          'Aplicar tratamento preventivo',
          'Verificar condições climáticas',
          'Considerar aplicação de defensivos'
        ];
      case 'Médio':
        return [
          'Aumentar frequência de monitoramento',
          'Preparar plano de ação',
          'Monitorar condições climáticas',
          'Verificar histórico de pragas'
        ];
      default:
        return [
          'Manter monitoramento regular',
          'Observar mudanças nas condições',
          'Documentar observações'
        ];
    }
  }

  /// Salva dados de monitoramento para treinamento
  Future<bool> saveMonitoringData({
    required String talhaoId,
    required String cultura,
    required String pragaDetectada,
    required String intensidade,
    required double areaHa,
    double? temperatura,
    double? umidade,
    double? precipitacao7d,
  }) async {
    try {
      final monitoringData = {
        'talhao_id': talhaoId,
        'cultura': cultura,
        'data_coleta': DateTime.now().toIso8601String(),
        'praga_detectada': pragaDetectada,
        'intensidade': intensidade,
        'area_ha': areaHa,
        'temperatura': temperatura ?? 25.0,
        'umidade': umidade ?? 60.0,
        'precipitacao_7d': precipitacao7d ?? 0.0,
      };

      // Salvar localmente no SQLite
      await _saveToLocalDatabase(monitoringData);

      // Enviar para API em background
      _sendToAPI(monitoringData);

      return true;
    } catch (e) {
      print('❌ Erro ao salvar dados de monitoramento: $e');
      return false;
    }
  }

  /// Salva dados no banco local
  Future<void> _saveToLocalDatabase(Map<String, dynamic> data) async {
    try {
      final db = await AppDatabase.instance.database;
      
      await db.insert('monitoring_ai_data', {
        'talhao_id': data['talhao_id'],
        'cultura': data['cultura'],
        'data_coleta': data['data_coleta'],
        'praga_detectada': data['praga_detectada'],
        'intensidade': data['intensidade'],
        'area_ha': data['area_ha'],
        'temperatura': data['temperatura'],
        'umidade': data['umidade'],
        'precipitacao_7d': data['precipitacao_7d'],
        'sincronizado': 0, // Não sincronizado ainda
        'criado_em': DateTime.now().toIso8601String(),
      });
      
      print('✅ Dados salvos no banco local');
    } catch (e) {
      print('❌ Erro ao salvar no banco local: $e');
    }
  }

  /// Envia dados para API em background
  Future<void> _sendToAPI(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/monitoring/data'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        print('✅ Dados enviados para API com sucesso');
        // Marcar como sincronizado no banco local
        await _markAsSynced(data['talhao_id']);
      } else {
        print('⚠️ Erro ao enviar dados para API: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Erro na comunicação com API: $e');
    }
  }

  /// Marca dados como sincronizados
  Future<void> _markAsSynced(String talhaoId) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.update(
        'monitoramento_ai_data',
        {'sincronizado': 1},
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
      );
    } catch (e) {
      print('❌ Erro ao marcar como sincronizado: $e');
    }
  }

  /// Obtém histórico de predições
  Future<List<Map<String, dynamic>>> getPredictionHistory(String talhaoId) async {
    try {
      final db = await AppDatabase.instance.database;
      final results = await db.query(
        'prediction_history',
        where: 'talhao_id = ?',
        whereArgs: [talhaoId],
        orderBy: 'data_predicao DESC',
        limit: 10,
      );
      
      return results;
    } catch (e) {
      print('❌ Erro ao obter histórico: $e');
      return [];
    }
  }

  /// Limpa cache de predições
  void clearCache() {
    _predictionCache.clear();
    print('🧹 Cache de predições limpo');
  }

  /// Verifica status da API
  Future<bool> checkAPIStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ API não disponível: $e');
      return false;
    }
  }
}
