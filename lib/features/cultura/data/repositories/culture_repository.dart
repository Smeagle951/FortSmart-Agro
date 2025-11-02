
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';

abstract class ICultureRepository {
  Future<List<Cultura>> getAll();
}

class CultureRepository implements ICultureRepository {
  final AppDatabase db;
  CultureRepository(this.db);

  @override
  Future<List<Cultura>> getAll() => db.select(db.culturas).get();
}
