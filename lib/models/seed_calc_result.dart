class SeedCalcResult {
  final double pms_g_per_seed;
  final double pms_g_per_1000;
  final double seedsPerHa;
  final double seedsNeededPerHa;
  final double kgPerHa;
  final double hectaresCoveredBySeeds;
  final double hectaresCoveredByKg;
  final double hectaresCovered; // média dos dois
  final double totalKgForN;
  final double totalSeedsForN;
  
  SeedCalcResult({
    required this.pms_g_per_seed,
    required this.pms_g_per_1000,
    required this.seedsPerHa,
    required this.seedsNeededPerHa,
    required this.kgPerHa,
    required this.hectaresCoveredBySeeds,
    required this.hectaresCoveredByKg,
    required this.hectaresCovered,
    required this.totalKgForN,
    required this.totalSeedsForN,
  });
}
