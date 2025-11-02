import '../models/plantio_model.dart';
import '../repositories/plantio_repository.dart';

class PlantioService {
  final PlantioRepository _repository = PlantioRepository();

  Future<void> savePlantio(PlantioModel plantio) async {
    if (plantio.id != null) {
      await _repository.update(plantio);
    } else {
      await _repository.insert(plantio);
    }
  }

  Future<List<PlantioModel>> getAllPlantios() async {
    return await _repository.getAll();
  }

  Future<List<PlantioModel>> getPlantiosByFilters({
    int? talhaoId, 
    int? culturaId, 
    int? ano, 
    int? tratorId, 
    int? plantadeiraId
  }) async {
    return await _repository.getByFilters(
      talhaoId: talhaoId,
      culturaId: culturaId,
      ano: ano,
      tratorId: tratorId,
      plantadeiraId: plantadeiraId,
    );
  }

  Future<PlantioModel?> getPlantioById(int id) async {
    return await _repository.getById(id);
  }

  Future<void> deletePlantio(int id) async {
    await _repository.delete(id);
  }
}
