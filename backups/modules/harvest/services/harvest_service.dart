import '../models/harvest_model.dart';
import '../repositories/harvest_repository.dart';

class HarvestService {
  final HarvestRepository _repository = HarvestRepository();

  Future<void> saveHarvest(HarvestModel model) async {
    await _repository.insert(model);
  }

  Future<List<HarvestModel>> getHistory() async {
    return await _repository.getAll();
  }

  Future<List<HarvestModel>> getUnsynced() async {
    return await _repository.getUnsynced();
  }

  Future<void> deleteHarvest(String id) async {
    await _repository.delete(id);
  }
}
