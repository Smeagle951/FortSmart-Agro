import '../models/safra_model.dart';
import '../repositories/safra_repository.dart';
import '../utils/logger.dart';

/// Serviço para gerenciar as safras e prover funcionalidades para outros módulos
class SafraService {
  final SafraRepository _safraRepository = SafraRepository();

  /// Obtém todas as safras cadastradas
  Future<List<SafraModel>> listarTodas() async {
    try {
      return await _safraRepository.listarTodos();
    } catch (e) {
      Logger.error('SafraService', 'Erro ao listar safras: $e');
      return [];
    }
  }

  /// Obtém safras filtradas por período
  Future<List<SafraModel>> listarPorPeriodo(String periodo) async {
    try {
      final safras = await _safraRepository.listarTodos();
      if (periodo.isEmpty) return safras;
      
      return safras.where((safra) => 
        safra.safra.contains(periodo)
      ).toList();
    } catch (e) {
      Logger.error('SafraService', 'Erro ao filtrar safras por período: $e');
      return [];
    }
  }

  /// Obtém uma safra pelo ID
  Future<SafraModel?> buscarPorId(String id) async {
    try {
      return await _safraRepository.buscarPorId(id);
    } catch (e) {
      Logger.error('SafraService', 'Erro ao buscar safra: $e');
      return null;
    }
  }

  /// Obtém safras associadas a um talhão específico
  Future<List<SafraModel>> buscarPorTalhao(String talhaoId) async {
    try {
      return await _safraRepository.buscarPorTalhao(talhaoId);
    } catch (e) {
      Logger.error('SafraService', 'Erro ao buscar safras por talhão: $e');
      return [];
    }
  }

  /// Salva uma safra
  Future<bool> salvar(SafraModel safra) async {
    try {
      return await _safraRepository.salvar(safra);
    } catch (e) {
      Logger.error('SafraService', 'Erro ao salvar safra: $e');
      return false;
    }
  }

  /// Exclui uma safra
  Future<bool> excluir(String id) async {
    try {
      return await _safraRepository.excluir(id);
    } catch (e) {
      Logger.error('SafraService', 'Erro ao excluir safra: $e');
      return false;
    }
  }

  /// Retorna os períodos de safras disponíveis (ex: "2023/2024")
  Future<List<String>> listarPeriodos() async {
    try {
      final safras = await _safraRepository.listarTodos();
      final periodos = safras.map((s) => s.safra).toSet().toList();
      periodos.sort();
      return periodos;
    } catch (e) {
      Logger.error('SafraService', 'Erro ao listar períodos: $e');
      return [];
    }
  }

  /// Retorna a safra atual ou a mais recente
  Future<SafraModel?> obterSafraAtual() async {
    try {
      final safras = await _safraRepository.listarTodos();
      if (safras.isEmpty) return null;
      
      // Ordenar por data de criação (mais recente primeiro)
      safras.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      return safras.first;
    } catch (e) {
      Logger.error('SafraService', 'Erro ao obter safra atual: $e');
      return null;
    }
  }
}
