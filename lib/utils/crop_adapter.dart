import '../database/models/crop.dart' as db_crop;
import '../models/crop.dart' as app_crop;

/// Classe utilitária para converter entre os diferentes tipos de Crop
class CropAdapter {
  /// Converte um app_crop.Crop para db_crop.Crop
  static db_crop.Crop? convertAppCropToDbCrop(app_crop.Crop? appCrop) {
    if (appCrop == null) return null;
    
    return db_crop.Crop(
      id: appCrop.id ?? 0,
      name: appCrop.name,
      description: appCrop.description ?? '',
      syncStatus: appCrop.isSynced ? 1 : 0,
      remoteId: null,
      scientificName: appCrop.scientificName,
      growthCycle: appCrop.growthCycle,
      plantSpacing: appCrop.plantSpacing,
      rowSpacing: appCrop.rowSpacing,
      plantingDepth: appCrop.plantingDepth,
      idealTemperature: appCrop.idealTemperature,
      waterRequirement: appCrop.waterRequirement,
    );
  }

  /// Converte um db_crop.Crop para app_crop.Crop
  static app_crop.Crop? convertDbCropToAppCrop(db_crop.Crop? dbCrop) {
    if (dbCrop == null) return null;
    
    return app_crop.Crop(
      id: dbCrop.id,
      name: dbCrop.name,
      description: dbCrop.description,
      scientificName: dbCrop.scientificName,
      isSynced: dbCrop.isSynced,
      isDefault: false,
      growthCycle: dbCrop.growthCycle,
      plantSpacing: dbCrop.plantSpacing,
      rowSpacing: dbCrop.rowSpacing,
      plantingDepth: dbCrop.plantingDepth,
      idealTemperature: dbCrop.idealTemperature,
      waterRequirement: dbCrop.waterRequirement,
      colorValue: 0xFF4CAF50, // Cor padrão verde
    );
  }
}
