import 'dart:convert';
import '../../../models/organism_catalog.dart';
import '../../../services/cultura_service.dart';
import '../../../repositories/organism_catalog_repository.dart';
import '../../../utils/logger.dart';

/// Motor de cálculo avançado de infestação
/// Usa dados do catálogo JSON de organismos para cálculos precisos
class AdvancedInfestationCalculator {
  final OrganismCatalogRepository _catalogRepo = OrganismCatalogRepository();
  final CulturaService _culturaService = CulturaService();

  /// Calcula percentual real de infestação usando dados do catálogo
  Future<Map<String, dynamic>> calculateInfestation({
    required String? organismoId,
    required int quantidadeBruta,
    required int totalPlantasAvaliadas,
    required String culturaId,
    String? tercoPlanta,
  }) async {
    try {
      // Se não tem organismo_id, usa cálculo simples
      if (organismoId == null || organismoId.isEmpty) {
        return _calculoSimples(quantidadeBruta, totalPlantasAvaliadas);
      }

      // Buscar organismo no catálogo JSON
      final organismo = await _buscarOrganismoCatalogo(organismoId, culturaId);
      
      if (organismo == null) {
        return _calculoSimples(quantidadeBruta, totalPlantasAvaliadas);
      }

      // Calcular baseado na unidade do organismo
      final percentualReal = await _calcularPorUnidade(
        organismo: organismo,
        quantidade: quantidadeBruta,
        total: totalPlantasAvaliadas,
        culturaId: culturaId,
        tercoPlanta: tercoPlanta,
      );

      // Determinar nível de severidade usando thresholds do catálogo
      final nivelSeveridade = _determinarNivelComThreshold(
        percentual: percentualReal,
        organismo: organismo,
      );

      // Determinar cor baseada no nível
      final cor = _obterCorNivel(nivelSeveridade);

      return {
        'percentual_real': percentualReal,
        'nivel_severidade': nivelSeveridade,
        'cor': cor,
        'unidade_original': organismo['unit'] ?? 'unidades',
        'metodo_calculo': 'avancado_catalogo',
        'organismo_nome': organismo['name'],
        'threshold_acao': organismo['action_threshold'],
        'threshold_controle': organismo['control_threshold'],
      };

    } catch (e) {
      Logger.error('Erro no cálculo avançado: $e');
      return _calculoSimples(quantidadeBruta, totalPlantasAvaliadas);
    }
  }

  /// Cálculo simples quando não tem dados do catálogo
  Map<String, dynamic> _calculoSimples(int quantidade, int total) {
    if (total <= 0) {
      return {
        'percentual_real': 0.0,
        'nivel_severidade': 'Ausente',
        'cor': '#27AE60',
        'metodo_calculo': 'simples',
      };
    }

    final percentual = (quantidade / total) * 100;
    
    return {
      'percentual_real': percentual,
      'nivel_severidade': _determinarNivelSimples(percentual),
      'cor': _obterCorNivel(_determinarNivelSimples(percentual)),
      'metodo_calculo': 'simples',
    };
  }

