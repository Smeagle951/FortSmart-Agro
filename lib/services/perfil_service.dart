import 'package:shared_preferences/shared_preferences.dart';
import '../models/farm.dart';
import '../repositories/farm_repository.dart';

/// Serviço para gerenciar o perfil da fazenda ativa
class PerfilService {
  static final PerfilService _instance = PerfilService._internal();
  factory PerfilService() => _instance;
  PerfilService._internal();

  final FarmRepository _farmRepository = FarmRepository();
  static const String _activeFarmIdKey = 'active_farm_id';

  /// Obtém a fazenda ativa
  Future<Farm?> getFazendaAtual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeFarmId = prefs.getString(_activeFarmIdKey);
      
      if (activeFarmId != null) {
        return await _farmRepository.getFarmById(activeFarmId);
      }
      
      // Se não há fazenda ativa, retorna a primeira fazenda disponível
      final farms = await _farmRepository.getAllFarms();
      final activeFarms = farms.where((farm) => farm.isActive).toList();
      
      if (activeFarms.isNotEmpty) {
        final firstFarm = activeFarms.first;
        await setFazendaAtiva(firstFarm);
        return firstFarm;
      }
      
      return null;
    } catch (e) {
      print('Erro ao obter fazenda ativa: $e');
      return null;
    }
  }

  /// Define a fazenda ativa
  Future<void> setFazendaAtiva(Farm farm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeFarmIdKey, farm.id);
    } catch (e) {
      print('Erro ao definir fazenda ativa: $e');
    }
  }

  /// Obtém o ID da fazenda ativa
  Future<String?> getFazendaAtivaId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeFarmIdKey);
    } catch (e) {
      print('Erro ao obter ID da fazenda ativa: $e');
      return null;
    }
  }

  /// Limpa a fazenda ativa
  Future<void> limparFazendaAtiva() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeFarmIdKey);
    } catch (e) {
      print('Erro ao limpar fazenda ativa: $e');
    }
  }
}