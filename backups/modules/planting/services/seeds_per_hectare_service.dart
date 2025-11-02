import '../models/seeds_per_hectare_model.dart';
import '../repositories/seeds_per_hectare_repository.dart';
import '../utils/planting_calculations.dart';

class SeedsPerHectareService {
  final SeedsPerHectareRepository _repository = SeedsPerHectareRepository();

  Future<void> saveSeeds(SeedsPerHectareModel model) async {
    await _repository.insert(model);
  }

  Future<List<SeedsPerHectareModel>> getHistory() async {
    return await _repository.getAll();
  }

  double calculateSeedsHa(double rowSpacing, double seedSpacing) {
    return PlantingCalculations.calcSeedsHa(rowSpacing, seedSpacing);
  }

  double calculateKgHa(double seedsHa, double thousandSeedWeight) {
    return PlantingCalculations.calcKgHaSeeds(seedsHa, thousandSeedWeight);
  }

  double calculateKgHaAdjusted(double kgHa, double? germination, double? purity) {
    return PlantingCalculations.calcKgHaAdjusted(kgHa, germination, purity);
  }
}
