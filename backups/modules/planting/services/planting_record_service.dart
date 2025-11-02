import '../models/planting_record_model.dart';
import '../repositories/planting_record_repository.dart';

class PlantingRecordService {
  final PlantingRecordRepository _repository = PlantingRecordRepository();

  Future<void> saveRecord(PlantingRecordModel model) async {
    await _repository.insert(model);
  }

  Future<List<PlantingRecordModel>> getHistory() async {
    return await _repository.getAll();
  }
}
