import '../models/estande_model.dart';
import '../repositories/estande_repository.dart';

class EstandeService {
  final EstandeRepository _repository = EstandeRepository();

  Future<void> saveEstande(EstandeModel estande) async {
    if (estande.id != null) {
      await _repository.update(estande);
    } else {
      await _repository.insert(estande);
    }
  }

  Future<List<EstandeModel>> getAllEstandes() async {
    return await _repository.getAll();
  }

  Future<List<EstandeModel>> getEstandesByFilters({
    int? talhaoId, 
    int? culturaId, 
    int? variedadeId, 
    String? dataAvaliacao
  }) async {
    return await _repository.getByFilters(
      talhaoId: talhaoId,
      culturaId: culturaId,
      variedadeId: variedadeId,
      dataAvaliacao: dataAvaliacao,
    );
  }

  Future<EstandeModel?> getEstandeById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> deleteEstande(int id) async {
    await _repository.delete(id);
  }
  
  /// Calcula o estande de plantas
  double calcularEstande(int plantasContadas, int linhas, double comprimento, double espacamento) {
    return EstandeModel.calcularEstande(plantasContadas, linhas, comprimento, espacamento);
  }
  
  /// Calcula o Desvio Absoluto Esperado (DAE)
  double calcularDAE(double populacaoReal, int populacaoDesejada) {
    return EstandeModel.calcularDAE(populacaoReal, populacaoDesejada);
  }
  
  /// Calcula a porcentagem de falha
  double calcularPorcentagemFalha(double dae, int populacaoDesejada) {
    return EstandeModel.calcularPorcentagemFalha(dae, populacaoDesejada);
  }
  
  /// Gera uma recomendação técnica com base na porcentagem de falha
  String gerarRecomendacaoTecnica(double porcentagemFalha) {
    return EstandeModel.gerarRecomendacaoTecnica(porcentagemFalha);
  }
  
  /// Realiza todos os cálculos de estande e retorna um mapa com os resultados
  Map<String, dynamic> realizarCalculosEstande({
    required int plantasContadas,
    required int linhas,
    required double comprimento,
    required double espacamento,
    required int populacaoDesejada,
    double? germinacaoEstimada,
  }) {
    // Calcula a população real (plantas/ha)
    final populacaoReal = calcularEstande(plantasContadas, linhas, comprimento, espacamento);
    
    // Calcula o DAE
    final dae = calcularDAE(populacaoReal, populacaoDesejada);
    
    // Calcula a porcentagem de falha
    final porcentagemFalha = calcularPorcentagemFalha(dae, populacaoDesejada);
    
    // Gera a recomendação técnica
    final recomendacao = gerarRecomendacaoTecnica(porcentagemFalha);
    
    return {
      'populacaoReal': populacaoReal,
      'dae': dae,
      'porcentagemFalha': porcentagemFalha,
      'recomendacaoTecnica': recomendacao,
    };
  }
}
