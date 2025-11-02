import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rain_data_model.dart';
import '../utils/logger.dart';

/// Repositório para persistência de dados de chuva
class RainDataRepository {
  static const String _rainDataKey = 'rain_data';
  static const String _stationsKey = 'rain_stations';
  
  /// Salva dados de chuva
  Future<bool> saveRainData(RainDataModel rainData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = await getAllRainData();
      
      // Adicionar novo dado
      existingData.add(rainData);
      
      // Converter para JSON
      final jsonData = existingData.map((data) => data.toMap()).toList();
      final jsonString = jsonEncode(jsonData);
      
      // Salvar
      final success = await prefs.setString(_rainDataKey, jsonString);
      
      if (success) {
        Logger.info('✅ Dados de chuva salvos: ${rainData.id}');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao salvar dados de chuva: $e');
      return false;
    }
  }
  
  /// Obtém todos os dados de chuva
  Future<List<RainDataModel>> getAllRainData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_rainDataKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonData = jsonDecode(jsonString);
      return jsonData.map((data) => RainDataModel.fromMap(data)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados de chuva: $e');
      return [];
    }
  }
  
  /// Obtém dados de chuva por estação
  Future<List<RainDataModel>> getRainDataByStation(String stationId) async {
    try {
      final allData = await getAllRainData();
      return allData.where((data) => data.stationId == stationId).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados por estação: $e');
      return [];
    }
  }
  
  /// Obtém dados de chuva por período
  Future<List<RainDataModel>> getRainDataByPeriod(
    String stationId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final stationData = await getRainDataByStation(stationId);
      return stationData.where((data) {
        return data.dateTime.isAfter(startDate) && 
               data.dateTime.isBefore(endDate);
      }).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados por período: $e');
      return [];
    }
  }
  
  /// Obtém dados de chuva dos últimos N dias
  Future<List<RainDataModel>> getRainDataLastDays(String stationId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      return await getRainDataByPeriod(stationId, startDate, endDate);
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados dos últimos $days dias: $e');
      return [];
    }
  }
  
  /// Calcula estatísticas de chuva
  Future<RainStatisticsModel> calculateStatistics(
    String stationId,
    String stationName,
    DateTime startDate,
    DateTime endDate,
    String periodType,
  ) async {
    try {
      final data = await getRainDataByPeriod(stationId, startDate, endDate);
      
      if (data.isEmpty) {
        return RainStatisticsModel(
          stationId: stationId,
          stationName: stationName,
          totalRainfall: 0.0,
          averageRainfall: 0.0,
          maxRainfall: 0.0,
          minRainfall: 0.0,
          totalRecords: 0,
          periodStart: startDate,
          periodEnd: endDate,
          periodType: periodType,
        );
      }
      
      final totalRainfall = data.fold<double>(0, (sum, item) => sum + item.rainfall);
      final averageRainfall = totalRainfall / data.length;
      final maxRainfall = data.map((d) => d.rainfall).reduce((a, b) => a > b ? a : b);
      final minRainfall = data.map((d) => d.rainfall).reduce((a, b) => a < b ? a : b);
      
      return RainStatisticsModel(
        stationId: stationId,
        stationName: stationName,
        totalRainfall: totalRainfall,
        averageRainfall: averageRainfall,
        maxRainfall: maxRainfall,
        minRainfall: minRainfall,
        totalRecords: data.length,
        periodStart: startDate,
        periodEnd: endDate,
        periodType: periodType,
      );
    } catch (e) {
      Logger.error('❌ Erro ao calcular estatísticas: $e');
      return RainStatisticsModel(
        stationId: stationId,
        stationName: stationName,
        totalRainfall: 0.0,
        averageRainfall: 0.0,
        maxRainfall: 0.0,
        minRainfall: 0.0,
        totalRecords: 0,
        periodStart: startDate,
        periodEnd: endDate,
        periodType: periodType,
      );
    }
  }
  
  /// Gera dados simulados para 1 ano
  Future<void> generateSimulatedDataForOneYear() async {
    try {
      Logger.info('🌧️ Gerando dados simulados para 1 ano...');
      
      final stations = [
        {'id': 'CHUVA_001', 'name': 'Estação Central', 'lat': -23.5505, 'lng': -46.6333},
        {'id': 'CHUVA_002', 'name': 'Estação Norte', 'lat': -23.5405, 'lng': -46.6300},
        {'id': 'CHUVA_003', 'name': 'Estação Sul', 'lat': -23.5605, 'lng': -46.6366},
      ];
      
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      
      for (final station in stations) {
        // Gerar dados para cada dia do último ano
        for (int i = 0; i < 365; i++) {
          final date = oneYearAgo.add(Duration(days: i));
          
          // Simular padrão sazonal de chuva
          final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
          final seasonalFactor = _calculateSeasonalFactor(dayOfYear);
          
          // Gerar chuva baseada no fator sazonal
          final baseRainfall = 5.0 + (seasonalFactor * 15.0);
          final randomFactor = (DateTime.now().millisecondsSinceEpoch % 100) / 100.0;
          final rainfall = baseRainfall * (0.5 + randomFactor);
          
          // 70% de chance de ter chuva
          if (randomFactor > 0.3) {
            final rainData = RainDataModel.create(
              stationId: station['id'] as String,
              stationName: station['name'] as String,
              rainfall: rainfall,
              rainType: _getRainType(rainfall),
              dateTime: date,
              notes: 'Dados simulados - ${_getSeasonName(dayOfYear)}',
              latitude: station['lat'] as double,
              longitude: station['lng'] as double,
            );
            
            await saveRainData(rainData);
          }
        }
      }
      
      Logger.info('✅ Dados simulados para 1 ano gerados com sucesso');
    } catch (e) {
      Logger.error('❌ Erro ao gerar dados simulados: $e');
    }
  }
  
  /// Calcula fator sazonal baseado no dia do ano
  double _calculateSeasonalFactor(int dayOfYear) {
    // Simular padrão de chuva brasileiro (mais chuva no verão)
    final summerPeak = 80; // Pico no verão (março)
    final winterLow = 260; // Baixa no inverno (setembro)
    
    final distanceFromSummer = (dayOfYear - summerPeak).abs();
    final distanceFromWinter = (dayOfYear - winterLow).abs();
    
    if (distanceFromSummer < distanceFromWinter) {
      return 1.0 - (distanceFromSummer / 90.0); // Verão
    } else {
      return 0.3 + (0.7 * (1.0 - (distanceFromWinter / 90.0))); // Inverno
    }
  }
  
  /// Obtém tipo de chuva baseado na quantidade (para dados simulados)
  String _getRainType(double rainfall) {
    if (rainfall > 20) return 'Chuva Torrencial (20mm+)';
    if (rainfall > 15) return 'Chuva Forte (15-20mm)';
    if (rainfall > 10) return 'Chuva Moderada (10-15mm)';
    if (rainfall > 5) return 'Chuva Normal (5-10mm)';
    if (rainfall > 2) return 'Chuva Fraca (2-5mm)';
    return 'Garoa (0-2mm)';
  }
  
  /// Obtém nome da estação baseado no dia do ano
  String _getSeasonName(int dayOfYear) {
    if (dayOfYear < 80 || dayOfYear > 260) return 'Verão';
    if (dayOfYear < 170) return 'Outono';
    if (dayOfYear < 260) return 'Inverno';
    return 'Primavera';
  }
  
  /// Limpa todos os dados (para testes)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rainDataKey);
      Logger.info('✅ Todos os dados de chuva foram limpos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar dados: $e');
    }
  }
  
  /// Obtém contagem total de registros
  Future<int> getTotalRecords() async {
    try {
      final data = await getAllRainData();
      return data.length;
    } catch (e) {
      Logger.error('❌ Erro ao obter contagem: $e');
      return 0;
    }
  }
}
