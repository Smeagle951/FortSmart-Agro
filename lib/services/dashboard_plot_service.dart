import 'package:flutter/material.dart';
import '../models/plot.dart';
import '../models/talhao_model.dart';
import '../repositories/talhao_plot_adapter.dart';
import '../repositories/plot_repository.dart';
import '../utils/logger.dart';

/// Serviço para integração dos talhões com o dashboard
class DashboardPlotService {
  final TalhaoPlotAdapter _talhaoAdapter = TalhaoPlotAdapter();
  final PlotRepository _plotRepository = PlotRepository();
  
  /// Singleton para o serviço
  static final DashboardPlotService _instance = DashboardPlotService._internal();
  
  factory DashboardPlotService() {
    return _instance;
  }
  
  DashboardPlotService._internal();

  /// Carrega todos os talhões para exibição no dashboard
  Future<List<Plot>> getAllPlotsForDashboard() async {
    try {
      // Sincronizar os talhões criados com o Mapbox com os plots
      await _talhaoAdapter.syncTalhoesToPlots();
      
      // Obter todos os plots, que agora incluem os talhões do Mapbox
      final plots = await _plotRepository.getAllPlots();
      
      Logger.info('Carregados ${plots.length} talhões para o dashboard');
      return plots;
    } catch (e) {
      Logger.error('Erro ao carregar talhões para o dashboard: $e');
      return [];
    }
  }

  /// Carrega os talhões de uma fazenda específica
  Future<List<Plot>> getPlotsByFarmId(dynamic farmId) async {
    try {
      // Sincronizar os talhões criados com o Mapbox com os plots
      await _talhaoAdapter.syncTalhoesToPlots();
      
      // Obter plots filtrados por fazenda
      final plots = await _plotRepository.getPlotsByFarm(farmId);
      
      Logger.info('Carregados ${plots.length} talhões da fazenda $farmId para o dashboard');
      return plots;
    } catch (e) {
      Logger.error('Erro ao carregar talhões da fazenda para o dashboard: $e');
      return [];
    }
  }

  /// Obtém um talhão específico para o dashboard
  Future<Plot?> getPlotForDashboard(String id) async {
    try {
      // Sincronizar os talhões criados com o Mapbox com os plots
      await _talhaoAdapter.syncTalhoesToPlots();
      
      // Obter o plot específico
      final plot = await _plotRepository.getPlotById(id);
      
      return plot;
    } catch (e) {
      Logger.error('Erro ao carregar talhão específico para o dashboard: $e');
      return null;
    }
  }

  /// Obtém as culturas únicas dos talhões
  Future<List<String>> getUniqueCrops() async {
    try {
      // Sincronizar os talhões criados com o Mapbox com os plots
      await _talhaoAdapter.syncTalhoesToPlots();
      
      // Obter todos os plots
      final plots = await _plotRepository.getAllPlots();
      
      // Extrair as culturas únicas
      final Set<String> uniqueCrops = {};
      
      for (var plot in plots) {
        String? cultura;
        
        // Verificar primeiro cropName, depois cropType
        if (plot.cropName != null && plot.cropName!.isNotEmpty) {
          cultura = plot.cropName;
        } else if (plot.cropType != null && plot.cropType!.isNotEmpty) {
          cultura = plot.cropType;
        }
        
        if (cultura != null && cultura.isNotEmpty) {
          uniqueCrops.add(cultura);
        }
      }
      
      return uniqueCrops.toList()..sort();
    } catch (e) {
      Logger.error('Erro ao obter culturas únicas: $e');
      return [];
    }
  }

  /// Obtém a área total por cultura
  Future<Map<String, double>> getTotalAreaByCrop() async {
    try {
      // Sincronizar os talhões criados com o Mapbox com os plots
      await _talhaoAdapter.syncTalhoesToPlots();
      
      // Obter todos os plots
      final plots = await _plotRepository.getAllPlots();
      
      // Calcular a área total por cultura
      final Map<String, double> areaByCrop = {};
      
      for (var plot in plots) {
        String? cultura;
        
        // Verificar primeiro cropName, depois cropType
        if (plot.cropName != null && plot.cropName!.isNotEmpty) {
          cultura = plot.cropName;
        } else if (plot.cropType != null && plot.cropType!.isNotEmpty) {
          cultura = plot.cropType;
        }
        
        if (cultura != null && cultura.isNotEmpty) {
          final area = plot.area ?? 0.0;
          
          if (areaByCrop.containsKey(cultura)) {
            areaByCrop[cultura] = areaByCrop[cultura]! + area;
          } else {
            areaByCrop[cultura] = area;
          }
        }
      }
      
      return areaByCrop;
    } catch (e) {
      Logger.error('Erro ao calcular área total por cultura: $e');
      return {};
    }
  }
}
