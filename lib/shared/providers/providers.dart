
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../culture/data/repositories/culture_repository.dart';
import '../../organisms/data/repositories/organism_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final bootstrapProvider = FutureProvider<void>((ref) async {
  final db = ref.read(databaseProvider);
  final count = await db.select(db.culturas).get().then((v) => v.length);
  if (count == 0) {
    final jsonStr = await rootBundle.loadString('assets/seeds/seeds.json');
    await db.importSeeds(json.decode(jsonStr) as Map<String, dynamic>);
  }
});

// repositories
final cultureRepositoryProvider = Provider<ICultureRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CultureRepository(db);
});

final organismRepositoryProvider = Provider<IOrganismRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return OrganismRepository(db);
});

// use-cases: Riverpod
final culturasProvider = FutureProvider((ref) async {
  await ref.watch(bootstrapProvider.future);
  final repo = ref.watch(cultureRepositoryProvider);
  return repo.getAll();
});

final pragasByCulturaProvider = FutureProvider.family((ref, int culturaId) async {
  await ref.watch(bootstrapProvider.future);
  final repo = ref.watch(organismRepositoryProvider);
  return repo.getByCulture(culturaId, isDisease: false);
});

final doencasByCulturaProvider = FutureProvider.family((ref, int culturaId) async {
  await ref.watch(bootstrapProvider.future);
  final repo = ref.watch(organismRepositoryProvider);
  return repo.getByCulture(culturaId, isDisease: true);
});

final plantasDaninhasByCulturaProvider = FutureProvider.family((ref, int culturaId) async {
  await ref.watch(bootstrapProvider.future);
  final repo = ref.watch(organismRepositoryProvider);
  return repo.getByCulture(culturaId, isWeed: true);
});
