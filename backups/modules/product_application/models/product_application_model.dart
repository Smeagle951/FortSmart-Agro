import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'application_target_model.dart';

enum ApplicationType {
  terrestrial,
  aerial,
}

class ProductApplicationModel {
  final String id;
  final ApplicationType applicationType;
  final DateTime applicationDate;
  final String responsibleName;
  final String equipmentType;
  final double syrupVolumePerHectare;
  
  // Área de aplicação
  final String cropId;
  final String cropName;
  final String plotId;
  final String plotName;
  final double area;
  final List<String> targetIds; // IDs de pragas, doenças ou plantas daninhas
  final ApplicationControlType controlType; // Tipos de controle da aplicação
  
  // Produtos aplicados
  final List<ApplicationProductModel> products;
  
  // Equipamento e cálculos
  final double totalSyrupVolume;
  final double equipmentCapacity;
  final int numberOfTanks;
  final String nozzleType;
  
  // Observações
  final String? technicalJustification;
  final bool deductFromStock;
  
  // Metadados
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  ProductApplicationModel({
    String? id,
    required this.applicationType,
    required this.applicationDate,
    required this.responsibleName,
    required this.equipmentType,
    required this.syrupVolumePerHectare,
    required this.cropId,
    required this.cropName,
    required this.plotId,
    required this.plotName,
    required this.area,
    required this.targetIds,
    required this.controlType,
    required this.products,
    required this.totalSyrupVolume,
    required this.equipmentCapacity,
    required this.numberOfTanks,
    required this.nozzleType,
    this.technicalJustification,
    required this.deductFromStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Método para criar uma cópia do modelo com alterações
  ProductApplicationModel copyWith({
    String? id,
    ApplicationType? applicationType,
    DateTime? applicationDate,
    String? responsibleName,
    String? equipmentType,
    double? syrupVolumePerHectare,
    String? cropId,
    String? cropName,
    String? plotId,
    String? plotName,
    double? area,
    List<String>? targetIds,
    ApplicationControlType? controlType,
    List<ApplicationProductModel>? products,
    double? totalSyrupVolume,
    double? equipmentCapacity,
    int? numberOfTanks,
    String? nozzleType,
    String? technicalJustification,
    bool? deductFromStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ProductApplicationModel(
      id: id ?? this.id,
      applicationType: applicationType ?? this.applicationType,
      applicationDate: applicationDate ?? this.applicationDate,
      responsibleName: responsibleName ?? this.responsibleName,
      equipmentType: equipmentType ?? this.equipmentType,
      syrupVolumePerHectare: syrupVolumePerHectare ?? this.syrupVolumePerHectare,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      area: area ?? this.area,
      targetIds: targetIds ?? this.targetIds,
      controlType: controlType ?? this.controlType,
      products: products ?? this.products,
      totalSyrupVolume: totalSyrupVolume ?? this.totalSyrupVolume,
      equipmentCapacity: equipmentCapacity ?? this.equipmentCapacity,
      numberOfTanks: numberOfTanks ?? this.numberOfTanks,
      nozzleType: nozzleType ?? this.nozzleType,
      technicalJustification: technicalJustification ?? this.technicalJustification,
      deductFromStock: deductFromStock ?? this.deductFromStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Converter para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'applicationType': applicationType.index,
      'applicationDate': applicationDate.toIso8601String(),
      'responsibleName': responsibleName,
      'equipmentType': equipmentType,
      'syrupVolumePerHectare': syrupVolumePerHectare,
      'cropId': cropId,
      'cropName': cropName,
      'plotId': plotId,
      'plotName': plotName,
      'area': area,
      'targetIds': jsonEncode(targetIds),
      'controlType': controlType.toJson(),
      'products': jsonEncode(products.map((product) => product.toMap()).toList()),
      'totalSyrupVolume': totalSyrupVolume,
      'equipmentCapacity': equipmentCapacity,
      'numberOfTanks': numberOfTanks,
      'nozzleType': nozzleType,
      'technicalJustification': technicalJustification,
      'deductFromStock': deductFromStock ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Criar a partir de um Map
  factory ProductApplicationModel.fromMap(Map<String, dynamic> map) {
    return ProductApplicationModel(
      id: map['id'],
      applicationType: ApplicationType.values[map['applicationType']],
      applicationDate: DateTime.parse(map['applicationDate']),
      responsibleName: map['responsibleName'],
      equipmentType: map['equipmentType'],
      syrupVolumePerHectare: map['syrupVolumePerHectare'],
      cropId: map['cropId'],
      cropName: map['cropName'],
      plotId: map['plotId'],
      plotName: map['plotName'],
      area: map['area'],
      targetIds: List<String>.from(jsonDecode(map['targetIds'])),
      controlType: ApplicationControlType.fromJson(map['controlType']),
      products: (jsonDecode(map['products']) as List)
          .map((productMap) => ApplicationProductModel.fromMap(productMap))
          .toList(),
      totalSyrupVolume: map['totalSyrupVolume'],
      equipmentCapacity: map['equipmentCapacity'],
      numberOfTanks: map['numberOfTanks'],
      nozzleType: map['nozzleType'],
      technicalJustification: map['technicalJustification'],
      deductFromStock: map['deductFromStock'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }
}

// Modelo para produtos aplicados
class ApplicationProductModel {
  final String productId;
  final String productName;
  final double dosePerHectare;
  final String unit;
  final double totalDose;
  final int numberOfTanks;
  final double productPerTank;

  ApplicationProductModel({
    required this.productId,
    required this.productName,
    required this.dosePerHectare,
    required this.unit,
    required this.totalDose,
    required this.numberOfTanks,
    required this.productPerTank,
  });

  // Método para criar uma cópia do modelo com alterações
  ApplicationProductModel copyWith({
    String? productId,
    String? productName,
    double? dosePerHectare,
    String? unit,
    double? totalDose,
    int? numberOfTanks,
    double? productPerTank,
  }) {
    return ApplicationProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      dosePerHectare: dosePerHectare ?? this.dosePerHectare,
      unit: unit ?? this.unit,
      totalDose: totalDose ?? this.totalDose,
      numberOfTanks: numberOfTanks ?? this.numberOfTanks,
      productPerTank: productPerTank ?? this.productPerTank,
    );
  }

  // Converter para Map para persistência
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'dosePerHectare': dosePerHectare,
      'unit': unit,
      'totalDose': totalDose,
      'numberOfTanks': numberOfTanks,
      'productPerTank': productPerTank,
    };
  }

  // Criar a partir de um Map
  factory ApplicationProductModel.fromMap(Map<String, dynamic> map) {
    return ApplicationProductModel(
      productId: map['productId'],
      productName: map['productName'],
      dosePerHectare: map['dosePerHectare'],
      unit: map['unit'],
      totalDose: map['totalDose'],
      numberOfTanks: map['numberOfTanks'],
      productPerTank: map['productPerTank'],
    );
  }
}