  /// Busca organismo no catálogo JSON
  Future<Map<String, dynamic>?> _buscarOrganismoCatalogo(
    String organismoId,
    String culturaId,
  ) async {
    try {
      // Buscar todos os organismos da cultura
      final organisms = await _catalogRepo.getOrganismsByCrop(culturaId);
      
      // Procurar o organismo específico pelo ID
      for (final org in organisms) {
        if (org['id'].toString() == organismoId) {
          return org;
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('Erro ao buscar organismo no catálogo: $e');
      return null;
    }
  }

  /// Calcula percentual baseado na unidade do organismo
  Future<double> _calcularPorUnidade({
    required Map<String, dynamic> organismo,
    required int quantidade,
    required int total,
    required String culturaId,
    String? tercoPlanta,
  }) async {
    final unidade = organismo['unit']?.toString().toLowerCase() ?? '';

    // Se já é percentual, retorna direto
    if (unidade.contains('%') || unidade == 'percentual') {
      return quantidade.toDouble();
    }

    // Insetos/m² ou plantas/m²
    if (unidade.contains('/m²') || unidade.contains('m2')) {
      return await _calcularPorArea(
        quantidade: quantidade,
        total: total,
        culturaId: culturaId,
        organismo: organismo,
      );
    }

    // Insetos/planta
    if (unidade.contains('/planta')) {
      return _calcularPorPlanta(quantidade, total);
    }

    // Folhas atacadas, plantas danificadas, etc
    if (unidade.contains('folhas') || unidade.contains('plantas')) {
      return _calcularPorContagem(quantidade, total);
    }

    // Padrão: cálculo simples
    return (quantidade / total) * 100;
  }

  /// Cálculo para unidades por área (insetos/m², plantas/m²)
  Future<double> _calcularPorArea({
    required int quantidade,
    required int total,
    required String culturaId,
    required Map<String, dynamic> organismo,
  }) async {
    try {
      // Usar densidade padrão (pode ser refinado depois)
      final densidadePlantas = 50000; // plantas/ha (padrão para soja/milho)

      // Converter para plantas/m²
      final plantasPorM2 = densidadePlantas / 10000; // 1 ha = 10000 m²

      // Calcular área amostrada baseado no total de plantas
      final areaAmostrada = total / plantasPorM2; // m²

      // Densidade de organismos por m²
      final densidadePorM2 = quantidade / areaAmostrada;

      // Nível de ação do organismo
      final nivelAcao = (organismo['action_threshold'] as num?)?.toDouble() ?? 5.0;

      // Percentual baseado no nível de ação
      final percentual = (densidadePorM2 / nivelAcao) * 100;

      return percentual.clamp(0.0, 100.0);

    } catch (e) {
      Logger.error('Erro no cálculo por área: $e');
      return _calcularPorContagem(quantidade, total);
    }
  }

  /// Cálculo para unidades por planta
  double _calcularPorPlanta(int quantidade, int total) {
    if (total <= 0) return 0.0;
    
    // Média de organismos por planta
    final mediaPorPlanta = quantidade / total;
    
    // Considera crítico acima de 3 organismos/planta (ajustável)
    final limiteAcao = 3.0;
    
    return ((mediaPorPlanta / limiteAcao) * 100).clamp(0.0, 100.0);
  }

  /// Cálculo para contagem simples (folhas, plantas, etc)
  double _calcularPorContagem(int quantidade, int total) {
    if (total <= 0) return 0.0;
    return ((quantidade / total) * 100).clamp(0.0, 100.0);
  }

  /// Determina nível usando thresholds do catálogo
  String _determinarNivelComThreshold(
    {required double percentual, required Map<String, dynamic> organismo}
  ) {
    final limiteAcao = (organismo['action_threshold'] as num?)?.toDouble() ?? 25.0;
    final limiteControle = (organismo['control_threshold'] as num?)?.toDouble() ?? 50.0;

    if (percentual <= 0) return 'Ausente';
    if (percentual < limiteAcao * 0.5) return 'Baixo';
    if (percentual < limiteAcao) return 'Médio';
    if (percentual < limiteControle) return 'Alto';
    return 'Crítico';
  }

  /// Determina nível simples (sem threshold)
  String _determinarNivelSimples(double percentual) {
    if (percentual <= 0) return 'Ausente';
    if (percentual < 10) return 'Baixo';
    if (percentual < 25) return 'Médio';
    if (percentual < 50) return 'Alto';
    return 'Crítico';
  }

  /// Obtém cor baseada no nível
  String _obterCorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'ausente':
        return '#CCCCCC';
      case 'baixo':
        return '#27AE60';
      case 'médio':
        return '#F2C94C';
      case 'alto':
        return '#F2994A';
      case 'crítico':
        return '#EB5757';
      default:
        return '#95A5A6';
    }
  }

  /// Recalcula todas as infestações pendentes no banco
  /// (útil quando o catálogo é atualizado)
  Future<int> recalcularInfestacoesHistoricas() async {
    int recalculadas = 0;
    
    // TODO: Implementar leitura do banco e recálculo em batch
    // Isso permite atualizar cálculos quando o JSON do catálogo muda
    
    return recalculadas;
  }
}

