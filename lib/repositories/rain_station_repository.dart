import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rain_station_model.dart';
import '../utils/logger.dart';

/// Repositório para gerenciar pontos de coleta de chuva
class RainStationRepository {
  static const String _stationsKey = 'rain_stations';
  
  /// Salva um ponto de chuva
  Future<bool> saveRainStation(RainStationModel station) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStations = await getAllRainStations();
      
      // Verificar se já existe (atualizar) ou adicionar novo
      final existingIndex = existingStations.indexWhere((s) => s.id == station.id);
      if (existingIndex >= 0) {
        existingStations[existingIndex] = station;
      } else {
        existingStations.add(station);
      }
      
      // Converter para JSON
      final jsonData = existingStations.map((station) => station.toMap()).toList();
      final jsonString = jsonEncode(jsonData);
      
      // Salvar
      final success = await prefs.setString(_stationsKey, jsonString);
      
      if (success) {
        Logger.info('✅ Ponto de chuva salvo: ${station.name} (${station.id})');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao salvar ponto de chuva: $e');
      return false;
    }
  }
  
  /// Obtém todos os pontos de chuva
  Future<List<RainStationModel>> getAllRainStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_stationsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonData = jsonDecode(jsonString);
      return jsonData.map((data) => RainStationModel.fromMap(data)).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar pontos de chuva: $e');
      return [];
    }
  }
  
  /// Obtém pontos de chuva ativos
  Future<List<RainStationModel>> getActiveRainStations() async {
    try {
      final allStations = await getAllRainStations();
      return allStations.where((station) => station.isActive).toList();
    } catch (e) {
      Logger.error('❌ Erro ao carregar pontos ativos: $e');
      return [];
    }
  }
  
  /// Obtém um ponto de chuva por ID
  Future<RainStationModel?> getRainStationById(String id) async {
    try {
      final allStations = await getAllRainStations();
      return allStations.firstWhere(
        (station) => station.id == id,
        orElse: () => throw Exception('Ponto não encontrado'),
      );
    } catch (e) {
      Logger.error('❌ Erro ao buscar ponto por ID: $e');
      return null;
    }
  }
  
  /// Remove um ponto de chuva
  Future<bool> deleteRainStation(String id) async {
    try {
      final allStations = await getAllRainStations();
      allStations.removeWhere((station) => station.id == id);
      
      // Converter para JSON
      final jsonData = allStations.map((station) => station.toMap()).toList();
      final jsonString = jsonEncode(jsonData);
      
      // Salvar
      final success = await SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_stationsKey, jsonString),
      );
      
      if (success) {
        Logger.info('✅ Ponto de chuva removido: $id');
      }
      
      return success;
    } catch (e) {
      Logger.error('❌ Erro ao remover ponto de chuva: $e');
      return false;
    }
  }
  
  /// Atualiza um ponto de chuva
  Future<bool> updateRainStation(RainStationModel updatedStation) async {
    try {
      final allStations = await getAllRainStations();
      final index = allStations.indexWhere((s) => s.id == updatedStation.id);
      
      if (index >= 0) {
        allStations[index] = updatedStation.copyWith(
          updatedAt: DateTime.now(),
        );
        
        // Converter para JSON
        final jsonData = allStations.map((station) => station.toMap()).toList();
        final jsonString = jsonEncode(jsonData);
        
        // Salvar
        final success = await SharedPreferences.getInstance().then(
          (prefs) => prefs.setString(_stationsKey, jsonString),
        );
        
        if (success) {
          Logger.info('✅ Ponto de chuva atualizado: ${updatedStation.name}');
        }
        
        return success;
      } else {
        Logger.error('❌ Ponto de chuva não encontrado: ${updatedStation.id}');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erro ao atualizar ponto de chuva: $e');
      return false;
    }
  }
  
  /// Cria pontos de chuva padrão para demonstração
  Future<void> createDefaultRainStations() async {
    try {
      Logger.info('🌧️ Criando pontos de chuva padrão...');
      
      final defaultStations = [
        RainStationModel.create(
          name: 'Estação Central',
          description: 'Ponto principal de coleta de chuva',
          latitude: -23.5505,
          longitude: -46.6333,
          notes: 'Localização central da fazenda',
          color: 'blue',
        ),
        RainStationModel.create(
          name: 'Estação Norte',
          description: 'Ponto de coleta na região norte',
          latitude: -23.5405,
          longitude: -46.6300,
          notes: 'Próximo ao talhão 1',
          color: 'green',
        ),
        RainStationModel.create(
          name: 'Estação Sul',
          description: 'Ponto de coleta na região sul',
          latitude: -23.5605,
          longitude: -46.6366,
          notes: 'Próximo ao talhão 3',
          color: 'orange',
        ),
      ];
      
      for (final station in defaultStations) {
        await saveRainStation(station);
      }
      
      Logger.info('✅ ${defaultStations.length} pontos de chuva padrão criados');
    } catch (e) {
      Logger.error('❌ Erro ao criar pontos padrão: $e');
    }
  }
  
  /// Limpa todos os pontos de chuva
  Future<void> clearAllStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stationsKey);
      Logger.info('✅ Todos os pontos de chuva foram removidos');
    } catch (e) {
      Logger.error('❌ Erro ao limpar pontos: $e');
    }
  }
  
  /// Obtém contagem total de pontos
  Future<int> getTotalStations() async {
    try {
      final stations = await getAllRainStations();
      return stations.length;
    } catch (e) {
      Logger.error('❌ Erro ao obter contagem: $e');
      return 0;
    }
  }
}
