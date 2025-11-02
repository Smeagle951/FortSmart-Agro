import '../models/crop.dart' as app_crop;
import '../database/models/crop.dart' as db_crop;
import '../models/agricultural_product.dart';

/// Classe utilitária para converter entre diferentes modelos de dados
/// usados em diferentes partes do aplicativo.
class ModelConverters {
  /// Converte um AgriculturalProduct para o modelo Crop da aplicação
  static app_crop.Crop agriculturalProductToAppCrop(AgriculturalProduct product) {
    int? color;
    if (product.colorValue != null) {
      // Tenta converter de uma string hexadecimal para int
      color = int.tryParse(product.colorValue!.replaceFirst('#', ''), radix: 16);
      if (color != null) {
        color = 0xFF000000 | color; // Adiciona o canal alfa se não estiver presente
      }
    }

    return app_crop.Crop(
      id: int.tryParse(product.id) ?? 0,
      name: product.name,
      description: product.notes ?? '',
      colorValue: color,
    );
  }

  /// Converte um Crop da aplicação para AgriculturalProduct
  static AgriculturalProduct appCropToAgriculturalProduct(app_crop.Crop crop) {
    String? colorString;
    if (crop.colorValue != null) {
      // Converte o valor int para uma string hexadecimal no formato #RRGGBB
      colorString = '#${crop.colorValue!.toRadixString(16).padLeft(6, '0')}';
    }

    return AgriculturalProduct(
      id: crop.id?.toString() ?? '',
      name: crop.name,
      notes: crop.description,
      colorValue: colorString,
      type: ProductType.seed, // Assumindo tipo 'seed' para Crop
    );
  }

  /// Converte um Crop do modelo de banco de dados para o modelo da aplicação
  static app_crop.Crop dbCropToAppCrop(db_crop.Crop dbCrop) {
    return app_crop.Crop(
      id: dbCrop.id,
      name: dbCrop.name,
      description: dbCrop.description,
      scientificName: dbCrop.scientificName,
      growthCycle: dbCrop.growthCycle,
      plantSpacing: dbCrop.plantSpacing,
      rowSpacing: dbCrop.rowSpacing,
      plantingDepth: dbCrop.plantingDepth,
      idealTemperature: dbCrop.idealTemperature,
      waterRequirement: dbCrop.waterRequirement,
      isSynced: dbCrop.syncStatus == 1,
    );
  }

  /// Converte um Crop do modelo da aplicação para o modelo de banco de dados
  static db_crop.Crop appCropToDbCrop(app_crop.Crop appCrop) {
    return db_crop.Crop(
      id: appCrop.id ?? 0, // Garantir que id não seja nulo
      name: appCrop.name,
      description: appCrop.description ?? '',
      scientificName: appCrop.scientificName,
      growthCycle: appCrop.growthCycle,
      plantSpacing: appCrop.plantSpacing,
      rowSpacing: appCrop.rowSpacing,
      plantingDepth: appCrop.plantingDepth,
      idealTemperature: appCrop.idealTemperature,
      waterRequirement: appCrop.waterRequirement,
      syncStatus: appCrop.isSynced ? 1 : 0,
    );
  }

  /// Converte uma lista de Crop do modelo de banco de dados para o modelo da aplicação
  static List<app_crop.Crop> dbCropsToAppCrops(List<db_crop.Crop> dbCrops) {
    return dbCrops.map((crop) => dbCropToAppCrop(crop)).toList();
  }
}

