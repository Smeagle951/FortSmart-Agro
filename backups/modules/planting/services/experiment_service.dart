import '../models/experiment_model.dart';
import '../repositories/experiment_repository.dart';

class ExperimentService {
  final ExperimentRepository _repository = ExperimentRepository();

  Future<void> saveExperiment(ExperimentModel model) async {
    await _repository.insert(model);
  }

  Future<List<ExperimentModel>> getHistory() async {
    return await _repository.getAll();
  }
}
