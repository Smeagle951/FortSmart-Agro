import '../models/regulagem_plantadeira_model.dart';
import '../repositories/regulagem_plantadeira_repository.dart';

class RegulagemPlantadeiraService {
  final RegulagemPlantadeiraRepository _repository = RegulagemPlantadeiraRepository();

  Future<void> saveRegulagemPlantadeira(RegulagemPlantadeiraModel regulagem) async {
    if (regulagem.id != null) {
      await _repository.update(regulagem);
    } else {
      await _repository.insert(regulagem);
    }
  }

  Future<List<RegulagemPlantadeiraModel>> getAllRegulagens() async {
    return await _repository.getAll();
  }

  Future<List<RegulagemPlantadeiraModel>> getRegulagensByFilters({
    int? culturaId, 
    int? variedadeId, 
    String? dataRegulagem, 
    String? disco
  }) async {
    return await _repository.getByFilters(
      culturaId: culturaId,
      variedadeId: variedadeId,
      dataRegulagem: dataRegulagem,
      disco: disco,
    );
  }

  Future<RegulagemPlantadeiraModel?> getRegulagemById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> deleteRegulagem(int id) async {
    await _repository.delete(id);
  }
  
  /// Calcula a quantidade de sementes por metro
  double calcularSementesPorMetro(double populacao, double espacamento) {
    return RegulagemPlantadeiraModel.calcularSementesPorMetro(populacao, espacamento);
  }
  
  /// Calcula a velocidade ideal para plantio
  double calcularVelocidadeIdeal(String tipoDisco, double populacao) {
    return RegulagemPlantadeiraModel.calcularVelocidadeIdeal(tipoDisco, populacao);
  }
}
