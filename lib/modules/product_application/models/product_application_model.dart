import 'dart:convert';
import 'package:fortsmart_agro/models/crop.dart' as app_crop;
import 'package:fortsmart_agro/models/talhao_model.dart';
import 'package:fortsmart_agro/models/user_model.dart';
import 'package:fortsmart_agro/modules/planting/services/data_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:fortsmart_agro/database/models/talhao.dart';
import 'package:fortsmart_agro/database/models/user.dart';

/// Enum para tipos de aplicação
enum ApplicationType {
  foliar,
  solo,
  semente,
  outro
}

/// Modelo para um produto aplicado
class AppliedProduct {
  final String? id;
  final String? productId;
  final String? productName;
  final String? productType;
  final double? dosePerHectare;
  final double? totalQuantity;
  final String? unitOfMeasure;
  final String? batchNumber;
  final String? inventoryId;

  /// Retorna a dose total do produto (quantidade total aplicada)
  double? get totalDose => totalQuantity;

  AppliedProduct({
    this.id,
    this.productId,
    this.productName,
    this.productType,
    this.dosePerHectare,
    this.totalQuantity,
    this.unitOfMeasure,
    this.batchNumber,
    this.inventoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'productId': productId,
      'productName': productName,
      'productType': productType,
      'dosePerHectare': dosePerHectare,
      'totalQuantity': totalQuantity,
      'unitOfMeasure': unitOfMeasure,
      'batchNumber': batchNumber,
      'inventoryId': inventoryId,
    };
  }

  factory AppliedProduct.fromMap(Map<String, dynamic> map) {
    return AppliedProduct(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      productType: map['productType'],
      dosePerHectare: map['dosePerHectare']?.toDouble(),
      totalQuantity: map['totalQuantity']?.toDouble(),
      unitOfMeasure: map['unitOfMeasure'],
      batchNumber: map['batchNumber'],
      inventoryId: map['inventoryId'],
    );
  }

  AppliedProduct copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productType,
    double? dosePerHectare,
    double? totalQuantity,
    String? unitOfMeasure,
    String? batchNumber,
    String? inventoryId,
  }) {
    return AppliedProduct(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      dosePerHectare: dosePerHectare ?? this.dosePerHectare,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      batchNumber: batchNumber ?? this.batchNumber,
      inventoryId: inventoryId ?? this.inventoryId,
    );
  }
}

/// Modelo para condições climáticas durante a aplicação
class WeatherConditions {
  final double? temperature;
  final double? humidity;
  final double? windSpeed;
  final String? windDirection;
  final bool? precipitation;

  WeatherConditions({
    this.temperature,
    this.humidity,
    this.windSpeed,
    this.windDirection,
    this.precipitation,
  });

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'precipitation': precipitation,
    };
  }

  factory WeatherConditions.fromMap(Map<String, dynamic> map) {
    return WeatherConditions(
      temperature: map['temperature']?.toDouble(),
      humidity: map['humidity']?.toDouble(),
      windSpeed: map['windSpeed']?.toDouble(),
      windDirection: map['windDirection'],
      precipitation: map['precipitation'],
    );
  }
}

/// Modelo para aplicação de produtos
class ProductApplicationModel {
  final String? id;
  final String? plotId;
  final String? cropId;
  final DateTime? applicationDate;
  final ApplicationType? applicationType;
  final int? numberOfTanks;
  final double? tankVolume;
  final double? totalArea;
  final String? userId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AppliedProduct>? products;
  final WeatherConditions? weatherConditions;

  /// Nome da cultura associada à aplicação
  String? get cropName {
    if (cropId == null) return null;
    try {
      final dataCache = DataCacheService();
      final culturas = dataCache.getCulturasSync();
      if (culturas == null) return null;
      
      final cultura = culturas.firstWhere(
        (c) => c.id.toString() == cropId,
        orElse: () => app_crop.Crop(id: 0, name: 'Cultura não encontrada', description: ''),
      );
      return cultura.name;
    } catch (e) {
      debugPrint('Erro ao obter nome da cultura: $e');
      return null;
    }
  }

