import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/safra_model.dart';

/// Repositório para gerenciar as safras no armazenamento local
class SafraRepository {
  static const String _keySafras = 'safras';
  
  /// Salva uma safra no armazenamento local
  Future<bool> salvar(SafraModel safra) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<SafraModel> safras = await listarTodos();
      
      // Verificar se a safra já existe para atualizar
      final index = safras.indexWhere((s) => s.id == safra.id);
      if (index >= 0) {
        safras[index] = safra;
      } else {
        safras.add(safra);
      }
      
      // Salvar a lista atualizada
      final safrasJson = safras.map((s) => jsonEncode(s.toMap())).toList();
      await prefs.setStringList(_keySafras, safrasJson);
      
      return true;
    } catch (e) {
      print('Erro ao salvar safra: $e');
      return false;
    }
  }
  
  /// Exclui uma safra do armazenamento local
  Future<bool> excluir(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<SafraModel> safras = await listarTodos();
      
      // Remover a safra da lista
      safras.removeWhere((s) => s.id == id);
      
      // Salvar a lista atualizada
      final safrasJson = safras.map((s) => jsonEncode(s.toMap())).toList();
      await prefs.setStringList(_keySafras, safrasJson);
      
      return true;
    } catch (e) {
      print('Erro ao excluir safra: $e');
      return false;
    }
  }
  
  /// Retorna todas as safras armazenadas
  Future<List<SafraModel>> listarTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final safrasJson = prefs.getStringList(_keySafras) ?? [];
      
      return safrasJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return SafraModel.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erro ao listar safras: $e');
      return [];
    }
  }
  
  /// Retorna uma safra pelo ID
  Future<SafraModel?> buscarPorId(String id) async {
    try {
      final safras = await listarTodos();
      return safras.firstWhere((s) => s.id == id);
    } catch (e) {
      print('Erro ao buscar safra por ID: $e');
      return null;
    }
  }
  
  /// Retorna todas as safras de um talhão específico
  Future<List<SafraModel>> buscarPorTalhao(String talhaoId) async {
    try {
      final safras = await listarTodos();
      return safras.where((s) => s.talhaoId == talhaoId).toList();
    } catch (e) {
      print('Erro ao buscar safras por talhão: $e');
      return [];
    }
  }
  
  /// Retorna a safra mais recente de um talhão específico
  Future<SafraModel?> buscarSafraAtual(String talhaoId) async {
    try {
      final safras = await buscarPorTalhao(talhaoId);
      if (safras.isEmpty) return null;
      
      // Ordenar por data de criação (mais recente primeiro)
      safras.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      return safras.first;
    } catch (e) {
      print('Erro ao buscar safra atual: $e');
      return null;
    }
  }
  
  /// Exclui todas as safras de um talhão específico
  Future<bool> excluirPorTalhao(String talhaoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<SafraModel> safras = await listarTodos();
      
      // Remover todas as safras do talhão
      safras.removeWhere((s) => s.talhaoId == talhaoId);
      
      // Salvar a lista atualizada
      final safrasJson = safras.map((s) => jsonEncode(s.toMap())).toList();
      await prefs.setStringList(_keySafras, safrasJson);
      
      return true;
    } catch (e) {
      print('Erro ao excluir safras por talhão: $e');
      return false;
    }
  }
}
