class PlantingCalculations {
  // Regulagem: Quantidade aplicada em 50m
  static double calcG50m(List<double> weights, int numRows) {
    if (numRows == 0 || weights.isEmpty) return 0;
    final total = weights.fold<double>(0.0, (a, b) => a + b);
    return total / numRows;
  }

  // Regulagem: Kg/ha com base na coleta
  static double calcKgHa(double avgWeightG, double rowSpacing) {
    if (rowSpacing == 0) return 0;
    return (avgWeightG * 10000) / (rowSpacing * 50 * 1000);
  }

  // Regulagem: Correção via Engrenagens
  static double calcGearRatio(int driving, int driven) {
    if (driven == 0) return 0;
    return driving / driven;
  }

  // Regulagem: Meta em gramas por linha a cada 50m
  static double calcTargetG50m(double kgHa, double rowSpacing) {
    return (kgHa * rowSpacing * 50 * 1000) / 10000;
  }

  // Estande: plantas/ha
  static double calcStand(int numPlants, double rowSpacing, double evaluatedLength) {
    if (rowSpacing == 0 || evaluatedLength == 0) return 0;
    return (numPlants * 10000) / (rowSpacing * evaluatedLength);
  }

  // Sementes/ha
  static double calcSeedsHa(double rowSpacing, double seedSpacing) {
    if (rowSpacing == 0 || seedSpacing == 0) return 0;
    return 10000 / (rowSpacing * seedSpacing);
  }

  // Kg/ha (sementes)
  static double calcKgHaSeeds(double seedsHa, double thousandSeedWeight) {
    return (seedsHa * thousandSeedWeight) / (1000 * 1000);
  }

  // Kg/ha ajustado
  static double calcKgHaAdjusted(double kgHa, double? germination, double? purity) {
    if (germination == null || purity == null || germination == 0 || purity == 0) return kgHa;
    return kgHa / ((germination * purity) / 10000);
  }
}
