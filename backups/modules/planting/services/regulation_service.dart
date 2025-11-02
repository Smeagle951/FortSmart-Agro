import '../models/regulation_model.dart';
import '../repositories/regulation_repository.dart';
import '../utils/planting_calculations.dart';

class RegulationService {
  final RegulationRepository _repository = RegulationRepository();

  Future<void> saveRegulation(RegulationModel model) async {
    await _repository.insert(model);
  }

  Future<List<RegulationModel>> getHistory() async {
    return await _repository.getAll();
  }

  double calculateG50m(List<double> weights, int numRows) {
    return PlantingCalculations.calcG50m(weights, numRows);
  }

  double calculateKgHa(double avgWeightG, double rowSpacing) {
    return PlantingCalculations.calcKgHa(avgWeightG, rowSpacing);
  }

  double calculateGearRatio(int driving, int driven) {
    return PlantingCalculations.calcGearRatio(driving, driven);
  }

  double calculateTargetG50m(double kgHa, double rowSpacing) {
    return PlantingCalculations.calcTargetG50m(kgHa, rowSpacing);
  }
}
