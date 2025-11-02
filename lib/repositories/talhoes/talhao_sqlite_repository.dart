import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/talhao_model.dart';
import '../../models/safra_model.dart';
import '../../database/talhao_database.dart';
import '../talhao_repository_v2.dart';
import '../../utils/color_converter.dart';

/// Repositório para gerenciar talhões com persistência SQLite
class TalhaoSQLiteRepository extends ChangeNotifier {
  final TalhaoDatabase _database = TalhaoDatabase();
  final TalhaoRepositoryV2 _legacyRepository = TalhaoRepositoryV2();
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
  
  /// Salva um talhão no banco de dados SQLite
  Future<bool> salvar(TalhaoModel talhao) async {
    try {
      _setLoading(true);
      
      // Salvar no banco SQLite
      final result = await _database.salvarTalhao(talhao);
      
      if (result) {
        // Atualizar a lista em memória
        await _carregarTalhoes();
      }
      
      return result;
    } catch (e) {
      debugPrint('Erro ao salvar talhão: $e');
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
      
      return await _carregarTalhoes();
    } catch (e) {
      debugPrint('Erro ao listar talhões: $e');
      return [];
    }
  }
  
  /// Carrega os talhões do banco de dados
  Future<List<TalhaoModel>> _carregarTalhoes() async {
    try {
      _setLoading(true);
      
      // Tentar carregar do banco SQLite
      _talhoes = await _database.listarTodos();
      
      // Se não encontrou nenhum talhão, tentar importar do repositório legado
      if (_talhoes.isEmpty) {
        await _importarDoRepositorioLegado();
        _talhoes = await _database.listarTodos();
      }
      
      notifyListeners();
      return _talhoes;
    } catch (e) {
      debugPrint('Erro ao carregar talhões: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Importa talhões do repositório legado (SharedPreferences)
  Future<bool> _importarDoRepositorioLegado() async {
    try {
      _setLoading(true);
      
      // Carregar talhões do repositório legado
      final talhoesLegados = await _legacyRepository.listarTodos();
      
      if (talhoesLegados.isEmpty) {
        return false;
      }
      
      // Salvar cada talhão no banco SQLite
      for (final talhao in talhoesLegados) {
        await _database.salvarTalhao(talhao);
      }
      
      return true;
    } catch (e) {
      debugPrint('Erro ao importar talhões do repositório legado: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Busca um talhão pelo ID
  Future<TalhaoModel?> buscarPorId(int id) async {
    try {
      return await _database.buscarPorId(id);
    } catch (e) {
      debugPrint('Erro ao buscar talhão por ID: $e');
      return null;
    }
  }
  
  /// Exclui um talhão pelo ID
  Future<bool> excluir(int id) async {
    try {
      _setLoading(true);
      
      final result = await _database.excluir(id);
      
      if (result) {
        // Atualizar a lista em memória
        _talhoes.removeWhere((t) => t.id.toString() == id.toString());
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      debugPrint('Erro ao excluir talhão: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Adiciona uma nova safra a um talhão existente
  Future<bool> adicionarSafra({
    required int talhaoId,
    required String safra,
    required String culturaId,
    required String culturaNome,
    required Color culturaCor,
  }) async {
    try {
      // Buscar o talhão
      final talhao = await buscarPorId(talhaoId);
      
      if (talhao == null) {
        return false;
      }
      
      // Criar objeto SafraModel
      // Converter Color para String hexadecimal usando o ColorConverter
      final corHex = ColorConverter.colorToHex(culturaCor);
      
      final novaSafra = SafraModel.criar(
        talhaoId: talhao.id,
        safra: safra,
        culturaId: culturaId,
        culturaNome: culturaNome,
        culturaCor: corHex,
      );
      
      // Adicionar a safra
      final talhaoAtualizado = talhao.adicionarSafra(novaSafra);
      
      // Salvar o talhão atualizado
      return await salvar(talhaoAtualizado);
    } catch (e) {
      debugPrint('Erro ao adicionar safra: $e');
      return false;
    }
  }
  
  /// Retorna o histórico de safras de um talhão
  Future<List<SafraModel>> obterHistoricoSafras(int talhaoId) async {
    try {
      final talhao = await buscarPorId(talhaoId);
      
      if (talhao == null) {
        return [];
      }
      
      return talhao.safras;
    } catch (e) {
      debugPrint('Erro ao obter histórico de safras: $e');
      return [];
    }
  }
  
  /// Lista talhões por safra
  Future<List<TalhaoModel>> listarPorSafra(String safraIdOuPeriodo) async {
    try {
      final talhoes = await listarTodos();
      
      if (safraIdOuPeriodo.isEmpty) {
        return talhoes;
      }
      
      // Se for uma string que parece ser um UUID
      if (safraIdOuPeriodo.contains('-') && safraIdOuPeriodo.length > 30) {
        return talhoes.where((talhao) => 
          talhao.safras.any((safra) => safra.id == safraIdOuPeriodo)
        ).toList();
      }
      
      // Se for um período de safra (ex: "2023/2024")
      return talhoes.where((talhao) => 
        (talhao.safraAtual?.safra == safraIdOuPeriodo) || 
        (talhao.safras.any((s) => s.safra == safraIdOuPeriodo))
      ).toList();
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
  
  /// Calcula a área total por cultura
/// 
/// Retorna um mapa onde a chave é o ID ou nome da cultura e o valor é a área total.
/// O mapa contém tanto entradas com IDs de cultura quanto com nomes de cultura
/// para garantir compatibilidade com diferentes partes do sistema.
/// 
/// [safraFiltro] - Filtro opcional para considerar apenas talhões de uma safra específica
Future<Map<String, double>> calcularAreaPorCultura({String? safraFiltro}) async {
  try {
    debugPrint('Iniciando cálculo de área por cultura...');
    
    // Buscar talhões com filtro de safra, se especificado
    final List<TalhaoModel> talhoes;
    if (safraFiltro != null && safraFiltro.isNotEmpty) {
      talhoes = await listarPorSafra(safraFiltro);
      debugPrint('Filtrando talhões por safra: $safraFiltro');
    } else {
      talhoes = await listarTodos();
    }
    debugPrint('Total de talhões para cálculo de área: ${talhoes.length}');
      
      // Mapas para armazenar áreas por ID e por nome da cultura
      final Map<String, double> areaPorCulturaId = {};
      final Map<String, double> areaPorCulturaNome = {};
      
      // Contador de talhões sem safra para log
      int talhoesSemSafra = 0;
      
      // Processar cada talhão
      for (final talhao in talhoes) {
        // Pular talhões sem safras
        if (talhao.safras.isEmpty) {
          talhoesSemSafra++;
          continue;
        }
        
        // Ordenar safras para pegar a mais recente
        final safrasOrdenadas = List<SafraModel>.from(talhao.safras)
          ..sort((a, b) => b.safra.compareTo(a.safra));
        final safraAtual = safrasOrdenadas.first;
        
        // Extrair informações da cultura
        final String culturaId = safraAtual.culturaId;
        final String culturaNome = safraAtual.culturaNome;
        
        // Somar área ao total por ID e por nome
        areaPorCulturaId[culturaId] = (areaPorCulturaId[culturaId] ?? 0) + talhao.area;
        areaPorCulturaNome[culturaNome] = (areaPorCulturaNome[culturaNome] ?? 0) + talhao.area;
        
        debugPrint('Talhão ${talhao.id}: área ${talhao.area.toStringAsFixed(2)} ha, cultura: $culturaNome (ID: $culturaId)');
      }
      
      // Combinar os dois mapas em um único resultado
      final Map<String, double> resultado = {};
      resultado.addAll(areaPorCulturaId);
      resultado.addAll(areaPorCulturaNome);
      
      // Log de resultados
      debugPrint('Cálculo de área concluído: ${resultado.length} culturas encontradas');
      debugPrint('Talhões sem safra: $talhoesSemSafra');
      resultado.forEach((cultura, area) {
        debugPrint('Cultura $cultura: ${area.toStringAsFixed(2)} hectares');
      });
      
      return resultado;
    } catch (e) {
      debugPrint('Erro ao calcular área por cultura: $e');
      return {};
    }
  }
  
  /// Cria um novo talhão
  Future<TalhaoModel?> criarTalhao({
    required String nome,
    required List<LatLng> pontos,
    double? area,
    int? culturaId,
    int? safraId,
    String? fazendaId,
    String? observacoes,
    Map<String, dynamic>? metadados,
  }) async {
    try {
      // Calcular a área se não foi informada
      final areaCalculada = area ?? _calcularArea(pontos);
      
      // Criar o talhão - o método criar() vai converter os pontos em polígonos internamente
      final talhao = TalhaoModel.criar(
        nome: nome,
        pontos: pontos,
        area: areaCalculada,
        culturaId: culturaId,
        safraId: safraId,
        fazendaId: fazendaId,
        observacoes: observacoes,
        metadados: metadados,
      );
      
      // Salvar o talhão
      final result = await salvar(talhao);
      
      if (result) {
        return talhao;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao criar talhão: $e');
      return null;
    }
  }
  
  /// Calcula a área de um polígono em hectares
  double _calcularArea(List<LatLng> pontos) {
    if (pontos.length < 3) {
      return 0.0;
    }
    
    // Implementação do algoritmo de cálculo de área (Fórmula de Gauss)
    double area = 0.0;
    for (int i = 0; i < pontos.length; i++) {
      int j = (i + 1) % pontos.length;
      area += pontos[i].longitude * pontos[j].latitude;
      area -= pontos[j].longitude * pontos[i].latitude;
    }
    
    area = (area.abs() / 2.0) * 11100000; // Converter para hectares usando fator de conversão correto
    return area;
  }
  
  /// Limpa o cache de talhões em memória
  void limparCache() {
    _talhoes = [];
    notifyListeners();
  }
  
  /// Lista todas as safras disponíveis
  /// 
  /// Retorna uma lista de todas as safras cadastradas em todos os talhões,
  /// sem duplicatas e ordenadas por período (mais recente primeiro)
  Future<List<SafraModel>> listarSafras() async {
    try {
      debugPrint('Iniciando listagem de safras...');
      
      // Buscar todos os talhões
      final talhoes = await listarTodos();
      debugPrint('Total de talhões encontrados: ${talhoes.length}');
      
      // Extrair todas as safras de todos os talhões
      final Set<String> safrasIds = {};
      final List<SafraModel> todasSafras = [];
      int totalSafrasComDuplicatas = 0;
      
      for (final talhao in talhoes) {
        totalSafrasComDuplicatas += talhao.safras.length;
        for (final safra in talhao.safras) {
          // Evitar duplicatas usando o ID da safra
          if (!safrasIds.contains(safra.id)) {
            safrasIds.add(safra.id);
            todasSafras.add(safra);
          }
        }
      }
      
      // Ordenar por período de safra (mais recente primeiro)
      todasSafras.sort((a, b) {
        // Primeiro tentar comparar por período de safra
        final compareSafra = b.safra.compareTo(a.safra);
        if (compareSafra != 0) return compareSafra;
        
        // Se o período for igual, ordenar por cultura
        return a.culturaNome.compareTo(b.culturaNome);
      });
      
      debugPrint('Total de safras encontradas: ${todasSafras.length} (de $totalSafrasComDuplicatas com duplicatas)');
      for (int i = 0; i < todasSafras.length && i < 5; i++) {
        debugPrint('Safra ${i+1}: ${todasSafras[i].safra} - ${todasSafras[i].culturaNome}');
      }
      
      return todasSafras;
    } catch (e) {
      debugPrint('Erro ao listar safras: $e');
      return [];
    }
  }
  
  /// Marca um talhão como sincronizado
  /// 
  /// Recebe o ID do talhão (pode ser String ou int) e atualiza seu status para sincronizado
  /// Retorna true se a operação foi bem-sucedida, false caso contrário
  Future<bool> marcarComoSincronizado(dynamic id) async {
    try {
      // Converter o ID para int se for uma string
      final int talhaoId = id is String ? int.parse(id) : id;
      
      debugPrint('Marcando talhão como sincronizado: $talhaoId');
      
      // Usar o método da classe TalhaoDatabase para marcar como sincronizado
      final result = await _database.marcarComoSincronizado(talhaoId);
      
      if (result) {
        // Atualizar o objeto em memória se existir
        final index = _talhoes.indexWhere((t) => t.id.toString() == talhaoId.toString());
        if (index >= 0) {
          _talhoes[index].sincronizado = true;
          notifyListeners();
        }
        
        debugPrint('Talhão marcado como sincronizado com sucesso: $talhaoId');
      } else {
        debugPrint('Falha ao marcar talhão como sincronizado: $talhaoId');
      }
      
      return result;
    } catch (e) {
      debugPrint('Erro ao marcar talhão como sincronizado: $e');
      return false;
    }
  }
}
