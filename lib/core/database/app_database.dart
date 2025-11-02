
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'app_database.g.dart';

class Culturas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get iconePath => text().nullable()();
}

class Variedades extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get culturaId => integer().references(Culturas, #id)();
  TextColumn get nome => text()();
  TextColumn get ciclo => text().nullable()();
  TextColumn get observacoes => text().nullable()();
}

class Organismos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tipo => text()(); // PRAGA ou DOENCA
  TextColumn get nomeComum => text()();
  TextColumn get nomeCientifico => text().nullable()();
  TextColumn get categoria => text().nullable()();
  TextColumn get iconePath => text().nullable()();
  TextColumn get sintomaDescricao => text().nullable()();
  TextColumn get danoEconomico => text().nullable()();
  TextColumn get partesAfetadas => text().nullable()(); // JSON
  TextColumn get fenologia => text().nullable()(); // JSON
  TextColumn get niveisAcao => text().nullable()(); // JSON
  TextColumn get manejoQuimico => text().nullable()(); // JSON
  TextColumn get manejoBiologico => text().nullable()(); // JSON
  TextColumn get manejoCultural => text().nullable()(); // JSON
  TextColumn get observacoes => text().nullable()();
}

class CulturaOrganismo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get culturaId => integer().references(Culturas, #id)();
  IntColumn get organismoId => integer().references(Organismos, #id)();
  RealColumn get severidadeMedia => real().nullable()();
  TextColumn get observacoesEspecificas => text().nullable()();
}

class Fotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get organismoId => integer().references(Organismos, #id)();
  TextColumn get path => text()();
  BoolColumn get isIcon => boolean().withDefault(Constant(false))();
}

// Tabelas de persistência
class AuditLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  IntColumn get recordId => integer()();
  TextColumn get action => text()();
  TextColumn get oldValues => text().nullable()();
  TextColumn get newValues => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get level => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get deviceInfo => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  TextColumn get userAgent => text().nullable()();
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableName => text()();
  IntColumn get recordId => integer()();
  TextColumn get action => text()();
  TextColumn get data => text()();
  IntColumn get priority => integer().withDefault(Constant(0))();
  IntColumn get retryCount => integer().withDefault(Constant(0))();
  IntColumn get maxRetries => integer().withDefault(Constant(3))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get status => text().withDefault(Constant('pending'))();
}

class SyncHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get syncType => text()();
  TextColumn get status => text()();
  IntColumn get recordsProcessed => integer().withDefault(Constant(0))();
  IntColumn get recordsSuccess => integer().withDefault(Constant(0))();
  IntColumn get recordsFailed => integer().withDefault(Constant(0))();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// Tabelas de monitoramento
class Monitoring extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer().nullable()();
  TextColumn get date => text()();
  TextColumn get weatherCondition => text().nullable()();
  RealColumn get temperature => real().nullable()();
  RealColumn get humidity => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class MonitoringPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get monitoringId => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get organismId => integer().nullable()();
  IntColumn get severityLevel => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Infestacoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get monitoringPointId => integer()();
  IntColumn get organismId => integer()();
  IntColumn get severityLevel => integer()();
  RealColumn get affectedArea => real().nullable()();
  TextColumn get treatmentApplied => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// Tabelas de talhões
class Plots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get area => real().nullable()();
  IntColumn get cultureId => integer().nullable()();
  IntColumn get varietyId => integer().nullable()();
  TextColumn get plantingDate => text().nullable()();
  TextColumn get harvestDate => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Polygons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

// Tabelas de aplicações
class Aplicacoes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer()();
  TextColumn get productName => text()();
  TextColumn get applicationDate => text()();
  RealColumn get dosage => real().nullable()();
  TextColumn get dosageUnit => text().nullable()();
  TextColumn get applicationMethod => text().nullable()();
  TextColumn get weatherCondition => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer()();
  TextColumn get prescriptionDate => text()();
  TextColumn get prescriptionType => text()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class PrescriptionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prescriptionId => integer()();
  TextColumn get productName => text()();
  RealColumn get dosage => real().nullable()();
  TextColumn get dosageUnit => text().nullable()();
  TextColumn get applicationMethod => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// Tabelas de calibração
