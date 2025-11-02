
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

abstract class IOrganismRepository {
  Future<List<Organismo>> getByCulture(int culturaId, {required bool isDisease, bool isWeed = false});
  Future<int> insertOrganismo(OrganismosCompanion companion);
  Future<void> updateOrganismo(Organismo organismo);
  Future<void> deleteOrganismo(int id);
}

class OrganismRepository implements IOrganismRepository {
  final AppDatabase db;
  OrganismRepository(this.db);

  @override
  Future<List<Organismo>> getByCulture(int culturaId, {required bool isDisease, bool isWeed = false}) async {
    final tipo = isWeed ? 'PLANTA_DANINHA' : (isDisease ? 'DOENCA' : 'PRAGA');
    final joinQuery = db.select(db.organismos).join([
      innerJoin(db.culturaOrganismo,
        db.culturaOrganismo.organismoId.equalsExp(db.organismos.id),
      ),
    ])
    ..where(db.culturaOrganismo.culturaId.equals(culturaId))
    ..where(db.organismos.tipo.equals(tipo));

    final rows = await joinQuery.get();
    return rows.map((r) => r.readTable(db.organismos)).toList();
  }

  @override
  Future<int> insertOrganismo(OrganismosCompanion companion) {
    return db.into(db.organismos).insert(companion);
  }

  @override
  Future<void> updateOrganismo(Organismo organismo) async {
    await db.update(db.organismos).replace(organismo);
  }

  @override
  Future<void> deleteOrganismo(int id) async {
    await (db.delete(db.organismos)..where((tbl) => tbl.id.equals(id))).go();
  }
}