  /// Nome do talhão associado à aplicação
  String? get plotName {
    if (plotId == null) return null;
    try {
      final dataCache = DataCacheService();
      final talhoes = dataCache.getTalhoesSync();
      if (talhoes == null) return null;
      
      final talhao = talhoes.firstWhere(
        (t) => t.id.toString() == plotId,
        orElse: () => TalhaoModel(
          id: '0',
          name: 'Talhão não encontrado',
          poligonos: [], // Lista de polígonos vazia
          area: 0,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
          sincronizado: false,
          safras: [],

        ),
      );
      return talhao.name;
    } catch (e) {
      debugPrint('Erro ao obter nome do talhão: $e');
      return null;
    }
  }

  /// Nome do responsável pela aplicação
  String? get responsibleName {
    if (userId == null) return null;
    try {
      final dataCache = DataCacheService();
      final users = dataCache.getUsersSync();
      if (users == null) return null;
      
      final user = users.firstWhere(
        (u) => u.id.toString() == userId,
        orElse: () => UserModel(id: '0', nome: 'Usuário não encontrado'),
      );
      return user.nome;
    } catch (e) {
      debugPrint('Erro ao obter nome do responsável: $e');
      return null;
    }
  }

  /// Volume total de calda utilizado
  double? get totalSyrupVolume {
    if (tankVolume == null || numberOfTanks == null) return null;
    return tankVolume! * numberOfTanks!;
  }

  ProductApplicationModel({
    this.id,
    this.plotId,
    this.cropId,
    this.applicationDate,
    this.applicationType,
    this.numberOfTanks,
    this.tankVolume,
    this.totalArea,
    this.userId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.products,
    this.weatherConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'plotId': plotId,
      'cropId': cropId,
      'applicationDate': applicationDate?.toIso8601String(),
      'applicationType': applicationType?.index,
      'numberOfTanks': numberOfTanks,
      'tankVolume': tankVolume,
      'totalArea': totalArea,
      'userId': userId,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'products': products != null ? jsonEncode(products!.map((x) => x.toMap()).toList()) : null,
      'weatherConditions': weatherConditions?.toMap() != null ? jsonEncode(weatherConditions!.toMap()) : null,
    };
  }

  factory ProductApplicationModel.fromMap(Map<String, dynamic> map) {
    List<AppliedProduct>? productsList;
    WeatherConditions? weather;

    try {
      if (map['products'] != null) {
        final List<dynamic> productsJson = jsonDecode(map['products']);
        productsList = productsJson.map((x) => AppliedProduct.fromMap(x)).toList();
      }
    } catch (e) {
      debugPrint('Erro ao decodificar produtos: $e');
      productsList = [];
    }

    try {
      if (map['weatherConditions'] != null) {
        final Map<String, dynamic> weatherJson = jsonDecode(map['weatherConditions']);
        weather = WeatherConditions.fromMap(weatherJson);
      }
    } catch (e) {
      debugPrint('Erro ao decodificar condições climáticas: $e');
      weather = null;
    }

    return ProductApplicationModel(
      id: map['id'],
      plotId: map['plotId'],
      cropId: map['cropId'],
      applicationDate: map['applicationDate'] != null ? DateTime.parse(map['applicationDate']) : null,
      applicationType: map['applicationType'] != null ? ApplicationType.values[map['applicationType']] : null,
      numberOfTanks: map['numberOfTanks'],
      tankVolume: map['tankVolume']?.toDouble(),
      totalArea: map['totalArea']?.toDouble(),
      userId: map['userId'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      products: productsList,
      weatherConditions: weather,
    );
  }

  ProductApplicationModel copyWith({
    String? id,
    String? plotId,
    String? cropId,
    DateTime? applicationDate,
    ApplicationType? applicationType,
    int? numberOfTanks,
    double? tankVolume,
    double? totalArea,
    String? userId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AppliedProduct>? products,
    WeatherConditions? weatherConditions,
  }) {
    return ProductApplicationModel(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      cropId: cropId ?? this.cropId,
      applicationDate: applicationDate ?? this.applicationDate,
      applicationType: applicationType ?? this.applicationType,
      numberOfTanks: numberOfTanks ?? this.numberOfTanks,
      tankVolume: tankVolume ?? this.tankVolume,
      totalArea: totalArea ?? this.totalArea,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      products: products ?? this.products,
      weatherConditions: weatherConditions ?? this.weatherConditions,
    );
  }
}