class CalibracaoFertilizantes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer()();
  TextColumn get fertilizerName => text()();
  TextColumn get calibrationDate => text()();
  RealColumn get targetDosage => real()();
  RealColumn get actualDosage => real().nullable()();
  RealColumn get calibrationFactor => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// Tabelas de estoque
class Estoque extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productName => text()();
  TextColumn get productType => text()();
  RealColumn get currentQuantity => real()();
  TextColumn get unit => text()();
  RealColumn get minQuantity => real().nullable()();
  RealColumn get maxQuantity => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stockId => integer()();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().nullable()();
  TextColumn get supplier => text().nullable()();
  TextColumn get batchNumber => text().nullable()();
  TextColumn get expiryDate => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class InventoryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stockId => integer()();
  TextColumn get movementType => text()();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// Tabelas de análise de solo
class SoilAnalysis extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer()();
  TextColumn get analysisDate => text()();
  RealColumn get phLevel => real().nullable()();
  RealColumn get organicMatter => real().nullable()();
  RealColumn get phosphorus => real().nullable()();
  RealColumn get potassium => real().nullable()();
  RealColumn get calcium => real().nullable()();
  RealColumn get magnesium => real().nullable()();
  RealColumn get sulfur => real().nullable()();
  RealColumn get boron => real().nullable()();
  RealColumn get copper => real().nullable()();
  RealColumn get iron => real().nullable()();
  RealColumn get manganese => real().nullable()();
  RealColumn get zinc => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SoilSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get analysisId => integer()();
  RealColumn get sampleDepth => real()();
  TextColumn get sampleLocation => text().nullable()();
  TextColumn get sampleDate => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// Tabelas de teste de germinação
class GerminationTests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer()();
  TextColumn get testDate => text()();
  TextColumn get seedVariety => text()();
  TextColumn get seedBatch => text().nullable()();
  TextColumn get testType => text()();
  IntColumn get initialSeedCount => integer()();
  IntColumn get finalGerminationCount => integer().nullable()();
  RealColumn get germinationPercentage => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class GerminationDailyRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get testId => integer()();
  TextColumn get recordDate => text()();
  IntColumn get germinatedCount => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [
  Culturas, Variedades, Organismos, CulturaOrganismo, Fotos,
  AuditLog, SyncQueue, SyncHistory,
  Monitoring, MonitoringPoints, Infestacoes,
  Plots, Polygons,
  Aplicacoes, Prescriptions, PrescriptionItems,
  CalibracaoFertilizantes,
  Estoque, InventoryItems, InventoryMovements,
  SoilAnalysis, SoilSamples,
  GerminationTests, GerminationDailyRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10;

  // Seeds
  Future<void> importSeeds(Map<String, dynamic> json) async {
    await batch((b) {
      final culturasList = (json['culturas'] as List)
          .map((e) => CulturasCompanion.insert(nome: e['nome'] as String))
          .toList();
      b.insertAll(culturas, culturasList);

      final organismosList = (json['organismos'] as List).map((e) {
        return OrganismosCompanion.insert(
          tipo: e['tipo'] as String,
          nomeComum: e['nomeComum'] as String,
          nomeCientifico: Value(e['nomeCientifico'] as String?),
          categoria: Value(e['categoria'] as String?),
          iconePath: Value(e['iconePath'] as String?),
          sintomaDescricao: Value(e['sintomaDescricao'] as String?),
          danoEconomico: Value(e['danoEconomico'] as String?),
          partesAfetadas: Value(e['partesAfetadas'] as String?),
          fenologia: Value(e['fenologia'] as String?),
          niveisAcao: Value(e['niveisAcao'] as String?),
          manejoQuimico: Value(e['manejoQuimico'] as String?),
          manejoBiologico: Value(e['manejoBiologico'] as String?),
          manejoCultural: Value(e['manejoCultural'] as String?),
          observacoes: Value(e['observacoes'] as String?),
        );
      }).toList();
      b.insertAll(organismos, organismosList);

      final coList = (json['cultura_organismo'] as List).map((e) {
        return CulturaOrganismoCompanion.insert(
          culturaId: e['culturaId'] as int,
          organismoId: e['organismoId'] as int,
          severidadeMedia: const Value(null),
          observacoesEspecificas: const Value(null),
        );
      }).toList();
      b.insertAll(culturaOrganismo, coList);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fortsmart.db'));
    return NativeDatabase(file);
  });
}
