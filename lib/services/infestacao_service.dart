import '../models/monitoring.dart';
import '../models/talhao_model_new.dart';
import '../models/talhao_resumo_model.dart';
import '../repositories/monitoring_repository.dart';
import '../repositories/talhao_repository_new.dart';

/// Serviço para análise de infestação e geração de resumos de talhões
class InfestacaoService {
  final MonitoringRepository _monitoringRepository = MonitoringRepository();
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  
  /// Obter resumo de todos os talhões
  Future<List<TalhaoResumoModel>> obterResumoTalhoes() async {
    final talhoes = await _talhaoRepository.listarTodos();
    final List<TalhaoResumoModel> resumos = [];
    
    for (final talhao in talhoes) {
      final resumo = await calcularResumoTalhao(talhao.id);
      if (resumo != null) {
        resumos.add(resumo);
      }
    }
    
    return resumos;
  }
  
  /// Obter talhões com seus respectivos resumos de infestação
  Future<List<TalhaoModel>> obterTalhoesComResumo() async {
    return await _talhaoRepository.listarTodos();
  }
  
  /// Obter um talhão específico pelo ID
  Future<TalhaoModel?> obterTalhao(String talhaoId) async {
    return await _talhaoRepository.buscarPorId(talhaoId);
  }
  
  /// Obter os últimos monitoramentos de um talhão
  Future<List<Monitoring>> obterUltimosMonitoramentos(String talhaoId, int limit) async {
    // Obter todos os monitoramentos do talhão
    // Comentado temporariamente até resolver dependências
    final monitoramentos = await _monitoringRepository.getMonitoringsByPlot(int.parse(talhaoId));
    
    // Comentado temporariamente até resolver dependências
    // // Ordenar por data de criação (mais recentes primeiro)
    // monitoramentos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // 
    // // Retornar apenas os primeiros 'limit' monitoramentos
    // return monitoramentos.take(limit).toList();
    return [];
  }
  
  /// Calcular resumo para um talhão específico
  Future<TalhaoResumoModel?> calcularResumoTalhao(String talhaoId) async {
    try {
      final talhao = await _talhaoRepository.buscarPorId(talhaoId);
      if (talhao == null) return null;
      
      // Obter os últimos 3 monitoramentos do talhão
      final monitoramentos = await obterUltimosMonitoramentos(talhaoId, 3);
      
      if (monitoramentos.isEmpty) return null;
      
      // Calcular a média ponderada dos índices de infestação
      // Monitoramento mais recente tem peso maior
      double severidadeTotal = 0;
      double pesoTotal = 0;
      final Map<String, OcorrenciaAcumulada> ocorrenciasMap = {};
      String? imagemRepresentativa;
      
      for (int i = 0; i < monitoramentos.length; i++) {
        final monitoramento = monitoramentos[i];
        final double peso = (monitoramentos.length - i).toDouble(); // Peso maior para os mais recentes
        pesoTotal += peso;
        
        // Processar pontos de monitoramento
        for (final ponto in monitoramento.points) {
          for (final ocorrencia in ponto.occurrences) {
            severidadeTotal += ocorrencia.infestationIndex * peso;
            
            // Acumular ocorrências para identificar as principais
            final key = '${ocorrencia.type}_${ocorrencia.name}';
            if (!ocorrenciasMap.containsKey(key)) {
              ocorrenciasMap[key] = OcorrenciaAcumulada(
                nome: ocorrencia.name,
                tipo: ocorrencia.type,
                indiceAcumulado: 0,
                contagem: 0,
                imagemPath: ponto.imagePaths.isNotEmpty ? ponto.imagePaths.first : null,
              );
            }
            
            ocorrenciasMap[key]!.indiceAcumulado += ocorrencia.infestationIndex * peso;
            ocorrenciasMap[key]!.contagem += peso.toDouble();
            
            // Guardar a imagem do ponto com maior índice de infestação
            if (imagemRepresentativa == null && ponto.imagePaths.isNotEmpty) {
              imagemRepresentativa = ponto.imagePaths.first;
            }
          }
        }
      }
      
      // Calcular a severidade média (escala 0-100)
      final double severidadeMedia = monitoramentos.isEmpty || pesoTotal == 0 ? 0 : 
        (severidadeTotal / (pesoTotal * monitoramentos.length)) * 100;
      
      // Obter as principais ocorrências (top 3)
      final List<OcorrenciaResumo> principaisOcorrencias = ocorrenciasMap.values
        .map((acumulada) => OcorrenciaResumo(
          nome: acumulada.nome,
          tipo: acumulada.tipo,
          indiceInfestacao: (acumulada.indiceAcumulado / acumulada.contagem) * 100, // Escala 0-100
          imagemPath: acumulada.imagemPath,
        ))
        .toList()
        ..sort((a, b) => b.indiceInfestacao.compareTo(a.indiceInfestacao));
      
      // Limitar a 3 ocorrências principais
      final topOcorrencias = principaisOcorrencias.take(3).toList();
      
      return TalhaoResumoModel(
        talhaoId: talhao.id ?? '',
        talhaoNome: talhao.nome ?? '',
        severidadeMedia: severidadeMedia,
        nivelSeveridade: TalhaoResumoModel.getNivelSeveridade(severidadeMedia),
        corSeveridade: TalhaoResumoModel.getCorPorSeveridade(severidadeMedia),
        principaisOcorrencias: topOcorrencias,
        diagnosticos: [], // Lista vazia por enquanto
        ultimaAtualizacao: monitoramentos.first.createdAt,
        imagemRepresentativa: imagemRepresentativa,
      );
    } catch (e) {
      print('Erro ao calcular resumo do talhão: $e');
      return null;
    }
  }
}
