import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/dashboard/dashboard_data.dart';
import '../utils/logger.dart';
import 'farm_service.dart';
import 'monitoring_service.dart';
import 'inventory_service.dart';
import 'talhao_service.dart';
import 'planting_service.dart';

/// Serviço responsável por fornecer dados para o dashboard
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final StreamController<DashboardData> _dataController = StreamController<DashboardData>.broadcast();
  Stream<DashboardData> get dataStream => _dataController.stream;

  DashboardData? _currentData;
  DashboardData? get currentData => _currentData;

  // Serviços responsáveis pelos dados
  final FarmService _farmService = FarmService();
  final MonitoringService _monitoringService = MonitoringService();
  final InventoryService _inventoryService = InventoryService();
  final TalhaoService _talhaoService = TalhaoService();
  final PlantingService _plantingService = PlantingService();

  /// Carrega todos os dados do dashboard
  Future<DashboardData> loadDashboardData() async {
    try {
      Logger.info('📊 Carregando dados do dashboard...');

      // Carregar dados de forma paralela para melhor performance
      final results = await Future.wait([
        _loadFarmProfile(),
        _loadAlerts(),
        _loadTalhoesSummary(),
        _loadPlantiosAtivos(),
        _loadMonitoramentosSummary(),
        _loadEstoqueSummary(),
        _loadWeatherData(),
        _loadIndicadoresRapidos(),
      ]);

      final dashboardData = DashboardData(
        id: const Uuid().v4(),
        farmProfile: results[0] as FarmProfile,
        alerts: results[1] as List<Alert>,
        talhoesSummary: results[2] as TalhoesSummary,
        plantiosAtivos: results[3] as PlantiosAtivos,
        monitoramentosSummary: results[4] as MonitoramentosSummary,
        estoqueSummary: results[5] as EstoqueSummary,
        weatherData: results[6] as WeatherData,
        indicadoresRapidos: results[7] as IndicadoresRapidos,
        lastUpdated: DateTime.now(),
      );

      _currentData = dashboardData;
      _dataController.add(dashboardData);

      Logger.info('✅ Dados do dashboard carregados com sucesso');
      return dashboardData;

    } catch (e) {
      Logger.error('❌ Erro ao carregar dados do dashboard: $e');
      rethrow;
    }
  }

  /// Carrega perfil da fazenda
  Future<FarmProfile> _loadFarmProfile() async {
    try {
      Logger.info('🏡 Carregando perfil da fazenda...');
      
      final farm = await _farmService.getCurrentFarm();
      if (farm != null) {
        Logger.info('✅ Fazenda carregada: ${farm.name}');
        return FarmProfile(
          nome: farm.name,
          proprietario: farm.ownerName ?? 'Não informado',
          cidade: farm.municipality ?? 'N/A',
          uf: farm.state ?? 'N/A',
          areaTotal: farm.totalArea ?? 0.0,
          totalTalhoes: 0, // Será calculado pelo TalhaoService
        );
      } else {
        Logger.warning('⚠️ Nenhuma fazenda encontrada');
        return FarmProfile.empty();
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar perfil da fazenda: $e');
      return FarmProfile.empty();
    }
  }

  /// Carrega alertas ativos
  Future<List<Alert>> _loadAlerts() async {
    try {
      Logger.info('🚨 Carregando alertas ativos...');
      
      final alerts = <Alert>[];
      
      // Buscar monitoramentos pendentes
      final monitoringStats = await _monitoringService.getMonitoringStats();
      final pendingMonitorings = monitoringStats['pending'] ?? 0;
      
      if (pendingMonitorings > 0) {
        alerts.add(Alert(
          id: 'monitoring_pending',
          titulo: 'Monitoramentos Pendentes',
          descricao: '$pendingMonitorings monitoramentos aguardando realização',
          talhao: 'Múltiplos talhões',
          data: DateTime.now(),
          level: AlertLevel.medio,
          type: AlertType.monitoramento,
          isActive: true,
        ));
      }
      
      // Buscar itens com baixo estoque
      final lowStockItems = await _inventoryService.getLowStockItemsCount();
      if (lowStockItems > 0) {
        alerts.add(Alert(
          id: 'low_stock',
          titulo: 'Baixo Estoque',
          descricao: '$lowStockItems itens com estoque baixo',
          talhao: 'Estoque geral',
          data: DateTime.now(),
          level: AlertLevel.alto,
          type: AlertType.estoque,
          isActive: true,
        ));
      }
      
      Logger.info('✅ ${alerts.length} alertas carregados');
      return alerts;
    } catch (e) {
      Logger.error('❌ Erro ao carregar alertas: $e');
      return [];
    }
  }

  /// Carrega resumo de talhões
  Future<TalhoesSummary> _loadTalhoesSummary() async {
    try {
      Logger.info('🗺️ Carregando resumo de talhões...');
      
      // Buscar dados dos talhões
      final talhoesData = {'total': 0, 'areaTotal': 0.0, 'active': 0}; // TODO: Implementar getTalhoesStats
      final totalTalhoes = talhoesData['total'] ?? 0;
      final areaTotal = talhoesData['areaTotal'] ?? 0.0;
      final talhoesAtivos = talhoesData['active'] ?? 0;
      
      Logger.info('✅ Talhões carregados: $totalTalhoes total, $areaTotal ha');
      
      return TalhoesSummary(
        totalTalhoes: (totalTalhoes as num).toInt(),
        talhoesAtivos: (talhoesAtivos as num).toInt(),
        areaTotal: (areaTotal as num).toDouble(),
        ultimaAtualizacao: DateTime.now(),
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar resumo de talhões: $e');
      return TalhoesSummary.empty();
    }
  }

  /// Carrega plantios ativos
  Future<PlantiosAtivos> _loadPlantiosAtivos() async {
    try {
      Logger.info('🌱 Carregando plantios ativos...');
      
      // Buscar dados dos plantios
      final plantingsData = {'total': 0, 'areaPlanted': 0.0}; // TODO: Implementar getActivePlantingsStats
      final totalPlantios = plantingsData['total'] ?? 0;
      final areaPlanted = plantingsData['areaPlanted'] ?? 0.0;
      
      Logger.info('✅ Plantios carregados: $totalPlantios total, $areaPlanted ha');
      
      return PlantiosAtivos(
        totalPlantios: (totalPlantios as num).toInt(),
        areaTotalPlantada: (areaPlanted as num).toDouble(),
        plantios: [], // TODO: Implementar lista detalhada de plantios
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar plantios ativos: $e');
      return PlantiosAtivos.empty();
    }
  }

  /// Carrega resumo de monitoramentos
  Future<MonitoramentosSummary> _loadMonitoramentosSummary() async {
    try {
      Logger.info('🔍 Carregando resumo de monitoramentos...');
      
      // Buscar dados dos monitoramentos
      final monitoringStats = await _monitoringService.getMonitoringStats();
      final totalMonitorings = monitoringStats['total'] ?? 0;
      final pendingMonitorings = monitoringStats['pending'] ?? 0;
      final realizedMonitorings = totalMonitorings - pendingMonitorings;
      
      Logger.info('✅ Monitoramentos carregados: $totalMonitorings total, $pendingMonitorings pendentes');
      
      return MonitoramentosSummary(
        realizados: realizedMonitorings,
        pendentes: pendingMonitorings,
        ultimoTalhao: 'N/A', // TODO: Implementar último talhão monitorado
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar resumo de monitoramentos: $e');
      return MonitoramentosSummary.empty();
    }
  }

  /// Carrega resumo de estoque
  Future<EstoqueSummary> _loadEstoqueSummary() async {
    try {
      Logger.info('📦 Carregando resumo de estoque...');
      
      // Buscar dados do estoque
      final totalItems = await _inventoryService.getTotalItemsCount();
      final lowStockItems = await _inventoryService.getLowStockItemsCount();
      
      Logger.info('✅ Estoque carregado: $totalItems total, $lowStockItems baixo estoque');
      
      return EstoqueSummary(
        totalItens: totalItems,
        itensBaixoEstoque: lowStockItems,
        principaisInsumos: [], // TODO: Implementar lista de principais insumos
      );
    } catch (e) {
      Logger.error('❌ Erro ao carregar resumo de estoque: $e');
      return EstoqueSummary.empty();
    }
  }

  /// Carrega dados climáticos (removido - não será utilizado)
  Future<WeatherData> _loadWeatherData() async {
    try {
      // Card de clima removido conforme solicitado
      return WeatherData.empty();
    } catch (e) {
      Logger.error('❌ Erro ao carregar dados climáticos: $e');
      return WeatherData.empty();
    }
  }

  /// Carrega indicadores rápidos
  Future<IndicadoresRapidos> _loadIndicadoresRapidos() async {
    try {
      // TODO: Implementar carregamento real do banco de dados
      // Fontes combinadas: Plantio, Colheita + Histórico, Mapa de Infestação, Gestão de Custos
      await Future.delayed(const Duration(milliseconds: 100));

      // Por enquanto, retornar dados vazios até implementar integração real
      return IndicadoresRapidos.empty();
    } catch (e) {
      Logger.error('❌ Erro ao carregar indicadores rápidos: $e');
      return IndicadoresRapidos.empty();
    }
  }

  /// Atualiza dados específicos do dashboard
  Future<void> refreshData() async {
    try {
      Logger.info('🔄 Atualizando dados do dashboard...');
      await loadDashboardData();
    } catch (e) {
      Logger.error('❌ Erro ao atualizar dados: $e');
    }
  }

  /// Obtém dados do dashboard
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final dashboardData = await loadDashboardData();
      
      return {
        'activityDistribution': [
          {'type': 'Monitoramentos', 'count': dashboardData.monitoramentosSummary.realizados},
          {'type': 'Plantios', 'count': dashboardData.plantiosAtivos.totalPlantios},
          {'type': 'Talhões', 'count': dashboardData.talhoesSummary.totalTalhoes},
          {'type': 'Estoque', 'count': dashboardData.estoqueSummary.totalItens},
        ],
        'lastUpdated': dashboardData.lastUpdated,
      };
    } catch (e) {
      print('❌ [DashboardService] Erro ao obter dados: $e');
      return {
        'activityDistribution': [],
        'lastUpdated': DateTime.now(),
      };
    }
  }

  /// Limpa recursos
  void dispose() {
    _dataController.close();
  }
}
