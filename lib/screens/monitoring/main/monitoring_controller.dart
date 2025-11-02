import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/logger.dart';
import '../../services/talhao_module_service.dart';
import '../../services/cultura_service.dart';
import '../../services/database_fix_service.dart';
import '../../services/talhao_notification_service.dart';
import '../../models/talhao_model.dart';
import '../../models/cultura_model.dart';
import '../../models/monitoring.dart';
import '../../models/monitoring_point.dart';
import 'monitoring_state.dart';

/// Controlador principal do módulo de monitoramento
/// Gerencia toda a lógica de negócio e estado
class MonitoringController extends ChangeNotifier {
  final TalhaoModuleService _talhaoService = TalhaoModuleService();
  final CulturaService _culturaService = CulturaService();
  
  // Estado gerenciado
  final MonitoringState _state = MonitoringState();
  
  // Getters para o estado
  MonitoringState get state => _state;
  bool get isLoading => _state.isLoading;
  bool get isInitialized => _state.isInitialized;
  String? get errorMessage => _state.errorMessage;
  
  // Dados
  List<TalhaoModel> get availableTalhoes => _state.availableTalhoes;
  List<CulturaModel> get availableCulturas => _state.availableCulturas;
  TalhaoModel? get selectedTalhao => _state.selectedTalhao;
  CulturaModel? get selectedCultura => _state.selectedCultura;
  LatLng? get currentPosition => _state.currentPosition;
  
  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }
  
  /// Inicializa o controlador
  Future<void> initialize() async {
    try {
      _state.setLoading(true);
      _state.setError(null);
      
      Logger.info('🔄 Inicializando controlador de monitoramento...');
      
      // Primeiro, verificar e corrigir estrutura do banco
      Logger.info('🔧 Verificando estrutura do banco de dados...');
      final dbFixed = await DatabaseFixService().fixDatabaseStructure();
      
      if (!dbFixed) {
        Logger.warning('⚠️ Problemas na estrutura do banco, mas continuando...');
      }
      
      // Carregar dados básicos em paralelo
      await Future.wait([
        _loadTalhoes(),
        _loadCulturas(),
        _getCurrentLocation(),
      ]);
      
      _state.setInitialized(true);
      _state.setLoading(false);
      
      Logger.info('✅ Controlador de monitoramento inicializado com sucesso');
      notifyListeners();
      
    } catch (e) {
      Logger.error('❌ Erro ao inicializar controlador: $e');
      _state.setError('Erro ao inicializar: $e');
      _state.setLoading(false);
      notifyListeners();
      rethrow;
    }
  }
  
  /// Carrega lista de talhões disponíveis
  Future<void> _loadTalhoes() async {
    try {
      Logger.info('📋 Carregando talhões...');
      final talhoes = await _talhaoService.listarTalhoes();
      _state.setAvailableTalhoes(talhoes);
      Logger.info('✅ ${talhoes.length} talhões carregados');
    } catch (e) {
      Logger.error('❌ Erro ao carregar talhões: $e');
      _state.setAvailableTalhoes([]);
    }
  }
  
  /// Carrega lista de culturas disponíveis
  Future<void> _loadCulturas() async {
    try {
      Logger.info('🌱 Carregando culturas...');
      final culturas = await _culturaService.listarCulturas();
      _state.setAvailableCulturas(culturas);
      Logger.info('✅ ${culturas.length} culturas carregadas');
    } catch (e) {
      Logger.error('❌ Erro ao carregar culturas: $e');
      _state.setAvailableCulturas([]);
    }
  }
  
  /// Obtém localização atual
  Future<void> _getCurrentLocation() async {
    try {
      Logger.info('📍 Obtendo localização atual...');
      
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.warning('⚠️ Permissão de localização negada');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Logger.warning('⚠️ Permissão de localização negada permanentemente');
        return;
      }
      
      // Obter posição
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _state.setCurrentPosition(LatLng(position.latitude, position.longitude));
      Logger.info('✅ Localização obtida: ${position.latitude}, ${position.longitude}');
      
    } catch (e) {
      Logger.error('❌ Erro ao obter localização: $e');
      // Não definir erro crítico, apenas log
    }
  }
  
  /// Atualiza dados
  Future<void> refreshData() async {
    try {
      Logger.info('🔄 Atualizando dados...');
      await Future.wait([
        _loadTalhoes(),
        _loadCulturas(),
        _getCurrentLocation(),
      ]);
      Logger.info('✅ Dados atualizados com sucesso');
      notifyListeners();
    } catch (e) {
      Logger.error('❌ Erro ao atualizar dados: $e');
      _state.setError('Erro ao atualizar: $e');
      notifyListeners();
    }
  }
  
  /// Seleciona um talhão
  void selectTalhao(TalhaoModel? talhao) {
    _state.setSelectedTalhao(talhao);
    Logger.info('🎯 Talhão selecionado: ${talhao?.nome ?? 'Nenhum'}');
    notifyListeners();
  }
  
  /// Seleciona uma cultura
  void selectCultura(CulturaModel? cultura) {
    _state.setSelectedCultura(cultura);
    Logger.info('🌱 Cultura selecionada: ${cultura?.nome ?? 'Nenhuma'}');
    notifyListeners();
  }
  
  /// Inicia novo monitoramento
  void startNewMonitoring() {
    if (selectedTalhao == null) {
      Logger.warning('⚠️ Nenhum talhão selecionado para monitoramento');
      return;
    }
    
    Logger.info('🚀 Iniciando novo monitoramento para talhão: ${selectedTalhao!.nome}');
    // TODO: Navegar para tela de monitoramento
  }
  
  /// Vai para localização atual
  void goToCurrentLocation() {
    if (currentPosition != null) {
      Logger.info('📍 Indo para localização atual');
      // TODO: Centralizar mapa na posição atual
    } else {
      Logger.warning('⚠️ Localização atual não disponível');
    }
  }
  
  /// Abre histórico
  void openHistory() {
    Logger.info('📚 Abrindo histórico de monitoramento V2');
    // Navegar para a nova tela de histórico V2
    Navigator.pushNamed(
      TalhaoNotificationService.navigatorKey.currentContext!,
      '/monitoring/history-v2',
    );
  }
  
  /// Abre configurações
  void openSettings() {
    Logger.info('⚙️ Abrindo configurações');
    // TODO: Navegar para tela de configurações
  }
  
  /// Limpa dados
  void clearData() {
    Logger.info('🗑️ Limpando dados de monitoramento');
    // TODO: Implementar limpeza de dados
  }
  
  /// Filtra talhões por cultura
  List<TalhaoModel> getFilteredTalhoes() {
    if (selectedCultura == null) return availableTalhoes;
    
    return availableTalhoes.where((talhao) {
      return talhao.culturaId == selectedCultura!.id;
    }).toList();
  }
  
  /// Verifica se há dados disponíveis
  bool get hasData => availableTalhoes.isNotEmpty && availableCulturas.isNotEmpty;
  
  /// Verifica se há erro
  bool get hasError => errorMessage != null;
  
  /// Limpa erro
  void clearError() {
    _state.setError(null);
    notifyListeners();
  }
}
