import '../models/seed_calc_result.dart';

/// Função para cálculo de sementes (neutro - sem correção de germinação/vigor)
/// Suporta dois modos: sementes por metro ou população desejada
SeedCalcResult calculateSeeds({
  // entradas
  required bool modeSeedsPerBag, // true = informei seeds_per_bag, false = informei W_bag
  double seedsPerBag = 0, // ex: 5_000_000
  double Wbag = 0, // kg por bag, ex: 50
  int nBags = 1,
  double? PMS_g_per_1000_input, // se o usuário inserir PMS diretamente (g/1000)
  double sMetro = 0, // sementes por metro linear (ex: 12) - usado se modoPopulacao = false
  double populacaoDesejada = 0, // população desejada em plantas/ha (ex: 250000) - usado se modoPopulacao = true
  bool modoPopulacao = false, // true = calcular por população, false = calcular por sementes/metro
  required double esp, // espaçamento entre linhas em metros (ex: 0.45)
  double Nha = 0, // área pra calcular necessidade
}) {
  final totalSeeds = seedsPerBag * nBags;
  final WtotalKg = Wbag * nBags;

  // PMS: tenta usar entrada direta; se não tiver, calcula a partir de seeds & peso
  double pms_g_per_seed;
  if (PMS_g_per_1000_input != null && PMS_g_per_1000_input > 0) {
    pms_g_per_seed = PMS_g_per_1000_input / 1000.0;
  } else {
    // Calcular PMS a partir de sementes e peso
    if (totalSeeds > 0 && WtotalKg > 0) {
      // Se temos tanto sementes quanto peso, podemos calcular PMS
      pms_g_per_seed = (WtotalKg * 1000.0) / totalSeeds;
    } else {
      // Se não temos dados suficientes para calcular PMS
      throw ArgumentError('Para calcular PMS, é necessário informar o número de sementes por bag e o peso do bag, ou inserir PMS manualmente');
    }
  }
  final pms_g_per_1000 = pms_g_per_seed * 1000.0;

  // ✅ FÓRMULA NEUTRA: Calcular sementes/ha baseado no modo escolhido
  double seedsPerHa;
  double calculatedSMetro;
  
  if (modoPopulacao) {
    // MODO POPULAÇÃO: Calcular sementes/metro a partir da população desejada
    // Fórmula inversa: sementes/m = (população/ha × espaçamento) / 10.000
    calculatedSMetro = (populacaoDesejada * esp) / 10000.0;
    seedsPerHa = populacaoDesejada; // A população desejada É a densidade de sementes/ha
    print('🔍 CALC DEBUG [POPULAÇÃO] - População desejada: $populacaoDesejada plantas/ha');
    print('🔍 CALC DEBUG [POPULAÇÃO] - Calculado sementes/m: $calculatedSMetro');
    print('🔍 CALC DEBUG [POPULAÇÃO] - seedsPerHa = $seedsPerHa');
  } else {
    // MODO SEMENTES/METRO: Calcular sementes/ha a partir de sementes/metro
    // sementes/ha = (sementes/m × 10.000) / espaçamento
    calculatedSMetro = sMetro;
    seedsPerHa = (sMetro * 10000.0) / esp;
    print('🔍 CALC DEBUG [SEMENTES/M] - Sementes por metro: $sMetro');
    print('🔍 CALC DEBUG [SEMENTES/M] - seedsPerHa = $seedsPerHa');
  }
  
  print('🔍 CALC DEBUG - seedsPerHa (bruto, sem correção) = $seedsPerHa');

  // ⚠️ GERMINAÇÃO E VIGOR: Apenas para informação, NÃO afeta o cálculo
  // Nota: Parâmetros removidos da assinatura, mas mantidos para compatibilidade
  print('📊 INFO - Germinação e Vigor são apenas informativos (não afetam o cálculo)');

  // ✅ MUDANÇA: Não aplicar correção por germinação/vigor
  // Antes: seedsNeededPerHa = seedsPerHa / (germ × vigor)
  // Agora: seedsNeededPerHa = seedsPerHa (densidade bruta real)
  final seedsNeededPerHa = seedsPerHa;
  print('🔍 CALC DEBUG - seedsNeededPerHa = $seedsNeededPerHa (sem correção)');

  // ✅ FÓRMULA NEUTRA: kg per ha
  // kg/ha = sementes/ha × (peso_bag / sementes_por_bag)
  final kgPerHa = seedsNeededPerHa * pms_g_per_seed / 1000.0;
  print('🔍 CALC DEBUG - kgPerHa = $kgPerHa');

  // hectares covered
  final hectaresCoveredBySeeds =
      (seedsNeededPerHa > 0) ? totalSeeds / seedsNeededPerHa : 0.0;
  final hectaresCoveredByKg =
      (kgPerHa > 0) ? (WtotalKg / kgPerHa) : 0.0;
  final hectaresCovered = (hectaresCoveredBySeeds + hectaresCoveredByKg) / 2.0;
  print('🔍 CALC DEBUG - hectaresCovered = $hectaresCovered');

  final totalKgForN = kgPerHa * Nha;
  final totalSeedsForN = seedsNeededPerHa * Nha;

  return SeedCalcResult(
    pms_g_per_seed: pms_g_per_seed,
    pms_g_per_1000: pms_g_per_1000,
    seedsPerHa: seedsPerHa,
    seedsNeededPerHa: seedsNeededPerHa,
    kgPerHa: kgPerHa,
    hectaresCoveredBySeeds: hectaresCoveredBySeeds,
    hectaresCoveredByKg: hectaresCoveredByKg,
    hectaresCovered: hectaresCovered,
    totalKgForN: totalKgForN,
    totalSeedsForN: totalSeedsForN,
  );
}
