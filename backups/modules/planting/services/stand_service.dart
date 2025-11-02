import '../models/stand_model.dart';
import '../repositories/stand_repository.dart';
import '../utils/planting_calculations.dart';

class StandService {
  final StandRepository _repository = StandRepository();

  Future<void> saveStand(StandModel model) async {
    await _repository.insert(model);
  }

  Future<List<StandModel>> getHistory() async {
    return await _repository.getAll();
  }

  double calculateStand(int numPlants, double rowSpacing, double evaluatedLength) {
    return PlantingCalculations.calcStand(numPlants, rowSpacing, evaluatedLength);
  }
}
