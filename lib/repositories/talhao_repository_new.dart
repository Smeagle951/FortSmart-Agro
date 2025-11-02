import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/talhao_model_new.dart';
import '../models/safra_model.dart';
import 'safra_repository.dart';

/// Repositório para gerenciar os talhões no armazenamento local
class TalhaoRepository {
  static const String _keyTalhoes = 'talhoes';
  final SafraRepository _safraRepository = SafraRepository();
  
  /// Salva um talhão no armazenamento local
  Future<bool> salvar(TalhaoModel talhao) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<TalhaoModel> talhoes = await listarTodos();
      
      // Verificar se o talhão já existe para atualizar
      final index = talhoes.indexWhere((t) => t.id == talhao.id);
      if (index >= 0) {
        talhoes[index] = talhao;
      } else {
        talhoes.add(talhao);
      }
      
      // Salvar a lista atualizada
      final talhoesJson = talhoes.map((t) => jsonEncode(t.toMap())).toList();
      await prefs.setStringList(_keyTalhoes, talhoesJson);
      
      // Salvar as safras associadas ao talhão
      for (final safra in talhao.safras) {
        await _safraRepository.salvar(safra);
      }
      
      return true;
    } catch (e) {
      print('Erro ao salvar talhão: $e');
      return false;
    }
  }
  
  /// Exclui um talhão do armazenamento local
  Future<bool> excluir(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<TalhaoModel> talhoes = await listarTodos();
      
      // Remover o talhão da lista
      talhoes.removeWhere((t) => t.id == id);
      
      // Salvar a lista atualizada
      final talhoesJson = talhoes.map((t) => jsonEncode(t.toMap())).toList();
      await prefs.setStringList(_keyTalhoes, talhoesJson);
      
      // Excluir todas as safras associadas ao talhão
      await _safraRepository.excluirPorTalhao(id);
      
      return true;
    } catch (e) {
      print('Erro ao excluir talhão: $e');
      return false;
    }
  }
  
  /// Lista todos os talhões cadastrados
  Future<List<TalhaoModel>> listarTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? talhoesJson = prefs.getStringList(_keyTalhoes);
      
      if (talhoesJson == null || talhoesJson.isEmpty) {
        return [];
      }
      
      return talhoesJson.map((json) {
        final Map<String, dynamic> map = jsonDecode(json);
        return TalhaoModel.fromMap(map);
      }).toList();
    } catch (e) {
      print('Erro ao listar talhões: $e');
      return [];
    }
  }
  
  // Método removido para evitar duplicação
  
  /// Retorna um talhão pelo ID
  Future<TalhaoModel?> buscarPorId(String id) async {
    try {
      final talhoes = await listarTodos();
      return talhoes.firstWhere((t) => t.id == id);
    } catch (e) {
      print('Erro ao buscar talhão por ID: $e');
      return null;
    }
  }
  
  /// Alias para buscarPorId - mantém compatibilidade com outros módulos
  Future<TalhaoModel?> obterPorId(String id) async {
    return buscarPorId(id);
  }
  
  /// Adiciona uma nova safra a um talhão existente
  Future<bool> adicionarSafra({
    required String talhaoId,
    required String safra,
    required String culturaId,
    required String culturaNome,
    required Color culturaCor,
  }) async {
    try {
      // Buscar o talhão
      final talhao = await buscarPorId(talhaoId);
      if (talhao == null) return false;
      
      // Adicionar a nova safra
      final talhaoAtualizado = talhao.adicionarSafraNomeada(
        safra: safra,
        culturaId: culturaId,
        culturaNome: culturaNome,
        culturaCor: culturaCor,
      );
      
      // Salvar o talhão atualizado
      return await salvar(talhaoAtualizado);
    } catch (e) {
      print('Erro ao adicionar safra: $e');
      return false;
    }
  }
  
  /// Retorna todos os talhões filtrados por safra
  Future<List<TalhaoModel>> filtrarPorSafra(String safra) async {
    try {
      final talhoes = await listarTodos();
      return talhoes.where((t) => 
        t.safras.any((s) => s.safra == safra)
      ).toList();
    } catch (e) {
      print('Erro ao filtrar talhões por safra: $e');
      return [];
    }
  }
  
  /// Retorna todos os talhões filtrados por cultura
  Future<List<TalhaoModel>> filtrarPorCultura(String culturaId) async {
    try {
      final talhoes = await listarTodos();
      return talhoes.where((t) => 
        t.safraAtual?.culturaId == culturaId
      ).toList();
    } catch (e) {
      print('Erro ao filtrar talhões por cultura: $e');
      return [];
    }
  }
  
  /// Retorna o histórico de safras de um talhão
  Future<List<SafraModel>> obterHistoricoSafras(String talhaoId) async {
    try {
      final safras = await _safraRepository.buscarPorTalhao(talhaoId);
      
      // Ordenar por data de criação (mais recente primeiro)
      safras.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      
      return safras;
    } catch (e) {
      print('Erro ao obter histórico de safras: $e');
      return [];
    }
  }
  
  /// Lista talhões por safra
  /// 
  /// @param safraIdOuPeriodo - Pode ser o ID da safra, o ID da safra como inteiro ou o período (ex: "2023/2024")
  Future<List<TalhaoModel>> listarPorSafra(dynamic safraIdOuPeriodo) async {
    try {
      if (safraIdOuPeriodo == null) {
        return await listarTodos();
      }
      
      final talhoes = await listarTodos();
      
      if (safraIdOuPeriodo.toString().isEmpty) {
        return talhoes;
      }
      
      // Se for um número (ID de safra como inteiro)
      if (safraIdOuPeriodo is int || (safraIdOuPeriodo is String && int.tryParse(safraIdOuPeriodo) != null)) {
        final int safraId = safraIdOuPeriodo is int ? safraIdOuPeriodo : int.parse(safraIdOuPeriodo);
        return talhoes.where((talhao) => talhao.safraId == safraId).toList();
      }
      
      // Se for uma string que parece ser um UUID
      if (safraIdOuPeriodo is String && safraIdOuPeriodo.contains('-') && safraIdOuPeriodo.length > 30) {
        return talhoes.where((talhao) => 
          talhao.safras.any((safra) => safra.id == safraIdOuPeriodo)
        ).toList();
      }
      
      // Se for um período de safra (ex: "2023/2024")
      if (safraIdOuPeriodo is String) {
        return talhoes.where((talhao) => 
          (talhao.safraAtual?.safra == safraIdOuPeriodo) || 
          (talhao.safras.any((s) => s.safra == safraIdOuPeriodo))
        ).toList();
      }
      
      // Se não for nenhum dos casos acima, retorna vazio
      return [];
    } catch (e) {
      print('Erro ao listar talhões por safra: $e');
      return [];
    }
  }

  /// Retorna a área total de todos os talhões
  Future<double> calcularAreaTotal() async {
    try {
      final talhoes = await listarTodos();
      return talhoes.fold<double>(0.0, (total, talhao) => total + (talhao.area as double? ?? 0.0));
    } catch (e) {
      print('Erro ao calcular área total: $e');
      return 0;
    }
  }
  
  /// Retorna a área total de uma safra específica
  Future<double> calcularAreaTotalPorSafra(String safraId) async {
    final talhoes = await listarPorSafra(safraId);
    return talhoes.fold<double>(0.0, (total, talhao) => total + (talhao.area as double? ?? 0.0));
  }
  
  /// Retorna a área total por cultura na safra atual
  Future<Map<String, double>> calcularAreaPorCultura() async {
    try {
      final talhoes = await listarTodos();
      final Map<String, double> areaPorCultura = {};
      
      for (final talhao in talhoes) {
        if (talhao.safraAtual != null) {
          final cultura = talhao.safraAtual!.culturaNome;
          areaPorCultura[cultura] = (areaPorCultura[cultura] ?? 0) + talhao.area;
        }
      }
      
      return areaPorCultura;
    } catch (e) {
      print('Erro ao calcular área por cultura: $e');
      return {};
    }
  }
}
