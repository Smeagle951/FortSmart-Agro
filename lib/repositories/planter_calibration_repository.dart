import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/planter_calibration.dart';

/// Repositório para operações com calibragens de plantadeira
class PlanterCalibrationRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'planter_calibrations';

  /// Cria a tabela de calibragens de plantadeira no banco de dados
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        plotId TEXT,
        cropId TEXT NOT NULL,
        machineId TEXT NOT NULL,
        targetPopulation REAL NOT NULL,
        rowSpacing REAL NOT NULL,
        thousandSeedWeight REAL,
        planterRows INTEGER,
        workSpeed REAL,
        drivingGear REAL,
        drivenGear REAL,
        wheelTurns REAL,
        seedDiscHoles INTEGER,
        wheelCircumference REAL,
        isAdvanced INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        responsiblePerson TEXT NOT NULL,
        observations TEXT,
        FOREIGN KEY (plotId) REFERENCES plots (id) ON DELETE SET NULL,
        FOREIGN KEY (cropId) REFERENCES crops (id) ON DELETE RESTRICT,
        FOREIGN KEY (machineId) REFERENCES machines (id) ON DELETE RESTRICT
      )
    ''');
  }

  /// Insere uma nova calibragem de plantadeira no banco de dados
  Future<String> insert(PlanterCalibration calibration) async {
    final db = await _database.database;
    await db.insert(
      _tableName,
      calibration.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return calibration.id;
  }

  /// Atualiza uma calibragem de plantadeira existente
  Future<int> update(PlanterCalibration calibration) async {
    final db = await _database.database;
    return await db.update(
      _tableName,
      calibration.toMap(),
      where: 'id = ?',
      whereArgs: [calibration.id],
    );
  }

  /// Remove uma calibragem de plantadeira
  Future<int> delete(String id) async {
    final db = await _database.database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtém uma calibragem de plantadeira pelo ID
  Future<PlanterCalibration?> getById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PlanterCalibration.fromMap(maps.first);
  }

  /// Obtém todas as calibragens de plantadeira
  Future<List<PlanterCalibration>> getAll() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => PlanterCalibration.fromMap(maps[i]));
  }

  /// Obtém todas as calibragens de plantadeira para um talhão específico
  Future<List<PlanterCalibration>> getByPlotId(String plotId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'plotId = ?',
      whereArgs: [plotId],
    );
    return List.generate(maps.length, (i) => PlanterCalibration.fromMap(maps[i]));
  }

  /// Obtém todas as calibragens de plantadeira para uma cultura específica
  Future<List<PlanterCalibration>> getByCropId(String cropId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'cropId = ?',
      whereArgs: [cropId],
    );
    return List.generate(maps.length, (i) => PlanterCalibration.fromMap(maps[i]));
  }

  /// Obtém todas as calibragens de plantadeira para uma máquina específica
  Future<List<PlanterCalibration>> getByMachineId(String machineId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'machineId = ?',
      whereArgs: [machineId],
    );
    return List.generate(maps.length, (i) => PlanterCalibration.fromMap(maps[i]));
  }

  /// Obtém todas as calibragens simples (não avançadas)
  Future<List<PlanterCalibration>> getSimpleCalibrations() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isAdvanced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => PlanterCalibration.fromMap(maps[i]));
  }

  /// Obtém todas as calibragens avançadas
  Future<List<PlanterCalibration>> getAdvancedCalibrations() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isAdvanced = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => PlanterCalibration.fromMap(maps[i]));
  }

  /// Obtém a contagem total de calibragens de plantadeira
  Future<int> count() async {
    final db = await _database.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
