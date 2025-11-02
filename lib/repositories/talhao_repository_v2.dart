import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/talhao_model.dart';
import '../models/safra_model.dart';
import '../models/poligono_model.dart';
// Imports removidos para corrigir erros de lint
import 'safra_repository.dart';

/// Repositório para gerenciar os talhões no armazenamento local
/// Versão 2 compatível com o novo modelo TalhaoModel
class TalhaoRepositoryV2 extends ChangeNotifier {
  static const String _keyTalhoes = 'talhoes_v2';
  final SafraRepository _safraRepository = SafraRepository();
  bool _isLoading = false;
  List<TalhaoModel> _talhoes = [];
  
  /// Lista de talhões carregados
  List<TalhaoModel> get talhoes => _talhoes;
  
  /// Indica se está carregando dados
  bool get isLoading => _isLoading;
  
  /// Define o estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Salva um talhão no armazenamento local
  Future<bool> salvar(TalhaoModel talhao) async {
    try {
      _setLoading(true);
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
      final talhoesJson = talhoes.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_keyTalhoes, talhoesJson);
      
      // Salvar as safras associadas ao talhão
      for (final safra in talhao.safras) {
        await _safraRepository.salvar(safra);
      }
      
      // Atualizar a lista em memória
      _talhoes = talhoes;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar talhão: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Exclui um talhão do armazenamento local
  Future<bool> excluir(String id) async {
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      final List<TalhaoModel> talhoes = await listarTodos();
      
      // Remover o talhão da lista
      talhoes.removeWhere((t) => t.id == id);
      
      // Salvar a lista atualizada
      final talhoesJson = talhoes.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_keyTalhoes, talhoesJson);
      
      // Excluir todas as safras associadas ao talhão
      await _safraRepository.excluirPorTalhao(id);
      
      // Atualizar a lista em memória
      _talhoes = talhoes;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir talhão: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Lista todos os talhões cadastrados
  Future<List<TalhaoModel>> listarTodos() async {
    try {
      if (_talhoes.isNotEmpty) {
        return _talhoes;
      }
      
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      final List<String>? talhoesJson = prefs.getStringList(_keyTalhoes);
      
      if (talhoesJson == null || talhoesJson.isEmpty) {
        return [];
      }
      
      _talhoes = talhoesJson.map((json) {
        final Map<String, dynamic> map = jsonDecode(json);
        // Usar o adaptador para criar o TalhaoModel a partir do mapa
        return TalhaoModel.fromMap(map);
      }).toList();
      
      return _talhoes;
    } catch (e) {
      debugPrint('Erro ao listar talhões: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Retorna um talhão pelo ID
  Future<TalhaoModel?> buscarPorId(String id) async {
    try {
      final talhoes = await listarTodos();
      return talhoes.firstWhere((t) => t.id == id);
    } catch (e) {
      debugPrint('Erro ao buscar talhão por ID: $e');
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
      debugPrint('Erro ao adicionar safra: $e');
      return false;
    }
  }
  
  /// Adiciona um novo polígono a um talhão existente
  Future<bool> adicionarPoligono({
    required String talhaoId,
    required List<LatLng> pontos,
  }) async {
    try {
      // Buscar o talhão
      final talhao = await buscarPorId(talhaoId);
      if (talhao == null) return false;
      
      // Adicionar o novo polígono
      final talhaoAtualizado = talhao.adicionarPoligono(pontos as PoligonoModel);
      
      // Salvar o talhão atualizado
      return await salvar(talhaoAtualizado);
    } catch (e) {
      debugPrint('Erro ao adicionar polígono: $e');
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
      debugPrint('Erro ao filtrar talhões por safra: $e');
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
      debugPrint('Erro ao filtrar talhões por cultura: $e');
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
      debugPrint('Erro ao obter histórico de safras: $e');
      return [];
    }
  }
  
  /// Lista talhões por safra
  /// 
  /// @param safraIdOuPeriodo - Pode ser o ID da safra ou o período (ex: "2023/2024")
  Future<List<TalhaoModel>> listarPorSafra(dynamic safraIdOuPeriodo) async {
    try {
      if (safraIdOuPeriodo == null) {
        return await listarTodos();
      }
      
      final talhoes = await listarTodos();
      
      if (safraIdOuPeriodo.toString().isEmpty) {
        return talhoes;
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
      debugPrint('Erro ao listar talhões por safra: $e');
      return [];
    }
  }

  /// Retorna a área total de todos os talhões
  Future<double> calcularAreaTotal() async {
    try {
      final talhoes = await listarTodos();
      return talhoes.fold<double>(0.0, (total, talhao) => total + talhao.area);
    } catch (e) {
      debugPrint('Erro ao calcular área total: $e');
      return 0;
    }
  }
  
  /// Retorna a área total de uma safra específica
  Future<double> calcularAreaTotalPorSafra(String safraId) async {
    final talhoes = await listarPorSafra(safraId);
    return talhoes.fold<double>(0.0, (total, talhao) => total + talhao.area);
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
      debugPrint('Erro ao calcular área por cultura: $e');
      return {};
    }
  }
  
  /// Busca talhões por ID da fazenda
  Future<List<TalhaoModel>> getTalhoesByFarmId(String farmId) async {
    try {
      final talhoes = await listarTodos();
      return talhoes.where((t) => t.fazendaId == farmId).toList();
    } catch (e) {
      debugPrint('Erro ao buscar talhões por fazenda: $e');
      return [];
    }
  }
  
  /// Cria um novo talhão
  Future<TalhaoModel> criarTalhao({
    required String nome,
    required String fazendaId,
    required List<List<LatLng>> poligonos,
    String? observacoes,
    Map<String, dynamic>? metadados,
    String? safra,
    String? culturaId,
    String? culturaNome,
    Color? culturaCor,
  }) async {
    // Converter List<List<LatLng>> para List<PoligonoModel>
    final String talhaoId = const Uuid().v4();
    final List<PoligonoModel> poligonosModel = [];
    
    for (final pontos in poligonos) {
      if (pontos.isNotEmpty) {
        try {
          // Converter os pontos para o tipo correto de LatLng (do pacote latlong2)
          final List<LatLng> convertedPoints = pontos.map((point) => 
            LatLng(point.latitude, point.longitude)).toList();
            
          final poligono = PoligonoModel.criar(
            pontos: convertedPoints,
            talhaoId: talhaoId,
          );
          poligonosModel.add(poligono);
        } catch (e) {
          developer.log('Erro ao converter pontos para polígono: $e');
        }
      }
    }
    
    // Calcular a área total dos polígonos
    double area = 0;
    for (final poligono in poligonosModel) {
      area += poligono.area;
    }
    
    // Criar o talhão
    final talhao = TalhaoModel(
      id: talhaoId,
      name: nome,
      fazendaId: fazendaId,
      poligonos: poligonosModel,
      area: area,
      dataCriacao: DateTime.now(),
      dataAtualizacao: DateTime.now(),
      observacoes: observacoes,
      safras: [],
      sincronizado: false,
    );
    
    // Se informou safra e cultura, adicionar a safra
    if (safra != null && culturaId != null && culturaNome != null && culturaCor != null) {
      final talhaoComSafra = talhao.adicionarSafraPorNome(
        safra: safra,
        culturaId: culturaId,
        culturaNome: culturaNome,
        culturaCor: culturaCor,
      );
      
      // Salvar o talhão com safra
      await salvar(talhaoComSafra);
      return talhaoComSafra;
    }
    
    // Salvar o talhão sem safra
    await salvar(talhao);
    return talhao;
  }
  
  /// Importa talhões do repositório antigo
  Future<List<TalhaoModel>> importarDoRepositorioAntigo() async {
    try {
      _setLoading(true);
      
      // Implementar a importação do repositório antigo
      // Esta é uma implementação de exemplo que deve ser adaptada
      
      return [];
    } catch (e) {
      debugPrint('Erro ao importar talhões do repositório antigo: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Limpa o cache de talhões em memória
  void limparCache() {
    _talhoes = [];
    notifyListeners();
  }
  
  /// Lista todas as safras de todos os talhões
  Future<List<SafraModel>> listarSafras() async {
    try {
      final talhoes = await listarTodos();
      final List<SafraModel> todasSafras = [];
      
      // Coletar todas as safras de todos os talhões
      for (final talhao in talhoes) {
        todasSafras.addAll(talhao.safras);
      }
      
      // Remover duplicatas baseado no ID da safra
      final Map<String, SafraModel> safrasUnicas = {};
      for (final safra in todasSafras) {
        safrasUnicas[safra.id] = safra;
      }
      
      return safrasUnicas.values.toList();
    } catch (e) {
      debugPrint('Erro ao listar safras: $e');
      return [];
    }
  }
  
  /// Lista todas as safras únicas (períodos) disponíveis
  Future<List<String>> listarPeriodosSafra() async {
    try {
      final safras = await listarSafras();
      final Set<String> periodos = {};
      
      for (final safra in safras) {
        if (safra.safra.isNotEmpty) {
          periodos.add(safra.safra);
        }
      }
      
      return periodos.toList();
    } catch (e) {
      debugPrint('Erro ao listar períodos de safra: $e');
      return [];
    }
  }
}
