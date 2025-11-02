import '../models/semente_hectare_model.dart';
import '../repositories/semente_hectare_repository.dart';

class SementeHectareService {
  final SementeHectareRepository _repository = SementeHectareRepository();

  Future<void> saveSementeHectare(SementeHectareModel sementeHectare) async {
    if (sementeHectare.id != null) {
      await _repository.update(sementeHectare);
    } else {
      await _repository.insert(sementeHectare);
    }
  }

  Future<List<SementeHectareModel>> getAllSementesHectare() async {
    return await _repository.getAll();
  }

  Future<List<SementeHectareModel>> getSementesHectareByFilters({
    int? culturaId, 
    int? variedadeId, 
    String? dataCalculo
  }) async {
    return await _repository.getByFilters(
      culturaId: culturaId,
      variedadeId: variedadeId,
      dataCalculo: dataCalculo,
    );
  }

  Future<SementeHectareModel?> getSementeHectareById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> deleteSementeHectare(int id) async {
    await _repository.delete(id);
  }
  
  /// Calcula a quantidade de sementes em kg/ha
  double calcularSementesKgHa(double populacao, double pesoMilSementes, double germinacao, double pureza) {
    return SementeHectareModel.calcularSementesKgHa(populacao, pesoMilSementes, germinacao, pureza);
  }
}
