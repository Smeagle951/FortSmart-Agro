import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../repositories/farm_repository.dart';
import '../utils/logger.dart';

/// Provider para gerenciar dados da fazenda em tempo real
class FarmProvider extends ChangeNotifier {
  final FarmRepository _farmRepository = FarmRepository();
  
  // Estado
  Farm? _selectedFarm;
  List<Farm> _farms = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  Farm? get selectedFarm => _selectedFarm;
  List<Farm> get farms => List.unmodifiable(_farms);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasFarm => _selectedFarm != null;
  
  /// Carrega todas as fazendas do banco de dados
  Future<void> loadFarms() async {
    try {
      _setLoading(true);
      _clearError();
      
      Logger.info('🔄 Carregando fazendas...');
      
      final farms = await _farmRepository.getAllFarms();
      
      if (mounted) {
        setState(() {
          _farms = farms;
          // Selecionar a primeira fazenda se não houver nenhuma selecionada
          if (_selectedFarm == null && farms.isNotEmpty) {
            _selectedFarm = farms.first;
          }
        });
        
        Logger.info('✅ ${farms.length} fazendas carregadas');
        notifyListeners();
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar fazendas: $e');
      _setError('Erro ao carregar fazendas: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Carrega uma fazenda específica por ID
  Future<void> loadFarmById(String farmId) async {
    try {
      _setLoading(true);
      _clearError();
      
      Logger.info('🔄 Carregando fazenda ID: $farmId');
      
      final farm = await _farmRepository.getFarmById(farmId);
      
      if (mounted) {
        setState(() {
          _selectedFarm = farm;
        });
        
        if (farm != null) {
          Logger.info('✅ Fazenda carregada: ${farm.name}');
        } else {
          Logger.warning('⚠️ Fazenda não encontrada: $farmId');
        }
        
        notifyListeners();
      }
    } catch (e) {
      Logger.error('❌ Erro ao carregar fazenda: $e');
      _setError('Erro ao carregar fazenda: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Seleciona uma fazenda
  void selectFarm(Farm farm) {
    if (mounted) {
      setState(() {
        _selectedFarm = farm;
      });
      Logger.info('✅ Fazenda selecionada: ${farm.name}');
      notifyListeners();
    }
  }
  
  /// Adiciona uma nova fazenda
  Future<bool> addFarm(Farm farm) async {
    try {
      _setLoading(true);
      _clearError();
      
      Logger.info('🔄 Adicionando fazenda: ${farm.name}');
      
      final farmId = await _farmRepository.addFarm(farm);
      
      if (farmId.isNotEmpty) {
        // Recarregar a lista de fazendas
        await loadFarms();
        
        Logger.info('✅ Fazenda adicionada com sucesso: $farmId');
        return true;
      } else {
        _setError('Erro ao adicionar fazenda');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erro ao adicionar fazenda: $e');
      _setError('Erro ao adicionar fazenda: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Atualiza uma fazenda existente
  Future<bool> updateFarm(Farm farm) async {
    try {
      _setLoading(true);
      _clearError();
      
      Logger.info('🔄 Atualizando fazenda: ${farm.name}');
      
      final success = await _farmRepository.updateFarm(farm);
      
      if (success) {
        // Atualizar a fazenda selecionada se for a mesma
        if (_selectedFarm?.id == farm.id) {
          setState(() {
            _selectedFarm = farm;
          });
        }
        
        // Recarregar a lista de fazendas
        await loadFarms();
        
        Logger.info('✅ Fazenda atualizada com sucesso');
        return true;
      } else {
        _setError('Erro ao atualizar fazenda');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erro ao atualizar fazenda: $e');
      _setError('Erro ao atualizar fazenda: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Remove uma fazenda
  Future<bool> removeFarm(String farmId) async {
    try {
      _setLoading(true);
      _clearError();
      
      Logger.info('🔄 Removendo fazenda ID: $farmId');
      
      final success = await _farmRepository.removeFarm(farmId);
      
      if (success) {
        // Se a fazenda removida era a selecionada, limpar seleção
        if (_selectedFarm?.id == farmId) {
          setState(() {
            _selectedFarm = null;
          });
        }
        
        // Recarregar a lista de fazendas
        await loadFarms();
        
        Logger.info('✅ Fazenda removida com sucesso');
        return true;
      } else {
        _setError('Erro ao remover fazenda');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Erro ao remover fazenda: $e');
      _setError('Erro ao remover fazenda: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Atualiza estatísticas da fazenda em tempo real
  Future<void> refreshFarmStats() async {
    if (_selectedFarm == null) return;
    
    try {
      Logger.info('🔄 Atualizando estatísticas da fazenda...');
      
      // Aqui você pode adicionar lógica para buscar estatísticas atualizadas
      // Por exemplo, número de talhões, área total, etc.
      
      // Por enquanto, vamos apenas notificar que os dados foram atualizados
      notifyListeners();
      
      Logger.info('✅ Estatísticas da fazenda atualizadas');
    } catch (e) {
      Logger.error('❌ Erro ao atualizar estatísticas: $e');
    }
  }
  
  /// Força uma atualização completa dos dados
  Future<void> refresh() async {
    await loadFarms();
  }
  
  /// Limpa todos os dados
  void clear() {
    if (mounted) {
      setState(() {
        _selectedFarm = null;
        _farms = [];
        _errorMessage = null;
      });
      notifyListeners();
    }
  }
  
  // Métodos auxiliares
  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
      });
    }
  }
  
  void _setError(String error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
      });
    }
  }
  
  void _clearError() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }
  
  void setState(VoidCallback fn) {
    fn();
  }
  
  bool get mounted => true; // Simplificado para este provider
}
