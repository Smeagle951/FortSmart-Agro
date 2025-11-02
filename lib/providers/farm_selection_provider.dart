import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';

/// Provider para gerenciar a seleção de fazenda globalmente
/// Permite que todos os módulos tenham acesso à fazenda selecionada
class FarmSelectionProvider with ChangeNotifier {
  final FarmService _farmService = FarmService();
  
  Farm? _selectedFarm;
  List<Farm> _allFarms = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Farm? get selectedFarm => _selectedFarm;
  List<Farm> get allFarms => _allFarms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMultipleFarms => _allFarms.length > 1;
  String? get selectedFarmId => _selectedFarm?.id;

  /// Carrega todas as fazendas disponíveis
  Future<void> loadFarms() async {
    _setLoading(true);
    _clearError();

    try {
      print('🔄 Carregando fazendas...');
      _allFarms = await _farmService.getAllFarms();
      print('✅ ${_allFarms.length} fazendas carregadas');

      // Se não há fazenda selecionada e existe pelo menos uma, selecionar a primeira
      if (_selectedFarm == null && _allFarms.isNotEmpty) {
        _selectedFarm = _allFarms.first;
        print('📍 Fazenda padrão selecionada: ${_selectedFarm!.name}');
      }

      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar fazendas: $e');
      print('❌ Erro ao carregar fazendas: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Seleciona uma fazenda específica
  void selectFarm(String? farmId) {
    if (farmId == null) {
      _selectedFarm = null;
      print('📍 Fazenda desmarcada (todas as fazendas)');
    } else {
      _selectedFarm = _allFarms.firstWhere(
        (farm) => farm.id == farmId,
        orElse: () => _allFarms.first,
      );
      print('📍 Fazenda selecionada: ${_selectedFarm!.name}');
    }
    notifyListeners();
  }

  /// Seleciona uma fazenda por objeto
  void selectFarmObject(Farm? farm) {
    _selectedFarm = farm;
    if (farm != null) {
      print('📍 Fazenda selecionada: ${farm.name}');
    } else {
      print('📍 Fazenda desmarcada (todas as fazendas)');
    }
    notifyListeners();
  }

  /// Obtém talhões da fazenda selecionada
  Future<List<dynamic>> getTalhoesDaFazendaSelecionada() async {
    if (_selectedFarm == null) {
      print('⚠️ Nenhuma fazenda selecionada, retornando lista vazia');
      return [];
    }

    try {
      // Aqui você pode integrar com o TalhaoRepository para buscar talhões por fazenda
      // Por enquanto, retornamos uma lista vazia
      print('🔄 Buscando talhões da fazenda: ${_selectedFarm!.name}');
      return [];
    } catch (e) {
      print('❌ Erro ao buscar talhões: $e');
      return [];
    }
  }

  /// Obtém estatísticas da fazenda selecionada
  Map<String, dynamic> getEstatisticasFazenda() {
    if (_selectedFarm == null) {
      return {
        'totalFazendas': _allFarms.length,
        'fazendaSelecionada': 'Todas as Fazendas',
        'totalTalhoes': 0,
        'areaTotal': 0.0,
        'culturas': <String, int>{},
      };
    }

    return {
      'totalFazendas': _allFarms.length,
      'fazendaSelecionada': _selectedFarm!.name,
      'totalTalhoes': _selectedFarm!.plotsCount,
      'areaTotal': _selectedFarm!.totalArea,
      'culturas': _selectedFarm!.crops,
      'isActive': _selectedFarm!.isActive,
      'address': _selectedFarm!.address,
    };
  }

  /// Filtra fazendas por nome
  List<Farm> filtrarFazendasPorNome(String nome) {
    if (nome.isEmpty) return _allFarms;
    
    return _allFarms.where((farm) => 
      farm.name.toLowerCase().contains(nome.toLowerCase())
    ).toList();
  }

  /// Obtém fazenda por ID
  Farm? getFazendaPorId(String id) {
    try {
      return _allFarms.firstWhere((farm) => farm.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Recarrega as fazendas
  Future<void> refreshFarms() async {
    await loadFarms();
  }

  /// Limpa a seleção (volta para "todas as fazendas")
  void clearSelection() {
    selectFarm(null);
  }

  /// Verifica se uma fazenda está selecionada
  bool isFarmSelected(String farmId) {
    return _selectedFarm?.id == farmId;
  }

  /// Obtém o nome da fazenda selecionada para exibição
  String getDisplayName() {
    if (_selectedFarm == null) {
      return 'Todas as Fazendas';
    }
    return '${_selectedFarm!.name} (${_selectedFarm!.totalArea.toStringAsFixed(1)} ha)';
  }

  /// Obtém informações resumidas da fazenda selecionada
  String getSummaryInfo() {
    if (_selectedFarm == null) {
      return '${_allFarms.length} fazendas • Área total: ${_allFarms.fold(0.0, (sum, farm) => sum + farm.totalArea).toStringAsFixed(1)} ha';
    }
    return '${_selectedFarm!.plotsCount} talhões • ${_selectedFarm!.totalArea.toStringAsFixed(1)} ha • ${_selectedFarm!.crops.length} culturas';
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
