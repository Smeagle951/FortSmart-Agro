import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Modelo para representar um produto em uma prescrição
class PrescriptionProduct {
  final String id;
  final String productId;
  final String productName;
  final String dosage;
  final String dosageUnit;
  final String applicationMethod;
  final String? observations;

  PrescriptionProduct({
    String? id,
    required this.productId,
    required this.productName,
    required this.dosage,
    required this.dosageUnit,
    required this.applicationMethod,
    this.observations,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'applicationMethod': applicationMethod,
      'observations': observations,
    };
  }

  factory PrescriptionProduct.fromMap(Map<String, dynamic> map) {
    return PrescriptionProduct(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      dosage: map['dosage'],
      dosageUnit: map['dosageUnit'],
      applicationMethod: map['applicationMethod'],
      observations: map['observations'],
    );
  }

  String toJson() => json.encode(toMap());

  factory PrescriptionProduct.fromJson(String source) =>
      PrescriptionProduct.fromMap(json.decode(source));

  PrescriptionProduct copyWith({
    String? id,
    String? productId,
    String? productName,
    String? dosage,
    String? dosageUnit,
    String? applicationMethod,
    String? observations,
  }) {
    return PrescriptionProduct(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      observations: observations ?? this.observations,
    );
  }
}

/// Modelo para representar uma prescrição agronômica
class Prescription {
  final String id;
  final String title;
  final String farmId;
  final String farmName;
  final String plotId;
  final String plotName;
  final String cropId;
  final String cropName;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String agronomistName;
  final String agronomistRegistration;
  final String status; // Pendente, Aprovada, Aplicada, Cancelada
  final List<PrescriptionProduct> products;
  final String? targetPest;
  final String? targetDisease;
  final String? targetWeed;
  final String? observations;
  final String? applicationConditions;
  final String? safetyInstructions;
  final double? totalArea;
  final double? dosagePerHectare;
  final double? dosagePerApplication;
  final double? applicationVolume;
  final String? deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Prescription({
    String? id,
    required this.title,
    required this.farmId,
    required this.farmName,
    required this.plotId,
    required this.plotName,
    required this.cropId,
    required this.cropName,
    required this.issueDate,
    required this.expiryDate,
    required this.agronomistName,
    required this.agronomistRegistration,
    required this.status,
    required this.products,
    this.targetPest,
    this.targetDisease,
    this.targetWeed,
    this.observations,
    this.applicationConditions,
    this.safetyInstructions,
    this.totalArea,
    this.dosagePerHectare,
    this.dosagePerApplication,
    this.applicationVolume,
    this.deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'farmId': farmId,
      'farmName': farmName,
      'plotId': plotId,
      'plotName': plotName,
      'cropId': cropId,
      'cropName': cropName,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'agronomistName': agronomistName,
      'agronomistRegistration': agronomistRegistration,
      'status': status,
      'products': products.map((x) => x.toMap()).toList(),
      'targetPest': targetPest,
      'targetDisease': targetDisease,
      'targetWeed': targetWeed,
      'observations': observations,
      'applicationConditions': applicationConditions,
      'safetyInstructions': safetyInstructions,
      'totalArea': totalArea,
      'dosagePerHectare': dosagePerHectare,
      'dosagePerApplication': dosagePerApplication,
      'applicationVolume': applicationVolume,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      title: map['title'],
      farmId: map['farmId'],
      farmName: map['farmName'],
      plotId: map['plotId'],
      plotName: map['plotName'],
      cropId: map['cropId'],
      cropName: map['cropName'],
      issueDate: DateTime.parse(map['issueDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      agronomistName: map['agronomistName'],
      agronomistRegistration: map['agronomistRegistration'],
      status: map['status'],
      products: List<PrescriptionProduct>.from(
          map['products']?.map((x) => PrescriptionProduct.fromMap(x))),
      targetPest: map['targetPest'],
      targetDisease: map['targetDisease'],
      targetWeed: map['targetWeed'],
      observations: map['observations'],
      applicationConditions: map['applicationConditions'],
      safetyInstructions: map['safetyInstructions'],
      totalArea: map['totalArea']?.toDouble(),
      dosagePerHectare: map['dosagePerHectare']?.toDouble(),
      dosagePerApplication: map['dosagePerApplication']?.toDouble(),
      applicationVolume: map['applicationVolume']?.toDouble(),
      deviceId: map['deviceId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory Prescription.fromJson(String source) =>
      Prescription.fromMap(json.decode(source));

  Prescription copyWith({
    String? id,
    String? title,
    String? farmId,
    String? farmName,
    String? plotId,
    String? plotName,
    String? cropId,
    String? cropName,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? agronomistName,
    String? agronomistRegistration,
    String? status,
    List<PrescriptionProduct>? products,
    String? targetPest,
    String? targetDisease,
    String? targetWeed,
    String? observations,
    String? applicationConditions,
    String? safetyInstructions,
    double? totalArea,
    double? dosagePerHectare,
    double? dosagePerApplication,
    double? applicationVolume,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Prescription(
      id: id ?? this.id,
      title: title ?? this.title,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      plotId: plotId ?? this.plotId,
      plotName: plotName ?? this.plotName,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      agronomistName: agronomistName ?? this.agronomistName,
      agronomistRegistration: agronomistRegistration ?? this.agronomistRegistration,
      status: status ?? this.status,
      products: products ?? this.products,
      targetPest: targetPest ?? this.targetPest,
      targetDisease: targetDisease ?? this.targetDisease,
      targetWeed: targetWeed ?? this.targetWeed,
      observations: observations ?? this.observations,
      applicationConditions: applicationConditions ?? this.applicationConditions,
      safetyInstructions: safetyInstructions ?? this.safetyInstructions,
      totalArea: totalArea ?? this.totalArea,
      dosagePerHectare: dosagePerHectare ?? this.dosagePerHectare,
      dosagePerApplication: dosagePerApplication ?? this.dosagePerApplication,
      applicationVolume: applicationVolume ?? this.applicationVolume,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
