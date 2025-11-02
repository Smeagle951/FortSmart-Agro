import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/prescription.dart';
import '../utils/device_id_manager.dart';

class PrescriptionRepository {
  final AppDatabase _database = AppDatabase();
  final String _tableName = 'prescriptions';
  final String _productsTableName = 'prescription_products';

  /// Cria a tabela de prescrições no banco de dados
  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        farmId TEXT NOT NULL,
        farmName TEXT NOT NULL,
        plotId TEXT NOT NULL,
        plotName TEXT NOT NULL,
        cropId TEXT NOT NULL,
        cropName TEXT NOT NULL,
        issueDate TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        agronomistName TEXT NOT NULL,
        agronomistRegistration TEXT NOT NULL,
        status TEXT NOT NULL,
        targetPest TEXT,
        targetDisease TEXT,
        targetWeed TEXT,
        observations TEXT,
        applicationConditions TEXT,
        safetyInstructions TEXT,
        deviceId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_productsTableName (
        id TEXT PRIMARY KEY,
        prescriptionId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        dosage TEXT NOT NULL,
        dosageUnit TEXT NOT NULL,
        applicationMethod TEXT NOT NULL,
        observations TEXT,
        FOREIGN KEY (prescriptionId) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Insere uma nova prescrição no banco de dados
  Future<String> insertPrescription(Prescription prescription) async {
    final db = await _database.database;
    final deviceId = await DeviceIdManager.getDeviceId();
    
    // Adicionar o deviceId ao objeto de prescrição
    final prescriptionWithDeviceId = prescription.copyWith(
      deviceId: deviceId,
      updatedAt: DateTime.now(),
    );
    
    await db.transaction((txn) async {
      // Inserir a prescrição
      await txn.insert(
        _tableName,
        prescriptionWithDeviceId.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Inserir os produtos da prescrição
      for (var product in prescriptionWithDeviceId.products) {
        await txn.insert(
          _productsTableName,
          {
            ...product.toMap(),
            'prescriptionId': prescriptionWithDeviceId.id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    
    return prescriptionWithDeviceId.id;
  }

  /// Atualiza uma prescrição existente
  Future<bool> updatePrescription(Prescription prescription) async {
    final db = await _database.database;
    
    // Atualizar a data de modificação
    final updatedPrescription = prescription.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    
    bool success = false;
    
    await db.transaction((txn) async {
      // Atualizar a prescrição
      final updateCount = await txn.update(
        _tableName,
        updatedPrescription.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPrescription.id],
      );
      
      if (updateCount > 0) {
        // Excluir produtos antigos
        await txn.delete(
          _productsTableName,
          where: 'prescriptionId = ?',
          whereArgs: [updatedPrescription.id],
        );
        
        // Inserir produtos atualizados
        for (var product in updatedPrescription.products) {
          await txn.insert(
            _productsTableName,
            {
              ...product.toMap(),
              'prescriptionId': updatedPrescription.id,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        success = true;
      }
    });
    
    return success;
  }

  /// Exclui uma prescrição pelo ID
  Future<bool> deletePrescription(String id) async {
    final db = await _database.database;
    
    bool success = false;
    
    await db.transaction((txn) async {
      // Excluir produtos da prescrição
      await txn.delete(
        _productsTableName,
        where: 'prescriptionId = ?',
        whereArgs: [id],
      );
      
      // Excluir a prescrição
      final deleteCount = await txn.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      success = deleteCount > 0;
    });
    
    return success;
  }

  /// Obtém uma prescrição pelo ID
  Future<Prescription?> getPrescriptionById(String id) async {
    final db = await _database.database;
    
    final prescriptionMaps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (prescriptionMaps.isEmpty) {
      return null;
    }
    
    final productMaps = await db.query(
      _productsTableName,
      where: 'prescriptionId = ?',
      whereArgs: [id],
    );
    
    final products = productMaps.map((map) => PrescriptionProduct.fromMap(map)).toList();
    
    final prescription = Prescription.fromMap(prescriptionMaps.first);
    
    // Criar uma nova prescrição com os produtos
    return prescription.copyWith(products: products);
  }

  /// Obtém todas as prescrições
  Future<List<Prescription>> getAllPrescriptions() async {
    final db = await _database.database;
    final deviceId = await DeviceIdManager.getDeviceId();
    
    final prescriptionMaps = await db.query(
      _tableName,
      where: 'deviceId = ?',
      whereArgs: [deviceId],
      orderBy: 'issueDate DESC',
    );
    
    if (prescriptionMaps.isEmpty) {
      return [];
    }
    
    List<Prescription> prescriptions = [];
    
    for (var map in prescriptionMaps) {
      final id = map['id'] as String;
      
      final productMaps = await db.query(
        _productsTableName,
        where: 'prescriptionId = ?',
        whereArgs: [id],
      );
      
      final products = productMaps.map((map) => PrescriptionProduct.fromMap(map)).toList();
      
      final prescription = Prescription.fromMap(map);
      prescriptions.add(prescription.copyWith(products: products));
    }
    
    return prescriptions;
  }

  /// Obtém prescrições por status
  Future<List<Prescription>> getPrescriptionsByStatus(String status) async {
    final db = await _database.database;
    final deviceId = await DeviceIdManager.getDeviceId();
    
    final prescriptionMaps = await db.query(
      _tableName,
      where: 'status = ? AND deviceId = ?',
      whereArgs: [status, deviceId],
      orderBy: 'issueDate DESC',
    );
    
    if (prescriptionMaps.isEmpty) {
      return [];
    }
    
    List<Prescription> prescriptions = [];
    
    for (var map in prescriptionMaps) {
      final id = map['id'] as String;
      
      final productMaps = await db.query(
        _productsTableName,
        where: 'prescriptionId = ?',
        whereArgs: [id],
      );
      
      final products = productMaps.map((map) => PrescriptionProduct.fromMap(map)).toList();
      
      final prescription = Prescription.fromMap(map);
      prescriptions.add(prescription.copyWith(products: products));
    }
    
    return prescriptions;
  }

  /// Obtém prescrições por intervalo de datas
  Future<List<Prescription>> getPrescriptionsByDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _database.database;
    final deviceId = await DeviceIdManager.getDeviceId();
    
    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
    
    final prescriptionMaps = await db.query(
      _tableName,
      where: 'issueDate >= ? AND issueDate < ? AND deviceId = ?',
      whereArgs: [start, end, deviceId],
      orderBy: 'issueDate DESC',
    );
    
    if (prescriptionMaps.isEmpty) {
      return [];
    }
    
    List<Prescription> prescriptions = [];
    
    for (var map in prescriptionMaps) {
      final id = map['id'] as String;
      
      final productMaps = await db.query(
        _productsTableName,
        where: 'prescriptionId = ?',
        whereArgs: [id],
      );
      
      final products = productMaps.map((map) => PrescriptionProduct.fromMap(map)).toList();
      
      final prescription = Prescription.fromMap(map);
      prescriptions.add(prescription.copyWith(products: products));
    }
    
    return prescriptions;
  }

  /// Obtém prescrições por fazenda
  Future<List<Prescription>> getPrescriptionsByFarm(String farmId) async {
    final db = await _database.database;
    final deviceId = await DeviceIdManager.getDeviceId();
    
    final prescriptionMaps = await db.query(
      _tableName,
      where: 'farmId = ? AND deviceId = ?',
      whereArgs: [farmId, deviceId],
      orderBy: 'issueDate DESC',
    );
    
    if (prescriptionMaps.isEmpty) {
      return [];
    }
    
    List<Prescription> prescriptions = [];
    
    for (var map in prescriptionMaps) {
      final id = map['id'] as String;
      
      final productMaps = await db.query(
        _productsTableName,
        where: 'prescriptionId = ?',
        whereArgs: [id],
      );
      
      final products = productMaps.map((map) => PrescriptionProduct.fromMap(map)).toList();
      
      final prescription = Prescription.fromMap(map);
      prescriptions.add(prescription.copyWith(products: products));
    }
    
    return prescriptions;
  }

  /// Obtém prescrições por talhão
  Future<List<Prescription>> getPrescriptionsByPlot(String plotId) async {
    final db = await _database.database;
    final deviceId = await DeviceIdManager.getDeviceId();
    
    final prescriptionMaps = await db.query(
      _tableName,
      where: 'plotId = ? AND deviceId = ?',
      whereArgs: [plotId, deviceId],
      orderBy: 'issueDate DESC',
    );
    
    if (prescriptionMaps.isEmpty) {
      return [];
    }
    
    List<Prescription> prescriptions = [];
    
    for (var map in prescriptionMaps) {
      final id = map['id'] as String;
      
      final productMaps = await db.query(
        _productsTableName,
        where: 'prescriptionId = ?',
        whereArgs: [id],
      );
      
      final products = productMaps.map((map) => PrescriptionProduct.fromMap(map)).toList();
      
      final prescription = Prescription.fromMap(map);
      prescriptions.add(prescription.copyWith(products: products));
    }
    
    return prescriptions;
  }
}
